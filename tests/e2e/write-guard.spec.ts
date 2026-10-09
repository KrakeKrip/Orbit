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

  test("открытый dirty schedule editor при чужом held POST: controls disabled, программные submit/cancel не действуют; отказ снимает блокировку", async ({
    page,
  }) => {
    const title = `Guard G ${run}`;
    const heldTitle = `Guard H ${run}`;
    const plannedDay = shift(await serverToday(page), 3);

    await page.goto("/inbox");
    await page.getByLabel("Название задачи").fill(title);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const row = page.locator("li[data-task-id]", { hasText: title });
    await expect(row).toBeVisible();

    // PATCH наблюдатель: считает и пропускает в сеть.
    let patchCount = 0;
    await page.route("**/api/v1/tasks/*", async (route) => {
      if (route.request().method() === "PATCH") {
        patchCount += 1;
      }
      await route.continue();
    });

    // Открыть dirty editor ДО удержания POST.
    await row.getByRole("button", { name: "Планирование" }).click();
    const dateInput = row.getByLabel("Дата выполнения");
    await dateInput.fill(plannedDay);

    // Удержанный POST quick-add; delivery фиксируем expect.poll'ом.
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
    await expect.poll(() => postCount).toBe(1);

    // Чужая pending запись: открытый editor заблокирован целиком, create
    // тоже; собственная операция не изображается («Сохранение…» нет).
    await expect(dateInput).toBeDisabled();
    await expect(row.getByRole("button", { name: "Сохранить" })).toBeDisabled();
    await expect(row.getByRole("button", { name: "Отмена" })).toBeDisabled();
    await expect(page.getByRole("button", { name: "Добавление…" })).toBeDisabled();
    await expect(row.getByRole("button", { name: "Сохранение…" })).toHaveCount(0);

    // Программный submit мимо disabled: handler guard — PATCH не уходит.
    await page.evaluate(() => {
      const form = document
        .querySelector('[id^="task-schedule-date-input-"]')
        ?.closest("form");
      if (form instanceof HTMLFormElement) {
        form.requestSubmit();
      }
    });
    // Программный cancel мимо disabled: close guard — editor не закрыт.
    await row.getByRole("button", { name: "Отмена" }).dispatchEvent("click");
    await expect(dateInput).toHaveCount(1);
    expect(patchCount).toBe(0);

    // Отказ чужого POST: блокировка снята, editor/draft прежние.
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
    await expect(dateInput).toBeEnabled();
    await expect(dateInput).toHaveValue(plannedDay);
    await expect(row.getByRole("button", { name: "Сохранить" })).toBeEnabled();
    await expect(row.getByRole("button", { name: "Отмена" })).toBeEnabled();

    // Последующее настоящее сохранение успешно.
    await page.unroute("**/api/v1/tasks");
    const savedPatch = page.waitForResponse(
      (response) =>
        response.request().method() === "PATCH" &&
        response.url().includes("/api/v1/tasks/") &&
        response.status() === 200,
    );
    await row.getByRole("button", { name: "Сохранить" }).click();
    await savedPatch;
    await expect(
      page.locator("li[data-task-id]", { hasText: title }),
    ).toHaveCount(0);
    expect(patchCount).toBe(1);
  });

  test("открытые rename и delete confirmation при чужом held POST: блокировка, guards, отказ снимает (таблица)", async ({
    page,
  }) => {
    const renameTitle = `Guard I ${run}`;
    const renameDraft = `Guard I переименован ${run}`;
    const deleteTitle = `Guard J ${run}`;
    const heldTitle = `Guard K ${run}`;

    await page.goto("/inbox");
    // Две задачи; для rename и delete по открытой форме.
    await page.getByLabel("Название задачи").fill(renameTitle);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    await expect(
      page.locator("li[data-task-id]", { hasText: renameTitle }),
    ).toBeVisible();
    await page.getByLabel("Название задачи").fill(deleteTitle);
    await page.getByRole("button", { name: "Добавить задачу" }).click();
    const deleteRow = page.locator("li[data-task-id]", { hasText: deleteTitle });
    await expect(deleteRow).toBeVisible();

    const renameRow = page.locator("li[data-task-id]", { hasText: renameTitle });
    await expect(renameRow).toBeVisible();
    const renameTaskId = await renameRow.getAttribute("data-task-id");
    expect(renameTaskId).not.toBeNull();
    // Открытый rename editor заменяет <p> title формой: текст строки
    // пропадает, поэтому после открытия ищем по data-task-id/id, не hasText.
    const renameBox = page.locator(`li[data-task-id="${renameTaskId}"]`);
    await renameBox.getByRole("button", { name: "Переименовать" }).click();
    const renameInput = page.locator(`#task-rename-input-${renameTaskId}`);
    await renameInput.fill(renameDraft);
    await deleteRow.getByRole("button", { name: "Удалить" }).click();
    await expect(page.getByText("Удалить задачу?")).toBeVisible();

    // Наблюдатели row-запросов: считают и пропускают.
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
    await expect.poll(() => postCount).toBe(1);

    // Обе открытые формы заблокированы чужой записью.
    await expect(renameInput).toBeDisabled();
    await expect(
      renameBox.getByRole("button", { name: "Сохранить" }),
    ).toBeDisabled();
    await expect(
      renameBox.getByRole("button", { name: "Отмена" }),
    ).toBeDisabled();
    await expect(
      deleteRow.getByRole("button", { name: "Удалить", exact: true }),
    ).toBeDisabled();
    await expect(
      deleteRow.locator('[id^="task-delete-cancel-"]'),
    ).toBeDisabled();
    // Собственные операции не изображаются.
    await expect(renameBox.getByRole("button", { name: "Сохранение…" })).toHaveCount(0);
    await expect(deleteRow.getByRole("button", { name: "Удаление…" })).toHaveCount(0);

    // Программные bypass: submit/cancel обеих форм — без запросов и без
    // закрытия форм.
    await page.evaluate((id) => {
      const form = document
        .getElementById(`task-rename-input-${id}`)
        ?.closest("form");
      if (form instanceof HTMLFormElement) {
        form.requestSubmit();
      }
    }, renameTaskId);
    await renameBox.getByRole("button", { name: "Отмена" }).dispatchEvent("click");
    await expect(renameInput).toHaveCount(1);
    await deleteRow
      .getByRole("button", { name: "Удалить", exact: true })
      .dispatchEvent("click");
    await expect(page.getByText("Удалить задачу?")).toBeVisible();
    await deleteRow.locator('[id^="task-delete-cancel-"]').dispatchEvent("click");
    await expect(page.getByText("Удалить задачу?")).toBeVisible();
    expect(patchCount).toBe(0);
    expect(deleteCount).toBe(0);

    // Отказ чужого POST снимает блокировку; формы открыты, draft прежний.
    const failedPost = page.waitForResponse(
      (response) =>
        response.request().method() === "POST" &&
        response.url().endsWith("/api/v1/tasks") &&
        response.status() === 500,
    );
    release();
    await failedPost;
    await expect(renameInput).toBeEnabled();
    await expect(renameInput).toHaveValue(renameDraft);
    await expect(
      renameBox.getByRole("button", { name: "Сохранить" }),
    ).toBeEnabled();
    await expect(
      deleteRow.getByRole("button", { name: "Удалить", exact: true }),
    ).toBeEnabled();
    await expect(
      deleteRow.locator('[id^="task-delete-cancel-"]'),
    ).toBeEnabled();

    // Обычная отмена теперь работает: обе формы закрываются.
    await renameBox.getByRole("button", { name: "Отмена" }).click();
    await expect(renameInput).toHaveCount(0);
    await deleteRow.locator('[id^="task-delete-cancel-"]').click();
    await expect(page.getByText("Удалить задачу?")).toHaveCount(0);
    expect(patchCount).toBe(0);
    expect(deleteCount).toBe(0);
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
