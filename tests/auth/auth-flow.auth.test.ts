import { randomBytes } from "node:crypto";
import { describe, expect, test } from "vitest";
import {
  authBaseURL,
  collectCookie,
  fetchJson,
  requireEnv,
  signIn,
  currentUser,
  withAuthDbClient,
} from "./helpers";

/**
 * HTTP/DB интеграция auth (реальный production Next handler + PostgreSQL):
 * публичный signup запрещён, generic ошибки входа, session boundary
 * (отсутствие/подделка/истечение/отзыв), identity endpoint, rate limit.
 *
 * Порядок тестов фиксирован: все sign-in POST одного IP/маршрута/процесса
 * делят rate limit bucket (max 10 за 60s). Основной набор использует 5
 * входов; завершающий rate-limit тест добивает окно до 429.
 * Все «неправильные» пароли генерируются в рантайме — literals запрещены.
 */

let userACookie = "";
let userAId = "";
let userBId = "";

function wrongPassword(): string {
  return `wrong-${randomBytes(12).toString("hex")}`;
}

async function accountPasswordHash(userId: string): Promise<string | null> {
  let hash: string | null = null;
  await withAuthDbClient(async (client) => {
    const { rows } = await client.query<{ password: string | null }>(
      `SELECT "password" FROM "account" WHERE "user_id" = $1 AND "provider_id" = 'credential'`,
      [userId],
    );
    hash = rows[0]?.password ?? null;
  });
  return hash;
}

describe("граница анонимного доступа", () => {
  test("workspace страница анонимно перенаправляет на /login", async () => {
    const response = await fetch(`${authBaseURL()}/today`, {
      redirect: "manual",
    });
    expect(response.status).toBe(307);
    expect(response.headers.get("location")).toBe("/login");
  });

  test("me без сессии: 401 UNAUTHENTICATED и private no-store", async () => {
    const result = await currentUser("");
    expect(result.status).toBe(401);
    expect(result.body).toEqual({ error: { code: "UNAUTHENTICATED" } });
    expect(result.headers.get("cache-control")).toContain("private");
    expect(result.headers.get("cache-control")).toContain("no-store");
  });
});

describe("hostile origin и публичный signup", () => {
  test("sign-in с посторонним Origin отвергается CSRF-защитой", async () => {
    const result = await signIn(
      `origin-check-${crypto.randomUUID()}@orbit.test`,
      wrongPassword(),
      { origin: "https://evil.example" },
    );
    expect(result.status).toBeGreaterThanOrEqual(400);
    expect(result.status).toBeLessThan(500);
    expect(result.status).not.toBe(200);
  });

  const signupEmail = `signup-forbidden-${crypto.randomUUID()}@orbit.test`;

  test("прямой POST /sign-up/email отвергается без создания строк", async () => {
    const result = await fetchJson("/api/auth/sign-up/email", {
      method: "POST",
      body: JSON.stringify({
        email: signupEmail,
        password: wrongPassword(),
        name: "Should Not Exist",
      }),
    });
    expect(result.status).toBeGreaterThanOrEqual(400);
    expect(result.status).toBeLessThan(500);

    await withAuthDbClient(async (client) => {
      const { rows } = await client.query<{ count: string }>(
        `SELECT count(*)::text AS "count" FROM "user" WHERE "email" = $1`,
        [signupEmail],
      );
      expect(rows[0].count).toBe("0");
      // Сессии считаются по собственному fixture email этого теста, а не
      // глобально: соседние suite создают легитимные сессии своих
      // синтетических пользователей, не имеющие отношения к отвергнутому
      // signup (изоляция mutable fixtures, TASK-005).
      const sessions = await client.query<{ count: string }>(
        `SELECT count(*)::text AS "count" FROM "session" WHERE "user_id" IN (SELECT "id" FROM "user" WHERE "email" = $1)`,
        [signupEmail],
      );
      expect(sessions.rows[0].count).toBe("0");
    });
  });

  test("signup под email существующего пользователя не меняет пароль", async () => {
    const userAEmail = requireEnv("AUTH_TEST_USER_A_EMAIL");
    await withAuthDbClient(async (client) => {
      const selectHash = () =>
        client.query<{ password: string | null }>(
          `SELECT "password" FROM "account" WHERE "provider_id" = 'credential' AND "user_id" = (SELECT "id" FROM "user" WHERE "email" = $1)`,
          [userAEmail],
        );
      const before = await selectHash();
      const result = await fetchJson("/api/auth/sign-up/email", {
        method: "POST",
        body: JSON.stringify({
          email: userAEmail,
          password: wrongPassword(),
          name: "Attacker",
        }),
      });
      expect(result.status).toBeGreaterThanOrEqual(400);
      const after = await selectHash();
      expect(after.rows[0]?.password).toBe(before.rows[0]?.password);
    });
  });
});

