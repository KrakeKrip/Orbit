"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { TaskItemsList } from "@/components/orbit/task-items-list";
import { useTaskWrites } from "@/components/orbit/use-task-writes";
import type { TaskDTO } from "@/lib/tasks";
import { parseTaskTitle } from "@/lib/tasks";
import { ru } from "@/lib/i18n/ru";

type TaskTab = "open" | "completed";

async function fetchInboxList(
  status: "open" | "completed",
): Promise<{ tasks: TaskDTO[]; today: string } | null> {
  const response = await fetch(`/api/v1/tasks?view=inbox&status=${status}`);
  if (!response.ok) {
    return null;
  }
  try {
    const payload = (await response.json()) as {
      tasks?: TaskDTO[];
      context?: { today?: string };
    };
    if (!Array.isArray(payload.tasks)) {
      return null;
    }
    return {
      tasks: payload.tasks,
      today: typeof payload.context?.today === "string" ? payload.context.today : "",
    };
  } catch {
    return null;
  }
}

/**
 * Реальный экран Входящих (TASK-007 + TASK-008 планирование): quick-add,
 * переименование, завершение/переоткрытие, soft delete с подтверждением и
 * планирование (дата/время/дедлайн) через общий shared row и единый хук
 * task-мутаций. Подтверждение только по server response + перечитывание
 * обоих списков и read context. Инварианты: R1 — сбой чтения после
 * подтверждённой записи это read error/retry (GET-only), а не failed
 * write; R2 — pending блокирует конфликты (никакой второй mutation);
 * R3/R3b — delete confirmation focus/Escape; stale callbacks подавлены
 * (mounted/actor/requestSeq, StrictMode-симметрично). Записи прежнего
 * actor клиентом не отменяются.
 */
export function TasksView({
  initialOpen,
  initialCompleted,
  actorId,
  today: initialToday,
}: {
  initialOpen: TaskDTO[];
  initialCompleted: TaskDTO[];
  actorId: string;
  /** Server context today (account timezone) для deadline-бейджей. */
  today: string;
}) {
  const [lists, setLists] = useState({
    open: initialOpen,
    completed: initialCompleted,
  });
  const [contextToday, setContextToday] = useState(initialToday);
  const [tab, setTab] = useState<TaskTab>("open");
  const [listError, setListError] = useState(false);
  const [listPending, setListPending] = useState(false);

  const [createDraft, setCreateDraft] = useState("");
  const [createPending, setCreatePending] = useState(false);
  const [createInvalid, setCreateInvalid] = useState(false);
  const [createError, setCreateError] = useState(false);

  const mountedRef = useRef(true);
  const actorRef = useRef(actorId);
  const requestSeqRef = useRef(0);
  const createInFlight = useRef(false);

  useEffect(() => {
    actorRef.current = actorId;
  }, [actorId]);
  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const onConfirmed = useCallback(async (): Promise<boolean> => {
    const requestedActorId = actorRef.current;
    setListPending(true);
    const requestSeq = ++requestSeqRef.current;
    try {
      const [open, completed] = await Promise.all([
        fetchInboxList("open"),
        fetchInboxList("completed"),
      ]);
      if (
        !mountedRef.current ||
        actorRef.current !== requestedActorId ||
        requestSeq !== requestSeqRef.current
      ) {
        return false;
      }
      if (open === null || completed === null) {
        setListError(true);
        return false;
      }
      setLists({ open: open.tasks, completed: completed.tasks });
      if (open.today !== "") {
        setContextToday(open.today);
      }
      setListError(false);
      return true;
    } catch {
      if (mountedRef.current && actorRef.current === requestedActorId) {
        setListError(true);
      }
      return false;
    } finally {
      if (mountedRef.current && actorRef.current === requestedActorId) {
        setListPending(false);
      }
    }
  }, []);

  const writes = useTaskWrites({
    actorId,
    createFocusElementId: "task-title-input",
    onConfirmed,
  });

  const handleCreate = useCallback(async (): Promise<void> => {
    if (createInFlight.current || writes.anyInFlight()) {
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
    const requestedActorId = actorRef.current;
    try {
      const response = await fetch("/api/v1/tasks", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ title: parsed.title }),
      });
      if (!mountedRef.current || actorRef.current !== requestedActorId) {
        return;
      }
      if (response.ok) {
        // Create подтверждён: draft очищен; сбой последующего чтения —
        // read error с retry (GET-only), не failed create (R1).
        setCreateDraft("");
        await onConfirmed();
        return;
      }
      setCreateError(true);
    } catch {
      if (mountedRef.current && actorRef.current === requestedActorId) {
        setCreateError(true);
      }
    } finally {
      createInFlight.current = false;
      if (mountedRef.current && actorRef.current === requestedActorId) {
        setCreatePending(false);
      }
    }
  }, [createDraft, writes, onConfirmed]);

  const visibleTasks = tab === "open" ? lists.open : lists.completed;

  return (
    <div>
      <form
        className="rounded-xl border bg-card p-4"
        aria-busy={createPending}
        onSubmit={(event) => {
          event.preventDefault();
          void handleCreate();
        }}
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
          <Button
            type="button"
            variant="outline"
            className="min-h-11 px-4"
            onClick={() => void onConfirmed()}
            disabled={listPending}
            id="inbox-refresh-button"
          >
            {listPending ? ru.tasks.refreshing : ru.tasks.refresh}
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
            onClick={() => void onConfirmed()}
            disabled={listPending}
          >
            {ru.tasks.retry}
          </Button>
        </div>
      ) : null}

      <div className="mt-4">
        <TaskItemsList
          tasks={visibleTasks}
          today={contextToday}
          completedMode={tab === "completed"}
          writes={writes}
          emptyState={
            tab === "open" ? ru.pages.inbox.empty : ru.tasks.completedEmpty
          }
        />
      </div>
    </div>
  );
}
