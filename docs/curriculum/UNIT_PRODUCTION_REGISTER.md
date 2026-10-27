# Unit Production Register

**Status:** Internal control register v2.4 — MYP Year 1 guide v1.1, implementation structure v1.2 and Unit 1 v2 have founder approval as a candidate; separate MYP academic/mapping/rights/accessibility/suitability/release gates remain open. Cambridge Stage 7 Unit 1 v1.3 remains the active draft candidate in PR #12. Controlled preview run #14 and Build check #245 succeeded on 27 October 2026; the TypeScript/Vite build and 17/17 Chromium tests passed. This is limited automated evidence, not full accessibility certification, manual hosted-page visual review, human suitability review or release approval. Formal rights/originality clearance, human suitability, current full Cambridge framework/version and mapping, manual accessibility checks and explicit release remain open. Both PRs remain unmerged; no production deployment or DNS change occurred.
**Source of truth:** docs/PROJECT_MASTER_BRIEF.md, docs/ENGLISH_STAGE_1_ROADMAP.md, docs/ENGLISH_CURRICULUM_GUIDES.md, docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md and the relevant course guide.
**Binding rule:** Complete Unit 1 across age/grade-band cohorts before starting Unit 2 anywhere. First cohort: IB MYP Year 1 → Cambridge Lower Secondary Stage 7 → CBSE Grade 6. Second cohort: IB MYP Year 2 → Cambridge Lower Secondary Stage 8 → CBSE Grade 7. Then continue to the next comparable band (for example MYP Year 3 → Cambridge Stage 9 → CBSE Grade 8), after verifying learner/grade alignment and current official sources. These are internal planning comparisons, not official equivalences. Do not start Unit 2 for the first cohort immediately after its Unit 1s finish. Unit 2 begins only after the approved Unit 1 rotation across all in-scope levels is complete. A blocked unit pauses the sequence; do not skip it or invent syllabus objectives.

## 1. Curriculum guide readiness register

| Curriculum group | Year/stage chapters available | Current guide state | Main unresolved check |
|---|---|---|---|
| IB MYP Language and Literature | Year 1 standalone guide: docs/curriculum/IB_MYP_LANGUAGE_AND_LITERATURE_YEAR_1_GUIDE.md; implementation: docs/curriculum/IB_MYP_YEAR_1_PATHWAY_IMPLEMENTATION.md | Guide v1.1, implementation v1.2 and Unit 1 v2 content founder-approved as a candidate; separate academic/mapping/rights/accessibility/suitability/release gates open | Official objective/strand mapping not claimed. Founder approved the v2 content as a candidate; separate academic, rights, accessibility/suitability and release gates remain open. Years 2–5 in the legacy group file remain drafts. |
| Cambridge Lower Secondary English 0861 | Stages 7–9 in docs/curriculum/CAMBRIDGE_LOWER_SECONDARY_ENGLISH_0861_GUIDE.md | Public-framework-aligned group guide drafted | Pin the currently applicable official framework/version and verify exact objective IDs |
| IB DP Language A: Language and Literature | Year 1/Year 2 in docs/curriculum/IB_DP_LANGUAGE_A_LANGUAGE_AND_LITERATURE_GUIDE.md | Public-source-aligned guide drafted | Verify session-specific assessment details/criterion version against current official materials before scored mocks |
| Cambridge IGCSE First Language English 0500 | Syllabus-wide guide and two proposed delivery phases in docs/curriculum/CAMBRIDGE_IGCSE_FIRST_LANGUAGE_ENGLISH_0500_GUIDE.md | Current 2027–2029 syllabus/specimen baseline recorded | Record each learner's examination year and component/route; map every task against the exact syllabus/specimen |
| CBSE English Grades 6–12 | Grade-specific routes documented in `docs/curriculum/CBSE_ENGLISH_GRADES_6_12_PATHWAY_RESEARCH_BRIEF.md` | Pathway scope approved; class-wise research and guides not yet completed; Grade 6 Unit 1 is the third first-cohort item | Verify current CBSE/NCERT sources by grade/session, preserve course distinctions and do not invent objective codes |

