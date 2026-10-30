import type { PilotLessonPack } from "./model";

/**
 * Teacher/editor source for the reviewed pilot lesson pack. This includes answer
 * keys and model responses, so MUST NOT be imported into the client application.
 * Academic review passed for the pilot preview on 2026-10-24; curriculum mapping
 * remains unverified and the pack is not an officially mapped or released MYP unit.
 */
export const pilotLessonPack: PilotLessonPack = {
  id: "draft-lesson-how-writers-shape-meaning",
  version: 1,
  unitId: "ib-myp-lal-y1-u1",
  status: "approved-for-pilot-preview",
  reviewRecord: {
    outcome: "passed",
    reviewedAt: "2026-10-24",
    reviewerLabel: "Academic lead (approval confirmed by project owner; name not specified)",
    scopeNote: "Academic content review passed for this version per project owner confirmation. This approval supports the pilot preview only; the official curriculum mapping remains unverified and release is not authorised.",
  },
  title: "How writers shape meaning",
  audienceNote:
    "Proposed for an early MYP learner audience; the Year 1 level fit has not yet been approved by the academic lead.",
  estimatedMinutes: 25,
  proposedLearningObjective:
    "Identify a deliberate word or phrase choice and explain how it may shape meaning or mood, supporting the interpretation with precise evidence.",
  mappingStatus: "unverified",
  successCriteria: [
    "I can select a precise word or phrase rather than describe the whole passage generally.",
    "I can explain a plausible association or effect instead of only naming a technique.",
    "I can connect that effect to the moment in the passage and support it with evidence.",
  ],
  passage: {
    label: "Original practice passage — written for this draft",
    text:
      "At the edge of the field, the last bus sighed, its headlights shrinking into the rain. Mara held her ticket beneath the shelter, smoothing its damp corners. Above her, the station clock clicked on. Across the road, the bakery's sign turned from OPEN to CLOSED. When the bus finally arrived, warm light spilled across the wet pavement. Mara took one step forward, then stopped.",
    rightsNote:
      "The passage is original draft text written for this pilot. Any future additions must be original or have a documented, appropriate rights basis.",
  },
  keyIdea: {
    label: "An evidence chain",
    pattern: [
      "Choice — point to an exact word or phrase.",
      "Association — explain what it may suggest or make the reader notice.",
      "Effect in context — link the suggestion to the mood or meaning of this moment.",
    ],
    explanation:
      "A technique name on its own is not a complete explanation. Interpretations can differ: support yours with the words on the page, use cautious language such as “may suggest”, and avoid claiming that every reader must react in the same way.",
  },
  sections: [
    {
      id: "observe",
      heading: "1. Notice before you interpret",
      purpose: "Separate what the passage literally says from what you infer.",
      explanation:
        "Start with an observation you can point to. Then make an interpretation that the details support. For example, the passage says that the bus “sighed”; it does not directly tell us that the bus is sad. The verb invites a possible human association, which can shape how the departure feels.",
      learnerAction:
        "Underline one word or phrase that stands out. In a few words, record what it literally describes before explaining what it might suggest.",
    },
    {
      id: "evidence-chain",
      heading: "2. Build an evidence chain",
      purpose: "Connect a writer's choice to a reasoned explanation.",
      explanation:
        "Move from the chosen words to an association and then to the effect in this specific moment. Do not skip the middle step: “The writer uses personification” names a technique, but does not explain why that choice matters here.",
      learnerAction:
        "Complete this frame in your own words: “The word/phrase ‘…’ may suggest … . In this moment, that makes … seem/feel … because … .”",
      example: {
        label: "Worked example",
        text: "“the last bus sighed”",
        explanation:
          "The verb “sighed” gives the bus a human-like action. It may make the departure seem weary or reluctant, adding a subdued mood to the scene. This is a plausible interpretation, not the only acceptable one.",
      },
    },
    {
      id: "context",
      heading: "3. Use the surrounding details",
      purpose: "Keep an interpretation connected to the whole moment.",
      explanation:
        "A phrase can do more than create a mood. The image of headlights “shrinking into the rain” suggests the bus moving farther away. Together with the damp ticket and the closing bakery, it may contribute to a sense of waiting, distance or uncertainty. Select the meaning you can best support.",
      learnerAction:
        "Choose a second phrase from the passage. Explain how it supports, develops or changes your first interpretation.",
    },
    {
      id: "independent",
      heading: "4. Explain a choice independently",
      purpose: "Write a short analytical response without relying on a sentence frame.",
      explanation:
        "A useful response usually makes one clear point, supports it with a short quotation and explains the connection. It is better to explain one choice carefully than to list several techniques without analysis.",
      learnerAction:
        "Write two or three sentences about “warm light spilled across the wet pavement”. Explain what the image may suggest at this point in the scene and support your reading with a detail from the passage.",
      example: {
        label: "Possible line of thinking",
        text: "“warm light spilled across the wet pavement”",
        explanation:
          "“Warm” can suggest comfort or welcome, while “spilled” makes the light seem to spread freely. The contrast with the rain may briefly make the arrival feel inviting, although Mara's hesitation means the moment is not simply happy.",
      },
    },
  ],
  practiceItems: [
    {
      id: "pilot-q1",
      type: "best-explanation",
      focus: "Interpreting a word choice",
      prompt:
        "Which explanation is best supported by the phrase “the last bus sighed”?",
      options: [
        {
          id: "A",
          text: "It proves that the bus has a mechanical problem.",
          feedback:
            "The passage does not give evidence of a mechanical fault. Look at the human association created by the verb.",
        },
        {
          id: "B",
          text: "It may make the departure feel weary or reluctant.",
          feedback:
            "This is well supported: “sighed” describes a human-like action and can suggest tiredness or reluctance in the scene.",
        },
        {
          id: "C",
          text: "It tells us that Mara is physically exhausted.",
          feedback:
            "The phrase describes the bus, not Mara. You can consider how it shapes the scene, but do not transfer the action directly to her.",
        },
        {
          id: "D",
          text: "It means that every reader must feel sad.",
          feedback:
            "The wording can influence mood, but it cannot guarantee that every reader responds in the same way.",
        },
      ],
      bestOptionId: "B",
      modelAnswer:
        "B — “sighed” gives the bus a human-like action and may make its departure feel weary or reluctant.",
      successIndicators: [
        "Uses the wording in the passage as evidence.",
        "Explains a plausible association rather than claiming certainty.",
      ],
      feedbackForLearner: {
        ifStrong:
          "You connected the verb to a plausible effect and stayed close to the evidence.",
        nextStep:
          "Check whether your explanation is supported by the actual words and avoids claiming more than the passage shows.",
      },
    },
    {
      id: "pilot-q2",
      type: "short-response",
      focus: "Explaining imagery",
      prompt:
        "Explain how “its headlights shrinking into the rain” may shape the reader's view of the bus leaving. Use the quoted phrase in your answer.",
      modelAnswer:
        "“Shrinking into the rain” makes the headlights seem to grow smaller and less distinct as the bus moves away. This can emphasise distance and make the departure feel uncertain or final.",
      successIndicators: [
        "Quotes or identifies “shrinking into the rain”.",
        "Explains a plausible association such as distance or fading visibility.",
        "Connects that association to the departure or mood of the scene.",
      ],
      feedbackForLearner: {
        ifStrong:
          "Your explanation connects the image to what is happening in the scene.",
        nextStep:
          "Add a precise phrase from the passage and explain what that phrase suggests; do not stop after naming a technique.",
      },
    },
    {
      id: "pilot-q3",
      type: "short-response",
      focus: "Interpreting a change in mood",
      prompt:
        "How might “warm light spilled across the wet pavement” change the mood as the bus arrives? Give one interpretation and support it with the wording.",
      modelAnswer:
        "“Warm light” may suggest comfort or welcome, briefly making the arrival feel more hopeful. The verb “spilled” presents the light as spreading across the pavement, although Mara's final hesitation leaves some uncertainty.",
      successIndicators: [
        "Selects at least one precise word or phrase.",
        "Explains the association it may create.",
        "Connects the interpretation to the arrival and recognises the final hesitation as relevant context.",
      ],
      feedbackForLearner: {
        ifStrong:
          "You explained how the language contributes to the moment and considered the surrounding context.",
        nextStep:
          "Explain why the selected words support your interpretation, and check whether the final sentence complicates your reading.",
      },
    },
    {
      id: "pilot-q4",
      type: "response-revision",
      focus: "Improving an analytical explanation",
      prompt:
        "Improve this weak response in two or three sentences: “The writer uses personification. It makes the story good.”",
      modelAnswer:
        "The verb “sighed” gives the bus a human-like action, which may make its departure seem weary or reluctant. This subdued impression fits the bus moving away into the rain and helps establish the scene's uncertain mood.",
      successIndicators: [
        "Names an exact word or phrase.",
        "Explains what the choice may suggest or how it may affect the moment.",
        "Links the explanation to the surrounding scene rather than saying only that it is “good”.",
      ],
      feedbackForLearner: {
        ifStrong:
          "The revision explains why the choice matters, rather than stopping at a technique name.",
        nextStep:
          "Replace general praise with evidence, a plausible interpretation and a connection to the scene.",
      },
    },
  ],
  exitTicket: {
    prompt:
      "Choose a different word or phrase from the passage and write two or three sentences explaining how it may shape meaning or mood. Do not use “sighed” or “warm light”.",
    successIndicators: [
      "Selects a precise piece of evidence.",
      "Explains a plausible effect in their own words.",
      "Connects the effect to the context of the passage.",
    ],
    modelAnswer:
      "“The station clock clicked on” may draw attention to the passing time through the small, repeated sound. In a quiet scene where Mara is waiting, this can make the wait feel more noticeable or tense.",
  },
  feedbackGuide: [
    {
      area: "Evidence",
      developing:
        "The response describes the scene generally or refers to a broad idea without selecting useful words.",
      secure:
        "The response selects a specific word or short phrase that supports its point.",
    },
    {
      area: "Explanation",
      developing:
        "The response only names a technique or says that the writing is effective.",
      secure:
        "The response explains a plausible association or effect and shows how the wording supports it.",
    },
    {
      area: "Context",
      developing:
        "The explanation could be attached to almost any passage and does not address this moment.",
      secure:
        "The explanation connects the choice to the action, mood or meaning in this passage.",
    },
  ],
  accessibilitySupports: [
    "Offer the passage in a readable, selectable text format; do not rely on colour alone to highlight evidence.",
    "Allow learners to plan first using the three-part evidence chain: choice, association, effect in context.",
    "Keep the short-response instructions visible beside the response field when this content is implemented in a real lesson.",
    "Accept different evidence-supported interpretations and provide a next step rather than marking one literary reading as the only possible answer.",
    "Review vocabulary, sentence length and cognitive load with a teacher before confirming age/level suitability.",
  ],
  remainingReleaseChecks: [
    "Confirm the applicable current guide/edition used by the intended school and verify whether candidate strands A(ii), A(iii), both or neither are appropriate.",
    "Record exact official objective/strand references only after checking that guide.",
    "Complete and record the separate content-rights review.",
    "Complete and record the accessibility review for the interactive lesson.",
    "Record explicit release approval only after all required evidence is complete.",
  ],
  releaseNote:
    "Academic content review passed for pilot preview version 1. Do not describe this as an officially mapped MYP unit, grade it as an official IB achievement level, or release it as a syllabus-mapped course until the applicable guide edition/objective references, rights review, accessibility review and explicit release approval are recorded.",
};
