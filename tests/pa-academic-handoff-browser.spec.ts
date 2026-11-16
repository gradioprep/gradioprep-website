import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
const worker = readFileSync("worker/index.ts", "utf8");
const workspace = readFileSync("src/auth/PaFeedbackWorkspacePanel.tsx", "utf8");
const evidence = readFileSync("src/auth/PaAcademicEvidencePanel.tsx", "utf8");
const zero = "00000000-0000-0000-0000-000000000000";
const codes = ["RV01","RV02","RV03","RV04","RV05","RV06","RV07a","RV07b","RV08","RV09",
  ...["LC","AW","CW","SP"].flatMap(group=>Array.from({ length:5 },(_,i)=>group+"0"+(i+1)))];

test("qualified Founder handoff reuses existing private rubric and academic receipt RPCs", () => {
  const handler = worker.split("async function ownerPaAcademicHandoff(")[1]
    ?.split("async function ownerPaScoringWorkflow(")[0] ?? "";
  expect(handler).toContain('requireActiveRole(auth.context, "owner")');
  expect(handler).toContain("requireAal2(auth.context)");
  expect(handler).toContain('"inspect_pa_academic_readiness"');
  expect(handler).toContain('"approve_pa_scoring_rubric"');
  expect(handler).toContain('"record_pa_release_evidence"');
  expect(handler).toContain("fields.dimension_maxima.length !== 30");
  expect(handler).toContain("new Set(");
  expect(handler).toContain("digest(fields[k])");
  expect(handler).not.toContain("service_role");
  expect(handler).not.toContain("answer_key");
  expect(worker).toContain('"/api/v1/admin/pa-academic/rubric"');
  expect(worker).toContain('"/api/v1/admin/pa-academic/evidence"');
  expect(workspace).toContain("owner && <PaAcademicEvidencePanel");
  expect(evidence).toContain("!allMapped");
  expect(evidence).toContain("!rubricReady");
  expect(evidence).toContain("!receiptReady");
  expect(evidence).not.toContain("max_points: 4");
  expect(evidence).not.toContain("autoGrade");
});

test("private academic handoff API denies anonymous and signed-in student", async ({ page, request }) => {
  const base = "/api/v1/admin/pa-academic";
  const operations = [
    { path: base + "/readiness/" + zero, method: "GET" },
    { path: base + "/rubric", method: "POST",
      data: { diagnostic_version_id: zero, rubric_sha256: "a".repeat(64),
        dimension_maxima: codes.map(code=>({ code, max_points: 2 })), academic_review_reference: "Synthetic reference",
        assessor_calibration_reference: "Synthetic reference",
        approval_note: "Synthetic note for authorization test." } },
    { path: base + "/evidence", method: "POST",
      data: { diagnostic_version_id: zero, rubric_approval_id: zero,
        route_source_reference: "Synthetic only, no actual Year 4 route",
        review_bundle_sha256: "a".repeat(64), direct_mapping_sha256: "b".repeat(64),
        restricted_teacher_packs_sha256: "c".repeat(64),
        calibration_evidence_sha256: "d".repeat(64),
        evidence_note: "Synthetic only, no calibration approval." } },
  ] as const;
  for (const op of operations) {
    const response = op.method === "GET"
      ? await request.get(op.path) : await request.post(op.path, { data: op.data });
    expect(response.status(), op.path).toBe(401);
  }
  let authorization = "";
  page.on("request", outgoing => {
    if (new URL(outgoing.url()).pathname === "/api/v1/me" && outgoing.method() === "GET")
      authorization = outgoing.headers()["authorization"] ?? authorization;
  });
  await page.goto("/account");
  await page.getByLabel("Email address").fill("student.a@example.invalid");
  await page.getByLabel("Password").fill(["Local-only","GradiPrep","2026!"].join("-"));
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Synthetic Student A", exact: true })).toBeVisible();
  await expect.poll(() => authorization.length).toBeGreaterThan(20);
  for (const op of operations) {
    const options = { headers: { Authorization: authorization } };
    const response = op.method === "GET"
      ? await request.get(op.path, options)
      : await request.post(op.path, { ...options, data: op.data });
    expect(response.status(), op.path).toBe(403);
  }
});
