import { expect, test } from "@playwright/test";
import { paResponseSourceSummary } from "../src/auth/PaReportEvidenceSummary";

const codes = [
  "RV01", "RV02", "RV03", "RV04", "RV05", "RV06", "RV07a", "RV07b", "RV08", "RV09",
  ...["LC", "AW", "CW", "SP"].flatMap(group =>
    Array.from({ length: 5 }, (_, index) => group + "0" + (index + 1))),
];
const hash = "a".repeat(64);

test("thirty rubric observations correspond to eighteen independent response sources", () => {
  const observations = codes.map(observation_code => ({ observation_code }));
  const evidence = codes.map(observation_code => ({
    observation_code,
    source_response_observation_code: /^(AW|CW|SP)/.test(observation_code)
      ? observation_code.slice(0, 2) + "01" : observation_code,
    response_sha256: hash,
  }));
  expect(paResponseSourceSummary(observations, evidence)).toEqual({ recorded: 18, expected: 18 });
  evidence[17].response_sha256 = "missing";
  // One shared writing source is still present via the other rubric dimensions.
  expect(paResponseSourceSummary(observations, evidence)).toEqual({ recorded: 18, expected: 18 });
  for (const entry of evidence.filter(x => x.observation_code.startsWith("AW"))) {
    entry.response_sha256 = "missing";
  }
  expect(paResponseSourceSummary(observations, evidence)).toEqual({ recorded: 17, expected: 18 });
});

test("legacy fifteen-response fixture remains correctly counted", () => {
  const subset = codes.slice(0, 15).map(observation_code => ({ observation_code }));
  expect(paResponseSourceSummary(subset, subset.map(x => ({ ...x, response_sha256: hash }))))
    .toEqual({ recorded: 15, expected: 15 });
});

test("refuses unrelated, forged or Listening response source identities", () => {
  const observations = [{ observation_code: "AW01" }, { observation_code: "AW02" },
    { observation_code: "RV01" }, { observation_code: "L01" }];
  const evidence = [
    { observation_code: "AW01", source_response_observation_code: "LC01", response_sha256: hash },
    { observation_code: "AW02", source_response_observation_code: "AW01", response_sha256: hash },
    { observation_code: "RV01", source_response_observation_code: "L01", response_sha256: hash },
    { observation_code: "L01", source_response_observation_code: "L01", response_sha256: hash },
  ];
  expect(paResponseSourceSummary(observations, evidence)).toEqual({ recorded: 1, expected: 2 });
});
