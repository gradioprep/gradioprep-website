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
    title: "IB MYP Language and literature — official subject page",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl:
      "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-24",
    scopeNote:
      "The public IB subject page and its subject brief describe the programme broadly but do not themselves provide Year 1 strand descriptors. The detailed guide source is still awaiting confirmation against the edition used by the intended school.",
  },
  candidateGuide: {
    title: "IB Language and literature guide — candidate Year 1 strands",
    url: "https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf",
    checkedAt: "2026-10-24",
    accessNote:
      "A search-indexed excerpt suggests Year 1 Criterion A strands A(ii) and A(iii), but the guide opens through IB curriculum sign-in. These references are candidates only until the applicable school-guide edition is verified.",
  },
  candidateObjectiveMappings: [
    {
      criterion: "A — Analysing",
      strand: "A(ii)",
      descriptor: "Identify and comment upon the creator's choices.",
      state: "candidate-unverified",
      rationale:
        "A plausible candidate reference for the reviewed focus; confirm the applicable guide edition before accepting it as a mapping.",
    },
    {
      criterion: "A — Analysing",
      strand: "A(iii)",
      descriptor: "Justify opinions and ideas using examples, explanations and terminology.",
      state: "candidate-unverified",
      rationale:
        "A plausible candidate reference for using evidence and explanations; confirm the applicable guide edition before accepting it as a mapping.",
    },
  ],
  remainingReleaseChecks: [
    "Confirm the applicable MYP Language and literature guide/edition used by the intended school.",
    "Verify whether candidate strands A(ii), A(iii), both or neither fit this unit, then record exact official references.",
    "Complete and record the separate content-rights review.",
    "Complete and record the accessibility review for the interactive lesson.",
    "Record explicit release approval only after all required evidence is complete.",
  ],
  releaseNote:
    "Academic content review passed for pilot preview version 1. Do not claim official curriculum mapping or release this as a syllabus-mapped course until the applicable guide edition/objective references and all remaining release gates are verified.",
};
