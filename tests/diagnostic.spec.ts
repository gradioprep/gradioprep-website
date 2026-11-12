import { expect, test } from "@playwright/test";
import { randomUUID } from "node:crypto";

const learnerEmail = "student.a@example.invalid";
const learnerPassword = ["Local-only", "GradiPrep", "2026!"].join("-");
const startPath = "/api/v1/learner/diagnostics/ib-myp-g9-cycle1/start";

function userIdFromAuthorization(authorization: string): string {
  const token = authorization.replace(/^Bearer\s+/i, "");
  const payload = token.split(".")[1];
  if (!payload) throw new Error("The authenticated test session did not contain a JWT payload.");
  const claims = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as { sub?: string };
  if (!claims.sub) throw new Error("The authenticated test session did not contain a user ID.");
  return claims.sub;
}

test.describe("Cycle 1 Preliminary Assessment — Read & View and Language in Context evidence API", () => {
  test("student starts, saves, resumes and submits the unscored Read & View and Language in Context slice", async ({ page, request }) => {
    const unauthenticatedStart = await request.post(startPath, {
      data: { idempotency_key: randomUUID() },
    });
    expect(unauthenticatedStart.status()).toBe(401);
    const unauthenticatedPublication = await request.post("/api/v1/admin/pa-feedback/publish", {
      data: { review_id: randomUUID(), idempotency_key: randomUUID() },
    });
    expect(unauthenticatedPublication.status()).toBe(401);

    const unauthenticatedReportCreate = await request.post(
      "/api/v1/learner/diagnostic-attempts/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee/evaluation-report",
      { data: { idempotency_key: randomUUID() } },
    );
    expect(unauthenticatedReportCreate.status()).toBe(401);
    const unauthenticatedReportRead = await request.get(
      "/api/v1/learner/evaluation-reports/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",
    );
    expect(unauthenticatedReportRead.status()).toBe(401);

    let accessToken = "";
    page.on("request", outgoing => {
      if (new URL(outgoing.url()).pathname === "/api/v1/me" && outgoing.method() === "GET") {
        accessToken = outgoing.headers()["authorization"] ?? accessToken;
      }
    });

    await page.goto("/account");
    await page.getByLabel("Email address").fill(learnerEmail);
    await page.getByLabel("Password").fill(learnerPassword);
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Student A", exact: true })).toBeVisible();
    await expect.poll(() => Boolean(accessToken)).toBe(true);

    const headers = { Authorization: accessToken };
    const learnerUserId = userIdFromAuthorization(accessToken);
    const startedResponsePromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === startPath && response.request().method() === "POST",
    );
    await page.getByRole("button", { name: "Start / continue Preliminary Assessment" }).click();
    const started = await startedResponsePromise;
    const startedBody = await started.json() as {
      diagnostic: { diagnostic_code: string; version: number };
      attempt: { id: string; status: string; is_replay: boolean };
      section_status: string;
      available_observation_codes: string[];
    };
    expect(started.status(), JSON.stringify(startedBody)).toBe(201);
    await expect(page.getByRole("heading", { name: "Stimulus A · The Repair Table", exact: true })).toBeVisible();
    await expect(page.getByText("Reading and language tasks", { exact: true })).toBeVisible();
    expect(startedBody.diagnostic).toMatchObject({ diagnostic_code: "ib-myp-g9-cycle1", version: 1 });
    expect(startedBody.attempt.status).toBe("in_progress");
    expect(startedBody.attempt.is_replay).toBe(false);
    expect(startedBody.section_status).toBe("read_view_language_context_only");
    expect(startedBody.available_observation_codes).toHaveLength(15);
    expect(startedBody.available_observation_codes).not.toContain("AW01");
    expect(startedBody.available_observation_codes).not.toContain("CW01");
    await expect(page.getByRole("heading", { name: /Creative\/Purposeful Production · The Book Swap/ })).toHaveCount(0);
    await expect(page.getByRole("heading", { name: /Analytical Writing · The Unfinished Label/ })).toHaveCount(0);
    await expect(page.locator("audio")).toHaveCount(0);
    const firstWrittenResponse = page.locator(".proto-diagnostic-text-field").first();
    await expect(firstWrittenResponse.locator(".proto-diagnostic-word-count")).toHaveText("0 / 40 words");
    await firstWrittenResponse.locator("textarea").fill("An answer with six words in total");
    await expect(firstWrittenResponse.locator(".proto-diagnostic-word-count")).toHaveText("7 / 40 words");
    await firstWrittenResponse.locator("textarea").fill(Array(46).fill("word").join(" "));
    await expect(firstWrittenResponse.locator(".proto-diagnostic-word-count")).toHaveText("46 / 40 words");
    await firstWrittenResponse.locator("textarea").fill("");
    await expect(firstWrittenResponse.locator(".proto-diagnostic-word-count")).toHaveText("0 / 40 words");


    const resumed = await request.post(startPath, {
      headers,
      data: { idempotency_key: randomUUID() },
    });
    const resumedBody = await resumed.json() as { attempt: { id: string; is_replay: boolean } };
    expect(resumed.status()).toBe(200);
    expect(resumedBody.attempt.id).toBe(startedBody.attempt.id);
    expect(resumedBody.attempt.is_replay).toBe(true);

    const invalidResponse = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/RV01",
      { headers, data: { response: { a: "B", b: ["A", "A"] } } },
    );
    expect(invalidResponse.status()).toBe(400);

    const outOfScopeObservation = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/L01",
      { headers, data: { response: { a: "A", b: ["A", "B"] } } },
    );
    expect(outOfScopeObservation.status()).toBe(404);

    // The AW01 format is recognised, but the current fifteen-observation
    // published fixture must never accept an AW draft response.
    const unreleasedAnalyticalWriting = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/AW01",
      { headers, data: { response: { text: "A reasoned interpretation supported by clear textual evidence." } } },
    );
    expect(unreleasedAnalyticalWriting.status()).toBe(400);
    expect(await unreleasedAnalyticalWriting.json()).toMatchObject({
      error: "invalid_diagnostic_response",
    });
    const unreleasedCreative = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/CW01",
      { headers, data: { response: {
        plan: "A viewpoint, surprise, and ending.",
        initial_draft: "The first sentence of the scene.",
        final_text: "The finished school magazine scene.",
        revision_before: "A quiet room",
        revision_after: "A bright hall",
        revision_note: "The revision strengthens atmosphere.",
      } } },
    );
    expect(unreleasedCreative.status()).toBe(400);
    expect(await unreleasedCreative.json()).toMatchObject({ error: "invalid_diagnostic_response" });
    const injectedAnalyticalScore = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/AW01",
      { headers, data: { response: { text: "A reasoned interpretation supported by evidence.", score: 7 } } },
    );
    expect(injectedAnalyticalScore.status()).toBe(400);
    const standaloneRubricDimension = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/AW02",
      { headers, data: { response: { text: "A second essay is not an assessment dimension." } } },
    );
    expect(standaloneRubricDimension.status()).toBe(404);

    const invalidLanguageContext = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/LC01",
      { headers, data: { response: { choice: "A", extra: "must be rejected" } } },
    );
    expect(invalidLanguageContext.status()).toBe(400);

    const responses: Array<[string, Record<string, unknown>]> = [
      ["RV01", { a: "B", b: ["A", "C"] }],
      ["RV02", { text: "Nia records what was completed and what must wait, showing a balanced view of the afternoon." }],
      ["RV03", { text: "The bright note creates a lively moment and helps show why the small success matters." }],
      ["RV04", { choice: "A" }],
      ["RV05", { choice: "A" }],
      ["RV06", { text: "The claim exaggerates the result because 17 of the 48 objects were not repaired on the day." }],
      ["RV07a", { text: "Nia sees success as honest progress, while the poster counts outcomes and makes unfinished work visible." }],
      ["RV07b", { text: "The story uses a sequence of events, while the poster groups results into clear visual categories." }],
      ["RV08", { order: ["2", "3", "4", "5", "1"], explanation: "The sequence moves from uncertainty to small success and then an honest record of what remains." }],
      ["RV09", { choice: "B", explanation: "The figures list completed and unfinished outcomes, unlike the tagline or invitation." }],
      ["LC01", { choice: "A" }],
      ["LC02", { choice: "A" }],
      ["LC03", { choice: "B" }],
      ["LC04", { choice: "A" }],
      ["LC05", { text: "Please place bags on the shelves beside the entrance so that the stairs and walkway remain clear for everyone." }],
    ];

    for (const [code, response] of responses) {
      const saved = await request.put(
        "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/" + code,
        { headers, data: { response } },
      );
      const savedBody = await saved.json() as { response?: { observation_code: string; revision_number: number }; error?: string };
      expect(saved.status(), code + ": " + JSON.stringify(savedBody)).toBe(200);
      expect(savedBody.response).toMatchObject({ observation_code: code, revision_number: 1 });
    }

    const submitted = await request.post(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/submit",
      { headers, data: {} },
    );
    const submittedBody = await submitted.json() as {
      attempt?: { attempt_id: string; status: string; saved_observations: number; expected_observations: number };
      error?: string;
    };
    expect(submitted.status(), JSON.stringify(submittedBody)).toBe(200);
    expect(submittedBody.attempt).toMatchObject({
      attempt_id: startedBody.attempt.id,
      status: "submitted",
      saved_observations: 15,
      expected_observations: 15,
    });

    const reportCreatePath =
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/evaluation-report";
    const reportIdempotencyKey = randomUUID();
    const invalidReportCreate = await request.post(reportCreatePath, {
      headers,
      data: { idempotency_key: reportIdempotencyKey, route_version_id: "caller-controlled" },
    });
    expect(invalidReportCreate.status()).toBe(400);

    const createdReportResponse = await request.post(reportCreatePath, {
      headers,
      data: { idempotency_key: reportIdempotencyKey },
    });
    const createdReportBody = await createdReportResponse.json() as {
      report?: {
        report_record_id: string;
        report_version_id: string;
        version_number: number;
        curriculum_mapping_status: string;
        evidence_sufficiency_status: string;
      };
      is_replay?: boolean;
      error?: string;
    };
    expect(createdReportResponse.status(), JSON.stringify(createdReportBody)).toBe(201);
    expect(createdReportBody.report).toMatchObject({
      version_number: 1,
      curriculum_mapping_status: "contains_unmapped",
      evidence_sufficiency_status: "insufficient",
    });
    expect(createdReportBody.is_replay).toBe(false);

    const replayedReportResponse = await request.post(reportCreatePath, {
      headers,
      data: { idempotency_key: reportIdempotencyKey },
    });
    const replayedReportBody = await replayedReportResponse.json() as typeof createdReportBody;
    expect(replayedReportResponse.status(), JSON.stringify(replayedReportBody)).toBe(200);
    expect(replayedReportBody.report?.report_record_id).toBe(createdReportBody.report?.report_record_id);
    expect(replayedReportBody.report?.report_version_id).toBe(createdReportBody.report?.report_version_id);
    expect(replayedReportBody.is_replay).toBe(true);

    const reportRecordId = createdReportBody.report?.report_record_id;
    expect(reportRecordId).toBeTruthy();
    const reportReadPath = "/api/v1/learner/evaluation-reports/" + reportRecordId;
    const invalidReportVersion = await request.get(reportReadPath + "?version=0", { headers });
    expect(invalidReportVersion.status()).toBe(400);

    const unavailableReportVersion = await request.get(reportReadPath + "?version=2", { headers });
    expect(unavailableReportVersion.status()).toBe(404);
    const reportReadResponse = await request.get(reportReadPath + "?version=1", { headers });
    const reportReadBody = await reportReadResponse.json() as {
      report?: {
        report_record_id: string;
        report_version_id: string;
        report_scope: string;
        version_number: number;
        curriculum_mapping_status: string;
        evidence_sufficiency_status: string;
        scope_snapshot: Record<string, unknown>;
        eligible_analytics_snapshot: Record<string, unknown>;
        curriculum_mapping_snapshot: unknown[];
        learner_evidence_snapshot: Array<Record<string, unknown>>;
        [key: string]: unknown;
      };
      error?: string;
    };
    expect(reportReadResponse.status(), JSON.stringify(reportReadBody)).toBe(200);
    const report = reportReadBody.report;
    expect(report).toMatchObject({
      report_record_id: reportRecordId,
      report_version_id: createdReportBody.report?.report_version_id,
      report_scope: "pa_baseline",
      version_number: 1,
      curriculum_mapping_status: "contains_unmapped",
      evidence_sufficiency_status: "insufficient",
    });
    expect(report?.scope_snapshot).toMatchObject({
      report_scoring_state: "unscored_baseline",
      official_grade_conversion: "not_applicable",
    });
    expect(report?.eligible_analytics_snapshot).toMatchObject({
      status: "not_available_for_unscored_preliminary_assessment",
      score: null,
      official_grade: null,
      percentile_or_rank: null,
    });
    expect(report?.curriculum_mapping_snapshot).toHaveLength(15);
    expect(report?.learner_evidence_snapshot).toHaveLength(15);
    expect(report?.learner_evidence_snapshot[0]).toHaveProperty("response_sha256");
    expect(report?.learner_evidence_snapshot[0]).not.toHaveProperty("response_text");
    expect(report).not.toHaveProperty("learner_id");
    expect(report).not.toHaveProperty("created_by");
    expect(report).not.toHaveProperty("idempotency_key");

    await page.evaluate(({ learnerUserId, attemptId, reportRecordId, idempotencyKey }) => {
      localStorage.setItem("gradioprep.evaluation-report.record:" + learnerUserId, reportRecordId);
      localStorage.setItem("gradioprep.evaluation-report.idempotency:" + attemptId, idempotencyKey);
    }, {
      learnerUserId,
      attemptId: startedBody.attempt.id,
      reportRecordId: reportRecordId!,
      idempotencyKey: reportIdempotencyKey,
    });

    const lateEdit = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/RV02",
      { headers, data: { response: { text: "Submitted evidence cannot be changed." } } },
    );
    expect(lateEdit.status()).toBe(409);
    await expect(lateEdit.json()).resolves.toMatchObject({ error: "diagnostic_attempt_not_editable" });

    // Reload and resume the submitted attempt. The UI must reuse the report's
    // idempotency key, restore the submitted section read-only, and show the report.
    await page.reload();
    await expect(page.getByRole("heading", { name: "Synthetic Student A", exact: true })).toBeVisible();
    const uiReportReplayPromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === reportCreatePath && response.request().method() === "POST",
    );
    await page.getByRole("button", { name: "Start / continue Preliminary Assessment" }).click();
    const uiReportReplay = await uiReportReplayPromise;
    const uiReportReplayBody = await uiReportReplay.json() as {
      report?: { report_record_id: string; version_number: number };
      is_replay?: boolean;
    };
    expect(uiReportReplay.status(), JSON.stringify(uiReportReplayBody)).toBe(200);
    expect(uiReportReplayBody.report).toMatchObject({
      report_record_id: reportRecordId,
      version_number: 1,
    });
    expect(uiReportReplayBody.is_replay).toBe(true);
    await expect(page.getByRole("heading", { name: "Stimulus A · The Repair Table", exact: true })).toBeVisible();
    await expect(page.getByRole("button", { name: "Submit Preliminary Assessment section" })).toHaveCount(0);
    await expect(page.locator('input[type="radio"]').first()).toBeDisabled();
    await expect(page.locator("textarea").first()).toBeDisabled();
    await expect(page.getByRole("button", { name: "View your Evaluation Report →" })).toBeVisible();

    await page.getByRole("button", { name: "View your Evaluation Report →" }).click();
    await expect(page.getByRole("heading", { name: "Your starting point is recorded." })).toBeVisible();
    await expect(page.getByText(/initial record of your work, not a scored evaluation/i)).toBeVisible();
    await expect(page.getByRole("group", { name: "Evaluation Report versions" })).toContainText("Viewing version 1 · Latest");
    await expect(page.getByRole("button", { name: "Previous version" })).toBeDisabled();
    await expect(page.getByRole("button", { name: "Next version" })).toBeDisabled();
    const latestRefresh = page.waitForResponse(response =>
      new URL(response.url()).pathname === reportReadPath && response.request().method() === "GET",
    );
    await page.getByRole("button", { name: "Check latest report" }).click();
    const refreshedReport = await latestRefresh;
    expect(refreshedReport.status()).toBe(200);
    expect(new URL(refreshedReport.url()).searchParams.has("version")).toBe(false);
    await expect(page.getByRole("group", { name: "Evaluation Report versions" })).toContainText("Viewing version 1 · Latest");
    await expect(page.getByText("Not yet sufficient", { exact: true })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Assessment scope and source" })).toBeVisible();
    const scopePanel = page.getByRole("region", { name: "Assessment scope and source" });
    await expect(scopePanel).toContainText("Synthetic");
    await expect(scopePanel).toContainText("Report version 1");
    await expect(page.getByText("Awaiting reviewed feedback", { exact: true })).toBeVisible();
    await expect(page.getByText(/not a final teacher-approved Evaluation Report/i)).toBeVisible();
    await expect(page.locator(".proto-evaluation-coverage")).toContainText("15");
    await expect(page.locator(".proto-evaluation-coverage")).toContainText("15 / 15");
    await expect(page.locator(".proto-evaluation-coverage")).toContainText("0 / 15");
    await expect(page.locator(".proto-evaluation-coverage")).toContainText("2 sittings");
    await expect(page.locator(".proto-evaluation-coverage")).toContainText("80 planned minutes");
    const itemEvidence = page.locator(".proto-evaluation-observations li");
    await expect(itemEvidence).toHaveCount(15);
    await expect(itemEvidence.first()).toContainText("RV01");
    await expect(itemEvidence.first()).toContainText("Response saved");
    await expect(itemEvidence.first()).toContainText("Curriculum connection unavailable");
    await expect(page.getByRole("list", { name: /Verified curriculum outcomes for/ })).toHaveCount(0);
    await expect(itemEvidence.last()).toContainText("LC05");
    await expect(itemEvidence.last()).toContainText("Response saved");
    await expect(page.getByText("Not scored", { exact: true })).toBeVisible();
    await expect(page.getByText(/does not contain a score, grade or percentile comparison/i)).toBeVisible();
    await expect(page.getByRole("heading", { name: "Teacher-reviewed feedback" })).toHaveCount(0);
  });
});
