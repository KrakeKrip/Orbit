import type { TaskDTO } from "./tasks";

/**
 * Чистые view-model helpers для Today/Upcoming (TASK-008): группировка и
 * сортировка внутри секций. Входные списки уже owner-scoped/filtered и
 * отсортированы стабильно (sort_order/created_at/id) сервером; JS sort
 * стабилен, поэтому tie-break наследуется от входного порядка.
 */

export type TodaySectionKey =
  | "planOverdue"
  | "planToday"
  | "deadlineOverdue"
  | "deadlineToday";

export type TodaySection = {
  rank: 1 | 2 | 3 | 4;
  key: TodaySectionKey;
  tasks: TaskDTO[];
};

/**
 * Взаимоисключающая секция задачи на Today: каждая task максимум в одной
 * секции по приоритету plan<today → plan=today → deadline<today →
 * deadline=today. null — не входит в Today (future/undated вне deadline).
 */
export function todaySectionOf(
  task: TaskDTO,
  today: string,
): 1 | 2 | 3 | 4 | null {
  if (task.plannedDate !== null && task.plannedDate < today) {
    return 1;
  }
  if (task.plannedDate !== null && task.plannedDate === today) {
    return 2;
  }
  if (task.deadlineDate !== null && task.deadlineDate < today) {
    return 3;
  }
  if (task.deadlineDate !== null && task.deadlineDate === today) {
    return 4;
  }
  return null;
}

function compareCivilAsc(a: string, b: string): number {
  if (a === b) {
    return 0;
  }
  return a < b ? -1 : 1;
}

function byPlannedDateTimeThenStable(a: TaskDTO, b: TaskDTO): number {
  const date = compareCivilAsc(a.plannedDate ?? "", b.plannedDate ?? "");
  if (date !== 0) {
    return date;
  }
  // NULLS LAST
  if (a.plannedTime === null && b.plannedTime !== null) {
    return 1;
  }
  if (a.plannedTime !== null && b.plannedTime === null) {
    return -1;
  }
  if (a.plannedTime !== null && b.plannedTime !== null && a.plannedTime !== b.plannedTime) {
    return a.plannedTime < b.plannedTime ? -1 : 1;
  }
  return 0;
}

function byPlannedTimeThenStable(a: TaskDTO, b: TaskDTO): number {
  if (a.plannedTime === null && b.plannedTime !== null) {
    return 1;
  }
  if (a.plannedTime !== null && b.plannedTime === null) {
    return -1;
  }
  if (a.plannedTime !== null && b.plannedTime !== null && a.plannedTime !== b.plannedTime) {
    return a.plannedTime < b.plannedTime ? -1 : 1;
  }
  return 0;
}

function byDeadlineThenStable(a: TaskDTO, b: TaskDTO): number {
  const deadline = compareCivilAsc(a.deadlineDate ?? "", b.deadlineDate ?? "");
  if (deadline !== 0) {
    return deadline;
  }
  return 0;
}

const SECTION_KEYS: TodaySectionKey[] = [
  "planOverdue",
  "planToday",
  "deadlineOverdue",
  "deadlineToday",
];

/**
 * Четыре взаимоисключающие секции Today по приоритету 1..4; каждая task
 * ровно один раз. Сортировки внутри секций — по контракту (plannedDate/
 * time NULLS LAST/deadline + стабильный tie-break из входного порядка).
 */
export function groupTodayTasks(
  tasks: TaskDTO[],
  today: string,
): TodaySection[] {
  const sections: TodaySection[] = SECTION_KEYS.map((key, index) => ({
    rank: (index + 1) as 1 | 2 | 3 | 4,
    key,
    tasks: [],
  }));
  for (const task of tasks) {
    const rank = todaySectionOf(task, today);
    if (rank !== null) {
      sections[rank - 1].tasks.push(task);
    }
  }
  for (const section of sections) {
    if (section.rank === 1) {
      section.tasks.sort(byPlannedDateTimeThenStable);
    } else if (section.rank === 2) {
      section.tasks.sort(byPlannedTimeThenStable);
    } else if (section.rank === 3) {
      section.tasks.sort(byDeadlineThenStable);
    }
    // rank 4: стабильный порядок входа.
  }
  return sections.filter((section) => section.key !== undefined);
}

export type UpcomingDayGroup = {
  date: string;
  tasks: TaskDTO[];
};

/**
 * Группировка Upcoming по plannedDate в инклюзивном диапазоне
 * [startDate..endDate]; ровно (дней в диапазоне) групп, даже если день
 * пуст; сортировка внутри группы plannedTime ASC NULLS LAST + stable.
 * Deadline-only задачи в диапазон не попадают (plannedDate null).
 */
export function groupUpcomingTasks(
  tasks: TaskDTO[],
  startDate: string,
  endDate: string,
): UpcomingDayGroup[] {
  const groups: UpcomingDayGroup[] = [];
  const byDate = new Map<string, TaskDTO[]>();
  for (const task of tasks) {
    if (
      task.plannedDate === null ||
      task.plannedDate < startDate ||
      task.plannedDate > endDate
    ) {
      continue;
    }
    const bucket = byDate.get(task.plannedDate);
    if (bucket === undefined) {
      byDate.set(task.plannedDate, [task]);
    } else {
      bucket.push(task);
    }
  }
  let cursor = startDate;
  while (cursor <= endDate) {
    groups.push({ date: cursor, tasks: byDate.get(cursor) ?? [] });
    const next = addOneCivilDay(cursor);
    if (next === null) {
      break;
    }
    cursor = next;
  }
  for (const group of groups) {
    group.tasks.sort(byPlannedTimeThenStable);
  }
  return groups;
}

function addOneCivilDay(date: string): string | null {
  const year = Number(date.slice(0, 4));
  const month = Number(date.slice(5, 7));
  const day = Number(date.slice(8, 10));
  const shifted = new Date(Date.UTC(year, month - 1, day + 1));
  const value = `${String(shifted.getUTCFullYear()).padStart(4, "0")}-${String(
    shifted.getUTCMonth() + 1,
  ).padStart(2, "0")}-${String(shifted.getUTCDate()).padStart(2, "0")}`;
  if (value > "2199-12-31") {
    return null;
  }
  return value;
}
