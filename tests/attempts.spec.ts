import { expect, test, type Page } from "@playwright/test";
import { createHmac, randomUUID } from "node:crypto";
import { readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { PDFDocument } from "pdf-lib";
import { createClient } from "@supabase/supabase-js";
import { actorIdFromAuthorizationHeader, assertPersistedAuditCorrelation } from "./audit-assertions";

const localPassword = ["Local-only", "GradiPrep", "2026!"].join("-");
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

async function signInOwnerAal2(page: Page): Promise<string> {
  let token = "";
  page.on("request", request => {
    if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
      token = request.headers()["authorization"] ?? token;
    }
  });
  await page.goto("/account");
  await page.getByLabel("Email address").fill("owner@example.invalid");
  await page.getByLabel("Password").fill(localPassword);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Verify your sign-in.", exact: true })).toBeVisible();

  const ownerTotpSecretPath = join(tmpdir(), "gradioprep-playwright-owner-totp-secret");
  let secret = "";
  try {
    secret = readFileSync(ownerTotpSecretPath, "utf8").trim();
  } catch {
    throw new Error("The account spec did not provide the synthetic Owner authenticator secret.");
  } finally {
    try { unlinkSync(ownerTotpSecretPath); } catch { /* already removed */ }
  }
  if (!secret) throw new Error("The synthetic Owner authenticator secret file was empty.");
  await waitForTotpWindow();
  await page.getByLabel("Authenticator code").fill(createTotpCode(secret));
  await page.getByRole("button", { name: "Verify code" }).click();
  await expect(page.getByText("Verified authenticator", { exact: true })).toBeVisible();
  await expect(page.getByText("MFA verified", { exact: true })).toBeVisible();
  await expect.poll(() => Boolean(token)).toBe(true);

  const ownerReadProbe = await page.request.get("/api/v1/admin/staff-invitations", {
    headers: { Authorization: token },
  });
  expect(ownerReadProbe.status()).toBe(200);
  return token;
}

async function withdrawSyntheticSubmission(
  page: Page,
  ownerAal2Token: string,
  submissionId: string,
): Promise<void> {
  const response = await page.request.post(
    "/api/v1/owner/submissions/" + submissionId + "/transition",
    {
      headers: { Authorization: ownerAal2Token },
      data: {
        target_status: "withdrawn",
        reason: "Synthetic Playwright queue-capacity cleanup",
      },
    },
  );
  const body = await response.json() as {
    transition?: { submission_id?: string; status?: string };
    error?: string;
  };
  expect(response.status(), JSON.stringify(body)).toBe(200);
  expect(body.transition).toMatchObject({
    submission_id: submissionId,
    status: "withdrawn",
  });
  assertPersistedAuditCorrelation(response.headers()["x-request-id"], {
    actorId: "88888888-8888-4888-8888-888888888888",
    actorRole: "owner",
    action: "assessment_submission_withdrawn",
    targetType: "assessment_submission",
    targetId: submissionId,
    outcome: "success",
    reason: "owner_withdrawal",
  });
}

