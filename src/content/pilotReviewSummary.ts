import type { PilotReviewSummary } from "./model";

/**
 * Safe planning metadata for the Pathways screen.
 * Contains no answer keys, worked answers or correct-option identifiers.
 */
export const pilotReviewSummary: PilotReviewSummary = {
  id: "review-summary-ib-myp-lal-y1-u1-v2",
  unitId: "ib-myp-lal-y1-u1",
  version: 2,
  status: "founder-approved-candidate",
  title: "How writers and creators shape meaning",
  proposedFocus:
    "Use precise textual and visual evidence to explain how creator choices may shape meaning and invite audience responses.",
  proposedLearningObjective:
    "Explain how a writer's word choices and a visual creator's design choices may shape meaning or invite an audience response, using precise evidence and context.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  reviewRecord: {
    outcome: "pending",
    reviewedAt: null,
    reviewerLabel: "Academic review pending",
    scopeNote:
      "The founder approved the content of version 2 on 26 October 2026. This is not a separate academic-review pass: academic review, current official mapping, rights, accessibility, age/level suitability and release approval remain open.",
  },
  source: {
    title: "IB MYP Language and Literature — current public subject overview",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl:
      "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-26",
    scopeNote:
      "The current public IB overview supports broad subject aims and six connected skill areas. The indexed 2014/15 detailed guide is used only as a legacy reference; the latest applicable detailed edition and current Year 1 objective/strand mapping are not verified.",
  },
  remainingReleaseChecks: [
    "Complete the separate academic review of version 2; founder content approval is recorded but does not replace this review.",
    "Complete separate academic review for version 2.",
    "Keep current official Year 1 objective/strand mapping unverified until the applicable guide is confirmed.",
    "Complete and record content rights review for the original prose, original poster copy/layout and the CC0 photograph.",
    "Complete and record accessibility, age/level suitability and cultural/context review.",
    "Record explicit release approval only after the required evidence is complete.",
  ],
  releaseNote:
    "Founder-approved content candidate, version 2. Version 1's review outcome does not transfer. This is not an officially mapped or released unit; separate academic, rights, accessibility, suitability and release gates remain open. Answers are not graded or saved in the prototype.",
};
