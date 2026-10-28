import { expect, test } from "@playwright/test";
import { cbseGrade6Unit1LearnerLesson } from "../src/content/cbseGrade6Unit1LearnerLesson";

test("CBSE Grade 6 Unit 1 remains unreleased with partial source alignment and no official code", () => {
  expect(cbseGrade6Unit1LearnerLesson.releaseStatus).toBe("draft-unreleased");
  expect(cbseGrade6Unit1LearnerLesson.curriculum.mappingStatus).toBe("partial-source-alignment-code-unverified");
  expect(cbseGrade6Unit1LearnerLesson.curriculum.officialObjectiveCodes).toEqual([]);
  expect(cbseGrade6Unit1LearnerLesson.curriculum.reviewNote).toMatch(/no unit-specific official CBSE objective code/i);
  expect(cbseGrade6Unit1LearnerLesson.sourceContext.references).toContain(
    "https://ncert.nic.in/pdf/Bridge_Month_Program/Grade6/BMP_Grade-6-English%28R2%29.pdf",
  );
  expect(cbseGrade6Unit1LearnerLesson.visualAssets).toEqual([]);
  expect(cbseGrade6Unit1LearnerLesson.passage.rightsNote).toContain("Written for this platform");
  expect(cbseGrade6Unit1LearnerLesson.passage.text.length).toBeGreaterThan(600);
  expect(cbseGrade6Unit1LearnerLesson.tasks).toHaveLength(4);
  expect(cbseGrade6Unit1LearnerLesson.exitTask.responseType).toBe("text");

  const forbiddenKeyNames = /(?:correctanswer|answerkey|modelanswer|markingguide|markscheme)/i;
  const inspect = (value: unknown): void => {
    if (Array.isArray(value)) {
      for (const item of value) inspect(item);
      return;
    }
    if (value && typeof value === "object") {
      for (const [key, child] of Object.entries(value)) {
        expect(key, `Learner data must not contain teacher-only field "${key}"`).not.toMatch(forbiddenKeyNames);
        inspect(child);
      }
    }
  };
  inspect(cbseGrade6Unit1LearnerLesson);
});
