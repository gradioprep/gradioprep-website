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
    { path: base + "/versions", method: "GET" },
    { path: base + "/readiness/" + zero, method: "GET" },
    { path: base + "/outcomes/" + zero, method: "GET" },
    { path: base + "/rubric", method: "POST",
      data: { diagnostic_version_id: zero, rubric_sha256: "a".repeat(64),
        dimension_maxima: codes.map(code=>({ code, max_points: 2 })), academic_review_reference: "Synthetic reference",
        assessor_calibration_reference: "Synthetic reference",
        approval_note: "Synthetic note for authorization test." } },
    { path: base + "/crosswalk", method: "POST",
      data: { diagnostic_version_id: zero,
        mappings: codes.map(code=>({ code,
          outcome_mapping_id: zero,
          rationale: "Synthetic-only placeholder; not approved real curriculum evidence." })) } },
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

test("restricted source files are fingerprinted in the Owner browser without uploading their bytes", () => {
  expect(evidence).toContain('crypto.subtle.digest("SHA-256", bytes)');
  expect(evidence).toContain('file.arrayBuffer()');
  expect(evidence).toContain('event.currentTarget.files?.[0]');
  expect(evidence).toContain('setHash(hash)');
  expect(evidence).toContain('Reviewed rubric');
  expect(evidence).toContain('Verified 30-row direct crosswalk');
  expect(evidence).toContain('Complete restricted teacher-pack bundle');
  expect(evidence).toContain('Witnessed calibration record');
  expect(evidence).toContain('!fingerprinting && allMapped');
  expect(evidence).toContain('!fingerprinting && uuid(version)');
  const fingerprint = evidence.split('async function fingerprintLocalFile(')[1]
    ?.split('export default function PaAcademicEvidencePanel(')[0] ?? '';
  expect(fingerprint).not.toContain('fetch(');
  expect(fingerprint).not.toContain('FormData');
  expect(fingerprint).not.toContain('localStorage');
});

test("verified 30-link direct mapping handoff is tightly scoped to Owner AAL2", () => {
  const handler=worker.split("async function ownerPaAcademicHandoff(")[1]
    ?.split("async function ownerPaScoringWorkflow(")[0] ?? "";
  expect(handler).toContain('"record_pa_verified_direct_crosswalk"');
  expect(handler).toContain('"crosswalk"');
  expect(handler).toContain('fields.mappings.length !== 30');
  expect(handler).toContain('requireActiveRole(auth.context, "owner")');
  expect(handler).toContain('requireAal2(auth.context)');
  expect(worker).toContain('"/api/v1/admin/pa-academic/crosswalk"');
  expect(evidence).toContain("Record 30 reviewed direct links");
  expect(evidence).toContain("parsedCrosswalk");
  expect(evidence).not.toContain("max_points: 4");
});

test("Owner mapping selector exposes only reviewed exact-route outcome references", () => {
  const sql=readFileSync("supabase/migrations/20261116000300_phase2_pa_verified_route_outcome_inventory.sql","utf8");
  expect(sql).toContain("private.current_user_has_role('owner'::public.app_role)");
  expect(sql).toContain("coalesce(auth.jwt()->>'aal','aal1') <> 'aal2'");
  expect(sql).toContain("unit.route_version_id=instrument.route_version_id");
  expect(sql).toContain("outcome.mapping_status='direct'");
  expect(sql).toContain("outcome.reviewed_by IS NOT NULL");
  expect(sql).toContain("unit.release_state='published'");
  expect(evidence).toContain("verifiedOutcomes.map(");
  expect(evidence).toContain("Prepare the 30 verified links for review");
  expect(evidence).toContain('"/api/v1/admin/pa-academic/outcomes/"+version');
  expect(worker).toContain('"/api/v1/admin/pa-academic/crosswalk"');
});

test("Owner selects actual PA versions with exact-route readiness, not manually typed IDs", () => {
  const sql=readFileSync("supabase/migrations/20261116000400_phase2_pa_owner_instrument_inventory.sql","utf8");
  expect(sql).toContain("private.current_user_has_role('owner'::public.app_role)");
  expect(sql).toContain("coalesce(auth.jwt()->>'aal','aal1') <> 'aal2'");
  expect(sql).toContain("dv.diagnostic_code='ib-myp-g9-cycle1'");
  expect(sql).toContain("m.mapping_status='direct'");
  expect(sql).toContain("om.mapping_status='direct'");
  expect(worker).toContain('"/api/v1/admin/pa-academic/versions"');
  expect(worker).toContain('"list_pa_academic_versions"');
  expect(evidence).toContain('aria-label="Exact PA instrument version"');
  expect(evidence).toContain("availableVersions.map(");
  expect(evidence).toContain('"/api/v1/admin/pa-academic/versions"');
});
