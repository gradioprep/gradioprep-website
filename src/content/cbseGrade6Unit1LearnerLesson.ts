/**
 * Unreleased, learner-safe draft data for CBSE English Grade 6 Unit 1.
 *
 * Intentionally not imported by any UI route. This source has no answer key,
 * correct-answer flags, marking guide or teacher-only material. Keep teacher
 * guidance in docs/curriculum/CBSE_G6_UNIT_1_TEACHER_REVIEW_PACK.md.
 */
export const cbseGrade6Unit1LearnerLesson = {
  id: "cbse-english-g6-u1-the-red-marker",
  version: "1.0",
  releaseStatus: "draft-unreleased",
  curriculum: {
    programme: "CBSE",
    course: "English",
    level: "Grade 6",
    unitId: "cbse-english-g6-u1",
    syllabusEdition: null,
    mappingStatus: "unverified",
    officialObjectiveCodes: [],
    reviewNote:
      "Public-source-aligned independent practice draft. No exact official Grade 6 English objective descriptor was verified; do not assign an official code.",
  },
  title: "The Red Marker",
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
      "Along a forest path, the animals had tied a red marker to a post beside the stream. It showed the safest place to cross after rain. One morning, the marker was gone. Piku the parakeet noticed hoofprints near the post and guessed that the deer had pulled it away. Keshav the tortoise asked him to look more carefully. A narrow strip of red cloth was caught on a thorn under a low branch. It continued across the mud and curled around a fallen log. Behind the log, the marker had wrapped around a bush when a strong gust blew through the trees. Piku loosened the string and carried the marker back. He retied it higher on the post, then apologised to the deer for his guess. The animals placed a second marker beside the footpath. “A clue is not the same as proof,” Keshav reminded them. “Look for the whole story before you decide.”",
    rightsNote:
      "Written for this platform. It is not copied or adapted from an NCERT passage or a third-party story.",
  },
  tasks: [
    {
      id: "cbse-g6-u1-q1",
      kind: "multiple-choice",
      focus: "Find a direct clue",
      prompt:
        "Which detail helps the animals discover where the marker has gone?",
      options: [
        { id: "A", text: "The deer had walked near the post." },
        { id: "B", text: "A strip of red cloth led towards the fallen log." },
        { id: "C", text: "The marker was used after rain." },
        { id: "D", text: "The animals placed a second marker beside the footpath." },
      ],
      responseType: "single-choice",
    },
    {
      id: "cbse-g6-u1-q2",
      kind: "short-response",
      focus: "Explain an inference",
      prompt:
        "Why does Piku apologise to the deer? Use one detail from the passage to support your explanation.",
      responseType: "text",
      expectedLength: "2–3 sentences",
    },
    {
      id: "cbse-g6-u1-q3",
      kind: "sequence",
      focus: "Track event order",
      prompt: "Number the four events in the order they occur.",
      items: [
        "The marker is found wrapped around a bush.",
        "Piku notices hoofprints and makes a guess.",
        "Piku apologises to the deer and reties the marker.",
        "A strip of red cloth is traced past the thorn and fallen log.",
      ],
      responseType: "ordered-list",
    },
    {
      id: "cbse-g6-u1-q4",
      kind: "fill-in",
      focus: "Prepositions of location",
      prompt:
        "Complete the sentences with beside, under, across, around or behind. Use each word once.",
      items: [
        "The marker was tied to a post ___ the stream.",
        "The red cloth was caught on a thorn ___ a low branch.",
        "The strip continued ___ the mud.",
        "The cloth curled ___ a fallen log.",
        "The marker was found ___ the log.",
      ],
      responseType: "text",
    },
  ],
  exitTask: {
    id: "cbse-g6-u1-exit",
    prompt:
      "Write 50–70 words explaining how the animals found the marker and what Piku learned. Include one event-order word, at least two location prepositions from the passage, and one detail explaining why Piku changed his mind.",
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
