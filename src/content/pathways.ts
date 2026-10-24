import type { CurriculumPathway, PlannedUnitSlot, UnitSequence } from "./model";

const unitSequences: readonly UnitSequence[] = [1, 2, 3];

/**
 * Create empty production-planning slots only. These are not lesson topics and
 * do not imply curriculum coverage; the academic lead chooses each focus.
 */
function plannedUnitSlots(pathwayId: string): PlannedUnitSlot[] {
  return unitSequences.map((sequence) => {
    const isPilotDraft = pathwayId === "ib-myp-lal-y1" && sequence === 1;
    return {
      id: `${pathwayId}-u${sequence}`,
      pathwayId,
      sequence,
      title: isPilotDraft ? "Draft focus — How writers shape meaning" : "Unit focus to be confirmed",
      learningObjective: null,
      officialObjectiveCodes: [],
      mappingStatus: "unverified",
      releaseStatus: "planned",
      reviewNote: isPilotDraft
        ? "Working content draft available for academic review; not an approved Year 1 objective mapping or release."
        : "Planning slot only. Add a skill focus and official objective references after academic review.",
    };
  });
}

function pathway(
  entry: Omit<CurriculumPathway, "syllabusEditionCode" | "mappingStatus" | "releaseStatus" | "unitSlots">
): CurriculumPathway {
  return {
    ...entry,
    syllabusEditionCode: null,
    mappingStatus: "unverified",
    releaseStatus: "planned",
    unitSlots: plannedUnitSlots(entry.id),
  };
}

/**
 * Ten Stage 1 planning entries, matching the master brief and roadmap.
 * The catalogue is intentionally not yet tied to an official syllabus edition.
 */
export const englishPathways: CurriculumPathway[] = [
  pathway({
    id: "ib-myp-lal-y1",
    programmeCode: "ib-myp",
    programmeName: "IB MYP",
    courseCode: "ib-myp-language-literature",
    courseName: "Language and Literature",
    levelCode: "year-1",
    levelLabel: "Year 1",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: "Approx. Grade 6 equivalent",
    reviewNote:
      "Grade equivalent is a navigation aid only. Verify programme documents and approve unit sequence before release.",
  }),
  pathway({
    id: "ib-myp-lal-y2",
    programmeCode: "ib-myp",
    programmeName: "IB MYP",
    courseCode: "ib-myp-language-literature",
    courseName: "Language and Literature",
    levelCode: "year-2",
    levelLabel: "Year 2",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: "Approx. Grade 7 equivalent",
    reviewNote:
      "Grade equivalent is a navigation aid only. Verify programme documents and approve unit sequence before release.",
  }),
  pathway({
    id: "ib-myp-lal-y3",
    programmeCode: "ib-myp",
    programmeName: "IB MYP",
    courseCode: "ib-myp-language-literature",
    courseName: "Language and Literature",
    levelCode: "year-3",
    levelLabel: "Year 3",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: "Approx. Grade 8 equivalent",
    reviewNote:
      "Grade equivalent is a navigation aid only. Verify programme documents and approve unit sequence before release.",
  }),
  pathway({
    id: "ib-myp-lal-y4",
    programmeCode: "ib-myp",
    programmeName: "IB MYP",
    courseCode: "ib-myp-language-literature",
    courseName: "Language and Literature",
    levelCode: "year-4",
    levelLabel: "Year 4",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: "Approx. Grade 9 equivalent",
    reviewNote:
      "Grade equivalent is a navigation aid only. Verify programme documents and approve unit sequence before release.",
  }),
  pathway({
    id: "ib-myp-lal-y5",
    programmeCode: "ib-myp",
    programmeName: "IB MYP",
    courseCode: "ib-myp-language-literature",
    courseName: "Language and Literature",
    levelCode: "year-5",
    levelLabel: "Year 5",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: "Approx. Grade 10 equivalent",
    reviewNote:
      "Grade equivalent is a navigation aid only. Verify programme documents and approve unit sequence before release.",
  }),
  pathway({
    id: "cambridge-ls-english-s7",
    programmeCode: "cambridge-lower-secondary",
    programmeName: "Cambridge Lower Secondary",
    courseCode: "cambridge-lower-secondary-english",
    courseName: "English",
    levelCode: "stage-7",
    levelLabel: "Stage 7",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: null,
    reviewNote:
      "Confirm applicable curriculum framework and official learning-objective references before release.",
  }),
  pathway({
    id: "cambridge-ls-english-s8",
    programmeCode: "cambridge-lower-secondary",
    programmeName: "Cambridge Lower Secondary",
    courseCode: "cambridge-lower-secondary-english",
    courseName: "English",
    levelCode: "stage-8",
    levelLabel: "Stage 8",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: null,
    reviewNote:
      "Confirm applicable curriculum framework and official learning-objective references before release.",
  }),
  pathway({
    id: "cambridge-ls-english-s9",
    programmeCode: "cambridge-lower-secondary",
    programmeName: "Cambridge Lower Secondary",
    courseCode: "cambridge-lower-secondary-english",
    courseName: "English",
    levelCode: "stage-9",
    levelLabel: "Stage 9",
    levelKind: "official-programme-level",
    gradeEquivalentLabel: null,
    reviewNote:
      "Confirm applicable curriculum framework and official learning-objective references before release.",
  }),
  pathway({
    id: "cambridge-igcse-fle-band-9",
    programmeCode: "cambridge-igcse",
    programmeName: "Cambridge IGCSE",
    courseCode: "cambridge-igcse-first-language-english",
    courseName: "First Language English",
    levelCode: "grade-9-equivalent-band",
    levelLabel: "Grade 9-equivalent learning band",
    levelKind: "navigation-only-grade-equivalent",
    gradeEquivalentLabel: "Grade 9-equivalent learning band",
    reviewNote:
      "Provisional learner-navigation band only; not a separate qualification or syllabus. Verify the applicable current syllabus and confirm this band is useful before release.",
  }),
  pathway({
    id: "cambridge-igcse-fle-band-10",
    programmeCode: "cambridge-igcse",
    programmeName: "Cambridge IGCSE",
    courseCode: "cambridge-igcse-first-language-english",
    courseName: "First Language English",
    levelCode: "grade-10-equivalent-band",
    levelLabel: "Grade 10-equivalent learning band",
    levelKind: "navigation-only-grade-equivalent",
    gradeEquivalentLabel: "Grade 10-equivalent learning band",
    reviewNote:
      "Provisional learner-navigation band only; not a separate qualification or syllabus. Verify the applicable current syllabus and confirm this band is useful before release.",
  }),
];

/** Useful to screens and tests that need a stable pathway lookup. */
export function findEnglishPathway(pathwayId: string): CurriculumPathway | undefined {
  return englishPathways.find((item) => item.id === pathwayId);
}
