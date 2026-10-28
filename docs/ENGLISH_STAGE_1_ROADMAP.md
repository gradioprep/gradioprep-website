# English Stage 1 — Curriculum Roadmap

**Status:** Working roadmap. MYP Year 1 guide/implementation and Unit 1 v2 remain a separate content candidate with their own gates. Cambridge Stage 7 Unit 1 v1.3 has founder-confirmed review/approval; its officially evidenced mapping stays limited to 7Ri.03 for explicit-information items. Build checks #250/#251 and preview runs #19/#20 passed on the Cambridge preview branch. CBSE Grade 6 Unit 1 “The Turning Sign” learner-facing v1.0 has now been approved for the academic-content gate by the founder (28 October 2026). The NCERT Grade 6 English Bridge Month Programme supports partial alignment for narrative reading and event sequencing; no unit-specific CBSE code is assigned. PR #16 remains draft/unmerged and unreleased; its content data remains unimported in normal app routes. A controlled unlinked preview is now available in [PR #17](https://github.com/gradioprep/gradioprep-website/pull/17), deployed at [the hosted preview URL](https://pr-17-gradioprep-website.wandering-scene-1822.workers.dev/preview/cbse-grade-6/english/unit-1). Automated checks passed; manual hosted visual, keyboard/focus, screen-reader and zoom/reflow review remains next. This is not normal navigation or release.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`
**Purpose:** Turn the approved Stage 1 scope into a trackable production plan without claiming full syllabus coverage or inventing official curriculum mappings.

## 1. Rules that must not be broken

- IB MYP Language and Literature, Cambridge Lower Secondary English (0861), IB DP Language A: Language and Literature, and Cambridge IGCSE First Language English (0500 only) are distinct curriculum tracks. Do not merge their objectives into one generic “Grade 6–10 English” course.
- Grade equivalents are a navigation aid only. They are not a claim that a qualification or syllabus is officially defined by that school grade.
- Before an item is published, record the relevant programme, course, year/stage, syllabus edition (where applicable), skill objective, task type and review status.
- Verify mappings against the applicable official specification. Record the official URL, edition/code, date checked and reviewer. Do not invent objective codes or imply a syllabus edition has been checked when it has not.
- Stage 1 is a starter pathway, not exhaustive syllabus coverage. Quality and verified mapping take precedence over item counts.
- Apply docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md: use short platform-original passages/excerpts plus functional learning tasks; source longer passages and task stimuli such as images/posters/documents from verified public-domain or suitably open-licensed works. Record the source and intended-use rights before selecting/embedding the exact asset. Do not copy protected exam papers or paid materials without documented permission or a specific legal basis.
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

The standalone MYP Year 1 guide (`docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_YEAR_1_GUIDE.md`) and implementation structure (`docs/curriculum/IB_MYP_YEAR_1_PATHWAY_IMPLEMENTATION.md`) are founder-approved. The founder also approved the content of MYP Unit 1 v2 on 26 October 2026; it remains an unmerged candidate because the separate academic review, official objective/strand mapping, rights, accessibility/suitability and release gates remain open. **Checkpoint rule:** MYP v2 content approval permits the documented production rotation to advance but does not authorize release. The active unit is Cambridge Lower Secondary Stage 7 Unit 1 v1.3 in draft PR #12. AI-led curriculum/content review of v1.2 found three improvements and applied them to v1.3: a worked inference model, optional learner-facing vocabulary help, and item-specific scoring. The founder approved proceeding with further review/release checks on 26 October 2026. The exact-phrase rights screen and content-level accessibility/context preflight are recorded; formal rights/originality, human academic/suitability judgement, current full framework/version, UI accessibility and release checks remain open. Review the existing draft; do not duplicate it. Later-track draft files do not mean those checkpoints are complete.


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
2. Cambridge Lower Secondary English 0861 Stage 7 — active checkpoint: founder/academic-lead review of exact v1.3; AI-led academic-content review improvements are documented. The full current framework/version and codes beyond the limited 7Ri.03 explicit-information crosswalk remain unverified.
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

