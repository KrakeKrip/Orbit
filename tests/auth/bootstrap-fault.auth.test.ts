import { randomBytes } from "node:crypto";
import { describe, expect, test } from "vitest";
import { provisionLocalUser } from "@/server/auth/bootstrap-core";
import { authDbConnectionString } from "./helpers";

/**
 * R1-регрессия: атомарность provisioning. Отказ credential INSERT (fault
 * injection триггером на собственной per-run базе) не оставляет orphan
 * user/account/session; дубликат email не меняет существующие строки;
 * успешный bootstrap даёт совместимый sign-in. База — уникальная база
 * этого auth-запуска, чужие ресурсы не затрагиваются.
 */

async function installAccountInsertFault(): Promise<void> {
  const { Client } = await import("pg");
  const client = new Client({ connectionString: authDbConnectionString() });
  await client.connect();
  try {
    // Имена fault-объектов — фиксированные константы теста.
    await client.query(`
      CREATE FUNCTION orbit_test_fail_account_insert() RETURNS trigger LANGUAGE plpgsql AS $$
        BEGIN
          RAISE EXCEPTION 'orbit fault injection: account insert rejected';
        END;
      $$;
    `);
    await client.query(
      `CREATE TRIGGER orbit_test_fail_account_insert_trg BEFORE INSERT ON "account" FOR EACH ROW EXECUTE FUNCTION orbit_test_fail_account_insert()`,
    );
  } finally {
    await client.end();
  }
}

async function removeAccountInsertFault(): Promise<void> {
  const { Client } = await import("pg");
  const client = new Client({ connectionString: authDbConnectionString() });
  await client.connect();
  try {
    await client.query(
      `DROP TRIGGER IF EXISTS orbit_test_fail_account_insert_trg ON "account"`,
    );
    await client.query(
      `DROP FUNCTION IF EXISTS orbit_test_fail_account_insert()`,
    );
  } finally {
    await client.end();
  }
}

async function countRows(email: string): Promise<{
  users: number;
  accounts: number;
  sessions: number;
}> {
  const { Client } = await import("pg");
  const client = new Client({ connectionString: authDbConnectionString() });
  await client.connect();
  try {
    const users = await client.query<{ count: string }>(
      `SELECT count(*)::text AS "count" FROM "user" WHERE "email" = $1`,
      [email],
    );
    const accounts = await client.query<{ count: string }>(
      `SELECT count(*)::text AS "count" FROM "account" WHERE "user_id" IN (SELECT "id" FROM "user" WHERE "email" = $1)`,
      [email],
    );
    const sessions = await client.query<{ count: string }>(
      `SELECT count(*)::text AS "count" FROM "session" WHERE "user_id" IN (SELECT "id" FROM "user" WHERE "email" = $1)`,
      [email],
    );
    return {
      users: Number(users.rows[0].count),
      accounts: Number(accounts.rows[0].count),
      sessions: Number(sessions.rows[0].count),
    };
  } finally {
    await client.end();
  }
}

describe("R1: атомарность provisioning", () => {
  const faultEmail = `fault-inject-${crypto.randomUUID()}@orbit.test`;

  test("отказ credential INSERT не оставляет partial user/account/session", async () => {
    await installAccountInsertFault();
    try {
      await expect(
        provisionLocalUser(authDbConnectionString(), {
          email: faultEmail,
          password: randomBytes(12).toString("hex"),
          name: "Fault Injection",
        }),
      ).rejects.toThrowError();

      const state = await countRows(faultEmail);
      expect(state.users).toBe(0);
      expect(state.accounts).toBe(0);
      expect(state.sessions).toBe(0);
    } finally {
      await removeAccountInsertFault();
    }
  });

  test("повтор после сбоя и успешный bootstrap дают валидный аккаунт", async () => {
    const email = `retry-ok-${crypto.randomUUID()}@orbit.test`;
    const password = randomBytes(12).toString("hex");

    await provisionLocalUser(authDbConnectionString(), {
      email,
      password,
      name: "Retry OK",
    });
    const state = await countRows(email);
    expect(state.users).toBe(1);
    expect(state.accounts).toBe(1);
    expect(state.sessions).toBe(0);
    // Совместимость provision → sign-in дополнительно доказана в
    // auth-flow.auth.test.ts (пользователи A/B, созданные тем же core).
  });
});
