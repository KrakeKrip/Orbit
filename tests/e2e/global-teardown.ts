import { existsSync, readFileSync, rmSync } from "node:fs";

/**
 * Global teardown E2E (выполняется в runner-процессе после всех тестов).
 * Playwright спавнит webServer через shell, поэтому его SIGTERM получает
 * shell, а не node-процесс сервера. Здесь сигнал пересылается напрямую
 * pid сервера: сервер сам закрывает HTTP, закрывает пул приложения и
 * удаляет СВОЮ per-run базу (shutdown-обработчик в scripts/e2e-server.ts).
 *
 * Удаление чужого ресурса невозможно: имя базы этим файлом не передаётся,
 * удаляет её только владелец-сервер.
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

export default async function teardown(): Promise<void> {
  if (!existsSync(credentialsFile)) {
    return;
  }
  const raw = readFileSync(credentialsFile, "utf8");
  rmSync(credentialsFile, { force: true });

  let parsed: { pid?: number };
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
  if (!alive) {
    // Сервер уже остановлен (и убрал свою базу в shutdown-обработчике).
    return;
  }

  // reuseExistingServer вне CI оставит сервер работать: живой процесс —
  // владелец базы, сигнал ему не пересылается.
  if (process.env.CI) {
    process.kill(pid, "SIGTERM");
    await waitProcessExit(pid, 15000);
  }
}
