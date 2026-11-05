import { createHmac, randomUUID } from "node:crypto";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { expect, test, type APIRequestContext, type Browser, type Page } from "@playwright/test";

const accountPassword = "Local-only-GradiPrep-2026!";
const seededOwnerId = "88888888-8888-4888-8888-888888888888";
const seededGraderId = "55555555-5555-4555-8555-555555555555";

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
    throw new Error("The local synthetic race-test database query failed: " + details);
  }
}

function readLocalRaceSecret(): string {
  const match = readFileSync(".dev.vars", "utf8").match(/^GRADIPREP_TEST_RACE_BARRIER_SECRET=(.+)$/m);
  if (!match?.[1] || match[1].length < 32) {
    throw new Error("The local-only race-test barrier secret is missing from .dev.vars.");
  }
  return match[1];
}

type MeCapture = {
  tokens: string[];
  userId: string;
};

function captureMeRequests(page: Page): MeCapture {
  const capture: MeCapture = { tokens: [], userId: "" };
  page.on("request", (request) => {
    const url = new URL(request.url());
    if (url.pathname === "/api/v1/me" && request.method() === "GET") {
      const authorization = request.headers()["authorization"];
      if (authorization?.startsWith("Bearer ")) capture.tokens.push(authorization);
    }
  });
  page.on("response", async (response) => {
    const url = new URL(response.url());
    if (url.pathname !== "/api/v1/me" || response.request().method() !== "GET" || !response.ok()) return;
    const body = await response.json().catch(() => null) as { user?: { id?: string } } | null;
    if (body?.user?.id) capture.userId = body.user.id;
  });
  return capture;
}

function tokenHasAal2(authorization: string): boolean {
  try {
    const token = authorization.replace(/^Bearer\s+/i, "");
    const payload = token.split(".")[1];
    return Boolean(payload && JSON.parse(Buffer.from(payload, "base64url").toString("utf8")).aal === "aal2");
  } catch {
    return false;
  }
}

async function waitForAal2(capture: MeCapture): Promise<string> {
  await expect.poll(
    () => capture.tokens.some(tokenHasAal2),
    { timeout: 20_000, message: "the verified second-factor session must reach the Worker as AAL2" },
  ).toBe(true);
  const token = capture.tokens.find(tokenHasAal2);
  if (!token) throw new Error("The AAL2 access token was not captured.");
  return token;
}

