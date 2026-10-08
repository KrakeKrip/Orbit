import { expect, test } from "@playwright/test";

const routes = [
  { path: "/today", title: "Сегодня" },
  { path: "/inbox", title: "Входящие" },
  { path: "/upcoming", title: "Предстоящее" },
  { path: "/projects", title: "Проекты" },
  { path: "/settings", title: "Настройки" },
] as const;

for (const width of [360, 390, 768, 1280]) {
  test.describe(`оболочка ${width}px`, () => {
    test.use({
      viewport: { width, height: width <= 390 ? 740 : width >= 1280 ? 800 : 1024 },
    });

    test("корень перенаправляет на /today без 404", async ({ page }) => {
      const response = await page.goto("/");
      expect(response?.status()).toBe(200);
      await expect(page).toHaveURL(/\/today$/);
      await expect(
        page.getByRole("heading", { level: 1, name: "Сегодня" }),
      ).toBeVisible();
    });

    for (const route of routes) {
      test(`прямой вход и активная ссылка: ${route.path}`, async ({ page }) => {
        await page.goto(route.path);
        await expect(page).toHaveURL(new RegExp(`${route.path}$`));
        await expect(
          page.getByRole("heading", { level: 1, name: route.title }),
        ).toBeVisible();
        // В DOM присутствуют обе версии навигации; видима и доступна ровно одна
        // активная ссылка, скрытая оболочка не попадает в AX tree.
        const activeLink = page
          .locator(`a[aria-current="page"][href="${route.path}"]`)
          .filter({ visible: true });
        await expect(activeLink).toHaveCount(1);
        await expect(
          page.getByRole("link", { name: route.title, exact: true }),
        ).toHaveCount(1);
      });
    }

    test("переход по всем разделам через видимую навигацию", async ({
      page,
    }) => {
      await page.goto("/today");
      for (const route of routes) {
        const link = page.getByRole("link", {
          name: route.title,
          exact: true,
        });
        await expect(link).toHaveCount(1);
        await link.click();
        await expect(page).toHaveURL(new RegExp(`${route.path}$`));
        await expect(
          page.getByRole("heading", { level: 1, name: route.title }),
        ).toBeVisible();
      }
    });

    test("нет горизонтального overflow на всех маршрутах", async ({ page }) => {
      for (const route of routes) {
        await page.goto(route.path);
        const scrollWidth = await page.evaluate(
          () => document.documentElement.scrollWidth,
        );
        const clientWidth = await page.evaluate(
          () => document.documentElement.clientWidth,
        );
        expect(scrollWidth, `route ${route.path}`).toBeLessThanOrEqual(
          clientWidth,
        );
      }
    });

    test("skip link получает фокус по Tab и переводит его на контент", async ({
      page,
    }) => {
      await page.goto("/today");
      await page.keyboard.press("Tab");
      const skipLink = page.getByRole("link", { name: "К содержимому" });
      await expect(skipLink).toBeFocused();
      await page.keyboard.press("Enter");
      await expect(page.locator("#content")).toBeFocused();
    });
  });
}

test.describe("touch targets мобильной оболочки", () => {
  test.use({ viewport: { width: 360, height: 740 } });

  test("ссылки bottom nav и доступ к настройкам >= 44x44 px", async ({
    page,
  }) => {
    await page.goto("/today");
    const navLinks = page.locator(
      "nav[aria-label='Мобильная навигация'] a",
    );
    const count = await navLinks.count();
    expect(count).toBe(4);
    for (let i = 0; i < count; i += 1) {
      const box = await navLinks.nth(i).boundingBox();
      expect(box).not.toBeNull();
      expect(box!.width, `link ${i}`).toBeGreaterThanOrEqual(44);
      expect(box!.height, `link ${i}`).toBeGreaterThanOrEqual(44);
    }
    const settingsBox = await page
      .getByRole("link", { name: "Настройки", exact: true })
      .boundingBox();
    expect(settingsBox).not.toBeNull();
    expect(settingsBox!.width).toBeGreaterThanOrEqual(44);
    expect(settingsBox!.height).toBeGreaterThanOrEqual(44);
  });
});

for (const width of [360, 390]) {
  test.describe(`touch targets выбора темы, ${width}px`, () => {
    test.use({ viewport: { width, height: 740 } });

    test("триггер, раскрытые options и ссылка Orbit >= 44x44 без выхода за viewport", async ({
      page,
    }) => {
      await page.goto("/settings");

      const orbitBox = await page
        .getByRole("link", { name: "Orbit", exact: true })
        .boundingBox();
      expect(orbitBox).not.toBeNull();
      expect(orbitBox!.width).toBeGreaterThanOrEqual(44);
      expect(orbitBox!.height).toBeGreaterThanOrEqual(44);

      const trigger = page.locator("#theme-select");
      const triggerBox = await trigger.boundingBox();
      expect(triggerBox).not.toBeNull();
      expect(triggerBox!.width).toBeGreaterThanOrEqual(44);
      expect(triggerBox!.height).toBeGreaterThanOrEqual(44);

      await trigger.click();
      const options = page.getByRole("option");
      await expect(options).toHaveCount(3);
      for (let i = 0; i < 3; i += 1) {
        const box = await options.nth(i).boundingBox();
        expect(box).not.toBeNull();
        expect(box!.width, `option ${i}`).toBeGreaterThanOrEqual(44);
        expect(box!.height, `option ${i}`).toBeGreaterThanOrEqual(44);
        expect(box!.x, `option ${i} left edge`).toBeGreaterThanOrEqual(0);
        expect(box!.x + box!.width, `option ${i} right edge`).toBeLessThanOrEqual(
          width,
        );
        expect(box!.y + box!.height, `option ${i} bottom edge`).toBeLessThanOrEqual(
          740,
        );
      }

      await page.keyboard.press("Escape");
      await expect(trigger).toBeFocused();
      const scrollWidth = await page.evaluate(
        () => document.documentElement.scrollWidth,
      );
      expect(scrollWidth).toBeLessThanOrEqual(width);
    });

    test("выбор темы с клавиатуры работает при мобильной ширине", async ({
      page,
    }) => {
      await page.goto("/settings");
      const trigger = page.locator("#theme-select");
      await trigger.focus();
      await page.keyboard.press("Enter");
      await page.keyboard.press("ArrowDown");
      await page.keyboard.press("Enter");
      await expect(page.locator("html")).toHaveClass(/light/);
      await expect(trigger).toBeFocused();
    });
  });
}
