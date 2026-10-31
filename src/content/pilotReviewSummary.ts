import type { PilotReviewSummary } from "./model";

/** Safe, learner-visible review metadata for the current Unit 1 candidate. */
export const pilotReviewSummary: PilotReviewSummary = {
  id: "review-summary-ib-myp-lal-y1-u1-v3",
  unitId: "ib-myp-lal-y1-u1",
  version: 3,
  status: "founder-approved-candidate",
  title: "How writers and creators shape meaning",
  proposedFocus: "Language, imagery, atmosphere and visual design choices.",
  proposedLearningObjective:
    "Explain how a writer's language choices and a visual creator's design choices may shape atmosphere and meaning, using precise evidence and the surrounding context.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  reviewRecord: {
    outcome: "pending",
    reviewedAt: null,
    reviewerLabel: "Founder content approval recorded 30 October 2026; fresh human academic review pending",
    scopeNote:
      "The founder approved this exact version 3 content candidate on 30 October 2026. Version 1 and version 2 approvals remain historical and do not transfer. This candidate remains unreleased; human academic review and separate mapping, rights, suitability, accessibility and release gates remain pending.",
  },
  source: {
    title: "IB MYP Language and Literature public programme overview and dated subject brief; current detailed Year 1 guide edition not verified",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl: "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-31",
    scopeNote:
      "Public programme context and the linked subject brief were rechecked on 31 October 2026; the brief is labelled From 2014. The applicable current detailed Year 1 guide and exact objective/strand mapping remain unverified. Official objective codes are intentionally blank.",
  },
  remainingReleaseChecks: [
    "Fresh human academic review of version 3, including all questions, distractor rationales, model responses and feedback.",
    "Verification of the exact current official Year 1 guide and any claimed objective/strand mapping.",
    "Separate final unit-level rights approval for text and visual assets.",
    "Age/level suitability and accessibility review.",
    "Explicit founder release approval.",
  ],
  releaseNote:
    "Version 3 is not released. Practice is temporary and ungraded. The teacher pack is separate from the learner-facing application. Official IB mapping, academic review, rights, accessibility, age/level suitability and release approval remain open.",
};