test.describe("Phase 1C typed attempts and assignment-scoped grading API", () => {
  test("student attempt reads, response versioning and submission remain caller-owned", async ({ page, request }) => {
    await expect((await request.get("/api/v1/learner/attempts")).status()).toBe(401);

    const token = await signIn(page, "student.a@example.invalid", "Synthetic Student A");
    const headers = { Authorization: token };

    const listResponse = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(listResponse.status()).toBe(200);
    assertPersistedAuditCorrelation(listResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"student_attempt_list_authorized",targetType:"attempt_collection",targetId:null,outcome:"success",reason:"student_self"});
    const listBody = await listResponse.json() as { attempts: Array<{ id: string; learner_id: string }> };
    const listedIds = listBody.attempts.map(attempt => attempt.id);
    expect(listedIds).toContain(attemptA);
    expect(listedIds).not.toContain(attemptB);
    expect(listBody.attempts.every(attempt => attempt.learner_id === "11111111-1111-4111-8111-111111111111")).toBe(true);

    const otherLearnerAttempt = await page.request.get("/api/v1/learner/attempts/" + attemptB, { headers });
    expect(otherLearnerAttempt.status()).toBe(404);

    const ownAttempt = await page.request.get("/api/v1/learner/attempts/" + attemptA, { headers });
    expect(ownAttempt.status()).toBe(200);
    assertPersistedAuditCorrelation(ownAttempt.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"student_attempt_read_authorized",targetType:"attempt",targetId:attemptA,outcome:"success",reason:"student_self"});
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
    assertPersistedAuditCorrelation(createResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"attempt_created",targetType:"attempt",targetId:created.attempt.id,outcome:"success",reason:"learner_action"});
    expect(created.attempt.status).toBe("in_progress");

    const responseText = "This synthetic typed response explains how a carefully chosen detail shapes the reader's interpretation.";
    const saveResponse = await page.request.put(
      "/api/v1/learner/attempts/" + created.attempt.id + "/responses/" + promptA,
      { headers, data: { response_text: responseText } },
    );
    expect(saveResponse.status()).toBe(200);
    assertPersistedAuditCorrelation(saveResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"attempt_response_saved",targetType:"attempt",targetId:created.attempt.id,outcome:"success",reason:"learner_action"});
    const saved = await saveResponse.json() as { response: { word_count: number; version: number } };
    expect(saved.response.word_count).toBeGreaterThan(0);
    expect(saved.response.version).toBe(1);

    const reviseResponse = await page.request.put(
      "/api/v1/learner/attempts/" + created.attempt.id + "/responses/" + promptA,
      { headers, data: { response_text: responseText + " A further explanation supports the interpretation." } },
    );
    expect(reviseResponse.status()).toBe(200);
    assertPersistedAuditCorrelation(reviseResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"attempt_response_saved",targetType:"attempt",targetId:created.attempt.id,outcome:"success",reason:"learner_action"});
    const revised = await reviseResponse.json() as { response: { version: number } };
    expect(revised.response.version).toBe(2);

    const submitResponse = await page.request.post(
      "/api/v1/learner/attempts/" + created.attempt.id + "/submit",
      { headers, data: {} },
    );
    expect(submitResponse.status()).toBe(200);
    assertPersistedAuditCorrelation(submitResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"attempt_submitted",targetType:"attempt",targetId:created.attempt.id,outcome:"success",reason:"learner_action"});
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
    assertPersistedAuditCorrelation(lateEdit.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"student_attempt_response_save",targetType:"attempt",targetId:created.attempt.id,outcome:"failed",reason:"state_conflict"});
    const graderRoute = await page.request.get("/api/v1/grader/queue", { headers });
    expect(graderRoute.status()).toBe(403);
    assertPersistedAuditCorrelation(graderRoute.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"grader_attempt_queue_authorized",targetType:"attempt_queue",targetId:null,outcome:"denied",reason:"resource_scope_denied"});
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
    assertPersistedAuditCorrelation(acceptedResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"assessment_submission_accepted",targetType:"assessment_submission",targetId:acceptedBody.submission.submission_id,outcome:"success",reason:"learner_action"});
    expect(acceptedBody.submission.learner_id).toBe("11111111-1111-4111-8111-111111111111");
    expect(acceptedBody.submission.task_version_id).toBe(taskVersionA);
    expect(acceptedBody.submission.rubric_version_id).toBe("f1111111-1111-4111-8111-111111111111");
    expect(acceptedBody.submission.status).toBe("queued");
    expect(acceptedBody.submission.sla_target_seconds).toBe(86_400);
    expect(new Date(acceptedBody.submission.grading_due_at).getTime() -
      new Date(acceptedBody.submission.accepted_at).getTime()).toBe(86_400_000);
    expect(acceptedBody.submission.capacity_limit_snapshot).toBe(3);
    // Other synthetic learner/owner flows run in parallel. The database must
    // snapshot the real queue load, which can be non-zero, but must accept only
    // while at least one capacity slot remains.
    expect(acceptedBody.submission.open_submissions_before_acceptance).toBeGreaterThanOrEqual(0);
    expect(acceptedBody.submission.open_submissions_before_acceptance)
      .toBeLessThan(acceptedBody.submission.capacity_limit_snapshot);
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

    const concurrentPayload = {
      ...payload,
      idempotency_key: randomUUID(),
      response_text: "This concurrent synthetic retry must produce only one accepted queue item.",
    };
    const concurrentResponses = await Promise.all([
      page.request.post("/api/v1/learner/submissions", { headers, data: concurrentPayload }),
      page.request.post("/api/v1/learner/submissions", { headers, data: concurrentPayload }),
    ]);
    const concurrentBodies = await Promise.all(
      concurrentResponses.map(response => response.json()),
    ) as Array<{ submission: { submission_id: string; is_replay: boolean } }>;
    expect(concurrentResponses.map(response => response.status()).sort()).toEqual([200, 201]);
    expect(concurrentBodies[0].submission.submission_id).toBe(concurrentBodies[1].submission.submission_id);
    expect(concurrentBodies.filter(body => body.submission.is_replay)).toHaveLength(1);

    const listResponse = await page.request.get("/api/v1/learner/submissions", { headers });
    expect(listResponse.status()).toBe(200);
    assertPersistedAuditCorrelation(listResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"student_submission_list_authorized",targetType:"assessment_submission_collection",targetId:null,outcome:"success",reason:"student_self"});
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
    assertPersistedAuditCorrelation(detailResponse.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"student_submission_read_authorized",targetType:"assessment_submission",targetId:acceptedBody.submission.submission_id,outcome:"success",reason:"student_self"});
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
    assertPersistedAuditCorrelation(taskOutsideEnrolment.headers()["x-request-id"],{actorId:"11111111-1111-4111-8111-111111111111",actorRole:"student",action:"student_assessment_submission_accept",targetType:"task_version",targetId:"a2222222-2222-4222-8222-222222222222",outcome:"failed",reason:"resource_not_found"});


    // Phase 1D: the Worker validates actual bytes, not the browser's claims,
    // and only the authorised API can issue short-lived access to the private original.
    const submissionId = acceptedBody.submission.submission_id;
    const fileUploadRoute = "/api/v1/learner/submissions/" + submissionId + "/file";
    const fileReadRoute = "/api/v1/submissions/" + submissionId + "/file";
    expect((await request.post(fileUploadRoute)).status()).toBe(401);
    expect((await request.get(fileReadRoute)).status()).toBe(401);

    const createPdf = async (pages: number): Promise<Buffer> => {
      const document = await PDFDocument.create();
      for (let pageIndex = 0; pageIndex < pages; pageIndex += 1) document.addPage();
      return Buffer.from(await document.save());
    };
    const expectRejectedUpload = async (
      name: string,
      mimeType: string,
      buffer: Buffer,
      status: number,
      error: string,
    ) => {
      const response = await page.request.post(fileUploadRoute, {
        headers,
        multipart: { file: { name, mimeType, buffer } },
      });
      expect(response.status(), name).toBe(status);
      await expect(response.json()).resolves.toMatchObject({ error });
    };

    const onePagePdf = await createPdf(1);
    await expectRejectedUpload("response.txt", "application/pdf", onePagePdf, 400, "pdf_extension_required");
    await expectRejectedUpload("response.pdf", "application/octet-stream", onePagePdf, 415, "pdf_mime_type_required");
    await expectRejectedUpload("response.pdf", "application/pdf", Buffer.from("not a PDF"), 400, "invalid_pdf_signature");
    await expectRejectedUpload(
      "malformed.pdf",
      "application/pdf",
      Buffer.from("%PDF-1.7\\nthis is not a valid PDF document\\n%%EOF"),
      400,
      "malformed_pdf",
    );
    const encryptedPdf = Buffer.from(
      "JVBERi0xLjMKJeLjz9MKMSAwIG9iago8PAovUHJvZHVjZXIgPDU5MTI3MzdiN2I+Cj4+CmVuZG9iagoyIDAgb2JqCjw8Ci9UeXBlIC9QYWdlcwovQ291bnQgMQovS2lkcyBbIDQgMCBSIF0KPj4KZW5kb2JqCjMgMCBvYmoKPDwKL1R5cGUgL0NhdGFsb2cKL1BhZ2VzIDIgMCBSCj4+CmVuZG9iago0IDAgb2JqCjw8Ci9UeXBlIC9QYWdlCi9SZXNvdXJjZXMgPDwKPj4KL01lZGlhQm94IFsgMC4wIDAuMCA2MTIgNzkyIF0KL1BhcmVudCAyIDAgUgo+PgplbmRvYmoKNSAwIG9iago8PAovViAyCi9SIDMKL0xlbmd0aCAxMjgKL1AgNDI5NDk2NzI5MgovRmlsdGVyIC9TdGFuZGFyZAovTyA8NTQyMTc4Zjk2YTVhYWFmNmZlMGFmYzMzYzU1ZTFjOGQ0YTc2NDllZDY4NDU2YzRjMjdiMDc5NGRlOGM0ZTc5Yz4KL1UgPDU1NjY0NzdiZDMzOTRmMTEyN2YzZTRlMTQxNjVlMzYyMjhiZjRlNWU0ZTc1OGE0MTY0MDA0ZTU2ZmZmYTAxMDg+Cj4+CmVuZG9iagp4cmVmCjAgNgowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwMTUgMDAwMDAgbiAKMDAwMDAwMDA1OSAwMDAwMCBuIAowMDAwMDAwMTE4IDAwMDAwIG4gCjAwMDAwMDAxNjcgMDAwMDAgbiAKMDAwMDAwMDI2MSAwMDAwMCBuIAp0cmFpbGVyCjw8Ci9TaXplIDYKL1Jvb3QgMyAwIFIKL0luZm8gMSAwIFIKL0lEIFsgPDM1NjEzMTMyNjIzNzY0MzczODM1NjEzNjY0MzUzNTM3MzUzNjM5NjI2MjM3MzA2NDMyMzQzMjMyNjEzNzMwMzk+IDwzNTYxMzEzMjYyMzc2NDM3MzgzNTYxMzY2NDM1MzUzNzM1MzYzOTYyNjIzNzMwNjQzMjM0MzIzMjYxMzczMDM5PiBdCi9FbmNyeXB0IDUgMCBSCj4+CnN0YXJ0eHJlZgo0NzYKJSVFT0YK",
      "base64",
    );
    await expectRejectedUpload("encrypted.pdf", "application/pdf", encryptedPdf, 422, "encrypted_pdf_not_supported");
    await expectRejectedUpload("eleven-pages.pdf", "application/pdf", await createPdf(11), 413, "pdf_page_limit_exceeded");
    await expectRejectedUpload(
      "too-large.pdf",
      "application/pdf",
      Buffer.alloc(10 * 1024 * 1024 + 1, 0),
      413,
      "pdf_file_too_large",
    );

    // Exercise the learner-facing upload control for an already accepted typed response.
    await page.reload();
    const learnerSubmissionRow = page.getByTestId("learner-submission-" + submissionId);
    await expect(learnerSubmissionRow).toBeVisible();
    await learnerSubmissionRow.getByLabel("Attach optional PDF").setInputFiles({
      name: "learner-response.pdf",
      mimeType: "application/pdf",
      buffer: onePagePdf,
    });
    await expect(learnerSubmissionRow.getByText("Typed response + PDF")).toBeVisible();

    const pdfSubmissionDetail = await page.request.get(
      "/api/v1/learner/submissions/" + submissionId,
      { headers },
    );
    expect(pdfSubmissionDetail.status()).toBe(200);
    const pdfSubmissionDetailBody = await pdfSubmissionDetail.json() as {
      submission: { response_mode: string };
    };
    expect(pdfSubmissionDetailBody.submission.response_mode).toBe("typed_pdf");

    const fileAccess = await page.request.get(fileReadRoute, { headers });
    const fileAccessBody = await fileAccess.json() as {
      file: { signed_url: string; expires_in_seconds: number; sha256: string; page_count: number };
    };
    expect(fileAccess.status()).toBe(200);
    expect(fileAccessBody.file.expires_in_seconds).toBe(60);
    expect(fileAccessBody.file.sha256).toMatch(/^[a-f0-9]{64}$/);
    expect(fileAccessBody.file.byte_size).toBe(onePagePdf.byteLength);
    expect(fileAccessBody.file.mime_type).toBe("application/pdf");
    expect(fileAccessBody.file.page_count).toBe(1);
    const downloadedPdf = await page.request.get(fileAccessBody.file.signed_url);
    expect(downloadedPdf.status()).toBe(200);
    expect((await downloadedPdf.body()).byteLength).toBe(onePagePdf.byteLength);

    // The object path is visible only inside the short-lived signed URL. The
    // ordinary private-object endpoint remains inaccessible to anonymous and
    // authenticated browser clients even when they know that opaque path.
    const signedUrl = new URL(fileAccessBody.file.signed_url);
    const signedPath = signedUrl.pathname.match(/^\/storage\/v1\/object\/sign\/private-submissions\/(.+)$/);
    expect(signedPath).not.toBeNull();
    const objectPath = decodeURIComponent(signedPath![1]);
    const storagePath = objectPath.split("/").map(segment => encodeURIComponent(segment)).join("/");
    const directObjectUrl = new URL(
      "/storage/v1/object/private-submissions/" + storagePath,
      signedUrl.origin,
    ).toString();
    const envLines = readFileSync(".dev.vars", "utf8").split(/\r?\n/);
    const envValue = (key: string): string => {
      const value = envLines.find(line => line.startsWith(key + "="))?.slice(key.length + 1).trim();
      if (!value) throw new Error("Missing local test environment value: " + key);
      return value;
    };
    const publishableKey = envValue("SUPABASE_PUBLISHABLE_KEY");
    const storageAdmin = createClient(
      envValue("SUPABASE_URL"),
      envValue("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false } },
    );

    const anonymousDirect = await page.request.get(directObjectUrl, {
      headers: { apikey: publishableKey },
    });
    expect(anonymousDirect.status()).not.toBe(200);
    const authenticatedDirect = await page.request.get(directObjectUrl, {
      headers: { apikey: publishableKey, Authorization: "Bearer " + token },
    });
    expect(authenticatedDirect.status()).not.toBe(200);

    // Opaque paths are unguessable, and knowing a plausible path does not
    // disclose whether an object exists or grant direct bucket access.
    const guessedObjectPath = randomUUID() + "/" + randomUUID() + ".pdf";
    const guessedStoragePath = guessedObjectPath.split("/").map(segment => encodeURIComponent(segment)).join("/");
    const guessedObjectUrl = new URL(
      "/storage/v1/object/private-submissions/" + guessedStoragePath,
      signedUrl.origin,
    ).toString();
    const anonymousGuessed = await page.request.get(guessedObjectUrl, {
      headers: { apikey: publishableKey },
    });
    expect(anonymousGuessed.status()).not.toBe(200);
    const authenticatedGuessed = await page.request.get(guessedObjectUrl, {
      headers: { apikey: publishableKey, Authorization: "Bearer " + token },
    });
    expect(authenticatedGuessed.status()).not.toBe(200);

    // Issue a deliberately one-second signed URL from the local-only service
    // client to verify the Storage gateway rejects access after expiration.
    const shortLived = await storageAdmin.storage
      .from("private-submissions")
      .createSignedUrl(objectPath, 1);
    expect(shortLived.error).toBeNull();
    expect(shortLived.data?.signedUrl).toBeTruthy();
    await new Promise(resolve => setTimeout(resolve, 2_100));
    const expiredSignedDownload = await page.request.get(shortLived.data!.signedUrl);
    expect(expiredSignedDownload.status()).not.toBe(200);

    const secondLearnerContext = await page.context().browser()!.newContext({
      baseURL: "http://127.0.0.1:8787",
    });
    try {
      const secondLearnerPage = await secondLearnerContext.newPage();
      const secondLearnerToken = await signIn(
        secondLearnerPage,
        "student.c@example.invalid",
        "Synthetic Student C",
      );
      const secondLearnerHeaders = { Authorization: secondLearnerToken };
      const crossLearnerRead = await secondLearnerPage.request.get(fileReadRoute, {
        headers: secondLearnerHeaders,
      });
      expect(crossLearnerRead.status()).toBe(404);
      const crossLearnerUpload = await secondLearnerPage.request.post(fileUploadRoute, {
        headers: secondLearnerHeaders,
        multipart: { file: { name: "other-learner.pdf", mimeType: "application/pdf", buffer: onePagePdf } },
      });
      expect(crossLearnerUpload.status()).toBe(404);
    } finally {
      await secondLearnerContext.close();
    }

    const malformedPdfOnly = await page.request.post("/api/v1/learner/pdf-submissions", {
      headers,
      multipart: {
        task_version_id: taskVersionA,
        idempotency_key: randomUUID(),
        response_mode: "pdf_only",
        transcript_pages: "[]",
        file: {
          name: "invalid-signature.pdf",
          mimeType: "application/pdf",
          buffer: Buffer.from("not a PDF"),
        },
      },
    });
    expect(malformedPdfOnly.status()).toBe(400);
    await expect(malformedPdfOnly.json()).resolves.toMatchObject({
      error: "invalid_pdf_signature",
    });

    const elevenPageDocument = await PDFDocument.create();
    for (let pageIndex = 0; pageIndex < 11; pageIndex += 1) elevenPageDocument.addPage();
    const elevenPagePdf = Buffer.from(await elevenPageDocument.save());
    const overPageLimitPdfOnly = await page.request.post("/api/v1/learner/pdf-submissions", {
      headers,
      multipart: {
        task_version_id: taskVersionA,
        idempotency_key: randomUUID(),
        response_mode: "pdf_only",
        transcript_pages: "[]",
        file: {
          name: "eleven-pages.pdf",
          mimeType: "application/pdf",
          buffer: elevenPagePdf,
        },
      },
    });
    expect(overPageLimitPdfOnly.status()).toBe(413);
    await expect(overPageLimitPdfOnly.json()).resolves.toMatchObject({
      error: "pdf_page_limit_exceeded",
    });

    // Exercise atomic PDF-only acceptance. Page 1 contains a digital text
    // layer; page 2 is image/blank-only and must be marked, never OCR-guessed.
    const pdfOnlyDocument = await PDFDocument.create();
    const digitalPage = pdfOnlyDocument.addPage();
    digitalPage.drawText("Synthetic digital transcript text captured from the original PDF page.", {
      size: 12,
      x: 50,
      y: 700,
    });
    pdfOnlyDocument.addPage();
    const pdfOnlyBuffer = Buffer.from(await pdfOnlyDocument.save());

    await page.reload();
    await page.getByLabel("Assessment task").selectOption(taskVersionA);
    await page.getByLabel("Response format").selectOption("pdf_only");
    await page.locator("#proto-learner-pdf").setInputFiles({
      name: "synthetic-pdf-only.pdf",
      mimeType: "application/pdf",
      buffer: pdfOnlyBuffer,
    });
    await page.getByRole("button", { name: "Submit PDF response" }).click();
    await expect(
      page.getByRole("status").filter({ hasText: /Your PDF submission was accepted/ }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole("status").filter({ hasText: /page\(s\) 2/ })).toBeVisible();

    const refreshedSubmissions = await page.request.get("/api/v1/learner/submissions", { headers });
    expect(refreshedSubmissions.status()).toBe(200);
    const refreshedBody = await refreshedSubmissions.json() as {
      submissions: Array<{
        id: string;
        response_mode: string;
        accepted_at: string;
        grading_due_at: string;
      }>;
    };
    const pdfOnlySubmission = refreshedBody.submissions.find(item => item.response_mode === "pdf_only");
    expect(pdfOnlySubmission).toBeTruthy();
    expect(
      new Date(pdfOnlySubmission!.grading_due_at).getTime() -
      new Date(pdfOnlySubmission!.accepted_at).getTime(),
    ).toBe(86_400_000);

    const pdfOnlyFileResponse = await page.request.get(
      "/api/v1/submissions/" + pdfOnlySubmission!.id + "/file",
      { headers },
    );
    expect(pdfOnlyFileResponse.status()).toBe(200);
    const pdfOnlyFile = await pdfOnlyFileResponse.json() as {
      transcript: {
        version: number;
        method: string;
        state: string;
        verification_state: string;
        page_count: number;
        pages: Array<{ page_number: number; status: string; text: string }>;
        text: string;
      };
    };
    expect(pdfOnlyFile.transcript.version).toBe(1);
    expect(pdfOnlyFile.transcript.method).toBe("pdfjs");
    expect(pdfOnlyFile.transcript.state).toBe("partial");
    expect(pdfOnlyFile.transcript.verification_state).toBe("unverified");
    expect(pdfOnlyFile.transcript.page_count).toBe(2);
    expect(pdfOnlyFile.transcript.pages[0]).toMatchObject({
      page_number: 1,
      status: "digital_text",
    });
    expect(pdfOnlyFile.transcript.pages[0].text).toBe(
      "Synthetic digital transcript text captured from the original PDF page.",
    );
    expect(pdfOnlyFile.transcript.pages[1]).toEqual({
      page_number: 2,
      text: "",
      status: "no_text_layer",
    });
    expect(pdfOnlyFile.transcript.text).toContain("Synthetic digital transcript text");

    const graderContext = await page.context().browser()!.newContext({
      baseURL: "http://127.0.0.1:8787",
    });
    try {
      const graderPage = await graderContext.newPage();
      const graderToken = await signIn(graderPage, "grader.a@example.invalid", "Synthetic Grader A");
      const unassignedGraderRead = await graderPage.request.get(fileReadRoute, {
        headers: { Authorization: graderToken },
      });
      expect(unassignedGraderRead.status()).toBe(404);
    } finally {
      await graderContext.close();
    }

    const ownerContext = await page.context().browser()!.newContext({
      baseURL: "http://127.0.0.1:8787",
    });
    try {
      const ownerPage = await ownerContext.newPage();
      const ownerAal2Token = await signInOwnerAal2(ownerPage);
      process.env.PLAYWRIGHT_SYNTHETIC_OWNER_AAL2_TOKEN = ownerAal2Token;
      writeFileSync(
        join(tmpdir(), "gradioprep-playwright-owner-aal2-token"),
        ownerAal2Token,
        { mode: 0o600 },
      );

      // Move the synthetic PDF-only submission into the assigned review state.
      const assignPdfForReview = await ownerPage.request.post(
        "/api/v1/admin/submissions/" + pdfOnlySubmission!.id + "/assign",
        {
          headers: { Authorization: ownerAal2Token },
          data: {
            grader_user_id: "55555555-5555-4555-8555-555555555555",
            reason: "Synthetic PDF transcript review exercise",
          },
        },
      );
      expect(assignPdfForReview.status()).toBe(201);

      const assignOlderSubmissionForQueueOrder = await ownerPage.request.post(
        "/api/v1/admin/submissions/" + acceptedBody.submission.submission_id + "/assign",
        {
          headers: { Authorization: ownerAal2Token },
          data: {
            grader_user_id: "55555555-5555-4555-8555-555555555555",
            reason: "Synthetic oldest-first grader queue verification",
          },
        },
      );
      expect(assignOlderSubmissionForQueueOrder.status()).toBe(201);

      await expect(ownerPage.getByRole("heading", { name: "PDF and transcript review" })).toBeVisible();
      await ownerPage.getByRole("button", { name: "Refresh queue" }).click();
      await ownerPage.getByLabel("Submission queue").selectOption(pdfOnlySubmission!.id);
      await expect(ownerPage.getByTitle("Original learner submission PDF")).toBeVisible();
      await expect(ownerPage.getByRole("textbox", { name: "Transcript text for page 2" })).toBeVisible();

      await ownerPage.getByRole("textbox", { name: "Transcript text for page 2" })
        .fill("Synthetic human transcription for page two, checked against the original PDF.");
      await ownerPage.getByLabel("Review note")
        .fill("Manually transcribed page two after checking the original PDF.");
      await ownerPage.getByRole("button", { name: "Save corrected transcript version" }).click();
      await expect(ownerPage.getByRole("status").filter({
        hasText: "A new corrected transcript version was saved",
      })).toBeVisible({ timeout: 15_000 });

      const correctedTranscriptResponse = await ownerPage.request.get(
        "/api/v1/submissions/" + pdfOnlySubmission!.id + "/file",
        { headers: { Authorization: ownerAal2Token } },
      );
      expect(correctedTranscriptResponse.status()).toBe(200);
      const correctedTranscriptBody = await correctedTranscriptResponse.json() as {
        transcript: {
          version: number;
          verification_state: string;
          pages: Array<{ page_number: number; text: string; status: string }>;
        };
      };
      expect(correctedTranscriptBody.transcript.version).toBe(2);
      expect(correctedTranscriptBody.transcript.verification_state).toBe("teacher_corrected");
      expect(correctedTranscriptBody.transcript.pages[1]).toMatchObject({
        page_number: 2,
        status: "teacher_transcribed",
      });
      expect(correctedTranscriptBody.transcript.pages[1].text)
        .toContain("Synthetic human transcription for page two");

      // A second save with no text changes records independent teacher verification.
      await ownerPage.getByLabel("Review note")
        .fill("Verified the corrected page-by-page transcript against the original PDF.");
      await ownerPage.getByRole("button", { name: "Save verified transcript version" }).click();
      await expect(ownerPage.getByRole("status").filter({
        hasText: "A new verified transcript version was saved",
      })).toBeVisible({ timeout: 15_000 });
      const verifiedTranscriptResponse = await ownerPage.request.get(
        "/api/v1/submissions/" + pdfOnlySubmission!.id + "/file",
        { headers: { Authorization: ownerAal2Token } },
      );
      expect(verifiedTranscriptResponse.status()).toBe(200);
      const verifiedTranscriptBody = await verifiedTranscriptResponse.json() as {
        transcript: { version: number; verification_state: string };
      };
      expect(verifiedTranscriptBody.transcript).toMatchObject({
        version: 3,
        verification_state: "teacher_verified",
      });

      process.env.PLAYWRIGHT_SYNTHETIC_GRADER_WORKSPACE_PDF_ID = pdfOnlySubmission!.id;
      process.env.PLAYWRIGHT_SYNTHETIC_GRADER_WORKSPACE_OLDER_ID = acceptedBody.submission.submission_id;
      const queueSubmissionIds = [concurrentBodies[0].submission.submission_id];
      for (const submissionIdToWithdraw of [...new Set(queueSubmissionIds)]) {
        await withdrawSyntheticSubmission(ownerPage, ownerAal2Token, submissionIdToWithdraw);
      }
    } finally {
      await ownerContext.close();
    }
  });

  
