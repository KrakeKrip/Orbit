import { existsSync, readFileSync, rmSync } from "node:fs";
import { Client } from "pg";
import {
  isRunnerCreatedDbName,
  loadDotEnv,
  resolveTestDatabaseTarget,
  type DbTarget,
} from "../db/db-target.ts";
import { dropRunnerDatabase } from "../db/runner.ts";

/**
 * Global teardown E2E (выполняется в runner-процессе после всех тестов).
 * Playwright спавнит webServer через shell, поэтому его SIGTERM получает
 * shell, а не node-процесс сервера. Здесь сигнал пересылается напрямую
 * pid сервера: сервер сам закрывает HTTP, закрывает пул приложения и
 * удаляет СВОЮ per-run базу (shutdown-обработчик в scripts/e2e-server.ts).
 *
 * R3b: результат ожидания выхода проверяется — таймаут означает нечистую
 * остановку и превращается в ошибку прогона. После выхода сервера teardown
 * убеждается, что база удалена; leftover собственной test-базы (владелец
 * погиб без зачистки) аварийно удаляется по имени из маркера с проверкой
 * namespace-паттерна, а прогон завершается ошибкой — это восстановление
 * своего ресурса, а не успешный teardown.
 *
 * Чужие ресурсы невозможны: имя базы берётся только из маркера этого
 * запуска и обязано соответствовать orbit_test-паттерну раннера.
 */

const credentialsFile = "test-results/.auth/e2e-db.json";

function waitProcessExit(pid: number, timeoutMs: number): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  return new Promise((resolve) => {
    const poll = () => {
      try {
        process.kill(pid, 0);
        if (Date.now() > deadline) {
          resolve(false);
          return;
        }
        setTimeout(poll, 200);
      } catch {
        resolve(true);
      }
    };
    poll();
  });
}

function adminConfig(): {
  host: string;
  port: number;
  user: string;
  password: string;
} {
  loadDotEnv();
  // Валидация TEST_DATABASE_URL выполняется повторно намеренно: подключения
  // строятся только из проверенных частей (host/port/user/password).
  const target = resolveTestDatabaseTarget(process.env);
  return {
    host: target.host,
    port: target.port,
    user: target.user,
    password: target.password,
  };
}

function adminTargetWith(database: string): DbTarget {
  return {
    ...adminConfig(),
    database,
  };
}

async function databaseExists(database: string): Promise<boolean> {
  const client = new Client({ ...adminConfig(), database: "postgres" });
  await client.connect();
  try {
    const { rows } = await client.query<{ exists: boolean }>(
      `SELECT EXISTS (SELECT 1 FROM "pg_database" WHERE "datname" = $1) AS "exists"`,
      [database],
    );
    return rows[0].exists;
  } finally {
    await client.end();
  }
}

async function waitForDatabaseDropped(
  database: string,
  timeoutMs: number,
): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (!(await databaseExists(database))) {
      return true;
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  return !(await databaseExists(database));
}

export default async function teardown(): Promise<void> {
  if (!existsSync(credentialsFile)) {
    return;
  }
  const raw = readFileSync(credentialsFile, "utf8");
  rmSync(credentialsFile, { force: true });

  let parsed: { pid?: number; database?: string };
  try {
    parsed = JSON.parse(raw);
  } catch {
    return;
  }
  const pid = parsed.pid;
  if (typeof pid !== "number" || pid <= 0) {
    return;
  }

  let alive = true;
  try {
    process.kill(pid, 0);
  } catch {
    alive = false;
  }
  if (alive && !process.env.CI) {
    // reuseExistingServer вне CI оставит сервер работать: живой процесс —
    // владелец базы, сигнал ему не пересылается, база не проверяется.
    return;
  }
  if (alive) {
    process.kill(pid, "SIGTERM");
    const exited = await waitProcessExit(pid, 20000);
    if (!exited) {
      // Нечистая остановка: базу не трогаем (владелец жив) и сообщаем сбой.
      throw new Error(
        `E2E server pid ${pid} did not exit within 20s after SIGTERM; its test database was left untouched.`,
      );
    }
  }

  const database = parsed.database;
  if (typeof database !== "string" || !isRunnerCreatedDbName(database)) {
    return;
  }
  const dropped = await waitForDatabaseDropped(database, 10000);
  if (dropped) {
    return;
  }
  // Владелец завершился, но базу не убрал (например, SIGKILL во время
  // shutdown): аварийная зачистка собственного ресурса + явный сбой прогона.
  await dropRunnerDatabase(adminTargetWith(database));
  throw new Error(
    `E2E server did not drop its test database ${database}; teardown dropped it as own-resource recovery. This is not a clean teardown.`,
  );
}
