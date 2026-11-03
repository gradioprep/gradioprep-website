import { createHmac } from "node:crypto";
import { expect, test } from "@playwright/test";

function createTotpCode(secret: string, timestamp = Date.now()): string {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  const decoded: number[] = [];
  let buffer = 0;
  let bits = 0;
  for (const character of secret.toUpperCase().replace(/=+$/g, "")) {
    const value = alphabet.indexOf(character);
    if (value < 0) throw new Error("The test authenticator secret is not valid Base32.");
    buffer = (buffer << 5) | value;
    bits += 5;
    if (bits >= 8) {
      decoded.push((buffer >>> (bits - 8)) & 0xff);
      bits -= 8;
      buffer &= (1 << bits) - 1;
    }
  }

  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(timestamp / 30_000)));
  const digest = createHmac("sha1", Buffer.from(decoded)).update(counter).digest();
  const offset = digest[digest.length - 1] & 0x0f;
  const binary = ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);
  return String(binary % 1_000_000).padStart(6, "0");
}

async function waitForTotpWindow(): Promise<void> {
  const remaining = 30_000 - (Date.now() % 30_000);
  if (remaining < 5_000) {
    await new Promise(resolve => setTimeout(resolve, remaining + 500));
  }
}

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

  test("owner enrols TOTP, verifies sign-in and can revoke a role only after MFA", async ({ page }) => {
    test.setTimeout(60_000);
    const accountPageErrors: string[] = [];
    page.on("pageerror", error => accountPageErrors.push(error.message));
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
    await expect(page.getByRole("button", { name: "Set up authenticator app" })).toBeVisible();
    await expect.poll(() => Boolean(ownerToken)).toBe(true);

    const firstFactorToken = ownerToken;
    const firstFactorAttempt = await page.request.post("/api/v1/admin/roles/revoke", {
      headers: { Authorization: firstFactorToken },
      data: roleRequest,
    });
    expect(firstFactorAttempt.status()).toBe(403);
    await expect(firstFactorAttempt.json()).resolves.toMatchObject({ error: "mfa_required" });

    const ownerAal1InvitationList = await page.request.get("/api/v1/admin/staff-invitations", {
      headers: { Authorization: firstFactorToken },
    });
    expect(ownerAal1InvitationList.status()).toBe(403);
    await expect(ownerAal1InvitationList.json()).resolves.toMatchObject({ error: "mfa_required" });

    await page.getByRole("button", { name: "Set up authenticator app" }).click();
    await expect(page.getByRole("img", { name: "Authenticator app setup QR code" })).toBeVisible();
    const secret = await page.getByTestId("totp-secret").innerText();
    await waitForTotpWindow();
    await page.getByLabel("Authenticator code").fill(createTotpCode(secret));
    await page.getByRole("button", { name: "Verify and enable" }).click();
    await page.waitForTimeout(750);
    await expect(page.getByText("Verified authenticator", { exact: true })).toBeVisible();
    await expect.poll(() => ownerToken !== firstFactorToken, { timeout: 10_000 }).toBe(true);

    const verifiedAttempt = await page.request.post("/api/v1/admin/roles/revoke", {
      headers: { Authorization: ownerToken },
      data: roleRequest,
    });
    expect(verifiedAttempt.status()).toBe(200);
    await expect(verifiedAttempt.json()).resolves.toMatchObject({ revoked: true });

    await expect(page.getByRole("heading", { name: "Staff invitations" })).toBeVisible();
    await page.getByLabel("Staff email address").fill("guardian.a@example.invalid");
    await page.getByLabel("Invitation role").selectOption("grader");
    const createInvitationResponsePromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === "/api/v1/admin/staff-invitations" &&
      response.request().method() === "POST"
    );
    await page.getByRole("button", { name: "Create invitation link" }).click();
    const createInvitationResponse = await createInvitationResponsePromise;
    const createInvitationBody = await createInvitationResponse.json() as { error?: string; message?: string; invite_url?: string };
    expect(
      createInvitationResponse.status(),
      "Staff invitation API failed: " + (createInvitationBody.error ?? "unknown_error") +
        (createInvitationBody.message ? " — " + createInvitationBody.message : "")
    ).toBe(201);
    expect(createInvitationBody.invite_url).toMatch(/^https?:\/\//);
    expect(createInvitationBody.invitation).toMatchObject({
      invited_email: "guardian.a@example.invalid",
      invited_role: "grader",
    });
    const invitationLinkField = page.getByTestId("staff-invite-url");
    await expect(invitationLinkField).toBeVisible();
    expect(accountPageErrors).toEqual([]);
    const invitationLink = await invitationLinkField.inputValue();
    const invitationToken = new URLSearchParams(new URL(invitationLink).hash.slice(1)).get("staff-invite");
    expect(invitationToken).toMatch(/^[A-Za-z0-9_-]{43}$/);

    const ownerInvitationList = await page.request.get("/api/v1/admin/staff-invitations", {
      headers: { Authorization: ownerToken },
    });
    expect(ownerInvitationList.status()).toBe(200);
    const listBody = await ownerInvitationList.json() as {
      invitations: Array<{ invited_email: string; invited_role: string; status: string }>;
    };
    expect(listBody.invitations).toEqual(expect.arrayContaining([
      expect.objectContaining({
        invited_email: "guardian.a@example.invalid",
        invited_role: "grader",
        status: "pending",
      }),
    ]));
    expect(JSON.stringify(listBody)).not.toMatch(/token_hash|invite_url|staff-invite=/i);

    const duplicateInvite = await page.request.post("/api/v1/admin/staff-invitations", {
      headers: { Authorization: ownerToken },
      data: { email: "guardian.a@example.invalid", role: "grader" },
    });
    expect(duplicateInvite.status()).toBe(409);
    await expect(duplicateInvite.json()).resolves.toMatchObject({ error: "invitation_already_pending" });

    const mismatchAcceptance = await page.request.post("/api/v1/staff-invitations/accept", {
      headers: { Authorization: ownerToken },
      data: { token: invitationToken },
    });
    expect(mismatchAcceptance.status()).toBe(403);
    await expect(mismatchAcceptance.json()).resolves.toMatchObject({ error: "invitation_email_mismatch" });

    await page.getByLabel("Staff email address").fill("invited.grader@example.invalid");
    await page.getByLabel("Invitation role").selectOption("admin");
    await page.getByRole("button", { name: "Create invitation link" }).click();
    const revokedInvitationUrl = await page.getByTestId("staff-invite-url").inputValue();
    const revokedInvitationToken = new URLSearchParams(new URL(revokedInvitationUrl).hash.slice(1)).get("staff-invite");
    expect(revokedInvitationToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
    page.on("dialog", dialog => dialog.accept());
    await page.getByRole("button", { name: "Revoke invitation for invited.grader@example.invalid" }).click();
    await expect(page.getByText("Revoked", { exact: true })).toBeVisible();

    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();

    // Follow the link as the invited synthetic account. Existing Guardian access
    // remains until the invited Grader role is accepted after the MFA check.
    let inviteeToken = "";
    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        inviteeToken = request.headers()["authorization"] ?? inviteeToken;
      }
    });
    await page.goto(invitationLink);
    await expect(page).toHaveURL(/\/account$/);
    await page.getByLabel("Email address").fill("guardian.a@example.invalid");
    await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Guardian A" })).toBeVisible();
    await expect(page.getByText("Staff invitation pending")).toBeVisible();
    await expect(page.getByRole("button", { name: "Set up authenticator app" })).toBeVisible();
    await expect.poll(() => Boolean(inviteeToken)).toBe(true);

    const firstFactorInviteeToken = inviteeToken;
    const firstFactorInviteAcceptance = await page.request.post("/api/v1/staff-invitations/accept", {
      headers: { Authorization: firstFactorInviteeToken },
      data: { token: invitationToken },
    });
    expect(firstFactorInviteAcceptance.status()).toBe(403);
    await expect(firstFactorInviteAcceptance.json()).resolves.toMatchObject({ error: "mfa_required" });

    let acceptedWithToken = "";
    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/staff-invitations/accept" && request.method() === "POST") {
        acceptedWithToken = request.headers()["authorization"] ?? acceptedWithToken;
      }
    });
    await page.getByRole("button", { name: "Set up authenticator app" }).click();
    await expect(page.getByRole("img", { name: "Authenticator app setup QR code" })).toBeVisible();
    const inviteeSecret = await page.getByTestId("totp-secret").innerText();
    await waitForTotpWindow();
    await page.getByLabel("Authenticator code").fill(createTotpCode(inviteeSecret));
    await page.getByRole("button", { name: "Verify and enable" }).click();
    await expect(page.getByText("Staff invitation accepted. Your grader role is active.")).toBeVisible();
    await expect(page.getByText("grader", { exact: true })).toBeVisible();
    await expect.poll(() => Boolean(acceptedWithToken), { timeout: 10_000 }).toBe(true);

    const revokedAcceptance = await page.request.post("/api/v1/staff-invitations/accept", {
      headers: { Authorization: acceptedWithToken },
      data: { token: revokedInvitationToken },
    });
    expect(revokedAcceptance.status()).toBe(410);
    await expect(revokedAcceptance.json()).resolves.toMatchObject({ error: "invitation_revoked" });

    const replayAttempt = await page.request.post("/api/v1/staff-invitations/accept", {
      headers: { Authorization: acceptedWithToken },
      data: { token: invitationToken },
    });
    expect(replayAttempt.status()).toBe(410);
    await expect(replayAttempt.json()).resolves.toMatchObject({ error: "invitation_already_used" });

    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();

    await waitForTotpWindow();
    await page.getByLabel("Email address").fill("owner@example.invalid");
    await page.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Verify your sign-in." })).toBeVisible();
    await waitForTotpWindow();
    await page.getByLabel("Authenticator code").fill(createTotpCode(secret));
    await page.getByRole("button", { name: "Verify code" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Owner" })).toBeVisible();

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

    const adminInvitationList = await page.request.get("/api/v1/admin/staff-invitations", {
      headers: { Authorization: adminToken },
    });
    expect(adminInvitationList.status()).toBe(403);
    await expect(adminInvitationList.json()).resolves.toMatchObject({ error: "staff_invitation_forbidden" });
  });

  test("role revocation and staff invitation endpoints reject anonymous and malformed requests", async ({ request }) => {
    const anonymousInvitationList = await request.get("/api/v1/admin/staff-invitations");
    expect(anonymousInvitationList.status()).toBe(401);

    const invalidInvitation = await request.post("/api/v1/admin/staff-invitations", {
      data: { email: "invite@example.invalid", role: "owner" },
    });
    expect(invalidInvitation.status()).toBe(400);

    const malformedAccept = await request.post("/api/v1/staff-invitations/accept", {
      data: { token: "short-token" },
    });
    expect(malformedAccept.status()).toBe(400);

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
