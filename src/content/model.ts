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
