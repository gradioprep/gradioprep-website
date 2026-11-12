import { expect, test } from "@playwright/test";
import { readFile } from "node:fs/promises";

test("staff speaking observation is private, live-witnessed, unscored and separately recorded", async () => {
  const ui=await readFile(new URL("../src/auth/PaFeedbackWorkspacePanel.tsx",import.meta.url),"utf8");
  const worker=await readFile(new URL("../worker/index.ts",import.meta.url),"utf8");
  expect(ui).toContain("I personally witnessed the live presentation");
  expect(ui).toContain("witnessedLive");
  expect(ui).toContain('"/spoken-evidence"');
  expect(ui).not.toContain("automatedSpeakingScore");
  expect(worker).toContain("async function staffPaSpokenEvidence");
  expect(worker).toContain('requireAnyActiveRole(auth.context, ["owner", "grader"])');
  expect(worker).toContain('p_observed_live: true');
  expect(worker).toContain("CW01|SP01");
});
