import type { PilotLearnerLesson } from "./model";

/**
 * Learner-safe version 2 candidate for founder review.
 * Answer keys and model responses stay in pilotLessonPack.ts and are not
 * imported by the client UI. Interactions are temporary and are not graded.
 */
export const pilotLearnerLesson: PilotLearnerLesson = {
  id: "pilot-lesson-how-writers-shape-meaning-v2",
  version: 2,
  unitId: "ib-myp-lal-y1-u1",
  status: "draft-for-founder-review",
  reviewRecord: {
    outcome: "pending",
    reviewedAt: null,
    reviewerLabel: "Pending founder review",
    scopeNote:
      "Version 1 passed academic content review for pilot preview on 24 October 2026. This revised version 2 has not yet been reviewed or approved and does not inherit version 1's approval. It remains a public-framework-aligned draft, not an officially mapped or released unit.",
  },
  title: "How writers and creators shape meaning",
  estimatedMinutes: 30,
  audienceNote:
    "Proposed for beginning MYP Language and Literature learners. Age/level fit, accessibility and local school sequencing require review.",
  proposedLearningObjective:
    "Explain how a writer's word choices and a visual creator's design choices may shape meaning or invite an audience response, using precise evidence and context.",
  mappingStatus: "unverified",
  successCriteria: [
    "I can point to a precise word, phrase or visual design choice.",
    "I can explain what that choice may suggest instead of only naming a technique.",
    "I can connect my interpretation to the context and audience, using evidence and allowing for other reasonable readings.",
  ],
  passage: {
    label: "Original practice passage",
    text:
      "At the edge of the field, the last bus sighed, its headlights shrinking into the rain. Mara held her ticket beneath the shelter, smoothing its damp corners. Above her, the station clock clicked on. Across the road, the bakery's sign turned from OPEN to CLOSED. When the bus finally arrived, warm light spilled across the wet pavement. Mara took one step forward, then stopped.",
    rightsNote:
      "Original passage written for this platform. It is not taken from an IB paper, textbook or third-party lesson.",
  },
  companionArtifact: {
    label: "Fictional night-bus poster mock-up",
    kicker: "NORTHBANK NIGHT BUS",
    headline: "A LIGHT ON EVERY LAST JOURNEY",
    supportingText: "The late bus is still a way home.",
    footerText: "PLAN AHEAD · TRAVEL WITH CARE",
    visualDescription:
      "A real photograph shows an empty bus-stop platform at night. A bus-stop sign stands beside a dark road; orange streetlights illuminate the pavement and distant headlights approach. The original poster headline and supporting line are set around the photograph.",
    altText:
      "Photograph of an empty bus-stop platform at night. A bus-stop sign stands beside a dark road; orange streetlights illuminate the pavement and distant headlights approach.",
    rightsNote:
      "Photograph “Bus stop with platform during night.jpg” by Mateusz Konieczny, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Bus_stop_with_platform_during_night.jpg. The file page explicitly records the creator’s CC0 1.0 Universal Public Domain Dedication. The image shows no identifiable people or visible commercial branding. Source and licence were checked before selection on 26 October 2026. Retain this source record and recheck the file page if the asset changes.",
  },
  entryCheck: {
    prompt:
      "Before studying the model, choose one word from the passage or one detail in the poster that catches your attention. Describe what you can see or read without explaining its effect yet.",
    placeholder:
      "I notice the word/detail … It literally shows …",
    successIndicators: [
      "I have identified a precise detail I can point to.",
      "I have described it before explaining what it might suggest.",
    ],
  },
  keyIdea: {
    label: "The evidence chain",
    pattern: [
      "Choice — point to an exact word, phrase or visual feature.",
      "Evidence — identify what is actually written or shown.",
      "Effect in context — explain what it may suggest to this audience and why it matters here.",
    ],
    explanation:
      "Naming a technique is a starting point, not a full explanation. Use cautious language such as “may suggest”, connect your reading to this moment and consider who the creator is addressing. More than one interpretation can be reasonable when supported by evidence.",
  },
  sections: [
    {
      id: "observe",
      heading: "1. Notice before you interpret",
      purpose: "Separate a detail you can identify from an idea you infer.",
      explanation:
        "The passage says that the bus “sighed”; it does not directly tell us that the bus is sad. The verb gives the bus a human-like action, which may invite an association with tiredness or reluctance. In the poster, the headline and bright shelter are visible choices too.",
      learnerAction:
        "Record one literal observation from the passage and one from the poster. Keep each observation close to what is actually written or shown.",
    },
    {
      id: "evidence-chain",
      heading: "2. Build an evidence chain",
      purpose: "Connect the creator's choice to a reasoned explanation.",
      explanation:
        "Move from a precise choice, to what it may suggest, to why that matters in this moment. “The writer uses personification” names a technique but leaves the explanation unfinished.",
      learnerAction:
        "Complete this frame in your own words: “The word/feature ‘…’ may suggest … . Here, it makes the moment/message seem … because … .”",
      example: {
        label: "Short worked example",
        text: "“the last bus sighed”",
        explanation:
          "The verb “sighed” gives the bus a human-like action. It may make the departure feel weary or reluctant, which fits the rain and the bus moving away. This is a plausible reading, not the only possible one.",
      },
    },
    {
      id: "compare",
      heading: "3. Compare two creators' choices",
      purpose: "Notice how a story and a poster can frame a similar journey differently.",
      explanation:
        "The passage follows Mara's uncertainty: the bus “sighed”, the headlights shrink into rain and Mara stops before boarding. The poster presents a late bus as “a way home” and makes the shelter the brightest part of the scene. These choices can invite different responses without either one having a single guaranteed effect.",
      learnerAction:
        "Choose one precise word or detail from the passage and one from the poster. Explain how each shapes the impression of a late journey and identify the difference you notice.",
    },
    {
      id: "context",
      heading: "4. Explain the choice in context",
      purpose: "Connect a small detail to the wider moment and audience.",
      explanation:
        "“Warm light spilled across the wet pavement” may suggest welcome or comfort, while Mara's final hesitation complicates the moment. The surrounding sentences matter: don't explain a phrase as if it appeared alone.",
      learnerAction:
        "Write two or three sentences about “warm light spilled across the wet pavement”. Explain one plausible effect and use Mara's final action to develop or qualify your interpretation.",
    },
    {
      id: "transfer",
      heading: "5. Get ready to transfer the skill",
      purpose: "Use the same reasoning on a fresh text rather than memorising one answer.",
      explanation:
        "The final check uses a new micro-extract. You will need to choose your own evidence, make a plausible inference and explain why it fits that new moment.",
      learnerAction:
        "Before submitting your exit response, check that you have not copied an interpretation from the bus passage or poster. Your evidence should come from the fresh micro-extract.",
    },
  ],
  practiceItems: [
    {
      id: "pilot-v2-q1",
      type: "best-explanation",
      focus: "Interpreting a word choice",
      prompt:
        "Which explanation is best supported by the phrase “the last bus sighed”?",
      options: [
        { id: "A", text: "It proves that the bus has a mechanical problem." },
        { id: "B", text: "It may make the departure feel weary or reluctant." },
        { id: "C", text: "It tells us that Mara is physically exhausted." },
        { id: "D", text: "It means that every reader must feel sad." },
      ],
      successIndicators: [
        "Use the wording in the passage as evidence.",
        "Explain a plausible association rather than claiming certainty.",
      ],
    },
    {
      id: "pilot-v2-q2",
      type: "short-response",
      focus: "Explaining imagery",
      prompt:
        "Explain how “its headlights shrinking into the rain” may shape the impression of the bus leaving. Use the phrase in your answer.",
      successIndicators: [
        "Identify “shrinking into the rain”.",
        "Explain a plausible association such as distance or fading visibility.",
        "Connect the association to the departure or mood of this scene.",
      ],
    },
    {
      id: "pilot-v2-q3",
      type: "short-response",
      focus: "Comparing text and visual design",
      prompt:
        "Choose one precise detail from the passage and one from the poster. How could those choices invite different impressions of a late bus journey? Support both parts of your explanation with evidence.",
      successIndicators: [
        "Uses a specific word/phrase from the passage.",
        "Uses a specific written or visual feature from the poster.",
        "Explains a plausible difference in impression and links it to context or audience.",
      ],
    },
    {
      id: "pilot-v2-q4",
      type: "short-response",
      focus: "Interpreting a change in mood",
      prompt:
        "How might “warm light spilled across the wet pavement” shape the moment when the bus arrives? Explain one interpretation and consider Mara's final hesitation.",
      successIndicators: [
        "Selects a precise word or phrase.",
        "Explains the association it may create.",
        "Uses Mara's final action to support or qualify the interpretation.",
      ],
    },
    {
      id: "pilot-v2-q5",
      type: "response-revision",
      focus: "Improving a weak explanation",
      prompt:
        "Improve this weak response in two or three sentences: “The poster uses dark colours. It looks nice.”",
      successIndicators: [
        "Names a specific visual contrast or placement choice.",
        "Explains what the choice may suggest or draw the audience's attention towards.",
        "Connects the explanation to the poster's message about a late journey.",
      ],
    },
  ],
  exitTicket: {
    stimulus: {
      label: "Fresh micro-extract — original transfer text",
      text:
        "At sunrise, the empty platform shone silver. A single yellow scarf fluttered from the bench, pointing towards the open gate.",
      rightsNote:
        "Original transfer text written for this platform. Do not treat it as an official IB sample.",
    },
    prompt:
      "Choose a word or phrase from this new extract. In two or three sentences, explain what it may suggest and how it shapes the moment. Use precise evidence and connect your interpretation to the context.",
    successIndicators: [
      "Uses an exact word or phrase from the fresh extract.",
      "Explains a plausible association or effect, not just a technique name.",
      "Connects the explanation to the sunrise, empty platform, scarf or open gate.",
    ],
  },
  accessibilitySupports: [
    "All passage, poster copy and lesson text remain selectable text; the poster also has a written visual description.",
    "The evidence-chain prompts can be used before writing, but learners can also structure an explanation independently.",
    "Keep the task instructions visible while a learner drafts a response.",
    "Accept different interpretations when supported by evidence; don't require one emotional response.",
    "Review reading demand, keyboard access, screen-reader announcements and visual layout before formal release.",
    "An optional partner discussion can ask learners to repeat a partner's evidence before offering a different interpretation; this is an extension, not a scored task in this preview.",
  ],
  learnerNote:
    "This is revised draft version 2, awaiting founder review. Version 1 passed content review for pilot preview only; that approval does not automatically cover this revision. Responses exist only in this open preview and are not saved, graded or sent anywhere. Official Year 1 mapping, rights, accessibility and release approval remain open.",
};
