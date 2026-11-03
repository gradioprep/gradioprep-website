import { expect, test, type Page } from "@playwright/test";
import { createHmac } from "node:crypto";

const localPassword = "Local-only-GradiPrep-2026!";
const taskVersionA = "a1111111-1111-4111-8111-111111111111";
const promptA = "b1111111-1111-4111-8111-111111111111";
const attemptA = "c1111111-1111-4111-8111-111111111111";
const attemptB = "c2222222-2222-4222-8222-222222222222";

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
  if (remaining < 5_000) await new Promise(resolve => setTimeout(resolve, remaining + 500));
}

async function signIn(page: Page, email: string, heading: string): Promise<string> {
  let token = "";
  page.on("request", request => {
    if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
      token = request.headers()["authorization"] ?? token;
    }
  });
  await page.goto("/account");
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password").fill(localPassword);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: heading, exact: true })).toBeVisible();
  await expect.poll(() => Boolean(token)).toBe(true);
  return token;
}

test.describe("Phase 1C typed attempts and assignment-scoped grading API", () => {
  test("student attempt reads, response versioning and submission remain caller-owned", async ({ page, request }) => {
    await expect((await request.get("/api/v1/learner/attempts")).status()).toBe(401);

    const token = await signIn(page, "student.a@example.invalid", "Synthetic Student A");
    const headers = { Authorization: token };

    const listResponse = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(listResponse.status()).toBe(200);
    const listBody = await listResponse.json() as { attempts: Array<{ id: string; learner_id: string }> };
    const listedIds = listBody.attempts.map(attempt => attempt.id);
    expect(listedIds).toContain(attemptA);
    expect(listedIds).not.toContain(attemptB);
    expect(listBody.attempts.every(attempt => attempt.learner_id === "11111111-1111-4111-8111-111111111111")).toBe(true);

    const otherLearnerAttempt = await page.request.get("/api/v1/learner/attempts/" + attemptB, { headers });
    expect(otherLearnerAttempt.status()).toBe(404);

    const ownAttempt = await page.request.get("/api/v1/learner/attempts/" + attemptA, { headers });
    expect(ownAttempt.status()).toBe(200);
    const ownBody = await ownAttempt.json() as {
      attempt: { attempt_responses: Array<{ response_text: string; word_count: number }> };
      prompts: Array<{ id: string }>;
    };
    expect(ownBody.attempt.attempt_responses).toHaveLength(1);
    expect(ownBody.prompts.map(prompt => prompt.id)).toContain(promptA);

    const forgedCreate = await page.request.post("/api/v1/learner/attempts", {
      headers,
      data: { task_version_id: taskVersionA, learner_id: "22222222-2222-4222-8222-222222222222" },
    });
    expect(forgedCreate.status()).toBe(400);

    const createResponse = await page.request.post("/api/v1/learner/attempts", {
      headers,
      data: { task_version_id: taskVersionA },
    });
    expect(createResponse.status()).toBe(201);
    const created = await createResponse.json() as { attempt: { id: string; status: string } };
    expect(created.attempt.status).toBe("in_progress");

    const responseText = "This synthetic typed response explains how a carefully chosen detail shapes the reader's interpretation.";
    const saveResponse = await page.request.put(
      "/api/v1/learner/attempts/" + created.attempt.id + "/responses/" + promptA,
      { headers, data: { response_text: responseText } },
    );
    expect(saveResponse.status()).toBe(200);
    const saved = await saveResponse.json() as { response: { word_count: number; version: number } };
    expect(saved.response.word_count).toBeGreaterThan(0);
    expect(saved.response.version).toBe(1);

    const reviseResponse = await page.request.put(
      "/api/v1/learner/attempts/" + created.attempt.id + "/responses/" + promptA,
      { headers, data: { response_text: responseText + " A further explanation supports the interpretation." } },
    );
    expect(reviseResponse.status()).toBe(200);
    const revised = await reviseResponse.json() as { response: { version: number } };
    expect(revised.response.version).toBe(2);

    const submitResponse = await page.request.post(
      "/api/v1/learner/attempts/" + created.attempt.id + "/submit",
      { headers, data: {} },
    );
    expect(submitResponse.status()).toBe(200);
    const submitted = await submitResponse.json() as {
      attempt: { status: string; submitted_at: string };
    };
    expect(submitted.attempt.status).toBe("submitted");
    expect(submitted.attempt.submitted_at).toBeTruthy();

    const lateEdit = await page.request.put(
      "/api/v1/learner/attempts/" + created.attempt.id + "/responses/" + promptA,
      { headers, data: { response_text: "This must not overwrite a submitted response." } },
    );
    expect(lateEdit.status()).toBe(409);

    const graderRoute = await page.request.get("/api/v1/grader/queue", { headers });
    expect(graderRoute.status()).toBe(403);
    await expect(graderRoute.json()).resolves.toMatchObject({ error: "role_required" });
  });

  test("grader AAL2 session sees only the active assigned queue and response", async ({ page }) => {
    test.setTimeout(60_000);
    const firstFactorToken = await signIn(page, "grader.a@example.invalid", "Synthetic Grader A");

    const firstFactorQueue = await page.request.get("/api/v1/grader/queue", {
      headers: { Authorization: firstFactorToken },
    });
    expect(firstFactorQueue.status()).toBe(403);
    await expect(firstFactorQueue.json()).resolves.toMatchObject({ error: "mfa_required" });

    await expect(page.getByRole("button", { name: "Set up authenticator app" })).toBeVisible();
    await page.getByRole("button", { name: "Set up authenticator app" }).click();
    await expect(page.getByRole("img", { name: "Authenticator app setup QR code" })).toBeVisible();
    const secret = await page.getByTestId("totp-secret").innerText();
    await waitForTotpWindow();
    await page.getByLabel("Authenticator code").fill(createTotpCode(secret));
    await page.getByRole("button", { name: "Verify and enable" }).click();
    await expect(page.getByText("Verified authenticator", { exact: true })).toBeVisible();

    let aal2Token = firstFactorToken;
    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        aal2Token = request.headers()["authorization"] ?? aal2Token;
      }
    });
    await expect.poll(() => aal2Token !== firstFactorToken, { timeout: 10_000 }).toBe(true);

    const headers = { Authorization: aal2Token };
    const queueResponse = await page.request.get("/api/v1/grader/queue", { headers });
    expect(queueResponse.status()).toBe(200);
    const queueBody = await queueResponse.json() as { attempts: Array<{ id: string }> };
    const queueIds = queueBody.attempts.map(attempt => attempt.id);
    expect(queueIds).toContain(attemptA);
    expect(queueIds).not.toContain(attemptB);

    const assignedDetail = await page.request.get("/api/v1/grader/attempts/" + attemptA, { headers });
    expect(assignedDetail.status()).toBe(200);
    const detailBody = await assignedDetail.json() as {
      attempt: { attempt_responses: Array<{ response_text: string }> };
      prompts: Array<{ prompt_text: string }>;
    };
    expect(detailBody.attempt.attempt_responses).toHaveLength(1);
    expect(detailBody.prompts).toHaveLength(1);

    const unassignedToThisGrader = await page.request.get("/api/v1/grader/attempts/" + attemptB, { headers });
    expect(unassignedToThisGrader.status()).toBe(404);
    const learnerRoute = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(learnerRoute.status()).toBe(403);
    await expect(learnerRoute.json()).resolves.toMatchObject({ error: "role_required" });
  });
});
