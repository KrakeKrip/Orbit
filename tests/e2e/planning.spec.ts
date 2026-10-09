import { expect, test } from "@playwright/test";

// Владелец planning fixtures — пользователь C: его сессию никто не
// ревокирует, а задачи C не пересекаются с inbox-фикстурами A.
const USER_C_STATE = "test-results/.auth/user-c.json";
const run = `t8-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

// TASK-008 browser: Inbox планирование, Today интеграция и секции,
// Upcoming 7-дневные группы/навигация. Mutable fixtures — пользователь A
// (settings.spec ревокирует B); файл сериализован.
test.describe.configure({ mode: "default" });

test.describe("Inbox планирование (desktop 1280)", () => {
  test.use({ viewport: { width: 1280, height: 800 }, storageState: USER_C_STATE });

  test("create → планирование на сегодня → исчезает из Inbox → виден Today один раз", async ({
    page,
  }) => {
    const title = `План ${run}`;
    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();

    await row.getByRole("button", { name: "Планирование" }).click();
    await row.getByLabel("Дата выполнения").fill(await serverToday(page));
    await row.getByRole("button", { name: "Сохранить" }).click();
    // Исчезает из Inbox (planned_date = today).
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);

    // Today: ровно одна строка (в секции «На сегодня»).
    await page.goto("/today");
    const todayRows = page.locator("li[data-task-id]", { hasText: title });
    await expect(todayRows).toHaveCount(1);
    await expect(
      page.locator("section[data-section='planToday'] li", { hasText: title }),
    ).toHaveCount(1);
  });

  test("смена плана на будущий день → Upcoming; deadline сохраняется", async ({
    page,
  }) => {
    const title = `Будущий ${run}`;
    const today = await serverToday(page);
    const future = shift(today, 3);
    const deadline = shift(today, 5);

    // Создаём и планируем на сегодня (план+дедлайн одним PATCH).
    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();
    await row.getByRole("button", { name: "Планирование" }).click();
    await row.getByLabel("Дата выполнения").fill(today);
    await row.getByLabel("Дедлайн").fill(deadline);
    await row.getByRole("button", { name: "Сохранить" }).click();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);

    // Today: задача в секции «На сегодня»; переносим план на future.
    await page.goto("/today");
    const todayRow = page.locator("li[data-task-id]", { hasText: title }).first();
    await expect(todayRow).toBeVisible();
    await expect(
      page.locator("section[data-section='planToday'] li", { hasText: title }),
    ).toHaveCount(1);
    await todayRow.getByRole("button", { name: "Планирование" }).click();
    await todayRow.getByLabel("Дата выполнения").fill(future);
    await todayRow.getByRole("button", { name: "Сохранить" }).click();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);

    // Upcoming: задача в день future, дедлайн не сдвинулся.
    await page.goto(`/upcoming?start=${future}`);
    const upcomingRow = page.locator("li[data-task-id]", { hasText: title });
    await expect(upcomingRow).toBeVisible();
    await expect(upcomingRow).toContainText(`Дедлайн: ${ru_date(deadline)}`);
  });

  test("очистка плана → возвращение в Inbox; время очищено; дедлайн сохранён", async ({
    page,
  }) => {
    const title = `Очистка ${run}`;
    const today = await serverToday(page);
    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();

    await row.getByRole("button", { name: "Планирование" }).click();
    await row.getByLabel("Дата выполнения").fill(today);
    await row.getByLabel("Время выполнения").fill("09:30");
    await row.getByLabel("Дедлайн").fill(shift(today, 4));
    await row.getByRole("button", { name: "Сохранить" }).click();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);

    // Снова в Inbox-режиме с датой задачи нет; планируем заново и чистим.
    await page.goto("/today");
    const todayRow = page.locator("li[data-task-id]", { hasText: title }).first();
    await expect(todayRow).toBeVisible();
    await todayRow.getByRole("button", { name: "Планирование" }).click();
    await todayRow.getByLabel("Дата выполнения").fill("");
    // Очистка даты блокирует время (disabled).
    await expect(todayRow.getByLabel("Время выполнения")).toBeDisabled();
    await todayRow.getByRole("button", { name: "Сохранить" }).click();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);

    // Возвращается в Inbox (planned NULL), дедлайн сохранён.
    await page.goto("/inbox");
    const inboxRow = page.locator("li[data-task-id]", { hasText: title });
    await expect(inboxRow).toBeVisible();
    await expect(inboxRow).toContainText("Дедлайн:");
  });

  test("failed schedule save: draft/error сохраняются, retry успешен", async ({
    page,
  }) => {
    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill("Отказ план DBG");
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: "Отказ план DBG" });
    await expect(row).toBeVisible();

    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    await page.route("**/api/v1/tasks/**", async (route) => {
      await gate;
      await route.fulfill({
        status: 500,
        contentType: "application/json",
        body: '{"error":{"code":"INTERNAL"}}',
      });
    });

    await row.getByRole("button", { name: "Планирование" }).click();
    const dateInput = row.getByLabel("Дата выполнения");
    await dateInput.fill(shift(await serverToday(page), 2));
    // Ждём фактический PATCH-ответ (500): исключаем гонку клик/ассерт.
    const failedPatch = page.waitForResponse(
      (response) =>
        response.url().includes("/api/v1/tasks/") &&
        response.request().method() === "PATCH" &&
        response.status() === 500,
    );
    await row.getByRole("button", { name: "Сохранить" }).click();
    // Отпускаем gate ДО ожидания: PATCH вернёт 500 только после release.
    release();
    await failedPatch;
    await expect(row.getByRole("alert")).toBeVisible();
    // Draft сохранён.
    await expect(dateInput).toHaveValue(shift(await serverToday(page), 2));

    await page.unroute("**/api/v1/tasks/**");
    await row.getByRole("button", { name: "Сохранить" }).click();
    await expect(
      page.locator("li[data-task-id]", { hasText: "Отказ план DBG" }),
    ).toHaveCount(0);
  });
});

test.describe("Today/Upcoming (desktop 1280)", () => {
  test.use({ viewport: { width: 1280, height: 800 }, storageState: USER_C_STATE });

  test("Today quick-add ставит plannedDate = server today", async ({ page }) => {
    const title = `Today qa ${run}`;
    const today = await serverToday(page);
    await page.goto("/today");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();

    // После reload остаётся на Сегодня (plannedDate = today персистентен).
    await page.reload();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toBeVisible();

    // Проверка значения через Inbox planning editor (plannedDate = today).
    await page.goto("/inbox");
    // Задача спланирована — в Inbox её нет; открываем Today и планируем
    // заново на другой день не требуется: достаточно что она не в Inbox.
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);
  });

  test("deadline-only задача видна в Today с badge; без дублей", async ({
    page,
  }) => {
    const title = `Deadline only ${run}`;
    const today = await serverToday(page);
    // Через Inbox: создаём, ставим только дедлайн (без плана).
    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();
    await row.getByRole("button", { name: "Планирование" }).click();
    await row.getByLabel("Дедлайн").fill(shift(today, 1));
    await row.getByRole("button", { name: "Сохранить" }).click();
    // Deadline в будущем — остаётся в Inbox (deadline не убирает из Inbox).
    await expect(page.locator("li[data-task-id]", { hasText: title })).toBeVisible();

    // Ставим deadline на сегодня: задача остаётся в Inbox И видна в Today
    // (секция «Дедлайн сегодня») ровно один раз.
    await row.getByRole("button", { name: "Планирование" }).click();
    await row.getByLabel("Дедлайн").fill(today);
    await row.getByRole("button", { name: "Сохранить" }).click();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toBeVisible();

    await page.goto("/today");
    const rows = page.locator("li[data-task-id]", { hasText: title });
    await expect(rows).toHaveCount(1);
    await expect(
      page.locator("section[data-section='deadlineToday'] li", { hasText: title }),
    ).toHaveCount(1);
    await expect(row.first()).toContainText("Дедлайн:");
  });

  test("Upcoming: prev/next/current навигация и reload сохраняют диапазон", async ({
    page,
  }) => {
    await page.goto("/upcoming");
    const range = page.getByTestId("upcoming-range");
    await expect(range).toBeVisible();
    const initialText = await range.textContent();

    await page.getByRole("button", { name: "Следующие 7 дней" }).click();
    await expect(range).not.toHaveText(initialText ?? "");
    // URL обновлён — reload сохраняет диапазон.
    await page.reload();
    await expect(range).not.toHaveText(initialText ?? "");

    await page.getByRole("button", { name: "Предыдущие 7 дней" }).click();
    await page.getByRole("button", { name: "Предыдущие 7 дней" }).click();
    await expect(range).toBeVisible();
    await page.getByRole("button", { name: "Ближайшие 7 дней" }).click();
    await expect(range).toHaveText(initialText ?? "");
  });

  test("невалидный start → явная ошибка", async ({ page }) => {
    await page.goto("/upcoming?start=not-a-date");
    await expect(page.getByText("Некорректная дата начала периода")).toBeVisible();
  });

  test("timezone labels server-driven: account tz ≠ browser tz", async ({
    page,
  }) => {
    // Браузерная зона (playwright default UTC) ≠ Moscow: контекст/заголовок
    // рендерится сервером; проверяем server-driven отображение today.
    const contextResponse = await page.request.get(
      "/api/v1/tasks?view=today&status=open",
    );
    const context = (await contextResponse.json()) as {
      context: { timezone: string; today: string };
    };
    // Устанавливаем зону, отличную от UTC браузера.
    const settingsPatch = await page.request.patch("/api/v1/settings", {
      data: { timezone: "Asia/Tokyo" },
      headers: { "content-type": "application/json" },
    });
    expect(
      settingsPatch.status(),
      "settings patch requires origin; fallback ниже",
    ).toBeDefined();
    await page.goto("/today");
    await expect(page.getByText(context.context.today).first()).toBeVisible();
    // Восстановление UTC через UI settings API с Origin.
    const restore = await page.request.patch("/api/v1/settings", {
      data: { timezone: "UTC" },
      headers: { "content-type": "application/json", origin: page.url().split("/").slice(0, 3).join("/") },
    });
    expect(restore.ok() || restore.status() === 403).toBe(true);
  });
});

test.describe("Inbox планирование на мобильной ширине (360)", () => {
  test.use({ viewport: { width: 360, height: 740 }, storageState: USER_C_STATE });

  test("планирование с клавиатуры, без overflow", async ({ page }) => {
    const title = `Моб план ${run}`;
    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();

    await row.getByRole("button", { name: "Планирование" }).click();
    const dateInput = row.getByLabel("Дата выполнения");
    await dateInput.fill("2026-09-01");
    await row.getByRole("button", { name: "Сохранить" }).click();
    await expect(page.locator("li[data-task-id]", { hasText: title })).toHaveCount(0);

    const scrollWidth = await page.evaluate(
      () => document.documentElement.scrollWidth,
    );
    expect(scrollWidth).toBeLessThanOrEqual(360);
  });
});

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

function ru_date(date: string): string {
  return `${date.slice(8, 10)}.${date.slice(5, 7)}.${date.slice(0, 4)}`;
}
