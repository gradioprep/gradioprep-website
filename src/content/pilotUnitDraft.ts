import type { PilotUnitDraft } from "./model";

/**
 * Unit 1 version 2 planning brief. This is a draft for founder review;
 * version 1's pilot-preview approval does not carry forward automatically.
 */
export const pilotUnitDraft: PilotUnitDraft = {
  id: "draft-ib-myp-lal-y1-u1-v2",
  version: 2,
  pathwayId: "ib-myp-lal-y1",
  unitId: "ib-myp-lal-y1-u1",
  status: "draft-for-founder-review",
  reviewRecord: {
    outcome: "pending",
    reviewedAt: null,
    reviewerLabel: "Pending founder review",
    scopeNote:
      "Version 1 passed academic content review for pilot preview on 24 October 2026. This revised version 2 needs its own review and approval. It does not inherit the previous version's approval.",
  },
  title: "How writers and creators shape meaning",
  proposedFocus:
    "Move from noticing to interpreting: use precise textual and visual evidence to explain how creator choices may shape meaning and audience response.",
  proposedLearningObjective:
    "Explain how a writer's word choices and a visual creator's design choices may shape meaning or invite an audience response, using precise evidence and context.",
  mappingStatus: "unverified",
  officialObjectiveCodes: [],
  source: {
    title: "IB MYP Language and Literature — current public subject overview",
    url: "https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/",
    subjectBriefUrl: "https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf",
    checkedAt: "2026-10-26",
    scopeNote:
      "The current public overview supports the broad skill areas and text/creator focus. The detailed Year 1 guide indexed for 2014/15 is a legacy reference, not proof of the latest applicable edition. Exact current objective/strand mapping remains unverified.",
  },
  teachingSequence: [
    { number: "01", title: "Notice before interpreting", purpose: "Begin with literal observations from an original prose passage and a photographic poster mock-up; distinguish observation from inference." },
    { number: "02", title: "Build an evidence chain", purpose: "Connect a precise word or visual choice to a plausible association and an effect in context." },
    { number: "03", title: "Compare creator choices", purpose: "Explain how a story and poster can frame a similar late-bus journey differently for an audience." },
    { number: "04", title: "Explain and qualify", purpose: "Use surrounding details to support, complicate or refine an interpretation instead of asserting one guaranteed response." },
    { number: "05", title: "Transfer independently", purpose: "Apply the same thinking to a fresh original micro-extract, then self-review using success indicators." },
  ],
  originalExample: {
    label: "Original micro-extract — from the lesson passage",
    text: "At the edge of the field, the last bus sighed, its headlights shrinking into the rain.",
    focus: "sighed",
    teachingNote:
      "The verb gives the bus a human-like action. It may make the departure feel weary or reluctant. The interpretation is plausible, not mandatory; the explanation should connect it to the rain and the bus moving away.",
  },
  practicePrompt:
    "Choose one precise word or phrase from the passage and one written or visual feature from the companion poster. Explain how those choices may invite different impressions of a late journey.",
  responseExpectation: [
    "Identifies exact wording or a specific visual design feature.",
    "Explains what the choice may suggest rather than only naming a technique.",
    "Connects the interpretation to the surrounding context and/or intended audience.",
    "Uses evidence from both artefacts when completing the comparison prompt.",
    "Applies the thinking move to a fresh text in the exit check.",
  ],
  commonMisconceptions: [
    "Naming a technique without explaining the effect.",
    "Treating an interpretation as fact or claiming all readers must feel the same way.",
    "Describing a visual choice without explaining its relationship to message, emphasis or audience.",
    "Quoting evidence but not explaining how it supports the point.",
    "Ignoring context or a later detail that complicates the first interpretation.",
  ],
  remainingReleaseChecks: [
    "Founder reviews and approves this exact version 2 before the curriculum rotation advances.",
    "Complete item-level academic review; version 1 approval does not carry forward.",
    "Keep official Year 1 objective/strand codes blank until the applicable current guide is verified.",
    "Record final asset provenance and complete the unit-level rights review for original prose, original poster copy/layout and the CC0 photograph; check the asset for third-party marks or other visible rights concerns.",
    "Complete and record accessibility, visual, reading-demand and age/level suitability checks.",
    "Record explicit release approval only after all required gates are complete.",
  ],
  rightsNote:
    "The prose and poster copy/layout are platform-authored. The poster uses “Bus stop with platform during night.jpg” by Mateusz Konieczny, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Bus_stop_with_platform_during_night.jpg. The file page records CC0 1.0 Universal Public Domain Dedication. The photo contains no identifiable people or visible commercial branding. Licence/source checked before selection on 26 October 2026; final unit-level rights review remains a separate release gate.",
  releaseNote:
    "Version 2 is a founder-review draft. Version 1 remains the previously reviewed pilot preview, but no approval automatically transfers to version 2. Official mapping, rights, accessibility and release approval are still open.",
};
