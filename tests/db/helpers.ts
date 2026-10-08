import { Client } from "pg";

/**
 * Помощник DB-тестов: короткоживущее подключение на каждый тест.
 * Клиенты всегда закрываются в finally — висящих процессов не остаётся.
 */

export function testDatabaseUrl(): string {
  try {
    process.loadEnvFile(".env");
  } catch {
    // .env может отсутствовать: TEST_DATABASE_URL берётся из окружения.
  }
  const url = process.env.TEST_DATABASE_URL;
  if (!url) {
    throw new Error("TEST_DATABASE_URL is not set.");
  }
  return url;
}

export async function withDbClient<T>(
  fn: (client: Client) => Promise<T>,
): Promise<T> {
  const client = new Client({ connectionString: testDatabaseUrl() });
  await client.connect();
  try {
    return await fn(client);
  } finally {
    await client.end();
  }
}

export async function createUsers(client: Client): Promise<{
  userA: string;
  userB: string;
}> {
  const userA = `user-a-${crypto.randomUUID()}`;
  const userB = `user-b-${crypto.randomUUID()}`;
  await client.query(
    `INSERT INTO "user" ("id", "name", "email") VALUES ($1, 'User A', $2), ($3, 'User B', $4)`,
    [userA, `${userA}@example.test`, userB, `${userB}@example.test`],
  );
  return { userA, userB };
}

/** Ожидает ошибку PostgreSQL с конкретным SQLSTATE. */
export async function expectPgError(
  action: () => Promise<unknown>,
  expectedCode: string,
): Promise<void> {
  let failed = false;
  try {
    await action();
  } catch (error) {
    failed = true;
    const code = (error as { code?: string }).code;
    if (code !== expectedCode) {
      throw new Error(
        `Expected SQLSTATE ${expectedCode}, got ${code ?? "no code"}: ${String(error)}`,
      );
    }
  }
  if (!failed) {
    throw new Error(`Expected PostgreSQL error ${expectedCode}, but operation succeeded.`);
  }
}
