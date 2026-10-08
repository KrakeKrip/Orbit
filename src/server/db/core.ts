import { drizzle } from "drizzle-orm/node-postgres";
import type { NodePgDatabase } from "drizzle-orm/node-postgres";
import { Pool } from "pg";

/**
 * Нижний уровень доступа к БД (lower-level core, без server-only маркера):
 * разрешён CLI/тестовой инфраструктуре (scripts/, tests/, e2e-сервер),
 * которые создают собственные подключения/пулы и закрывают их явно.
 *
 * App-facing граница — `src/server/db/client.ts` (server-only): клиентские
 * компоненты не могут импортировать пул, а Next build это проверяет.
 * На import ничего не подключается и DATABASE_URL не требуется; первая
 * явная DB-операция без настроенного DATABASE_URL получает понятную
 * ошибку без раскрытия секретов.
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
    // Стандартная практика pg: ошибки idle-клиентов (например, рестарт БД или
    // завершение соединений при teardown тестового окружения) эмитятся на пул
    // и без обработчика роняют процесс. Ошибка логируется — не глушится.
    pool.on("error", (error) => {
      console.error("[db] idle client error:", error.message);
    });
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