describe("вход: generic ошибки без user enumeration", () => {
  test("неверный пароль: 401 с нейтральной ошибкой", async () => {
    const result = await signIn(
      requireEnv("AUTH_TEST_USER_A_EMAIL"),
      wrongPassword(),
    );
    expect(result.status).toBe(401);
    expect(JSON.stringify(result.body)).not.toContain(
      requireEnv("AUTH_TEST_USER_A_EMAIL"),
    );
  });

  test("неизвестный email: тот же статус и то же тело ответа", async () => {
    const unknown = await signIn(
      `unknown-${crypto.randomUUID()}@orbit.test`,
      wrongPassword(),
    );
    expect(unknown.status).toBe(401);
    const known = await signIn(requireEnv("AUTH_TEST_USER_A_EMAIL"), wrongPassword());
    expect(known.status).toBe(401);
    expect(JSON.stringify(unknown.body)).toBe(JSON.stringify(known.body));
  });

  test("валидный вход A: cookie с HttpOnly/SameSite=Lax", async () => {
    const result = await signIn(
      requireEnv("AUTH_TEST_USER_A_EMAIL"),
      requireEnv("AUTH_TEST_USER_A_PASSWORD"),
    );
    expect(result.status).toBe(200);
    expect(result.setCookie.length).toBeGreaterThan(0);
    const cookieHeader = result.setCookie.join("\n");
    expect(cookieHeader).toMatch(/HttpOnly/i);
    expect(cookieHeader).toMatch(/SameSite=Lax/i);
    userACookie = collectCookie(result.setCookie);
    expect(userACookie).toContain("better-auth.session_token=");
  });

  test("me с сессией A: id из сессии, impersonation игнорируется", async () => {
    const userBEmail = requireEnv("AUTH_TEST_USER_B_EMAIL");
    const result = await currentUser(userACookie);
    expect(result.status).toBe(200);
    const body = result.body as { user: { id: string } };
    expect(typeof body.user.id).toBe("string");
    userAId = body.user.id;
    expect(JSON.stringify(result.body)).not.toContain("@");

    const query = await currentUser(userACookie, {
      query: `?user_id=${encodeURIComponent("victim-user")}`,
    });
    expect(query.status).toBe(200);
    expect((query.body as { user: { id: string } }).user.id).toBe(userAId);

    const header = await currentUser(userACookie, {
      query: `?user_id=${encodeURIComponent(userBEmail)}`,
      headers: { "x-user-id": "victim-user" },
    });
    expect(header.status).toBe(200);
    expect((header.body as { user: { id: string } }).user.id).toBe(userAId);
  });

  test("поддельный cookie: 401", async () => {
    const tampered = userACookie.replace(/.$/, (character) =>
      character === "0" ? "1" : "0",
    );
    const result = await currentUser(tampered);
    expect(result.status).toBe(401);
  });

  test("sign-out отзывает сессию: старый cookie больше не работает", async () => {
    const signOut = await fetchJson("/api/auth/sign-out", {
      method: "POST",
      body: JSON.stringify({}),
      cookie: userACookie,
    });
    expect(signOut.status).toBe(200);
    const result = await currentUser(userACookie);
    expect(result.status).toBe(401);
  });
});

describe("два пользователя и истечение сессии", () => {
  test("вход B: me возвращает другого actor", async () => {
    const result = await signIn(
      requireEnv("AUTH_TEST_USER_B_EMAIL"),
      requireEnv("AUTH_TEST_USER_B_PASSWORD"),
    );
    expect(result.status).toBe(200);
    const cookieB = collectCookie(result.setCookie);
    const me = await currentUser(cookieB);
    expect(me.status).toBe(200);
    userBId = (me.body as { user: { id: string } }).user.id;
    expect(userBId).not.toBe(userAId);
    expect(userBId).not.toBe("");
  });

  test("просроченный expiresAt в БД: me 401 (cookie cache отключён)", async () => {
    await withAuthDbClient(async (client) => {
      await client.query(
        `UPDATE "session" SET "expires_at" = now() - interval '1 second' WHERE "user_id" = $1`,
        [userBId],
      );
    });
    const login = await signIn(
      requireEnv("AUTH_TEST_USER_B_EMAIL"),
      requireEnv("AUTH_TEST_USER_B_PASSWORD"),
    );
    expect(login.status).toBe(200);
    const cookieB = collectCookie(login.setCookie);
    expect((await currentUser(cookieB)).status).toBe(200);

    await withAuthDbClient(async (client) => {
      await client.query(
        `UPDATE "session" SET "expires_at" = now() - interval '1 second' WHERE "user_id" = $1`,
        [userBId],
      );
    });
    const result = await currentUser(cookieB);
    expect(result.status).toBe(401);
  });
});

describe("provisioning core: повторный bootstrap", () => {
  test("дубликат email отказывает без изменения пароля и без новых сессий", async () => {
    const { provisionLocalUser } = await import("@/server/auth/bootstrap-core");
    const { authDbConnectionString } = await import("./helpers");
    const email = requireEnv("AUTH_TEST_USER_A_EMAIL");
    const hashBefore = await accountPasswordHash(userAId);
    const sessionCount = async (): Promise<string> => {
      let count = "";
      await withAuthDbClient(async (client) => {
        const { rows } = await client.query<{ count: string }>(
          `SELECT count(*)::text AS "count" FROM "session" WHERE "user_id" = $1`,
          [userAId],
        );
        count = rows[0].count;
      });
      return count;
    };
    const sessionsBefore = await sessionCount();

    await expect(
      provisionLocalUser(authDbConnectionString(), {
        email,
        password: wrongPassword(),
        name: "Duplicate",
      }),
    ).rejects.toMatchObject({ code: "EMAIL_EXISTS" });

    expect(await accountPasswordHash(userAId)).toBe(hashBefore);
    expect(await sessionCount()).toBe(sessionsBefore);
  });
});

describe("rate limit на реальном runtime path", () => {
  test("повторные неудачные входы завершаются 429", async () => {
    let sawTooManyRequests = false;
    // Основной набор уже использовал 5 sign-in POST; окно max 10 → 429
    // не позже 11-й попытки. Cap 15 с запасом.
    for (let attempt = 0; attempt < 15 && !sawTooManyRequests; attempt += 1) {
      const result = await signIn(
        `rate-limit-${crypto.randomUUID()}@orbit.test`,
        wrongPassword(),
      );
      if (result.status === 429) {
        sawTooManyRequests = true;
      } else {
        expect(result.status).toBe(401);
      }
    }
    expect(sawTooManyRequests).toBe(true);
  });
});
