import type { PilotUnitDraft } from "./model";

/**
 * Editorial planning record for the revised IB MYP Language and Literature
 * Year 1 Unit 1 v4 editorial-correction candidate. Official strand mapping remains unverified.
 */
export const pilotUnitDraft: PilotUnitDraft = {
  id: "draft-ib-myp-lal-y1-u1-v4",
  version: 4,
  pathwayId: "ib-myp-lal-y1",
  unitId: "ib-myp-lal-y1-u1",
  status: "founder-approved-candidate",
  reviewRecord: {
    outcome: "passed",
    reviewedAt: "2026-10-31",
    reviewerLabel: "Founder / project owner",
    scopeNote:
      "Version 4 was approved by the founder / project owner on 31 October 2026 after full human academic and age/level/context review. Approval applies to exact v4 only. Both registered passages, learner questions/prompts, response ranges and counter targets are preserved. Rights/territory, manual accessibility, official mapping and release remain separate gates.",
  },
  title: "How writers and creators shape meaning",
  proposedFocus: "Language, imagery, atmosphere and visual design choices.",
  proposedLearningObjective:
    "Explain how a writer's language choices and a visual creator's design choices may shape atmosphere and meaning, using precise evidence and the surrounding context.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  source: {
    title: "IB MYP Language and Literature public programme overview and dated subject brief; current detailed Year 1 guide edition not verified",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl: "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-31",
    scopeNote:
      "The public programme overview and linked subject brief were rechecked on 31 October 2026; the brief is labelled From 2014. These are broad programme references only and do not verify the applicable current detailed Year 1 guide edition, exact objective wording or strand mapping. Official objective codes remain blank.",
  },
  teachingSequence: [
    { number: "01", title: "Notice before interpreting", purpose: "Separate observable details from inferences in a literary description and a visual campaign." },
    { number: "02", title: "Build an evidence chain", purpose: "Link a precise choice to evidence and a contextual explanation." },
    { number: "03", title: "Compare creator choices", purpose: "Compare the atmosphere of Dickens's written setting with the poster's visual framing." },
    { number: "04", title: "Explain imagery in context", purpose: "Interpret personification and exaggeration without treating figurative language literally." },
    { number: "05", title: "Transfer independently", purpose: "Apply the same reasoning to a separate author and fantasy context in Carroll." },
  ],
  originalExample: {
    label: "Public-domain literary example — A Christmas Carol (1843)",
    text: "“the houses opposite were mere phantoms”",
    focus: "Comparison, visual imagery and atmosphere.",
    teachingNote:
      "Use the exact 1843 Chapman & Hall English text recorded as EXC-IB-MYP-Y1-U1-MAIN / SRC-IB-MYP-Y1-U1-001. Do not substitute a modern edition, adaptation or translation without a separate rights check.",
  },
  practicePrompt:
    "Explain how a precise language or design choice may shape atmosphere or meaning. Use evidence and connect your explanation to the moment or audience.",
  responseExpectation: [
    "Entry observation: 15–25 words.",
    "Practice Q2: 40–55 words.",
    "Practice Q3 comparison: 65–85 words.",
    "Practice Q4 imagery: 45–65 words.",
    "Practice Q5 revision: 45–65 words in two or three sentences.",
    "Independent transfer exit response: 45–60 words.",
    "The word ranges guide the learner and are not an automatic limit or grading rule.",
  ],
  commonMisconceptions: [
    "Naming a technique is not the same as explaining its effect.",
    "A possible reader response should not be presented as guaranteed for everyone.",
    "A visual detail should be described precisely before interpreting it.",
    "The word “phantoms” is figurative in this scene; the extract does not introduce actual ghosts.",
    "The Alice transfer must be analysed using its own evidence, not copied comments about Dickens's fog.",
  ],
  remainingReleaseChecks: [
    "Final unit-level rights/territory approval for the text excerpts and photo/poster asset.",
    "Official current IB Year 1 guide edition and objective/strand mapping remain unverified.",
    "Complete unit-level rights approval for the text excerpts and separate poster/photo asset review.",
    "Complete manual accessibility and responsive reflow review, including keyboard/focus, screen-reader order, contrast and zoom.",
    "Verify no teacher-only answer content enters the learner application bundle.",
    "Obtain explicit founder release approval after all separate gates pass.",
  ],
  rightsNote:
    "Candidate main excerpt: EXC-IB-MYP-Y1-U1-MAIN / SRC-IB-MYP-Y1-U1-001. Candidate transfer excerpt: EXC-IB-MYP-Y1-U1-TRANSFER / SRC-IB-MYP-Y1-U1-002. Original English texts from historical editions; source-level term checks for India and the United Kingdom recorded 30 October 2026; the United States and other territories are not cleared in this record. Final unit-level rights sign-off remains pending.",
  releaseNote:
    "Unreleased version 4 founder-approved content candidate. Founder / project owner review on 31 October 2026 covers the exact learner/teacher content and academic, age/level/context suitability. Official IB mapping remains unverified; final rights/territory, manual accessibility and release gates remain open.",
};
