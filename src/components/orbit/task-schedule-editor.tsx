"use client";

import { useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { TaskPlanningValues } from "@/lib/tasks";
import { parseCivilDate, parseCivilTime } from "@/lib/calendar";
import { ru } from "@/lib/i18n/ru";

export type TaskScheduleSnapshot = TaskPlanningValues;

export type TaskScheduleDraftPatch = Partial<TaskPlanningValues>;

/**
 * Небольшой планировочный редактор (TASK-008): дата выполнения, время,
 * дедлайн. Save отправляет только реально изменённые поля относительно
 * snapshot задачи (dirty-подмножество), no-op — Save disabled. Snapshot
 * фиксируется на момент конкретного открытия (R1): refetch при открытом
 * редакторе обновляет prop, но не превращает чужие изменения в
 * пользовательские — dirty/PATCH считаются от исходного snapshot; Cancel
 * и новое открытие берут snapshot заново из актуального task. Очистка
 * даты очищает draft time и блокирует его. Ошибка сохранения сохраняет
 * draft; pending блокирует ввод/отмену/сохранение. Focus: при открытии —
 * первое поле (autofocus по id из parent), при ошибке поле остаётся.
 */
export function TaskScheduleEditor({
  snapshot,
  pending,
  error,
  dateInputId,
  onSave,
  onCancel,
}: {
  snapshot: TaskScheduleSnapshot;
  pending: boolean;
  error: string | null;
  /** id первого поля (для focus из parent). */
  dateInputId: string;
  onSave: (patch: TaskScheduleDraftPatch) => void;
  onCancel: () => void;
}) {
  // R1: snapshot неизменен до закрытия. Редактор монтируется только пока
  // открыт, поэтому useState фиксирует значения открытия; последующие
  // refetch'и меняют prop, но не базу dirty-сравнения — чужие поля не
  // попадают в PATCH, draft не теряется. Cancel/reopen — новый snapshot.
  const [openingSnapshot] = useState<TaskScheduleSnapshot>(snapshot);
  const [dateDraft, setDateDraft] = useState(openingSnapshot.plannedDate ?? "");
  const [timeDraft, setTimeDraft] = useState(openingSnapshot.plannedTime ?? "");
  const [deadlineDraft, setDeadlineDraft] = useState(
    openingSnapshot.deadlineDate ?? "",
  );
  const [invalid, setInvalid] = useState(false);

  const normalized = useMemo(
    () => ({
      plannedDate: dateDraft === "" ? null : dateDraft,
      plannedTime: dateDraft === "" || timeDraft === "" ? null : timeDraft,
      deadlineDate: deadlineDraft === "" ? null : deadlineDraft,
    }),
    [dateDraft, timeDraft, deadlineDraft],
  );

  const dirty =
    normalized.plannedDate !== openingSnapshot.plannedDate ||
    normalized.plannedTime !== openingSnapshot.plannedTime ||
    normalized.deadlineDate !== openingSnapshot.deadlineDate;

  // Валидность: заполненные поля — корректные civil значения; time требует date.
  const valid =
    (dateDraft === "" || parseCivilDate(dateDraft).ok) &&
    (timeDraft === "" || parseCivilTime(timeDraft).ok) &&
    (deadlineDraft === "" || parseCivilDate(deadlineDraft).ok) &&
    (normalized.plannedTime === null || normalized.plannedDate !== null);

  function handleSubmit(): void {
    if (pending) {
      return;
    }
    if (!valid || !dirty) {
      setInvalid(true);
      return;
    }
    setInvalid(false);
    // Только dirty-поля относительно snapshot открытия.
    const patch: TaskScheduleDraftPatch = {};
    if (normalized.plannedDate !== openingSnapshot.plannedDate) {
      patch.plannedDate = normalized.plannedDate;
    }
    if (normalized.plannedTime !== openingSnapshot.plannedTime) {
      patch.plannedTime = normalized.plannedTime;
    }
    if (normalized.deadlineDate !== openingSnapshot.deadlineDate) {
      patch.deadlineDate = normalized.deadlineDate;
    }
    onSave(patch);
  }

  return (
    <form
      className="mt-2 rounded-lg border bg-background p-3"
      aria-busy={pending}
      onSubmit={(event) => {
        event.preventDefault();
        handleSubmit();
      }}
      onKeyDown={(event) => {
        if (event.key === "Escape" && !pending) {
          event.preventDefault();
          onCancel();
        }
      }}
    >
      <div className="grid gap-3 sm:grid-cols-3">
        <div>
          <Label htmlFor={dateInputId}>{ru.tasks.schedule.plannedDate}</Label>
          <Input
            id={dateInputId}
            type="date"
            min="1900-01-01"
            max="2199-12-31"
            autoComplete="off"
            className="mt-1 min-h-11"
            value={dateDraft}
            onChange={(event) => {
              setDateDraft(event.target.value);
              if (event.target.value === "") {
                // Очистка даты очищает draft time (контракт clearing plan).
                setTimeDraft("");
              }
              if (invalid) {
                setInvalid(false);
              }
            }}
            disabled={pending}
          />
        </div>
        <div>
          <Label htmlFor={`${dateInputId}-time`}>
            {ru.tasks.schedule.plannedTime}
          </Label>
          <Input
            id={`${dateInputId}-time`}
            type="time"
            autoComplete="off"
            className="mt-1 min-h-11"
            value={timeDraft}
            onChange={(event) => setTimeDraft(event.target.value)}
            disabled={pending || dateDraft === ""}
            title={
              dateDraft === "" ? ru.tasks.schedule.timeNeedsDate : undefined
            }
          />
        </div>
        <div>
          <Label htmlFor={`${dateInputId}-deadline`}>
            {ru.tasks.schedule.deadlineDate}
          </Label>
          <Input
            id={`${dateInputId}-deadline`}
            type="date"
            min="1900-01-01"
            max="2199-12-31"
            autoComplete="off"
            className="mt-1 min-h-11"
            value={deadlineDraft}
            onChange={(event) => {
              setDeadlineDraft(event.target.value);
              if (invalid) {
                setInvalid(false);
              }
            }}
            disabled={pending}
          />
        </div>
      </div>
      <p className="mt-1 text-xs leading-4 text-muted-foreground">
        {ru.tasks.schedule.clearHint}
      </p>
      <div className="mt-2 flex gap-2">
        <Button type="submit" className="min-h-11 px-4" disabled={pending || !dirty || !valid}>
          {pending ? ru.tasks.schedule.saving : ru.tasks.schedule.save}
        </Button>
        <Button
          type="button"
          variant="outline"
          className="min-h-11 px-4"
          onClick={onCancel}
          disabled={pending}
        >
          {ru.tasks.schedule.cancel}
        </Button>
      </div>
      <p aria-live="polite" className="mt-2 text-sm leading-5">
        {invalid ? (
          <span role="alert" className="text-destructive">
            {ru.tasks.schedule.invalid}
          </span>
        ) : error !== null ? (
          <span role="alert" className="text-destructive">
            {error}
          </span>
        ) : null}
      </p>
    </form>
  );
}
