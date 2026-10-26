# English Stage 1 — Curriculum Roadmap

**Status:** Working roadmap. MYP Year 1 guide v1.1 and implementation structure v1.1 were approved on 26 October 2026. The founder approved the content of Unit 1 version 2 on 26 October 2026; it remains an unmerged candidate in draft PR #14. Separate academic review, official objective/strand mapping, full rights, accessibility/age-level suitability and release gates remain open. The next active production checkpoint is the existing Cambridge Lower Secondary English 0861 Stage 7 Unit 1 draft in PR #12. The documented six-unit MYP plan does not mean the application's current 10-entry catalogue or six MYP unit routes are implemented.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`
**Purpose:** Turn the approved Stage 1 scope into a trackable production plan without claiming full syllabus coverage or inventing official curriculum mappings.

## 1. Rules that must not be broken

- IB MYP Language and Literature, Cambridge Lower Secondary English (0861), IB DP Language A: Language and Literature, and Cambridge IGCSE First Language English (0500 only) are distinct curriculum tracks. Do not merge their objectives into one generic “Grade 6–10 English” course.
- Grade equivalents are a navigation aid only. They are not a claim that a qualification or syllabus is officially defined by that school grade.
- Before an item is published, record the relevant programme, course, year/stage, syllabus edition (where applicable), skill objective, task type and review status.
- Verify mappings against the applicable official specification. Record the official URL, edition/code, date checked and reviewer. Do not invent objective codes or imply a syllabus edition has been checked when it has not.
- Stage 1 is a starter pathway, not exhaustive syllabus coverage. Quality and verified mapping take precedence over item counts.
- All content must be original or used with appropriate rights. Do not copy protected examination papers or paid materials into the platform without permission.
- Every current screen example remains demonstration content until individually reviewed and approved.

## 2. Initial pathway register

The founder-confirmed planning scope is 12 level/pathway entries. The two IGCSE rows are learner-facing delivery bands under Cambridge IGCSE First Language English 0500, not separate official qualifications or separate syllabuses. The two DP rows are platform delivery years under the single selected DP course, not separate official DP syllabuses.

| Pathway ID | Programme / course | Learner-facing level | Initial unit slots | Mapping status |
|---|---|---|---:|---|
| `ib-myp-lal-y1` | IB MYP Language and Literature | Year 1 (approx. Grade 6 equivalent) | 3 | To verify |
| `ib-myp-lal-y2` | IB MYP Language and Literature | Year 2 (approx. Grade 7 equivalent) | 3 | To verify |
| `ib-myp-lal-y3` | IB MYP Language and Literature | Year 3 (approx. Grade 8 equivalent) | 3 | To verify |
| `ib-myp-lal-y4` | IB MYP Language and Literature | Year 4 (approx. Grade 9 equivalent) | 3 | To verify |
| `ib-myp-lal-y5` | IB MYP Language and Literature | Year 5 (approx. Grade 10 equivalent) | 3 | To verify |
| `cambridge-ls-english-s7` | Cambridge Lower Secondary English | Stage 7 | 3 | To verify |
| `cambridge-ls-english-s8` | Cambridge Lower Secondary English | Stage 8 | 3 | To verify |
| `cambridge-ls-english-s9` | Cambridge Lower Secondary English (0861) | Stage 9 | 3 | Current official framework/objectives to verify |
| `ib-dp-langlit-y1` | IB DP Language A: Language and Literature | Year 1 delivery chapter | 3 | Scope confirmed; current course guide and local sequence to verify |
| `ib-dp-langlit-y2` | IB DP Language A: Language and Literature | Year 2 delivery chapter | 3 | Scope confirmed; current course guide and local sequence to verify |
| `cambridge-igcse-fle-band-9` | Cambridge IGCSE First Language English 0500 only | Grade 9-equivalent delivery band | 3 | Scope confirmed; exam-year syllabus, component/route and mapping to verify |
| `cambridge-igcse-fle-band-10` | Cambridge IGCSE First Language English 0500 only | Grade 10-equivalent delivery band | 3 | Scope confirmed; use applicable 0500 syllabus unless verified route needs differ |