The guide/implementation approval checkpoint and founder content approval of MYP Unit 1 v2 are complete. PR #14 remains unmerged while separate academic review, current official mapping, rights, accessibility/suitability and release checks remain open; version 1's academic-review outcome does not transfer. Cambridge Lower Secondary Stage 7 Unit 1 is now the active draft QA checkpoint in PR #12. Its existing learner content, teacher pack and QA record are now version 1.3 after the academic-content review improvements; the exact v1.3 content has not been approved for release; its limited interface-test integration exists only in draft PR #15 and is not merged or deployed to production. Full current framework/version and objective mapping beyond the limited 7Ri.03 public cross-check remain unverified.


## 9. Binding Unit 1 rotation including CBSE — 26 October 2026

The approved production cohort is **IB MYP Language and Literature Year 1 Unit 1 → Cambridge Lower Secondary English 0861 Stage 7 Unit 1 → CBSE English Grade 6 Unit 1**. The cohort is an internal production grouping, not official curriculum equivalence. Cambridge Stage 7 is typically for ages 11–12 within Lower Secondary's broader age range, but school-grade alignment varies. The next comparable cohort is MYP Year 2 Unit 1 → Cambridge Stage 8 Unit 1 → CBSE Grade 7 Unit 1, followed by MYP Year 3 → Cambridge Stage 9 → CBSE Grade 8, subject to current-source checks and actual learner context. Finish Unit 1 across all approved in-scope levels before any Unit 2. If Stage 7 remains blocked by a required review gate, pause and report the blocker rather than skipping to CBSE Grade 6 or any older-level unit. Do not request school-account access to gated materials; document any unavailable official mapping as unresolved.

## 10. Stage 7 Unit 1 academic-content review outcome — 26 October 2026

AI-led review of v1.2 identified improvements in explicit instructional modelling, learner-facing vocabulary access and item-specific scoring. Draft v1.3 addresses these points. The review used the official Cambridge English 0861 subject page and public 7Ri.03 example for curriculum scope, and Education Endowment Foundation guidance only for pedagogy. This does not provide a human academic-review or learner-testing result. A controlled UI preview is now isolated in draft PR #15; automated build and 17/17 Chromium tests passed in GitHub Actions run #231. The remaining blockers include manual screen-reader, zoom/reflow, keyboard/focus and cross-browser assessment; human academic/age-suitability judgement; formal rights/originality clearance; and any current official framework/version verification legitimately available. Release approval remains separate. The hosted Cloudflare branch preview has not been verified, and no production deployment was performed.


## 11. Controlled preview UI test checkpoint — 26 October 2026

