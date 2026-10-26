import type { PilotReviewSummary } from "./model";

/**
 * Safe planning metadata for the Pathways screen.
 * This intentionally excludes worked explanations, model responses and answers.
 */
export const pilotReviewSummary: PilotReviewSummary = {
  id: "review-summary-ib-myp-lal-y1-u1-v1",
  unitId: "ib-myp-lal-y1-u1",
  title: "How writers shape meaning",
  proposedFocus:
    "A starter exploration of how deliberate word and sentence choices influence a reader's understanding and response.",
  proposedLearningObjective:
    "Identify a writer's choice in a short text and comment on how it may shape meaning or mood, using an example to support the explanation.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  reviewRecord: {
    outcome: "passed",
    reviewedAt: "2026-10-24",
    reviewerLabel: "Academic lead (approval confirmed by project owner; name not specified)",
    scopeNote:
      "Academic content review passed for this version per project owner confirmation. This approval supports the pilot preview only; the official curriculum mapping remains unverified and release is not authorised.",
  },
  source: {
    title: "IB MYP Language and Literature — public subject overview",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl:
      "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-26",
    scopeNote:
      "The current public IB overview describes the six MYP Language and Literature skill areas and broad programme aims, but it does not publish the detailed Year 1 objective/strand descriptors. This pilot is a public-framework-aligned learning design, not an officially mapped unit.",
  },
  remainingReleaseChecks: [
    "Confirm that the unit’s public-framework alignment is described accurately and no official objective codes are displayed.",
    "Keep exact official Year 1 objective/strand codes unmapped unless a current public source verifies the exact descriptors.",
    "Complete and record the separate content-rights review.",
    "Complete and record the accessibility review for the interactive lesson.",
    "Record explicit release approval only after all required evidence is complete.",
  ],
  releaseNote:
    "Academic content review passed for pilot preview version 1. The unit uses the broad publicly described MYP framework; exact official Year 1 objective mapping is not claimed. Rights review, accessibility review and explicit release approval remain outstanding.",
};
