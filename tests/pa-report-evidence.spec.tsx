import { expect, test } from "@playwright/test";
import { renderToStaticMarkup } from "react-dom/server";
import PaReportEvidenceReview, { paEvidenceRows, type PaReportEvidenceSnapshot } from "../src/auth/PaReportEvidenceReview";

const sha = "a".repeat(64);
const fixture: PaReportEvidenceSnapshot = {
  curriculum_mapping_status: "contains_unmapped",
  evidence_sufficiency_status: "insufficient",
  content_snapshot: { observations: [
    { observation_code: "RV01", group_code: "RV", sitting_number: 1 },
    { observation_code: "RV02", group_code: "RV", sitting_number: 1 },
    { observation_code: "AW01", group_code: "AW", sitting_number: 2 },
  ] },
  learner_evidence_snapshot: [
    { observation_code: "RV01", response_sha256: sha },
    { observation_code: "RV02", response_sha256: "not-a-hash" },
    { observation_code: "AW01", response_sha256: null },
  ],
  curriculum_mapping_snapshot: [
    { observation_code: "RV01", mapping_status: "direct", direct_outcomes: [
      { outcome_reference: "A.i", outcome_title: "Synthetic criterion", source_locator: "Fixture page 1" },
    ] },
    { observation_code: "RV02", mapping_status: "pending_review", direct_outcomes: [
      { outcome_reference: "A.ii", outcome_title: "Not actually verified" },
    ] },
    { observation_code: "AW01", mapping_status: "unmapped", direct_outcomes: [] },
  ],
};

test("staff evidence review reports only saved responses and verified direct links", () => {
  const rows = paEvidenceRows(fixture);
  expect(rows).toHaveLength(3);
  expect(rows.map(item => [item.code, item.saved, item.mapped])).toEqual([
    ["RV01", true, true],
    ["RV02", false, false],
    ["AW01", false, false],
  ]);
  const html = renderToStaticMarkup(<PaReportEvidenceReview report={fixture} />);
  expect(html).toContain("3 observations · 1/3 responses recorded · 1/3 verified direct curriculum links");
  expect(html).toContain("Review cannot be completed from these records yet");
  expect(html).toContain("Fixture page 1");
  expect(html).not.toContain("Not actually verified");
  expect(html).toContain("RV · 1/2 responses · 1/2 curriculum links");
  expect(html).toContain("AW · 0/1 responses · 0/1 curriculum links");
});

test("staff evidence review never equates complete snapshot checks to a grade or approval", () => {
  const complete: PaReportEvidenceSnapshot = {
    curriculum_mapping_status: "complete_direct",
    evidence_sufficiency_status: "sufficient",
    content_snapshot: { observations: [{ observation_code: "CW01", group_code: "CW" }] },
    learner_evidence_snapshot: [{ observation_code: "CW01", response_sha256: sha }],
    curriculum_mapping_snapshot: [{ observation_code: "CW01", mapping_status: "direct",
      direct_outcomes: [{ outcome_reference: "C.i", outcome_title: "<script>alert(1)</script>" }] }],
  };
  const html = renderToStaticMarkup(<PaReportEvidenceReview report={complete} />);
  expect(html).toContain("Human academic review is still required");
  expect(html).toContain("does not calculate a grade");
  expect(html).toContain("&lt;script&gt;");
  expect(html).not.toContain("<script>");
});

test("apparently complete but inconsistent report snapshots are flagged for staff review", () => {
  const report: PaReportEvidenceSnapshot = {
    curriculum_mapping_status: "complete_direct",
    evidence_sufficiency_status: "sufficient",
    content_snapshot: { observations: [
      { observation_code: "RV01", group_code: "RV" },
      { observation_code: "RV01", group_code: "RV" },
    ] },
    learner_evidence_snapshot: [
      { observation_code: "RV01", response_sha256: sha },
      { observation_code: "RV01", response_sha256: sha },
      { observation_code: "L01", response_sha256: sha },
    ],
    curriculum_mapping_snapshot: [
      { observation_code: "RV01", mapping_status: "direct", direct_outcomes: [{ outcome_reference: "A.i" }] },
      { observation_code: "RV01", mapping_status: "direct", direct_outcomes: [{ outcome_reference: "A.i" }] },
      { observation_code: "L01", mapping_status: "direct", direct_outcomes: [{ outcome_reference: "A.i" }] },
    ],
  };
  const html = renderToStaticMarkup(<PaReportEvidenceReview report={report} />);
  for (const warning of [
    "Repeated observation code: RV01",
    "Response outside this report instrument: L01",
    "Curriculum link outside this report instrument: L01",
    "Conflicting response entries: RV01",
    "Conflicting curriculum entries: RV01",
  ]) expect(html).toContain(warning);
  expect(html).toContain("Report record inconsistencies require staff review");
  expect(html).not.toContain("Saved evidence and curriculum connections meet");
});