A guide being approved does not mean every objective is officially mapped, every task is written, or a release gate has passed. MYP Year 1 Unit 1 v2 is a revised candidate based on the existing preview; founder content approval does not inherit version 1's review outcome. MYP v2 is not released. Cambridge Stage 7 Unit 1 v1.3 has a separate learner draft, teacher/editor pack and AI-led curriculum/content review record. The review added a worked inference model, vocabulary supports and item-specific scoring. Founder authorized further gate review. Limited public phrase-search and content-level accessibility preflights are recorded; formal rights, human suitability, current framework/version, UI accessibility and release gates remain pending. CBSE Grade 6 Unit 1 has not yet been created. Maintain the first cohort order and do not advance to older-level Unit 1 work or Unit 2 until all three first-cohort units are complete and their required gates recorded.

## 2. Unit 1 production rotation

**Current checkpoint (26 October 2026):** MYP Year 1 guide v1.1 and implementation structure v1.2 were founder-approved, and MYP Unit 1 v2 content has founder approval as a candidate; separate review/release gates remain open. The active Cambridge Stage 7 Unit 1 candidate is v1.3 in PR #12 following AI-led curriculum/content review of v1.2. On 26 October 2026, the founder authorized further review/release checks. A limited phrase-search and content-level accessibility/context preflight are recorded; formal rights, human suitability, current framework/version, UI accessibility and release remain pending. After Stage 7 is completed under the required gates, create CBSE Grade 6 Unit 1. Do not skip the first cohort or begin older-level Unit 1 / Unit 2 work before the binding sequence is complete.

| Order | Unit ID | Curriculum/year or delivery phase | Content status | Next action / blocking condition |
|---:|---|---|---|---|
| 1 | ib-myp-lal-y1-u1 | IB MYP Language and Literature Year 1 | Version 2 draft: **How writers and creators shape meaning**; founder-approved content candidate in PR #14. Version 1 review does not transfer; separate academic, mapping, rights, accessibility/suitability and release gates remain open | Complete the exact v2 review gates; do not claim current official mapping or release |
| 2 | cambridge-ls-english-s7-u1 | Cambridge Lower Secondary English 0861 Stage 7 | Draft v1.3 in PR #12; isolated interface-testing preview in draft PR #15 | CI build + 17/17 Chromium tests passed, including six preview UI checks. Manual accessibility, formal rights clearance, human suitability, current full framework/version/mapping and release gates remain open; preview is not student-ready |
| 3 | cbse-english-g6-u1 | CBSE English Grade 6 | Not started | After Stage 7 Unit 1 is cleared for the intended status, research current NCERT/CBSE sources and create original student-facing Unit 1; do not invent official mapping |
| 4 | ib-myp-lal-y2-u1 | IB MYP Language and Literature Year 2 | Planned; blocked until first cohort is complete | Next comparable band; verify the school's level context and do not invent official objective codes |
| 5 | cambridge-ls-english-s8-u1 | Cambridge Lower Secondary English 0861 Stage 8 | Planned; blocked until first cohort is complete | Next comparable band; verify framework version/objectives and do not simply repeat Stage 7 |
| 6 | cbse-english-g7-u1 | CBSE English Grade 7 | Planned; blocked until first cohort is complete | Next comparable band; research current CBSE/NCERT sources for Grade 7 before content creation |
| 7 | ib-myp-lal-y3-u1 | IB MYP Language and Literature Year 3 | Planned; blocked until second cohort is complete | Continue age/grade-band rotation; verify learner context and mapping status |
| 8 | cambridge-ls-english-s9-u1 | Cambridge Lower Secondary English 0861 Stage 9 | Planned; blocked until second cohort is complete | Verify framework version/objectives and learner context |
| 9 | cbse-english-g8-u1 | CBSE English Grade 8 | Planned; blocked until second cohort is complete | Research current CBSE/NCERT sources for Grade 8 before content creation |
| 10 | ib-myp-lal-y4-u1 | IB MYP Language and Literature Year 4 | Planned; blocked until earlier Unit 1 bands are complete | Verify learner context; keep official mapping status explicit |
| 11 | cbse-english-g9-u1 | CBSE English Grade 9 | Planned; blocked until earlier Unit 1 bands are complete | Verify current course options and subject codes before defining the exact route |
| 12 | ib-myp-lal-y5-u1 | IB MYP Language and Literature Year 5 | Planned; blocked until earlier Unit 1 bands are complete | Verify school-selected pathway; do not assume optional MYP eAssessment |
| 13 | cbse-english-g10-u1 | CBSE English Grade 10 | Planned; blocked until earlier Unit 1 bands are complete | Verify current course options and subject codes before defining the exact route |
| 14 | ib-dp-langlit-y1-u1 | IB DP Language A: Language and Literature Year 1 | Planned; blocked until younger approved Unit 1 bands are complete | Use current public course/examiner sources and verify SL/HL and assessment session |
| 15 | cambridge-igcse-fle-phase-a-u1 | Cambridge IGCSE First Language English 0500 first proposed delivery phase | Planned; blocked until younger approved Unit 1 bands are complete | Use syllabus Version 1 for exams 2027–2029 and check candidate route/current specimens |
| 16 | ib-dp-langlit-y2-u1 | IB DP Language A: Language and Literature Year 2 | Planned; blocked until preceding Unit 1 bands are complete | Check school sequence, candidate SL/HL and applicable assessment session |
| 17 | cambridge-igcse-fle-phase-b-u1 | Cambridge IGCSE First Language English 0500 second proposed delivery phase | Planned; blocked until preceding Unit 1 bands are complete | Same syllabus as phase A, not a separate qualification/syllabus; check exam year and route |
| Later queue | cbse-english-g11-u1 | CBSE English Grade 11 | Planned; blocked until older-level placement is verified | Preserve English Core/Elective distinctions where applicable; exact routes depend on current official evidence |
| Later queue | cbse-english-g12-u1 | CBSE English Grade 12 | Planned; blocked until older-level placement is verified | Preserve English Core/Elective distinctions where applicable; exact routes depend on current official evidence |

