import { and, eq } from "drizzle-orm";
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

  try {
    const db = drizzle(pool);
    const auth = betterAuth({
      database: drizzleAdapter(drizzle(pool), {
        provider: "pg",
        schema: { user, session, account, verification },
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
      .select({ id: user.id })
      .from(user)
      .where(eq(user.email, input.email))
      .limit(1);
    if (existing.length > 0) {
      throw new ProvisioningError(
        "EMAIL_EXISTS",
        "A user with this email already exists: nothing was changed.",
      );
    }

    const result = await auth.api.signUpEmail({
      body: {
        email: input.email,
        password: input.password,
        name: input.name,
      },
    });
    if (!result || !result.user) {
      throw new ProvisioningError(
        "PROVISIONING_FAILED",
        "Provisioning did not return a user.",
      );
    }
    const userId = result.user.id;

    // Целостность: пользователь имеет credential account, активная сессия
    // не создавалась; при частичном сбое — best-effort откат orphan user.
    const accounts = await db
      .select({ id: account.id })
      .from(account)
      .where(and(eq(account.userId, userId), eq(account.providerId, "credential")));
    const sessions = await db
      .select({ id: session.id })
      .from(session)
      .where(eq(session.userId, userId));

    if (accounts.length === 0) {
      await db.delete(user).where(eq(user.id, userId));
      throw new ProvisioningError(
        "PROVISIONING_FAILED",
        "Credential account was not created: the partial user record was rolled back.",
      );
    }
    if (sessions.length > 0) {
      throw new ProvisioningError(
        "PROVISIONING_FAILED",
        "Unexpected active session after provisioning.",
      );
    }

    return { userId, email: input.email };
  } finally {
    await pool.end();
  }
}
