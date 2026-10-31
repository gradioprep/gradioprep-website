# MYP Year 1 Unit 1 — Version 4 Reconciliation and Review Record

**Version:** 1.5  
**Date:** 31 October 2026  
**Status:** Version 4 is founder-approved in PR #14 for exact learner/teacher content, human academic review and age/level/context suitability on 31 October 2026; rights/territory, manual accessibility and release gates remain open. Current detailed official mapping remains unverified.  
**Unit:** IB MYP Language and Literature Year 1, Unit 1.  
**Content version:** 4 — “How writers and creators shape meaning” (editorial-correction draft).  
**Guide baseline:** MYP Year 1 guide v1.4 and implementation structure v1.3; current detailed IB Year 1 guide edition and exact official objective/strand mapping remain unverified.  
**Important:** This record is not an official IB mapping, academic-review pass, rights clearance, accessibility approval or release authorization.

The version 1, version 2 and version 3 sections below are historical records. Their approvals apply only to those exact versions and do not transfer to version 4.

## 1. Decision and version history

The founder approved the MYP Year 1 curriculum guide, implementation structure and official-plus-specialist-resource research method on 26 October 2026. The next step was to reconcile the existing “How writers shape meaning” preview with the approved six-unit plan, rather than create duplicate content.

Version 1 passed academic content review for pilot preview on 24 October 2026. That approval is specific to version 1. The changes documented here are a material revision and therefore use version 2 with a fresh review state:

- Learner data: src/content/pilotLearnerLesson.ts, ID pilot-lesson-how-writers-shape-meaning-v2.
- Teacher/editor pack: src/content/pilotLessonPack.ts, ID draft-lesson-how-writers-shape-meaning-v2.
- Safe Pathways metadata: src/content/pilotReviewSummary.ts, version 2 and draft-for-founder-review.
- Planning brief: src/content/pilotUnitDraft.ts, version 2.
- Readiness state: src/content/unitReadiness.ts, version-specific reviewer and answer-key status.
- User-facing route label: src/content/pathways.ts.
- Preview rendering/status: src/App.tsx; new poster/entry/transfer styles in src/styles.css.

Version 2 is in a pull request preview branch, not merged to main and not deployed to production. It must not be described as an approved Unit 1 or released MYP course.

## 2. Alignment with the approved Year 1 guide

| Guide v1.1 requirement / design choice | Version 2 response | Evidence or limit |
|---|---|---|
| Read and view varied text forms | Keeps the original prose passage and adds a fictional night-bus campaign-poster mock-up using a Wikimedia Commons photograph explicitly released under CC0 1.0, with platform-authored copy and layout. | Direct reading and viewing opportunities; the photograph has descriptive alt text, and the visible copy remains selectable text. The image is a third-party asset, not an original illustration. |
| Establish a diagnostic before instruction | Adds an unscored starting observation: identify a word or visual detail and describe it before interpreting it. | Temporary UI state only; not a saved diagnostic, score or persistent learner record. |
| Model an explicit evidence process | Uses choice → evidence → effect in context and an annotated example. | Learner instructions remain separate from answer keys/model responses. |
| Explain creator choices, meaning and audience | Adds a comparison task that asks learners to use a specific phrase from the passage and a written/visual choice from the poster. | It teaches plausible audience effects; it does not assume every reader responds identically. |
| Develop reasoning in context | Retains “warm light spilled across the wet pavement” and asks learners to consider Mara’s final hesitation. | Success indicators encourage evidence-based qualification, not one compulsory interpretation. |
| Include deliberate practice and revision | Includes a supported choice question, short responses, text/visual comparison, contextual interpretation and revision of a weak visual-analysis response. | Teacher/editor answer guide remains outside the learner-facing module graph. |
| Demonstrate transfer on a fresh task | Uses a new original micro-extract about a sunrise platform and yellow scarf for the exit task. | Requires new evidence; not represented as an IB specimen. |
| Keep skill claims honest | Main assessed modes are reading, viewing and written explanation/comparison. Optional partner discussion is an extension only. | The preview does not capture or score speaking/listening performance; do not claim that it does. |
| Keep official mapping separate from internal design | Official objective-code array remains empty; mapping status remains unverified. The 2014/15 guide is a labelled legacy crosswalk only. | No official objective/strand code is invented or inferred from a third-party platform. |
| Separate content/release gates | Version 2 is marked draft-for-founder-review; official mapping, academic review, rights, accessibility and release approval remain separate. | Version 1 approval does not transfer to this revision. |

## 3. Review of text, poster and source rights