test("learner task selector keeps PDF attachments disabled for typed-only tasks", async ({ page }) => {
  const token = await signIn(page, "student.a@example.invalid", "Synthetic Student A");
  const panel = page.getByTestId("learner-submissions-panel");
  const typedOnlyTaskId = "a3333333-3333-4333-8333-333333333333";

  await panel.getByLabel("Assessment task").selectOption(typedOnlyTaskId);
  await expect(panel.getByText(
    "This task accepts typed responses only. PDF attachments are not enabled.",
  )).toBeVisible();
  await expect(panel.getByLabel("Optional PDF attachment")).toHaveCount(0);

  const accepted = await page.request.post("/api/v1/learner/submissions", {
    headers: { Authorization: token },
    data: {
      task_version_id: typedOnlyTaskId,
      idempotency_key: randomUUID(),
      response_text: "This synthetic written response verifies a typed-only assessment submission without an optional PDF.",
    },
  });
  const body = await accepted.json() as { submission?: { submission_id?: string }; error?: string };
  expect(accepted.status(), JSON.stringify(body)).toBe(201);
  const submissionId = body.submission?.submission_id;
  expect(submissionId).toBeTruthy();

  await page.reload();
  const row = page.getByTestId("learner-submission-" + submissionId);
  await expect(row).toBeVisible();
  await expect(row.getByText("Typed response only")).toBeVisible();
  await expect(row.getByLabel("Attach optional PDF")).toHaveCount(0);

  const ownerAal2Token = process.env.PLAYWRIGHT_SYNTHETIC_OWNER_AAL2_TOKEN;
  expect(ownerAal2Token, "The PDF submission test must provide a fresh synthetic Owner AAL2 token.")
    .toBeTruthy();
  await withdrawSyntheticSubmission(page, ownerAal2Token!, submissionId!);
  delete process.env.PLAYWRIGHT_SYNTHETIC_OWNER_AAL2_TOKEN;
});

