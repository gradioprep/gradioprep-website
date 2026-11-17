import type { CurriculumPathway, PlannedUnitSlot, UnitSequence } from "./model";

const unitSequences: readonly UnitSequence[] = [1, 2, 3];

/** Broad language-learning themes for pathway exploration, not official board
 * unit titles or syllabus mappings. Formal assessments use separately verified
 * route-specific academic records and release controls. */
const unitThemes: Record<UnitSequence, {
  title: string; summary: string; insights: readonly [string, string];
}> = {
  1: {
    title: "Reading with evidence",
    summary: "This unit explores how to recognise central ideas, follow supporting details and explain a reading with evidence from the text.",
    insights: [
      "Find the details that give an idea its meaning.",
      "Use a precise example from the text to support your interpretation.",
    ],
  },
  2: {
    title: "Exploring perspectives",
    summary: "This unit explores how viewpoint, word choice and structure influence the ways readers understand different texts.",
    insights: [
      "Notice whose perspective shapes the text and what it emphasises.",
      "Compare language and structural choices across different viewpoints.",
    ],
  },
  3: {
    title: "Writing for an audience",
    summary: "This unit explores how to choose ideas, organise a response and refine language for a particular purpose and reader.",
    insights: [
      "Plan an opening and a clear sequence of ideas for your reader.",
      "Revisit vocabulary and sentence choices to make the intended effect clearer.",
    ],
  },
};

function plannedUnitSlots(pathwayId: string): PlannedUnitSlot[] {
  return unitSequences.map((sequence) => {
    const isFirstUnit = pathwayId === "ib-myp-lal-y1" && sequence === 1;
    const theme = unitThemes[sequence];
    return {
      id: `${pathwayId}-u${sequence}`,
      pathwayId,
      sequence,
      title: isFirstUnit ? "How writers shape meaning" : theme.title,
      summary: isFirstUnit
        ? "This unit explores how writers shape meaning and mood through word and sentence choices, and how readers explain these effects with evidence."
        : theme.summary,
      insights: theme.insights,
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
