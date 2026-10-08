import { afterAll, describe, expect, test } from "vitest";
import { Client } from "pg";
import { loadDotEnv, resolveTestDatabaseTarget } from "./db-target";
import { prepareTestDatabase } from "./runner";

/**
 * R1 acceptance: раннер не трогает ранее существовавшие базы.
 * Sentinel-база создаётся этим тестом и удаляется только этим тестом;
 * на пользовательских данных проверка не выполняется.
 */

loadDotEnv();
const base = resolveTestDatabaseTarget();

async function withAdmin(fn: (client: Client) => Promise<void>): Promise<void> {
  const client = new Client({
    host: base.host,
    port: base.port,
    user: base.user,
    password: base.password,
    database: "postgres",
  });
  await client.connect();
  try {
    await fn(client);
  } finally {
    await client.end();
  }
}

async function databaseExists(name: string): Promise<boolean> {
  let exists = false;
  await withAdmin(async (admin) => {
    const { rows } = await admin.query<{ found: boolean }>(
      `SELECT EXISTS (SELECT 1 FROM "pg_database" WHERE "datname" = $1) AS "found"`,
      [name],
    );
    exists = rows[0].found;
  });
  return exists;
}

// Sentinel-ресурсы этого тестового файла.
const sentinelDb = "orbit_test";
let sentinelCreated = false;
let secondRunDb: string | null = null;

afterAll(async () => {
  if (sentinelCreated) {
    await withAdmin(async (admin) => {
      await admin.query(`DROP DATABASE IF EXISTS "${sentinelDb}" WITH (FORCE)`);
    });
  }
  if (secondRunDb && (await databaseExists(secondRunDb))) {
    await withAdmin(async (admin) => {
      await admin.query(`DROP DATABASE "${secondRunDb}" WITH (FORCE)`);
    });
  }
});

describe("R1: раннер не уничтожает существующие базы", () => {
  test("sentinel в заранее существующей orbit_test остаётся нетронутым", async () => {
    // 1. Готовим «ранее существовавшую» orbit_test с sentinel.
    await withAdmin(async (admin) => {
      await admin.query(`DROP DATABASE IF EXISTS "${sentinelDb}" WITH (FORCE)`);
      await admin.query(`CREATE DATABASE "${sentinelDb}"`);
    });
    sentinelCreated = true;
    const sentinel = new Client({
      host: base.host,
      port: base.port,
      user: base.user,
      password: base.password,
      database: sentinelDb,
    });
    await sentinel.connect();
    try {
      await sentinel.query(`CREATE TABLE "sentinel" ("value" text NOT NULL)`);
      await sentinel.query(
        `INSERT INTO "sentinel" ("value") VALUES ('keep-me')`,
      );
    } finally {
      await sentinel.end();
    }

    // 2. Реальный запуск подготовки test-базы.
    const prepared = await prepareTestDatabase(process.env);
    try {
      // 3. Создана уникальная база, а не orbit_test.
      expect(prepared.target.database).toMatch(/^orbit_test_[0-9]+_[a-z0-9]+$/);
      expect(prepared.target.database).not.toBe(sentinelDb);
      await expect(await databaseExists(prepared.target.database)).toBe(true);

      // 4. Sentinel и таблица с данными остались нетронутыми.
      const check = new Client({
        host: base.host,
        port: base.port,
        user: base.user,
        password: base.password,
        database: sentinelDb,
      });
      await check.connect();
      try {
        const { rows } = await check.query<{ value: string }>(
          `SELECT "value" FROM "sentinel"`,
        );
        expect(rows).toEqual([{ value: "keep-me" }]);
      } finally {
        await check.end();
      }
    } finally {
      // 5. teardown удаляет только созданную этим запуском базу.
      await prepared.teardown();
      await expect(await databaseExists(prepared.target.database)).toBe(false);
    }

    // 6. Sentinel жив и после teardown.
    await expect(await databaseExists(sentinelDb)).toBe(true);
    const verify = new Client({
      host: base.host,
      port: base.port,
      user: base.user,
      password: base.password,
      database: sentinelDb,
    });
    await verify.connect();
    try {
      const { rows } = await verify.query<{ value: string }>(
        `SELECT "value" FROM "sentinel"`,
      );
      expect(rows).toEqual([{ value: "keep-me" }]);
    } finally {
      await verify.end();
    }
  });

  test("два последовательных запуска создают разные базы и обе удаляются teardown", async () => {
    const first = await prepareTestDatabase(process.env);
    const second = await prepareTestDatabase(process.env);
    secondRunDb = second.target.database;
    try {
      expect(first.target.database).not.toBe(second.target.database);
      await expect(await databaseExists(first.target.database)).toBe(true);
      await expect(await databaseExists(second.target.database)).toBe(true);
    } finally {
      await first.teardown();
      await second.teardown();
    }
    await expect(await databaseExists(first.target.database)).toBe(false);
    await expect(await databaseExists(second.target.database)).toBe(false);
  });
});

describe("R1/R2: отказ без DDL", () => {
  test("без TEST_DATABASE_URL подготовка падает до DDL", async () => {
    await expect(
      prepareTestDatabase({ ...process.env, TEST_DATABASE_URL: undefined }),
    ).rejects.toThrowError(/explicit test permission/);
    await expect(
      prepareTestDatabase({
        ...process.env,
        TEST_DATABASE_URL: undefined,
        DATABASE_URL: "postgresql://orbit:secret@127.0.0.1:55432/orbit_test",
      }),
    ).rejects.toThrowError(/explicit test permission/);
  });

  test("remote host и query-подмена отвергаются до DDL", async () => {
    await expect(
      prepareTestDatabase({
        ...process.env,
        TEST_DATABASE_URL:
          "postgresql://orbit:secret@10.0.0.5:55432/orbit_test",
      }),
    ).rejects.toThrowError(/non-local test database host/);
    await expect(
      prepareTestDatabase({
        ...process.env,
        TEST_DATABASE_URL: `${base.host === "127.0.0.1" ? "postgresql://orbit:secret@127.0.0.1:55432" : "postgresql://orbit:secret@localhost:55432"}/orbit_test?host=10.0.0.5`,
      }),
    ).rejects.toThrowError(/query parameters/);
  });
});
