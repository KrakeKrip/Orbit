import { UnauthenticatedError, requireUser } from "@/server/auth/session";
import { readAuthBaseOrigin } from "@/server/auth/env";
import {
  getAccountSettings,
  updateAccountSettings,
} from "@/server/settings/service";
import {
  parseSettingsPatch,
  type AccountSettingsPayload,
} from "@/lib/settings";

/**
 * Versioned settings endpoint (TASK-005): GET/PATCH timezone/theme только
 * текущего пользователя. Actor только из проверенной сессии; query/header
 * identity игнорируются, query parameters не поддерживаются. Это собственный
 * cookie mutation endpoint: PATCH дополнительно защищён точной server-side
 * Origin проверкой configured BETTER_AUTH_URL (Better Auth routes этот
 * endpoint не защищают); разрешённый origin не берётся из Host/X-Forwarded-*.
 *
 * Порядок проверок PATCH (документирован и покрыт тестами): transport
 * (Content-Type 415 → размер 413 → JSON 400) → session 401 → Origin 403 →
 * валидация полей 400 → mutation. Любой отказ не пишет в БД; анонимный
 * вызов не создаёт row. Все ответы, включая ошибки: private, no-store;
 * тела ошибок без email/tokens/hashes/stack/SQL.
 */

export const dynamic = "force-dynamic";

const NO_STORE = { "cache-control": "private, no-store" } as const;
const MAX_PATCH_BODY_BYTES = 2048;

function errorResponse(
  status: number,
  code: string,
  field?: string,
): Response {
  return Response.json(
    { error: { code, ...(field === undefined ? {} : { field }) } },
    { status, headers: NO_STORE },
  );
}

function settingsResponse(payload: AccountSettingsPayload): Response {
  return Response.json(payload, { headers: NO_STORE });
}

function rejectQuery(request: Request): Response | null {
  if (new URL(request.url).search !== "") {
    return errorResponse(400, "VALIDATION_ERROR");
  }
  return null;
}

function isAllowedOrigin(originHeader: string | null): boolean {
  // Разрешён только точный configured BETTER_AUTH_URL origin; missing/null
  // и любые другие значения отклоняются. Host/Forwarded заголовки не читаются.
  const expected = readAuthBaseOrigin();
  if (!originHeader || originHeader === "null") {
    return false;
  }
  try {
    return new URL(originHeader).origin === expected;
  } catch {
    return false;
  }
}

async function readBodyWithLimit(
  request: Request,
  maxBytes: number,
): Promise<{ ok: true; text: string } | { ok: false }> {
  const declaredLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    return { ok: false };
  }
  if (!request.body) {
    return { ok: true, text: "" };
  }
  const reader = request.body.getReader();
  const decoder = new TextDecoder();
  let text = "";
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    total += value.byteLength;
    if (total > maxBytes) {
      await reader.cancel().catch(() => undefined);
      return { ok: false };
    }
    // stream: true — корректная сборка multi-byte символов на границах чанков.
    text += decoder.decode(value, { stream: true });
  }
  text += decoder.decode();
  return { ok: true, text };
}

export async function GET(request: Request): Promise<Response> {
  const queryRejection = rejectQuery(request);
  if (queryRejection) {
    return queryRejection;
  }
  try {
    const user = await requireUser();
    const settings = await getAccountSettings(user.id);
    return settingsResponse({ settings });
  } catch (error) {
    if (error instanceof UnauthenticatedError) {
      return errorResponse(401, "UNAUTHENTICATED");
    }
    return errorResponse(500, "INTERNAL");
  }
}

export async function PATCH(request: Request): Promise<Response> {
  const queryRejection = rejectQuery(request);
  if (queryRejection) {
    return queryRejection;
  }

  const contentType = request.headers.get("content-type") ?? "";
  if (!contentType.startsWith("application/json")) {
    return errorResponse(415, "UNSUPPORTED_MEDIA_TYPE");
  }

  const body = await readBodyWithLimit(request, MAX_PATCH_BODY_BYTES);
  if (!body.ok) {
    return errorResponse(413, "PAYLOAD_TOO_LARGE");
  }
  let parsedJson: unknown;
  try {
    parsedJson = JSON.parse(body.text);
  } catch {
    return errorResponse(400, "VALIDATION_ERROR");
  }

  try {
    // Session до любой mutation: анонимный вызов не создаёт row.
    const user = await requireUser();

    if (!isAllowedOrigin(request.headers.get("origin"))) {
      return errorResponse(403, "FORBIDDEN_ORIGIN");
    }

    const parsed = parseSettingsPatch(parsedJson);
    if (!parsed.ok) {
      return errorResponse(400, "VALIDATION_ERROR", parsed.field);
    }
    const settings = await updateAccountSettings(user.id, parsed.patch);
    return settingsResponse({ settings });
  } catch (error) {
    if (error instanceof UnauthenticatedError) {
      return errorResponse(401, "UNAUTHENTICATED");
    }
    return errorResponse(500, "INTERNAL");
  }
}
