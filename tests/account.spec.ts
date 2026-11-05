import { execFileSync } from "node:child_process";
import { createHmac, randomUUID } from "node:crypto";
import { expect, test } from "@playwright/test";
import { assertPersistedAuditCorrelation, readPersistedAuditTargetId } from "./audit-assertions";

function localSqlCsv(sql: string): string {
  try {
    return execFileSync(
      "npx",
      ["--no-install", "supabase", "db", "query", sql, "--local", "--output", "csv"],
      {
        cwd: process.cwd(),
        encoding: "utf8",
        timeout: 30_000,
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
  } catch (error) {
    const details = error && typeof error === "object" && "stderr" in error
      ? String((error as { stderr?: string | Buffer }).stderr ?? "").trim().slice(-1200)
      : String(error);
    throw new Error("The local invitation audit verification query failed: " + details);
  }
}

function assertStaffInvitationAuditCorrelation(args: {
  requestId: string | undefined;
  actorId: string;
  actorRole: "student" | "guardian" | "grader" | "admin" | "owner";
  invitationId: string;
  outcome: "success" | "denied" | "failed";
  reason: string;
}): void {
  assertPersistedAuditCorrelation(args.requestId, {
    actorId: args.actorId, actorRole: args.actorRole, action: "staff_invitation_accepted",
    targetType: "staff_invitation", targetId: args.invitationId, outcome: args.outcome, reason: args.reason,
  });
}

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

  test("owner enrols TOTP, verifies sign-in and can revoke a role only after MFA", async ({ page, browser }) => {
    test.setTimeout(90_000);

    const learnerContext = await browser.newContext();
    const learnerPage = await learnerContext.newPage();
    let learnerToken = "";
    learnerPage.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        learnerToken = request.headers()["authorization"] ?? learnerToken;
      }
    });
    await learnerPage.goto("/account");
    await learnerPage.getByLabel("Email address").fill("student.a@example.invalid");
    await learnerPage.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await learnerPage.getByRole("button", { name: "Sign in" }).click();
    await expect(learnerPage.getByRole("heading", { name: "Synthetic Student A" })).toBeVisible();
    await expect.poll(() => Boolean(learnerToken)).toBe(true);
    const learnerAcceptance = await learnerPage.request.post("/api/v1/learner/submissions", {
      headers: { Authorization: learnerToken },
      data: {
        task_version_id: "a1111111-1111-4111-8111-111111111111",
        idempotency_key: randomUUID(),
        response_text: "A synthetic assessment submission created to verify owner-controlled grader lifecycle routes and audit integrity.",
      },
    });
    const learnerAcceptanceBody = await learnerAcceptance.json() as {
      submission: { submission_id: string };
    };
    expect(learnerAcceptance.status(), JSON.stringify(learnerAcceptanceBody)).toBe(201);
    const lifecycleSubmissionId = learnerAcceptanceBody.submission.submission_id;
    await learnerContext.close();
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
    assertPersistedAuditCorrelation(firstFactorAttempt.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_role_revocation", targetType: "role_assignment_subject",
      targetId: roleRequest.target_user_id, outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1InvitationList = await page.request.get("/api/v1/admin/staff-invitations", {
      headers: { Authorization: firstFactorToken },
    });
    expect(ownerAal1InvitationList.status()).toBe(403);
    await expect(ownerAal1InvitationList.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1InvitationList.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitations_listed", targetType: "staff_invitation_collection",
      targetId: null, outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1InvitationCreate = await page.request.post("/api/v1/admin/staff-invitations", {
      headers: { Authorization: firstFactorToken },
      data: { email: "aal1-denial@example.invalid", role: "grader" },
    });
    expect(ownerAal1InvitationCreate.status()).toBe(403);
    await expect(ownerAal1InvitationCreate.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1InvitationCreate.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitation_created", targetType: "staff_invitation",
      targetId: null, outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1Assignment = await page.request.post(
      "/api/v1/admin/attempts/c3333333-3333-4333-8333-333333333333/assign",
      {
        headers: { Authorization: firstFactorToken },
        data: {
          grader_user_id: "55555555-5555-4555-8555-555555555555",
          reason: "Synthetic AAL1 assignment denial",
        },
      },
    );
    expect(ownerAal1Assignment.status()).toBe(403);
    await expect(ownerAal1Assignment.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1Assignment.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_attempt_assignment", targetType: "attempt",
      targetId: "c3333333-3333-4333-8333-333333333333", outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1SubmissionAssignment = await page.request.post(
      "/api/v1/admin/submissions/" + lifecycleSubmissionId + "/assign",
      { headers: { Authorization: firstFactorToken },
        data: { grader_user_id: "55555555-5555-4555-8555-555555555555", reason: "Synthetic AAL1 assignment denial" } },
    );
    expect(ownerAal1SubmissionAssignment.status()).toBe(403);
    assertPersistedAuditCorrelation(ownerAal1SubmissionAssignment.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_submission_assignment", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "denied", reason: "resource_scope_denied",
    });
    const ownerAal1Reassignment = await page.request.post(
      "/api/v1/owner/submissions/" + lifecycleSubmissionId + "/reassign",
      {
        headers: { Authorization: firstFactorToken },
        data: {
          grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
          reason: "Synthetic AAL1 reassignment denial",
        },
      },
    );
    expect(ownerAal1Reassignment.status()).toBe(403);
    await expect(ownerAal1Reassignment.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1Reassignment.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_submission_reassignment", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1Transition = await page.request.post(
      "/api/v1/owner/submissions/" + lifecycleSubmissionId + "/transition",
      {
        headers: { Authorization: firstFactorToken },
        data: { target_status: "withdrawn", reason: "Synthetic AAL1 transition denial" },
      },
    );
    expect(ownerAal1Transition.status()).toBe(403);
    await expect(ownerAal1Transition.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1Transition.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_submission_transition", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1QaRead = await page.request.get(
      "/api/v1/owner/assessment-versions/d3333333-3333-4333-8333-333333333333/private-qa",
      { headers: { Authorization: firstFactorToken } },
    );
    expect(ownerAal1QaRead.status()).toBe(403);
    await expect(ownerAal1QaRead.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1QaRead.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "private_qa_records_read", targetType: "assessment_version",
      targetId: "d3333333-3333-4333-8333-333333333333", outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1QaCreate = await page.request.post(
      "/api/v1/owner/assessment-versions/d3333333-3333-4333-8333-333333333333/private-qa",
      {
        headers: { Authorization: firstFactorToken },
        data: {
          checks: { rubric_alignment: true },
          status: "passed",
          explanation: "Synthetic QA route denial test.",
          reviewer_action: "No change required.",
        },
      },
    );
    expect(ownerAal1QaCreate.status()).toBe(403);
    await expect(ownerAal1QaCreate.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1QaCreate.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_private_qa_record_create", targetType: "assessment_version",
      targetId: "d3333333-3333-4333-8333-333333333333", outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal1SubmissionQueue = await page.request.get("/api/v1/admin/submissions/queue", {
      headers: { Authorization: firstFactorToken },
    });
    expect(ownerAal1SubmissionQueue.status()).toBe(403);
    await expect(ownerAal1SubmissionQueue.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1SubmissionQueue.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_submission_queue_authorized", targetType: "assessment_submission_queue",
      targetId: null, outcome: "denied", reason: "resource_scope_denied",
    });

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
    const roleEventTarget = readPersistedAuditTargetId(verifiedAttempt.headers()["x-request-id"], "role_revoked");
    assertPersistedAuditCorrelation(verifiedAttempt.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "role_revoked", targetType: "role_assignment", targetId: roleEventTarget,
      outcome: "success", reason: "Synthetic access review",
    });

    const attemptAssignmentUrl = "/api/v1/admin/attempts/c3333333-3333-4333-8333-333333333333/assign";
    const concurrentAttemptAssignments = await Promise.all([
      page.request.post(attemptAssignmentUrl, {
        headers: { Authorization: ownerToken },
        data: {
          grader_user_id: "55555555-5555-4555-8555-555555555555",
          reason: "Synthetic concurrent assignment A",
        },
      }),
      page.request.post(attemptAssignmentUrl, {
        headers: { Authorization: ownerToken },
        data: {
          grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
          reason: "Synthetic concurrent assignment B",
        },
      }),
    ]);
    const concurrentAttemptBodies = await Promise.all(
      concurrentAttemptAssignments.map(response => response.json()),
    ) as Array<{ error?: string; assignment?: { attempt_id: string; grader_user_id: string } }>;
    expect(concurrentAttemptAssignments.map(response => response.status()).sort()).toEqual([201, 409]);
    const successfulAttemptAssignment = concurrentAttemptBodies.find(body => body.assignment);
    const rejectedAttemptAssignment = concurrentAttemptBodies.find(body => body.error);
    const successfulIndex = concurrentAttemptBodies.findIndex(body => body.assignment);
    const failedIndex = concurrentAttemptBodies.findIndex(body => body.error);
    const assignmentAuditTarget = readPersistedAuditTargetId(
      concurrentAttemptAssignments[successfulIndex].headers()["x-request-id"], "attempt_assigned_to_grader",
    );
    assertPersistedAuditCorrelation(concurrentAttemptAssignments[successfulIndex].headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "attempt_assigned_to_grader", targetType: "grader_assignment",
      targetId: assignmentAuditTarget, outcome: "success", reason: "owner_assignment",
    });
    assertPersistedAuditCorrelation(concurrentAttemptAssignments[failedIndex].headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_attempt_assignment", targetType: "attempt",
      targetId: "c3333333-3333-4333-8333-333333333333", outcome: "failed", reason: "state_conflict",
    });
    expect(successfulAttemptAssignment?.assignment?.attempt_id).toBe("c3333333-3333-4333-8333-333333333333");
    expect(["55555555-5555-4555-8555-555555555555", "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"])
      .toContain(successfulAttemptAssignment?.assignment?.grader_user_id);
    expect(rejectedAttemptAssignment?.error).toBe("attempt_already_assigned");

    const ownerAal2QaRead = await page.request.get(
      "/api/v1/owner/assessment-versions/d3333333-3333-4333-8333-333333333333/private-qa",
      { headers: { Authorization: ownerToken } },
    );
    expect(ownerAal2QaRead.status()).toBe(404);
    await expect(ownerAal2QaRead.json()).resolves.toMatchObject({ error: "assessment_version_not_found" });
    assertPersistedAuditCorrelation(ownerAal2QaRead.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "private_qa_records_read", targetType: "assessment_version",
      targetId: "d3333333-3333-4333-8333-333333333333", outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerAal2QaCreate = await page.request.post(
      "/api/v1/owner/assessment-versions/d3333333-3333-4333-8333-333333333333/private-qa",
      {
        headers: { Authorization: ownerToken },
        data: {
          checks: { rubric_alignment: true },
          status: "passed",
          explanation: "Synthetic QA route denial test.",
          reviewer_action: "No change required.",
        },
      },
    );
    expect(ownerAal2QaCreate.status()).toBe(404);
    await expect(ownerAal2QaCreate.json()).resolves.toMatchObject({ error: "assessment_version_not_found" });
    assertPersistedAuditCorrelation(ownerAal2QaCreate.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_private_qa_record_create", targetType: "assessment_version",
      targetId: "d3333333-3333-4333-8333-333333333333", outcome: "failed", reason: "resource_not_found",
    });

    const ownerAal2InitialSubmissionAssignment = await page.request.post(
      "/api/v1/admin/submissions/" + lifecycleSubmissionId + "/assign",
      {
        headers: { Authorization: ownerToken },
        data: {
          grader_user_id: "55555555-5555-4555-8555-555555555555",
          reason: "Synthetic initial assessment assignment",
        },
      },
    );
    expect(ownerAal2InitialSubmissionAssignment.status()).toBe(201);
    assertPersistedAuditCorrelation(ownerAal2InitialSubmissionAssignment.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "assessment_submission_assigned", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "owner_assignment",
    });

    const ownerAal2Reassignment = await page.request.post(
      "/api/v1/owner/submissions/" + lifecycleSubmissionId + "/reassign",
      {
        headers: { Authorization: ownerToken },
        data: {
          grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
          reason: "Synthetic owner reassignment",
        },
      },
    );
    const reassignmentBody = await ownerAal2Reassignment.json() as Record<string, unknown>;
    expect(ownerAal2Reassignment.status(), JSON.stringify(reassignmentBody)).toBe(200);
    expect(reassignmentBody).toMatchObject({
      reassignment: {
        submission_id: lifecycleSubmissionId,
        previous_grader_user_id: "55555555-5555-4555-8555-555555555555",
        new_grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
        submission_status: "assigned",
      },
    });
    assertPersistedAuditCorrelation(ownerAal2Reassignment.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "assessment_submission_reassigned", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "owner_reassignment",
    });

    const ownerAal2Transition = await page.request.post(
      "/api/v1/owner/submissions/" + lifecycleSubmissionId + "/transition",
      {
        headers: { Authorization: ownerToken },
        data: {
          target_status: "queued",
          reason: "Synthetic owner queue transition",
        },
      },
    );
    const transitionBody = await ownerAal2Transition.json() as Record<string, unknown>;
    expect(ownerAal2Transition.status(), JSON.stringify(transitionBody)).toBe(200);
    expect(transitionBody).toMatchObject({
      transition: {
        submission_id: lifecycleSubmissionId,
        previous_status: "assigned",
        status: "queued",
        active_assignment_revoked: true,
      },
    });
    assertPersistedAuditCorrelation(ownerAal2Transition.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "assessment_submission_unassigned", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "owner_requeue",
    });

    const ownerAal2SubmissionQueue = await page.request.get("/api/v1/admin/submissions/queue", {
      headers: { Authorization: ownerToken },
    });
    const ownerQueueBody = await ownerAal2SubmissionQueue.json() as {
      submissions: Array<{ accepted_at: string; status: string }>;
    };
    expect(ownerAal2SubmissionQueue.status(), JSON.stringify(ownerQueueBody)).toBe(200);
    assertPersistedAuditCorrelation(ownerAal2SubmissionQueue.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_submission_queue_authorized", targetType: "assessment_submission_queue",
      targetId: null, outcome: "success", reason: "owner_aal2",
    });
    const acceptedTimes = ownerQueueBody.submissions.map(item => Date.parse(item.accepted_at));
    expect(acceptedTimes).toEqual([...acceptedTimes].sort((first, second) => first - second));


    const duplicateAttemptAssignment = await page.request.post(
      "/api/v1/admin/attempts/c3333333-3333-4333-8333-333333333333/assign",
      {
        headers: { Authorization: ownerToken },
        data: {
          grader_user_id: "55555555-5555-4555-8555-555555555555",
          reason: "Synthetic duplicate assignment",
        },
      },
    );
    expect(duplicateAttemptAssignment.status()).toBe(409);
    await expect(duplicateAttemptAssignment.json()).resolves.toMatchObject({ error: "attempt_already_assigned" });
    assertPersistedAuditCorrelation(duplicateAttemptAssignment.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "owner_attempt_assignment", targetType: "attempt",
      targetId: "c3333333-3333-4333-8333-333333333333", outcome: "failed", reason: "state_conflict",
    });

    await expect(page.getByRole("heading", { name: "Staff invitations" })).toBeVisible();
    await page.getByLabel("Staff email address").fill("guardian.a@example.invalid");
    await page.getByLabel("Invitation role").selectOption("grader");
    const createInvitationResponsePromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === "/api/v1/admin/staff-invitations" &&
      response.request().method() === "POST"
    );
    await page.getByRole("button", { name: "Create invitation link" }).click();
    const createInvitationResponse = await createInvitationResponsePromise;
    const createInvitationBody = await createInvitationResponse.json() as {
      error?: string;
      message?: string;
      invite_url?: string;
      invitation?: { invitation_id?: string; invited_email?: string; invited_role?: string };
    };
    expect(
      createInvitationResponse.status(),
      "Staff invitation API failed: " + (createInvitationBody.error ?? "unknown_error") +
        (createInvitationBody.message ? " — " + createInvitationBody.message : "")
    ).toBe(201);
    assertPersistedAuditCorrelation(createInvitationResponse.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitation_created", targetType: "staff_invitation",
      targetId: createInvitationBody.invitation?.invitation_id ?? null,
      outcome: "success", reason: "grader",
    });
    expect(createInvitationBody.invite_url).toMatch(/^https?:\/\//);
    expect(createInvitationBody.invitation).toMatchObject({
      invited_email: "guardian.a@example.invalid",
      invited_role: "grader",
    });
    const invitationLinkField = page.getByTestId("staff-invite-url");
    const invitationFieldVisible = await invitationLinkField.isVisible().catch(() => false);
    if (!invitationFieldVisible) {
      const alerts = await page.getByRole("alert").allTextContents().catch(() => []);
      const statuses = await page.getByRole("status").allTextContents().catch(() => []);
      throw new Error(
        "Invitation UI did not render the returned link. " +
        "Client errors: " + JSON.stringify(accountPageErrors) +
        "; alerts: " + JSON.stringify(alerts) +
        "; statuses: " + JSON.stringify(statuses) +
        "; owner panel visible: " + await page.getByRole("heading", { name: "Staff invitations" }).isVisible().catch(() => false)
      );
    }
    expect(accountPageErrors).toEqual([]);
    const invitationLink = await invitationLinkField.inputValue();
    const invitationToken = new URLSearchParams(new URL(invitationLink).hash.slice(1)).get("staff-invite");
    expect(invitationToken).toMatch(/^[A-Za-z0-9_-]{43}$/);

    const ownerAal1InvitationRevoke = await page.request.post(
      `/api/v1/admin/staff-invitations/${createInvitationBody.invitation!.invitation_id}/revoke`,
      {
        headers: { Authorization: firstFactorToken },
        data: { reason: "Synthetic AAL1 invitation revocation denial" },
      },
    );
    expect(ownerAal1InvitationRevoke.status()).toBe(403);
    await expect(ownerAal1InvitationRevoke.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(ownerAal1InvitationRevoke.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitation_revoked", targetType: "staff_invitation",
      targetId: createInvitationBody.invitation!.invitation_id!,
      outcome: "denied", reason: "resource_scope_denied",
    });

    const ownerInvitationList = await page.request.get("/api/v1/admin/staff-invitations", {
      headers: { Authorization: ownerToken },
    });
    expect(ownerInvitationList.status()).toBe(200);
    assertPersistedAuditCorrelation(ownerInvitationList.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitations_listed", targetType: "staff_invitation_collection",
      targetId: null, outcome: "success", reason: "owner_aal2",
    });
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
    assertPersistedAuditCorrelation(duplicateInvite.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitation_created", targetType: "staff_invitation",
      targetId: null, outcome: "failed", reason: "state_conflict",
    });

    const mismatchAcceptance = await page.request.post("/api/v1/staff-invitations/accept", {
      headers: { Authorization: ownerToken },
      data: { token: invitationToken },
    });
    expect(mismatchAcceptance.status()).toBe(403);
    await expect(mismatchAcceptance.json()).resolves.toMatchObject({ error: "invitation_email_mismatch" });
    assertStaffInvitationAuditCorrelation({
      requestId: mismatchAcceptance.headers()["x-request-id"],
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      invitationId: createInvitationBody.invitation!.invitation_id!,
      outcome: "denied",
      reason: "email_mismatch",
    });

    // Exercise the separate caller-scoped acceptance helper's false-ack path.
    // The temporary local-only trigger makes the real acceptance RPC fail while
    // leaving the invite otherwise eligible; the helper must refuse to invent
    // a failure event and the Worker must return 503 rather than the RPC error.
    const acceptanceFailureInvite = await page.request.post("/api/v1/admin/staff-invitations", {
      headers: { Authorization: ownerToken },
      data: { email: "owner@example.invalid", role: "grader" },
    });
    expect(acceptanceFailureInvite.status()).toBe(201);
    const acceptanceFailureInviteBody = await acceptanceFailureInvite.json() as {
      invitation?: { invitation_id?: string };
      invite_url?: string;
    };
    const acceptanceFailureInvitationId = acceptanceFailureInviteBody.invitation?.invitation_id;
    const acceptanceFailureToken = acceptanceFailureInviteBody.invite_url
      ? new URLSearchParams(new URL(acceptanceFailureInviteBody.invite_url).hash.slice(1)).get("staff-invite")
      : null;
    expect(acceptanceFailureInvitationId).toMatch(/^[0-9a-f-]{36}$/i);
    expect(acceptanceFailureToken).toMatch(/^[A-Za-z0-9_-]{43}$/);

    localSqlCsv(`
      CREATE OR REPLACE FUNCTION public.gradioprep_test_fail_invitation_role_insert()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $test$
      BEGIN
        IF NEW.user_id = '88888888-8888-4888-8888-888888888888'::uuid
          AND NEW.role = 'grader'::public.app_role
          AND NEW.reason = 'accepted_staff_invitation' THEN
          RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'synthetic_staff_invitation_acceptance_failure';
        END IF;
        RETURN NEW;
      END;
      $test$;
    `);
    localSqlCsv(`DROP TRIGGER IF EXISTS gradioprep_test_fail_invitation_role_insert ON public.role_assignments;`);
    localSqlCsv(`
      CREATE TRIGGER gradioprep_test_fail_invitation_role_insert
      BEFORE INSERT ON public.role_assignments
      FOR EACH ROW EXECUTE FUNCTION public.gradioprep_test_fail_invitation_role_insert();
    `);
    try {
      const unacknowledgedAcceptance = await page.request.post("/api/v1/staff-invitations/accept", {
        headers: { Authorization: ownerToken },
        data: { token: acceptanceFailureToken },
      });
      expect(unacknowledgedAcceptance.status()).toBe(503);
      await expect(unacknowledgedAcceptance.json()).resolves.toMatchObject({
        error: "staff_invitation_audit_unavailable",
      });
      expect(unacknowledgedAcceptance.headers()["x-request-id"]).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
      );
      const noFalseEvent = localSqlCsv(`
        SELECT CASE WHEN count(*) = 0
          THEN 'NO_FALSE_ACCEPTANCE_AUDIT_EVENT'
          ELSE 'UNEXPECTED_ACCEPTANCE_AUDIT_EVENT'
        END AS result
        FROM private.security_audit_events
        WHERE action = 'staff_invitation_accepted'
          AND target_id = '${acceptanceFailureInvitationId}'::uuid;
      `);
      expect(noFalseEvent).toContain("NO_FALSE_ACCEPTANCE_AUDIT_EVENT");
    } finally {
      localSqlCsv(`DROP TRIGGER IF EXISTS gradioprep_test_fail_invitation_role_insert ON public.role_assignments;`);
      localSqlCsv(`DROP FUNCTION IF EXISTS public.gradioprep_test_fail_invitation_role_insert();`);
    }

    await page.getByLabel("Staff email address").fill("invited.grader@example.invalid");
    await page.getByLabel("Invitation role").selectOption("admin");
    const revokeCreatePromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === "/api/v1/admin/staff-invitations" &&
      response.request().method() === "POST"
    );
    await page.getByRole("button", { name: "Create invitation link" }).click();
    const revokeCreate = await revokeCreatePromise;
    const revokeCreateBody = await revokeCreate.json() as { invitation?: { invitation_id?: string } };
    expect(revokeCreate.status()).toBe(201);
    const revokedInvitationId = revokeCreateBody.invitation?.invitation_id;
    assertPersistedAuditCorrelation(revokeCreate.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitation_created", targetType: "staff_invitation",
      targetId: revokedInvitationId ?? null, outcome: "success", reason: "admin",
    });
    const revokedInvitationUrl = await page.getByTestId("staff-invite-url").inputValue();
    const revokedInvitationToken = new URLSearchParams(new URL(revokedInvitationUrl).hash.slice(1)).get("staff-invite");
    expect(revokedInvitationToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
    page.on("dialog", dialog => dialog.accept());
    const revokeResponsePromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === `/api/v1/admin/staff-invitations/${revokedInvitationId}/revoke` &&
      response.request().method() === "POST"
    );
    await page.getByRole("button", { name: "Revoke invitation for invited.grader@example.invalid" }).click();
    const revokeResponse = await revokeResponsePromise;
    expect(revokeResponse.status()).toBe(200);
    assertPersistedAuditCorrelation(revokeResponse.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "staff_invitation_revoked", targetType: "staff_invitation", targetId: revokedInvitationId!,
      outcome: "success", reason: "owner_revocation",
    });
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
    assertStaffInvitationAuditCorrelation({
      requestId: firstFactorInviteAcceptance.headers()["x-request-id"],
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "guardian",
      invitationId: createInvitationBody.invitation!.invitation_id!,
      outcome: "denied",
      reason: "aal2_required",
    });

    let acceptedWithToken = "";
    let acceptedRequestId: string | undefined;
    page.on("response", response => {
      if (new URL(response.url()).pathname === "/api/v1/staff-invitations/accept" &&
          response.request().method() === "POST") {
        acceptedRequestId = response.headers()["x-request-id"];
      }
    });
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
    await expect.poll(() => Boolean(acceptedRequestId), { timeout: 10_000 }).toBe(true);
    assertStaffInvitationAuditCorrelation({
      requestId: acceptedRequestId,
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      invitationId: createInvitationBody.invitation!.invitation_id!,
      outcome: "success",
      reason: "grader",
    });

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
    await expect.poll(() => Boolean(ownerToken)).toBe(true);

    // Concurrency acceptance: owner assigns one queued submission to the newly
    // accepted synthetic grader, then two simultaneous publish requests race on
    // the same saved draft. Exactly one first publication must be created.
    const lifecycleAssignment = await page.request.post(
      "/api/v1/admin/submissions/" + lifecycleSubmissionId + "/assign",
      {
        headers: { Authorization: ownerToken },
        data: {
          grader_user_id: "33333333-3333-4333-8333-333333333333",
          reason: "Synthetic publication concurrency assignment",
        },
      },
    );
    expect(lifecycleAssignment.status()).toBe(201);

    const freshGraderContext = await browser.newContext();
    const freshGraderPage = await freshGraderContext.newPage();
    let freshGraderToken = "";
    freshGraderPage.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        freshGraderToken = request.headers()["authorization"] ?? freshGraderToken;
      }
    });
    await freshGraderPage.goto("/account");
    await freshGraderPage.getByLabel("Email address").fill("guardian.a@example.invalid");
    await freshGraderPage.getByLabel("Password").fill("Local-only-GradiPrep-2026!");
    await freshGraderPage.getByRole("button", { name: "Sign in" }).click();
    // This account already enrolled TOTP during invitation acceptance, so a
    // new sign-in correctly presents MFA verification before loading the profile.
    await expect(freshGraderPage.getByRole("heading", { name: "Verify your sign-in." })).toBeVisible();
    await waitForTotpWindow();
    await freshGraderPage.getByLabel("Authenticator code").fill(createTotpCode(inviteeSecret));
    await freshGraderPage.getByRole("button", { name: "Verify code" }).click();
    await expect(freshGraderPage.getByRole("heading", { name: "Synthetic Guardian A" })).toBeVisible();
    await expect.poll(() => Boolean(freshGraderToken), { timeout: 10_000 }).toBe(true);

    const graderSubmissionQueue = await freshGraderPage.request.get("/api/v1/grader/submissions", {
      headers: { Authorization: freshGraderToken },
    });
    expect(graderSubmissionQueue.status()).toBe(200);
    assertPersistedAuditCorrelation(graderSubmissionQueue.headers()["x-request-id"], {
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      action: "grader_submission_queue_authorized", targetType: "assessment_submission_queue",
      targetId: null, outcome: "success", reason: "assigned_grader_aal2",
    });
    const graderSubmissionRead = await freshGraderPage.request.get(
      "/api/v1/grader/submissions/" + lifecycleSubmissionId,
      { headers: { Authorization: freshGraderToken } },
    );
    const graderSubmissionBody = await graderSubmissionRead.json() as {
      submission?: { id: string; status: string };
      criteria?: Array<{ id: string; max_points: number }>;
      published_versions?: Array<{ version_number: number }>;
    };
    expect(graderSubmissionRead.status(), JSON.stringify(graderSubmissionBody)).toBe(200);
    assertPersistedAuditCorrelation(graderSubmissionRead.headers()["x-request-id"], {
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      action: "grader_submission_read_authorized", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "active_grader_assignment_aal2",
    });
    expect(graderSubmissionBody.submission?.status).toBe("assigned");
    expect(graderSubmissionBody.criteria?.length).toBeGreaterThan(0);

    const draftPayload = {
      overall_feedback: "Synthetic feedback used to verify concurrent publication safety.",
      criterion_results: graderSubmissionBody.criteria!.map(criterion => ({
        criterion_id: criterion.id, points_awarded: Math.min(criterion.max_points, 1),
        feedback: "Synthetic criterion feedback.",
      })),
    };
    const concurrentDraft = await page.request.put(
      "/api/v1/grader/submissions/" + lifecycleSubmissionId + "/draft",
      { headers: { Authorization: freshGraderToken }, data: draftPayload },
    );
    expect(concurrentDraft.status()).toBe(200);
    assertPersistedAuditCorrelation(concurrentDraft.headers()["x-request-id"], {
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      action: "assessment_draft_saved", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "grader_action",
    });
    const replayDraft = await freshGraderPage.request.put(
      "/api/v1/grader/submissions/" + lifecycleSubmissionId + "/draft",
      { headers: { Authorization: freshGraderToken }, data: draftPayload },
    );
    expect(replayDraft.status()).toBe(200);
    assertPersistedAuditCorrelation(replayDraft.headers()["x-request-id"], {
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      action: "assessment_draft_save_replayed", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "idempotent_retry",
    });

    const concurrentPublications = await Promise.all([
      page.request.post(
        "/api/v1/grader/submissions/" + lifecycleSubmissionId + "/publish",
        { headers: { Authorization: freshGraderToken }, data: {} },
      ),
      page.request.post(
        "/api/v1/grader/submissions/" + lifecycleSubmissionId + "/publish",
        { headers: { Authorization: freshGraderToken }, data: {} },
      ),
    ]);
    const concurrentPublicationBodies = await Promise.all(
      concurrentPublications.map(response => response.json()),
    ) as Array<{ error?: string; assessment?: { version_number: number; assessment_version_id?: string } }>;
    expect(concurrentPublications.map(response => response.status()).sort()).toEqual([201, 409]);
    expect(concurrentPublicationBodies.filter(body => body.assessment?.version_number === 1)).toHaveLength(1);
    expect(concurrentPublicationBodies.find(body => body.error)?.error).toBe("assessment_draft_required");
    const successfulPublicationIndex = concurrentPublications.findIndex(response => response.status() === 201);
    const failedPublicationIndex = concurrentPublications.findIndex(response => response.status() === 409);
    assertPersistedAuditCorrelation(concurrentPublications[successfulPublicationIndex].headers()["x-request-id"], {
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      action: "assessment_feedback_published", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "success", reason: "human_grader_publication",
    });
    assertPersistedAuditCorrelation(concurrentPublications[failedPublicationIndex].headers()["x-request-id"], {
      actorId: "33333333-3333-4333-8333-333333333333", actorRole: "grader",
      action: "grader_assessment_feedback_publish", targetType: "assessment_submission",
      targetId: lifecycleSubmissionId, outcome: "failed", reason: "state_conflict",
    });

    const publishedSubmissionRead = await freshGraderPage.request.get(
      "/api/v1/grader/submissions/" + lifecycleSubmissionId,
      { headers: { Authorization: freshGraderToken } },
    );
    const publishedSubmissionBody = await publishedSubmissionRead.json() as {
      submission?: { status: string };
      published_versions?: Array<{ version_number: number }>;
    };
    expect(publishedSubmissionRead.status()).toBe(200);
    expect(publishedSubmissionBody.submission?.status).toBe("feedback_published");
    expect(publishedSubmissionBody.published_versions?.map(version => version.version_number)).toEqual([1]);
    const publishedVersionId = concurrentPublicationBodies[successfulPublicationIndex].assessment?.assessment_version_id;
    expect(publishedVersionId).toMatch(/^[0-9a-f-]{36}$/i);
    const ownerPrivateQaRead = await page.request.get(
      "/api/v1/owner/assessment-versions/" + publishedVersionId + "/private-qa",
      { headers: { Authorization: ownerToken } },
    );
    expect(ownerPrivateQaRead.status()).toBe(200);
    assertPersistedAuditCorrelation(ownerPrivateQaRead.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "private_qa_records_read", targetType: "assessment_version",
      targetId: publishedVersionId!, outcome: "success", reason: "owner_qa_review",
    });
    const ownerPrivateQaCreate = await page.request.post(
      "/api/v1/owner/assessment-versions/" + publishedVersionId + "/private-qa",
      { headers: { Authorization: ownerToken }, data: {
        checks: { rubric_alignment: true }, status: "passed",
        explanation: "Synthetic QA confirms the published assessment version has complete rubric alignment.",
        reviewer_action: "Retain this synthetic version; no changes are required.",
      } },
    );
    expect(ownerPrivateQaCreate.status()).toBe(201);
    assertPersistedAuditCorrelation(ownerPrivateQaCreate.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888", actorRole: "owner",
      action: "private_qa_record_created", targetType: "assessment_version",
      targetId: publishedVersionId!, outcome: "success", reason: "owner_qa_review",
    });

    const onePublication = localSqlCsv(`
      SELECT CASE
        WHEN (SELECT count(*) FROM public.assessment_versions
              WHERE submission_id = '${lifecycleSubmissionId}'::uuid) = 1
         AND (SELECT count(*) FROM private.security_audit_events
              WHERE action = 'assessment_feedback_published'
                AND target_id = '${lifecycleSubmissionId}'::uuid
                AND outcome = 'success') = 1
         AND (SELECT count(*) FROM private.security_audit_events
              WHERE action = 'assessment_feedback_edited'
                AND target_id = '${lifecycleSubmissionId}'::uuid) = 0
        THEN 'ONE_CONCURRENT_PUBLICATION_CONFIRMED'
        ELSE 'CONCURRENT_PUBLICATION_MISMATCH'
      END AS result;
    `);
    expect(onePublication).toContain("ONE_CONCURRENT_PUBLICATION_CONFIRMED");
    await freshGraderContext.close();

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
    assertPersistedAuditCorrelation(adminAttempt.headers()["x-request-id"], {
      actorId: "77777777-7777-4777-8777-777777777777", actorRole: "admin",
      action: "owner_role_revocation", targetType: "role_assignment_subject",
      targetId: roleRequest.target_user_id, outcome: "denied", reason: "resource_scope_denied",
    });

    const adminInvitationList = await page.request.get("/api/v1/admin/staff-invitations", {
      headers: { Authorization: adminToken },
    });
    expect(adminInvitationList.status()).toBe(403);
    await expect(adminInvitationList.json()).resolves.toMatchObject({ error: "staff_invitation_forbidden" });
    assertPersistedAuditCorrelation(adminInvitationList.headers()["x-request-id"], {
      actorId: "77777777-7777-4777-8777-777777777777", actorRole: "admin",
      action: "staff_invitations_listed", targetType: "staff_invitation_collection",
      targetId: null, outcome: "denied", reason: "resource_scope_denied",
    });

    const adminGraderQueue = await page.request.get("/api/v1/grader/queue", {
      headers: { Authorization: adminToken },
    });
    expect(adminGraderQueue.status()).toBe(403);
    await expect(adminGraderQueue.json()).resolves.toMatchObject({ error: "role_required" });
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