**Rotation rule:** First complete Unit 1 across the Grade 6-equivalent cohort (MYP Year 1, Cambridge Stage 7, CBSE Grade 6). Then complete Unit 1 across the next comparable band (MYP Year 2, Cambridge Stage 8, CBSE Grade 7), followed by the next comparable band (MYP Year 3, Cambridge Stage 9, CBSE Grade 8), subject to verifying actual grade/age alignment and current sources. Continue through all approved levels in age/grade-band order, including older pathways. Do not start Unit 2 for any cohort until Unit 1 is complete across all approved in-scope levels. If any unit is blocked, pause and report the blocker rather than skipping ahead. This is a product-production sequence, not an official curriculum sequence.

## 3. Unit-level production gates

Before a unit is considered draft-complete:
- [ ] Its course guide and current public-source basis have been checked and recorded.
- [ ] The learning goal and proposed progression are original, clear and linked to that guide’s publicly verified skill structure.
- [ ] The unit uses only official objective/criterion codes whose exact current descriptors are verified; otherwise the mapping field stays blank/unverified.
- [ ] Its passage, questions and model/explanation are original or have a documented rights basis.
- [ ] The content sequence includes explicit modelling, guided practice, independent transfer, feedback, revision and exit evidence where appropriate.
- [ ] Answer keys/marking guidance are separate from learner-visible content.
- [ ] A teacher/editor review pack exists separately from the learner-facing material.
- [ ] Source/session/edition, content version and review status are recorded.
- [ ] Accessibility, readability, cultural/age suitability and final release reviews are treated as separate gates.
- [ ] The published/prototype route accurately states whether content is a planning draft, public-framework-aligned preview or fully mapped/released unit.

## 4. Cross-curriculum release principles

- A public-framework-aligned practice unit may teach verified general skills without pretending the detailed official objective/strand is known.
- A source check, academic content review, rights review, accessibility review, official mapping verification and release approval are different evidence records. Passing one does not pass the others.
- For Cambridge 0500, do not label legacy past papers as current-format practice without comparing question structure, marks, response length and mark scheme with the applicable syllabus/specimen.
- For DP Language A: Language and Literature, do not use Language A: Literature past-paper pages as though they were the same course.
- For MYP, do not use random “MYP past papers” from download sites as a substitute for protected official specimen assessments.
- Do not promise scores, grades or complete syllabus coverage from a three-unit starter pathway.

