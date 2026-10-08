import { and, eq, gte } from "drizzle-orm";
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import { account, session, user, verification } from "../db/schema.auth.ts";

/**
 * Provisioning core для локальной одноразовой bootstrap-процедуры и
 * синтетических аккаунтов в тестах. CLI-only: этот модуль НЕ импортируется
 * HTTP-обработчиками приложения и не управляется browser request/env —
 * production runtime всегда disableSignUp=true (см. auth/instance.ts).
 * Здесь нет своего password hashing и session протокола: аккаунт создаётся
 * поддерживаемым Better Auth API, поэтому формат совместим с runtime signIn.
 *
 * Атомарность: drizzle adapter создаёт user и credential account в одной
 * транзакции (transaction: true) — отказ второго INSERT откатывает первого,
 * orphan user не остаётся. Ошибки после создания (post-check, неожиданная
 * session) обрабатываются строго scoped компенсацией: удаляется только
 * пользователь, созданный ЭТИМ вызовом (email отсутствовал до него,
 * createdAt не раньше начала вызова, без завершённого credential account);
 * уже существующие пользователи/пароли не изменяются.
 */

export class ProvisioningError extends Error {
  readonly code: "EMAIL_EXISTS" | "PROVISIONING_FAILED";

  constructor(code: "EMAIL_EXISTS" | "PROVISIONING_FAILED", message: string) {
    super(message);
    this.name = "ProvisioningError";
    this.code = code;
  }
}

export type ProvisionedUser = {
  userId: string;
  email: string;
};

export async function provisionLocalUser(
  connectionString: string,
  input: { email: string; password: string; name: string },
): Promise<ProvisionedUser> {
  const pool = new Pool({ connectionString, max: 1 });
  const startedAt = new Date();

  try {
    const db = drizzle(pool);
    const auth = betterAuth({
      database: drizzleAdapter(drizzle(pool), {
        provider: "pg",
        schema: { user, session, account, verification },
        transaction: true,
      }),
      // Регистрация разрешена ТОЛЬКО в этом CLI/provisioning instance.
      emailAndPassword: {
        enabled: true,
        autoSignIn: false,
      },
      telemetry: {
        enabled: false,
      },
    });

    // Повторный запуск с существующим email: отказ без изменения
    // password/account и без нового user/session.
    const existing = await db
      .select({ id: user.id, createdAt: user.createdAt })
      .from(user)
      .where(eq(user.email, input.email))
      .limit(1);
    if (existing.length > 0) {
      throw new ProvisioningError(
        "EMAIL_EXISTS",
        "A user with this email already exists: nothing was changed.",
      );
    }

    let createdUserId: string | null = null;
    try {
      const result = await auth.api.signUpEmail({
        body: {
          email: input.email,
          password: input.password,
          name: input.name,
        },
      });
      createdUserId = result?.user?.id ?? null;
      if (!createdUserId) {
        throw new ProvisioningError(
          "PROVISIONING_FAILED",
          "Provisioning did not return a user.",
        );
      }

      // Целостность: credential account существует, активная сессия не
      // создавалась. Любая аномалия уходит в компенсацию ниже.
      const accounts = await db
        .select({ id: account.id })
        .from(account)
        .where(
          and(eq(account.userId, createdUserId), eq(account.providerId, "credential")),
        );
      if (accounts.length === 0) {
        throw new ProvisioningError(
          "PROVISIONING_FAILED",
          "Credential account was not created.",
        );
      }
      const sessions = await db
        .select({ id: session.id })
        .from(session)
        .where(eq(session.userId, createdUserId));
      if (sessions.length > 0) {
        throw new ProvisioningError(
          "PROVISIONING_FAILED",
          "Unexpected active session after provisioning.",
        );
      }

      return { userId: createdUserId, email: input.email };
    } catch (error) {
      // Строго scoped компенсация собственных строк этого вызова: pre-check
      // установил, что email до вызова отсутствовал, поэтому кандидаты —
      // только строки, созданные после начала вызова. Пользователь с уже
      // созданным credential account не трогается (это не наш сбой);
      // отказ "email занят другим actor" (422) компенсации не подлежит.
      const status = (error as { status?: number }).status;
      if (status !== 422) {
        try {
          const candidates = await db
            .select({ id: user.id })
            .from(user)
            .where(and(eq(user.email, input.email), gte(user.createdAt, startedAt)));
          for (const candidate of candidates) {
            const accounts = await db
              .select({ id: account.id })
              .from(account)
              .where(
                and(
                  eq(account.userId, candidate.id),
                  eq(account.providerId, "credential"),
                ),
              )
              .limit(1);
            if (accounts.length === 0) {
              // Каскад убирает и случайно созданные account/session.
              await db.delete(user).where(eq(user.id, candidate.id));
            }
          }
        } catch {
          // best-effort: исходная ошибка важнее сбоя компенсации.
        }
      }
      throw error;
    }
  } finally {
    await pool.end();
  }
}
