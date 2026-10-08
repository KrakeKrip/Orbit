import { createInterface, type Interface } from "node:readline";
import { ProvisioningError, provisionLocalUser } from "../src/server/auth/bootstrap-core.ts";

/**
 * Локальная одноразовая bootstrap-процедура первого аккаунта (операторский CLI):
 *   npm run auth:bootstrap
 *
 * - Работает только с локальным PostgreSQL: host обязателен явно и должен быть
 *   loopback (127.0.0.1/localhost/::1), query-параметры запрещены;
 *   production/unknown targets отвергаются до любых операций.
 * - Явное разрешение provisioning: интерактивное подтверждение "yes".
 * - Email/password вводятся оператором интерактивно; пароль читается скрыто
 *   (не argv, не stdout, не отчёты, не env).
 * - Повторный запуск с существующим email отказывает без изменения пароля,
 *   аккаунта и без создания сессии (никаких upsert/reset).
 * - Успех не оставляет активную сессию; при частичном сбое orphan user
 *   откатывается provisioning core.
 */

function loadDotEnv(): void {
  try {
    process.loadEnvFile(".env");
  } catch {
    // .env может отсутствовать: DATABASE_URL берётся из окружения.
  }
}

function assertLocalDatabaseUrl(): string {
  const raw = process.env.DATABASE_URL;
  if (!raw || raw.trim() === "") {
    console.error("DATABASE_URL is not set. Copy .env.example to .env first.");
    process.exit(1);
  }
  const url = new URL(raw);
  const localHosts = new Set(["localhost", "127.0.0.1", "::1"]);
  const host = url.hostname.replace(/^\[|\]$/g, "");
  if (!localHosts.has(host)) {
    console.error(
      `Refusing non-local database host: ${host}. Bootstrap is a local operator procedure only.`,
    );
    process.exit(1);
  }
  if ([...url.searchParams.keys()].length > 0) {
    console.error("Refusing DATABASE_URL with query parameters.");
    process.exit(1);
  }
  const port = url.port === "" ? "5432" : url.port;
  return `postgresql://${encodeURIComponent(url.username)}:${encodeURIComponent(decodeURIComponent(url.password))}@${host}:${port}${url.pathname}`;
}

function ask(rl: Interface, question: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(question, (answer: string) => resolve(answer.trim()));
  });
}

function askHidden(question: string): Promise<string> {
  return new Promise((resolve) => {
    process.stdout.write(question);
    const characters: string[] = [];
    const wasRaw = process.stdin.isRaw ?? false;
    if (process.stdin.isTTY) {
      process.stdin.setRawMode(true);
    }
    const onData = (chunk: Buffer) => {
      for (const character of chunk.toString("utf8")) {
        if (character === "\r" || character === "\n") {
          process.stdin.setRawMode?.(wasRaw);
          process.stdin.off("data", onData);
          process.stdout.write("\n");
          resolve(characters.join(""));
          return;
        }
        if (character === "\u0003") {
          process.stdout.write("\n");
          process.exit(130);
        }
        if (character === "\u007f" || character === "\b") {
          characters.pop();
          continue;
        }
        characters.push(character);
      }
    };
    process.stdin.on("data", onData);
  });
}

async function main(): Promise<void> {
  loadDotEnv();
  const connectionString = assertLocalDatabaseUrl();

  if (!process.stdin.isTTY) {
    console.error(
      "Bootstrap requires an interactive terminal: email/password are entered privately via prompts.",
    );
    process.exit(1);
  }

  const rl = createInterface({ input: process.stdin, output: process.stdout });

  const confirm = await ask(
    rl,
    "This creates a local user account in the configured LOCAL database. Continue? (yes/no) ",
  );
  if (confirm.toLowerCase() !== "yes") {
    console.log("Aborted.");
    process.exit(0);
  }

  const email = await ask(rl, "Email: ");
  rl.close();
  if (!email || !email.includes("@")) {
    console.error("A valid email is required.");
    process.exit(1);
  }

  const password = await askHidden("Password (hidden, min 8 chars): ");
  if (password.length < 8) {
    console.error("Password must be at least 8 characters.");
    process.exit(1);
  }

  try {
    const result = await provisionLocalUser(connectionString, {
      email,
      password,
      name: email.split("@")[0] ?? email,
    });
    console.log(
      `Account created for ${result.email} (user id: ${result.userId}).`,
    );
    console.log("No session was created. Sign in via /login in the app.");
  } catch (error) {
    if (error instanceof ProvisioningError) {
      console.error(`Bootstrap refused (${error.code}): ${error.message}`);
      process.exit(2);
    }
    console.error("Bootstrap failed. Nothing else was changed.");
    process.exit(1);
  }
}

process.on("SIGINT", () => {
  process.stdout.write("\n");
  process.exit(130);
});

await main();