## 5. Current production position

The first slot, IB MYP Year 1 Unit 1, already exists as the preview **How writers shape meaning**. The founder approved the MYP Year 1 guide v1.1, implementation structure v1.2 and Unit 1 v2 as a content candidate; this does not transfer the version-1 academic review or close the v2 academic, official-mapping, rights, accessibility/suitability or release gates. PR #14 remains an unmerged draft. Do not duplicate the existing unit. The current rotation checkpoint is Cambridge Stage 7 Unit 1 v1.3 in PR #12.

The second first-cohort slot, **Cambridge Lower Secondary English Stage 7 Unit 1**, remains in the existing PR #12; it was revised from v1.2 to v1.3 after AI-led academic/content review. On 26 October 2026, the founder approved proceeding with further gate checks. Limited phrase-search and content-level accessibility preflights are recorded, but the unit has not been integrated or released and its formal rights, human suitability, UI accessibility, current framework/version and release gates remain open. Do not create a duplicate. The third first-cohort slot is CBSE Grade 6 Unit 1; no content exists for it yet.


## 6. Expanded MYP research checkpoint — 26 October 2026

Completed work: dedicated MYP-specific platform/publisher/planning-resource review; replacement of the three-unit sketch with six proposed units plus eight shared hours (at least 50 planned hours); versioned legacy criterion crosswalk; and separate Enhanced MYP transition watch. These are research/documentation deliverables only.

Not completed for MYP Unit 1 v2: separate academic review, current official mapping verification, item-level rights, accessibility/suitability and final release approval. MYP v2 remains an unmerged candidate in PR #14. For Cambridge Stage 7 Unit 1 v1.3, AI-led content review of v1.2 is complete and improvements applied; founder review of exact v1.3, full current framework/version, rights, accessibility/suitability and release gates remain open.


## 7. Cambridge Lower Secondary Stage 7 Unit 1 v1.3 post-approval gates — 26 October 2026

The founder approved proceeding with further review/release checks for v1.3. The public exact-phrase desk screen searched distinctive passage lines and mini-texts; no exact passage-level match surfaced in returned results. Content-level accessibility/context preflight found no blocking text-only issue. These findings do not constitute full rights clearance, comprehensive plagiarism review, human suitability review or accessibility certification. This text-only unit contains no photograph or third-party excerpt; the photo pre-selection process is not applicable. The active checkpoint remains blocked for release until formal rights/originality, human age/level/cultural suitability, current full framework/version handling, intended-UI accessibility checks and explicit release approval are recorded. Do not skip ahead to CBSE Grade 6 while Stage 7 remains blocked.

## 8. Controlled preview interface-testing checkpoint — 26 October 2026

