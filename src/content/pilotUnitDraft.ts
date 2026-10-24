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
    "Identify a writer's choice in a short text and comment on how it may shape meaning or mood, using an example to support the explanation.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  source: {
    title: "IB MYP Language and literature — official subject page",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl: "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-24",
    scopeNote:
      "The public IB subject page and its subject brief describe the programme broadly and confirm the four assessment criteria, but do not themselves provide Year 1 strand descriptors. The more detailed candidate references below come from an IB-hosted guide result indexed as the 2014 Language and literature guide. Its applicability to the current guide used by the learner's school must be verified before mapping can be approved.",
  },
  candidateGuide: {
    title: "IB Language and literature guide — Year 1 objective strands",
    url: "https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf",
    checkedAt: "2026-10-24",
    accessNote:
      "The IB-hosted search-indexed guide excerpt lists Year 1 Criterion A strands, but opening the guide URL redirects to IB curriculum sign-in. Treat these as candidate references only and confirm against the current guide available to the school.",
  },
  candidateObjectiveMappings: [
    {
      criterion: "A — Analysing",
      strand: "A(ii)",
      descriptor: "Identify and comment upon the creator's choices.",
      state: "candidate-unverified",
      rationale:
        "Closest candidate for noticing and commenting on a deliberate word or sentence choice. The current guide edition and the unit-level fit still need confirmation.",
    },
    {
      criterion: "A — Analysing",
      strand: "A(iii)",
      descriptor: "Justify opinions and ideas using examples, explanations and terminology.",
      state: "candidate-unverified",
      rationale:
        "Candidate support for requiring a precise example and an explanation. Confirm whether this strand should be included in the first unit.",
    },
  ],
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
  modelResponse: {
    label: "Worked response — original draft",
    response:
      "The verb 'sighed' gives the bus a human action, which can make its departure seem weary or reluctant. The phrase 'headlights shrinking into the rain' suggests the bus is moving farther away, creating a quiet, wistful mood.",
    annotations: [
      {
        title: "Choice",
        detail: "Names the precise word 'sighed' rather than only naming a technique.",
      },
      {
        title: "Explanation",
        detail: "Explains a plausible association: the bus seems weary or reluctant.",
      },
      {
        title: "Supporting evidence",
        detail: "Connects a second phrase to distance and mood.",
      },
    ],
    reviewNote:
      "This is one plausible interpretation, not a single official answer. Review for level suitability and accept other evidence-supported interpretations.",
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
    "Does the learner's school use the guide represented by the candidate source, or a later applicable guide?",
    "Should candidate strands A(ii) and A(iii) both be used, or is one strand a better fit?",
    "Does the proposed sequence belong in Unit 1, or should another skill come first?",
    "What accessible range of text types and language needs should the finished unit include?",
    "Which formative check and marking guidance should be approved before practice items are authored?",
  ],
  rightsNote:
    "The short example is original draft text. Replace or supplement it only with original material or material whose use is appropriately permitted and documented.",
  releaseNote:
    "Do not publish or describe this draft as officially mapped until the academic lead verifies the applicable guide/criteria, objective references, level fit and sequence.",
};
