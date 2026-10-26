import type { PilotLessonPack } from "./model";

/**
 * Teacher/editor source for Unit 1 candidate version 2.
 * Contains answer keys and model responses and MUST NOT be imported by the
 * client application. It is awaiting founder review; version 1's review does
 * not automatically transfer to this revision.
 */
export const pilotLessonPack: PilotLessonPack = {
  id: "draft-lesson-how-writers-shape-meaning-v2",
  version: 2,
  unitId: "ib-myp-lal-y1-u1",
  status: "draft-for-founder-review",
  reviewRecord: {
    outcome: "pending",
    reviewedAt: null,
    reviewerLabel: "Pending founder review",
    scopeNote:
      "This is revised version 2 for founder review. Version 1 passed academic content review for pilot preview on 24 October 2026, but version 2 has not yet been reviewed or approved. Official Year 1 mapping, rights review, accessibility review and release approval remain separate gates.",
  },
  title: "How writers and creators shape meaning",
  audienceNote:
    "Proposed for beginning MYP Language and Literature learners. Confirm reading demand, age/level fit and local school sequence during founder review.",
  estimatedMinutes: 30,
  proposedLearningObjective:
    "Explain how a writer's word choices and a visual creator's design choices may shape meaning or invite an audience response, using precise evidence and context.",
  mappingStatus: "unverified",
  successCriteria: [
    "Select a precise word, phrase or visual design choice.",
    "Explain a plausible association or effect instead of only naming a technique.",
    "Connect the interpretation to context/audience using evidence, while accepting more than one reasonable reading.",
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
      "A real photograph shows several people waiting at an illuminated bus stop on a rainy night. The shelter and waiting figures stand out against a dark urban street while city lights reflect from wet pavement. The original poster headline and supporting line are set around the photograph.",
    altText:
      "Photograph of an empty bus-stop platform at night. A bus-stop sign stands beside a dark road; orange streetlights illuminate the pavement and distant headlights approach.",
    rightsNote:
      "Photograph “Bus stop with platform during night.jpg” by Mateusz Konieczny, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Bus_stop_with_platform_during_night.jpg. The file page explicitly records the creator’s CC0 1.0 Universal Public Domain Dedication. The image shows no identifiable people or visible commercial branding. Source and licence were checked before selection on 26 October 2026. Retain this source record and recheck the file page if the asset changes.",
  },
  entryCheck: {
    prompt:
      "Before studying the model, choose one word from the passage or one detail in the poster that catches your attention. Describe what you can see or read without explaining its effect yet.",
    placeholder: "I notice the word/detail … It literally shows …",
    successIndicators: [
      "The learner identifies a precise detail.",
      "The learner gives an observation before adding an inference.",
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
      "Technique-spotting is not a complete analysis. Ask what the selected choice may suggest, how the evidence supports the interpretation and why it matters in this context. Do not present a possible effect as a guaranteed audience reaction.",
  },
  sections: [
    {
      id: "observe",
      heading: "1. Notice before you interpret",
      purpose: "Separate an observable detail from an inferred idea.",
      explanation:
        "The passage says the bus “sighed”; it does not literally say that it is sad. The verb attributes a human-like action to the bus. The poster's headline, placement and contrast are choices that can also be described before interpreting them.",
      learnerAction:
        "Record one literal observation from the passage and one from the poster. Keep each observation close to the words or design details actually present.",
    },
    {
      id: "evidence-chain",
      heading: "2. Build an evidence chain",
      purpose: "Link a specific choice to a contextual explanation.",
      explanation:
        "Move from the exact choice to a plausible association, then to why that association matters in this moment. “The writer uses personification” names a technique but does not explain the effect.",
      learnerAction:
        "Complete this frame: “The word/feature ‘…’ may suggest … . Here, it makes the moment/message seem … because … .”",
      example: {
        label: "Worked example",
        text: "“the last bus sighed”",
        explanation:
          "The verb “sighed” gives the bus a human-like action. It may make the departure feel weary or reluctant, fitting the rain and the bus moving away. This is plausible, not the only acceptable reading.",
      },
    },
    {
      id: "compare",
      heading: "3. Compare two creators' choices",
      purpose: "Explain how text and visual design may frame a similar journey differently.",
      explanation:
        "The story follows Mara's uncertainty: the bus “sighed”, the headlights shrink into rain and Mara stops before boarding. The poster frames a late bus as “a way home” and makes the shelter the brightest part of the scene. Both can be read in more than one way, but evidence supports a contrast between uncertainty and reassurance.",
      learnerAction:
        "Choose a precise word/phrase from the passage and a written or visual feature from the poster. Explain how each can shape the audience's impression of a late journey.",
    },
    {
      id: "context",
      heading: "4. Explain the choice in context",
      purpose: "Use surrounding detail to develop or qualify an interpretation.",
      explanation:
        "“Warm light spilled across the wet pavement” may suggest welcome or comfort, but Mara's final hesitation complicates the moment. A strong explanation uses the wider scene rather than treating a phrase as if it were isolated.",
      learnerAction:
        "Write two or three sentences about “warm light spilled across the wet pavement”. Explain one plausible effect and use Mara's final action to develop or qualify your interpretation.",
    },
    {
      id: "transfer",
      heading: "5. Transfer the move",
      purpose: "Apply the same thinking to a fresh text.",
      explanation:
        "The exit uses a new micro-extract, so the learner must select new evidence. Don't reward a copied explanation that fits the bus passage but not the new context.",
      learnerAction:
        "Use a word or phrase from the fresh micro-extract in your exit response and connect its effect to the moment described.",
    },
  ],
  practiceItems: [
    {
      id: "pilot-v2-q1",
      type: "best-explanation",
      focus: "Interpreting a word choice",
      prompt: "Which explanation is best supported by the phrase “the last bus sighed”?",
      options: [
        { id: "A", text: "It proves that the bus has a mechanical problem.", feedback: "The text gives no evidence of a mechanical fault. Consider the human association created by the verb." },
        { id: "B", text: "It may make the departure feel weary or reluctant.", feedback: "This is plausible: “sighed” gives the bus a human-like action and can suggest tiredness or reluctance in this context." },
        { id: "C", text: "It tells us that Mara is physically exhausted.", feedback: "The phrase describes the bus, not Mara. Do not transfer the action directly to her." },
        { id: "D", text: "It means that every reader must feel sad.", feedback: "A creator can invite a response but cannot guarantee that all readers respond identically." },
      ],
      bestOptionId: "B",
      modelAnswer: "B — “sighed” gives the bus a human-like action and may make its departure feel weary or reluctant.",
      successIndicators: ["Uses the wording as evidence.", "Explains a plausible association rather than claiming certainty."],
      feedbackForLearner: {
        ifStrong: "You connected the verb to a plausible effect and stayed close to the evidence.",
        nextStep: "Check that your explanation is supported by the actual words and does not claim more than the passage shows.",
      },
    },
    {
      id: "pilot-v2-q2",
      type: "short-response",
      focus: "Explaining imagery",
      prompt: "Explain how “its headlights shrinking into the rain” may shape the impression of the bus leaving. Use the phrase in your answer.",
      modelAnswer: "“Shrinking into the rain” makes the headlights seem smaller and less distinct as the bus moves away. This can emphasise distance and make the departure feel uncertain or final.",
      successIndicators: [
        "Identifies “shrinking into the rain”.",
        "Explains a plausible association such as distance or fading visibility.",
        "Connects the association to the departure or mood of this scene.",
      ],
      feedbackForLearner: {
        ifStrong: "Your explanation connects the image with what is happening in the scene.",
        nextStep: "Add a precise phrase and explain what it suggests; don't stop after naming a technique.",
      },
    },
    {
      id: "pilot-v2-q3",
      type: "short-response",
      focus: "Comparing text and visual design",
      prompt: "Choose one precise detail from the passage and one from the poster. How could those choices invite different impressions of a late bus journey? Support both parts with evidence.",
      modelAnswer: "The phrase “headlights shrinking into the rain” can make the bus seem to move away into distance and uncertainty. By contrast, the poster's headline “A light on every last journey” and the bright amber shelter against the dark street can present the late bus as reassuring and available. The contrast depends on the selected details and is not a guaranteed response for every audience.",
      successIndicators: [
        "Uses a specific word or phrase from the passage.",
        "Uses a specific written or visual feature from the poster.",
        "Explains a plausible difference in impression and links it to context or audience.",
      ],
      feedbackForLearner: {
        ifStrong: "You compared choices from both artefacts instead of listing unrelated observations.",
        nextStep: "Explain how each specific choice supports the contrast you identify.",
      },
    },
    {
      id: "pilot-v2-q4",
      type: "short-response",
      focus: "Interpreting a change in mood",
      prompt: "How might “warm light spilled across the wet pavement” shape the moment when the bus arrives? Explain one interpretation and consider Mara's final hesitation.",
      modelAnswer: "“Warm light” may suggest welcome or comfort, and “spilled” makes the light seem to spread across the pavement. However, Mara takes one step and then stops, so the scene remains uncertain rather than simply happy.",
      successIndicators: [
        "Selects a precise word or phrase.",
        "Explains the association it may create.",
        "Uses Mara's final action to support or qualify the interpretation.",
      ],
      feedbackForLearner: {
        ifStrong: "You explained how language shapes the moment and used the surrounding context.",
        nextStep: "Check whether the last sentence supports, complicates or changes the interpretation you began with.",
      },
    },
    {
      id: "pilot-v2-q5",
      type: "response-revision",
      focus: "Improving a visual analysis",
      prompt: "Improve this weak response in two or three sentences: “The poster uses dark colours. It looks nice.”",
      modelAnswer: "The dark street contrasts with the amber light around the shelter, so the viewer's attention may move towards the place where the passenger can wait. Together with the headline “A light on every last journey”, this contrast can support the poster's reassuring message about travelling late.",
      successIndicators: [
        "Names a specific visual contrast or placement choice.",
        "Explains what the choice may suggest or draw the audience's attention towards.",
        "Connects the explanation to the poster's message about a late journey.",
      ],
      feedbackForLearner: {
        ifStrong: "You moved beyond a general opinion and explained a specific design choice.",
        nextStep: "Name the visual detail, explain its possible effect and connect it to the intended message/audience.",
      },
    },
  ],
  exitTicket: {
    stimulus: {
      label: "Fresh micro-extract — original transfer text",
      text: "At sunrise, the empty platform shone silver. A single yellow scarf fluttered from the bench, pointing towards the open gate.",
      rightsNote: "Original transfer text written for this platform; not an official IB sample.",
    },
    prompt: "Choose a word or phrase from this new extract. In two or three sentences, explain what it may suggest and how it shapes the moment. Use precise evidence and connect your interpretation to the context.",
    successIndicators: [
      "Uses an exact word or phrase from the fresh extract.",
      "Explains a plausible association or effect, not just a technique name.",
      "Connects the explanation to the sunrise, empty platform, scarf or open gate.",
    ],
    modelAnswer: "“Shone silver” may make the platform seem quiet, cool or almost still at sunrise. The “yellow scarf” stands out against that image, and the verb “pointing” may draw attention towards the open gate or suggest a possible way forward. The reading should be tied to those details rather than treated as the only possible meaning.",
  },
  feedbackGuide: [
    { area: "Evidence choice", developing: "Makes a broad comment with no precise detail.", secure: "Selects a short exact phrase or identifiable visual feature that supports the point." },
    { area: "Explanation", developing: "Names a technique or says something is effective without explaining why.", secure: "Explains a plausible association/effect and links the specific choice to it." },
    { area: "Context and audience", developing: "Could apply the same comment to almost any text/poster.", secure: "Connects the interpretation to this moment, the wider scene or the intended audience." },
    { area: "Comparison", developing: "Lists one feature from each artefact without explaining a relationship.", secure: "Explains how the choices create a similarity or difference in likely impression." },
    { area: "Communication", developing: "Idea is difficult to follow or relies on an unsupported assertion.", secure: "Presents one reasoned point, uses evidence and qualifies an interpretation where useful." },
  ],
  accessibilitySupports: [
    "The passage and poster copy remain selectable text. The poster includes a written visual description and does not rely on colour alone.",
    "The entry check accepts a short observation before interpretation; it is not scored.",
    "Keep task instructions visible beside written-response fields.",
    "Accept different interpretations when supported by evidence and context.",
    "Review keyboard navigation, focus visibility, screen-reader order, zoom/reflow, visual contrast and mobile layout before release.",
    "Optional partner discussion: each learner names evidence, then repeats a partner's evidence before offering a different interpretation. This is an extension, not a scored task in the static preview.",
  ],
  remainingReleaseChecks: [
    "Founder approves this exact Unit 1 version 2 before the production sequence advances.",
    "Complete item-level academic review for version 2; version 1's review does not carry forward.",
    "Keep official Year 1 objective/strand codes blank until the applicable current guide is verified.",
    "Complete and record the separate rights review for text, poster copy and CSS visual composition.",
    "Complete and record accessibility and age/level suitability reviews.",
    "Only record explicit release approval after required gates are complete.",
  ],
  releaseNote:
    "Version 2 is a draft for founder review, not an approved release. Version 1 passed academic review for pilot preview only on 24 October 2026. Official Year 1 mapping remains unverified; rights review, accessibility review and explicit release approval are outstanding.",
};