The founder approved integration of the Stage 7 Unit 1 v1.3 learner draft into a separate, unreleased preview branch only for UI accessibility testing. Draft PR [#15](https://github.com/gradioprep/gradioprep-website/pull/15) is based on `main` and contains a single isolated, unlinked preview route. The teacher/editor pack and answers are not imported into the client; responses are temporary and not graded or persisted.

GitHub Actions [Build check #231](https://github.com/gradioprep/gradioprep-website/actions/runs/40308612925) passed on commit `841c26ab5f3c0bd24d32cc88d839af015353eff9`: build successful; 17/17 Chromium tests passed. Added preview checks cover rendering and release labeling, keyboard interaction, unique task-specific accessible names for all 14 textareas with associated question prompts, narrow mobile reflow/overflow, clearing all temporary text responses and the warm-up radio choice, and representative text contrast sampling. The CI browser run uses local Wrangler assets; a hosted Cloudflare preview URL has not been verified. Do not treat automated checks as full accessibility review or as clearance for content, mapping, rights or release.

**Still blocked:** formal rights/originality review; human academic and age/level/cultural suitability judgement; the full currently applicable Cambridge framework/version and further objective mapping; manual keyboard/focus and screen-reader testing; 200%/400% zoom/reflow and cross-browser checks; text-to-speech review; explicit release approval. Continue to pause before CBSE Grade 6 Unit 1 until Stage 7 gates are addressed and the required release decision is recorded.


## 9. Final clear-all regression check — 26 October 2026

The controlled preview's “Clear all draft responses” action clears every temporary learner input, including the warm-up radio choice and all 14 text-area responses. The final test run also verifies that the skip link moves focus to main content, the exit-check prompt is associated with its response field, and responsive layout checks pass at 320/390/768/1024 CSS-pixel widths. These checks passed [Build check #231](https://github.com/gradioprep/gradioprep-website/actions/runs/40308612925), alongside the TypeScript/Vite build and 17/17 Chromium tests. The preview remains unreleased, unmerged, and is not a full accessibility audit. Keep the Stage 7 production checkpoint blocked until formal rights/originality, human academic and suitability, current framework/version and further objective mapping, manual accessibility checks and explicit release approval are recorded.


## 10. Hosted preview and refreshed verification — 27 October 2026

The PR #15 controlled preview workflow is now passing after the least-privilege permission correction. [Run #14](https://github.com/gradioprep/gradioprep-website/actions/runs/40524206707) passed, including the preview URL PR-comment step. [Build check #245](https://github.com/gradioprep/gradioprep-website/actions/runs/40524206694) passed the TypeScript/Vite build and all 17 Chromium tests on preview verification commit `127a7b82ccda52536b4bfd78e603499cd47281d6`. Cloudflare's API confirmed the hosted preview URL: https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev/preview/cambridge-lower-secondary/english/stage-7/unit-1 (the `deployed_on` field returned `2026-10-27T14:46:23Z` UTC at the verification check). The preview remains publicly reachable unless Cloudflare Access is configured and is for interface testing only.

The tests ran against local Wrangler assets and do not constitute manual review of the remote page or full WCAG certification. Human visual/academic/age-level/cultural suitability, formal rights/originality, the currently applicable full Cambridge framework/version and additional objective mapping, manual screen-reader/keyboard/zoom/text-to-speech/cross-browser checks, and explicit release approval remain open.

**Binding next task:** continue the already-authorised review of the exact Stage 7 Unit 1 v1.3 candidate. Do not ask for the earlier MYP content-candidate approval again. After Stage 7 passes the required gates and a release decision is recorded, create CBSE Grade 6 Unit 1. Do not skip blocked units or start Unit 2.


## 11. Supplemental Stage 7 Unit 1 rights/originality desk screen — 27 October 2026

As a follow-up to the original four phrase queries, eight additional exact-phrase searches were run against distinctive sentences/clauses from the learner passage and exit-check text, including the line about the grey-painted library windows, Jamil watching the school garden, the rain gauge trembling as leaves moved across the tiles, Ms Chen's calm voice, the smallest seed trays on the bench, and Lina packing the picnic blanket as the paper cup rolled along the platform. No exact passage-level match appeared in the returned public search results. The returned results included general reading/inference teaching resources but no passage-level match to the searched lines.

**Scope limit:** This is an expanded public-index desk screen only. It cannot rule out unindexed, private, paywalled, translated or paraphrased sources, and cannot independently prove authorship or substitute for formal rights/legal review. The unit remains text-only and uses no photos or third-party excerpts, so the mandatory photo pre-selection gate is not applicable. Formal rights/originality clearance remains **open**; no public-release claim is authorised.


## 12. Supplemental v1.3 learner/teacher-pack consistency check — 27 October 2026

An additional AI-assisted editorial pass compared the current v1.3 learner text with the separate v1.3 teacher/editor pack. Checks covered version labels, passage details referenced by the tasks/answers, whether acceptable-answer guidance matches the actual prompts, scoring descriptors, and the stated formative maximum. The score total is consistent: retrieval 1 point + evidence selection 2 + inference 2 + language-in-context 2 + interpretation evaluation 2 + extended response 6 = **15 points**. The exit check and reflection are correctly described as unscored. No clear internal contradiction was identified that warranted a content edit; learner content stays v1.3.

**Limit:** This is an AI-assisted editorial consistency check, not an independent human academic review, a learner pilot, a formal suitability assessment, rights clearance, complete official mapping, manual accessibility sign-off or release approval. The exact v1.3 content must still receive human academic and age/level/cultural-suitability review. Keep PR #12 in draft and do not release.
