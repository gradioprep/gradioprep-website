import type { PilotUnitDraft } from "./model";

/**
 * Original pilot-unit brief. Academic content review passed for the pilot
 * preview; official curriculum mapping remains unverified.
 */
export const pilotUnitDraft: PilotUnitDraft = {
  id: "draft-ib-myp-lal-y1-u1",
  version: 1,
  pathwayId: "ib-myp-lal-y1",
  unitId: "ib-myp-lal-y1-u1",
  status: "approved-for-pilot-preview",
  reviewRecord: {
    outcome: "passed",
    reviewedAt: "2026-10-24",
    reviewerLabel: "Academic lead (approval confirmed by project owner; name not specified)",
    scopeNote: "Academic content review passed for this version per project owner confirmation. This approval supports the pilot preview only; the official curriculum mapping remains unverified and release is not authorised.",
  },
  title: "How writers shape meaning",
  proposedFocus:
    "A starter exploration of how deliberate word and sentence choices influence a reader's understanding and response.",
  proposedLearningObjective:
    "Identify a writer's choice in a short text and comment on how it may shape meaning or mood, using an example to support the explanation.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  source: {
    title: "IB MYP Language and Literature — public subject overview",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl: "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-26",
    scopeNote:
      "The current public IB overview describes broad programme aims and six skill domains but does not publish the detailed current Year 1 objective/strand descriptors. This unit is designed against the public framework, not an official objective-code mapping.",
  },
  teachingSequence: [
    {
      number: "01",
      title: "Notice a deliberate choice",
      purpose:
        "Identify a precise word, phrase or sentence pattern instead of naming a broad topic.",
    },
    {
      number: "02",
      title: "Select useful evidence",
      purpose:
        "Choose a short quotation that clearly shows the choice being discussed.",
    },
    {
      number: "03",
      title: "Explain the effect",
      purpose:
        "Explore what the choice may make a reader picture, notice, feel or question; avoid claiming every reader reacts identically.",
    },
    {
      number: "04",
      title: "Connect choice and meaning",
      purpose:
        "Link the evidence and explanation to the mood or meaning of the moment in the text.",
    },
  ],
  originalExample: {
    label: "Original micro-extract — written for this draft",
    text: "At the edge of the field, the last bus sighed, its headlights shrinking into the rain.",
    focus: "sighed",
    teachingNote:
      "The verb 'sighed' gives the bus a human-like action. It can make the departure feel weary or reluctant, while the shrinking headlights and rain help create a sense of distance. These are plausible readings to support with evidence, not the only acceptable interpretation.",
  },
  practicePrompt:
    "Choose one word or phrase from the micro-extract. Explain how it helps create the mood of the moment.",
  responseExpectation: [
    "Selects a precise word or phrase from the extract.",
    "Explains a plausible association or effect rather than only naming a technique.",
    "Connects the explanation to the mood or meaning and supports it with evidence.",
  ],
  commonMisconceptions: [
    "Naming a technique without explaining its effect.",
    "Writing a general comment about the scene without referring to specific words.",
    "Treating one interpretation as the only possible reading without supporting it.",
  ],
  remainingReleaseChecks: [
    "Confirm the unit is presented accurately as a public-framework-aligned pilot, not an officially mapped unit.",
    "Keep official objective/strand codes unmapped unless a current public source verifies exact descriptors.",
    "Complete and record the separate content-rights review.",
    "Complete and record the accessibility review for the interactive lesson.",
    "Record explicit release approval only after all required evidence is complete.",
  ],
  rightsNote:
    "The short example is original draft text. Replace or supplement it only with original material or material whose use is appropriately permitted and documented.",
  releaseNote:
    "Approved for pilot preview only. Do not claim official curriculum mapping or release this as a syllabus-mapped course until the applicable guide edition/objective references and all remaining release gates are verified.",
};
