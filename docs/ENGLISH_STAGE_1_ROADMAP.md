# English Stage 1 — Curriculum Roadmap

**Status:** Current work is governed by `docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md`: Grade 9 IB MYP first (Grade 9 = MYP Year 4 confirmed by the Founder), then Cambridge Grade 6 (exact stage/course to be verified; do not substitute Stage 7). Cycle 1 provider research, taxonomy/high-level blueprint, detailed task-level item map, flagship PDF-response/grading/timed-analytics plan, 24-hour SLA and Phase 0 architecture/timer/retention/provider decisions are Founder-approved; Phase 0 is complete. The Phase 1 secure-foundation implementation specification is recorded at `docs/PHASE_1_SECURE_APPLICATION_FOUNDATION_IMPLEMENTATION_SPEC.md`; Phase 1B local synthetic-only coding is Founder-approved and underway in draft PR #22. Its initial Auth/Worker API/role slice passed exact-head CI run #41473237444 on code-bearing commit `50f4bb3`, including RLS and 15/15 Chromium tests. The next local synthetic-only increment adds suspended-account fail-closed RLS/Worker/UI handling; its exact-head verification and Preview refresh are pending. Hosted provisioning, paid services, real learner data, merge, production deployment and later checkpoints still require separate approval. Actual MYP item authoring follows feature implementation and pilot validation. The approved timer is advisory/no learner pause or hard stop, with responses preserved at zero; approved data retention and external-processing gates are in `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`. Existing content queues remain preserved/deferred; Cambridge Grade 6 remains blocked until Cycle 1 is complete and the Founder directs transition. No merge, production deployment or release is authorised.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`
**Purpose:** Turn the approved Stage 1 scope into a trackable production plan without claiming full syllabus coverage or inventing official curriculum mappings.
**Mandatory next content gate:** After the Cycle 1 diagnostic and evaluation report/analytics are complete and checked, carry out the whole-website learner-facing copy cleanup in Section 20 before creating any remedial content.

## 1. Rules that must not be broken

- IB MYP Language and Literature, Cambridge Lower Secondary English (0861), IB DP Language A: Language and Literature, and Cambridge IGCSE First Language English (0500 only) are distinct curriculum tracks. Do not merge their objectives into one generic “Grade 6–10 English” course.
- Grade equivalents are a navigation aid only. They are not a claim that a qualification or syllabus is officially defined by that school grade.
- Before an item is published, record the relevant programme, course, year/stage, syllabus edition (where applicable), skill objective, task type and review status.
- Verify mappings against the applicable official specification. Record the official URL, edition/code, date checked and reviewer. Do not invent objective codes or imply a syllabus edition has been checked when it has not.
- Stage 1 is a starter pathway, not exhaustive syllabus coverage. Quality and verified mapping take precedence over item counts.
- Apply docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md v2.1: project-original passage bodies up to and including 250 words are allowed; passage bodies over 250 words must be from a recognised writer's verified public-domain work. Existing qualifying short originals may remain. Record every passage with an Excerpt ID and the correct short-original provenance or long-public-domain source record. This does not permit reuse of third-party copyrighted text based only on length. Preserve the separate stricter visual/photo rights controls.
- Apply docs/TEACHER_PACK_AND_FEEDBACK_STANDARD.md v1.3: every typed response has its existing/approved response range plus an ideal target and a real-time current/ideal counter; the target never limits text entry.
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

## 8. Historical implementation status and immediate next action (superseded 31 October 2026)

**Change control:** Approved/reviewed units, features and documentation remain revisable at any later date. Track a version and rationale, update dependent documents, and repeat affected review gates for material changes.

The current prototype's typed catalogue at `src/content/pathways.ts` still contains 10 planned pathways and three slots per pathway. The newly approved documentation scope now plans 12 entries; do not claim the catalogue or deployed route register has already been expanded. Update the code/data catalogue only after the curriculum guide and pathway implementation plan have been reviewed and the official mapping gates are respected. The first IB MYP Year 1 pilot, **How writers shape meaning**, has a teacher/editor unit brief (`src/content/pilotUnitDraft.ts`), a learner-safe lesson source (`src/content/pilotLearnerLesson.ts`), an answer-free Pathways summary (`src/content/pilotReviewSummary.ts`) and a separate teacher/editor answer source (`src/content/pilotLessonPack.ts`). Academic content review for pilot-preview version 1 passed, as confirmed by the project owner on 24 October 2026. The Lesson screen is interactive: learners can select a choice, draft written answers and check success indicators. The preview does not score or persist responses.

