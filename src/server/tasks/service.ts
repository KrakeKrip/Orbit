import "server-only";

import { randomUUID } from "node:crypto";
import { and, asc, eq, isNotNull, isNull, sql } from "drizzle-orm";
import { getDb } from "@/server/db/client";
import { projects, taskCompletions, tasks } from "@/server/db/schema";
import type { TaskListStatus, TaskPatch } from "@/lib/tasks";

/**
 * Task service (TASK-007, Inbox one-off subset): owner-scoped list/read/
 * create/mutate на существующей схеме. Actor — только server-derived id из
 * requireUser; client owner/project/parent не принимаются. Composite FK
 * (project_id, owner_id)/(parent_id, owner_id) гарантируют, что связи
 * указывают только на собственные проекты/задачи, поэтому фильтры по
 * owner_id в join/EXISTS не создают меж-owner связей.
 *
 * Inbox collection: собственные не-deleted root tasks (parent_id NULL) без
 * planned_date, у которых project_id NULL либо собственный НЕархивированный
 * проект (исключение архивных — на сервере). Сортировка стабильная:
 * sort_order ASC, created_at ASC, id ASC. Ошибка БД пробрасывается, не
 * превращаясь в пустой список; cross-request cache нет.
 *
 * Мутации (PATCH/DELETE) выполняются в транзакции: сперва row lock задачи
 * (SELECT ... FOR UPDATE по id+owner+deleted_at IS NULL), затем guard'ы
 * состояния (child/recurrence → UNSUPPORTED_TASK; задача архивного проекта
 * → PROJECT_ARCHIVED — row lock проекта сериализует проверку с принятым
 * archive UPDATE projects, поэтому архив не может вклиниться между
 * проверкой и записью; порядок блокировок всегда task → project, у project
 * archive встречных task-блокировок нет — deadlock невозможен). Изменения
 * считываются и применяются под блокировкой: revision +1 только при
 * реальном изменении (title/complete/reopen/delete), updated_at — только
 * при изменении; полный no-op возвращает текущее состояние без записи.
 *
 * Completion: переход open→completed записывает task.completed_at и журнал
 * task_completions ОДНИМ server timestamp в той же транзакции
 * (occurrence_date NULL, completed_revision = revision ДО перехода,
 * idempotency_key — server UUID); отказ INSERT откатывает и task. Повторы и
 * конкурентные completes: row lock сериализует — второй видит уже
 * completed и возвращает no-op; ровно один journal row. Reopen:
 * completed_at NULL, revision+1, журнал сохраняется; re-complete добавляет
 * новый log с новой completed_revision (unique(task_id,completed_revision)
 * не конфликтует).
 *
 * Soft delete: root получает deleted_at/updated_at (один timestamp) и
 * revision+1; в той же транзакции собственные активные direct children
 * скрываются тем же timestamp с revision+1; уже удалённые children и
 * project/completion journal не меняются. Физического DELETE нет.
 */

export type TaskRecord = {
  id: string;
  title: string;
  projectId: string | null;
  parentId: string | null;
  completedAt: Date | null;
  revision: number;
  createdAt: Date;
  updatedAt: Date;
};

export type TaskMutationOutcome =
  | { kind: "task"; task: TaskRecord }
  | { kind: "not-found" }
  | { kind: "unsupported" }
  | { kind: "project-archived" };

const taskColumns = {
  id: tasks.id,
  title: tasks.title,
  projectId: tasks.projectId,
  parentId: tasks.parentId,
  completedAt: tasks.completedAt,
  revision: tasks.revision,
  createdAt: tasks.createdAt,
  updatedAt: tasks.updatedAt,
};