The prose passage is original to the platform and retained from version 1. The fictional night-bus campaign-poster mock-up uses original platform-authored copy/layout with “Bus stop with platform during night.jpg” by Mateusz Konieczny: https://commons.wikimedia.org/wiki/File:Bus_stop_with_platform_during_night.jpg. The file page explicitly records CC0 1.0 Universal Public Domain Dedication. The image was visually screened before selection; no identifiable people or visible commercial branding were observed. The exit-ticket micro-extract is original. No protected IB question, textbook extract, specialist-platform lesson, model response or past-paper question is reproduced.

This is a documented origin claim, not completed legal/rights clearance. The rights reviewer must still record the applicable approval basis for this exact version, including any future changes to copy, graphics, fonts or other assets. Do not add third-party materials without a fresh rights check.

## 4. Version 2 quality and accessibility checklist

| Check | State | Note |
|---|---|---|
| Reconciled with approved Unit 1 focus | Complete for review | Retains evidence-based analysis and extends it to an original visual artefact. |
| Original learner text/visual/transfer | Drafted | Original prose, poster copy/layout and transfer extract are platform-authored; a third-party photograph is now used. Complete current licence and model/property-release review. |
| Learning objective and success criteria | Drafted | Platform-authored; not an official IB objective statement. |
| Entry observation and fresh-text transfer | Implemented in preview branch | Both are temporary, not graded or persisted. |
| Answer/model response separation | Implemented in source structure | CI/source review must confirm the teacher pack is not imported into client modules. |
| Current official Year 1 map | Unverified | Keep officialObjectiveCodes empty. |
| Academic review for v2 | Pending | Founder content approval was recorded on 26 October 2026; version 1's academic-review outcome is retained as history only. |
| Reading and visual description | Present | Screen-reader order and reading load still need testing. |
| Keyboard, focus, zoom/reflow, contrast and small-screen layout | Review pending | JSX and CSS changed; formal accessibility review has not been completed. |
| Age/level and cultural/context suitability | Review pending | Founder/academic review required. |
| Release approval | Not approved | No released/syllabus-mapped-course claim. |

## 5. What must happen next — historical version 2 checkpoint

This section records the next actions as they stood before the version 3 migration on 30 October 2026. It is superseded by the version 3 checkpoint in section 7.

1. Complete and record the separate academic review of the founder-approved version 2 content and teacher/editor pack.
2. Complete academic, rights, accessibility, age/level and cultural/context checks separately.
3. Keep official objective/strand codes blank unless the applicable current IB guide is verified.
4. Merge/deploy content/app changes only after required checks for the intended status are addressed; founder content approval alone is not release approval.
5. The production rotation now advances to Cambridge Lower Secondary English Stage 7 Unit 1. Review the existing draft in PR #12; do not create a duplicate. Stage 7 must pass its own review gates before implementation/release.

## 6. PR and deployment status at the version 2 checkpoint — historical

- **PR #14:** Unit 1 v2 content candidate approved by the founder on 26 October 2026; separate academic, mapping, rights, accessibility/suitability and release gates remain open. PR remains draft and unmerged.
- **Main branch:** Still contains the previously reviewed version 1 preview; v2 is not on main.
- **Production:** No deployment of version 2 has occurred.
- **Cambridge Stage 7:** Existing draft learner/teacher files in PR #12 are now the active production checkpoint; they remain drafts and are not integrated or released.


## Pre-founder-review content refinement — 26 October 2026

A pre-review quality pass found that the initial definitions of “Choice” and “Evidence” could overlap. The learner-facing scaffold and the separate teacher/editor pack now distinguish the three moves explicitly:

- **Choice:** name the creator’s linguistic or visual-design decision (for example, personification).
- **Evidence:** quote the precise wording or identify the observable visual detail demonstrating that decision.
- **Effect in context:** explain a plausible inference or audience effect and connect it to the moment and relevant context.

The worked example, learner response frame and regression test were aligned to this distinction. The founder approved this exact content version on 26 October 2026. The refinement is included in that approved content candidate. It is not a separate academic-review pass or release decision; other review gates remain open.

## Pre-selection photograph rights record

- **Selected image:** “Bus stop with platform during night.jpg” by Mateusz Konieczny.
- **Source:** https://commons.wikimedia.org/wiki/File:Bus_stop_with_platform_during_night.jpg
- **Licence:** CC0 1.0 Universal Public Domain Dedication, as stated on the file page: https://creativecommons.org/publicdomain/zero/1.0/.
- **Date checked:** 26 October 2026, before committing the replacement image URL.
- **Visual screen:** Night-time bus stop/platform, bus sign, orange streetlights and distant headlights; no identifiable people or visible commercial branding observed.
- **Process standard:** All photographs must be screened and documented before selection under `docs/ENGLISH_PUBLIC_SOURCE_REGISTER.md`; free-to-use/royalty-free alone is not sufficient.
- **Open status:** Source-level CC0 check complete; full unit-level rights review, accessibility review, academic review and release approval remain separate.


