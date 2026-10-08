import { UnauthenticatedError, requireUser } from "@/server/auth/session";
import {
  errorResponse,
  hasJsonContentType,
  isAllowedOrigin,
  readJsonBodyWithLimit,
  NO_STORE,
} from "@/server/http";
import { createTask, listInboxTasks } from "@/server/tasks/service";
import {
  parseTaskCreate,
  parseTaskListStatusQuery,
  toTaskDTO,
} from "@/lib/tasks";

/**
 * Versioned Inbox collection endpoint (TASK-007). GET — только query
 * `status=open|completed|all` (default open; duplicate/unknown/лишние
 * keys →400); список строго owner-scoped, отсортирован
 * sort_order/created_at/id. POST — ровно {title} → 201 {task}: UUID и
 * owner генерирует сервер/БД, project/parent/notes/dates остаются NULL,
 * priority 4, sort_order 0, revision 0. Query на POST →400. Mutations:
 * точный application/json (415), потоковый лимит 2 KiB (413), malformed
 * 400, точная Origin-защита (403), session до mutation — любой отказ не
 * создаёт task. Все ответы private, no-store.
 */

export const dynamic = "force-dynamic";

export async function GET(request: Request): Promise<Response> {
  const parsedStatus = parseTaskListStatusQuery(
    new URL(request.url).searchParams,
  );
  if (!parsedStatus.ok) {
    return errorResponse(400, "VALIDATION_ERROR");
  }
  try {
    const user = await requireUser();
    const tasks = await listInboxTasks(user.id, parsedStatus.status);
    return Response.json(
      { tasks: tasks.map(toTaskDTO) },
      { headers: NO_STORE },
    );
  } catch (error) {
    if (error instanceof UnauthenticatedError) {
      return errorResponse(401, "UNAUTHENTICATED");
    }
    return errorResponse(500, "INTERNAL");
  }
}

export async function POST(request: Request): Promise<Response> {
  if (new URL(request.url).search !== "") {
    return errorResponse(400, "VALIDATION_ERROR");
  }
  if (!hasJsonContentType(request)) {
    return errorResponse(415, "UNSUPPORTED_MEDIA_TYPE");
  }
  const body = await readJsonBodyWithLimit(request);
  if (!body.ok) {
    return errorResponse(
      body.malformed ? 400 : 413,
      body.malformed ? "VALIDATION_ERROR" : "PAYLOAD_TOO_LARGE",
    );
  }
  try {
    // Session до любой mutation: анонимный вызов не создаёт task.
    const user = await requireUser();

    if (!isAllowedOrigin(request.headers.get("origin"))) {
      return errorResponse(403, "FORBIDDEN_ORIGIN");
    }

    const parsed = parseTaskCreate(body.json);
    if (!parsed.ok) {
      return errorResponse(400, "VALIDATION_ERROR", parsed.field);
    }
    const task = await createTask(user.id, parsed.title);
    return Response.json(
      { task: toTaskDTO(task) },
      { status: 201, headers: NO_STORE },
    );
  } catch (error) {
    if (error instanceof UnauthenticatedError) {
      return errorResponse(401, "UNAUTHENTICATED");
    }
    return errorResponse(500, "INTERNAL");
  }
}
