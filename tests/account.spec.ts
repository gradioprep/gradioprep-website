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

  test("profile updates reject anonymous requests", async ({ request }) => {
    const response = await request.patch("/api/v1/me", {
      data: { display_name: "Should Not Be Saved" },
    });
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

  test("suspended account cannot read or update protected profile data", async ({ page }) => {
    let authorization = "";
    const diagnostics: {
      authStatus: number | null;
      authError: string | null;
      meStatus: number | null;
      meError: string | null;
      meMessage: string | null;
      pageErrors: string[];
    } = {
      authStatus: null,
      authError: null,
      meStatus: null,
      meError: null,
      meMessage: null,
      pageErrors: [],
    };

    page.on("pageerror", error => diagnostics.pageErrors.push(error.message));
    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        authorization = request.headers()["authorization"] ?? "";
      }
    });
    page.on("response", async response => {
      const pathname = new URL(response.url()).pathname;
      if (pathname === "/auth/v1/token") {
        diagnostics.authStatus = response.status();
        const body = await response.json().catch(() => ({})) as { error?: string; error_description?: string; msg?: string };
        diagnostics.authError = body.error_description ?? body.msg ?? body.error ?? null;
      }
      if (pathname === "/api/v1/me" && response.request().method() === "GET") {
        diagnostics.meStatus = response.status();
        const body = await response.json().catch(() => ({})) as { error?: string; message?: string };
        diagnostics.meError = body.error ?? null;
        diagnostics.meMessage = body.message ?? null;
      }
    });

    await page.goto("/account");
    await page.getByLabel("Email address").fill("suspended.student@example.invalid");
    await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await page.getByRole("button", { name: "Sign in" }).click();
    await page.waitForTimeout(1_000);

    const cardText = await page.locator(".proto-account-card").innerText().catch(() => "<account card not found>");
    const feedback = await page.locator(".proto-account-feedback").allTextContents().catch(() => []);
    console.log("Suspended-account diagnostic:", JSON.stringify({
      ...diagnostics,
      authorizationPresent: Boolean(authorization),
      cardText,
      feedback,
    }));

    expect(authorization).toMatch(/^Bearer\s+\S+/);
    expect(diagnostics.meStatus).toBe(403);
    expect(diagnostics.meError).toBe("account_unavailable");
    await expect(page.getByRole("heading", { name: "Account access is unavailable." })).toBeVisible();
    await expect(page.getByText("This account cannot access protected GradiPrep records.")).toBeVisible();

    const update = await page.request.patch("/api/v1/me", {
      headers: { Authorization: authorization },
      data: { display_name: "Suspended Profile Tampering" },
    });
    expect(update.status()).toBe(403);
    await expect(update.json()).resolves.toMatchObject({ error: "account_unavailable" });

    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();
  });

  test("synthetic student can recover a password through the local test inbox", async ({ page }) => {
    const mailpitUrl = "http://127.0.0.1:54324/api/v1";
    const resetPassword = "Recovered-local-only-GradiPrep-2026!";

    await page.goto("/account");
    await page.getByRole("button", { name: "Forgot password?" }).click();
    await expect(page.getByRole("heading", { name: "Reset your password." })).toBeVisible();
    await page.getByLabel("Email address").fill("student.b@example.invalid");
    await page.getByRole("button", { name: "Send recovery link" }).click();
    await expect(page.getByRole("status").filter({
      hasText: "If an account matches that email address",
    })).toBeVisible();

    let matchingMessage: { ID: string } | undefined;
    await expect.poll(async () => {
      const response = await page.request.get(`${mailpitUrl}/messages?limit=50`);
      if (!response.ok()) return 0;
      const inbox = await response.json() as {
        messages?: Array<{ ID: string; To?: Array<{ Address?: string }> }>;
      };
      matchingMessage = inbox.messages?.find(message =>
        message.To?.some(recipient => recipient.Address?.toLowerCase() === "student.b@example.invalid")
      );
      return matchingMessage ? 1 : 0;
    }, { timeout: 10_000 }).toBe(1);

    const messageResponse = await page.request.get(`${mailpitUrl}/message/${matchingMessage!.ID}`);
    expect(messageResponse.ok()).toBeTruthy();
    const message = await messageResponse.json() as {
      HTML?: string;
      Text?: string;
    };
    const emailBody = [message.HTML, message.Text]
      .filter((part): part is string => Boolean(part))
      .join("\n")
      .replace(/&amp;/g, "&");
    const recoveryLink = emailBody.match(/https?:\/\/[^\s"'<>]+/g)
      ?.find((link) => link.includes("/auth/v1/verify"));
    expect(recoveryLink, "the local recovery email must contain a Supabase verification link").toBeTruthy();

    await page.goto(recoveryLink!);
    await expect(page.getByRole("heading", { name: "Choose a new password." })).toBeVisible();
    await page.getByLabel("New password", { exact: true }).fill(resetPassword);
    await page.getByLabel("Confirm new password", { exact: true }).fill(resetPassword);
    await page.getByRole("button", { name: "Update password" }).click();
    await expect(page.getByRole("status").filter({ hasText: "Password updated." })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Synthetic Student B" })).toBeVisible();

    await page.getByRole("button", { name: "Sign out" }).click();
    await page.getByLabel("Email address").fill("student.b@example.invalid");
    await page.getByLabel("Password").fill(resetPassword);
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Student B" })).toBeVisible();
  });


  test("global sign out revokes every synthetic session and blocks a stale access token", async ({ page, browser }) => {
    const secondContext = await browser.newContext();
    const secondPage = await secondContext.newPage();
    let secondRefreshToken = "";
    let publishableKey = "";
    let secondAccessToken = "";

    secondPage.on("request", request => {
      if (new URL(request.url()).pathname === "/auth/v1/token") {
        publishableKey = request.headers()["apikey"] ?? publishableKey;
      }
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        secondAccessToken = request.headers()["authorization"]?.replace(/^Bearer\s+/i, "") ?? secondAccessToken;
      }
    });
    secondPage.on("response", async response => {
      if (new URL(response.url()).pathname === "/auth/v1/token") {
        const body = await response.json().catch(() => ({})) as { refresh_token?: string };
        if (body.refresh_token) secondRefreshToken = body.refresh_token;
      }
    });

    try {
      await secondPage.goto("http://127.0.0.1:8787/account");
      await secondPage.getByLabel("Email address").fill("student.a@example.invalid");
      await secondPage.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
      await secondPage.getByRole("button", { name: "Sign in" }).click();
      await expect(secondPage.getByRole("heading", { name: "Synthetic Student A" })).toBeVisible();
      await expect.poll(() => Boolean(secondRefreshToken && publishableKey && secondAccessToken)).toBe(true);

      await page.goto("/account");
      await page.getByLabel("Email address").fill("student.a@example.invalid");
      await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
      await page.getByRole("button", { name: "Sign in" }).click();
      await expect(page.getByRole("heading", { name: "Synthetic Student A" })).toBeVisible();

      await page.getByRole("button", { name: "Sign out" }).click();
      await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();

      const refreshAttempt = await secondPage.request.post(
        "http://127.0.0.1:54321/auth/v1/token?grant_type=refresh_token",
        {
          headers: {
            apikey: publishableKey,
            "Content-Type": "application/json",
          },
          data: { refresh_token: secondRefreshToken },
        },
      );
      expect([400, 401]).toContain(refreshAttempt.status());

      const staleApiResponse = await secondPage.request.get("/api/v1/me", {
        headers: { Authorization: `Bearer ${secondAccessToken}` },
      });
      expect(staleApiResponse.status()).toBe(401);
      await expect(staleApiResponse.json()).resolves.toMatchObject({
        error: "authentication_required",
        code: "session_revoked",
      });

      await secondPage.reload();
      await expect(secondPage.getByRole("heading", { name: /welcome back/i })).toBeVisible();
    } finally {
      await secondContext.close();
    }
  });

  test("role revocation API is MFA-gated and unavailable to non-owners", async ({ page }) => {
    const roleRequest = {
      target_user_id: "66666666-6666-4666-8666-666666666666",
      role: "grader",
      reason: "Synthetic access review",
    };
    let ownerToken = "";

    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        ownerToken = request.headers()["authorization"] ?? ownerToken;
      }
    });

    await page.goto("/account");
    await page.getByLabel("Email address").fill("owner@example.invalid");
    await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Owner" })).toBeVisible();
    await expect.poll(() => Boolean(ownerToken)).toBe(true);

    const ownerAttempt = await page.request.post("/api/v1/admin/roles/revoke", {
      headers: { Authorization: ownerToken },
      data: roleRequest,
    });
    expect(ownerAttempt.status()).toBe(403);
    await expect(ownerAttempt.json()).resolves.toMatchObject({ error: "mfa_required" });

    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();

    let adminToken = "";
    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        adminToken = request.headers()["authorization"] ?? adminToken;
      }
    });
    await page.getByLabel("Email address").fill("admin@example.invalid");
    await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Admin" })).toBeVisible();
    await expect.poll(() => Boolean(adminToken)).toBe(true);

    const adminAttempt = await page.request.post("/api/v1/admin/roles/revoke", {
      headers: { Authorization: adminToken },
      data: roleRequest,
    });
    expect(adminAttempt.status()).toBe(403);
    await expect(adminAttempt.json()).resolves.toMatchObject({ error: "role_management_forbidden" });
  });

  test("role revocation endpoint rejects anonymous and malformed requests", async ({ request }) => {
    const anonymous = await request.post("/api/v1/admin/roles/revoke", {
      data: {
        target_user_id: "66666666-6666-4666-8666-666666666666",
        role: "grader",
        reason: "Synthetic access review",
      },
    });
    expect(anonymous.status()).toBe(401);

    const invalid = await request.post("/api/v1/admin/roles/revoke", {
      data: {
        target_user_id: "not-a-user",
        role: "owner",
        reason: "x",
        granted_by: "88888888-8888-4888-8888-888888888888",
      },
    });
    expect(invalid.status()).toBe(400);
    await expect(invalid.json()).resolves.toMatchObject({ error: "invalid_role_revocation" });
  });

});
