import { expect, test } from "@playwright/test";
import path from "node:path";
import { userAEmail, userAPassword } from "./credentials";

/**
 * Playwright setup: аутентифицируется как синтетический пользователь A через
 * реальную форму /login и сохраняет storageState для основного проекта.
 * Файл состояния — test-results/.auth/user-a.json (gitignored артефакт).
 */

const storageFile = path.join("test-results", ".auth", "user-a.json");

test("login as user A and persist storage state", async ({ page }) => {
  await page.goto("/login");
  await expect(
    page.getByRole("heading", { name: "Вход в Orbit" }),
  ).toBeVisible();

  await page.getByLabel("Email").fill(userAEmail);
  await page.getByLabel("Пароль").fill(userAPassword);
  await page.getByRole("button", { name: "Войти" }).click();

  await expect(page).toHaveURL(/\/today$/);
  await expect(
    page.getByRole("heading", { level: 1, name: "Сегодня" }),
  ).toBeVisible();

  await page.context().storageState({ path: storageFile });
});
