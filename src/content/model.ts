/**
 * Shared frontend types for curriculum-aware English learning content.
 *
 * These types are a code-level foundation, not a live database schema.
 * Content is not releasable until its mapping and academic review are verified.
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

export type PathwayLevelKind =
  | "official-programme-level"
  | "navigation-only-grade-equivalent";

export type UnitSequence = 1 | 2 | 3;

/**
 * Curriculum identity is explicit. Null values mean "not assigned yet", not
 * that the content applies to every programme or syllabus.
 */
export interface CurriculumAlignment {
  programmeCode: string | null;
  courseCode: string | null;
  pathwayId: string | null;
  syllabusEditionCode: string | null;
  objectiveCodes: string[];
  mappingStatus: SyllabusMappingStatus;
  reviewNote: string;
}

export interface PlannedUnitSlot {
  id: string;
  pathwayId: string;
  sequence: UnitSequence;
  title: string;
  learningObjective: null;
  officialObjectiveCodes: string[];
  mappingStatus: "unverified";
  releaseStatus: "planned";
  reviewNote: string;
}

/**
 * Catalogue entry for one learner-facing route.
 * An IGCSE grade-equivalent band is a navigation aid, not a separate
 * qualification or an assertion of a different official syllabus.
 */
export interface CurriculumPathway {
  id: string;
  programmeCode: string;
  programmeName: string;
  courseCode: string;
  courseName: string;
  levelCode: string;
  levelLabel: string;
  levelKind: PathwayLevelKind;
  gradeEquivalentLabel: string | null;
  syllabusEditionCode: null;
  mappingStatus: "unverified";
  releaseStatus: "planned";
  reviewNote: string;
  unitSlots: PlannedUnitSlot[];
}

/**
 * A question used only to demonstrate the current prototype UI.
 */
export interface DemoPracticeQuestion {
  id: string;
  version: 1;
  area: SkillArea;
  type: PracticeTaskType;
  title: string;
  skill: string;
  time: string;
  contentStatus: "demonstration";
  curriculum: CurriculumAlignment;
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
 * Structured content for the illustrative lesson used by the current UI.
 * Its curriculum alignment must stay unassigned until reviewed.
 */
export interface DemoLesson {
  id: string;
  version: 1;
  contentStatus: "demonstration";
  curriculum: CurriculumAlignment;
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

/** Review states used by the unit-content release checklist. */
export type ContentReviewState = "not-started" | "in-review" | "passed";

/**
 * Production planning record for a pathway unit. It deliberately separates
 * the intended pathway from verified syllabus alignment and released content.
 */
export interface UnitContentPlan {
  id: string;
  unitId: string;
  pathwayId: string;
  version: number;
  title: string;
  releaseStatus: ContentLifecycle;
  syllabusEditionCode: string | null;
  officialObjectiveCodes: string[];
  learningObjective: string | null;
  lessonIds: string[];
  practiceQuestionIds: string[];
  answerKeyReviewState: ContentReviewState;
  academicReviewer: string | null;
  academicReviewedAt: string | null;
  contentRightsNote: string | null;
  accessibilityReviewState: ContentReviewState;
  releaseApprovedBy: string | null;
  releaseApprovedAt: string | null;
}

export type UnitReadinessGateId =
  | "official-source"
  | "learning-objective"
  | "lesson-content"
  | "practice-and-answers"
  | "academic-review"
  | "rights-review"
  | "accessibility-review"
  | "release-approval";

export type UnitReadinessGateStatus = "blocked" | "pending" | "complete";

export interface UnitReadinessGate {
  id: UnitReadinessGateId;
  title: string;
  detail: string;
  owner: string;
  status: UnitReadinessGateStatus;
}