test("guardian cannot accept a human-assessment submission or use staff assessment APIs", async ({ page }) => {
    const token = await signIn(page, "guardian.d@example.invalid", "Synthetic Guardian D");
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
    const token = await signIn(page, "guardian.b@example.invalid", "Synthetic Guardian B");
    const headers = { Authorization: token };

    const learnerAttempts = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(learnerAttempts.status()).toBe(403);
    await expect(learnerAttempts.json()).resolves.toMatchObject({ error: "role_required" });
    assertPersistedAuditCorrelation(learnerAttempts.headers()["x-request-id"],{actorId:actorIdFromAuthorizationHeader(token),actorRole:"guardian",action:"student_attempt_list_authorized",targetType:"attempt_collection",targetId:null,outcome:"denied",reason:"resource_scope_denied"});

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
      request.put("/api/v1/submissions/" + submissionId + "/transcript", {
        data: {
          expected_version: 1,
          pages: [
            { page_number: 1, text: "Synthetic digital text for page one.", status: "digital_text" },
            { page_number: 2, text: "Synthetic teacher transcription for page two.", status: "teacher_transcribed" },
          ],
          review_note: "Checked both pages against the original synthetic PDF.",
        },
      }),
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
      request.post("/api/v1/owner/submissions/" + submissionId + "/reassign", {
        data: { grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", reason: "Anonymous route denial" },
      }),
      request.post("/api/v1/owner/submissions/" + submissionId + "/transition", {
        data: { target_status: "withdrawn", reason: "Anonymous route denial" },
      }),
      request.get("/api/v1/owner/assessment-versions/" + submissionId + "/private-qa"),
      request.post("/api/v1/owner/assessment-versions/" + submissionId + "/private-qa", {
        data: {
          checks: { rubric_alignment: true },
          status: "passed",
          explanation: "Synthetic QA route denial test.",
          reviewer_action: "No change required.",
        },
      }),
    ]);
    for (const response of anonymousChecks) expect(response.status()).toBe(401);

    const studentContext = await browser.newContext({ baseURL: "http://127.0.0.1:8787" });
    const studentPage = await studentContext.newPage();
    const studentToken = await signIn(studentPage, "student.a@example.invalid", "Synthetic Student A");
    const studentHeaders = { Authorization: studentToken };
    const studentChecks = await Promise.all([
      studentPage.request.get("/api/v1/grader/submissions", { headers: studentHeaders }),
      studentPage.request.put("/api/v1/submissions/" + submissionId + "/transcript", {
        headers: studentHeaders,
        data: {
          expected_version: 1,
          pages: [
            { page_number: 1, text: "Synthetic digital text for page one.", status: "digital_text" },
            { page_number: 2, text: "Synthetic teacher transcription for page two.", status: "teacher_transcribed" },
          ],
          review_note: "Checked both pages against the original synthetic PDF.",
        },
      }),
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
      studentPage.request.post("/api/v1/owner/submissions/" + submissionId + "/reassign", {
        headers: studentHeaders,
        data: { grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", reason: "Student route denial" },
      }),
      studentPage.request.post("/api/v1/owner/submissions/" + submissionId + "/transition", {
        headers: studentHeaders,
        data: { target_status: "withdrawn", reason: "Student route denial" },
      }),
      studentPage.request.get("/api/v1/owner/assessment-versions/" + submissionId + "/private-qa", {
        headers: studentHeaders,
      }),
      studentPage.request.post("/api/v1/owner/assessment-versions/" + submissionId + "/private-qa", {
        headers: studentHeaders,
        data: {
          checks: { rubric_alignment: true },
          status: "passed",
          explanation: "Synthetic QA route denial test.",
          reviewer_action: "No change required.",
        },
      }),
    ]);
    for (const response of studentChecks) {
      expect(response.status()).toBe(403);
      await expect(response.json()).resolves.toMatchObject({ error: "role_required" });
    }

    await studentContext.close();
    const guardianContext = await browser.newContext({ baseURL: "http://127.0.0.1:8787" });
    const guardianPage = await guardianContext.newPage();
    const guardianToken = await signIn(guardianPage, "guardian.c@example.invalid", "Synthetic Guardian C");
    const guardianQaResponse = await guardianPage.request.get(
      "/api/v1/owner/assessment-versions/" + submissionId + "/private-qa",
      { headers: { Authorization: guardianToken } },
    );
    expect(guardianQaResponse.status()).toBe(403);
    await expect(guardianQaResponse.json()).resolves.toMatchObject({ error: "role_required" });

    const guardianTranscriptReview = await guardianPage.request.put(
      "/api/v1/submissions/" + submissionId + "/transcript",
      {
        headers: { Authorization: guardianToken },
        data: {
          expected_version: 1,
          pages: [
            { page_number: 1, text: "Synthetic digital text for page one.", status: "digital_text" },
            { page_number: 2, text: "Synthetic teacher transcription for page two.", status: "teacher_transcribed" },
          ],
          review_note: "Checked both pages against the original synthetic PDF.",
        },
      },
    );
    expect(guardianTranscriptReview.status()).toBe(403);
    await expect(guardianTranscriptReview.json()).resolves.toMatchObject({ error: "role_required" });

    const guardianResponse = await guardianPage.request.get("/api/v1/grader/submissions", {
      headers: { Authorization: guardianToken },
    });
    expect(guardianResponse.status()).toBe(403);
    await expect(guardianResponse.json()).resolves.toMatchObject({ error: "role_required" });

    await guardianContext.close();
    const graderContext = await browser.newContext({ baseURL: "http://127.0.0.1:8787" });
    const graderPage = await graderContext.newPage();
    // Grader A is used by the concurrent AAL2-enrolment test and Grader B
    // is revoked by the owner-security test. Use the dedicated Grader C fixture
    // so parallel tests cannot mutate this AAL1-only account's state.
    const graderAal1 = await signIn(graderPage, "grader.c@example.invalid", "Synthetic Grader C");
    const graderResponse = await graderPage.request.get("/api/v1/grader/submissions", {
      headers: { Authorization: graderAal1 },
    });
    expect(graderResponse.status()).toBe(403);
    await expect(graderResponse.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(graderResponse.headers()["x-request-id"],{actorId:actorIdFromAuthorizationHeader(graderAal1),actorRole:"grader",action:"grader_submission_queue_authorized",targetType:"assessment_submission_queue",targetId:null,outcome:"denied",reason:"resource_scope_denied"});
    const graderTranscriptReview = await graderPage.request.put(
      "/api/v1/submissions/" + submissionId + "/transcript",
      {
        headers: { Authorization: graderAal1 },
        data: {
          expected_version: 1,
          pages: [
            { page_number: 1, text: "Synthetic digital text for page one.", status: "digital_text" },
            { page_number: 2, text: "Synthetic teacher transcription for page two.", status: "teacher_transcribed" },
          ],
          review_note: "Checked both pages against the original synthetic PDF.",
        },
      },
    );
    expect(graderTranscriptReview.status()).toBe(403);
    await expect(graderTranscriptReview.json()).resolves.toMatchObject({ error: "mfa_required" });
    assertPersistedAuditCorrelation(graderTranscriptReview.headers()["x-request-id"],{
      actorId:actorIdFromAuthorizationHeader(graderAal1),
      actorRole:"grader",
      action:"staff_submission_transcript_review",
      targetType:"assessment_submission",
      targetId:submissionId,
      outcome:"denied",
      reason:"resource_scope_denied"
    });

    const graderQaRoute = await graderPage.request.get(
      "/api/v1/owner/assessment-versions/" + submissionId + "/private-qa",
      { headers: { Authorization: graderAal1 } },
    );
    expect(graderQaRoute.status()).toBe(403);
    await expect(graderQaRoute.json()).resolves.toMatchObject({ error: "role_required" });

    const graderLifecycleRoute = await graderPage.request.post(
      "/api/v1/owner/submissions/" + submissionId + "/reassign",
      {
        headers: { Authorization: graderAal1 },
        data: { grader_user_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb", reason: "Grader route denial" },
      },
    );
    expect(graderLifecycleRoute.status()).toBe(403);
    await expect(graderLifecycleRoute.json()).resolves.toMatchObject({ error: "role_required" });
    await graderContext.close();
  });

  test("grader AAL2 session sees only the active assigned queue and response", async ({ page, browser }) => {
    test.setTimeout(150_000);
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
    assertPersistedAuditCorrelation(queueResponse.headers()["x-request-id"],{actorId:"55555555-5555-4555-8555-555555555555",actorRole:"grader",action:"grader_attempt_queue_authorized",targetType:"attempt_queue",targetId:null,outcome:"success",reason:"assigned_grader_aal2"});
    const queuePayload = await queueResponse.json() as Record<string, unknown>;
    expect(queueResponse.status(), JSON.stringify(queuePayload)).toBe(200);
    const queueBody = queuePayload as { attempts: Array<{ id: string }> };
    const queueIds = queueBody.attempts.map(attempt => attempt.id);
    expect(queueIds).toContain(attemptA);
    expect(queueIds).not.toContain(attemptB);

    const assignedDetail = await page.request.get("/api/v1/grader/attempts/" + attemptA, { headers });
    expect(assignedDetail.status()).toBe(200);
    assertPersistedAuditCorrelation(assignedDetail.headers()["x-request-id"],{actorId:"55555555-5555-4555-8555-555555555555",actorRole:"grader",action:"grader_attempt_read_authorized",targetType:"attempt",targetId:attemptA,outcome:"success",reason:"active_grader_assignment_aal2"});
    const detailBody = await assignedDetail.json() as {
      attempt: { attempt_responses: Array<{ response_text: string }> };
      prompts: Array<{ prompt_text: string }>;
    };
    expect(detailBody.attempt.attempt_responses).toHaveLength(1);
    expect(detailBody.attempt).not.toHaveProperty("timer");
    expect(detailBody.prompts).toHaveLength(1);

    const unassignedToThisGrader = await page.request.get("/api/v1/grader/attempts/" + attemptB, { headers });
    expect(unassignedToThisGrader.status()).toBe(404);
    assertPersistedAuditCorrelation(unassignedToThisGrader.headers()["x-request-id"],{actorId:"55555555-5555-4555-8555-555555555555",actorRole:"grader",action:"grader_attempt_read_authorized",targetType:"attempt",targetId:attemptB,outcome:"denied",reason:"resource_scope_denied"});
    const learnerRoute = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(learnerRoute.status()).toBe(403);
    await expect(learnerRoute.json()).resolves.toMatchObject({ error: "role_required" });

    const pdfSubmissionId = process.env.PLAYWRIGHT_SYNTHETIC_GRADER_WORKSPACE_PDF_ID;
    const olderSubmissionId = process.env.PLAYWRIGHT_SYNTHETIC_GRADER_WORKSPACE_OLDER_ID;
    const ownerAal2TokenPath = join(tmpdir(), "gradioprep-playwright-owner-aal2-token");
    let ownerAal2Token = "";
    try {
      ownerAal2Token = readFileSync(ownerAal2TokenPath, "utf8").trim();
    } catch {
      throw new Error("The prior synthetic Owner AAL2 session was not saved for grader queue cleanup.");
    } finally {
      try { unlinkSync(ownerAal2TokenPath); } catch { /* already removed */ }
    }
    expect(pdfSubmissionId).toBeTruthy();
    expect(olderSubmissionId).toBeTruthy();
    expect(ownerAal2Token).toBeTruthy();

    // Exercise the protected timer-adjustment Worker route with a separate
    // synthetic learner attempt. The Owner token comes from the existing
    // authenticated Owner+AAL2 setup above; no real learner information is used.
    const timerLearnerContext = await browser.newContext({ baseURL: "http://127.0.0.1:8787" });
    try {
      const timerLearnerPage = await timerLearnerContext.newPage();
      const timerLearnerToken = await signIn(
        timerLearnerPage,
        "student.a@example.invalid",
        "Synthetic Student A",
      );
      const timerAttemptCreate = await timerLearnerPage.request.post(
        "/api/v1/learner/attempts",
        {
          headers: { Authorization: timerLearnerToken },
          data: { task_version_id: "a3333333-3333-4333-8333-333333333333" },
        },
      );
      const timerAttemptCreateBody = await timerAttemptCreate.json() as {
        attempt?: { id: string };
        error?: string;
      };
      expect(timerAttemptCreate.status(), JSON.stringify(timerAttemptCreateBody)).toBe(201);
      const timerAttemptId = timerAttemptCreateBody.attempt!.id;

      const studentAdjustmentDenied = await timerLearnerPage.request.post(
        "/api/v1/staff/attempts/" + timerAttemptId + "/timer-adjustments",
        {
          headers: { Authorization: timerLearnerToken },
          data: {
            mode: "extended",
            extension_seconds: 120,
            reason_category: "approved_extension",
          },
        },
      );
      expect(studentAdjustmentDenied.status()).toBe(403);
      await expect(studentAdjustmentDenied.json()).resolves.toMatchObject({ error: "role_required" });
      assertPersistedAuditCorrelation(studentAdjustmentDenied.headers()["x-request-id"], {
        actorId: "11111111-1111-4111-8111-111111111111",
        actorRole: "student",
        action: "staff_attempt_timer_adjustment",
        targetType: "attempt",
        targetId: timerAttemptId,
        outcome: "denied",
        reason: "resource_scope_denied",
      });

      const extensionResponse = await timerLearnerPage.request.post(
        "/api/v1/staff/attempts/" + timerAttemptId + "/timer-adjustments",
        {
          headers: { Authorization: ownerAal2Token },
          data: {
            mode: "extended",
            extension_seconds: 120,
            reason_category: "approved_extension",
          },
        },
      );
      const extensionBody = await extensionResponse.json() as {
        adjustment?: { effective_allowance_seconds: number; accommodation_mode: string };
        error?: string;
      };
      expect(extensionResponse.status(), JSON.stringify(extensionBody)).toBe(201);
      expect(extensionBody.adjustment).toMatchObject({
        effective_allowance_seconds: 720,
        accommodation_mode: "extended",
      });
      assertPersistedAuditCorrelation(extensionResponse.headers()["x-request-id"], {
        actorId: "88888888-8888-4888-8888-888888888888",
        actorRole: "owner",
        action: "attempt_timer_adjusted",
        targetType: "attempt",
        targetId: timerAttemptId,
        outcome: "success",
        reason: "approved_extension",
      });

      const extendedTimerRead = await timerLearnerPage.request.get(
        "/api/v1/learner/attempts/" + timerAttemptId,
        { headers: { Authorization: timerLearnerToken } },
      );
      expect(extendedTimerRead.status()).toBe(200);
      const extendedTimerBody = await extendedTimerRead.json() as {
        attempt: { timer: { allowance_seconds: number; remaining_seconds: number } };
      };
      expect(extendedTimerBody.attempt.timer.allowance_seconds).toBe(720);
      expect(extendedTimerBody.attempt.timer.remaining_seconds).toBeGreaterThan(0);

      const untimedResponse = await timerLearnerPage.request.post(
        "/api/v1/staff/attempts/" + timerAttemptId + "/timer-adjustments",
        {
          headers: { Authorization: ownerAal2Token },
          data: {
            mode: "untimed",
            reason_category: "accessibility_accommodation",
          },
        },
      );
      const untimedBody = await untimedResponse.json() as {
        adjustment?: { effective_allowance_seconds: number | null; accommodation_mode: string };
        error?: string;
      };
      expect(untimedResponse.status(), JSON.stringify(untimedBody)).toBe(201);
      expect(untimedBody.adjustment).toMatchObject({
        effective_allowance_seconds: null,
        accommodation_mode: "untimed",
      });
      assertPersistedAuditCorrelation(untimedResponse.headers()["x-request-id"], {
        actorId: "88888888-8888-4888-8888-888888888888",
        actorRole: "owner",
        action: "attempt_timer_adjusted",
        targetType: "attempt",
        targetId: timerAttemptId,
        outcome: "success",
        reason: "accessibility_accommodation",
      });

      const untimedRead = await timerLearnerPage.request.get(
        "/api/v1/learner/attempts/" + timerAttemptId,
        { headers: { Authorization: timerLearnerToken } },
      );
      expect(untimedRead.status()).toBe(200);
      const untimedReadBody = await untimedRead.json() as {
        attempt: {
          timer: { allowance_seconds: number | null; remaining_seconds: number | null; is_expired: boolean };
          attempt_responses: Array<{ prompt_id: string }>;
        };
        prompts: Array<{ id: string }>;
      };
      expect(untimedReadBody.attempt.timer).toMatchObject({
        allowance_seconds: null,
        remaining_seconds: null,
        is_expired: false,
      });

      const timerPromptId = untimedReadBody.prompts[0]?.id;
      expect(timerPromptId).toBeTruthy();
      const timerResponseSave = await timerLearnerPage.request.put(
        "/api/v1/learner/attempts/" + timerAttemptId + "/responses/" + timerPromptId,
        {
          headers: { Authorization: timerLearnerToken },
          data: { response_text: "A synthetic response saved after an authorised untimed accommodation." },
        },
      );
      expect(timerResponseSave.status()).toBe(200);
      const timerAttemptSubmit = await timerLearnerPage.request.post(
        "/api/v1/learner/attempts/" + timerAttemptId + "/submit",
        { headers: { Authorization: timerLearnerToken }, data: {} },
      );
      expect(timerAttemptSubmit.status()).toBe(200);
    } finally {
      await timerLearnerContext.close();
    }

    // The assigned Grader is denied private PDF/transcript retrieval at AAL1;
    // the same active assignment is tested successfully below after MFA.
    const aal1PrivateFileResponse = await page.request.get(
      "/api/v1/submissions/" + pdfSubmissionId + "/file",
      { headers: { Authorization: firstFactorToken } },
    );
    const aal1PrivateFilePayload = await aal1PrivateFileResponse.json() as {
      error?: string;
      file?: { signed_url?: string };
      transcript?: unknown;
    };
    expect(aal1PrivateFileResponse.status(), JSON.stringify(aal1PrivateFilePayload)).toBe(404);
    expect(aal1PrivateFilePayload).toMatchObject({ error: "submission_file_not_found" });
    expect(aal1PrivateFilePayload.file).toBeUndefined();
    expect(aal1PrivateFilePayload.transcript).toBeUndefined();

    // A different Grader with AAL2 but no active assignment must not receive
    // either the private PDF URL or its transcript.
    const unassignedAal2Context = await page.context().browser()!.newContext({
      baseURL: "http://127.0.0.1:8787",
    });
    try {
      const unassignedAal2Page = await unassignedAal2Context.newPage();
      const unassignedFirstFactorToken = await signIn(
        unassignedAal2Page,
        "grader.c@example.invalid",
        "Synthetic Grader C",
      );
      let unassignedAal2Token = unassignedFirstFactorToken;
      unassignedAal2Page.on("request", request => {
        if (new URL(request.url()).pathname === "/api/v1/me" && request.method() === "GET") {
          unassignedAal2Token = request.headers()["authorization"] ?? unassignedAal2Token;
        }
      });
      await expect(unassignedAal2Page.getByRole("button", { name: "Set up authenticator app" })).toBeVisible();
      await unassignedAal2Page.getByRole("button", { name: "Set up authenticator app" }).click();
      await expect(unassignedAal2Page.getByRole("img", { name: "Authenticator app setup QR code" })).toBeVisible();
      const unassignedSecret = await unassignedAal2Page.getByTestId("totp-secret").innerText();
      await waitForTotpWindow();
      await unassignedAal2Page.getByLabel("Authenticator code").fill(createTotpCode(unassignedSecret));
      await unassignedAal2Page.getByRole("button", { name: "Verify and enable" }).click();
      await expect(unassignedAal2Page.getByText("Verified authenticator", { exact: true })).toBeVisible();
      await expect.poll(() => unassignedAal2Token !== unassignedFirstFactorToken, { timeout: 10_000 }).toBe(true);

      const unassignedAal2Response = await unassignedAal2Page.request.get(
        "/api/v1/submissions/" + pdfSubmissionId + "/file",
        { headers: { Authorization: unassignedAal2Token } },
      );
      const unassignedAal2Payload = await unassignedAal2Response.json() as {
        error?: string;
        file?: { signed_url?: string };
        transcript?: unknown;
      };
      expect(unassignedAal2Response.status(), JSON.stringify(unassignedAal2Payload)).toBe(404);
      expect(unassignedAal2Payload).toMatchObject({ error: "submission_file_not_found" });
      expect(unassignedAal2Payload.file).toBeUndefined();
      expect(unassignedAal2Payload.transcript).toBeUndefined();
    } finally {
      await unassignedAal2Context.close();
    }

    const assessmentQueueResponse = await page.request.get("/api/v1/grader/submissions", { headers });
    expect(assessmentQueueResponse.status()).toBe(200);
    const assessmentQueueBody = await assessmentQueueResponse.json() as {
      submissions: Array<{ id: string; accepted_at: string }>;
    };
    const queueIdsInOrder = assessmentQueueBody.submissions.map(item => item.id);
    const queueIdsSorted = [...assessmentQueueBody.submissions]
      .sort((left, right) => left.accepted_at.localeCompare(right.accepted_at) || left.id.localeCompare(right.id))
      .map(item => item.id);
    expect(queueIdsInOrder).toEqual(queueIdsSorted);
    expect(queueIdsInOrder).toContain(olderSubmissionId);
    expect(queueIdsInOrder).toContain(pdfSubmissionId);
    expect(queueIdsInOrder.indexOf(olderSubmissionId!)).toBeLessThan(queueIdsInOrder.indexOf(pdfSubmissionId!));

    const workspace = page.getByTestId("grader-workspace");
    await expect(workspace).toBeVisible();
    const privateFileResponse = await page.request.get(
      "/api/v1/submissions/" + pdfSubmissionId + "/file",
      { headers },
    );
    const privateFilePayload = await privateFileResponse.json() as {
      file?: { signed_url?: string };
      transcript?: {
        version?: number;
        verification_state?: string;
        page_count?: number;
        pages?: Array<{ page_number: number; text: string; status: string }>;
      } | null;
      error?: string;
    };
    expect(privateFileResponse.status(), JSON.stringify(privateFilePayload)).toBe(200);
    expect(privateFilePayload.file?.signed_url).toBeTruthy();
    expect(privateFilePayload.transcript).toMatchObject({
      version: 3,
      verification_state: "teacher_verified",
      page_count: 2,
    });
    expect(privateFilePayload.transcript?.pages, JSON.stringify(privateFilePayload)).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          page_number: 1,
          text: "Synthetic digital transcript text captured from the original PDF page.",
        }),
        expect.objectContaining({
          page_number: 2,
          text: "Synthetic human transcription for page two, checked against the original PDF.",
        }),
      ]),
    );

    await page.getByLabel("Assigned submissions · oldest first").selectOption(pdfSubmissionId!);
    await expect(page.getByRole("heading", { name: "Synthetic Phase 1C response task A" })).toBeVisible();
    await expect(page.getByText(
      "Synthetic test prompt: explain how one selected detail shapes a reader's understanding.",
      { exact: true },
    )).toBeVisible();
    await expect(page.getByRole("heading", { name: "Exact rubric for this submission" })).toBeVisible();
    await expect(page.getByText("Synthetic Rubric A — Version 1 · Version 1", { exact: true })).toBeVisible();
    await expect(page.getByTitle("Original grader submission PDF")).toBeVisible();
    await expect(page.getByText("Synthetic digital transcript text captured from the original PDF page.")).toBeVisible();
    await expect(page.getByText("Synthetic human transcription for page two, checked against the original PDF.")).toBeVisible();

    const detailResponse = await page.request.get(
      "/api/v1/grader/submissions/" + pdfSubmissionId,
      { headers },
    );
    expect(detailResponse.status()).toBe(200);
    const assessmentDetailBody = await detailResponse.json() as {
      criteria: Array<{ id: string; max_points: number }>;
    };
    expect(assessmentDetailBody.criteria).toHaveLength(2);
    await page.locator("#proto-grader-overall-feedback")
      .fill("The response selects a relevant detail and explains how it shapes a reader's understanding.");
    for (const criterion of assessmentDetailBody.criteria) {
      await page.locator("#proto-grader-score-" + criterion.id).fill("3");
      await page.locator("#proto-grader-criterion-feedback-" + criterion.id)
        .fill("The awarded mark is supported by specific evidence from the response.");
    }

    const saveResponsePromise = page.waitForResponse(response =>
      response.url().includes("/api/v1/grader/submissions/" + pdfSubmissionId + "/draft") &&
      response.request().method() === "PUT",
    );
    await page.getByRole("button", { name: "Save private grading draft" }).click();
    const saveResponse = await saveResponsePromise;
    const saveRequestBody = saveResponse.request().postDataJSON() as Record<string, unknown>;
    expect(saveRequestBody).not.toHaveProperty("change_reason");
    const saveResponseBody = await saveResponse.json() as { draft?: unknown; error?: string };
    expect(saveResponse.status(), JSON.stringify(saveResponseBody)).toBe(200);
    expect(saveResponseBody.draft).toBeTruthy();
    assertPersistedAuditCorrelation(saveResponse.headers()["x-request-id"], {
      actorId: "55555555-5555-4555-8555-555555555555",
      actorRole: "grader",
      action: "assessment_draft_saved",
      targetType: "assessment_submission",
      targetId: pdfSubmissionId!,
      outcome: "success",
      reason: "grader_action",
    });
    await expect(page.getByRole("status").filter({
      hasText: "Private grading draft saved. It has not been published",
    })).toBeVisible();

    const prePublicationLearnerContext = await page.context().browser()!.newContext({
      baseURL: "http://127.0.0.1:8787",
    });
    try {
      const prePublicationLearner = await prePublicationLearnerContext.newPage();
      const prePublicationToken = await signIn(
        prePublicationLearner,
        "student.a@example.invalid",
        "Synthetic Student A",
      );
      const prePublicationDetail = await prePublicationLearner.request.get(
        "/api/v1/learner/submissions/" + pdfSubmissionId,
        { headers: { Authorization: prePublicationToken } },
      );
      expect(prePublicationDetail.status()).toBe(200);
      const prePublicationBody = await prePublicationDetail.json() as {
        submission: { assessment_versions: unknown[] };
      };
      expect(prePublicationBody.submission.assessment_versions).toHaveLength(0);
    } finally {
      await prePublicationLearnerContext.close();
    }

    const publishResponsePromise = page.waitForResponse(response =>
      response.url().includes("/api/v1/grader/submissions/" + pdfSubmissionId + "/publish") &&
      response.request().method() === "POST",
    );
    page.once("dialog", dialog => dialog.accept());
    await page.getByRole("button", { name: "Publish feedback to learner" }).click();
    const publishResponse = await publishResponsePromise;
    expect(publishResponse.status()).toBe(201);
    assertPersistedAuditCorrelation(publishResponse.headers()["x-request-id"], {
      actorId: "55555555-5555-4555-8555-555555555555",
      actorRole: "grader",
      action: "assessment_feedback_published",
      targetType: "assessment_submission",
      targetId: pdfSubmissionId!,
      outcome: "success",
      reason: "human_grader_publication",
    });
    await expect(page.getByRole("status").filter({ hasText: "Feedback published." })).toBeVisible();

    const learnerContext = await page.context().browser()!.newContext({
      baseURL: "http://127.0.0.1:8787",
    });
    try {
      const learnerPage = await learnerContext.newPage();
      const learnerToken = await signIn(learnerPage, "student.a@example.invalid", "Synthetic Student A");
      const learnerHeaders = { Authorization: learnerToken };
      const learnerDetail = await learnerPage.request.get(
        "/api/v1/learner/submissions/" + pdfSubmissionId,
        { headers: learnerHeaders },
      );
      expect(learnerDetail.status()).toBe(200);
      const learnerDetailBody = await learnerDetail.json() as {
        submission: { assessment_versions: Array<{ version_number: number; overall_feedback: string }> };
      };
      expect(learnerDetailBody.submission.assessment_versions).toHaveLength(1);
      expect(learnerDetailBody.submission.assessment_versions[0].version_number).toBe(1);
      expect(learnerDetailBody.submission.assessment_versions[0].overall_feedback)
        .toContain("The response selects a relevant detail");
      const learnerRow = learnerPage.getByTestId("learner-submission-" + pdfSubmissionId);
      await expect(learnerRow).toBeVisible();
      await learnerRow.getByRole("button", { name: "View published feedback" }).click();
      await expect(learnerRow.getByTestId("learner-published-feedback"))
        .toContainText("The response selects a relevant detail");
      await expect(learnerRow.getByTestId("learner-published-feedback"))
        .toContainText("The awarded mark is supported by specific evidence");
    } finally {
      await learnerContext.close();
    }

    const closePublishedSubmission = await page.request.post(
      "/api/v1/owner/submissions/" + pdfSubmissionId + "/transition",
      {
        headers: { Authorization: ownerAal2Token! },
        data: {
          target_status: "closed",
          reason: "Synthetic grader workspace publication verification completed",
        },
      },
    );
    expect(closePublishedSubmission.status()).toBe(200);
    assertPersistedAuditCorrelation(closePublishedSubmission.headers()["x-request-id"], {
      actorId: "88888888-8888-4888-8888-888888888888",
      actorRole: "owner",
      action: "assessment_submission_closed",
      targetType: "assessment_submission",
      targetId: pdfSubmissionId!,
      outcome: "success",
      reason: "owner_closure",
    });
    await withdrawSyntheticSubmission(page, ownerAal2Token!, olderSubmissionId!);
  });
  test("student can start timed practice and see the advisory countdown", async ({ page }) => {
    const token = await signIn(page, "student.a@example.invalid", "Synthetic Student A");
    const headers = { Authorization: token };
    const panel = page.getByTestId("learner-attempt-panel");
    await expect(panel).toBeVisible();

    const timedTask = panel.getByTestId("practice-task-a3333333-3333-4333-8333-333333333333");
    await expect(timedTask).toContainText("10 minutes");
    await timedTask.getByRole("button", { name: "Start practice" }).click();

    await expect(panel.getByRole("heading", { name: "Synthetic Phase 2 typed-only task" })).toBeVisible();
    await expect(panel.getByTestId("attempt-countdown")).toHaveText(/^\d{2}:\d{2}$/);
    const attemptsResponse = await page.request.get("/api/v1/learner/attempts", { headers });
    expect(attemptsResponse.status()).toBe(200);
    const attemptsBody = await attemptsResponse.json() as {
      attempts: Array<{ id: string; task_version_id: string; status: string }>;
    };
    const timedAttempt = attemptsBody.attempts.find(item =>
      item.task_version_id === "a3333333-3333-4333-8333-333333333333" && item.status === "in_progress"
    );
    expect(timedAttempt).toBeTruthy();
    const attemptRead = await page.request.get(
      "/api/v1/learner/attempts/" + timedAttempt!.id,
      { headers },
    );
    expect(attemptRead.status()).toBe(200);
    const attemptBody = await attemptRead.json() as {
      attempt: {
        started_at: string;
        status: string;
        timer: {
          allowance_seconds: number;
          timer_policy_version: number;
          deadline_at: string;
          server_now: string;
          remaining_seconds: number;
          is_expired: boolean;
        };
      };
    };
    expect(attemptBody.attempt.status).toBe("in_progress");
    expect(attemptBody.attempt.timer).toMatchObject({
      allowance_seconds: 600,
      timer_policy_version: 1,
      is_expired: false,
    });
    expect(new Date(attemptBody.attempt.timer.deadline_at).getTime()
      - new Date(attemptBody.attempt.started_at).getTime()).toBe(600_000);
    expect(attemptBody.attempt.timer.remaining_seconds).toBeGreaterThan(0);

    await panel.getByLabel("Your response").fill(
      "This synthetic practice response remains editable while the advisory task timer is running.",
    );
    await panel.getByRole("button", { name: "Save response" }).click();
    await expect(panel.getByRole("status").filter({ hasText: "Response saved. The advisory countdown does not block saving." })).toBeVisible();
    await expect(panel.getByRole("button", { name: "Submit practice" })).toBeEnabled();
  });


  test("timed attempts link transactionally to one matching human assessment", async ({ page }) => {
    const localEnvLines = readFileSync(".dev.vars", "utf8").split(/\r?\n/);
    const envValue = (key: string): string => {
      const value = localEnvLines.find(line => line.startsWith(key + "="))?.slice(key.length + 1).trim();
      if (!value) throw new Error("Missing local test environment value: " + key);
      return value;
    };
    const localAdmin = createClient(
      envValue("SUPABASE_URL"),
      envValue("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false } },
    );
    // Obtain the second synthetic learner token directly from local Auth. This
    // avoids a second browser navigation and keeps the test focused on API authorization.
    const studentBAuth = createClient(
      envValue("SUPABASE_URL"),
      envValue("SUPABASE_PUBLISHABLE_KEY"),
      { auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false } },
    );
    const studentBId = "22222222-2222-4222-8222-222222222222";
    const mypPathwayId = "synthetic-ib-myp-year-4";
    const createdSubmissionIds: string[] = [];

    const acceptAssessment = async (
      token: string,
      taskVersionId: string,
      idempotencyKey = randomUUID(),
    ): Promise<string> => {
      const response = await page.request.post("/api/v1/learner/submissions", {
        headers: { Authorization: token },
        data: {
          task_version_id: taskVersionId,
          idempotency_key: idempotencyKey,
          response_text: "This synthetic human-assessment response explains how a selected detail supports an interpretation of the published task.",
        },
      });
      const body = await response.json() as {
        submission?: { submission_id?: string };
        error?: string;
      };
      expect(response.status(), JSON.stringify(body)).toBe(201);
      const submissionId = body.submission?.submission_id;
      expect(submissionId).toBeTruthy();
      createdSubmissionIds.push(submissionId!);
      return submissionId!;
    };

    const createAttempt = async (
      token: string,
      taskVersionId: string,
      promptId: string,
    ): Promise<{ attemptId: string; submit: () => Promise<void> }> => {
      const headers = { Authorization: token };
      const started = await page.request.post("/api/v1/learner/attempts", {
        headers,
        data: { task_version_id: taskVersionId },
      });
      const startedBody = await started.json() as { attempt?: { id?: string }; error?: string };
      expect(started.status(), JSON.stringify(startedBody)).toBe(201);
      const attemptId = startedBody.attempt?.id;
      expect(attemptId).toBeTruthy();

      const saved = await page.request.put(
        "/api/v1/learner/attempts/" + attemptId + "/responses/" + promptId,
        {
          headers,
          data: {
            response_text: "This synthetic timed response uses relevant evidence and explains how it contributes to a clear interpretation of the task.",
          },
        },
      );
      expect(saved.status()).toBe(200);

      return {
        attemptId: attemptId!,
        submit: async () => {
          const submitted = await page.request.post(
            "/api/v1/learner/attempts/" + attemptId + "/submit",
            { headers, data: {} },
          );
          expect(submitted.status()).toBe(200);
        },
      };
    };

    const linkAttempt = (
      token: string,
      attemptId: string,
      assessmentSubmissionId: string,
      idempotencyKey: string,
    ) => page.request.post(
      "/api/v1/learner/attempts/" + attemptId + "/assessment-link",
      {
        headers: { Authorization: token },
        data: { assessment_submission_id: assessmentSubmissionId, idempotency_key: idempotencyKey },
      },
    );

    try {
      const learnerA = await signIn(page, "student.a@example.invalid", "Synthetic Student A");
      const enrolment = await localAdmin.from("course_enrolments").upsert(
        { learner_id: studentBId, pathway_id: mypPathwayId, status: "active" },
        { onConflict: "learner_id,pathway_id" },
      );
      if (enrolment.error) throw new Error("Could not prepare Student B's synthetic pathway: " + enrolment.error.message);

      const primaryAttempt = await createAttempt(
        learnerA, "a3333333-3333-4333-8333-333333333333", "b3333333-3333-4333-8333-333333333333",
      );
      const primarySubmission = await acceptAssessment(
        learnerA, "a3333333-3333-4333-8333-333333333333",
      );
      const primaryKey = randomUUID();

      const preSubmit = await linkAttempt(
        learnerA, primaryAttempt.attemptId, primarySubmission, randomUUID(),
      );
      expect(preSubmit.status()).toBe(409);
      await expect(preSubmit.json()).resolves.toMatchObject({ error: "attempt_not_submitted" });
      assertPersistedAuditCorrelation(preSubmit.headers()["x-request-id"], {
        actorId: "11111111-1111-4111-8111-111111111111",
        actorRole: "student",
        action: "student_timed_attempt_assessment_link",
        targetType: "attempt",
        targetId: primaryAttempt.attemptId,
        outcome: "failed",
        reason: "state_conflict",
      });

      await primaryAttempt.submit();
      const concurrent = await Promise.all([
        linkAttempt(learnerA, primaryAttempt.attemptId, primarySubmission, primaryKey),
        linkAttempt(learnerA, primaryAttempt.attemptId, primarySubmission, primaryKey),
      ]);
      expect(concurrent.map(response => response.status()).sort()).toEqual([200, 201]);
      const concurrentBodies = await Promise.all(
        concurrent.map(response => response.json() as Promise<{
          link?: { link_id: string; attempt_id: string; assessment_submission_id: string; is_replay: boolean };
        }>),
      );
      expect(concurrentBodies[0].link?.link_id).toBe(concurrentBodies[1].link?.link_id);
      expect(concurrentBodies.map(body => body.link?.is_replay).sort()).toEqual([false, true]);
      const createdResponse = concurrent.find(response => response.status() === 201)!;
      const createdBody = concurrentBodies[concurrent.indexOf(createdResponse)];
      expect(createdBody.link).toMatchObject({
        attempt_id: primaryAttempt.attemptId,
        assessment_submission_id: primarySubmission,
        is_replay: false,
      });
      assertPersistedAuditCorrelation(createdResponse.headers()["x-request-id"], {
        actorId: "11111111-1111-4111-8111-111111111111",
        actorRole: "student",
        action: "student_timed_attempt_assessment_linked",
        targetType: "timed_attempt_assessment_link",
        targetId: createdBody.link!.link_id,
        outcome: "success",
        reason: "learner_action",
      });

      const secondAttempt = await createAttempt(
        learnerA, "a3333333-3333-4333-8333-333333333333", "b3333333-3333-4333-8333-333333333333",
      );
      await secondAttempt.submit();
      const secondSubmission = await acceptAssessment(
        learnerA, "a3333333-3333-4333-8333-333333333333",
      );

      const reusedKey = await linkAttempt(
        learnerA, secondAttempt.attemptId, secondSubmission, primaryKey,
      );
      expect(reusedKey.status()).toBe(409);
      await expect(reusedKey.json()).resolves.toMatchObject({
        error: "timed_attempt_assessment_link_idempotency_conflict",
      });

      const secondUseOfAttempt = await linkAttempt(
        learnerA, primaryAttempt.attemptId, secondSubmission, randomUUID(),
      );
      expect(secondUseOfAttempt.status()).toBe(409);
      await expect(secondUseOfAttempt.json()).resolves.toMatchObject({
        error: "timed_attempt_assessment_link_conflict",
      });

      const secondUseOfSubmission = await linkAttempt(
        learnerA, secondAttempt.attemptId, primarySubmission, randomUUID(),
      );
      expect(secondUseOfSubmission.status()).toBe(409);
      await expect(secondUseOfSubmission.json()).resolves.toMatchObject({
        error: "timed_attempt_assessment_link_conflict",
      });

      const otherTaskAttempt = await createAttempt(
        learnerA, "a1111111-1111-4111-8111-111111111111", "b1111111-1111-4111-8111-111111111111",
      );
      await otherTaskAttempt.submit();
      const crossTask = await linkAttempt(
        learnerA, otherTaskAttempt.attemptId, primarySubmission, randomUUID(),
      );
      expect(crossTask.status()).toBe(409);
      await expect(crossTask.json()).resolves.toMatchObject({ error: "attempt_task_version_mismatch" });

      const { data: studentBAuthResult, error: studentBAuthError } =
        await studentBAuth.auth.signInWithPassword({
          email: "student.b@example.invalid",
          password: localPassword,
        });
      if (studentBAuthError || !studentBAuthResult.session?.access_token) {
        throw new Error("Could not authenticate the second synthetic learner with local Auth.");
      }
      const learnerB = "Bearer " + studentBAuthResult.session.access_token;
      const otherLearnerSubmission = await acceptAssessment(
        learnerB, "a3333333-3333-4333-8333-333333333333",
      );
      const crossLearnerSubmission = await linkAttempt(
        learnerA, primaryAttempt.attemptId, otherLearnerSubmission, randomUUID(),
      );
      expect(crossLearnerSubmission.status()).toBe(404);
      await expect(crossLearnerSubmission.json()).resolves.toMatchObject({
        error: "assessment_submission_not_found",
      });
      const crossLearnerAttempt = await linkAttempt(
        learnerB, primaryAttempt.attemptId, otherLearnerSubmission, randomUUID(),
      );
      expect(crossLearnerAttempt.status()).toBe(404);
      await expect(crossLearnerAttempt.json()).resolves.toMatchObject({
        error: "attempt_not_found",
      });

      const withdrawn = await localAdmin
        .from("assessment_submissions")
        .update({ status: "withdrawn" })
        .eq("id", secondSubmission);
      if (withdrawn.error) throw new Error("Could not prepare withdrawn synthetic assessment: " + withdrawn.error.message);
      const withdrawnLink = await linkAttempt(
        learnerA, secondAttempt.attemptId, secondSubmission, randomUUID(),
      );
      expect(withdrawnLink.status()).toBe(409);
      await expect(withdrawnLink.json()).resolves.toMatchObject({
        error: "assessment_submission_not_linkable",
      });
    } finally {
      if (createdSubmissionIds.length > 0) {
        await localAdmin.from("assessment_submissions")
          .update({ status: "withdrawn" })
          .in("id", createdSubmissionIds);
      }
      await localAdmin.from("course_enrolments")
        .delete()
        .eq("learner_id", studentBId)
        .eq("pathway_id", mypPathwayId);
      await studentBAuth.auth.signOut({ scope: "local" });
    }
  });

});