export async function listInboxTasks(
  actorId: string,
  status: TaskListStatus,
): Promise<TaskRecord[]> {
  const ownerFilter = eq(tasks.ownerId, actorId);
  const completionFilter =
    status === "open"
      ? isNull(tasks.completedAt)
      : status === "completed"
        ? isNotNull(tasks.completedAt)
        : undefined;
  return getDb()
    .select(taskColumns)
    .from(tasks)
    .where(
      and(
        ownerFilter,
        isNull(tasks.deletedAt),
        isNull(tasks.parentId),
        isNull(tasks.plannedDate),
        // project_id NULL либо собственный неархивированный проект.
        sql`(${tasks.projectId} IS NULL OR EXISTS (
          SELECT 1 FROM ${projects}
          WHERE ${projects.id} = ${tasks.projectId}
            AND ${projects.ownerId} = ${actorId}
            AND ${projects.archivedAt} IS NULL
        ))`,
        ...(completionFilter === undefined ? [] : [completionFilter]),
      ),
    )
    .orderBy(asc(tasks.sortOrder), asc(tasks.createdAt), asc(tasks.id));
}

/** Собственная не-deleted задача в любом состоянии (даты/архив проекта). */
export async function getTask(
  actorId: string,
  taskId: string,
): Promise<TaskRecord | null> {
  const rows = await getDb()
    .select(taskColumns)
    .from(tasks)
    .where(
      and(
        eq(tasks.id, taskId),
        eq(tasks.ownerId, actorId),
        isNull(tasks.deletedAt),
      ),
    )
    .limit(1);
  return rows[0] ?? null;
}

export async function createTask(
  actorId: string,
  title: string,
): Promise<TaskRecord> {
  const rows = await getDb()
    .insert(tasks)
    .values({ ownerId: actorId, title })
    .returning(taskColumns);
  const row = rows[0];
  if (!row) {
    throw new Error("Task insert returned no row.");
  }
  return row;
}

/**
 * PATCH title/completed: транзакция + row lock; см. модульный комментарий.
 * not-found — missing/foreign/конкурентно удалённая; unsupported — child/
 * recurrence; project-archived — задача архивного проекта.
 */
export async function mutateTask(
  actorId: string,
  taskId: string,
  patch: TaskPatch,
): Promise<TaskMutationOutcome> {
  return getDb().transaction(async (tx) => {
    const locked = await tx
      .select({ ...taskColumns, recurrenceRule: tasks.recurrenceRule })
      .from(tasks)
      .where(
        and(
          eq(tasks.id, taskId),
          eq(tasks.ownerId, actorId),
          isNull(tasks.deletedAt),
        ),
      )
      .for("update")
      .limit(1);
    const task = locked[0];
    if (!task) {
      return { kind: "not-found" };
    }
    if (task.parentId !== null || task.recurrenceRule !== null) {
      return { kind: "unsupported" };
    }
    if (task.projectId !== null) {
      const lockedProject = await tx
        .select({ archivedAt: projects.archivedAt })
        .from(projects)
        .where(
          and(
            eq(projects.id, task.projectId),
            eq(projects.ownerId, actorId),
          ),
        )
        .for("update")
        .limit(1);
      if (lockedProject[0] === undefined) {
        return { kind: "not-found" };
      }
      if (lockedProject[0].archivedAt !== null) {
        return { kind: "project-archived" };
      }
    }

    const titleChanged = patch.title !== undefined && patch.title !== task.title;
    const completionTransition =
      patch.completed === undefined
        ? null
        : patch.completed && task.completedAt === null
          ? "complete"
          : !patch.completed && task.completedAt !== null
            ? "reopen"
            : null;
    if (!titleChanged && completionTransition === null) {
      // Полный no-op: текущий DTO без изменения revision/timestamps.
      return {
        kind: "task",
        task: {
          id: task.id,
          title: task.title,
          projectId: task.projectId,
          parentId: task.parentId,
          completedAt: task.completedAt,
          revision: task.revision,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        },
      };
    }

    const updated = await tx
      .update(tasks)
      .set({
        title: titleChanged ? (patch.title as string) : task.title,
        // now() в PostgreSQL стабилен внутри транзакции: task.completed_at и
        // journal.completed_at получают один server timestamp (см. INSERT).
        completedAt:
          completionTransition === "complete"
            ? sql`now()`
            : completionTransition === "reopen"
              ? null
              : task.completedAt,
        revision: task.revision + 1,
        updatedAt: sql`now()`,
      })
      .where(and(eq(tasks.id, taskId), eq(tasks.ownerId, actorId)))
      .returning(taskColumns);
    const row = updated[0];
    if (!row) {
      throw new Error("Task update returned no row.");
    }
    if (completionTransition === "complete") {
      // Журнал в той же транзакции: отказ INSERT откатывает и task.
      await tx.insert(taskCompletions).values({
        ownerId: actorId,
        taskId,
        completedAt: sql`now()`,
        completedRevision: task.revision,
        idempotencyKey: randomUUID(),
        occurrenceDate: null,
      });
    }
    return { kind: "task", task: row };
  });
}

