import http from "node:http";
import { randomBytes } from "node:crypto";
import { Client } from "pg";
import { loadDotEnv } from "../db/db-target.ts";
import { prepareTestDatabase } from "../db/runner.ts";
import { closeDbPool } from "../../src/server/db/core.ts";
import { provisionLocalUser } from "../../src/server/auth/bootstrap-core.ts";

/**
 * Global setup auth suite (npm run test:auth): изолированная per-run база
 * (проверенный target, уникальное имя, миграции) + production Next
 * request handler, поднятый в процессе тест-раннера на собственном
 * http-сервере (реальные сетевые сокеты, HTTP-граница настоящая).
 *
 * Runtime-конфигурация auth живёт только в памяти этого процесса
 * (temporary secret, temporary baseURL, собственная база) и выставляется
 * до инициализации обработчика; build и UI-тесты от неё не зависят.
 * Синтетические аккаунты A/B создаются provisioning core; их пароли
 * генерируются на этот запуск и передаются тестам через окружение.
 *
 * Teardown (R3): остановка своего http-сервера → закрытие пула приложения
 * (closeDbPool) → проверка отсутствия соединений → удаление только своей
 * базы. Сбой setup не оставляет своих сервера/пула/базы.
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

function getFreePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = http.createServer();
    server.unref();
    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      const port = typeof address === "object" && address ? address.port : 0;
      server.close(() => resolve(port));
    });
  });
}

function waitForReady(baseURL: string, timeoutMs: number): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  return new Promise((resolve, reject) => {
    const poll = async () => {
      if (Date.now() > deadline) {
        reject(new Error(`Next server did not become ready at ${baseURL}`));
        return;
      }
      try {
        const response = await fetch(`${baseURL}/login`);
        if (response.ok) {
          resolve();
          return;
        }
      } catch {
        // сервер ещё не готов
      }
      setTimeout(poll, 500);
    };
    void poll();
  });
}

/** R3-регрессия: после остановки приложения соединений к базе быть не должно. */
async function countConnections(target: {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
}): Promise<number> {
  const admin = new Client({
    host: target.host,
    port: target.port,
    user: target.user,
    password: target.password,
    database: "postgres",
  });
  await admin.connect();
  try {
    const { rows } = await admin.query<{ count: number }>(
      `SELECT count(*)::int AS "count" FROM "pg_stat_activity" WHERE "datname" = $1`,
      [target.database],
    );
    return rows[0].count;
  } finally {
    await admin.end();
  }
}

/** Ожидает закрытия соединений после closeDbPool; возвращает остаток. */
async function waitForConnectionsClosed(target: {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
}, timeoutMs: number): Promise<number> {
  const deadline = Date.now() + timeoutMs;
  let count = await countConnections(target);
  while (count !== 0 && Date.now() < deadline) {
    await new Promise((resolve) => setTimeout(resolve, 250));
    count = await countConnections(target);
  }
  return count;
}

export default async function setup(): Promise<() => Promise<void>> {
  loadDotEnv();
  const prepared = await prepareTestDatabase(process.env);
  const target = prepared.target;
  const databaseUrl = childDatabaseUrl(target);

  const port = await getFreePort();
  const baseURL = `http://127.0.0.1:${port}`;
  const secret = randomBytes(32).toString("hex");

  // Синтетические пользователи A/B: одноразовые пароли этого запуска.
  const userAPassword = randomBytes(16).toString("hex");
  const userBPassword = randomBytes(16).toString("hex");

  let server: http.Server | null = null;
  let stopped = false;
  const stopServer = async () => {
    const active = server;
    if (stopped || !active) {
      return;
    }
    stopped = true;
    await new Promise<void>((resolve) => {
      // closeAllConnections: keep-alive не удерживает остановку сервера,
      // чтобы teardown успел закрыть пул и удалить свою базу.
      active.closeAllConnections();
      active.close(() => resolve());
    });
  };

  // Сбой setup не оставляет своих сервера/пула/базы.
  try {
    // Runtime env до инициализации Next-обработчика (fail-closed при отсутствии).
    Object.assign(process.env, {
      NODE_ENV: "production",
      DATABASE_URL: databaseUrl,
      BETTER_AUTH_SECRET: secret,
      BETTER_AUTH_URL: baseURL,
      PORT: String(port),
    });

    await provisionLocalUser(databaseUrl, {
      email: "user-a@orbit.test",
      password: userAPassword,
      name: "User A",
    });
    await provisionLocalUser(databaseUrl, {
      email: "user-b@orbit.test",
      password: userBPassword,
      name: "User B",
    });

    // Production request handler Next.js (тот же кодовый путь, что и у
    // `next start`): подключается к собранному .next и отвечает по HTTP.
    const { getRequestHandlers } = await import(
      "next/dist/server/lib/start-server.js"
    );
    const { requestHandler } = (await getRequestHandlers({
      dir: process.cwd(),
      port,
      hostname: "127.0.0.1",
      isDev: false,
      minimalMode: false,
      quiet: false,
      onDevServerCleanup: () => undefined,
    })) as unknown as {
      requestHandler: (
        request: import("node:http").IncomingMessage,
        response: import("node:http").ServerResponse,
      ) => Promise<void>;
    };

    const createdServer: http.Server = http.createServer((request, response) => {
      void requestHandler(request, response);
    });
    server = createdServer;
    await new Promise<void>((resolve) => {
      createdServer.listen(port, "127.0.0.1", resolve);
    });
    await waitForReady(baseURL, 60000);
  } catch (error) {
    await stopServer();
    // Пул приложения закрывается ДО удаления собственной test-базы (R3).
    await closeDbPool();
    await prepared.teardown();
    throw error;
  }

  process.env.AUTH_TEST_BASE_URL = baseURL;
  process.env.AUTH_TEST_USER_A_EMAIL = "user-a@orbit.test";
  process.env.AUTH_TEST_USER_A_PASSWORD = userAPassword;
  process.env.AUTH_TEST_USER_B_EMAIL = "user-b@orbit.test";
  process.env.AUTH_TEST_USER_B_PASSWORD = userBPassword;
  process.env.ORBIT_TEST_DB_NAME = target.database;

  return async () => {
    await stopServer();
    // Пул приложения закрывается ДО удаления собственной test-базы (R3):
    // иначе DROP WITH FORCE терминирует idle-клиентов (57P01).
    await closeDbPool();
    // Соединения compiled-бандла Next недоступны из этого графа модулей —
    // завершаем только соединения к СВОЕЙ базе (pg_terminate_backend по pid)
    // и ждём их закрытия до drop. Ошибки пула логируются обработчиком в core.
    await terminateOwnConnections(target);
    const remaining = await waitForConnectionsClosed(target, 5000);
    if (remaining !== 0) {
      throw new Error(
        `R3 regression: ${remaining} app connection(s) remain to the test DB after close.`,
      );
    }
    await prepared.teardown();
  };
}

/** Завершает только соединения к собственной per-run базе этого запуска. */
async function terminateOwnConnections(target: {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
}): Promise<void> {
  const admin = new Client({
    host: target.host,
    port: target.port,
    user: target.user,
    password: target.password,
    database: "postgres",
  });
  await admin.connect();
  try {
    await admin.query(
      `SELECT pg_terminate_backend("pid") FROM "pg_stat_activity" WHERE "datname" = $1 AND "pid" <> "pg_backend_pid"()`,
      [target.database],
    );
  } finally {
    await admin.end();
  }
}
