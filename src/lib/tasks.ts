/**
 * Чистые контракты и валидация tasks (TASK-007, Inbox one-off subset):
 * без импортов БД/auth и без server-only. Title: trim, 1–500 Unicode code
 * points (согласовано с PG char_length, не UTF-16 units); NUL и
 * unpaired surrogates отвергаются до PostgreSQL (иначе сервер возвращал бы
 * 500 на некорректный Unicode). Дубликаты разрешены; markup — данные, UI
 * рендерит текстом. Write-контракт этого TASK: create ровно {title},
 * PATCH — непустой subset {title?, completed?}; project/parent/notes/
 * priority/dates/recurrence/order через API не меняются.
 */

export const TASK_TITLE_MAX_LENGTH = 500;

export const TASK_LIST_STATUS_VALUES = ["open", "completed", "all"] as const;

export type TaskListStatus = (typeof TASK_LIST_STATUS_VALUES)[number];

export type TaskDTO = {
  id: string;
  title: string;
  projectId: string | null;
  parentId: string | null;
  completedAt: string | null;
  revision: number;
  createdAt: string;
  updatedAt: string;
};

export function isValidTaskListStatus(value: unknown): value is TaskListStatus {
  return (
    typeof value === "string" &&
    (TASK_LIST_STATUS_VALUES as readonly string[]).includes(value)
  );
}

export function parseTaskListStatusQuery(
  searchParams: URLSearchParams,
): { ok: true; status: TaskListStatus } | { ok: false } {
  const values = searchParams.getAll("status");
  const otherKeys = [...searchParams.keys()].filter((key) => key !== "status");
  if (otherKeys.length > 0 || values.length > 1) {
    return { ok: false };
  }
  if (values.length === 0) {
    return { ok: true, status: "open" };
  }
  if (!isValidTaskListStatus(values[0])) {
    return { ok: false };
  }
  return { ok: true, status: values[0] };
}

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Строгая синтаксическая проверка UUID (доменный id задач). */
export function isValidTaskId(value: unknown): value is string {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

/**
 * NUL-байты и unpaired surrogates не являются корректным текстом UTF-8:
 * PostgreSQL отверг бы их с 500, поэтому валидация отсекает их раньше.
 * Valid surrogate pairs разрешены (emoji и другие non-BMP символы).
 */
export function containsInvalidUnicodeText(input: string): boolean {
  if (input.includes("\0")) {
    return true;
  }
  // Убираем валидные surrogate pairs; остаточные lone surrogates невалидны.
  return /[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/.test(
    input,
  );
}

export function parseTaskTitle(
  input: unknown,
): { ok: true; title: string } | { ok: false } {
  if (typeof input !== "string") {
    return { ok: false };
  }
  const trimmed = input.trim();
  const codePoints = Array.from(trimmed).length;
  if (
    codePoints === 0 ||
    codePoints > TASK_TITLE_MAX_LENGTH ||
    containsInvalidUnicodeText(trimmed)
  ) {
    return { ok: false };
  }
  return { ok: true, title: trimmed };
}

export type TaskPatch = {
  title?: string;
  completed?: boolean;
};

export type TaskPatchField = "title" | "completed";

export type TaskPatchParseResult =
  | { ok: true; patch: TaskPatch }
  | { ok: false; field?: TaskPatchField };

/**
 * Строгий разбор PATCH: непустой plain object с подмножеством ключей
 * title/completed; неизвестные поля (project_id/parent_id/notes/priority/
 * dates/recurrence/owner/revision и т.п.), null, массивы и неверные типы
 * отвергаются; raw input в результат не попадает. Title канонизируется.
 */
export function parseTaskPatch(input: unknown): TaskPatchParseResult {
  if (typeof input !== "object" || input === null || Array.isArray(input)) {
    return { ok: false };
  }
  const record = input as Record<string, unknown>;
  const keys = Object.keys(record);
  if (keys.length === 0) {
    return { ok: false };
  }
  const patch: TaskPatch = {};
  for (const key of keys) {
    if (key !== "title" && key !== "completed") {
      return { ok: false };
    }
    if (key === "completed") {
      if (typeof record[key] !== "boolean") {
        return { ok: false, field: "completed" };
      }
      patch.completed = record[key] as boolean;
      continue;
    }
    const parsed = parseTaskTitle(record[key]);
    if (!parsed.ok) {
      return { ok: false, field: "title" };
    }
    patch.title = parsed.title;
  }
  return { ok: true, patch };
}

/** Строгий разбор create body: ровно {title:string}. */
export function parseTaskCreate(
  input: unknown,
): { ok: true; title: string } | { ok: false; field?: "title" } {
  if (typeof input !== "object" || input === null || Array.isArray(input)) {
    return { ok: false };
  }
  const keys = Object.keys(input as Record<string, unknown>);
  if (keys.length !== 1 || keys[0] !== "title") {
    return { ok: false };
  }
  const parsed = parseTaskTitle((input as Record<string, unknown>).title);
  if (!parsed.ok) {
    return { ok: false, field: "title" };
  }
  return { ok: true, title: parsed.title };
}

/** Преобразование строки БД в DTO (timestamps ISO8601; owner/секреты нет). */
export function toTaskDTO(row: {
  id: string;
  title: string;
  projectId: string | null;
  parentId: string | null;
  completedAt: Date | null;
  revision: number;
  createdAt: Date;
  updatedAt: Date;
}): TaskDTO {
  return {
    id: row.id,
    title: row.title,
    projectId: row.projectId,
    parentId: row.parentId,
    completedAt: row.completedAt === null ? null : row.completedAt.toISOString(),
    revision: row.revision,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}
