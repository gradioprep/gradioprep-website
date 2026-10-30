import type {
  PlannedUnitSlot,
  UnitContentPlan,
  UnitReadinessGate,
} from "./model";
import { englishPathways } from "./pathways";
import { pilotReviewSummary } from "./pilotReviewSummary";
import { pilotLearnerLesson } from "./pilotLearnerLesson";

/**
 * Static planning records, not a database. The pilot's content-review outcome,
 * lesson IDs and practice IDs are recorded for version 1. Curriculum mapping,
 * rights/accessibility review and release approval remain separate requirements.
 */
export const unitContentPlans: UnitContentPlan[] = englishPathways.flatMap(pathway =>
  pathway.unitSlots.map((unit: PlannedUnitSlot): UnitContentPlan => {
    const isPilotUnit = unit.id === pilotLearnerLesson.unitId;
    return {
      id: `plan-${unit.id}`,
      unitId: unit.id,
      pathwayId: pathway.id,
      version: 1,
      title: isPilotUnit ? pilotLearnerLesson.title : unit.title,
      releaseStatus: "planned",
      syllabusEditionCode: null,
      officialSourceUrl: isPilotUnit ? pilotReviewSummary.source.url : null,
      officialSourceCheckedAt: isPilotUnit ? pilotReviewSummary.source.checkedAt : null,
      officialSourceNote: isPilotUnit ? pilotReviewSummary.source.scopeNote : null,
      officialObjectiveCodes: isPilotUnit ? pilotReviewSummary.officialObjectiveCodes : [],
      learningObjective: isPilotUnit ? pilotLearnerLesson.proposedLearningObjective : null,
      lessonIds: isPilotUnit ? [pilotLearnerLesson.id] : [],
      practiceQuestionIds: isPilotUnit ? pilotLearnerLesson.practiceItems.map(item => item.id) : [],
      answerKeyReviewState: isPilotUnit ? "passed" : "not-started",
      academicReviewer: isPilotUnit ? pilotLearnerLesson.reviewRecord.reviewerLabel : null,
      academicReviewedAt: isPilotUnit ? pilotLearnerLesson.reviewRecord.reviewedAt : null,
      contentRightsNote: null,
      accessibilityReviewState: "not-started",
      releaseApprovedBy: null,
      releaseApprovedAt: null,
    };
  })
);

/**
 * Readiness is calculated from the record's evidence, never from the selected
 * UI state. Missing evidence blocks relevant gates; it is never assumed passed.
 */
export function getUnitReadinessGates(plan: UnitContentPlan): UnitReadinessGate[] {
  const sourceVerified = Boolean(
    plan.syllabusEditionCode &&
    plan.officialSourceUrl &&
    plan.officialSourceCheckedAt &&
    plan.officialObjectiveCodes.length > 0
  );
  const objectiveApproved = Boolean(plan.learningObjective?.trim());
  const lessonLinked = plan.lessonIds.length > 0;
  const practiceLinked = plan.practiceQuestionIds.length > 0;
  const answersReviewed = plan.answerKeyReviewState === "passed";
  const academicReviewed = Boolean(plan.academicReviewer && plan.academicReviewedAt);
  const rightsReviewed = Boolean(plan.contentRightsNote?.trim());
  const accessibilityReviewed = plan.accessibilityReviewState === "passed";
  const releaseApproved = Boolean(
    (plan.releaseStatus === "approved" || plan.releaseStatus === "published") &&
    plan.releaseApprovedBy &&
    plan.releaseApprovedAt
  );

  return [
    {
      id: "official-source",
      title: "Verify the official curriculum source",
      detail: "Record the applicable specification or framework edition, official source URL, date checked and objective references.",
      owner: "Academic review",
      status: sourceVerified ? "complete" : "blocked",
    },
    {
      id: "learning-objective",
      title: "Approve the learning objective",
      detail: "Confirm the unit focus, objective wording and prerequisites before drafting the lesson.",
      owner: "Academic decision",
      status: objectiveApproved && sourceVerified ? "complete" : "blocked",
    },
    {
      id: "lesson-content",
      title: "Prepare and link the lesson",
      detail: "Add the explanation, worked or annotated example, common mistakes and a meaningful next step.",
      owner: "Content work",
      status: lessonLinked ? "complete" : "pending",
    },
    {
      id: "practice-and-answers",
      title: "Link practice and reviewed answers",
      detail: "Add relevant questions, answer keys and explanations. Review answer material before release.",
      owner: "Content work",
      status: practiceLinked && answersReviewed ? "complete" : "pending",
    },
    {
      id: "academic-review",
      title: "Record academic review",
      detail: "Record the reviewer, date and review outcome for this exact content version.",
      owner: "Quality review",
      status: academicReviewed ? "complete" : "pending",
    },
    {
      id: "rights-review",
      title: "Record content rights and sources",
      detail: "Confirm the content is original or has an appropriate rights basis, and keep source notes.",
      owner: "Quality review",
      status: rightsReviewed ? "complete" : "pending",
    },
    {
      id: "accessibility-review",
      title: "Complete accessibility review",
      detail: "Check readability, keyboard operation, contrast, responsive presentation and mobile use.",
      owner: "Quality review",
      status: accessibilityReviewed ? "complete" : "pending",
    },
    {
      id: "release-approval",
      title: "Approve the unit for release",
      detail: "Record who approved the release and when. This gate must not pass while earlier requirements are unresolved.",
      owner: "Release gate",
      status: releaseApproved && sourceVerified && objectiveApproved &&
        lessonLinked && practiceLinked && answersReviewed && academicReviewed &&
        rightsReviewed && accessibilityReviewed
        ? "complete"
        : "blocked",
    },
  ];
}

export function getUnitReadinessSummary(plan: UnitContentPlan): {
  complete: number;
  total: number;
  releasable: boolean;
} {
  const gates = getUnitReadinessGates(plan);
  const complete = gates.filter(gate => gate.status === "complete").length;
  return {
    complete,
    total: gates.length,
    releasable: gates.every(gate => gate.status === "complete"),
  };
}
