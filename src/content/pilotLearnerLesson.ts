import type { PilotLearnerLesson } from "./model";

/**
 * Learner-safe content for IB MYP Language and Literature Year 1 Unit 1.
 * Version 4 is founder-approved for content, academic quality and age/level suitability (31 October 2026); rights, manual accessibility and release remain separate gates. It contains no answer keys, model responses,
 * hidden rationales or teacher-only scoring guidance.
 */
export const pilotLearnerLesson: PilotLearnerLesson = {
  id: "pilot-lesson-how-writers-shape-meaning-v4",
  version: 4,
  unitId: "ib-myp-lal-y1-u1",
  status: "founder-approved-candidate",
  reviewRecord: {
    outcome: "passed",
    reviewedAt: "2026-10-31",
    reviewerLabel: "Founder / project owner",
    scopeNote:
      "Version 4 was approved by the founder / project owner on 31 October 2026 following review of the full learner and teacher/editor content, including both editorial corrections, questions, answers, models, feedback, age/level and contextual suitability. This approval is for the exact v4 content only and is not a release approval. Both registered passages, all learner questions/prompts, response ranges and counter targets remain unchanged. Official mapping remains unverified; unit-level rights/territory, manual accessibility and release decisions remain separate gates.",
  },
  title: "How writers and creators shape meaning",
  estimatedMinutes: 35,
  audienceNote:
    "Proposed for beginning MYP Language and Literature learners. Victorian vocabulary and sentence structure need the supplied word help and teacher-led chunking. Confirm age/level fit and school sequence during review.",
  proposedLearningObjective:
    "Explain how a writer's language choices and a visual creator's design choices may shape atmosphere and meaning, using precise evidence and the surrounding context.",
  mappingStatus: "unverified",
  successCriteria: [
    "Select a precise word, phrase or visible design detail.",
    "Explain a plausible association or effect instead of only naming a technique.",
    "Connect the interpretation to the moment and audience using evidence.",
    "Recognise that more than one interpretation can be reasonable when it is supported by the text or image.",
  ],
  passage: {
    excerptId: "EXC-IB-MYP-Y1-U1-MAIN",
    sourceId: "SRC-IB-MYP-Y1-U1-001",
    label: "Literary extract — A Christmas Carol by Charles Dickens",
    text: "The city clocks had only just gone three, but it was quite dark already: it had not been light all day: and candles were flaring in the windows of the neighbouring offices, like ruddy smears upon the palpable brown air. The fog came pouring in at every chink and keyhole, and was so dense without, that although the court was of the narrowest, the houses opposite were mere phantoms.\n\nTo see the dingy cloud come drooping down, obscuring everything, one might have thought that Nature lived hard by, and was brewing on a large scale.",
    rightsNote:
      "From Stave I, “Marley's Ghost”, in A Christmas Carol (London: Chapman & Hall, 1843). The original English text is reproduced from the 1843 edition without a modern translation or substantive adaptation. Source-level public-domain term checks are recorded for India and the United Kingdom only; the United States and other territories are not cleared. Final unit-level rights approval remains a separate gate.",
  },
  companionArtifact: {
    label: "Fictional night-bus campaign poster",
    kicker: "NORTHBANK NIGHT BUS",
    headline: "A LIGHT ON EVERY LAST JOURNEY",
    supportingText: "The late bus is still a way home.",
    footerText: "PLAN AHEAD · TRAVEL WITH CARE",
    visualDescription:
      "A photograph shows an empty, raised paved bus-stop platform beside a dark road at night. A tall bus-stop sign stands by the platform; orange streetlights illuminate the pavement and a nearby tree, while headlights approach along the road. The platform is open to the sky, with no shelter or people visible. The poster headline and supporting line are placed around the photograph.",
    altText:
      "An empty raised paved bus-stop platform at night beside a dark road. A tall bus-stop sign stands on the platform; orange streetlights illuminate the pavement and a nearby tree, while distant headlights approach. The platform is open to the sky; no shelter or people are visible.",
    rightsNote:
      "The photograph “Bus stop with platform during night.jpg” by Mateusz Konieczny is recorded on Wikimedia Commons under the CC0 1.0 Universal Public Domain Dedication. The file page and licence were rechecked on 30 October 2026. The poster wording and layout are original platform-authored material. The image and text remain subject to the separate asset and accessibility gates.",
  },
  vocabularySupport: [
    { term: "ruddy", meaning: "reddish in colour" },
    { term: "palpable", meaning: "so noticeable or thick that it almost seems touchable" },
    { term: "chink", meaning: "a small crack or opening" },
    { term: "phantoms", meaning: "ghost-like shapes that are difficult to see clearly" },
    { term: "dingy", meaning: "dull, dark or dirty-looking" },
    { term: "obscuring", meaning: "making something difficult to see" },
    { term: "brewing", meaning: "making or producing something; here, used figuratively" },
  ],
  entryCheck: {
    prompt:
      "Choose one word or phrase from the Dickens extract, or one visible detail from the poster. Describe exactly what you notice before explaining its effect.",
    placeholder: "I notice the phrase/detail … It literally shows …",
    expectedResponseLength: { minWords: 15, maxWords: 25, idealWords: 20 },
    successIndicators: [
      "Identifies a precise word, phrase or visible detail.",
      "Describes what is literally present before adding an interpretation.",
    ],
  },
  keyIdea: {
    label: "The evidence chain",
    pattern: [
      "Choice — identify the creator's language or design decision.",
      "Evidence — quote the exact wording or describe the specific visible detail.",
      "Effect in context — explain a plausible association and connect it to the moment or audience.",
    ],
    explanation:
      "Keep the choice, evidence and interpretation distinct. “Personification” names a choice; “Nature lived hard by” is evidence; the idea that the fog seems almost deliberately produced is an interpretation. A possible effect is not a guaranteed reaction for every reader or viewer.",
  },
  sections: [
    {
      id: "observe",
      heading: "1. Notice before you interpret",
      purpose: "Separate what can be observed from what can be inferred.",
      explanation:
        "The extract describes candles as “ruddy smears” and nearby houses as “mere phantoms”. The poster shows an empty platform, orange lighting and approaching headlights. Record these details first; do not assume that every reader will interpret them in the same way.",
      learnerAction:
        "Write one literal observation from the Dickens extract and one from the poster. Keep each close to the exact words or visible details.",
    },
    {
      id: "evidence-chain",
      heading: "2. Build an evidence chain",
      purpose: "Link a precise choice to an explanation supported by context.",
      explanation:
        "The phrase “mere phantoms” compares the houses to ghost-like shapes. This may suggest that the fog makes familiar buildings seem faint or uncertain. The nearby description of fog entering through “every chink and keyhole” supports that reading.",
      learnerAction:
        "Use all three parts: “The writer chooses to … . The evidence is ‘…’. This may suggest … because … .”",
      example: {
        label: "Worked example",
        text: "“the houses opposite were mere phantoms”",
        explanation:
          "The writer uses a comparison that makes the houses seem ghost-like (choice and evidence). This may suggest that the fog hides their familiar shapes, creating an uncertain or eerie atmosphere (possible effect in this setting).",
      },
    },
    {
      id: "compare",
      heading: "3. Compare two creators' choices",
      purpose: "Explain how a written description and a visual campaign may frame night-time streets differently.",
      explanation:
        "Dickens describes thick fog and buildings that are difficult to see. The poster places an empty, orange-lit platform and the words “A light on every last journey” against a dark street. The poster may appear reassuring, although the dark setting could also remind some viewers to take care when travelling.",
      learnerAction:
        "Choose one exact phrase from Dickens and one written or visual feature from the poster. Explain how each could shape an audience's impression of being out at night.",
    },
    {
      id: "context",
      heading: "4. Explain a choice in context",
      purpose: "Use the wider sentence and moment to develop an interpretation.",
      explanation:
        "Dickens imagines that “Nature lived hard by” and was “brewing” the fog. This makes the weather seem almost like something a neighbour is deliberately making. The exaggeration may feel playful, ominous or both; the surrounding darkness helps explain why.",
      learnerAction:
        "Explain what the image of Nature “brewing” may suggest. Use the wording and the surrounding description of the dark, foggy street.",
    },
    {
      id: "transfer",
      heading: "5. Transfer the thinking move",
      purpose: "Apply the same evidence chain to a new writer and a different kind of scene.",
      explanation:
        "The exit extract comes from Lewis Carroll's fantasy story, not Dickens's urban Christmas setting. Focus on the sudden change in the rabbit-hole and Alice's unusual fall. A copied explanation about fog will not fit this new context.",
      learnerAction:
        "Choose a word or phrase from the Alice extract. Explain how it shapes the moment of the fall and connect your interpretation to what Alice experiences.",
    },
  ],
  practiceItems: [
    {
      id: "pilot-v3-q1",
      type: "best-explanation",
      focus: "Interpreting imagery and atmosphere",
      prompt:
        "Which explanation is best supported by comparing the candles to “ruddy smears upon the palpable brown air”?",
      options: [
        { id: "A", text: "The candles appear as neat, sharply outlined points against clear air." },
        { id: "B", text: "The light seems blurred and spread through thick air, helping the reader imagine the foggy, obscured street." },
        { id: "C", text: "The phrase proves that the neighbouring offices are on fire." },
        { id: "D", text: "The image suggests that bright morning sunlight has cleared the fog." },
      ],
      successIndicators: [
        "Chooses the explanation that fits the comparison and the surrounding description.",
        "Checks that the interpretation does not add an event that the text never states.",
      ],
    },
    {
      id: "pilot-v3-q2",
      type: "short-response",
      focus: "Explaining a writer's description of fog",
      prompt:
        "Explain how the words “pouring in at every chink and keyhole” and “mere phantoms” shape the atmosphere of the street.",
      expectedResponseLength: { minWords: 40, maxWords: 55, idealWords: 50 },
      successIndicators: [
        "Uses at least one of the quoted phrases accurately.",
        "Explains a plausible association, such as the fog seeming to enter everywhere or the houses becoming hard to see.",
        "Connects the wording to the atmosphere of the street.",
      ],
    },
    {
      id: "pilot-v3-q3",
      type: "short-response",
      focus: "Comparing written and visual choices",
      prompt:
        "Compare how Dickens's description and the night-bus poster could shape an audience's impression of being out at night. Use one precise detail from each.",
      expectedResponseLength: { minWords: 65, maxWords: 85, idealWords: 75 },
      successIndicators: [
        "Uses an exact phrase from the Dickens extract.",
        "Uses a specific written or visual feature from the poster.",
        "Explains a similarity or difference in the impressions the choices may create.",
        "Recognises that the dark poster background may be read in more than one defensible way.",
      ],
    },
    {
      id: "pilot-v3-q4",
      type: "short-response",
      focus: "Interpreting personification and exaggeration",
      prompt:
        "What might Dickens suggest by imagining that Nature “lived hard by” and was “brewing” the fog? Explain how the image fits the scene.",
      expectedResponseLength: { minWords: 45, maxWords: 65, idealWords: 55 },
      successIndicators: [
        "Uses the words “lived hard by” or “brewing” as evidence.",
        "Explains the personification or exaggeration rather than treating the image literally.",
        "Connects the interpretation to the thick fog and darkness.",
      ],
    },
    {
      id: "pilot-v3-q5",
      type: "response-revision",
      focus: "Improving a vague explanation",
      prompt:
        "Improve this weak response in two or three sentences: “The fog is described. It makes the writing interesting.” Use one precise phrase from Dickens and explain its effect.",
      expectedResponseLength: { minWords: 45, maxWords: 65, idealWords: 55 },
      successIndicators: [
        "Replaces the vague comment with a specific phrase from the extract.",
        "Explains what the phrase may suggest or help the reader imagine.",
        "Links the interpretation to the street's atmosphere.",
      ],
    },
  ],
  exitTicket: {
    stimulus: {
      excerptId: "EXC-IB-MYP-Y1-U1-TRANSFER",
      sourceId: "SRC-IB-MYP-Y1-U1-002",
      label: "Independent transfer extract — Alice's Adventures in Wonderland by Lewis Carroll",
      text: "The rabbit-hole went straight on like a tunnel for some way, and then dipped suddenly down, so suddenly that Alice had not a moment to think about stopping herself before she found herself falling down what seemed to be a very deep well.\n\nEither the well was very deep, or she fell very slowly, for she had plenty of time as she went down to look about her, and to wonder what was going to happen next. First, she tried to look down and make out what she was coming to, but it was too dark to see anything: then she looked at the sides of the well, and noticed that they were filled with cupboards and book-shelves: here and there she saw maps and pictures hung upon pegs.",
      rightsNote:
        "From Chapter I, “Down the rabbit-hole”, in Alice's Adventures in Wonderland (London: Macmillan and Co., 1866). Original English text from the 1866 edition; no modern translation or illustration is reproduced. Source-level public-domain term checks are recorded for India and the United Kingdom only; the United States and other territories are not cleared. Final unit-level rights approval remains a separate gate.",
    },
    prompt:
      "Choose a word or phrase from this extract. Explain how Carroll makes the fall seem unusual or surprising, and connect your interpretation to what Alice experiences.",
    expectedResponseLength: { minWords: 45, maxWords: 60, idealWords: 50 },
    vocabularySupport: [
      { term: "dipped", meaning: "sloped or moved downward" },
      { term: "make out", meaning: "see or recognise clearly" },
      { term: "cupboards", meaning: "storage cabinets" },
      { term: "pegs", meaning: "small hooks or pins used for hanging things" },
    ],
    successIndicators: [
      "Quotes a precise word or phrase from the Alice extract.",
      "Explains a plausible effect, such as surprise, uncertainty, curiosity or comic strangeness.",
      "Connects the explanation to the sudden fall or Alice's unusual surroundings.",
    ],
  },
  accessibilitySupports: [
    "Both literary extracts remain selectable text and are paired with visible source information.",
    "The main extract includes short vocabulary explanations; teachers should chunk the longer Victorian sentences and pause at the semicolon.",
    "The transfer extract includes vocabulary support for less familiar words.",
    "The poster has a text description and meaningful alt text; meaning does not rely on colour alone.",
    "Question-specific response-length guidance appears before each typed response. The range is guidance, not an automatic word-count limit.",
    "Practice responses are temporary to this open preview; there is no grading, saving or submission.",
    "Review keyboard order, focus visibility, screen-reader order, zoom/reflow, visual contrast and mobile layout before release.",
  ],
  learnerNote:
    "Unit 1 version 4 is approved by the Founder / project owner for its exact content, human academic review and age/level/context suitability (31 October 2026). The unit is not released: official Year 1 mapping remains unverified, and unit-level rights/territory, manual accessibility and release approval remain open. Your responses are temporary and are not saved or graded.",
};
