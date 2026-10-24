import type { DemoPracticeQuestion } from "./model";
import { createUnassignedDemoCurriculum } from "./demoMetadata";

/**
 * Fictitious examples for the question-bank prototype.
 *
 * These items demonstrate search/filter behaviour only. They have not been
 * syllabus-mapped or approved for student use, and no learner attempts are saved.
 */
export const demoQuestionItems: DemoPracticeQuestion[] = [
  {
    id: "Q-014",
    version: 1,
    curriculum: createUnassignedDemoCurriculum(),
    area: "Reading",
    type: "Short response",
    title: "Read between the lines",
    skill: "Inference and evidence",
    time: "8 min",
    contentStatus: "demonstration",
  },
  {
    id: "Q-021",
    version: 1,
    curriculum: createUnassignedDemoCurriculum(),
    area: "Analysis",
    type: "Guided analysis",
    title: "How language shapes tone",
    skill: "Writer's choices",
    time: "12 min",
    contentStatus: "demonstration",
  },
  {
    id: "Q-026",
    version: 1,
    curriculum: createUnassignedDemoCurriculum(),
    area: "Writing",
    type: "Writing task",
    title: "Build a purposeful opening",
    skill: "Structure and audience",
    time: "15 min",
    contentStatus: "demonstration",
  },
  {
    id: "Q-033",
    version: 1,
    curriculum: createUnassignedDemoCurriculum(),
    area: "Reading",
    type: "Short response",
    title: "Select the strongest evidence",
    skill: "Evidence selection",
    time: "7 min",
    contentStatus: "demonstration",
  },
  {
    id: "Q-041",
    version: 1,
    curriculum: createUnassignedDemoCurriculum(),
    area: "Writing",
    type: "Revision task",
    title: "Make every sentence work",
    skill: "Precision and concision",
    time: "10 min",
    contentStatus: "demonstration",
  },
  {
    id: "Q-052",
    version: 1,
    curriculum: createUnassignedDemoCurriculum(),
    area: "Analysis",
    type: "Guided analysis",
    title: "Notice the pattern, explain the effect",
    skill: "Language and effect",
    time: "14 min",
    contentStatus: "demonstration",
  },
];
