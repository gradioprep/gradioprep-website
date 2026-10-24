/**
 * Shared, lightweight frontend types for curriculum content.
 *
 * These types are a code-level starting point, not a database schema.
 * Keep prototype/demo content clearly separate from reviewed and published content.
 */

export type SkillArea = "Reading" | "Writing" | "Analysis";

export type PracticeTaskType =
  | "Short response"
  | "Guided analysis"
  | "Writing task"
  | "Revision task";

export type ContentLifecycle =
  | "planned"
  | "draft"
  | "in-review"
  | "approved"
  | "published"
  | "retired";

export type SyllabusMappingStatus = "unverified" | "verified";

/**
 * A question used only to demonstrate the current prototype UI.
 * Do not treat it as approved curriculum content or a real learner record.
 */
export interface DemoPracticeQuestion {
  id: string;
  area: SkillArea;
  type: PracticeTaskType;
  title: string;
  skill: string;
  time: string;
  contentStatus: "demonstration";
  syllabusMappingStatus: "unverified";
}

export interface DemoLessonAnswerOption {
  id: "A" | "B" | "C";
  text: string;
}

export interface DemoLessonOutlineStep {
  number: string;
  title: string;
  description: string;
  status: "complete" | "current" | "upcoming";
}

/**
 * Structured content for the one illustrative lesson currently used by the UI.
 * This must not be treated as syllabus-approved learning material.
 */
export interface DemoLesson {
  id: string;
  contentStatus: "demonstration";
  syllabusMappingStatus: "unverified";
  breadcrumb: {
    overview: string;
    questionBank: string;
    lessonTitle: string;
  };
  introduction: {
    eyebrow: string;
    headlineStart: string;
    headlineEmphasis: string;
    description: string;
    progressCompleted: number;
    progressTotal: number;
  };
  concept: {
    title: string;
    explanation: string;
    extractLabel: string;
    extractBefore: string;
    extractFocus: string;
    extractAfter: string;
    extractExplanation: string;
    tipTitle: string;
    tipBody: string;
  };
  practice: {
    title: string;
    instructions: string;
    answerOptions: DemoLessonAnswerOption[];
    correctAnswerId: DemoLessonAnswerOption["id"];
    correctFeedbackTitle: string;
    incorrectFeedbackTitle: string;
    feedbackExplanation: string;
  };
  outline: DemoLessonOutlineStep[];
  aside: {
    saveLabel: string;
    savedLabel: string;
    saveNote: string;
    tipTitle: string;
    tipBody: string;
  };
}
