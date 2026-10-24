import type { DemoLesson } from "./model";
import { createUnassignedDemoCurriculum } from "./demoMetadata";

/**
 * One illustrative lesson, separated from the page component so content can
 * be reviewed and replaced independently of its presentation.
 *
 * It is fictional demonstration content, not mapped to an official syllabus.
 */
export const demoLesson: DemoLesson = {
  id: "demo-language-choices",
  version: 1,
  curriculum: createUnassignedDemoCurriculum(),
  contentStatus: "demonstration",
  breadcrumb: {
    overview: "Overview",
    questionBank: "Question bank",
    lessonTitle: "Language choices",
  },
  introduction: {
    eyebrow: "SKILL STUDY · SAMPLE UNIT",
    headlineStart: "Notice the choice.",
    headlineEmphasis: "Explain the effect.",
    description:
      "Strong analysis moves beyond spotting a technique. It explains how a particular choice shapes a reader's experience.",
    progressCompleted: 2,
    progressTotal: 4,
  },
  concept: {
    title: "A choice is only the beginning.",
    explanation:
      "When you analyse a piece of writing, naming a technique is not enough. Ask what the writer's choice makes the reader notice, feel or question—and support your explanation with evidence.",
    extractLabel: "INVENTED EXAMPLE EXTRACT",
    extractBefore: "The door swung open. ",
    extractFocus: "Silence.",
    extractAfter: " Then the room erupted.",
    extractExplanation:
      "The one-word sentence interrupts the rhythm. That pause makes the sudden shift in the room feel sharper.",
    tipTitle: "Try this thinking move",
    tipBody:
      "Choice → evidence → effect. Make the link between each part explicit.",
  },
  practice: {
    title: "Why might the writer use the one-word sentence?",
    instructions:
      "Choose the strongest explanation. This is a sample question, not a syllabus-verified item.",
    answerOptions: [
      { id: "A", text: "It tells the reader exactly what to think." },
      { id: "B", text: "It slows the scene without changing its mood." },
      {
        id: "C",
        text: "It creates a pause that makes the change feel sudden.",
      },
    ],
    correctAnswerId: "C",
    correctFeedbackTitle: "That's the strongest explanation.",
    incorrectFeedbackTitle: "Review the effect, not just the technique.",
    feedbackExplanation:
      "The abrupt pause changes the rhythm and heightens the contrast with what follows.",
  },
  outline: [
    {
      number: "01",
      title: "The idea",
      description: "Understand the skill",
      status: "complete",
    },
    {
      number: "02",
      title: "Check understanding",
      description: "Try a question",
      status: "current",
    },
    {
      number: "03",
      title: "Review an example",
      description: "See the reasoning",
      status: "upcoming",
    },
    {
      number: "04",
      title: "Choose what is next",
      description: "Review and continue",
      status: "upcoming",
    },
  ],
  aside: {
    saveLabel: "Save this lesson",
    savedLabel: "Saved to demo list",
    saveNote: "Temporary to this open preview; not synced to an account.",
    tipTitle: "Keep the explanation useful.",
    tipBody:
      "A strong response names the choice, points to evidence and explains its effect.",
  },
};