Founder authorisation was limited to integration on an isolated preview branch for interface accessibility testing. The code resides in [draft PR #15](https://github.com/gradioprep/gradioprep-website/pull/15), based on `main`, with the preview route `/preview/cambridge-lower-secondary/english/stage-7/unit-1` kept out of normal navigation. It renders the learner-facing v1.3 draft only; the teacher/editor answer pack is not imported into the client, and responses are not graded or persisted.

[GitHub Actions Build check #231](https://github.com/gradioprep/gradioprep-website/actions/runs/40308612925) succeeded on commit `841c26ab5f3c0bd24d32cc88d839af015353eff9`: the TypeScript/Vite build passed and all 17 Chromium tests passed (11 existing navigation tests plus six new preview tests). New checks cover draft-status rendering, keyboard operation of the skip link and disclosure, unique task-specific accessible names for all 14 textareas and programmatic question-prompt associations, narrow mobile overflow, clear-all behaviour for every temporary input and sampled text contrast. This is an automated technical checkpoint only. Manual accessibility checks, human academic/suitability judgement, formal rights clearance, current full framework/version and mapping, and explicit release approval remain unresolved. Do not treat the preview as student-ready and do not proceed to CBSE Grade 6 Unit 1 yet.


## Final controlled-preview accessibility regression run — 26 October 2026

The latest controlled preview test commit `841c26ab5f3c0bd24d32cc88d839af015353eff9` passed [GitHub Actions Build check #231](https://github.com/gradioprep/gradioprep-website/actions/runs/40308612925): TypeScript/Vite build successful and 17/17 Chromium tests passed. In addition to the prior checks, the skip link now moves keyboard focus onto the main content; the exit-check prompt is associated with its response field for assistive technology; and responsive reflow/overflow is tested at 320, 390, 768 and 1024 CSS-pixel widths. These are automated checks only. Manual screen-reader testing, broader focus-order, zoom/reflow and cross-browser review remain open, as do rights/originality, human suitability, current full Cambridge framework/version and objective mapping, and explicit release approval. No hosted Cloudflare branch preview or production deployment is claimed.

## Content-rights and Stage 7 gate update — 28 October 2026

Use docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md as the binding process for all tracks. The founder confirms that human review of Cambridge Stage 7 Unit 1 v1.3 is complete and approved. Its short original passage/tasks passed the internal originality/provenance screen after an initial phrase screen plus eight supplemental searches found no exact passage-level match in returned public results. Formal legal review is not a blanket requirement for such short original content when no specific rights concern is identified; do not describe this internal screen as a legal opinion.

For longer reading passages and image/poster/document-based tasks, use an exact public-domain or suitably open-licensed source and verify the intended use before selection/embedding. Remaining Stage 7 release gates are the current full Cambridge framework/version and further objective mapping, manual accessibility/hosted visual review, and explicit release approval. Historical earlier status notes above are retained as the record of earlier review states.


## Current decision — 28 October 2026

The founder confirms that the required Stage 7 Unit 1 verification and approval decisions were already given; do not repeat those requests. This closes the outstanding founder-approval checkpoint for the production sequence, but it does not justify adding Cambridge objective codes beyond those directly supported by the recorded source evidence. Stage 7 remains an isolated, unmerged interface preview until a separate code-release action is completed. Proceed with the next first-cohort item, CBSE English Grade 6 Unit 1, using the current *Poorvi* textbook context and official CIET activity page as sources. The new candidate must not copy NCERT textbook wording or assets, claim an unverified official objective map, or inherit Cambridge's review statuses.

## CBSE Grade 6 Unit 1 — initial draft completed, 28 October 2026

The unit candidate “The Turning Sign” is drafted with an original narrative, questions for direct information and inference, event sequencing, location-preposition practice and a short independent retelling. It is informed by NCERT/CIET public source context but does not reproduce any *Poorvi* passage, exercise, image or screenshot. The official CBSE objective mapping remains unverified. The teacher/editor answer guidance is separate from the learner-safe source data; the latter is not imported into the client UI. The new content needs its own human content/suitability review and independent accessibility/release gates before any UI integration.


The initial draft was revised before review after a supplementary phrase/image-pattern query surfaced avoidable overlap with generic wording and a red-cloth/thorn motif. The current narrative is “The Turning Sign”; see the QA/provenance record for the transparent history and limited re-screen. Its status remains draft/unapproved/unreleased.


**Narrative provenance refinement — 28 October 2026:** The currently proposed Grade 6 unit is “The Turning Sign.” Its earlier wording and clue image were revised before review after a supplementary search, and the updated QA record reports the finding and limited re-screen. The draft remains in PR [#16](https://github.com/gradioprep/gradioprep-website/pull/16), with no UI integration or release.

## Current CBSE Grade 6 Unit 1 decision — 28 October 2026

Learner-facing v1.0 “The Turning Sign” is approved for the academic-content gate. NCERT's Grade 6 English Bridge Month Programme (English R2, first edition April 2024) supports limited alignment for reading a story, identifying main ideas/characters/events and sequencing; CIET's activity list supports contextual focus on location prepositions. No official CBSE objective code is assigned, and the exact current *Poorvi* reprint remains unverified.

The controlled, unlinked preview for accessibility and interface testing is implemented in draft PR #17 and deployed at [the hosted preview URL](https://pr-17-gradioprep-website.wandering-scene-1822.workers.dev/preview/cbse-grade-6/english/unit-1). Build check #256 passed 20/20 Chromium tests; controlled preview run #22 succeeded. Next: manual hosted visual, keyboard/focus, screen-reader, zoom/reflow and cross-browser review. Keep the teacher pack out of learner bundles, keep the route out of normal navigation, and do not release without a separate decision.
