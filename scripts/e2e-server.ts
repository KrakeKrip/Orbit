import http from "node:http";
import path from "node:path";
import { mkdirSync, writeFileSync } from "node:fs";
import { loadDotEnv } from "../tests/db/db-target.ts";
import { prepareTestDatabase } from "../tests/db/runner.ts";
import { closeAppPoolAndConnections } from "../tests/db/app-connections.ts";
import { provisionLocalUser } from "../src/server/auth/bootstrap-core.ts";
import {
  e2eSecret,
  userAEmail,
  userAPassword,
  userBEmail,
  userBPassword,
} from "../tests/e2e/credentials.ts";

/**
 * Production-сервер для Playwright E2E (запускается webServer'ом playwright):
 * изолированная per-run база (проверенный target, уникальное имя, миграции)
 * и production Next request handler в этом же процессе (реальные сетевые
 * сокеты). Синтетические аккаунты A/B; пароли генерирует playwright config
 * и передаёт через окружение (AUTH_E2E_USER_*_PASSWORD) — литералов нет.
 *
 * Остановка: SIGTERM/SIGINT → graceful close HTTP-сервера → закрытие
 * фактического пула приложения (общий с compiled-бандлом через globalThis
 * реестр) → ожидание нуля соединений к своей базе → удаление только своей
 * базы → exit 0. Принудительный обрыв соединений — только аварийная
 * зачистка: тогда сервер сообщает нечистую остановку через exit 1.
 * Имя базы и pid записываются в маркер сразу после создания базы: teardown
 * playwright-раннера проверяет, что сервер вышел и убрал свою базу.
 */

function childDatabaseUrl(target: {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
}): string {
  return `postgresql://${encodeURIComponent(target.user)}:${encodeURIComponent(
    target.password,
  )}@${target.host}:${target.port}/${target.database}`;
}

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    console.error(`${name} is required for the E2E server.`);
    process.exit(1);
  }
  return value;
}

let shuttingDown = false;
let prepared: Awaited<ReturnType<typeof prepareTestDatabase>> | null = null;
let server: http.Server | null = null;

async function stopHttpServer(): Promise<void> {
  const active = server;
  if (!active) {
    return;
  }
  await new Promise<void>((resolve) => {
    // closeAllConnections: keep-alive сокеты браузера не должны удерживать
    // close — иначе SIGKILL придёт раньше удаления своей test-базы.
    active.closeAllConnections();
    active.close(() => resolve());
  });
}

async function shutdown(): Promise<void> {
  if (shuttingDown) {
    return;
  }
  shuttingDown = true;
  await stopHttpServer();
  if (prepared) {
    // R3b: пул приложения закрывается ДО удаления своей test-базы; ожидание
    // нуля соединений проверяет фактическое закрытие. clean:false (потребовался
    // принудительный обрыв) — нечистая остановка: exit 1 вместо успеха.
    const closed = await closeAppPoolAndConnections(prepared.target);
    await prepared.teardown();
    if (!closed.clean) {
      console.error(
        `[e2e-server] unclean shutdown: ${closed.remaining} connection(s) required forced termination`,
      );
      process.exit(1);
    }
  }
  process.exit(0);
}

process.on("SIGTERM", () => {
  void shutdown();
});
process.on("SIGINT", () => {
  void shutdown();
});

async function main(): Promise<void> {
  loadDotEnv();
  prepared = await prepareTestDatabase(process.env);
  const target = prepared.target;
  const port = Number(requiredEnv("E2E_PORT"));
  const baseURL = `http://127.0.0.1:${port}`;

  // Маркер пишется сразу после создания базы: любой сбой ниже оставляет
  // global-teardown'у имя базы и pid для проверки зачистки собственной базы.
  mkdirSync(path.join("test-results", ".auth"), { recursive: true });
  writeFileSync(
    path.join("test-results", ".auth", "e2e-db.json"),
    JSON.stringify({ database: target.database, pid: process.pid }),
  );

  // Сбой init не оставляет своих сервера/пула/базы.
  try {
    Object.assign(process.env, {
      NODE_ENV: "production",
      DATABASE_URL: childDatabaseUrl(target),
      BETTER_AUTH_SECRET: e2eSecret,
      BETTER_AUTH_URL: baseURL,
      PORT: String(port),
    });
    const databaseUrl = childDatabaseUrl(target);

    await provisionLocalUser(databaseUrl, {
      email: userAEmail,
      password: userAPassword,
      name: "E2E User A",
    });
    await provisionLocalUser(databaseUrl, {
      email: userBEmail,
      password: userBPassword,
      name: "E2E User B",
    });

    const { getRequestHandlers } = await import(
      "next/dist/server/lib/start-server.js"
    );
    const { requestHandler } = (await getRequestHandlers({
      dir: process.cwd(),
      port,
      hostname: "127.0.0.1",
      isDev: false,
      minimalMode: false,
      quiet: true,
      onDevServerCleanup: () => undefined,
    })) as unknown as {
      requestHandler: (
        request: http.IncomingMessage,
        response: http.ServerResponse,
      ) => Promise<void>;
    };

    const activeServer: http.Server = http.createServer(
      (request, response) => {
        void requestHandler(request, response);
      },
    );
    server = activeServer;
    await new Promise<void>((resolve) => {
      activeServer.listen(port, "127.0.0.1", resolve);
    });
    console.log(`E2E server ready at ${baseURL}`);
  } catch (error) {
    // R3b: закрыть пул приложения до удаления своей базы; принудительный
    // обрыв при сбое init — аварийная зачистка, она логируется.
    const closed = await closeAppPoolAndConnections(target);
    await prepared.teardown();
    if (!closed.clean) {
      console.error(
        `[e2e-server] init cleanup: ${closed.remaining} connection(s) required forced termination`,
      );
    }
    throw error;
  }
}

await main();
