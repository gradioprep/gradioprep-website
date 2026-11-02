import { expect, test } from "@playwright/test";

test.describe("Phase 1B account foundation", () => {
  test("public health endpoint responds without exposing configuration", async ({ request }) => {
    const response = await request.get("/api/health");
    expect(response.status()).toBe(200);
    await expect(response.json()).resolves.toEqual({
      status: "ok",
      service: "gradioprep-api",
    });
    expect(response.headers()["cache-control"]).toBe("no-store");
  });

  test("current-account endpoint rejects anonymous requests", async ({ request }) => {
    const response = await request.get("/api/v1/me");
    expect(response.status()).toBe(401);
    const body = await response.json() as { error?: string };
    expect(body.error).toBe("authentication_required");
  });

  test("synthetic student can sign up, load own profile, edit display name and sign out", async ({ page }) => {
    const pageErrors: string[] = [];
    const apiResponses: string[] = [];
    page.on("pageerror", (error) => pageErrors.push(error.message));
    page.on("response", async (response) => {
      if (new URL(response.url()).pathname === "/api/v1/me") {
        const body = await response.text().catch(() => "<response body unavailable>");
        apiResponses.push(`${response.status()} ${body}`);
      }
    });

    await page.goto("/account");
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();
    await page.getByRole("button", { name: /create a synthetic student account/i }).click();
    await expect(page.getByRole("heading", { name: /create a student account/i })).toBeVisible();

    const uniqueEmail = `phase1b-${crypto.randomUUID()}@example.invalid`;
    await page.getByLabel("Display name").fill("Synthetic Phase One Learner");
    await page.getByLabel("Email address").fill(uniqueEmail);
    await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");

    await page.getByRole("button", { name: "Create account" }).click();

    // Wait for the form to settle into either a signed-in profile or a visible
    // signup/validation error so that a failure reports the actual UI/API state.
    await expect.poll(async () => {
      const saveButton = page.getByRole("button", { name: "Save display name" });
      const createButton = page.getByRole("button", { name: "Create account" });
      const hasAlert = await page.getByRole("alert").count() > 0;
      return (
        (await saveButton.isVisible() && await saveButton.isEnabled()) ||
        (await createButton.isVisible() && await createButton.isEnabled()) ||
        hasAlert
      );
    }, { timeout: 10_000 }).toBe(true);

    const cardText = await page.locator(".proto-account-card").innerText();
    const feedback = await page.locator(".proto-account-feedback").allTextContents();
    console.log("Phase 1B signup diagnostic:", JSON.stringify({
      cardText,
      feedback,
      apiResponses,
      pageErrors,
    }));

    await expect(page.getByRole("heading", { name: "Synthetic Phase One Learner" })).toBeVisible();
    await expect(page.getByText("student", { exact: true })).toBeVisible();

    const displayName = page.getByLabel("Display name");
    await displayName.fill("Synthetic Learner Updated");
    await page.getByRole("button", { name: "Save display name" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Learner Updated" })).toBeVisible();
    await expect(page.getByRole("status").filter({ hasText: "Display name saved." })).toBeVisible();

    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page.getByRole("heading", { name: /create a student account/i })).toBeVisible();
    expect(pageErrors).toEqual([]);
  });
});