async function waitForTotpWindow(): Promise<void> {
  const remaining = 30_000 - (Date.now() % 30_000);
  if (remaining < 5_000) await new Promise(resolve => setTimeout(resolve, remaining + 500));
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

async function createSyntheticAccount(page: Page, displayName: string) {
  const email = "phase1c-race-" + randomUUID() + "@example.invalid";
  const capture = captureMeRequests(page);

  await page.goto("/account");
  await expect(page.getByRole("heading", { name: /welcome back/i })).toBeVisible();
  await page.getByRole("button", { name: /create a synthetic student account/i }).click();
  await expect(page.getByRole("heading", { name: /create a student account/i })).toBeVisible();
  await page.getByLabel("Display name").fill(displayName);
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password").fill(accountPassword);
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(page.getByRole("heading", { name: displayName, exact: true })).toBeVisible();
  await expect.poll(() => Boolean(capture.userId && capture.tokens.length), { timeout: 15_000 }).toBe(true);

  return { email, displayName, userId: capture.userId, capture };
}

async function enableTotp(page: Page, capture: MeCapture): Promise<{ secret: string; token: string }> {
  await page.getByRole("button", { name: "Set up authenticator app" }).click();
  await expect(page.getByRole("img", { name: "Authenticator app setup QR code" })).toBeVisible();
  const secret = await page.getByTestId("totp-secret").innerText();
  await waitForTotpWindow();
  await page.getByLabel("Authenticator code").fill(createTotpCode(secret));
  await page.getByRole("button", { name: "Verify and enable" }).click();
  await expect(page.getByText("Verified authenticator", { exact: true })).toBeVisible();
  const token = await waitForAal2(capture);
  return { secret, token };
}

async function createSyntheticOwner(page: Page) {
  const account = await createSyntheticAccount(page, "Synthetic Phase 1C Race Owner");
  localSqlCsv(
    "INSERT INTO public.role_assignments (user_id, role, granted_by, reason) VALUES (" +
    "'" + account.userId + "'::uuid, 'owner'::public.app_role, '" + seededOwnerId +
    "'::uuid, 'phase1c_race_test_owner');",
  );
  await page.reload();
  await expect(page.locator(".proto-account-roles")).toContainText("owner");
  const mfa = await enableTotp(page, account.capture);
  return { ...account, ...mfa };
}

async function signInIndependentSession(
  browser: Browser,
  account: { email: string; displayName: string },
  totpSecret: string,
) {
  const context = await browser.newContext({ baseURL: "http://127.0.0.1:8787" });
  const page = await context.newPage();
  const capture = captureMeRequests(page);
  await page.goto("/account");
  await page.getByLabel("Email address").fill(account.email);
  await page.getByLabel("Password").fill(accountPassword);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Verify your sign-in." })).toBeVisible();
  await waitForTotpWindow();
  await page.getByLabel("Authenticator code").fill(createTotpCode(totpSecret));
  await page.getByRole("button", { name: "Verify code" }).click();
  await expect(page.getByRole("heading", { name: account.displayName, exact: true })).toBeVisible();
  const token = await waitForAal2(capture);
  return { context, page, token };
}

function barrierHeaders(secret: string, barrierId: string, point: string): Record<string, string> {
  return {
    "x-gradioprep-test-race-secret": secret,
    "x-gradioprep-test-race-barrier": barrierId,
    "x-gradioprep-test-race-point": point,
  };
}

async function registerBarrier(
  api: APIRequestContext,
  secret: string,
  barrierId: string,
  expectedArrivals: number,
): Promise<void> {
  const response = await api.post("/api/__test/race-barriers/" + barrierId, {
    headers: { "x-gradioprep-test-race-secret": secret },
    data: { expected_arrivals: expectedArrivals },
  });
  expect(response.status()).toBe(201);
}

async function waitForBarrier(
  api: APIRequestContext,
  secret: string,
  barrierId: string,
  expectedArrivals: number,
): Promise<void> {
  await expect.poll(async () => {
    const response = await api.get("/api/__test/race-barriers/" + barrierId, {
      headers: { "x-gradioprep-test-race-secret": secret },
    });
    if (!response.ok()) return -1;
    const body = await response.json() as { arrivals?: number };
    return body.arrivals ?? -1;
  }, { timeout: 20_000, intervals: [50, 100, 200, 500] }).toBe(expectedArrivals);
}

async function releaseBarrier(
  api: APIRequestContext,
  secret: string,
  barrierId: string,
): Promise<void> {
  const response = await api.post("/api/__test/race-barriers/" + barrierId + "/release", {
    headers: { "x-gradioprep-test-race-secret": secret },
  });
  expect(response.status()).toBe(200);
}

async function releaseBarrierQuietly(
  api: APIRequestContext,
  secret: string,
  barrierId: string | null,
): Promise<void> {
  if (!barrierId) return;
  await api.post("/api/__test/race-barriers/" + barrierId + "/release", {
    headers: { "x-gradioprep-test-race-secret": secret },
  }).catch(() => undefined);
}

test.describe("Phase 1C-F synchronized synthetic race acceptance", () => {
  test("two independent AAL2 sessions accepting one invitation token produce one grant and one success", async ({ page, browser }) => {
    test.setTimeout(180_000);
    const secret = readLocalRaceSecret();
    let inviteeContext: Awaited<ReturnType<typeof browser.newContext>> | null = null;
    let secondSession: Awaited<ReturnType<typeof signInIndependentSession>> | null = null;
    let invitationId: string | null = null;
    let barrierId: string | null = null;

    try {
      const ownerAccount = await createSyntheticOwner(page);
      inviteeContext = await browser.newContext({ baseURL: "http://127.0.0.1:8787" });
      const inviteePage = await inviteeContext.newPage();
      const inviteeAccount = await createSyntheticAccount(inviteePage, "Synthetic Phase 1C Race Invitee");
      const inviteeMfa = await enableTotp(inviteePage, inviteeAccount.capture);

      const createInvitation = await page.request.post("/api/v1/admin/staff-invitations", {
        headers: { Authorization: ownerAccount.token },
        data: { email: inviteeAccount.email, role: "grader" },
      });
      const createBody = await createInvitation.json() as {
        invitation?: { invitation_id?: string };
        invite_url?: string;
      };
      expect(createInvitation.status(), JSON.stringify(createBody)).toBe(201);
      invitationId = createBody.invitation?.invitation_id ?? null;
      expect(invitationId).toMatch(/^[0-9a-f-]{36}$/i);
      expect(createBody.invite_url).toBeTruthy();
      const token = new URLSearchParams(new URL(createBody.invite_url!).hash.slice(1)).get("staff-invite");
      expect(token).toMatch(/^[A-Za-z0-9_-]{43}$/);
      if (!token) throw new Error("The invitation URL did not contain its single-use token.");

      secondSession = await signInIndependentSession(
        browser,
        { email: inviteeAccount.email, displayName: inviteeAccount.displayName },
        inviteeMfa.secret,
      );

      barrierId = randomUUID();
      await registerBarrier(page.request, secret, barrierId, 2);
      const headersA = {
        Authorization: inviteeMfa.token,
        ...barrierHeaders(secret, barrierId, "staff_invitation_accept_before_rpc"),
      };
      const headersB = {
        Authorization: secondSession.token,
        ...barrierHeaders(secret, barrierId, "staff_invitation_accept_before_rpc"),
      };
      const acceptanceA = inviteePage.request.post("/api/v1/staff-invitations/accept", {
        headers: headersA,
        data: { token },
      });
      const acceptanceB = secondSession.page.request.post("/api/v1/staff-invitations/accept", {
        headers: headersB,
        data: { token },
      });

      await waitForBarrier(page.request, secret, barrierId, 2);
      await releaseBarrier(page.request, secret, barrierId);
      const responses = await Promise.all([acceptanceA, acceptanceB]);
      expect(responses.map(response => response.status()).sort((a, b) => a - b)).toEqual([200, 410]);
      const acceptedIndex = responses.findIndex(response => response.status() === 200);
      const rejectedIndex = acceptedIndex === 0 ? 1 : 0;
      const accepted = responses[acceptedIndex];
      const rejected = responses[rejectedIndex];
      await expect(accepted.json()).resolves.toMatchObject({ accepted: true, role: "grader" });
      const rejectedBody = await rejected.json() as Record<string, unknown>;
      expect(rejectedBody).toMatchObject({ error: "invitation_already_used" });
      expect(JSON.stringify(rejectedBody)).not.toMatch(/token|hash/i);

      const acceptedRequestId = accepted.headers()["x-request-id"];
      const rejectedRequestId = rejected.headers()["x-request-id"];
      expect(acceptedRequestId).toMatch(/^[0-9a-f-]{36}$/i);
      expect(rejectedRequestId).toMatch(/^[0-9a-f-]{36}$/i);
      expect(acceptedRequestId).not.toBe(rejectedRequestId);

      const acceptanceState = localSqlCsv(
        "SELECT 'active_grader_roles=' || (" +
        "SELECT count(*)::text FROM public.role_assignments WHERE user_id = '" + inviteeAccount.userId +
        "'::uuid AND role = 'grader'::public.app_role AND revoked_at IS NULL" +
        ") || ';successful_acceptance_events=' || (" +
        "SELECT count(*)::text FROM private.security_audit_events WHERE action = 'staff_invitation_accepted' " +
        "AND target_id = '" + invitationId + "'::uuid AND outcome = 'success'" +
        ") || ';conflict_acceptance_events=' || (" +
        "SELECT count(*)::text FROM private.security_audit_events WHERE action = 'staff_invitation_accepted' " +
        "AND target_id = '" + invitationId + "'::uuid AND outcome = 'failed'" +
        ");",
      );
      expect(acceptanceState).toContain(
        "active_grader_roles=1;successful_acceptance_events=1;conflict_acceptance_events=1",
      );

      const acceptedCorrelation = localSqlCsv(
        "SELECT 'matched_success=' || count(*)::text FROM private.security_audit_events " +
        "WHERE request_id = '" + acceptedRequestId + "'::uuid " +
        "AND actor_id = '" + inviteeAccount.userId + "'::uuid " +
        "AND action = 'staff_invitation_accepted' AND target_id = '" + invitationId + "'::uuid " +
        "AND outcome = 'success';",
      );
      expect(acceptedCorrelation).toContain("matched_success=1");
      const rejectedCorrelation = localSqlCsv(
        "SELECT 'matched_conflict=' || count(*)::text FROM private.security_audit_events " +
        "WHERE request_id = '" + rejectedRequestId + "'::uuid " +
        "AND actor_id = '" + inviteeAccount.userId + "'::uuid " +
        "AND action = 'staff_invitation_accepted' AND target_id = '" + invitationId + "'::uuid " +
        "AND outcome = 'failed' AND reason_category = 'state_conflict';",
      );
      expect(rejectedCorrelation).toContain("matched_conflict=1");
    } finally {
      await releaseBarrierQuietly(page.request, secret, barrierId);
      if (secondSession) await secondSession.context.close();
      if (inviteeContext) await inviteeContext.close();
      // Preserve synthetic invitation/account records and append-only audit
      // history. CI recreates the entire local database for each run; deleting
      // parent rows here would attempt to delete immutable audit events.
    }
  });

  test("role revocation and account suspension racing an in-flight privileged assignment are rechecked", async ({ page }) => {
    test.setTimeout(180_000);
    const secret = readLocalRaceSecret();
    let owner: Awaited<ReturnType<typeof createSyntheticOwner>> | null = null;
    const openBarriers: string[] = [];

    try {
      const ownerAccount = await createSyntheticOwner(page);
      owner = ownerAccount;

      const revokedAttemptId = randomUUID();
      const revokeBarrierId = randomUUID();
      openBarriers.push(revokeBarrierId);
      await registerBarrier(page.request, secret, revokeBarrierId, 1);
      const revokedRequest = page.request.post(
        "/api/v1/admin/attempts/" + revokedAttemptId + "/assign",
        {
          headers: {
            Authorization: ownerAccount.token,
            ...barrierHeaders(secret, revokeBarrierId, "owner_attempt_assignment_before_rpc"),
          },
          data: {
            grader_user_id: seededGraderId,
            reason: "Synthetic in-flight owner-role revocation race",
          },
        },
      );
      await waitForBarrier(page.request, secret, revokeBarrierId, 1);

      const revokeResponse = await page.request.post("/api/v1/admin/roles/revoke", {
        headers: { Authorization: ownerAccount.token },
        data: {
          target_user_id: ownerAccount.userId,
          role: "owner",
          reason: "Synthetic in-flight privileged request race",
        },
      });
      expect(revokeResponse.status()).toBe(200);
      await releaseBarrier(page.request, secret, revokeBarrierId);
      openBarriers.splice(openBarriers.indexOf(revokeBarrierId), 1);
      const revokedRaceResponse = await revokedRequest;
      expect(revokedRaceResponse.status()).toBe(403);
      await expect(revokedRaceResponse.json()).resolves.toMatchObject({
        error: "attempt_assignment_forbidden",
      });

      const revokedRequestId = revokedRaceResponse.headers()["x-request-id"];
      expect(revokedRequestId).toMatch(/^[0-9a-f-]{36}$/i);
      const revokedAudit = localSqlCsv(
        "SELECT 'denied_audit=' || count(*)::text FROM private.security_audit_events " +
        "WHERE request_id = '" + revokedRequestId + "'::uuid " +
        "AND actor_id = '" + ownerAccount.userId + "'::uuid " +
        "AND action = 'owner_attempt_assignment' AND target_id = '" + revokedAttemptId + "'::uuid " +
        "AND outcome = 'denied';",
      );
      expect(revokedAudit).toContain("denied_audit=1");
      const revokedSideEffect = localSqlCsv(
        "SELECT 'assignments=' || count(*)::text FROM public.grader_assignments " +
        "WHERE attempt_id = '" + revokedAttemptId + "'::uuid;",
      );
      expect(revokedSideEffect).toContain("assignments=0");

      const afterRevocation = await page.request.post(
        "/api/v1/admin/attempts/" + randomUUID() + "/assign",
        {
          headers: { Authorization: ownerAccount.token },
          data: { grader_user_id: seededGraderId, reason: "Post-revocation denial check" },
        },
      );
      expect(afterRevocation.status()).toBe(403);
      await expect(afterRevocation.json()).resolves.toMatchObject({ error: "role_required" });

      localSqlCsv(
        "UPDATE public.role_assignments SET revoked_at = NULL, revoked_by = NULL, " +
        "reason = 'phase1c_race_test_owner' WHERE user_id = '" + ownerAccount.userId + "'::uuid " +
        "AND role = 'owner'::public.app_role;",
      );

      const suspendedAttemptId = randomUUID();
      const suspensionBarrierId = randomUUID();
      openBarriers.push(suspensionBarrierId);
      await registerBarrier(page.request, secret, suspensionBarrierId, 1);
      const suspendedRequest = page.request.post(
        "/api/v1/admin/attempts/" + suspendedAttemptId + "/assign",
        {
          headers: {
            Authorization: ownerAccount.token,
            ...barrierHeaders(secret, suspensionBarrierId, "owner_attempt_assignment_before_rpc"),
          },
          data: {
            grader_user_id: seededGraderId,
            reason: "Synthetic in-flight account-suspension race",
          },
        },
      );
      await waitForBarrier(page.request, secret, suspensionBarrierId, 1);

      localSqlCsv(
        "UPDATE public.profiles SET account_status = 'suspended'::public.account_status " +
        "WHERE user_id = '" + ownerAccount.userId + "'::uuid;",
      );
      const suspendedState = localSqlCsv(
        "SELECT 'account_status=' || account_status::text FROM public.profiles " +
        "WHERE user_id = '" + ownerAccount.userId + "'::uuid;",
      );
      expect(suspendedState).toContain("account_status=suspended");

      await releaseBarrier(page.request, secret, suspensionBarrierId);
      openBarriers.splice(openBarriers.indexOf(suspensionBarrierId), 1);
      const suspensionRaceResponse = await suspendedRequest;
      expect(suspensionRaceResponse.status()).toBe(403);
      await expect(suspensionRaceResponse.json()).resolves.toMatchObject({
        error: "attempt_assignment_forbidden",
      });
      const suspensionRequestId = suspensionRaceResponse.headers()["x-request-id"];
      expect(suspensionRequestId).toMatch(/^[0-9a-f-]{36}$/i);
      const suspensionAudit = localSqlCsv(
        "SELECT 'denied_audit=' || count(*)::text FROM private.security_audit_events " +
        "WHERE request_id = '" + suspensionRequestId + "'::uuid " +
        "AND actor_id = '" + ownerAccount.userId + "'::uuid " +
        "AND action = 'owner_attempt_assignment' AND target_id = '" + suspendedAttemptId + "'::uuid " +
        "AND outcome = 'denied';",
      );
      expect(suspensionAudit).toContain("denied_audit=1");
      const suspensionSideEffect = localSqlCsv(
        "SELECT 'assignments=' || count(*)::text FROM public.grader_assignments " +
        "WHERE attempt_id = '" + suspendedAttemptId + "'::uuid;",
      );
      expect(suspensionSideEffect).toContain("assignments=0");

      const meWhileSuspended = await page.request.get("/api/v1/me", {
        headers: { Authorization: ownerAccount.token },
      });
      expect(meWhileSuspended.status()).toBe(403);
      await expect(meWhileSuspended.json()).resolves.toMatchObject({ error: "account_unavailable" });
    } finally {
      for (const barrierId of openBarriers) {
        await releaseBarrierQuietly(page.request, secret, barrierId);
      }
      if (owner?.userId) {
        // Restore only mutable access state. Keep the synthetic account and
        // append-only security audit evidence; the local CI database is reset
        // for the next run, and auth-user deletion would cascade into audit rows.
        localSqlCsv(
          "UPDATE public.profiles SET account_status = 'active'::public.account_status " +
          "WHERE user_id = '" + owner.userId + "'::uuid;",
        );
        localSqlCsv(
          "UPDATE public.role_assignments SET revoked_at = NULL, revoked_by = NULL, " +
          "reason = 'phase1c_race_test_owner' WHERE user_id = '" + owner.userId + "'::uuid " +
          "AND role = 'owner'::public.app_role;",
        );
      }
    }
  });
});