**Do not release the IGCSE rows as distinct syllabus tracks unless the academic lead confirms that the distinction is useful and correctly mapped.** They may share the same qualification syllabus while differing in the recommended sequence or readiness support.

## 3. Planning targets

These are production targets from the master brief, not promises of complete coverage:

| Measure | Initial target | Control |
|---|---:|---|
| Pathway entries | 12 | Keep official programme/course identity separate from delivery-year/band and grade-equivalent labels |
| Skill units | About 36 | About 3 per entry; final distribution may differ if academic review requires it |
| Original short-form practice items | About 360 | Each must have a learning purpose, answer/explanation or appropriate marking guidance, and review status |
| Extended-response tasks | About 36 | Each must have task instructions, expected response format, task-specific rubric/criteria and credit requirement if offered for human grading |
| Diagnostic | One per pathway | Use only after skill mapping and scoring/recommendation rules are approved |
| Annotated example(s) | At least one per pathway | Clearly link the example to a verified objective or mark it as general introductory material pending mapping |
| Common mistakes and next steps | For each released unit | Must lead to a relevant skill or task, not a generic link |

Treat these counts as a planning baseline. Do not create filler items to hit a quota.

## 4. Unit planning sheet

Create three unit records for each pathway in the register. Initially, use the identifiers `<pathway-id>-u1`, `<pathway-id>-u2` and `<pathway-id>-u3`. The following fields must remain **unapproved/blank** until academic review; the identifier does not imply a confirmed skill focus.

| Field | Required decision or record |
|---|---|
| Unit title | Clear learner-facing title after content is selected |
| Learning objective | Specific, assessable skill written in original language |
| Official mapping | Objective/reference from the applicable verified specification, or an explicit “general/unmapped introductory content” label |
| Prerequisites | Prior skills needed, where relevant |
| Teaching sequence | Explanation, worked/annotated example, guided practice and independent practice as appropriate |
| Question mix | Selected task types and difficulty progression |
| Common errors | Typical errors with corrective explanation |
| Exit check | Evidence that informs the next recommendation |
| Review record | Academic reviewer, review date, content version and decision |
| Release state | Planned, Draft, In review, Approved, Published or Retired |

The academic lead can choose the actual unit focuses and their order after reviewing the official specifications. This document deliberately does not assign generic skills to official syllabus objectives.

## 5. Required fields for each content item

Every lesson, practice question, diagnostic item and extended-response task should carry:

- Stable content ID and version.
- Programme, course, pathway/year or stage, and applicable syllabus edition.
- One or more skill objective mappings, each with its own verification/review state.
- Content type and response type.
- Learner-facing title, instructions and body/prompt.
- Expected time where useful.
- Answer key and explanation for automatically checked items, or task-specific marking guidance/rubric for extended responses.
- Author, reviewer, review date, review notes and publication state.
- Rights/source note for any quoted or adapted material.
- Related prerequisites and next-step links only when those relationships have been reviewed.

Keep the answer key separate from learner-visible prompt content in the future application. Do not ship production answer keys to an unrestricted frontend bundle.

## 6. Content review and release gates

1. **Planned:** pathway/unit slot exists; no syllabus claim is made.
2. **Draft:** content authored; not visible as released learning material.
3. **Academic review:** verify accuracy, age/level suitability, objective mapping, difficulty, originality/rights and explanations.
4. **Approved:** reviewer records approval against the exact content version and syllabus mapping.
5. **Published:** only approved version is available to its intended audience.
6. **Retired:** hidden from new discovery but retained for audit/history where learner records depend on it.

A material edit to a published question, answer, rubric or syllabus mapping creates a new version and triggers review again. Existing attempts and assessments must retain the exact content/rubric version used at that time.

## 7. Acceptance checklist before the first pathway is released

