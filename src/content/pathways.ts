import type { CurriculumPathway, PlannedUnitSlot, UnitSequence } from "./model";

const unitSequences: readonly UnitSequence[] = [1, 2, 3];

function plannedUnitSlots(pathwayId: string): PlannedUnitSlot[] {
  return unitSequences.map((sequence) => {
    const isFirstUnit = pathwayId === "ib-myp-lal-y1" && sequence === 1;
    return {
      id: `${pathwayId}-u${sequence}`,
      pathwayId,
      sequence,
      title: isFirstUnit ? "How writers shape meaning" : "Your next unit is being prepared",
    };
  });
}

function pathway(
  entry: Omit<CurriculumPathway, "unitSlots">
): CurriculumPathway {
  return {
    ...entry,
    unitSlots: plannedUnitSlots(entry.id),
  };
}

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
  }),
];

/** Look up a course pathway by its stable identifier. */
export function findEnglishPathway(pathwayId: string): CurriculumPathway | undefined {
  return englishPathways.find((item) => item.id === pathwayId);
}