## Mandatory shared-standard migration — 30 October 2026

The founder has approved `docs/TEACHER_PACK_AND_FEEDBACK_STANDARD.md` and `docs/CONTENT_ORIGINALITY_AND_RIGHTS_PROTOCOL.md` v2.0. This supersedes earlier permission for short platform-original reading passages. The v2 main prose passage and transfer micro-extract are now legacy stimuli and must be replaced by separately registered public-domain excerpts. Record stable Excerpt IDs and exact Source IDs in `docs/LITERARY_EXCERPT_SOURCE_REGISTER.md` before use.

Revise the full teacher-only pack so every objective item has the answer, question-specific reasoning and a rationale for each alternative; ordering/matching tasks must explain the sequence or pairing logic. Typed responses need a question-specific length, model response, accepted interpretations and item-specific feedback. Audit all other mini-texts and stimuli during this work. The existing 26 October founder content approval remains historical for the exact former v2 only; the revised version requires fresh review. This MYP revision is first in the new migration sequence, followed by Cambridge Stage 7 and then CBSE Grade 6.

## Historical Version 3 reconciliation — 30 October 2026

**Current candidate:** version 3, “How writers and creators shape meaning”, prepared on the existing branch `feat/myp-y1-unit1-v2` in draft PR #14. This section supersedes the earlier “What must happen next” and version 2 current-status paragraphs above for present-day work. The earlier v1/v2 records and their approvals remain historical and unchanged.

### Source selection and replacement

- Main reading: Charles Dickens, *A Christmas Carol in Prose, Being a Ghost Story of Christmas* (London: Chapman & Hall, 1843), Stave I, “Marley's Ghost”. Exact excerpt anchor: `EXC-IB-MYP-Y1-U1-MAIN` / `SRC-IB-MYP-Y1-U1-001`.
- Independent transfer: Lewis Carroll, *Alice's Adventures in Wonderland* (London: Macmillan and Co., 1866-dated issue), Chapter I, “Down the rabbit-hole”. Exact excerpt anchor: `EXC-IB-MYP-Y1-U1-TRANSFER` / `SRC-IB-MYP-Y1-U1-002`.
- The two Source IDs were registered before the corresponding excerpt-bearing candidate files were committed. Both extracts are original-English historical texts, not modern translations or adaptations.
- The source-level rights term check covers India and the United Kingdom only. Exact editions, locations, text anchors and applicable term calculations are recorded in `docs/LITERARY_EXCERPT_SOURCE_REGISTER.md`. The United States and other territories are not cleared by this record. Final unit-level rights approval remains open.
- The existing bus-stop photograph by Mateusz Konieczny remains in the poster because the Wikimedia Commons file page expressly records CC0 1.0. Poster wording/layout are platform-authored. The photograph's source/CC0 check does not close the separate unit-level rights or accessibility gates.

### Version 3 learning and assessment revision

- Replaces both platform-written v2 stimuli and rewrites all five dependent practice items and the independent exit ticket.
- Retains the choice → evidence → effect-in-context teaching sequence and current site design/navigation. Adds visible vocabulary support for Victorian language and the Carroll transfer extract.
- Entry observation: 15–25 words. Typed practice: Q2 40–55 words; Q3 65–85 words; Q4 45–65 words; Q5 45–65 words. Independent exit response: 45–60 words. Guidance appears before each input and is not enforced as a limit.
- Teacher pack v3 supplies an entry model and response guide; Q1 exact correct answer and question-specific reasoning plus a separate rationale for all four options; and for every typed practice response and the exit task, model response, evidence targets, accepted interpretations, strong/developing/weak traits, tailored feedback and an actionable next step.
- Learner data contains no correct-answer IDs, model responses, per-option rationales or teacher scoring bands. A build-time guard checks browser assets for teacher-only markers.
- No automatic grading, live AI marking, grading API, authentication, persistence, payments or release infrastructure is added. Responses remain temporary and ungraded.

### Version-specific review state and open gates