- [ ] Academic lead selected the three unit focuses and sequence for this pathway.
- [ ] Applicable official specification and edition were checked and recorded.
- [ ] Each syllabus mapping is defensible and reviewed; unmapped general content is labelled honestly.
- [ ] The pathway is clearly labelled as Stage 1 starter content, not complete syllabus coverage.
- [ ] Lesson, example, question, answer/explanation and next step align.
- [ ] Extended-response tasks include their own task-specific rubric and explicit credit scope before submission.
- [ ] Content is original or has a recorded, appropriate rights basis.
- [ ] Accessibility, readability and responsive presentation were checked.
- [ ] All content states and versions are recorded; unreleased items do not appear as available.
- [ ] A final academic-lead approval is recorded.

## 8. Implementation status and immediate next action

**Change control:** Approved/reviewed units, features and documentation remain revisable at any later date. Track a version and rationale, update dependent documents, and repeat affected review gates for material changes.

The current prototype's typed catalogue at `src/content/pathways.ts` still contains 10 planned pathways and three slots per pathway. The newly approved documentation scope now plans 12 entries; do not claim the catalogue or deployed route register has already been expanded. Update the code/data catalogue only after the curriculum guide and pathway implementation plan have been reviewed and the official mapping gates are respected. The first IB MYP Year 1 pilot, **How writers shape meaning**, has a teacher/editor unit brief (`src/content/pilotUnitDraft.ts`), a learner-safe lesson source (`src/content/pilotLearnerLesson.ts`), an answer-free Pathways summary (`src/content/pilotReviewSummary.ts`) and a separate teacher/editor answer source (`src/content/pilotLessonPack.ts`). Academic content review for pilot-preview version 1 passed, as confirmed by the project owner on 24 October 2026. The Lesson screen is interactive: learners can select a choice, draft written answers and check success indicators. The preview does not score or persist responses.

The teacher/editor brief and answer guide are not imported into the client module graph; the client uses only the learner-safe lesson and non-answer review summary. This is adequate source separation for a static preview but is not production authorization. Real answer keys must be served only through a protected server-side path.