The teacher/editor brief and answer guide are not imported into the client module graph; the client uses only the learner-safe lesson and non-answer review summary. This is adequate source separation for a static preview but is not production authorization. Real answer keys must be served only through a protected server-side path.

The detailed official IB guide edition and objective mapping remain unverified. The official [MYP Language and Literature page](https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/) links a public subject brief marked “From 2014”; the indexed detailed guide ([Language and literature guide](https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf)) redirects to IB sign-in from this environment. Use the authenticated [Programme Resource Centre](https://resources.ibo.org/), search the exact guide title under MYP/English, and check its publication metadata plus “Updates to the publication.” If access is unavailable, ask an MYP coordinator/school librarian or check the [IB Store](https://store.ibo.org/). Do not use the public brief alone or a search crawl date to claim that the detailed edition is current. The previously surfaced candidate Criterion A strand references A(ii) and A(iii) are not verified mappings and must not be used as official objective codes or attached to the pilot. The static readiness fixture now records the reviewed lesson and practice IDs, answer-key review and academic-review pass. Rights review, accessibility review and explicit release approval remain separate outstanding gates. Therefore the unit is **approved for pilot preview only**, not a released syllabus-mapped course.

The standalone MYP Year 1 guide (`docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_YEAR_1_GUIDE.md`) and implementation structure (`docs/curriculum/IB_MYP_YEAR_1_PATHWAY_IMPLEMENTATION.md`) are founder-approved. The founder also approved the content of MYP Unit 1 v2 on 26 October 2026; it remains an unmerged candidate because the separate academic review, official objective/strand mapping, rights, accessibility/suitability and release gates remain open. **Checkpoint rule:** MYP v2 content approval permits the documented production rotation to advance but does not authorize release. The active unit is Cambridge Lower Secondary Stage 7 Unit 1 v1.3 in draft PR #12. AI-led curriculum/content review of v1.2 found three improvements and applied them to v1.3: a worked inference model, optional learner-facing vocabulary help, and item-specific scoring. The founder approved proceeding with further review/release checks on 26 October 2026. The exact-phrase rights screen and content-level accessibility/context preflight are recorded; formal rights/originality, human academic/suitability judgement, current full framework/version, UI accessibility and release checks remain open. Review the existing draft; do not duplicate it. Later-track draft files do not mean those checkpoints are complete.


## 9. Historical curriculum guide and rotating unit-production policy (superseded 31 October 2026)

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


## 10. Public-source method and historical curriculum guide order (deferred)

Use `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md` as the shared source/currency register and `docs/IB_CAMBRIDGE_CURRICULUM_RESEARCH_WORKFLOW.md` Section 2A for the mandatory ranked Top Five independent websites for every exact route. The shared cross-track starter set is not the route-specific Top Five. Record exact course, year/stage/grade, edition/session, paper/sample type, access, inspectable evidence and rights checks. Do not select a worksheet or exam paper merely because it is easy to download. For Cambridge 0500 exams 2027–2029, prefer the current official syllabus and specimen/mark-scheme set; older papers require an item-level comparison. For DP Language A: Language and Literature, use public current IB course/examiner information and cross-check with specialist sites; do not mislabel Language A: Literature papers as Language and Literature specimens. For MYP, use the public six-skill framework and school-based assessment description to create original tasks; official Year 1 objective/strand codes stay blank if not verifiable.

**Historical guide-creation order only — no guide or unit production from this list is active during the diagnostic cycles.** The public-source method above remains binding when curriculum content work resumes, but the founder will set the next content order after both readiness cycles. Former guide order:
1. IB MYP Language and Literature Year 1 — guide/implementation structure and Unit 1 v4 exact content, human academic review and age/level/context suitability are now founder-approved. Official mapping, rights/territory, visual context, manual accessibility and release gates remain open; all further Year 1 unit work is deferred.
2. Cambridge Lower Secondary English 0861 Stage 7 — historical checkpoint: exact v1.3 founder-confirmed review and curriculum-content Top Five are complete; full framework/version and codes beyond 7Ri.03 remain unverified. Stage 7 pack/counter migration is deferred; Stage 7 is not the requested Cambridge Grade 6 diagnostic cycle.
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


## Historical MYP Year 1 research revision — 26 October 2026

Version 1.1 of the guide replaces the initial three-unit sketch with six proposed units plus shared diagnostic, language support, retrieval, revision and transfer time for a planned total of at least 50 teaching hours. Research now includes MYP-specific teaching/publisher/planning resources and a separate landscape review. The 2014/15 detailed IB guide is used only as a labelled legacy crosswalk; its continued current applicability is not confirmed. Enhanced MYP beta material remains a separate transition watch.

The guide/implementation approval checkpoint and founder content approval of MYP Unit 1 v2 are complete. PR #14 remains unmerged while separate academic review, current official mapping, rights, accessibility/suitability and release checks remain open; version 1's academic-review outcome does not transfer. Cambridge Lower Secondary Stage 7 Unit 1 is now the active draft QA checkpoint in PR #12. Its existing learner content, teacher pack and QA record are now version 1.3 after the academic-content review improvements; the exact v1.3 content has not been approved for release; its limited interface-test integration exists only in draft PR #15 and is not merged or deployed to production. Full current framework/version and objective mapping beyond the limited 7Ri.03 public cross-check remain unverified.


## 9. Historical Unit 1 rotation including CBSE — superseded 31 October 2026

**Historical queue only — do not execute while diagnostic cycles are active.** The former production cohort was **IB MYP Language and Literature Year 1 Unit 1 → Cambridge Lower Secondary English 0861 Stage 7 Unit 1 → CBSE English Grade 6 Unit 1**. The cohort is an internal production grouping, not official curriculum equivalence. Cambridge Stage 7 is typically for ages 11–12 within Lower Secondary's broader age range, but school-grade alignment varies. The former next comparable cohort was MYP Year 2 Unit 1 → Cambridge Stage 8 Unit 1 → CBSE Grade 7 Unit 1, followed by MYP Year 3 → Cambridge Stage 9 → CBSE Grade 8. This and the former Unit 2 rule are superseded; the founder will set the content order after the diagnostic cycles. If Stage 7 remains blocked by a required review gate, pause and report the blocker rather than skipping to CBSE Grade 6 or any older-level unit. Do not request school-account access to gated materials; document any unavailable official mapping as unresolved.

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

Historical next-step note — 28 October 2026 (superseded by the 30 October standards update): the earlier plan would have advanced directly from Stage 7 to CBSE Grade 6. The founder's new decision requires revising existing MYP Year 1 Unit 1 v2 teacher materials and excerpts first, then revising Cambridge Stage 7 Unit 1 v1.3 teacher materials and excerpts, and only then completing the CBSE Grade 6 Unit 1 teacher pack. Use the binding sequence in Section 12. The CBSE source checks and no-copy rules remain applicable.

## CBSE Grade 6 Unit 1 — initial draft completed, 28 October 2026

The unit candidate “The Turning Sign” is drafted with an original narrative, questions for direct information and inference, event sequencing, location-preposition practice and a short independent retelling. It is informed by NCERT/CIET public source context but does not reproduce any *Poorvi* passage, exercise, image or screenshot. The official CBSE objective mapping remains unverified. The teacher/editor answer guidance is separate from the learner-safe source data; the latter is not imported into the client UI. The new content needs its own human content/suitability review and independent accessibility/release gates before any UI integration.


The initial draft was revised before review after a supplementary phrase/image-pattern query surfaced avoidable overlap with generic wording and a red-cloth/thorn motif. The current narrative is “The Turning Sign”; see the QA/provenance record for the transparent history and limited re-screen. Its status remains draft/unapproved/unreleased.


**Narrative provenance refinement — 28 October 2026:** The currently proposed Grade 6 unit is “The Turning Sign.” Its earlier wording and clue image were revised before review after a supplementary search, and the updated QA record reports the finding and limited re-screen. The draft remains in PR [#16](https://github.com/gradioprep/gradioprep-website/pull/16), with no UI integration or release.

## Current CBSE Grade 6 Unit 1 decision — 28 October 2026

Learner-facing v1.0 “The Turning Sign” is approved for the academic-content gate. NCERT's Grade 6 English Bridge Month Programme (English R2, first edition April 2024) supports limited alignment for reading a story, identifying main ideas/characters/events and sequencing; CIET's activity list supports contextual focus on location prepositions. No official CBSE objective code is assigned, and the exact current *Poorvi* reprint remains unverified.

**Historical CBSE preview checkpoint — 28 October 2026:** The unlinked interface-test route in draft PR #17 was built against the original v1.0 passage and passed 20/20 Chromium tests. It is not a preview of the forthcoming public-domain replacement version. Keep it out of normal navigation; after the third-stage CBSE content revision, update/rebuild the controlled preview and repeat affected visual, keyboard/focus, screen-reader, zoom/reflow and cross-browser checks before any separate release decision.



## 12. Historical migration and feature-integration plan — deferred 31 October 2026

**Archive notice:** The three-unit sequence below records the former MYP Year 1 → Cambridge Stage 7 → CBSE Grade 6 migration plan. None of these steps is currently active. They will not resume automatically after an individual review gate closes; wait for the founder's post-diagnostic curriculum-content order.

The founder-approved 250-word threshold and live-counter rules below supersede the previous blanket instruction that every short passage must be replaced by public-domain literature. The exact founder-approved v3 content remains preserved as historical version content; current v4 contains only the two documented editorial corrections. Any further passage/content changes must be versioned. Qualifying platform-original passages of 250 words or fewer may remain.

**Order and integration gates:**

1. **IB MYP Year 1 Unit 1 v4 — content and academic review approved; release gates remain open.** Founder / project owner approved the exact v4 learner and teacher/editor materials, human academic review and age/level/context suitability on 31 October 2026. The two v3 editorial findings were corrected; passages, other questions, response ranges and six live counters remain unchanged. Final v4 run #352 passed the TypeScript/Vite build, teacher-pack separation and 16/16 Chromium tests. Exact official IB mapping remains unverified; final unit-level rights/territory and image-context review plus manual accessibility remain open. Cambridge Stage 7 independent Top Five research is complete and recorded in its resource-landscape review. Its teacher-pack/counter migration is deferred while diagnostic cycles run; closure of MYP rights/accessibility gates does not automatically trigger it.
2. **Cambridge Lower Secondary English 0861 Stage 7 Unit 1 v1.3 — historically second; deferred.** Revise the teacher/editor pack and perform a word-count audit of “The Rain Gauge” and the warm-up mini-text. Retain each platform-original passage unchanged if its body is 250 words or fewer. If a passage is over 250 words and remains a reading stimulus, replace it in the revised content version with a registered public-domain excerpt; then update dependent answers and feedback. Retrofit live counters to all existing typed-response fields as part of preview/build QA. Previous v1.3 approval applies to that exact version only; material revision requires relevant fresh review.
3. **CBSE English Grade 6 Unit 1 “The Turning Sign” v1.0 — historically third; deferred.** At its scheduled revision, audit the story-body word count. Retain the platform-original story unchanged if it is 250 words or fewer; if over 250 words, use a registered public-domain excerpt and update all passage-dependent tasks/answers. Complete the teacher/editor pack under v1.1, and add the live counter to every typed-response field. The former v1.0 approval remains exact-version history and does not transfer to a revised version.

For every new unit from this point forward, classify each reading passage by the same threshold during drafting; do not author a passage over 250 words as platform-original. Every new typed-response field must include an ideal target and the live counter from its first integration.

**Live counter acceptance tests:** update on typing, paste, edit, deletion and clear-all; display current/ideal counts such as 38/50 and 59/50; never limit or truncate the response; no maxLength; use the same word-tokenisation convention as the rights protocol; expose the counter accessibly; test all current and future typed-response fields.

**Project boundaries:** teacher-only answers remain out of browser bundles; response state remains temporary and ungraded unless separately approved; no authentication, database, real grading, payments, production deployment, DNS or Cloudflare configuration change is included in this plan.

## Historical first-cohort checkpoint — IB MYP Year 1 Unit 1 v3 — 30 October 2026

PR #18 (“Approved content standards: public-domain excerpts and question-specific feedback”) was merged to `main` on 30 October 2026. The first mandatory migration has been implemented on the existing PR #14 branch `feat/myp-y1-unit1-v2`, using a new, versioned **Unit 1 v3** candidate rather than duplicating the unit. GitHub Actions run [#279](https://github.com/gradioprep/gradioprep-website/actions/runs/41008214446) passed the TypeScript/Vite production build, teacher-pack separation guard and all 13 Chromium browser tests, including the 360/390/768/1024/1440px responsive-width check. The Cloudflare Workers branch-preview build also succeeded; no production deployment occurred.

The v3 revision replaces the old platform-written main and transfer extracts with registered historical English works: Dickens's 1843 *A Christmas Carol* and Carroll's 1866-dated Macmillan issue of *Alice's Adventures in Wonderland*. Stable Excerpt IDs are retained; new Source IDs were recorded in `docs/LITERARY_EXCERPT_SOURCE_REGISTER.md` before the excerpt text was committed. Source-level term checks cover India and the United Kingdom only; the United States and other territories are not cleared in this record. The bus-stop photograph remains only because its Commons file page expressly states CC0 1.0; other unit-level rights and accessibility checks remain separate.

The revised teacher/editor pack covers the entry activity, all five practice items and independent transfer exit. It provides question-specific ranges, model responses, correct-answer reasoning, individual distractor rationales, accepted interpretations, strong/developing/weak response guidance and actionable feedback. The learner UI displays each expected word range before typing; the range is guidance, not an automatic limit. Teacher answers and scoring guides are kept out of learner data, and a build-time bundle guard is included.

**Historical gate snapshot for v3 (superseded by v4 approval):** founder content approval for exact v3 recorded on 30 October 2026; at that point fresh human academic review, age/level suitability, rights, manual accessibility and release were pending. Current v4 approval/gates are recorded in the Master Brief, PR #14 and `docs/PILOT_UNIT_REVIEW.md`. This former next-step sequence is not active. No Cambridge or CBSE Unit 1 work begins automatically when the MYP gates close.


## Historical MYP counter implementation checkpoint — 30 October 2026

The six-field retrospective live word counter is implemented on the existing PR #14 branch, commit `0a90f3eb550bba9e7b17e7db1594826f28e1cca7`. All six ideal targets are present and existing response ranges are preserved. The counter is reusable for future typed-response fields and does not cap input. New Playwright tests cover all six targets, lexical counting, editing/clearing and over-target text. Fresh GitHub Actions verification is pending. This implementation does not itself complete the independent academic, mapping, rights, suitability, manual accessibility or release gates, and does not authorize the Cambridge migration.

## Historical MYP Year 1 Unit 1 v3 review checkpoint — 31 October 2026

The six-field counter retrofit and accessible links to prompt, response guidance and live count are implemented. The latest CI run #295 passed the build, teacher-pack separation and all 16 Chromium tests for the earlier v3 snapshot. The public IB sources support broad programme context but not exact applicable current Year 1 mapping; keep official codes blank. This is a historical v3 checkpoint: its two editorial flags were corrected in v4, and human academic/age-context review is now approved for exact v4. Rights/territory, visual context, manual accessibility and release remain open. Any former instruction to move next to Cambridge Stage 7 is superseded by the diagnostic-first cycle register.

## 13. Historical curriculum-content Top Five research checkpoint — 31 October 2026

The binding method now requires a ranked Top Five independent-website comparison for every exact course/level/edition, with official awarding-body/government sources assessed separately. The research must inspect accessible material, score relevance, expertise/transparency, currency, evidence quality and teaching/implementation usefulness, then trace conclusions into the guide and implementation structure.

**Completed:** IB MYP Language and Literature Year 1. The five independent sources and design implications are recorded in `docs/curriculum/IB_MYP_YEAR_1_RESOURCE_LANDSCAPE_REVIEW.md` v1.1 and applied in the Year 1 guide v1.5 and implementation plan v1.4.

**Outstanding/deferred:** CBSE English Grade 6 requires its own India-relevant curriculum-content Top Five, but it is deferred during the diagnostic cycles and will resume only when the founder sets the next content order. The Cambridge Stage 7 audit v1.0 is complete and applied to the group guide v1.2; do not copy the MYP or Cambridge lists across tracks. Continue using public evidence when official detail is gated; leave only unsupported official mapping unverified. Research completion is separate from content migration and rights/accessibility/suitability/release gates.

## 14. Historical first-cohort Unit 1 reconciliation — 31 October 2026 (deferred)

The authoritative three-route status, exact-version approval boundaries, passage counts, branch controls and nine-step completion queue are in [Unit 1 Cohort Status and Reconciliation](UNIT_1_COHORT_STATUS_AND_RECONCILIATION.md). This section supersedes older “current” summaries in Sections 10–13 where their sequence/status language conflicts.

- Route-specific curriculum-content Top Five: MYP Year 1 and Cambridge Stage 7 complete; CBSE Grade 6 remains pending but is deferred during diagnostic cycles.
- Passage count: Cambridge 16/221/27; CBSE 165. All are platform-original and within the 250-word allowance. No replacement is presently required; repeat the count if a passage changes.
- Teacher-pack/counter work: MYP pack and six counters are complete; Cambridge and CBSE pack/counter migrations are both deferred until the founder sets the post-diagnostic content order.
- Deferred content checkpoint: MYP unit-level rights/territory and manual accessibility gates remain open. Cambridge Stage 7 Top Five is complete, but its pack/counter migration does not begin automatically when MYP gates close. All Unit 1 work is deferred during the diagnostic cycles; do not ask the founder to repeat the previously confirmed Cambridge v1.3 review/verification decisions.
- All five relevant draft PRs remain separate and unmerged. Synchronize shared documents and reconcile the older stacked PR #16 base before any merge review.


## Current MYP Year 1 Unit 1 v4 checkpoint — 31 October 2026

The current candidate is v4 on draft PR #14. The two editorial corrections are complete: Q4 uses the source's lowercase phrase and Q3 describes the photographed open platform rather than an unshown shelter. Founder / project owner approved exact v4 content, human academic review and age/level/context suitability on 31 October 2026. MYP Top Five and six counters remain complete. Unit-level rights/territory, visual-context and manual accessibility plus release approval remain open; official mapping remains unverified. Cambridge Stage 7 independent Top Five research is complete, but Stage 7 content/teacher-pack/counter migration is deferred under the diagnostic-first work order. The outstanding MYP rights/territory and manual accessibility gates remain open; this diagnostic-first decision neither closes nor alters them.


## 15. Diagnostic-first learning-readiness sequence — 31 October 2026

The new binding work order is set out in `docs/DIAGNOSTIC_AND_REMEDIAL_LEARNING_READINESS_STANDARD.md` and `docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md`. It supersedes the immediate work order in the historical rotation and migration sections above.

**Cycle 1:** Grade 9 IB MYP Language and Literature. Grade 9 = MYP Year 4 is confirmed by the Founder for the relevant school/programme context. This is no longer a working assumption; do not ask the Founder to reconfirm it. The official MYP programme age band is 11–16; the individual learner's exact age is not separately specified.

**Cycle 2:** Cambridge Grade 6 English. The exact official Cambridge stage/course remains to be scope-locked. Cambridge Primary Stage 6 / English 0058 is a candidate where the learner's actual age and first-language route support it. Do not substitute Lower Secondary Stage 7 for the requested Grade 6 target.

For each cycle, follow this order: (1) rank the five strongest diagnostic/evaluation providers using the approved internal 50/50 percentile method; (2) approve the underlying-skill taxonomy and test blueprint; (3) build and validate the diagnostic; (4) create and validate the detailed, accessible evaluation report and analytics; (5) complete the mandatory whole-website learner-facing copy cleanup; (6) create the personalised remedial course, preferring five 60-minute sessions and extending to six or seven only where evaluation analytics justify the extra time, with Priority 5→1 learning emphasis; (7) validate a fresh post-course check; (8) integrate, test and obtain Founder approval. Only then may the next level be started, and only in the founder-approved order.

Cycle 1's independent Top Five diagnostic-provider research is approved by the Founder; see `docs/curriculum/IB_MYP_G9_DIAGNOSTIC_PROVIDER_REVIEW.md`. The skill taxonomy and high-level 90-minute/two-sitting blueprint were approved on 1 November 2026; see `docs/curriculum/IB_MYP_G9_DIAGNOSTIC_SKILL_TAXONOMY_AND_BLUEPRINT.md`. The detailed task-level item map/scoring specification was approved on 2 November 2026; see `docs/curriculum/IB_MYP_G9_DIAGNOSTIC_ITEM_MAP_AND_SCORING_SPEC.md`. The flagship PDF-response, teacher-grading and timed-analytics plan, 24-hour grading target and Phase 0 architecture/timer/retention/provider decisions are Founder-approved; Phase 0 is complete. The binding decisions are in `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`. Phase 1B local synthetic-only coding is Founder-approved and underway in draft PR #22; hosted provisioning, paid services, real learner data, merge and production deployment remain separately gated. Actual MYP diagnostic implementation and item authoring remain gated until the flagship feature is implemented and pilot-validated. The Cambridge Cycle 2 provider audit must not be started while Cycle 1 is underway. All existing curriculum-unit production, old teacher-pack/counter migration and the former Unit 1 rotation are deferred while these cycles are completed. Keep existing content, approvals, branch history and outstanding gates unchanged. After both cycles, the Founder / project owner will set the next curriculum-content order and scope. This may include completing multiple further units for Grade 9 IB MYP or Cambridge Grade 6 before switching to another level, or another explicitly selected order. No automatic rotation or cyclical sequence resumes.

This is a sequencing layer only. Preserve the existing lesson architecture, research/authoring processes, rights controls, teacher-pack rules, academic/human review, accessibility, QA and release approval requirements. The diagnostic/report presentation uses a white/cool-white canvas with accessible, legible charts and minimal tables/data blocks; follow the approved Palette B, typography and component system. Do not alter the global architecture or add authentication, a database, persistent records, AI/API costs or other infrastructure without separate approval.



**Founder approval update — 31 October 2026:** MYP Grade 9 provider research approved. Draft taxonomy/blueprint submitted for review. Provider percentiles and their 50/50 basis (actual test-taker volume / independent research evidence) are internal-only and excluded from all learner/parent reports, including logged-in views. Five 60-minute remedial sessions are preferred; six or seven only where analytics justify.


**Diagnostic blueprint approval update — 1 November 2026:** The Founder approved the MYP Grade 9 / Year 4 skill taxonomy and high-level blueprint. The task-level item map/scoring specification is now the active review gate. It covers 35 evidence observations across the six MYP skill areas and all 23 subskills; the observation count is not a count of independent long questions. No actual diagnostic items, final cut scores, report interface, remedial lessons, diagnostic implementation or release are approved. Keep Cambridge Grade 6 and all existing curriculum-unit work blocked/deferred.


## 16. Flagship PDF response, human grading and timed analytics — approved plan, 2 November 2026

This shared feature is inserted after approval of the MYP Year 4 item map and before actual diagnostic item authoring. It is intended for written-response tasks across Grades 6–12, not just MYP. The phased plan is in docs/FLAGSHIP_PDF_RESPONSE_GRADING_AND_TIMED_ANALYTICS_SPEC.md.

The approved requirements include optional PDF submission for written responses whose expected length exceeds 20 words, PDF-only learner uploads, preservation of the original, page-aligned extraction/handwriting OCR, an oldest-first human-grading queue, task-specific expandable rubrics, ten AI-drafted feedback suggestions with human publication, editable learner-visible feedback, a task countdown and accuracy/speed analytics. The approved grading target is 24 elapsed hours from accepted submission to first feedback publication, using Priority 1 (more than 0 and up to 10 hours remaining), Priority 2 (more than 10 and up to 20 hours remaining), Priority 3 (more than 20 hours remaining) and an overdue state.

Phase 0 is complete. The Founder-approved decision register (`docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`) selects Supabase Auth/PostgreSQL/private Storage in Mumbai (`ap-south-1`), PDF.js for digital PDFs, Azure Document Intelligence Read with Central India as the intended OCR region, Cloudflare Workers AI stateless teacher-only drafts, and Cloudflare R2 only for encrypted secondary PDF-object backups subject to transfer/residency review. It fixes the initial PDF cap at 10 MB/10 pages, advisory server-authoritative timing with no learner pause/hard stop and no auto-submit/deletion at zero, plus retention/deletion and role controls.

Next is Phase 1 secure application foundation, but implementation and any paid/account provisioning require separate explicit Founder approval. No code, authentication, database, storage bucket, OCR account, AI endpoint, DNS or Cloudflare configuration has been activated by this documentation decision. No real learner data may be sent to an external processor until the privacy, contract, region, legal/guardian-consent and quality gates pass. Actual MYP item authoring remains paused until feature implementation and pilot validation. Cambridge Grade 6 remains blocked until the MYP cycle is completed and the Founder directs the transition.


## 17. Historical Phase 1 secure application foundation — planning checkpoint (superseded by approved Phase 1B implementation)

At this 2 November planning checkpoint, Phase 1 was still a planning artefact and no implementation had started. This historical state was superseded when the Founder separately approved Phase 1B local synthetic-only coding and work began in draft PR #22. The current implementation status and exact verification evidence are recorded in the Master Brief v4.36 checkpoint and the Phase 1 specification. The approved provider/region choices and retention rules remain those in the Phase 0 decision register. Hosted services, paid plans, real learner records, merge, production deployment and DNS remain unauthorised. MYP Year 4 diagnostic item authoring remains gated until flagship implementation and pilot validation; Cambridge Grade 6 remains blocked.


## 18. Phase 1A build-ready implementation handoff — 2 November 2026

The detailed engineering handoff is `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`. It records the inspected React/Vite/Wrangler starting point, the local Supabase CLI approach, the first Worker API entrypoint, Auth SDK choices, initial identity/role schema, safe RLS helper rules, synthetic seed identities, database/API/Playwright CI coverage, estimated hosted costs and proposed recovery targets. The first coding slice is local synthetic-only Auth, API and role foundation; no hosted project or paid service is required. Phase 1B coding was subsequently approved and is underway in draft PR #22. No hosted service, paid plan, real learner data, merge or production deployment is authorised. Preserve the approved Phase 0 provider and retention choices; do not provision R2, KMS, Azure OCR or Workers AI as part of the first slice. MYP Year 4 item authoring remains gated until flagship implementation and pilot validation; Cambridge Grade 6 remains blocked.


## 19. Mandatory GitHub implementation and public verification loop — 2 November 2026

The Founder has directed that each meaningful implementation increment be verified on a public Cloudflare Worker Preview without waiting for the end of a phase. Every implementation PR must complete the build/test checks, deploy its isolated `pr-<number>` Preview (or its approved branch-specific Preview where the provider integration is already configured), post the current URL, and provide a concise non-coder test handoff. The Founder inspects actual pages and interactions; findings are corrected in the same PR and the Preview is refreshed. The governing process is `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`. Use synthetic data only; Phase 1B backend tests remain local Supabase until a separate hosted-synthetic-project approval is granted. Public Preview is not official production. The exact confirmed custom domain is attached at the Launch Candidate / Production Cutover checkpoint after all launch gates and separate DNS/production approval. MYP Year 4 item authoring remains gated until the flagship feature is implemented and pilot-validated; Cambridge Grade 6 remains blocked.

For PR #22, the latest exact-code Preview was supplied by Cloudflare's linked Workers Builds integration, not by the Phase 1B Actions job. The Phase 1B job's own create/update/comment Preview steps were skipped because its latest run was triggered by a branch push; its local Supabase/RLS/build/Playwright checks still passed. Do not use the older `pr-22` alias for current review. Use the latest branch alias and immutable deployment URL in the Master Brief v4.35 checkpoint. Manual Founder browser verification remains outstanding.


## 20. Mandatory whole-website learner-facing copy cleanup — 2 November 2026

Immediately after the Cycle 1 diagnostic and evaluation report/analytics have been completed and checked, and before any remedial content is authored, review and correct the entire website. This is a required gate in the Grade 9 IB MYP cycle, not a narrow diagnostic-page edit.

Review all routes and states, including shared navigation and footer, homepage, pathways, course/level/unit/lesson/practice pages, dashboard, diagnostic, evaluation report and analytics, sign-in, feedback/profile, preview/status, and populated/empty/loading/error/locked and responsive states. Identify every visible internal planning instruction, editor note, development comment, temporary placeholder and misleading demo disclosure. The three examples recorded in docs/PROJECT_MASTER_BRIEF.md Section 16.9 and docs/DESIGN_SPEC.md Section 17 are known findings only; the sweep must discover the rest of the site.

Do not remove any existing band, card or page structure simply because the copy is temporary. Replace the content in place with relevant, accurate learner-facing wording or a purposeful empty state. In particular, do not expose fictional dashboard figures as live activity, and do not imply a confirmed learning unit or syllabus focus where none has been verified. Use “Sign in” as the concise navigation label.

Use standard TODO: comments and a central TEMP_COPY_ content registry only as development traceability; never show those markers in the UI. Search the full repository and verify every route/state at desktop and mobile widths. Automated text checks and browser QA must confirm that internal notes and temporary markers are absent, actual values are data-backed, learner copy is specific and useful, and the established layout/visual bands remain intact. Record completion and obtain Founder Preview verification before remedial content authoring begins.



## 21. Phase 1B local security and Preview verification checkpoint — 2 November 2026

Draft PR #22 remains open and unmerged. The user-designated Actions run #41473170539 passed on the preceding code revision `97d2bb4`; the newer exact-head run #41473237444 passed on code-bearing revision `50f4bb3`. The latest run reset an isolated local Supabase stack, loaded synthetic fixtures, passed `supabase/tests/identity_roles.test.sql`, completed browser and Worker type/build steps, and passed 15/15 Chromium account/API/navigation tests. The generic Build check is intentionally skipped for this stacked base branch; the dedicated Phase 1B workflow runs the corresponding build and browser checks.

Cloudflare's branch-specific Preview for commit `50f4bb3` reports Build and Deployment success. Stable alias: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. Immutable deployment: https://b7df4c52-gradioprep-website.wandering-scene-1822.workers.dev. Cloudflare API metadata shows the deployment has only the Static Assets binding and no Supabase variables. It is therefore a public UI/route/safe-failure-state Preview, not a live authentication backend. The Phase 1B Actions workflow did not upload this Preview: its post-test Preview steps were skipped on the push-triggered run. Manual Founder review is pending. Do not enter credentials or real learner data.

This checkpoint does not begin diagnostic item authoring, the mandatory whole-site learner-facing copy cleanup, remedial work or Cycle 2. The copy cleanup in Section 20 remains not started and is still gated until Cycle 1 diagnostic/report validation. No hosted Supabase, paid service, real learner data, merge, production deployment or DNS change is authorised.

## 22. Phase 1B suspended-account access control — 2 November 2026

The next approved Phase 1B security increment adds a suspended synthetic student to the local seed. A private SECURITY DEFINER helper checks the calling user's current application-account status; every first-slice identity-table RLS policy requires an active caller. A valid Auth JWT does not bypass a suspended application status. An active owner retains the ability to inspect the suspended record. The Worker returns a generic 403 for protected profile reads/updates, and the account UI hides profile/role details while offering sign-out. SQL and Playwright tests cover the deny path. Fresh CI and branch Preview verification are pending. This does not provision a hosted project or change any diagnostic/content sequence.
