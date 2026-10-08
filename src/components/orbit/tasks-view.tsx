"use client";

import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { FolderOpen } from "lucide-react";
import { EmptyView } from "@/components/orbit/empty-view";
import type { TaskDTO } from "@/lib/tasks";
import { parseTaskTitle } from "@/lib/tasks";
import { ru } from "@/lib/i18n/ru";

type TaskTab = "open" | "completed";

type TaskLists = {
  open: TaskDTO[];
  completed: TaskDTO[];
};

async function fetchList(status: "open" | "completed"): Promise<TaskDTO[] | null> {
  const response = await fetch(`/api/v1/tasks?status=${status}`);
  if (!response.ok) {
    return null;
  }
  const payload = (await response.json()) as { tasks?: TaskDTO[] };
  return Array.isArray(payload.tasks) ? payload.tasks : null;
}

/**
 * Реальный экран Входящих (TASK-007): quick-add, переименование,
 * завершение/переоткрытие и soft delete с подтверждением — только по
 * подтверждённому server response с последующим обновлением обоих списков.
 * Оптимистичных записей нет: failed mutation сохраняет строку/draft без
 * ложного успеха. Имя задачи — текст.
 *
 * Pending блокирует double submit и переключение редактора; долгий
 * запрос одной строки не закрывает редактор другой (rename триггеры чужих
 * строк заблокированы на время rename pending — инвариант TASK-006/R2).
 * Lifecycle/actor guard (TASK-005): завершения после unmount/смены actor
 * игнорируются целиком; mounted-эффект симметричен — StrictMode replay в
 * next dev не ломает обработку ответов. Серверные записи прежнего actor
 * клиент не отменяет.
 */
