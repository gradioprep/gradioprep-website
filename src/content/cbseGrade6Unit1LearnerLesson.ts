/**
 * Unreleased, learner-safe draft data for CBSE English Grade 6 Unit 1.
 *
 * Imported only by CbseGrade6Unit1Preview for controlled interface testing. This source has no answer key,
 * correct-answer flags, marking guide or teacher-only material. Keep teacher
 * guidance in docs/curriculum/CBSE_G6_UNIT_1_TEACHER_REVIEW_PACK.md.
 */
export const cbseGrade6Unit1LearnerLesson = {
  id: "cbse-english-g6-u1-the-turning-sign",
  version: "1.0",
  releaseStatus: "draft-unreleased",
  curriculum: {
    programme: "CBSE",
    course: "English",
    level: "Grade 6",
    unitId: "cbse-english-g6-u1",
    syllabusEdition: null,
    mappingStatus: "partial-source-alignment-code-unverified",
    officialObjectiveCodes: [],
    reviewNote:
      "Partial source alignment to NCERT Grade 6 English Bridge Month Programme (English R2, first edition April 2024) for narrative reading and event sequencing. No unit-specific official CBSE objective code is assigned; current Poorvi reprint remains unverified.",
  },
  title: "The Turning Sign",
  estimatedMinutes: 35,
  sourceContext: {
    textbookTitle: "Poorvi",
    chapterContext: "Fables and Folk Tales",
    sourceScope:
      "Official NCERT/CIET public pages were checked for textbook and activity context only. No textbook passage, exercise, illustration or page image is reproduced.",
    references: [
      "https://www.ncert.nic.in/pdf/announcement/NCERT-Advisory-for-Schools.pdf",
      "https://www.ciet.ncert.gov.in/activity/grade6?lang=en",
      "https://ncert.nic.in/textbook.php",
      "https://ncert.nic.in/pdf/Bridge_Month_Program/Grade6/BMP_Grade-6-English%28R2%29.pdf",
    ],
  },
  learningGoals: [
    "Identify the main problem, key events and resolution in a short narrative.",
    "Select a relevant detail and explain what it suggests, distinguishing a clue from a proven conclusion.",
    "Use prepositions of location accurately when describing where an event or object occurs.",
    "Retell the solution in a clear sequence using textual evidence and precise location words.",
  ],
  passage: {
    label: "Original practice passage",
    text:
      "Each morning, the animals followed a narrow trail from the hill to a pool. At a fork stood a wooden arrow showing the path that stayed dry after rain. One evening, a gust turned the arrow toward the steep bank. Lali the langur noticed hoofprints near the post and guessed that the deer had pushed it. Naren the tortoise asked her to examine the ground before deciding. Beside the post, they found a fresh scrape in the soil. It continued down the slope to a loose wooden wedge lying behind a broad root. A fallen branch had knocked the wedge from its slot, leaving the arrow free to turn in the wind. Lali set the wedge back and pointed the arrow toward the safe path. She apologised to the deer. The animals placed two flat stones beside the post, so anyone could see where its base belonged. Naren reminded them, “Hoofprints show that a deer passed here; they do not explain who moved the sign.”",
    rightsNote:
      "Written for this platform. It is not copied or adapted from an NCERT passage or a third-party story.",
  },
  tasks: [
    {
      id: "cbse-g6-u1-q1",
      kind: "multiple-choice",
      focus: "Find a direct clue",
      prompt: "Which detail helps explain why the arrow turned?",
      options: [
        { id: "A", text: "The deer had walked near the post." },
        { id: "B", text: "A loose wooden wedge lay behind a broad root." },
        { id: "C", text: "The arrow showed the route that stayed dry after rain." },
        { id: "D", text: "The animals placed two flat stones beside the post." },
      ],
      responseType: "single-choice",
    },
    {
      id: "cbse-g6-u1-q2",
      kind: "short-response",
      focus: "Explain an inference",
      prompt:
        "Why does Lali apologise to the deer? Use one detail from the passage to support your explanation.",
      responseType: "text",
      expectedLength: "2–3 sentences",
    },
    {
      id: "cbse-g6-u1-q3",
      kind: "sequence",
      focus: "Track event order",
      prompt: "Number the four events in the order they occur.",
      items: [
        "The loose wooden wedge is found behind a broad root.",
        "Lali notices hoofprints and makes a guess.",
        "Lali apologises to the deer and resets the arrow.",
        "A scrape in the soil leads down the slope to the loose wedge.",
      ],
      responseType: "ordered-list",
    },
    {
      id: "cbse-g6-u1-q4",
      kind: "fill-in",
      focus: "Prepositions of location",
      prompt:
        "Complete the sentences with at, near, down, behind or beside. Use each word once.",
      items: [
        "The wooden arrow stood ___ a fork in the trail.",
        "The hoofprints were ___ the post.",
        "The scrape continued ___ the slope.",
        "The loose wedge lay ___ a broad root.",
        "The flat stones were placed ___ the post.",
      ],
      responseType: "text",
    },
  ],
  exitTask: {
    id: "cbse-g6-u1-exit",
    prompt:
      "Write 50–70 words explaining how the animals found out why the arrow turned and what Lali learned. Include one event-order word, at least two location prepositions from the passage, and one detail explaining why Lali changed her mind.",
    responseType: "text",
  },
  supportNotes: [
    "Read the passage as selectable text.",
    "Use sequence words and location-word banks as scaffolds if needed.",
    "Accept more than one reasonable inference when it is supported by the passage.",
    "Do not use colour alone to mark a response or identify a clue.",
  ],
  visualAssets: [],
} as const;
