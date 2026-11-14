import { expect, test } from "@playwright/test";
import { renderToStaticMarkup } from "react-dom/server";
import PaScoredResults, { approvedPaScoring, type PublishedPaSnapshot } from "../src/auth/PaScoredResults";

const codes = [
  "RV01", "RV02", "RV03", "RV04", "RV05", "RV06", "RV07a", "RV07b", "RV08", "RV09",
  ...["LC", "AW", "CW", "SP"].flatMap(group =>
    Array.from({ length: 5 }, (_, i) => group + "0" + (i + 1))),
];
const original: PublishedPaSnapshot = {
  published_feedback_snapshot: { status: "human_approved_published", feedback_text: "Reviewed teacher feedback." },
  eligible_analytics_snapshot: {
    pa_human_scoring: {
      status: "human_approved", dimension_count: 30,
      dimensions: codes.map(observation_code => ({
        observation_code, points_awarded: 2, points_possible: 4,
      })),
      points_awarded: 60, points_possible: 120, attainment_percent: 50,
    },
  },
};
const fixture = (): PublishedPaSnapshot => structuredClone(original);

test("only a complete, human-approved 30-dimension scored report can render results", () => {
  const score = approvedPaScoring(fixture());
  expect(score).not.toBeNull();
  const html = renderToStaticMarkup(<PaScoredResults score={score!} />);
  expect(html).toContain("Human-reviewed assessment results");
  expect(html).toContain("60 of 120 rubric points");
  expect(html).toContain("50% attainment");
  expect(html).toContain("Speaking and Presenting");
  expect(html).toContain("RV07a");
  expect(html).toContain("not an official IB grade");
  expect(html).not.toContain("composition_approval_id");
  expect(html).not.toContain("academic_review_reference");
});

test("unscored, draft-only, inaccurate, duplicated or partial scoring never renders", () => {
  const samples: PublishedPaSnapshot[] = [
    {},
    { ...fixture(), published_feedback_snapshot: { status: "draft", feedback_text: "Private draft" } },
    { ...fixture(), published_feedback_snapshot: { status: "human_approved_published", feedback_text: "" } },
  ];
  const wrongCount = fixture();
  wrongCount.eligible_analytics_snapshot!.pa_human_scoring!.dimensions!.pop();
  samples.push(wrongCount);
  const duplicate = fixture();
  duplicate.eligible_analytics_snapshot!.pa_human_scoring!.dimensions![1].observation_code = "RV01";
  samples.push(duplicate);
  const wrongSum = fixture();
  wrongSum.eligible_analytics_snapshot!.pa_human_scoring!.points_awarded = 90;
  samples.push(wrongSum);
  const wrongPercentage = fixture();
  wrongPercentage.eligible_analytics_snapshot!.pa_human_scoring!.attainment_percent = 80;
  samples.push(wrongPercentage);
  const invalidPoints = fixture();
  invalidPoints.eligible_analytics_snapshot!.pa_human_scoring!.dimensions![0].points_awarded = 9;
  samples.push(invalidPoints);
  const listening = fixture();
  listening.eligible_analytics_snapshot!.pa_human_scoring!.dimensions![0].observation_code = "L01";
  samples.push(listening);
  for (const sample of samples) expect(approvedPaScoring(sample)).toBeNull();
});
