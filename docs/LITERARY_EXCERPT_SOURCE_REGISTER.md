# Literary Excerpt Source Register

**Version:** 1.0  
**Created:** 30 October 2026  
**Access:** Internal/private project record. Do not expose teacher-only source notes or unreleased assessment material to learners.  
**Authority:** `docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md` and `docs/TEACHER_PACK_AND_FEEDBACK_STANDARD.md`.

## 1. Purpose

This register records the exact public-domain source and excerpt used by every reading stimulus. It is the single lookup point for replacing a passage without redesigning the website, navigation, layout, learner/teacher data boundary or assessment architecture.

Use two identifiers:

- **Excerpt ID:** stable identifier for the location/role of an excerpt in a unit. Keep it when the passage is replaced.
- **Source ID:** identifies the exact public-domain work, edition/transcription and excerpt. Create a new Source ID whenever the work, edition or excerpt changes.

No new passage may be inserted until its Excerpt ID and completed source record are present here. Preserve old records and mark them replaced rather than deleting them.

## 2. Current legacy excerpts requiring migration

The rows below inventory the existing platform-original stimuli. They are not public-domain source records and must not be represented as having passed the new source check. Assign the public-domain Source ID during the sequential content revision.

| Excerpt ID | Track / unit | Existing passage or stimulus | Current source location | Current status | Required action |
|---|---|---|---|---|---|
| `EXC-IB-MYP-Y1-U1-MAIN` | IB MYP Language and Literature Year 1 Unit 1 | “At the edge of the field, the last bus sighed…” (v1 passage retained by v2 candidate) | `src/content/pilotLearnerLesson.ts`; v2 teacher pack `src/content/pilotLessonPack.ts` | Legacy platform-original; replacement required | Replace with a registered public-domain excerpt and update every passage-dependent question/answer. |
| `EXC-IB-MYP-Y1-U1-TRANSFER` | IB MYP Language and Literature Year 1 Unit 1 | “Shone silver…” transfer micro-extract in v2 teacher pack | `src/content/pilotLessonPack.ts` | Legacy platform-original; replacement required | Replace with a separately registered public-domain excerpt or remove the transfer task. |
| `EXC-CAM-LS-S7-U1-WARMUP` | Cambridge Lower Secondary English 0861 Stage 7 Unit 1 | “The map's corners fluttered…” warm-up mini-text | `docs/curriculum/CAMBRIDGE_LS_S7_UNIT_1_LEARNER_CONTENT.md` | Legacy platform-original; replacement required | Replace with a public-domain excerpt or recast as clearly instructional prose, not a reading stimulus. |
| `EXC-CAM-LS-S7-U1-MAIN` | Cambridge Lower Secondary English 0861 Stage 7 Unit 1 | “The Rain Gauge” passage | `docs/curriculum/CAMBRIDGE_LS_S7_UNIT_1_LEARNER_CONTENT.md` and teacher pack | Legacy platform-original; replacement required | Replace with a public-domain literary excerpt; rework dependent tasks, answers and feedback. |
| `EXC-CBSE-G6-U1-MAIN` | CBSE English Grade 6 Unit 1 | “The Turning Sign” passage | `docs/curriculum/CBSE_G6_UNIT_1_LEARNER_CONTENT.md` and learner-safe source data | Legacy platform-original; replacement required | Replace with a public-domain excerpt suited to the Grade 6 learning purpose; revise dependent questions and answer pack after IB and Cambridge revisions. |

**Audit note:** This is the initial known inventory based on identified learner/teacher files, not a certified exhaustive list. During each unit revision, inspect the complete learner file, teacher pack and data sources; add a row for every additional standalone passage, quotation or mini-extract discovered.

## 3. Required fields for each public-domain source record

| Field | Required entry |
|---|---|
| Source ID | Unique identifier, e.g. `SRC-IB-MYP-Y1-U1-001` |
| Excerpt ID | Stable placement ID from Section 2 or a new registered ID |
| Work | Exact work title |
| Author | Recognised writer's full name and relevant dates |
| Original language | Language in which the work was written |
| Publication details | First publication date/source and exact edition/transcription used |
| Edition / translation | Editor, translator, publisher/repository and date, if applicable; mark original text where appropriate |
| Source URL | Exact page for the work/version, not a search-result URL |
| Public-domain basis | Concise evidence and intended territory/territories checked, including India |
| Location | Chapter, section, stanza, poem, act/scene, paragraph or page |
| Excerpt anchor | Exact opening/closing words and any omitted lines; the unit content file stores the exact excerpt |
| Adaptation record | Punctuation, spelling, ellipses, brackets or formatting changes; default is no substantive modernisation |
| Intended use | Programme, course, level, unit, question IDs and skill |
| Suitability check | Style, syntax, semantic context, vocabulary, age/cultural suitability and intended task fit |
| Checked by / date | Responsible reviewer and date |
| Status | Candidate, verified, blocked, replaced or retired |
| Replacement history | Previous Source ID, reason and content version affected |

## 4. Quick source selection and quality workflow

1. Choose a recognised public-domain work likely to provide a good excerpt for the target skill and age band.
2. Check the exact work/edition and public-domain status for the intended territory. Check a translation separately. Use the simplest reliable primary or public-domain source record available.
3. Read enough surrounding context to ensure the excerpt is represented accurately and is stylistically, syntactically and semantically appropriate.
4. Record the exact location and Source ID here **before** adding it to the learner or teacher file.
5. Link every question and teacher-pack entry to the Excerpt ID/Source ID.
6. If a concern is reported later, replace the source while preserving the Excerpt ID; create a new Source ID, content version and updated passage-dependent answers.

This is a quick, proportionate selection check, not a demand for exhaustive literary/legal research. A source that is not clearly public domain or does not fit the learner/task should be rejected in favour of another. Modern translations, editions, annotations, transcriptions and images can carry separate rights even when the underlying work is public domain.

## 5. Future replacement guarantee

The source register is independent of application routes and components. Passage content is versioned data; questions refer to stable Excerpt IDs and question IDs, not page-layout or navigation details. Replacing a source must not require changes to site navigation, URL hierarchy, component design, account flows or assessment service contracts. Only the content, source record, question-specific answers and required review/version data should change.
