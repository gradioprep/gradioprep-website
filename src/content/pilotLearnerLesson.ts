import type { PilotLearnerLesson } from "./model";

/**
 * Learner-safe content for the reviewed pilot preview.
 *
 * This file contains no correct-answer IDs, answer explanations, or model
 * answers. Those remain in pilotLessonPack.ts and are not imported by the
 * client UI. The static interactions below do not score or persist responses.
 */
export const pilotLearnerLesson: PilotLearnerLesson = {
  id: "pilot-lesson-how-writers-shape-meaning-v1",
  version: 1,
  unitId: "ib-myp-lal-y1-u1",
  status: "approved-for-pilot-preview",
  reviewRecord: {
    outcome: "passed",
    reviewedAt: "2026-10-24",
    reviewerLabel: "Academic lead (approval confirmed by project owner; name not specified)",
    scopeNote:
      "Academic review passed for the content preview. The official IB syllabus/guide edition and objective mapping remain unverified; this is not approval to claim official curriculum alignment or release a syllabus-mapped course.",
  },
  title: "How writers shape meaning",
  estimatedMinutes: 25,
  audienceNote:
    "Pilot preview for early MYP learners. Age/level fit and official Year 1 mapping remain subject to the applicable school guide.",
  proposedLearningObjective:
    "Identify a deliberate word or phrase choice and explain how it may shape meaning or mood, supporting the interpretation with precise evidence.",
  mappingStatus: "unverified",
  successCriteria: [
    "I can select a precise word or phrase rather than describe the whole passage generally.",
    "I can explain a plausible association or effect instead of only naming a technique.",
    "I can connect that effect to the moment in the passage and support it with evidence.",
  ],
  passage: {
    label: "Original practice passage",
    text:
      "At the edge of the field, the last bus sighed, its headlights shrinking into the rain. Mara held her ticket beneath the shelter, smoothing its damp corners. Above her, the station clock clicked on. Across the road, the bakery's sign turned from OPEN to CLOSED. When the bus finally arrived, warm light spilled across the wet pavement. Mara took one step forward, then stopped.",
    rightsNote:
      "Original draft passage written for this project. This preview does not use a copied examination passage.",
  },
  keyIdea: {
    label: "The evidence chain",
    pattern: [
      "Choice — point to an exact word or phrase.",
      "Association — explain what it may suggest or make the reader notice.",
      "Effect in context — link the suggestion to the mood or meaning of this moment.",
    ],
    explanation:
      "Naming a technique is only a starting point. Support your interpretation with the words on the page, use language such as “may suggest”, and remember that more than one interpretation can be reasonable when it is supported by evidence.",
  },
  sections: [
    {
      id: "observe",
      heading: "1. Notice before you interpret",
      purpose: "Separate what the passage says from what you infer.",
      explanation:
        "Start with an observation you can point to. Then make an interpretation that the details support. The passage says that the bus “sighed”; it does not directly tell us that the bus is sad. The verb invites a possible human association.",
      learnerAction:
        "Choose one word or phrase that stands out. Write what it literally describes before explaining what it might suggest.",
    },
    {
      id: "evidence-chain",
      heading: "2. Build an evidence chain",
      purpose: "Connect the writer's choice to an explanation.",
      explanation:
        "Move from the chosen words to an association, then to the effect in this moment. “The writer uses personification” names a technique, but it does not yet explain why that choice matters here.",
      learnerAction:
        "Try this frame in your own words: “The word/phrase ‘…’ may suggest … . In this moment, that makes … seem/feel … because … .”",
      example: {
        label: "Short example",
        text: "“the last bus sighed”",
        explanation:
          "The verb gives the bus a human-like action. Ask what that association might suggest about the departure, then connect your idea to the rest of the scene.",
      },
    },
    {
      id: "context",
      heading: "3. Use the surrounding details",
      purpose: "Keep an interpretation connected to the whole moment.",
      explanation:
        "A phrase can do more than create mood. The image of headlights “shrinking into the rain” suggests the bus moving farther away. The damp ticket, clock and closing bakery may contribute other details about waiting, distance or uncertainty.",
      learnerAction:
        "Choose a second phrase from the passage. Explain how it supports, develops or changes your first interpretation.",
    },
    {
      id: "independent",
      heading: "4. Explain a choice independently",
      purpose: "Write a short analytical response.",
      explanation:
        "A useful response makes one clear point, supports it with a short quotation, and explains the connection. It is usually better to explain one choice carefully than to list several techniques without analysis.",
      learnerAction:
        "Write two or three sentences about “warm light spilled across the wet pavement”. Explain what the image may suggest at this point and support your view with evidence from the passage.",
      example: {
        label: "Prompt to consider",
        text: "“warm light spilled across the wet pavement”",
        explanation:
          "Think about the associations of “warm” and “spilled”. Then compare the mood those words may create with Mara's final hesitation.",
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
        { id: "A", text: "It proves that the bus has a mechanical problem." },
        { id: "B", text: "It may make the departure feel weary or reluctant." },
        { id: "C", text: "It tells us that Mara is physically exhausted." },
        { id: "D", text: "It means that every reader must feel sad." },
      ],
      successIndicators: [
        "Use the wording in the passage as evidence.",
        "Explain a plausible association rather than claim certainty.",
      ],
    },
    {
      id: "pilot-q2",
      type: "short-response",
      focus: "Explaining imagery",
      prompt:
        "Explain how “its headlights shrinking into the rain” may shape the reader's view of the bus leaving. Use the quoted phrase in your answer.",
      successIndicators: [
        "Quote or identify “shrinking into the rain”.",
        "Explain a plausible association such as distance or fading visibility.",
        "Connect that association to the departure or mood of the scene.",
      ],
    },
    {
      id: "pilot-q3",
      type: "short-response",
      focus: "Interpreting a change in mood",
      prompt:
        "How might “warm light spilled across the wet pavement” change the mood as the bus arrives? Give one interpretation and support it with the wording.",
      successIndicators: [
        "Select at least one precise word or phrase.",
        "Explain the association it may create.",
        "Connect the interpretation to the arrival and the surrounding context.",
      ],
    },
    {
      id: "pilot-q4",
      type: "response-revision",
      focus: "Improving an analytical explanation",
      prompt:
        "Improve this weak response in two or three sentences: “The writer uses personification. It makes the story good.”",
      successIndicators: [
        "Name an exact word or phrase.",
        "Explain what the choice may suggest or how it may affect the moment.",
        "Link the explanation to the surrounding scene instead of saying only that it is “good”.",
      ],
    },
  ],
  exitTicket: {
    prompt:
      "Choose a different word or phrase from the passage and write two or three sentences explaining how it may shape meaning or mood. Do not use “sighed” or “warm light”.",
    successIndicators: [
      "Select a precise piece of evidence.",
      "Explain a plausible effect in your own words.",
      "Connect the effect to the context of the passage.",
    ],
  },
  accessibilitySupports: [
    "The passage is rendered as selectable text; do not rely on colour alone to identify evidence.",
    "The three-part evidence chain can be used as a planning frame before writing.",
    "Keep task instructions visible while a learner drafts a response.",
    "Accept different interpretations when they are supported by textual evidence.",
    "Review vocabulary, reading load and age/level fit again before formal course release.",
  ],
  learnerNote:
    "Academic content review passed for this preview. Curriculum mapping is still unverified. Responses only exist in this open preview; they are not saved to an account, graded, or sent anywhere.",
};