export type DeleteOutcome =
  | { kind: "deleted" }
  | { kind: "noop" }
  | { kind: "not-found" }
  | { kind: "unsupported" }
  | { kind: "project-archived" };

/**
 * DELETE: soft delete root + скрытие собственных активных direct children
 * одним timestamp (см. модульный комментарий). noop — собственная уже
 * удалённая задача (204 без изменений); not-found — foreign/unknown.
 */
export async function softDeleteTask(
  actorId: string,
  taskId: string,
): Promise<DeleteOutcome> {
  const existing = await getDb()
    .select({ deletedAt: tasks.deletedAt })
    .from(tasks)
    .where(and(eq(tasks.id, taskId), eq(tasks.ownerId, actorId)))
    .limit(1);
  if (existing[0] === undefined) {
    return { kind: "not-found" };
  }
  if (existing[0].deletedAt !== null) {
    return { kind: "noop" };
  }
  return getDb().transaction(async (tx) => {
    const locked = await tx
      .select({ ...taskColumns, recurrenceRule: tasks.recurrenceRule })
      .from(tasks)
      .where(
        and(
          eq(tasks.id, taskId),
          eq(tasks.ownerId, actorId),
          isNull(tasks.deletedAt),
        ),
      )
      .for("update")
      .limit(1);
    const task = locked[0];
    if (!task) {
      // Конкурентно удалена другим своим запросом: no-op.
      return { kind: "noop" };
    }
    if (task.parentId !== null || task.recurrenceRule !== null) {
      return { kind: "unsupported" };
    }
    if (task.projectId !== null) {
      const lockedProject = await tx
        .select({ archivedAt: projects.archivedAt })
        .from(projects)
        .where(
          and(
            eq(projects.id, task.projectId),
            eq(projects.ownerId, actorId),
          ),
        )
        .for("update")
        .limit(1);
      if (lockedProject[0] === undefined) {
        return { kind: "not-found" };
      }
      if (lockedProject[0].archivedAt !== null) {
        return { kind: "project-archived" };
      }
    }

    const updated = await tx
      .update(tasks)
      .set({ deletedAt: sql`now()`, revision: task.revision + 1, updatedAt: sql`now()` })
      .where(and(eq(tasks.id, taskId), eq(tasks.ownerId, actorId)))
      .returning({ id: tasks.id });
    if (updated[0] === undefined) {
      throw new Error("Task soft delete returned no row.");
    }
    // Собственные активные direct children скрываются тем же timestamp;
    // уже удалённые children и completion journal не меняются.
    // now() стабилен внутри транзакции: root и новые удалённые children
    // получают одинаковый server timestamp автоматически.
    await tx
      .update(tasks)
      .set({
        deletedAt: sql`now()`,
        updatedAt: sql`now()`,
        revision: sql`${tasks.revision} + 1`,
      })
      .where(
        and(
          eq(tasks.parentId, taskId),
          eq(tasks.ownerId, actorId),
          isNull(tasks.deletedAt),
        ),
      );
    return { kind: "deleted" };
  });
}
