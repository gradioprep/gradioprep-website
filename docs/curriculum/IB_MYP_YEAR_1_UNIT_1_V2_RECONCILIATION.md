# MYP Year 1 Unit 1 — Version 2 Reconciliation and Review Record

**Version:** 1.0  
**Date:** 26 October 2026  
**Status:** Founder-approved content candidate; separate review/release gates remain open in draft PR #14.  
**Unit:** IB MYP Language and Literature Year 1, Unit 1.  
**Content version:** 2 — “How writers and creators shape meaning”.  
**Guide baseline:** Approved guide v1.1 and implementation structure v1.2.  
**Important:** This record is not an official IB mapping, academic-review pass, rights clearance, accessibility approval or release authorization.

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

## 5. What must happen next

1. Complete and record the separate academic review of the founder-approved version 2 content and teacher/editor pack.
2. Complete academic, rights, accessibility, age/level and cultural/context checks separately.
3. Keep official objective/strand codes blank unless the applicable current IB guide is verified.
4. Merge/deploy content/app changes only after required checks for the intended status are addressed; founder content approval alone is not release approval.
5. The production rotation now advances to Cambridge Lower Secondary English Stage 7 Unit 1. Review the existing draft in PR #12; do not create a duplicate. Stage 7 must pass its own review gates before implementation/release.

## 6. Current PR and deployment status

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
