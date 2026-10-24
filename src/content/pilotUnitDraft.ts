import type { PilotUnitDraft } from "./model";

/**
 * First pilot-unit content pack. This is an original working draft for academic
 * review, not an approved syllabus mapping and not linked to the demo lesson.
 */
export const pilotUnitDraft: PilotUnitDraft = {
  id: "draft-ib-myp-lal-y1-u1",
  version: 1,
  pathwayId: "ib-myp-lal-y1",
  unitId: "ib-myp-lal-y1-u1",
  status: "working-draft",
  title: "How writers shape meaning",
  proposedFocus:
    "A starter exploration of how deliberate word and sentence choices influence a reader's understanding and response.",
  proposedLearningObjective:
    "Explain how a writer's specific word or sentence choices shape meaning or mood, using precise evidence from a text.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  source: {
    title: "IB MYP Language and literature — official subject page",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    checkedAt: "2026-10-24",
    scopeNote:
      "This public page describes the subject broadly, including reading and viewing among six skill areas and study of literary and non-literary texts. It does not provide a Year 1 unit sequence or an edition-specific objective code. The curriculum mapping therefore remains unverified.",
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
  reviewQuestions: [
    "Is the focus appropriate for MYP Year 1 learners and their prior knowledge?",
    "Which exact current MYP Language and Literature objective/strand should this teach toward, if any?",
    "Does the proposed sequence belong in Unit 1, or should another skill come first?",
    "What accessible range of text types and language needs should the finished unit include?",
    "Which formative check and marking guidance should be approved before practice items are authored?",
  ],
  rightsNote:
    "The short example is original draft text. Replace or supplement it only with original material or material whose use is appropriately permitted and documented.",
  releaseNote:
    "Do not publish or describe this draft as officially mapped until the academic lead verifies the applicable guide/criteria, objective references, level fit and sequence.",
};
