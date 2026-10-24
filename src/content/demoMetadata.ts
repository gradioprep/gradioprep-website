import type { CurriculumAlignment } from "./model";

/**
 * Explicitly unassigned metadata for demonstration-only content.
 * Do not set a pathway or syllabus until academic review confirms the mapping.
 */
export function createUnassignedDemoCurriculum(): CurriculumAlignment {
  return {
    programmeCode: null,
    courseCode: null,
    pathwayId: null,
    syllabusEditionCode: null,
    objectiveCodes: [],
    mappingStatus: "unverified",
    reviewNote:
      "Demonstration content only. No official programme, pathway, syllabus edition or objective mapping has been verified.",
  };
}
