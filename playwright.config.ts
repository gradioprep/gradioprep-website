import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests",
  // The local CI suite shares one synthetic grading-capacity singleton.
  // Run test cases deterministically; request-level races remain exercised inside
  // the dedicated Promise.all acceptance and role-revocation tests.
  fullyParallel: false,
  workers: 1,
  reporter: "list",
  timeout: 30_000,
  expect: {
    timeout: 5_000,
  },
  use: {
    baseURL: "http://127.0.0.1:8787",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "npx wrangler dev --ip 127.0.0.1 --port 8787",
    url: "http://127.0.0.1:8787",
    reuseExistingServer: false,
    timeout: 120_000,
  },
});