export function TasksView({
  initialOpen,
  initialCompleted,
  actorId,
}: {
  initialOpen: TaskDTO[];
  initialCompleted: TaskDTO[];
  actorId: string;
}) {
  const [lists, setLists] = useState<TaskLists>({
    open: initialOpen,
    completed: initialCompleted,
  });
  const [tab, setTab] = useState<TaskTab>("open");
  const [listError, setListError] = useState(false);
  const [listPending, setListPending] = useState(false);

  const [createDraft, setCreateDraft] = useState("");
  const [createPending, setCreatePending] = useState(false);
  const [createInvalid, setCreateInvalid] = useState(false);
  const [createError, setCreateError] = useState(false);

  const [renameId, setRenameId] = useState<string | null>(null);
  const [renameDraft, setRenameDraft] = useState("");
  const [renamePending, setRenamePending] = useState(false);
  const [renameInvalid, setRenameInvalid] = useState(false);
  const [renameError, setRenameError] = useState(false);
  const [renameFocusTarget, setRenameFocusTarget] = useState<{
    id: string;
    nonce: number;
  } | null>(null);

  const [togglePendingId, setTogglePendingId] = useState<string | null>(null);
  const [toggleError, setToggleError] = useState<string | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [deletePendingId, setDeletePendingId] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  // R3 фокус confirmation: при открытии — безопасная «Отмена»; при
  // отмене/Escape — trigger строки; после успешного удаления — quick-add.
  // Новый объект на каждый переход перезапускает эффект; сам эффект только
  // фокусирует DOM-узел (StrictMode-идемпотентно, без setState).
  const [deleteFocus, setDeleteFocus] = useState<{
    target: "cancel" | "trigger" | "create";
    id: string;
    nonce: number;
  } | null>(null);

  const mountedRef = useRef(true);
  const actorRef = useRef(actorId);
  const createInFlight = useRef(false);
  const renameInFlight = useRef(false);
  const toggleInFlight = useRef(false);
  const deleteInFlight = useRef(false);
  const focusNonceRef = useRef(0);

  useEffect(() => {
    actorRef.current = actorId;
  }, [actorId]);
  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);
  useEffect(() => {
    if (renameFocusTarget === null) {
      return;
    }
    document.getElementById(`task-rename-trigger-${renameFocusTarget.id}`)?.focus();
  }, [renameFocusTarget]);
  useEffect(() => {
    if (deleteFocus === null) {
      return;
    }
    if (deleteFocus.target === "create") {
      document.getElementById("task-title-input")?.focus();
      return;
    }
    const elementId =
      deleteFocus.target === "cancel"
        ? `task-delete-cancel-${deleteFocus.id}`
        : `task-delete-trigger-${deleteFocus.id}`;
    document.getElementById(elementId)?.focus();
  }, [deleteFocus]);

  async function refreshLists(): Promise<boolean> {
    const requestedActorId = actorRef.current;
    setListPending(true);
    try {
      const [open, completed] = await Promise.all([
        fetchList("open"),
        fetchList("completed"),
      ]);
      if (!mountedRef.current || actorRef.current !== requestedActorId) {
        return false;
      }
      if (open === null || completed === null) {
        // Read failure: подтверждённые mutation не переклассифицируются —
        // показывается read error с retry (retry выполняет только GET).
        setListError(true);
        return false;
      }
      setLists({ open, completed });
      setListError(false);
      return true;
    } catch {
      // Network/JSON rejection чтения — контролируемый outcome, не
      // unhandled rejection и не отказ уже успешной mutation.
      if (mountedRef.current && actorRef.current === requestedActorId) {
        setListError(true);
      }
      return false;
    } finally {
      if (mountedRef.current && actorRef.current === requestedActorId) {
        setListPending(false);
      }
    }
  }

  async function handleCreate(): Promise<void> {
    if (createInFlight.current) {
      return;
    }
    const parsed = parseTaskTitle(createDraft);
    if (!parsed.ok) {
      setCreateInvalid(true);
      setCreateError(false);
      return;
    }
    setCreateInvalid(false);
    setCreateError(false);
    setCreatePending(true);
    createInFlight.current = true;
    try {
      const response = await fetch("/api/v1/tasks", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ title: parsed.title }),
      });
      if (!mountedRef.current) {
        return;
      }
      if (response.ok) {
        setCreateDraft("");
        await refreshLists();
        return;
      }
      setCreateError(true);
    } catch {
      if (mountedRef.current) {
        setCreateError(true);
      }
    } finally {
      createInFlight.current = false;
      if (mountedRef.current) {
        setCreatePending(false);
      }
    }
  }

  function openRename(project: TaskDTO): void {
    // Пока не завершился любой другой mutation, новый editor не
    // открывается: поздний ответ прежнего запроса не должен закрыть/поменять
    // новую форму (TASK-006/R2 и R2 этого раунда).
    if (
      renamePending ||
      renameInFlight.current ||
      toggleInFlight.current ||
      deleteInFlight.current
    ) {
      return;
    }
    setDeleteConfirmId(null);
    setRenameId(project.id);
    setRenameDraft(project.title);
    setRenameInvalid(false);
    setRenameError(false);
  }

  function closeRename(taskId: string): void {
    setRenameId(null);
    setRenameDraft("");
    // Строка пересоздаётся после редактирования: фокус возвращается к
    // новому узлу после коммита (renameFocusTarget effect).
    focusNonceRef.current += 1;
    setRenameFocusTarget({ id: taskId, nonce: focusNonceRef.current });
  }

  async function handleRenameSubmit(): Promise<void> {
    if (
      renameInFlight.current ||
      toggleInFlight.current ||
      deleteInFlight.current ||
      renameId === null
    ) {
      return;
    }
    const parsed = parseTaskTitle(renameDraft);
    if (!parsed.ok) {
      setRenameInvalid(true);
      setRenameError(false);
      return;
    }
    setRenameInvalid(false);
    setRenameError(false);
    setRenamePending(true);
    renameInFlight.current = true;
    const renameTargetId = renameId;
    try {
      const response = await fetch(`/api/v1/tasks/${renameTargetId}`, {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ title: parsed.title }),
      });
      if (!mountedRef.current) {
        return;
      }
      if (response.ok) {
        closeRename(renameTargetId);
        // Сбой чтения после успешного rename — read error/retry, не отказ
        // rename (обновлённое имя уже подтверждено сервером).
        await refreshLists();
        return;
      }
      setRenameError(true);
    } catch {
      if (mountedRef.current) {
        setRenameError(true);
      }
    } finally {
      renameInFlight.current = false;
      if (mountedRef.current) {
        setRenamePending(false);
      }
    }
  }

  async function handleToggle(task: TaskDTO): Promise<void> {
    // R2: повторный toggle и конфликтующие действия других строк/редактора
    // не запускаются, пока completion/reopen в полёте.
    if (
      toggleInFlight.current ||
      renameInFlight.current ||
      deleteInFlight.current
    ) {
      return;
    }
    setToggleError(null);
    setTogglePendingId(task.id);
    toggleInFlight.current = true;
    try {
      const response = await fetch(`/api/v1/tasks/${task.id}`, {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ completed: task.completedAt === null }),
      });
      if (!mountedRef.current) {
        return;
      }
      if (response.ok) {
        await refreshLists();
        return;
      }
      setToggleError(
        task.completedAt === null
          ? ru.tasks.complete.errorOpen
          : ru.tasks.complete.errorCompleted,
      );
    } catch {
      if (mountedRef.current) {
        setToggleError(
          task.completedAt === null
            ? ru.tasks.complete.errorOpen
            : ru.tasks.complete.errorCompleted,
        );
      }
    } finally {
      toggleInFlight.current = false;
      if (mountedRef.current) {
        setTogglePendingId(null);
      }
    }
  }

  function openDeleteConfirm(task: TaskDTO): void {
    // R2: destructive confirmation не открывается во время любого другого
    // pending; R3: фокус уходит в confirmation (безопасная «Отмена»).
    if (
      deleteInFlight.current ||
      renameInFlight.current ||
      toggleInFlight.current ||
      renamePending
    ) {
      return;
    }
    setRenameId(null);
    setDeleteConfirmId(task.id);
    setDeleteError(null);
    focusNonceRef.current += 1;
    setDeleteFocus({
      target: "cancel",
      id: task.id,
      nonce: focusNonceRef.current,
    });
  }

  function cancelDelete(taskId: string): void {
    // Pending policy: отмена во время удаления не нарушает state handling.
    if (deletePendingId === taskId) {
      return;
    }
    setDeleteConfirmId(null);
    focusNonceRef.current += 1;
    setDeleteFocus({
      target: "trigger",
      id: taskId,
      nonce: focusNonceRef.current,
    });
  }

  async function handleDelete(task: TaskDTO): Promise<void> {
    if (
      deleteInFlight.current ||
      renameInFlight.current ||
      toggleInFlight.current
    ) {
      return;
    }
    setDeleteError(null);
    setDeletePendingId(task.id);
    deleteInFlight.current = true;
    try {
      const response = await fetch(`/api/v1/tasks/${task.id}`, {
        method: "DELETE",
      });
      if (!mountedRef.current) {
        return;
      }
      if (response.ok) {
        setDeleteConfirmId(null);
        await refreshLists();
        // Логичный следующий control после успешного удаления — quick-add.
        if (mountedRef.current) {
          focusNonceRef.current += 1;
          setDeleteFocus({
            target: "create",
            id: task.id,
            nonce: focusNonceRef.current,
          });
        }
        return;
      }
      setDeleteError(ru.tasks.delete.error);
    } catch {
      if (mountedRef.current) {
        setDeleteError(ru.tasks.delete.error);
      }
    } finally {
      deleteInFlight.current = false;
      if (mountedRef.current) {
        setDeletePendingId(null);
      }
    }
  }

  const visibleTasks = tab === "open" ? lists.open : lists.completed;
  const busy = renamePending || togglePendingId !== null || deletePendingId !== null;

  return (
    <div>
      <form
        className="rounded-xl border bg-card p-4"
        onSubmit={(event) => {
          event.preventDefault();
          void handleCreate();
        }}
        aria-busy={createPending}
      >
        <Label htmlFor="task-title-input">{ru.tasks.create.label}</Label>
        <div className="mt-3 flex flex-col gap-2 sm:flex-row sm:items-center">
          <Input
            id="task-title-input"
            name="title"
            type="text"
            autoComplete="off"
            className="min-h-11 max-w-72"
            placeholder={ru.tasks.create.placeholder}
            value={createDraft}
            onChange={(event) => {
              setCreateDraft(event.target.value);
              if (createInvalid) {
                setCreateInvalid(false);
              }
            }}
            aria-invalid={createInvalid || undefined}
            aria-describedby="task-create-status"
            disabled={createPending}
          />
          <Button type="submit" className="min-h-11 px-4" disabled={createPending}>
            {createPending ? ru.tasks.create.submitting : ru.tasks.create.submit}
          </Button>
        </div>
        <p
          id="task-create-status"
          aria-live="polite"
          className="mt-2 text-sm leading-5"
        >
          {createInvalid ? (
            <span role="alert" className="text-destructive">
              {ru.tasks.create.invalid}
            </span>
          ) : createError ? (
            <span role="alert" className="text-destructive">
              {ru.tasks.create.error}
            </span>
          ) : null}
        </p>
      </form>

      <div className="mt-4 flex gap-2" role="group" aria-label={ru.nav.inbox}>
        {(["open", "completed"] as const).map((value) => (
          <Button
            key={value}
            type="button"
            variant={tab === value ? "default" : "outline"}
            aria-pressed={tab === value}
            className="min-h-11 px-4"
            onClick={() => setTab(value)}
          >
            {value === "open" ? ru.tasks.tabs.open : ru.tasks.tabs.completed}
          </Button>
        ))}
      </div>

      {listError ? (
        <div className="mt-4 rounded-xl border bg-card p-4">
          <p role="alert" className="text-sm text-destructive">
            {ru.tasks.listError}
          </p>
          <Button
            type="button"
            variant="outline"
            className="mt-2 min-h-11 px-4"
            onClick={() => void refreshLists()}
            disabled={listPending}
          >
            {ru.tasks.retry}
          </Button>
        </div>
      ) : null}

      {visibleTasks.length === 0 ? (
        <div className="mt-4">
          <EmptyView
            icon={FolderOpen}
            title={
              tab === "open"
                ? ru.pages.inbox.empty.title
                : ru.tasks.completedEmpty.title
            }
            description={
              tab === "open"
                ? ru.pages.inbox.empty.description
                : ru.tasks.completedEmpty.description
            }
          />
        </div>
      ) : (
        <ul className="mt-4 flex flex-col gap-2">
          {visibleTasks.map((task) => {
            const renameOpen = renameId === task.id;
            const completed = task.completedAt !== null;
            const togglePending = togglePendingId === task.id;
            const deletePending = deletePendingId === task.id;
            return (
              <li
                key={task.id}
                className="rounded-xl border bg-card p-4"
                data-task-id={task.id}
              >
                {renameOpen ? (
                  <form
                    onSubmit={(event) => {
                      event.preventDefault();
                      void handleRenameSubmit();
                    }}
                    aria-busy={renamePending}
                  >
                    <Label htmlFor={`task-rename-input-${task.id}`}>
                      {ru.tasks.rename.action}
                    </Label>
                    <div className="mt-2 flex flex-col gap-2 sm:flex-row sm:items-center">
                      <Input
                        id={`task-rename-input-${task.id}`}
                        type="text"
                        autoComplete="off"
                        className="min-h-11 max-w-72"
                        value={renameDraft}
                        onChange={(event) => {
                          setRenameDraft(event.target.value);
                          if (renameInvalid) {
                            setRenameInvalid(false);
                          }
                        }}
                        aria-invalid={renameInvalid || undefined}
                        disabled={renamePending}
                      />
                      <Button
                        type="submit"
                        className="min-h-11 px-4"
                        disabled={renamePending}
                      >
                        {renamePending
                          ? ru.tasks.rename.saving
                          : ru.tasks.rename.save}
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="min-h-11 px-4"
                        onClick={() => closeRename(task.id)}
                        disabled={renamePending}
                      >
                        {ru.tasks.rename.cancel}
                      </Button>
                    </div>
                    <p aria-live="polite" className="mt-2 text-sm leading-5">
                      {renameInvalid ? (
                        <span role="alert" className="text-destructive">
                          {ru.tasks.rename.invalid}
                        </span>
                      ) : renameError ? (
                        <span role="alert" className="text-destructive">
                          {ru.tasks.rename.error}
                        </span>
                      ) : null}
                    </p>
                  </form>
                ) : deleteConfirmId === task.id ? (
                  <div
                    role="alert"
                    aria-live="assertive"
                    onKeyDown={(event) => {
                      // R3: Escape до отправки DELETE отменяет подтверждение
                      // и возвращает фокус к trigger строки.
                      if (event.key === "Escape" && !deletePending) {
                        event.preventDefault();
                        cancelDelete(task.id);
                      }
                    }}
                  >
                    <p className="text-sm font-medium leading-6">
                      {ru.tasks.delete.confirmTitle}
                    </p>
                    <p className="break-words text-sm text-muted-foreground">
                      {task.title}
                    </p>
                    <div className="mt-3 flex gap-2">
                      <Button
                        type="button"
                        variant="destructive"
                        className="min-h-11 px-4"
                        onClick={() => void handleDelete(task)}
                        disabled={deletePending}
                      >
                        {deletePending
                          ? ru.tasks.delete.pending
                          : ru.tasks.delete.confirm}
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        id={`task-delete-cancel-${task.id}`}
                        className="min-h-11 px-4"
                        onClick={() => cancelDelete(task.id)}
                        disabled={deletePending}
                      >
                        {ru.tasks.delete.cancel}
                      </Button>
                    </div>
                    {deleteError !== null && !deletePending ? (
                      <p role="alert" className="mt-2 text-sm text-destructive">
                        {deleteError}
                      </p>
                    ) : null}
                  </div>
                ) : (
                  <>
                    <p
                      className={`break-words text-sm font-medium leading-6 ${
                        completed ? "text-muted-foreground line-through" : ""
                      }`}
                    >
                      {task.title}
                    </p>
                    <div className="mt-3 flex flex-wrap gap-2">
                      <Button
                        type="button"
                        variant="outline"
                        className="min-h-11 px-4"
                        onClick={() => void handleToggle(task)}
                        disabled={busy}
                      >
                        {togglePending
                          ? completed
                            ? ru.tasks.complete.pendingCompleted
                            : ru.tasks.complete.pendingOpen
                          : completed
                            ? ru.tasks.complete.reopen
                            : ru.tasks.complete.action}
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        id={`task-rename-trigger-${task.id}`}
                        className="min-h-11 px-4"
                        onClick={() => openRename(task)}
                        disabled={busy}
                      >
                        {ru.tasks.rename.action}
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        id={`task-delete-trigger-${task.id}`}
                        className="min-h-11 px-4"
                        onClick={() => openDeleteConfirm(task)}
                        disabled={busy}
                      >
                        {ru.tasks.delete.action}
                      </Button>
                    </div>
                    {toggleError !== null && togglePendingId === null ? (
                      <p role="alert" className="mt-2 text-sm text-destructive">
                        {toggleError}
                      </p>
                    ) : null}
                  </>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
