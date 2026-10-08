import { expect, test } from "@playwright/test";

// Владелец project fixtures — пользователь A: его сессию никто не
// ревокирует (settings.spec завершается logout'ом B), а данные projects
// не пересекаются с theme/settings мутациями других specs.
const USER_A_STATE = "test-results/.auth/user-a.json";
const run = `e2e-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

// Проекты — mutable fixtures пользователя B (settings.spec мутирует только
// user_settings, theme.spec — тему A; пересечений по данным нет). Файл
// сериализован: тесты используют общее состояние списка B.
test.describe.configure({ mode: "default" });

test.describe("проекты: создание/переименование/архив (desktop 1280)", () => {
  test.use({ viewport: { width: 1280, height: 800 }, storageState: USER_A_STATE });

  test("создание по Enter, переименование, reload сохраняет состояние", async ({
    page,
  }) => {
    await page.goto("/projects");
    const input = page.getByLabel("Название проекта");

    await input.fill(`Проект ${run}`);
    await input.press("Enter");
    const row = page.locator("li", { hasText: `Проект ${run}` });
    await expect(row).toBeVisible();

    await page.reload();
    await expect(page.locator("li", { hasText: `Проект ${run}` })).toBeVisible();

    // Переименование: cancel ничего не пишет, фокус возвращается к trigger.
    const trigger = page
      .locator("li", { hasText: `Проект ${run}` })
      .getByRole("button", { name: "Переименовать" });
    await trigger.click();
    const renameInput = page.getByLabel("Переименовать");
    await renameInput.fill(`Проект ${run} ОТМЕНА`);
    await page.getByRole("button", { name: "Отмена" }).click();
    await expect(
      page.locator("li", { hasText: `Проект ${run}` }),
    ).toBeVisible();
    await expect(trigger).toBeFocused();

    // Переименование с сохранением.
    await trigger.click();
    await renameInput.fill(`Проект ${run} (обновлён)`);
    await page.getByRole("button", { name: "Сохранить" }).click();
    const renamed = page.locator("li", { hasText: `Проект ${run} (обновлён)` });
    await expect(renamed).toBeVisible();

    await page.reload();
    await expect(
      page.locator("li", { hasText: `Проект ${run} (обновлён)` }),
    ).toBeVisible();
  });

  test("невалидное имя: сообщение без создания проекта", async ({ page }) => {
    await page.goto("/projects");
    const before = await page.locator("li[data-project-id]").count();
    await page.getByLabel("Название проекта").fill("   ");
    await page.getByRole("button", { name: "Создать проект" }).click();
    await expect(page.getByText("Введите название проекта")).toBeVisible();
    expect(await page.locator("li[data-project-id]").count()).toBe(before);
  });

  test("архив: исчезает из активных, виден в архиве, restore возвращает", async ({
    page,
  }) => {
    const name = `Архивный ${run}`;
    await page.goto("/projects");
    await page.getByLabel("Название проекта").fill(name);
    await page.getByRole("button", { name: "Создать проект" }).click();
    const row = page.locator("li", { hasText: name });
    await expect(row).toBeVisible();

    await row.getByRole("button", { name: "Архивировать" }).click();
    await expect(page.locator("li", { hasText: name })).toHaveCount(0);

    await page.getByRole("button", { name: "Архив", exact: true }).click();
    const archivedRow = page.locator("li", { hasText: name });
    await expect(archivedRow).toBeVisible();

    // Rename доступен и в архиве.
    await archivedRow.getByRole("button", { name: "Переименовать" }).click();
    await page.getByLabel("Переименовать").fill(`${name} (архив)`);
    await page.getByRole("button", { name: "Сохранить" }).click();
    await expect(
      page.locator("li", { hasText: `${name} (архив)` }),
    ).toBeVisible();

    await page
      .locator("li", { hasText: `${name} (архив)` })
      .getByRole("button", { name: "Восстановить" })
      .click();
    await expect(
      page.locator("li", { hasText: `${name} (архив)` }),
    ).toHaveCount(0);

    await page.getByRole("button", { name: "Активные", exact: true }).click();
    await expect(
      page.locator("li", { hasText: `${name} (архив)` }),
    ).toBeVisible();
  });

  test("failed mutation: список/строка/draft сохраняются, retry успешен", async ({
    page,
  }) => {
    const name = `Отказ ${run}`;
    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    await page.route("**/api/v1/projects", async (route) => {
      await gate;
      await route.fulfill({
        status: 500,
        contentType: "application/json",
        body: '{"error":{"code":"INTERNAL"}}',
      });
    });

    await page.goto("/projects");
    await page.getByLabel("Название проекта").fill(name);
    await page.getByRole("button", { name: "Создать проект" }).click();
    await expect(page.getByRole("alert").first()).toBeVisible();
    // Draft сохранён для retry, проект не показан как созданный.
    await expect(page.getByLabel("Название проекта")).toHaveValue(name);
    await expect(page.locator("li", { hasText: name })).toHaveCount(0);

    // Delayed/late ответ после ухода со страницы не ломает новый UI (R1
    // инвариант TASK-005): уходим, отпускаем 500, возвращаемся.
    await page.getByRole("link", { name: "Сегодня", exact: true }).click();
    await expect(page).toHaveURL(/\/today$/);
    release();
    await page.waitForTimeout(300);
    await expect(page.locator("html")).toBeVisible();

    await page.goto("/projects");
    await page.unroute("**/api/v1/projects");
    await page.getByLabel("Название проекта").fill(name);
    await page.getByRole("button", { name: "Создать проект" }).click();
    await expect(page.locator("li", { hasText: name })).toBeVisible();
    // Ошибка предыдущей попытки ушла (route announcer — тоже alert, поэтому
    // проверяем отсутствие конкретного текста, а не счётчик роли).
    await expect(page.getByText("Не удалось создать проект")).toHaveCount(0);
  });

  test("длинное имя и разметка: текст без поломки layout", async ({ page }) => {
    const longName = `${"🦄".repeat(30)} Длинное название проекта ${run} с <b>разметкой</b> и эмодзи`;
    await page.goto("/projects");
    await page.getByLabel("Название проекта").fill(longName);
    await page.getByRole("button", { name: "Создать проект" }).click();
    const row = page.locator("li", { hasText: "Длинное название проекта" });
    await expect(row).toBeVisible();
    // markup — экранированный текст.
    await expect(row).toContainText("<b>разметкой</b>");
    const scrollWidth = await page.evaluate(
      () => document.documentElement.scrollWidth,
    );
    expect(scrollWidth).toBeLessThanOrEqual(1280);
  });
});

test.describe("проекты на мобильной ширине (360)", () => {
  test.use({ viewport: { width: 360, height: 740 }, storageState: USER_A_STATE });

  test("create с клавиатуры, tabs и actions доступны, без overflow", async ({
    page,
  }) => {
    await page.goto("/today");
    await page.getByRole("link", { name: "Проекты", exact: true }).click();
    await expect(page).toHaveURL(/\/projects$/);

    const input = page.getByLabel("Название проекта");
    await input.fill(`Мобильный ${run}`);
    await input.press("Enter");
    await expect(page.locator("li", { hasText: `Мобильный ${run}` })).toBeVisible();

    const scrollWidth = await page.evaluate(
      () => document.documentElement.scrollWidth,
    );
    expect(scrollWidth).toBeLessThanOrEqual(360);

    // Tabs переключаются.
    await page.getByRole("button", { name: "Архив", exact: true }).click();
    await expect(page.getByText("В архиве пока нет проектов")).toBeVisible();
    await page.getByRole("button", { name: "Активные", exact: true }).click();
    await expect(page.locator("li", { hasText: `Мобильный ${run}` })).toBeVisible();
  });
});
