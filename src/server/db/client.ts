import "server-only";

import { drizzle } from "drizzle-orm/node-postgres";
import type { NodePgDatabase } from "drizzle-orm/node-postgres";
import { Pool } from "pg";

/**
 * Server-only доступ к БД для app/service кода. На import ничего не
 * подключается и DATABASE_URL не требуется: build и быстрые UI-тесты
 * работают без БД и env. Первая явная DB-операция без настроенного
 * DATABASE_URL получает понятную ошибку без раскрытия секретов.
 *
 * `import "server-only"` делает импорт этого модуля из клиентских
 * компонентов ошибкой сборки: пул и строки подключения не попадают в
 * client bundle. CLI/тестовые сценарии используют собственные подключения
 * (см. tests/db, scripts/bootstrap-user.ts), этот модуль не ослабляется.
 */

let pool: Pool | null = null;
let db: NodePgDatabase<Record<string, never>> | null = null;

export function getDbPool(): Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error(
        "DATABASE_URL is not set: database operations are unavailable. Copy .env.example to .env for local development.",
      );
    }
    pool = new Pool({ connectionString, max: 10 });
  }
  return pool;
}

export function getDb(): NodePgDatabase<Record<string, never>> {
  if (!db) {
    db = drizzle(getDbPool());
  }
  return db;
}

export async function closeDbPool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    db = null;
  }
}
