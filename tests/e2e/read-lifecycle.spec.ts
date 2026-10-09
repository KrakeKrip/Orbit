import { expect, test } from "@playwright/test";

// Владелец fixtures — пользователь C: сессию никто не ревокирует; чистые
// mode reads Upcoming без активных форм/writes.
const USER_C_STATE = "test-results/.auth/user-c.json";
const run = `t8r3-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

// TASK-008-R3a browser: устаревший read не меняет tasks/context/error/
// pending нового read — guards после каждого await (fetch, JSON parsing),
// в catch и finally. Синхронизация по delivery (expect.poll)/событиям,
// без sleeps; тестовый fetch-обёртка только в тесте 3 и восстанавливается.
test.describe.configure({ mode: "default" });

test.describe("Read lifecycle (R3a, Upcoming desktop 1280)", () => {
  test.use({ viewport: { width: 1280, height: 800 }, storageState: USER_C_STATE });

  test("R3a: старый abort после успешного нового read без ошибки; последний failed read показывает error/retry", async ({
    page,
  }) => {
    const { openTitle, completedTitle, today } = await seedUpcomingFixtures(page, "abort");
    await page.goto(`/upcoming?start=${today}`);
    const openRow = page.locator("li[data-task-id]", { hasText: openTitle });
    const completedRow = page.locator("li[data-task-id]", {
      hasText: completedTitle,
    });
    const listError = page.getByText("Не удалось обновить список задач.");
    const retry = page.getByRole("button", { name: "Повторить" });

    // Удержание GET status=completed; старый запрос будет прерван.
    let completedHeld = 0;
    let failNextGet = false;
    let abortCompleted = false;
    let releaseCompleted!: () => void;
    const completedGate = new Promise<void>((resolve) => {
      releaseCompleted = resolve;
    });
    await page.route("**/api/v1/tasks*", async (route) => {
      const request = route.request();
      if (
        request.method() !== "GET" ||
        !request.url().includes("/api/v1/tasks?")
      ) {
        await route.continue();
        return;
      }
      if (failNextGet) {
        failNextGet = false;
        await route.abort();
        return;
      }
      if (request.url().includes("status=completed")) {
        completedHeld += 1;
        await completedGate;
        if (abortCompleted) {
          await route.abort();
          return;
        }
      }
      await route.continue();
    });

    // Старый read (completed) удержан.
    await page.getByRole("button", { name: "Завершённые" }).click();
    await expect.poll(() => completedHeld).toBe(1);

    // Новый read (all) успешно завершён и применён.
    await page.getByRole("button", { name: "Все" }).click();
    await expect(page.getByRole("button", { name: "Все" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(openRow).toBeVisible();
    await expect(completedRow).toBeVisible();

    // Старый completed прерван ПОСЛЕ успеха нового: без list error/retry,
    // latest список/context не тронуты.
    abortCompleted = true;
    releaseCompleted();
    await expect(listError).toHaveCount(0);
    await expect(retry).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Все" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(openRow).toBeVisible();
    await expect(completedRow).toBeVisible();

    // Последний failed read показывает error/retry; GET-only retry
    // восстанавливает список.
    failNextGet = true;
    await page.getByRole("button", { name: "Открытые" }).click();
    await expect(listError).toBeVisible();
    await expect(retry).toBeVisible();
    await retry.click();
    await expect(listError).toHaveCount(0);
    await expect(openRow).toBeVisible();
    await expect(completedRow).toHaveCount(0);
  });

  test("R3a: abort старого при удержанном новом не снимает pending; release нового применяет success", async ({
    page,
  }) => {
    const { openTitle, completedTitle, today } = await seedUpcomingFixtures(page, "pending");
    await page.goto(`/upcoming?start=${today}`);

    const heldCounts: Record<string, number> = { completed: 0, all: 0 };
    const gates: Record<string, Promise<void>> = {};
    const releases: Record<string, () => void> = {};
    const aborts: Record<string, boolean> = { completed: false, all: false };
    const arm = (status: string): void => {
      gates[status] = new Promise<void>((resolve) => {
        releases[status] = resolve;
      });
    };
    arm("completed");
    arm("all");
    await page.route("**/api/v1/tasks*", async (route) => {
      const request = route.request();
      const url = request.url();
      if (request.method() !== "GET" || !url.includes("/api/v1/tasks?")) {
        await route.continue();
        return;
      }
      for (const status of ["completed", "all"] as const) {
        if (url.includes(`status=${status}`)) {
          heldCounts[status] += 1;
          await gates[status];
          if (aborts[status]) {
            await route.abort();
            return;
          }
        }
      }
      await route.continue();
    });

    const refresh = page.getByRole("button", { name: "Обновить" });
    const refreshing = page.getByRole("button", { name: "Обновление…" });

    // Старый completed удержан; новый all тоже удержан.
    await page.getByRole("button", { name: "Завершённые" }).click();
    await expect.poll(() => heldCounts.completed).toBe(1);
    await page.getByRole("button", { name: "Все" }).click();
    await expect.poll(() => heldCounts.all).toBe(1);
    // Pending нового активен: кнопка в состоянии «Обновление…».
    await expect(refreshing).toBeVisible();

    // Старый abort, пока новый ещё удержан: pending нового НЕ снят,
    // ложной ошибки нет.
    aborts.completed = true;
    releases.completed();
    await expect(refreshing).toBeVisible();
    await expect(
      page.getByText("Не удалось обновить список задач."),
    ).toHaveCount(0);

    // Release нового: штатный success применён, pending снят.
    releases.all();
    await expect(page.getByRole("button", { name: "Все" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(page.locator("li[data-task-id]", { hasText: openTitle })).toBeVisible();
    await expect(
      page.locator("li[data-task-id]", { hasText: completedTitle }),
    ).toBeVisible();
    await expect(refresh).toBeVisible();
    await expect(refreshing).toHaveCount(0);
  });

  test("R3a: задержанный response.json() старого read не перезаписывает применённый новый", async ({
    page,
  }) => {
    const pageErrors: Error[] = [];
    page.on("pageerror", (error) => pageErrors.push(error));

    const { openTitle, completedTitle, today } = await seedUpcomingFixtures(page, "json");

    // Test-only wrapper: для GET status=completed возвращается Response,
    // у которого json() ожидает управляемого promise. Восстанавливается
    // вызовом restore() в конце теста.
    await page.addInitScript(() => {
      const w = window as unknown as {
        fetch: typeof fetch;
        __r3a?: {
          armed: boolean;
          releaseJson: (() => void) | null;
          original: typeof fetch;
          arm: () => void;
          release: () => void;
          restore: () => void;
        };
      };
      const api = {
        armed: false,
        releaseJson: null as (() => void) | null,
        original: w.fetch,
        arm() {
          api.armed = true;
        },
        release() {
          api.releaseJson?.();
          api.releaseJson = null;
        },
        restore() {
          api.armed = false;
          w.fetch = api.original;
        },
      };
      w.__r3a = api;
      w.fetch = (async (
        input: RequestInfo | URL,
        init?: RequestInit,
      ): Promise<Response> => {
        const response = await api.original.call(w, input, init);
        const url =
          typeof input === "string"
            ? input
            : input instanceof URL
              ? input.href
              : input.url;
        if (api.armed && response.ok && url.includes("status=completed")) {
          const text = await response.clone().text();
          let releaseJson!: () => void;
          const jsonGate = new Promise<void>((resolve) => {
            releaseJson = resolve;
          });
          api.releaseJson = releaseJson;
          const payload = new Response(text, {
            status: response.status,
            statusText: response.statusText,
            headers: response.headers,
          });
          payload.json = async () => {
            await jsonGate;
            return JSON.parse(text) as unknown;
          };
          return payload;
        }
        return response;
      }) as typeof fetch;
    });

    await page.goto(`/upcoming?start=${today}`);
    const openRow = page.locator("li[data-task-id]", { hasText: openTitle });
    const completedRow = page.locator("li[data-task-id]", {
      hasText: completedTitle,
    });
    const refresh = page.getByRole("button", { name: "Обновить" });

    // Взводим задержку JSON следующего completed GET.
    await page.evaluate(() => {
      (window as unknown as { __r3a?: { arm: () => void } }).__r3a?.arm();
    });

    // Старый completed: fetch получил ответ (initial seq guard пройден),
    // response.json() задержан — read висит на JSON await.
    await page.getByRole("button", { name: "Завершённые" }).click();

    // Новый all успешно применён.
    await page.getByRole("button", { name: "Все" }).click();
    await expect(page.getByRole("button", { name: "Все" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(openRow).toBeVisible();
    await expect(completedRow).toBeVisible();
    await expect(refresh).toBeVisible();

    // Отпускаем старый JSON: tasks/context остаются latest (обе строки в
    // all-режиме), без ошибки и без повторного pending.
    await page.evaluate(() => {
      (window as unknown as { __r3a?: { release: () => void } }).__r3a?.release();
    });
    await expect(openRow).toBeVisible();
    await expect(completedRow).toBeVisible();
    await expect(refresh).toBeVisible();
    await expect(page.getByRole("button", { name: "Все" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(
      page.getByText("Не удалось обновить список задач."),
    ).toHaveCount(0);

    // Wrapper восстановлен: последующий обычный GET работает.
    await page.evaluate(() => {
      (window as unknown as { __r3a?: { restore: () => void } }).__r3a?.restore();
    });
    await page.getByRole("button", { name: "Открытые" }).click();
    await expect(page.getByRole("button", { name: "Открытые" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(openRow).toBeVisible();
    await expect(completedRow).toHaveCount(0);
    expect(pageErrors).toEqual([]);
  });
});

async function seedUpcomingFixtures(
  page: import("@playwright/test").Page,
  label: string,
): Promise<{ openTitle: string; completedTitle: string; today: string }> {
  const today = await serverToday(page);
  // Уникальные titles на тест: строки накапливаются в аккаунте C.
  const openTitle = `R3a open ${run}-${label}`;
  const completedTitle = `R3a done ${run}-${label}`;
  const plannedDay = shift(today, 2);

  await page.goto("/inbox");
  for (const title of [openTitle, completedTitle]) {
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();
    await row.getByRole("button", { name: "Планирование" }).click();
    await row.getByLabel("Дата выполнения").fill(plannedDay);
    await row.getByRole("button", { name: "Сохранить" }).click();
    await expect(row).toHaveCount(0);
  }

  // Завершаем вторую задачу реальным toggle в Upcoming.
  await page.goto(`/upcoming?start=${today}`);
  const doneRow = page.locator("li[data-task-id]", { hasText: completedTitle });
  await expect(doneRow).toBeVisible();
  await doneRow.getByRole("button", { name: "Завершить" }).click();
  await expect(doneRow).toHaveCount(0);

  return { openTitle, completedTitle, today };
}

async function serverToday(page: import("@playwright/test").Page): Promise<string> {
  const response = await page.request.get("/api/v1/tasks?view=today&status=all");
  const payload = (await response.json()) as {
    context: { today: string };
  };
  return payload.context.today;
}

function shift(date: string, days: number): string {
  const [y, m, d] = date.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}
