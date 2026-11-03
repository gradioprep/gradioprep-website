import { expect, test, type Page } from "@playwright/test";
import { createHmac, randomUUID } from "node:crypto";

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
    const createBody = await createResponse.json() as Record<string, unknown>;
    expect(createResponse.status(), JSON.stringify(createBody)).toBe(201);
    const created = createBody as { attempt: { id: string; status: string } };
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

  test("learner accepts a separate human-assessment submission with immutable SLA and idempotency", async ({ page, request }) => {
    expect((await request.get("/api/v1/learner/submissions")).status()).toBe(401);

    const token = await signIn(page, "student.a@example.invalid", "Synthetic Student A");
    const headers = { Authorization: token };
    const payload = {
      task_version_id: taskVersionA,
      idempotency_key: randomUUID(),
      response_text: "This synthetic assessment response explains how a selected textual detail shapes a reader response and supports the interpretation with precise evidence.",
    };

    const acceptedResponse = await page.request.post("/api/v1/learner/submissions", {
      headers,
      data: payload,
    });
    const acceptedBody = await acceptedResponse.json() as {
      submission: {
        submission_id: string;
        learner_id: string;
        task_version_id: string;
        rubric_version_id: string;
        status: string;
        accepted_at: string;
        grading_due_at: string;
        sla_target_seconds: number;
        capacity_limit_snapshot: number;
        open_submissions_before_acceptance: number;
        is_replay: boolean;
      };
    };
    expect(acceptedResponse.status(), JSON.stringify(acceptedBody)).toBe(201);
    expect(acceptedBody.submission.learner_id).toBe("11111111-1111-4111-8111-111111111111");
    expect(acceptedBody.submission.task_version_id).toBe(taskVersionA);
    expect(acceptedBody.submission.rubric_version_id).toBe("f1111111-1111-4111-8111-111111111111");
    expect(acceptedBody.submission.status).toBe("queued");
    expect(acceptedBody.submission.sla_target_seconds).toBe(86_400);
    expect(new Date(acceptedBody.submission.grading_due_at).getTime() -
      new Date(acceptedBody.submission.accepted_at).getTime()).toBe(86_400_000);
    expect(acceptedBody.submission.capacity_limit_snapshot).toBe(3);
    expect(acceptedBody.submission.open_submissions_before_acceptance).toBe(0);
    expect(acceptedBody.submission.is_replay).toBe(false);

    const replayResponse = await page.request.post("/api/v1/learner/submissions", {
      headers,
      data: payload,
    });
    const replayBody = await replayResponse.json() as {
      submission: { submission_id: string; is_replay: boolean };
    };
    expect(replayResponse.status()).toBe(200);
    expect(replayBody.submission.submission_id).toBe(acceptedBody.submission.submission_id);
    expect(replayBody.submission.is_replay).toBe(true);

    const conflictingReplay = await page.request.post("/api/v1/learner/submissions", {
      headers,
      data: { ...payload, response_text: "This changed content cannot replace the original accepted assessment response." },
    });
    expect(conflictingReplay.status()).toBe(409);
    await expect(conflictingReplay.json()).resolves.toMatchObject({
      error: "submission_idempotency_conflict",
    });

    const listResponse = await page.request.get("/api/v1/learner/submissions", { headers });
    expect(listResponse.status()).toBe(200);
    const listBody = await listResponse.json() as {
      submissions: Array<{ id: string; status: string; accepted_at: string; grading_due_at: string }>;
    };
    expect(listBody.submissions.some(item =>
      item.id === acceptedBody.submission.submission_id && item.status === "queued"
    )).toBe(true);

    const detailResponse = await page.request.get(
      "/api/v1/learner/submissions/" + acceptedBody.submission.submission_id,
      { headers },
    );
    expect(detailResponse.status()).toBe(200);
    const detailBody = await detailResponse.json() as {
      submission: {
        submission_versions: Array<{ version_number: number; response_text: string; word_count: number }>;
      };
    };
    expect(detailBody.submission.submission_versions).toHaveLength(1);
    expect(detailBody.submission.submission_versions[0].version_number).toBe(1);
    expect(detailBody.submission.submission_versions[0].response_text).toBe(payload.response_text);
    expect(detailBody.submission.submission_versions[0].word_count).toBeGreaterThan(0);

    const forgedFields = await page.request.post("/api/v1/learner/submissions", {
      headers,
      data: { ...payload, learner_id: "22222222-2222-4222-8222-222222222222" },
    });
    expect(forgedFields.status()).toBe(400);

    const taskOutsideEnrolment = await page.request.post("/api/v1/learner/submissions", {
      headers,
      data: {
        task_version_id: "a2222222-2222-4222-8222-222222222222",
        idempotency_key: randomUUID(),
        response_text: "This should not be accepted for a learner enrolled in another pathway.",
      },
    });
    expect(taskOutsideEnrolment.status()).toBe(404);
  });

  test("guardian cannot accept a human-assessment submission or use staff assessment APIs", async ({ page }) => {
    const token = await signIn(page, "guardian.a@example.invalid", "Synthetic Guardian A");
    const headers = { Authorization: token };
    const attemptRoute = await page.request.get("/api/v1/learner/submissions", { headers });
    expect(attemptRoute.status()).toBe(403);
    await expect(attemptRoute.json()).resolves.toMatchObject({ error: "role_required" });

    const submitRoute = await page.request.post("/api/v1/learner/submissions", {
      headers,
      data: {
        task_version_id: taskVersionA,
        idempotency_key: randomUUID(),
        response_text: "A guardian must not submit work on behalf of the linked learner.",
      },
    });
    expect(submitRoute.status()).toBe(403);
    await expect(submitRoute.json()).resolves.toMatchObject({ error: "role_required" });
  });

  test("guardian cannot use learner or grader APIs without a matching role", async ({ page }) => {
    const token = await signIn(page, "guardian.a@example.invalid", "Synthetic Guardian A");
    const headers = { Authorization: token };

    const learnerAttempts = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(learnerAttempts.status()).toBe(403);
    await expect(learnerAttempts.json()).resolves.toMatchObject({ error: "role_required" });

    const graderQueue = await page.request.get("/api/v1/grader/queue", { headers });
    expect(graderQueue.status()).toBe(403);
    await expect(graderQueue.json()).resolves.toMatchObject({ error: "role_required" });

    const graderDetail = await page.request.get("/api/v1/grader/attempts/" + attemptA, { headers });
    expect(graderDetail.status()).toBe(403);
    await expect(graderDetail.json()).resolves.toMatchObject({ error: "role_required" });
  });

  test("human assessment APIs deny anonymous, student, guardian and AAL1 grader access", async ({ browser, request }) => {
    const submissionId = "d3333333-3333-4333-8333-333333333333";
    const anonymousChecks = await Promise.all([
      request.get("/api/v1/grader/submissions"),
      request.get("/api/v1/grader/submissions/" + submissionId),
      request.post("/api/v1/admin/submissions/" + submissionId + "/assign", {
        data: { grader_user_id: "55555555-5555-4555-8555-555555555555", reason: "Synthetic denial check" },
      }),
      request.put("/api/v1/grader/submissions/" + submissionId + "/draft", {
        data: {
          overall_feedback: "A valid-length synthetic draft feedback.",
          criterion_results: [{
            criterion_id: "f3333333-3333-4333-8333-333333333333",
            points_awarded: 2,
            feedback: "The learner selects a relevant detail and links it to an interpretation.",
          }],
        },
      }),
      request.post("/api/v1/grader/submissions/" + submissionId + "/publish", { data: {} }),
    ]);
    for (const response of anonymousChecks) expect(response.status()).toBe(401);

    const studentPage = await browser.newPage();
    const studentToken = await signIn(studentPage, "student.a@example.invalid", "Synthetic Student A");
    const studentHeaders = { Authorization: studentToken };
    const studentChecks = await Promise.all([
      studentPage.request.get("/api/v1/grader/submissions", { headers: studentHeaders }),
      studentPage.request.get("/api/v1/grader/submissions/" + submissionId, { headers: studentHeaders }),
      studentPage.request.post("/api/v1/admin/submissions/" + submissionId + "/assign", {
        headers: studentHeaders,
        data: { grader_user_id: "55555555-5555-4555-8555-555555555555", reason: "Synthetic denial check" },
      }),
      studentPage.request.put("/api/v1/grader/submissions/" + submissionId + "/draft", {
        headers: studentHeaders,
        data: {
          overall_feedback: "A valid-length synthetic draft feedback.",
          criterion_results: [{
            criterion_id: "f3333333-3333-4333-8333-333333333333",
            points_awarded: 2,
            feedback: "The learner selects a relevant detail and links it to an interpretation.",
          }],
        },
      }),
      studentPage.request.post("/api/v1/grader/submissions/" + submissionId + "/publish", {
        headers: studentHeaders,
        data: {},
      }),
    ]);
    for (const response of studentChecks) {
      expect(response.status()).toBe(403);
      await expect(response.json()).resolves.toMatchObject({ error: "role_required" });
    }

    await studentPage.close();
    const guardianPage = await browser.newPage();
    const guardianToken = await signIn(guardianPage, "guardian.a@example.invalid", "Synthetic Guardian A");
    const guardianResponse = await guardianPage.request.get("/api/v1/grader/submissions", {
      headers: { Authorization: guardianToken },
    });
    expect(guardianResponse.status()).toBe(403);
    await expect(guardianResponse.json()).resolves.toMatchObject({ error: "role_required" });

    await guardianPage.close();
    const graderPage = await browser.newPage();
    const graderAal1 = await signIn(graderPage, "grader.a@example.invalid", "Synthetic Grader A");
    const graderResponse = await graderPage.request.get("/api/v1/grader/submissions", {
      headers: { Authorization: graderAal1 },
    });
    expect(graderResponse.status()).toBe(403);
    await expect(graderResponse.json()).resolves.toMatchObject({ error: "mfa_required" });
    await graderPage.close();
  });

  test("grader AAL2 session sees only the active assigned queue and response", async ({ page }) => {
    test.setTimeout(60_000);
    const firstFactorToken = await signIn(page, "grader.a@example.invalid", "Synthetic Grader A");

    const firstFactorQueue = await page.request.get("/api/v1/grader/queue", {
      headers: { Authorization: firstFactorToken },
    });
    expect(firstFactorQueue.status()).toBe(403);
    await expect(firstFactorQueue.json()).resolves.toMatchObject({ error: "mfa_required" });

    let aal2Token = firstFactorToken;
    page.on("request", request => {
      if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
        aal2Token = request.headers()["authorization"] ?? aal2Token;
      }
    });

    await expect(page.getByRole("button", { name: "Set up authenticator app" })).toBeVisible();
    await page.getByRole("button", { name: "Set up authenticator app" }).click();
    await expect(page.getByRole("img", { name: "Authenticator app setup QR code" })).toBeVisible();
    const secret = await page.getByTestId("totp-secret").innerText();
    await waitForTotpWindow();
    await page.getByLabel("Authenticator code").fill(createTotpCode(secret));
    await page.getByRole("button", { name: "Verify and enable" }).click();
    await expect(page.getByText("Verified authenticator", { exact: true })).toBeVisible();
    await expect.poll(() => aal2Token !== firstFactorToken, { timeout: 10_000 }).toBe(true);

    const headers = { Authorization: aal2Token };
    const queueResponse = await page.request.get("/api/v1/grader/queue", { headers });
    const queuePayload = await queueResponse.json() as Record<string, unknown>;
    expect(queueResponse.status(), JSON.stringify(queuePayload)).toBe(200);
    const queueBody = queuePayload as { attempts: Array<{ id: string }> };
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
