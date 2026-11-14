import { expect, test } from "@playwright/test";

const codes = [
  "RV01", "RV02", "RV03", "RV04", "RV05", "RV06", "RV07a", "RV07b", "RV08", "RV09",
  ...["LC", "AW", "CW", "SP"].flatMap(group =>
    Array.from({ length: 5 }, (_, i) => group + "0" + (i + 1))),
];
const reportId = "1d000000-0000-4000-8000-000000000401";
const sourceHash = "a".repeat(64);
const versionedReport = (version: number) => ({
  report_record_id: reportId,
  report_version_id: version === 2
    ? "1d000000-0000-4000-8000-000000000402"
    : "1d000000-0000-4000-8000-000000000403",
  report_scope: "pa_baseline", version_number: version,
  curriculum_mapping_status: version === 2 ? "complete_direct" : "contains_unmapped",
  evidence_sufficiency_status: version === 2 ? "sufficient" : "insufficient",
  scope_snapshot: { awarding_body: "IB", programme_code: "MYP",
    subject_code: "Language and Literature", level_code: "Year 4",
    report_scoring_state: "unscored_baseline" },
  content_snapshot: { diagnostic_title: "Preliminary Assessment",
    sitting_count: 2, total_minutes: 80,
    observations: codes.map(observation_code => ({
      observation_code, group_code: observation_code.slice(0, 2),
    })) },
  curriculum_mapping_snapshot: codes.map(observation_code => ({
    observation_code, mapping_status: version === 2 ? "direct" : "pending_review",
    direct_outcomes: version === 2 ? [{ outcome_reference: "A.i" }] : [],
  })),
  learner_evidence_snapshot: codes.map(observation_code => ({
    observation_code,
    source_response_observation_code: /^(AW|CW|SP)/.test(observation_code)
      ? observation_code.slice(0, 2) + "01" : observation_code,
    response_sha256: version === 2 ? sourceHash : null,
  })),
  published_feedback_snapshot: version === 2
    ? { status: "human_approved_published", feedback_text: "Synthetic reviewed feedback." } : {},
  eligible_analytics_snapshot: version === 2 ? { pa_human_scoring: {
    status: "human_approved", dimension_count: 30,
    dimensions: codes.map(observation_code => ({
      observation_code, points_awarded: 2, points_possible: 4,
    })),
    points_awarded: 60, points_possible: 120, attainment_percent: 50,
  } } : {},
  created_at: "2026-11-14T00:00:00Z",
});

test("signed-in learner sees only synthetic published scores and version-specific evidence", async ({ page }) => {
  await page.goto("/account");
  await page.getByLabel("Email address").fill("student.a@example.invalid");
  await page.getByLabel("Password").fill(["Local-only", "GradiPrep", "2026!"].join("-"));
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Synthetic Student A", exact: true })).toBeVisible();

  await page.route("**/api/v1/learner/evaluation-reports/" + reportId + "*", async route => {
    const version = new URL(route.request().url()).searchParams.get("version") === "1" ? 1 : 2;
    await route.fulfill({ status: 200, contentType: "application/json",
      body: JSON.stringify({ report: versionedReport(version) }) });
  });
  await page.evaluate(id => {
    window.localStorage.setItem(
      "gradioprep.evaluation-report.record:11111111-1111-4111-8111-111111111111", id);
  }, reportId);
  await page.goto("/assessment");
  await expect(page.getByRole("heading", { name: "Human-reviewed assessment results" })).toBeVisible();
  await expect(page.getByText("60 of 120 rubric points", { exact: true })).toBeVisible();
  await expect(page.getByText("18 / 18", { exact: false })).toBeVisible();
  await expect(page.getByText("Synthetic reviewed feedback.")).toBeVisible();
  await expect(page.getByText("official IB grade", { exact: false }).first()).toBeVisible();
  await expect(page.getByText("assessor_calibration_reference")).toHaveCount(0);

  await page.getByRole("button", { name: "Previous version" }).click();
  await expect(page.getByText("Viewing version 1 · Earlier version")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Not scored" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Human-reviewed assessment results" })).toHaveCount(0);
  await expect(page.getByText("Synthetic reviewed feedback.")).toHaveCount(0);

  await page.getByRole("button", { name: "Check latest report" }).click();
  await expect(page.getByText("Viewing version 2 · Latest")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Human-reviewed assessment results" })).toBeVisible();
});
