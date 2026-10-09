import { expect, test } from "@playwright/test";

// Владелец fixtures — пользователь C: сессию никто не ревокирует, задачи C
// не пересекаются с fixtures A (inbox.spec) и planning-задачами C.
const USER_C_STATE = "test-results/.auth/user-c.json";
const run = `t8g-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

// TASK-008-R2a browser: один общий write guard — удержанный POST quick-add
// блокирует row writes (и наоборот), disabled контролы, программные submit
// обходы не отправляют второй запрос, отказ снимает guard, retry работает.
// Синхронизация по фактическим route/response событиям, без sleeps.
test.describe.configure({ mode: "default" });

test.describe("Write guard (R2a, desktop 1280)", () => {
  test.use({ viewport: { width: 1280, height: 800 }, storageState: USER_C_STATE });

  test("Inbox: удержанный POST блокирует row writes и второй create; отказ снимает guard, retry работает", async ({
    page,
  }) => {
    const existingTitle = `Guard A ${run}`;
    const heldTitle = `Guard B ${run}`;

    await page.goto("/inbox");
    // Existing задача в idle (route-ов ещё нет).
    await page.getByLabel("Название задачи").fill(existingTitle);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: existingTitle });
    await expect(row).toBeVisible();

    // Наблюдатель row-запросов: считывает и пропускает в сеть.
    let patchCount = 0;
    let deleteCount = 0;
    await page.route("**/api/v1/tasks/*", async (route) => {
      const method = route.request().method();
      if (method === "PATCH") {
        patchCount += 1;
      }
      if (method === "DELETE") {
        deleteCount += 1;
      }
      await route.continue();
    });

    // Удержанный POST коллекции: 500 только после release.
    let postCount = 0;
    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    await page.route("**/api/v1/tasks", async (route) => {
      if (route.request().method() !== "POST") {
        await route.continue();
        return;
      }
      postCount += 1;
      await gate;
      await route.fulfill({
        status: 500,
        contentType: "application/json",
        body: '{"error":{"code":"INTERNAL"}}',
      });
    });

    await page.getByLabel("Название задачи").fill(heldTitle);
    await page.getByRole("button", { name: "Добавить задачу" }).click();

    // Create в полёте: create-контролы и row controls disabled.
    const createInput = page.getByLabel("Название задачи");
    await expect(page.getByRole("button", { name: "Добавление…" })).toBeDisabled();
    await expect(createInput).toBeDisabled();
    await expect(row.getByRole("button", { name: "Завершить" })).toBeDisabled();
    await expect(row.getByRole("button", { name: "Переименовать" })).toBeDisabled();
    await expect(row.getByRole("button", { name: "Планирование" })).toBeDisabled();
    await expect(row.getByRole("button", { name: "Удалить" })).toBeDisabled();

    // Программные попытки обойти disabled: guard синхронный, запросов нет.
    await row.getByRole("button", { name: "Завершить" }).click({ force: true });
    await row.getByRole("button", { name: "Планирование" }).click({ force: true });
    // Editor не открылся при pending create.
    await expect(row.getByLabel("Дата выполнения")).toHaveCount(0);
    // Программный submit create — второй POST не отправляется.
    await page.evaluate(() => {
      const form = document
        .getElementById("task-title-input")
        ?.closest("form");
      if (form instanceof HTMLFormElement) {
        form.requestSubmit();
      }
    });
    expect(patchCount).toBe(0);
    expect(deleteCount).toBe(0);
    expect(postCount).toBe(1);

    // Отпустить POST с 500: guard снят, create error виден, draft сохранён.
    const failedPost = page.waitForResponse(
      (response) =>
        response.request().method() === "POST" &&
        response.url().endsWith("/api/v1/tasks") &&
        response.status() === 500,
    );
    release();
    await failedPost;
    await expect(
      page.locator("#task-create-status [role=alert]"),
    ).toBeVisible();
    await expect(createInput).toHaveValue(heldTitle);
    await expect(createInput).toBeEnabled();
    await expect(
      page.getByRole("button", { name: "Добавить задачу" }),
    ).toBeEnabled();
    await expect(row.getByRole("button", { name: "Завершить" })).toBeEnabled();

    // Retry: тот же черновик успешно создаётся.
    await page.unroute("**/api/v1/tasks");
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    await expect(
      page.locator("li[data-task-id]", { hasText: heldTitle }),
    ).toBeVisible();
  });

  test("Inbox: удержанный schedule PATCH блокирует create; отказ снимает guard, повторный save успешен", async ({
    page,
  }) => {
    const title = `Guard C ${run}`;
    const heldCreateTitle = `Guard D ${run}`;

    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();

    // Валидный create-черновик заранее: программный submit ниже обязан
    // пройти parse и упереться именно в guard, а не в валидацию.
    await page.getByLabel("Название задачи").fill(heldCreateTitle);

    let postCount = 0;
    await page.route("**/api/v1/tasks", async (route) => {
      if (route.request().method() === "POST") {
        postCount += 1;
      }
      await route.continue();
    });

    let patchCount = 0;
    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    await page.route("**/api/v1/tasks/*", async (route) => {
      if (route.request().method() !== "PATCH") {
        await route.continue();
        return;
      }
      patchCount += 1;
      await gate;
      await route.fulfill({
        status: 500,
        contentType: "application/json",
        body: '{"error":{"code":"INTERNAL"}}',
      });
    });

    // Удержанный schedule PATCH существующей задачи.
    await row.getByRole("button", { name: "Планирование" }).click();
    await row
      .getByLabel("Дата выполнения")
      .fill(shift(await serverToday(page), 2));
    const failedPatch = page.waitForResponse(
      (response) =>
        response.request().method() === "PATCH" &&
        response.url().includes("/api/v1/tasks/") &&
        response.status() === 500,
    );
    await row.getByRole("button", { name: "Сохранить" }).click();

    // Create контролы disabled при чужой записи в полёте.
    const createInput = page.getByLabel("Название задачи");
    await expect(createInput).toBeDisabled();
    await expect(
      page.getByRole("button", { name: "Добавить задачу" }),
    ).toBeDisabled();

    // Программный submit create и force-клик: POST не отправляется.
    await page.evaluate(() => {
      const form = document
        .getElementById("task-title-input")
        ?.closest("form");
      if (form instanceof HTMLFormElement) {
        form.requestSubmit();
      }
    });
    await page
      .getByRole("button", { name: "Добавить задачу" })
      .click({ force: true });
    expect(postCount).toBe(0);
    expect(patchCount).toBe(1);

    // HTTP отказ снимает общий guard: create снова доступен.
    release();
    await failedPatch;
    await expect(createInput).toBeEnabled();
    await expect(
      page.getByRole("button", { name: "Добавить задачу" }),
    ).toBeEnabled();

    // Повторное сохранение расписания успешно (draft редактора сохранён).
    await page.unroute("**/api/v1/tasks/*");
    const savedPatch = page.waitForResponse(
      (response) =>
        response.request().method() === "PATCH" &&
        response.url().includes("/api/v1/tasks/") &&
        response.status() === 200,
    );
    await row.getByRole("button", { name: "Сохранить" }).click();
    await savedPatch;
    // Editor закрыт, задача ушла из Inbox (planned = future).
    await expect(
      page.locator("li[data-task-id]", { hasText: title }),
    ).toHaveCount(0);
    expect(postCount).toBe(0);
  });

  test("Today: удержанный POST блокирует row controls; отказ и retry работают", async ({
    page,
  }) => {
    const existingTitle = `Guard E ${run}`;
    const heldTitle = `Guard F ${run}`;

    await page.goto("/today");
    await page.getByLabel("Название задачи").fill(existingTitle);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: existingTitle });
    await expect(row).toBeVisible();

    let patchCount = 0;
    await page.route("**/api/v1/tasks/*", async (route) => {
      if (route.request().method() === "PATCH") {
        patchCount += 1;
      }
      await route.continue();
    });

    let postCount = 0;
    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    await page.route("**/api/v1/tasks", async (route) => {
      if (route.request().method() !== "POST") {
        await route.continue();
        return;
      }
      postCount += 1;
      await gate;
      await route.fulfill({
        status: 500,
        contentType: "application/json",
        body: '{"error":{"code":"INTERNAL"}}',
      });
    });

    await page.getByLabel("Название задачи").fill(heldTitle);
    await page.getByRole("button", { name: "Добавить задачу" }).click();

    const createInput = page.getByLabel("Название задачи");
    await expect(page.getByRole("button", { name: "Добавление…" })).toBeDisabled();
    await expect(createInput).toBeDisabled();
    await expect(row.getByRole("button", { name: "Завершить" })).toBeDisabled();

    await row.getByRole("button", { name: "Завершить" }).click({ force: true });
    expect(patchCount).toBe(0);
    expect(postCount).toBe(1);

    const failedPost = page.waitForResponse(
      (response) =>
        response.request().method() === "POST" &&
        response.url().endsWith("/api/v1/tasks") &&
        response.status() === 500,
    );
    release();
    await failedPost;

    // Guard снят: контролы вновь доступны, create-черновик не потерян.
    await expect(createInput).toBeEnabled();
    await expect(createInput).toHaveValue(heldTitle);
    await expect(row.getByRole("button", { name: "Завершить" })).toBeEnabled();

    await page.unroute("**/api/v1/tasks");
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    await expect(
      page.locator("li[data-task-id]", { hasText: heldTitle }),
    ).toBeVisible();
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