The detailed official IB guide edition and objective mapping remain unverified. The official [MYP Language and Literature page](https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/) links a public subject brief marked “From 2014”; the indexed detailed guide ([Language and literature guide](https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf)) redirects to IB sign-in from this environment. Use the authenticated [Programme Resource Centre](https://resources.ibo.org/), search the exact guide title under MYP/English, and check its publication metadata plus “Updates to the publication.” If access is unavailable, ask an MYP coordinator/school librarian or check the [IB Store](https://store.ibo.org/). Do not use the public brief alone or a search crawl date to claim that the detailed edition is current. The previously surfaced candidate Criterion A strand references A(ii) and A(iii) are not verified mappings and must not be used as official objective codes or attached to the pilot. The static readiness fixture now records the reviewed lesson and practice IDs, answer-key review and academic-review pass. Rights review, accessibility review and explicit release approval remain separate outstanding gates. Therefore the unit is **approved for pilot preview only**, not a released syllabus-mapped course.

The standalone MYP Year 1 guide (`docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_YEAR_1_GUIDE.md`) and its implementation structure (`docs/curriculum/IB_MYP_YEAR_1_PATHWAY_IMPLEMENTATION.md`) are complete for the public-source workflow and await founder review. No official Year 1 objective/strand mapping is claimed. **Checkpoint rule:** do not begin or revise Unit 1 as curriculum production until the founder approves this guide and implementation structure. The existing “How writers shape meaning” preview is not a new implementation and remains preview-only; after approval, review/adapt that existing version rather than duplicate it. Only after Unit 1 is implemented and approved should the rotation continue to Cambridge Lower Secondary Stage 7 guide, then DP Language A: Language and Literature Year 1, then Cambridge IGCSE 0500's first approved delivery band. Existing later-track draft files do not mean those later guide checkpoints are complete. Rights, accessibility and release approval remain separate.


## 9. Curriculum guide and rotating unit-production policy

The shared research and quality rubric is maintained in `docs/ENGLISH_CURRICULUM_RESEARCH_AND_DESIGN_STANDARD.md`; the verified public source and sample-paper protocol is `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md`; year/stage guide architecture and rotation are in `docs/ENGLISH_CURRICULUM_GUIDES.md`; the public-framework-aligned MYP Year 1 guide and pathway plan are `docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_YEAR_1_GUIDE.md` and `docs/curriculum/IB_MYP_YEAR_1_PATHWAY_IMPLEMENTATION.md`.

The founder's production rule is to create **one unit at a time across curriculum tracks**, not to complete an entire curricular group first. Initial order:
1. IB MYP Language and Literature Year 1 — Unit 1.
2. Cambridge Lower Secondary English (0861) Stage 7 — Unit 1.
3. IB DP Language A: Language and Literature Year 1 — Unit 1.
4. Cambridge IGCSE First Language English 0500 — first approved delivery band, Unit 1.
5. IB MYP Year 2 — Unit 1.
6. Cambridge Lower Secondary Stage 8 — Unit 1.
7. IB DP Language A: Language and Literature Year 2 — Unit 1.
8. Cambridge Lower Secondary Stage 9 — Unit 1.
9. Cambridge IGCSE 0500 — next approved delivery band, Unit 1.
10. IB MYP Year 3 — Unit 1.
11. IB MYP Year 4 — Unit 1.
12. IB MYP Year 5 — Unit 1.

Then continue across the approved tracks for Unit 2, then Unit 3. The exact order after these initial slots may be revised only through a recorded decision. DP and IGCSE units are blocked until their current official guide/syllabus and school/exam-year sequence are verified. A blocked slot stays blocked; no invented content or mapping may be substituted merely to preserve rotation.


## 10. Public-source method and curriculum guide rotation

Use `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md` as the source selection/currency gate. It sets five core source families and requires exact course, edition/session, paper type, access and rights checks. Do not select a worksheet or exam paper merely because it is easy to download. For Cambridge 0500 exams 2027–2029, prefer the current official syllabus and specimen/mark-scheme set; older papers require an item-level comparison. For DP Language A: Language and Literature, use public current IB course/examiner information and cross-check with specialist sites; do not mislabel Language A: Literature papers as Language and Literature specimens. For MYP, use the public six-skill framework and school-based assessment description to create original tasks; official Year 1 objective/strand codes stay blank if not verifiable.

Guide creation order, before rotating unit-content production:
1. IB MYP Language and Literature Year 1 — guide/implementation structure and Unit 1 v2 content approved by the founder; separate academic review, official objective/strand mapping, rights, accessibility/suitability and release gates remain open.
2. Cambridge Lower Secondary English 0861 Stage 7 — active next checkpoint: verify the framework source, review/correct the existing Unit 1 draft, and record the limited 7Ri.03 public crosswalk without overclaiming a full official map.
3. IB DP Language A: Language and Literature Year 1 — use public course and current examiner guidance; identify any criterion/version updates.
4. Cambridge IGCSE First Language English 0500 — syllabus-wide guide anchored to Version 1 for 2027–2029; record component/route and exam year.
5. IB MYP Year 2.
6. Cambridge Lower Secondary Stage 8.
7. IB DP Language A: Language and Literature Year 2.
8. Cambridge Lower Secondary Stage 9.
9. Cambridge IGCSE 0500 second proposed delivery band (same syllabus, not a separate qualification).
10. IB MYP Year 3.
11. IB MYP Year 4.
12. IB MYP Year 5.

This is an editorial production order, not an official IB/Cambridge unit order. When each guide cycle is complete, rotate unit-content production through the same track order rather than completing one programme group first. A source-access gap must be recorded—not filled with invented official mapping.


## MYP Year 1 research revision — 26 October 2026

Version 1.1 of the guide replaces the initial three-unit sketch with six proposed units plus shared diagnostic, language support, retrieval, revision and transfer time for a planned total of at least 50 teaching hours. Research now includes MYP-specific teaching/publisher/planning resources and a separate landscape review. The 2014/15 detailed IB guide is used only as a labelled legacy crosswalk; its continued current applicability is not confirmed. Enhanced MYP beta material remains a separate transition watch.

The guide/implementation approval checkpoint is complete. Unit 1 version 2 now adapts rather than duplicates the existing preview. The draft preview implementation is in PR #14; it is not merged into main or deployed to production, and it does not inherit version 1's approval. The founder must review/approve this exact version before Cambridge Lower Secondary Stage 7 becomes active.