| Gate | Version 3 state | Notes |
|---|---|---|
| Founder content approval | **Approved 30 October 2026** | Applies to the exact v3 learner and teacher/editor content candidate; prior v1/v2 approvals remain historical. This is not a human academic-review pass or release approval. |
| Human academic review | Pending | AI-assisted drafts are not human validation. Review every question, answer, option rationale, model response and feedback item. |
| Official IB mapping | Unverified | Applicable current detailed Year 1 guide edition and objective/strand mapping are not verified; official code array remains empty. |
| Rights | Source-level India/UK term checks recorded; unit-level approval pending | US and other territory use not cleared; separately verify each edition, translation and visual asset. |
| Age/level and context suitability | Pending | Review Victorian vocabulary, syntax, genre/context and transfer task with the actual learner level. |
| Accessibility | Pending | Automated responsive tests are not a full accessibility audit; manual keyboard, screen-reader, contrast, reflow and hosted visual checks remain. |
| Release approval | Not approved | Keep v3 unreleased and separate from production content. |

### Technical and PR record

- PR #18 was merged to `main` on 30 October 2026 (merge commit `72689a529c3d2c4b1961803ea88d95e77a87c8ba`).
- PR #14 remains draft and unmerged. Work remains on its existing branch; no duplicate PR was created.
- The current main-branch site shell and navigation are retained. The learner app imports `pilotLearnerLesson.ts` and does not import `pilotLessonPack.ts`.
- GitHub Actions Build check [#279](https://github.com/gradioprep/gradioprep-website/actions/runs/41008214446) passed on commit `5308b81fd067b49ce0f6573ad36478a3094a2b41`: TypeScript/Vite production build successful; teacher-pack separation guard verified across one browser JavaScript asset; 13/13 Chromium tests passed, including URL/navigation checks, v3 extract/response-range checks and responsive overflow at 360, 390, 768, 1024 and 1440 CSS pixels. Cloudflare Workers branch-preview build `3b783bde-53e0-4b12-8106-f776d03901a6` succeeded. This is a preview build, not a production deployment. Manual accessibility and content/rights review remain open.
- No merge, production deployment, DNS change or Cloudflare setting change is part of this candidate.

### Forward-looking passage and live-counter update — 30 October 2026

The founder's later threshold decision does not change this v3 candidate: its Dickens and Carroll public-domain extracts, learner questions, current response ranges, model responses and teacher/editor pack remain unchanged. For new/materially revised passages, project-original text up to and including 250 words is allowed; over 250 words requires a recognised writer's verified public-domain work.

At the time this 30 October record was written, the next code integration was the retrospective live word counter across all six existing typed-response fields. That retrofit is now complete and verified in GitHub Actions run #295. Existing response ranges and approved v3 content remain unchanged. Apply the shared counter to all later typed-response fields.


## 18. Historical retrospective MYP v3 live-counter implementation — 30 October 2026

The word counter is implemented on the existing PR #14 branch in commit `0a90f3eb550bba9e7b17e7db1594826f28e1cca7`. It is a shared reusable client-side component and one lexical word-count helper. All six existing learner-facing typed-response fields display their approved current/ideal target: entry 20; Q2 50; Q3 75; Q4 55; Q5 55; exit 50. Their expected ranges remain unchanged: 15–25; 40–55; 65–85; 45–65; 45–65; and 45–60 respectively.

The counter updates from the controlled text value when the learner types, pastes, edits, deletes or clears. It counts Unicode letters/digits as lexical words, ignores punctuation-only tokens and counts contractions/hyphenated compounds as one. It continues above the ideal (for example 59/50); no input cap, `maxLength`, blocked review action, grading, saving or submission has been added. Each textarea is programmatically linked to its counter, which is announced through a polite status region.

Playwright tests cover the six initial counts, accessible linkage to prompt/range/count, word tokenisation, real clipboard paste, typing/editing/clearing, no `maxLength`, and over-target response preservation. GitHub Actions run #295 passed on 31 October 2026. The existing v3 content and separate teacher/editor pack are unchanged. No Cambridge/CBSE content revision, merge, production deployment or Cloudflare configuration change is included.

**Unchanged independent gates:** fresh human academic review, current official IB mapping, final unit-level rights/territory review, age/level suitability, manual accessibility review and explicit release approval remain open. Do not start Cambridge until the MYP technical verification and remaining review/authorization checkpoint are addressed.

## 19. Historical MYP v3 editorial, source and accessibility checkpoint — 31 October 2026

### Current official-source position

The current public IB Language and Literature page confirms the six skill areas and broad text/context/audience/purpose scope. The current public assessment page says school-based tasks are created and marked by teachers against prescribed objectives/criteria. The public subject brief is dated “From 2014”; the indexed detailed guide is for use from September 2014 or January 2015. Enhanced MYP beta planning guidance identifies 2027 as its full-release year. These sources do not verify the applicable current detailed Year 1 subject guide. Keep official mapping unverified and codes blank; use legacy A–D only as an internal historical audit lens.

### AI-assisted editorial review

The 31 October desk review is recorded in `docs/PILOT_UNIT_REVIEW.md`. It checks prompt-to-model fit, answer/distractor logic, response-range fit, evidence targets, feedback specificity and learner/teacher data separation. All six current model answers were counted with the project convention and fall inside their preserved ranges (entry 17/20 target; Q2 47/50; Q3 72/75; Q4 45/55; Q5 45/55; exit 48/50). No passage, question, prompt, range, answer, model or teacher-pack content was edited during this pass.

At the 31 October v3 desk-review checkpoint, two human-review points remained: Q4's model quotation capitalization differed from the exact excerpt (“On a large scale” versus “on a large scale”); Q3's teacher/model mention of a “bright shelter” did not align with the then-current visual description/alt text. These historical v3 flags were resolved as targeted edits in the separate v4 candidate described in Section 20; v4 now requires its own fresh founder and human academic review.

### Rights/source record

The Dickens and Carroll excerpt bodies are 95 and 129 words respectively under the project's lexical method. The registered English historical editions and their passage anchors were rechecked against their source records. The source register documents India Copyright Act section 22 and UK CDPA 1988 section 12 term calculations for the underlying works. The Commons file page for the existing night-bus photo states CC0 1.0 and names Mateusz Konieczny. These are source/file-page checks, not final unit-level legal/territory clearance, verification of the visual fit or a blanket clearance for other territories. Unit-level rights, exact image/alt-text consistency and any other relevant visual rights remain pending.

### Accessible response context

The response textareas now reference three pieces of information through `aria-describedby`: the exact question/entry/exit prompt, the expected response-range guidance and the live word count. The Playwright test verifies those IDs, visible prompts/ranges and accessible field names. GitHub Actions run #295 passed the build, separation check and 16/16 Chromium tests. This is code-level and automated evidence only; human screen-reader, keyboard/focus, contrast, zoom/reflow and cross-browser review remain pending.

### Independent gates and sequencing

- Founder approval: recorded for exact v3 on 30 October 2026; not release approval.
- AI-assisted editorial review: completed 31 October; two minor human-review points above remain.
- Human academic validation: **pending**.
- Exact current official Year 1 mapping: **unverified**; no codes assigned.
- Unit-level rights/territory and visual review: **pending**.
- Age/level/context suitability: **pending**.
- Manual accessibility: **pending**.
- Release approval: **not granted**.

PR #14 remains draft and unmerged. The counter/source/desk review do not authorize Cambridge. Proceed to Cambridge Stage 7 only after the remaining MYP academic, mapping, rights, suitability, accessibility and authorization requirements are resolved and the founder explicitly approves the next step.


## 20. Version 4 editorial corrections and current gate state — 31 October 2026

The current PR #14 candidate is v4. It preserves the v3 lesson structure, both reading passages, all questions/prompts, response ranges, item IDs and teacher-pack architecture. Version 3 founder approval (30 October 2026) remains recorded for v3 only. Version 4 was approved by the founder / project owner on 31 October 2026 for exact learner/teacher content, human academic review and age/level/context suitability. This is not release approval.

- Q4 model-answer quotation casing is corrected to the original lowercase “on a large scale”.
- Q3's unsupported “bright shelter” wording is removed. The exact Commons photograph was visually inspected and shows an open, raised paved platform, sign, orange streetlights, nearby tree and approaching headlights, with no shelter. Learner/teacher comparison language and visual description/alt text now align with the visible evidence.
- Six live counters remain on entry/Q2/Q3/Q4/Q5/exit with ideal targets 20/50/75/55/55/50 and unchanged ranges 15–25, 40–55, 65–85, 45–65, 45–65 and 45–60. No cap, truncation or `maxLength` is used. Run #295 verifies v3 only; v4 CI final v4 run #352 passed the TypeScript/Vite build, teacher-pack separation and 16/16 Chromium tests for the PR #14 branch snapshot at commit `c157ed2470e9c0e94e6758c075bb71484b767002`.
- MYP Year 1 independent Top Five remains complete and already applied. No repeat audit is required.

Unit-level image/text rights and territory review, manual accessibility, and explicit release approval remain open. Exact current official IB Year 1 mapping remains unverified; do not assign codes. Cambridge Stage 7 independent Top Five research is authorized and may proceed; learner-content/teacher-pack/counter migration remains after MYP rights/territory and manual accessibility gates are closed.
