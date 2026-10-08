import { Pool } from "pg";

/**
 * Ленивый server-only пул подключений. На import ничего не подключается и
 * DATABASE_URL не требуется: это позволяет npm test/build существующих
 * экранов работать без БД и env. Первая явная DB-операция без настроенного
 * DATABASE_URL получает понятную ошибку без раскрытия секретов.
 */

let pool: Pool | null = null;

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

export async function closeDbPool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
