import { test, expect } from "@playwright/test";
import { readFileSync } from "node:fs";

const worker = readFileSync("worker/index.ts", "utf8");
const workspace = readFileSync("src/auth/PaScoringWorkspacePanel.tsx", "utf8");
const feedbackWorkspace = readFileSync("src/auth/PaFeedbackWorkspacePanel.tsx", "utf8");

test("private Owner scoring UI reuses the 30-dimension human marking and report pipeline", () => {
  expect(feedbackWorkspace).toContain("{owner && <PaScoringWorkspacePanel");
  expect(feedbackWorkspace).toContain("feedbackReviews={reviews}");
  expect(workspace).toContain('report.curriculum_mapping_status === "complete_direct"');
  expect(workspace).toContain('report.evidence_sufficiency_status === "sufficient"');
  expect(workspace).toContain("new Set(codes).size === 30");
  expect(workspace).toContain("RV: 10, LC: 5, AW: 5, CW: 5, SP: 5");
  expect(workspace).toContain("/api/v1/admin/pa-scoring/drafts");
  expect(workspace).toContain("/api/v1/admin/pa-scoring/review");
  expect(workspace).toContain("/api/v1/admin/pa-scoring/joint");
  expect(workspace).toContain("/api/v1/admin/pa-scoring/manifest/");
  expect(workspace).toContain("/api/v1/admin/pa-scoring/publish");
  expect(workspace).toContain("I have checked all 30 human scores");
  expect(workspace).toContain("setConfirmed(false)");
  expect(workspace).toContain("idempotencyKey");
  expect(workspace).not.toContain("autoGrade");
  expect(workspace).not.toContain("official_ib_grade");
});

test("all private scoring actions require Owner and AAL2, no direct table access", () => {
  const handler = worker.split("async function ownerPaScoringWorkflow(")[1]
    ?.split("async function publishOwnerPaEvaluationFeedback(")[0] ?? "";
  expect(handler).toContain('requireActiveRole(auth.context, "owner")');
  expect(handler).toContain("requireAal2(auth.context)");
  for (const rpc of ["create_pa_scoring_draft", "review_pa_scoring_draft",
    "approve_private_pa_report_composition",
    "get_private_pa_scored_report_review_manifest", "publish_approved_pa_scored_report"]) {
    expect(handler).toContain(rpc);
  }
  expect(handler).toContain("marks.length !== 30");
  expect(handler).toContain("new Set(marks.map(mark => mark.code)).size !== 30");
  expect(handler).toContain("asRows(data)[0]");
  expect(handler).not.toContain("service_role");
  expect(handler).not.toContain("answer_key");
});

test("private Owner scoring rejects anonymous and authenticated learner callers", async ({ page, request }) => {
  const uuid = "00000000-0000-0000-0000-000000000123";
  const codes = ["RV01","RV02","RV03","RV04","RV05","RV06","RV07a","RV07b","RV08","RV09",
    ...["LC","AW","CW","SP"].flatMap(group => Array.from({ length: 5 }, (_, i) => group + "0" + (i+1)))];
  const testCases = [
    ["/api/v1/admin/pa-scoring/drafts", {
      report_version_id: uuid, rubric_approval_id: uuid,
      dimension_marks: codes.map(code => ({ code, points: 2 })),
    }],
    ["/api/v1/admin/pa-scoring/review", {
      scoring_draft_id: uuid, decision: "approved_private",
      review_note: "Synthetic review only; no real scores.",
    }],
    ["/api/v1/admin/pa-scoring/joint", {
      scoring_review_id: uuid, feedback_review_id: uuid,
      approval_note: "Synthetic joint approval request without a session.",
    }],
    ["/api/v1/admin/pa-scoring/publish", {
      composition_approval_id: uuid, idempotency_key: uuid,
    }],
  ] as const;
  for (const [path, body] of testCases) {
    const res = await request.post(path, { data: body });
    expect(res.status(), path).toBe(401);
  }
  const manifest = await request.get("/api/v1/admin/pa-scoring/manifest/" + uuid);
  expect(manifest.status()).toBe(401);

  let authorization = "";
  page.on("request", outgoing => {
    if (new URL(outgoing.url()).pathname === "/api/v1/me" && outgoing.method() === "GET") {
      authorization = outgoing.headers()["authorization"] ?? authorization;
    }
  });
  await page.goto("/account");
  await page.getByLabel("Email address").fill("student.a@example.invalid");
  await page.getByLabel("Password").fill(["Local-only","GradiPrep","2026!"].join("-"));
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Synthetic Student A", exact: true })).toBeVisible();
  await expect.poll(() => authorization.length).toBeGreaterThan(20);
  for (const [path, body] of testCases) {
    const denied = await request.post(path, { headers: { Authorization: authorization }, data: body });
    expect(denied.status(), path).toBe(403);
  }
  const privateManifest = await request.get("/api/v1/admin/pa-scoring/manifest/" + uuid,
    { headers: { Authorization: authorization } });
  expect(privateManifest.status()).toBe(403);
});
