import { drizzle } from "drizzle-orm/node-postgres";
import { migrate } from "drizzle-orm/node-postgres/migrator";
import { Client, Pool } from "pg";

/**
 * Подготовка изолированной test-базы для npm run test:db.
 *
 * Разрешение на деструктивные операции даёт только явный TEST_DATABASE_URL
 * (автоматического fallback на DATABASE_URL нет) при выполнении ВСЕХ условий:
 *   1. хост локальный (localhost/127.0.0.1/::1);
 *   2. имя базы заканчивается на _test и состоит из [a-z0-9_];
 *   3. база пересоздаётся раннером, поэтому чужие данные не затрагиваются.
 * Неизвестные/удалённые/production цели отвергаются ДО любого DDL.
 */

try {
  process.loadEnvFile(".env");
} catch {
  // .env может отсутствовать: TEST_DATABASE_URL берётся из окружения.
}

function testDatabaseUrl(): string {
  const url = process.env.TEST_DATABASE_URL;
  if (!url) {
    throw new Error(
      "TEST_DATABASE_URL is not set. Copy .env.example to .env and point it at a local *_test database. No fallback to DATABASE_URL by design.",
    );
  }
  return url;
}

function assertLocalTestDatabase(rawUrl: string): string {
  const url = new URL(rawUrl);
  const localHosts = new Set(["localhost", "127.0.0.1", "::1"]);
  if (!localHosts.has(url.hostname)) {
    throw new Error(
      `Refusing non-local test database host: ${url.hostname}. Only localhost/127.0.0.1/::1 are allowed.`,
    );
  }
  const dbName = url.pathname.replace(/^\//, "");
  if (!/^[a-z0-9_]+_test$/.test(dbName)) {
    throw new Error(
      `Refusing database name ${JSON.stringify(dbName)}: test database must match [a-z0-9_]+_test.`,
    );
  }
  return dbName;
}

export default async function setup(): Promise<() => Promise<void>> {
  const rawUrl = testDatabaseUrl();
  const dbName = assertLocalTestDatabase(rawUrl);

  // Административное подключение к maintenance-базе postgres для создания test-базы.
  // URL строится явно: опция database у pg не всегда переопределяет базу из строки.
  const adminUrl = new URL(rawUrl);
  adminUrl.pathname = "/postgres";
  const admin = new Client({ connectionString: adminUrl.toString() });
  await admin.connect();
  try {
    await admin.query(`DROP DATABASE IF EXISTS "${dbName}" WITH (FORCE)`);
    await admin.query(`CREATE DATABASE "${dbName}"`);
  } finally {
    await admin.end();
  }

  // Применяем checked-in миграции к свежей test-базе.
  const pool = new Pool({ connectionString: rawUrl, max: 1 });
  try {
    await migrate(drizzle(pool), { migrationsFolder: "./drizzle" });
  } finally {
    await pool.end();
  }

  return async () => {
    // Все подключения закрыты в setup; test-база остаётся для инспекции
    // и пересоздаётся при следующем прогоне.
  };
}
