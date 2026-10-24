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
/** An original pilot unit brief, intentionally kept separate from released lesson content. */
export interface PilotUnitDraft {
  id: string;
  version: 1;
  pathwayId: string;
  unitId: string;
  status: "approved-for-pilot-preview";
  reviewRecord: {
    outcome: "passed";
    reviewedAt: string;
    reviewerLabel: string;
    scopeNote: string;
  };
  title: string;
  proposedFocus: string;
  proposedLearningObjective: string;
  mappingStatus: "unverified";
  officialObjectiveCodes: string[];
  source: {
    title: string;
    url: string;
    subjectBriefUrl: string;
    checkedAt: string;
    scopeNote: string;
  };
  candidateGuide: {
    title: string;
    url: string;
    checkedAt: string;
    accessNote: string;
  };
  candidateObjectiveMappings: {
    criterion: "A — Analysing";
    strand: "A(ii)" | "A(iii)";
    descriptor: string;
    state: "candidate-unverified";
    rationale: string;
  }[];
  teachingSequence: {
    number: string;
    title: string;
    purpose: string;
  }[];
  originalExample: {
    label: string;
    text: string;
    focus: string;
    teachingNote: string;
  };
  practicePrompt: string;
  responseExpectation: string[];
  commonMisconceptions: string[];
  reviewQuestions: string[];
  rightsNote: string;
  releaseNote: string;
}

/** One teacher-facing teaching step in an unreleased pilot lesson. */
export interface PilotLessonSection {
  id: string;
  heading: string;
  purpose: string;
  explanation: string;
  learnerAction: string;
  example?: {
    label: string;
    text: string;
    explanation: string;
  };
}

export interface PilotPracticeOption {
  id: string;
  text: string;
  feedback: string;
}

export interface PilotPracticeItem {
  id: string;
  type: "best-explanation" | "short-response" | "response-revision";
  focus: string;
  prompt: string;
  options?: PilotPracticeOption[];
  bestOptionId?: string;
  modelAnswer: string;
  successIndicators: string[];
  feedbackForLearner: {
    ifStrong: string;
    nextStep: string;
  };
}

export interface PilotLessonPack {
  id: string;
  version: 1;
  unitId: string;
  status: "approved-for-pilot-preview";
  reviewRecord: {
    outcome: "passed";
    reviewedAt: string;
    reviewerLabel: string;
    scopeNote: string;
  };
  title: string;
  audienceNote: string;
  estimatedMinutes: number;
  proposedLearningObjective: string;
  mappingStatus: "unverified";
  successCriteria: string[];
  passage: {
    label: string;
    text: string;
    rightsNote: string;
  };
  keyIdea: {
    label: string;
    pattern: string[];
    explanation: string;
  };
  sections: PilotLessonSection[];
  practiceItems: PilotPracticeItem[];
  exitTicket: {
    prompt: string;
    successIndicators: string[];
    modelAnswer: string;
  };
  feedbackGuide: {
    area: string;
    developing: string;
    secure: string;
  }[];
  accessibilitySupports: string[];
  academicReviewQuestions: string[];
  releaseNote: string;
}

/** The learner-facing version deliberately excludes answer keys and model answers. */
export interface PilotLearnerLesson {
  id: string;
  version: 1;
  unitId: string;
  status: "approved-for-pilot-preview";
  reviewRecord: {
    outcome: "passed";
    reviewedAt: string;
    reviewerLabel: string;
    scopeNote: string;
  };
  title: string;
  estimatedMinutes: number;
  audienceNote: string;
  proposedLearningObjective: string;
  mappingStatus: "unverified";
  successCriteria: string[];
  passage: {
    label: string;
    text: string;
    rightsNote: string;
  };
  keyIdea: {
    label: string;
    pattern: string[];
    explanation: string;
  };
  sections: {
    id: string;
    heading: string;
    purpose: string;
    explanation: string;
    learnerAction: string;
    example?: {
      label: string;
      text: string;
      explanation: string;
    };
  }[];
  practiceItems: {
    id: string;
    type: "best-explanation" | "short-response" | "response-revision";
    focus: string;
    prompt: string;
    options?: { id: string; text: string }[];
    successIndicators: string[];
  }[];
  exitTicket: {
    prompt: string;
    successIndicators: string[];
  };
  accessibilitySupports: string[];
  learnerNote: string;
}

export interface UnitContentPlan {
  id: string;
  unitId: string;
  pathwayId: string;
  version: number;
  title: string;
  releaseStatus: ContentLifecycle;
  syllabusEditionCode: string | null;
  officialSourceUrl: string | null;
  officialSourceCheckedAt: string | null;
  officialSourceNote: string | null;
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
