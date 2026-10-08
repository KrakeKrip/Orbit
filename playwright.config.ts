import { defineConfig, devices } from "@playwright/test";
import {
  e2ePort,
  e2eSecret,
  userAPassword,
  userBEmail,
  userBPassword,
} from "./tests/e2e/credentials";

const port = e2ePort;
const baseURL = `http://127.0.0.1:${port}`;
const storageDir = "test-results/.auth";

export default defineConfig({
  testDir: "tests/e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  reporter: "list",
  globalTeardown: "./tests/e2e/global-teardown.ts",
  use: {
    baseURL,
    ...devices["Desktop Chrome"],
  },
  webServer: {
    command: "node scripts/e2e-server.ts",
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      E2E_PORT: String(port),
      AUTH_E2E_SECRET: e2eSecret,
    },
  },
  projects: [
    {
      name: "auth-setup",
      testMatch: /auth\.setup\.ts/,
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        storageState: `${storageDir}/user-a.json`,
      },
      dependencies: ["auth-setup"],
    },
  ],
});
