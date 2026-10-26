import type { PilotReviewSummary } from "./model";

/**
 * Safe planning metadata for the Pathways screen.
 * Contains no answer keys, worked answers or correct-option identifiers.
 */
export const pilotReviewSummary: PilotReviewSummary = {
  id: "review-summary-ib-myp-lal-y1-u1-v2",
  unitId: "ib-myp-lal-y1-u1",
  version: 2,
  status: "draft-for-founder-review",
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
    reviewerLabel: "Pending founder review",
    scopeNote:
      "Version 1 passed academic content review for pilot preview on 24 October 2026. Version 2 is a material revision and is awaiting founder review; its academic review has not yet passed.",
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
    "Founder review and approval of Unit 1 version 2.",
    "Complete separate academic review for version 2.",
    "Keep current official Year 1 objective/strand mapping unverified until the applicable guide is confirmed.",
    "Complete and record content rights review for the prose and the HTML/CSS poster design.",
    "Complete and record accessibility, age/level suitability and cultural/context review.",
    "Record explicit release approval only after the required evidence is complete.",
  ],
  releaseNote:
    "Draft version 2 for founder review. Version 1's pilot-preview approval does not transfer to this revision. This is not an officially mapped or released unit; answers are not graded or saved in the prototype.",
};
