# IB/IGCSE Learning Platform — Master Project Brief

**Version:** 2.8  
**Last updated:** 25 October 2026  
**Status:** Frontend prototype deployed to Cloudflare Workers; pathway navigation live-verified; pilot lesson content review passed for preview version 1 (not a commercial launch)  
**Working name:** “Criterion Lab” (placeholder only; brand and domain are not yet final)  
**Founder context:** 18 years of IB, IGCSE and SAT tutoring experience; founder will initially be the sole grader and academic lead.  
**Initial geography:** Delhi-NCR, then wider India  
**Initial promotion channel:** LinkedIn only for the first few months  
**Initial cash posture:** near-zero build budget; founder is willing to buy a domain. Do not assume paid cloud/API usage until approved.

---

## 1. How to use this document as the source of truth

This file is the canonical product/business specification. When starting a new AI chat or account, upload this file and paste the “New-chat kickoff prompt” near the end. Do not rely on the previous chat being available.

When a decision changes, update this file first or ask the assistant to produce a revised version. Keep it in a private GitHub repository at `docs/PROJECT_MASTER_BRIEF.md` once the repository exists. Do not place credentials, API keys, student data or private customer information in this document or in Git.

**Decision precedence:**
1. This latest master brief.
2. A newer, explicitly approved revision of this brief.
3. Earlier chat messages, which may contain superseded ideas.

Do not silently change approved prices, credit rules, curriculum scope, SLAs or roles. If a conflict is found, call it out and ask before changing the specification.

### Approved and reviewed work remains revisable

**No feature, design, policy, content item or document becomes permanently frozen merely because it has been reviewed or approved. Any and all approved/reviewed features and documentation may be updated or changed at a later date.** Keep changes in Git history; record the affected version, date and reason; update dependent documentation; and re-review the parts affected by a material change. A later version does not inherit the previous version's approval automatically. Changes to protected business rules or design-system tokens still follow their existing explicit-approval requirements. This is a change-control rule, not permission to silently override an approval.


**v2.0 change note — 25 October 2026:** The owner approved a site-wide visual-composition improvement on top of Palette B. Typography remains locked. The shared design system now specifies three spacing tiers, selective plum-charcoal bands, stronger visual section breaks, grouped IB/Cambridge pathway introductions on the homepage, and colour-coded, more spacious lesson stages with restrained visual motifs for younger learners. See `docs/DESIGN_SPEC.md` v0.7 for implementation rules.

**v2.1 change note — 25 October 2026:** Refined the Pathways catalogue with slim taxonomy bands and dividers for IB MYP, Cambridge Lower Secondary and Cambridge IGCSE. Added a consistent generous gap and differentiated panel treatments for unit planning, reviewed pilot preview and release-readiness details. Palette B and typography remain locked; content mapping and release status are unchanged.

**v2.3 change note — 25 October 2026:** The owner approved a curriculum-first information architecture. The Pathways page is a catalogue only; it must not display a default-selected pathway's unit plan, pilot preview or release-readiness panels beneath the catalogue. Selecting a pathway opens its curriculum/subject destination; selecting a specific year, stage or verified syllabus opens that level's own plan; selecting a unit opens its unit detail/learning view. Reusable templates are allowed, but content, objectives, sequence, assessment and mapping must remain specific to the selected curriculum, subject, level and applicable syllabus edition. Keep provisional grade-equivalent labels as navigation aids only; never treat them as separate qualifications or syllabus routes without verification. Use breadcrumbs and contextual level/unit navigation. This decision supersedes the v2.1 and v2.2 descriptions that placed planning, pilot-preview and readiness panels beneath the Pathways catalogue. No code has been changed by this documentation decision.

**v2.4 change note — 25 October 2026:** Implemented the approved curriculum-first Pathways navigation in the React prototype. The catalogue now contains three programme/subject route cards only; curriculum destinations list planned levels, level destinations list that level's unit slots, and unit detail views show the appropriate planning/pilot metadata and readiness checks. Added contextual breadcrumbs and curriculum-aware header text. No curriculum mapping, review outcome, release status, palette or typography was changed. The route transitions use temporary client-side state and do not create production deep links or persistence.

**v2.5 change note — 25 October 2026:** Added pathname-based URL navigation on `feature/pathway-url-navigation`. Pathways catalogue, curriculum/subject destinations, supported programme-level destinations, unit details and the one pilot lesson have canonical direct-link routes. The address bar is the navigation source of truth; in-app navigation records browser history and back/forward re-resolves the current pathname. Breadcrumbs retain course/level/unit context. Routes are resolved against existing course and pathway data; provisional IGCSE grade-equivalent bands and unverified syllabus editions do not get standalone level/syllabus routes. This change does not alter curriculum content, objective mapping, academic-review, rights, accessibility or release statuses. Build checks, pull-request review and live deployment verification are separate and must be recorded from their actual results.

**v2.6 change note — 25 October 2026:** Added automated Chromium browser checks for the URL-based curriculum navigation. The tests load direct catalogue, curriculum, supported level, unit and pilot-lesson URLs; walk through the route sequence; exercise browser Back/Forward; and confirm provisional IGCSE grade-equivalent routes remain unavailable. The GitHub Actions workflow builds the app, installs Chromium, then runs these checks against the locally served Wrangler assets. The suite passed 9/9 in Chromium on commit `e7f3982aecacb8d069ce7a6877235bd538bf4d22` (GitHub Actions run 57); the corresponding Cloudflare preview build also succeeded (`4bae1e4d-8f23-46d9-a974-fe58ba1e3e4e`). The preview branch and unique-deployment URLs are recorded in PR #10. These checks do not mean the PR is merged or that live production is updated; production verification remains separate. No curriculum content, official mapping, academic-review, rights, accessibility or release statuses were changed.

**v2.7 change note — 25 October 2026:** Added consistent in-page Previous/Next navigation to each supported curriculum, level, unit and lesson view. Buttons move through the actual route hierarchy and planned unit sequence while preserving the programme/subject context. A missing next destination is explained rather than invented; in particular, Cambridge IGCSE does not offer level navigation until its syllabus and level structure are verified. The unselected Pathways catalogue remains a catalogue with no default-selected curriculum. Automated Chromium coverage now passes 11/11 tests in GitHub Actions run 63 on commit `035b3a6d37d9df05dbe0ab6b2371b6fdc5998cb8`; this includes in-page navigation across Cambridge Lower Secondary unit slots and the IGCSE guardrail. The corresponding Cloudflare preview build succeeded (`51726b35-1247-4223-8778-2c878301fe48`). No curriculum content, mapping, review outcome, rights, accessibility or release statuses changed.

**v2.8 change note — 25 October 2026:** PR [#10](https://github.com/gradioprep/gradioprep-website/pull/10) was merged into `main` as commit `7d8d4ff53eaab5cef468bc4e0d3b633e51907e25`. GitHub Actions run [#64](https://github.com/gradioprep/gradioprep-website/actions/runs/64) passed on PR head commit `d202e0afa80c50d5c47048c6f2c86d6a8950eceb`, including the build and all 11 Chromium browser tests. Cloudflare Workers production build `99301a5d-91f7-4939-af95-f356f20268a7` succeeded and deployed the merge commit at `2026-10-25T17:26:16.522Z` (UTC). Live preview: [GradiPrep website](https://gradioprep-website.wandering-scene-1822.workers.dev). After deployment, the owner confirmed the Pathways flow, in-page Previous/Next controls, browser Back/Forward, and direct URLs work. This verifies the pathway-navigation deployment only; it does not indicate commercial-launch readiness or change curriculum content, official mapping, academic review, rights, accessibility or release statuses.

### Approved information architecture — binding product decision

The approved navigation hierarchy is:

1. **Homepage:** explain the product and provide a route to pathway discovery.
2. **Pathways catalogue:** compare available curriculum routes only. Show programme taxonomy, subject/course cards, brief descriptions and accurate availability caveats. Do not render any selected pathway's unit plan, pilot preview, release-readiness checklist or other level-specific planning details on this page. There is no default-selected curriculum whose details appear below the catalogue.
3. **Curriculum and subject destination:** identify the chosen programme and subject/course, explain the route, and offer only the relevant level choices that the product actually supports.
4. **Specific year, stage or syllabus destination:** show the plan and learning sequence for that exact programme, subject and level, including applicable objectives, unit sequence, assessment approach, available learning materials and accurate review/mapping/release statuses.
5. **Unit detail and learning view:** show that unit's purpose, skills, lessons, practice, explanations and relevant assessment activities.

The normal discovery path is Homepage → Pathways catalogue → Curriculum/subject → Year/stage/verified syllabus → Unit → Lesson/practice. Breadcrumbs and contextual navigation must let users return to the parent destination without losing curriculum context. Direct links to a level, unit or lesson must retain or clearly display the full curriculum context.

**Data and curriculum integrity rules:**
- Keep programme, subject/course, year/stage, qualification, syllabus edition, objective, unit, task and rubric as distinct data concepts; do not infer equivalence from similar labels.
- IB MYP Language and Literature, Cambridge Lower Secondary English and Cambridge IGCSE First Language English are separate routes with distinct structures. Do not merge their requirements into a generic Grade 6–10 plan.
- Cambridge grade-equivalent labels are navigation aids only. They must not create a separate qualification, syllabus or curriculum route unless official requirements and the founder-approved roadmap establish that route.
- Reuse page templates and components where useful, but never reuse one curriculum's unit plan, objectives, sequence, assessment or mapping as if it applied to another curriculum or level.
- Academic content review, official curriculum mapping, rights review, accessibility review and release approval are separate statuses. A passed review must not imply official mapping or release.
- Do not fabricate syllabus coverage or present planned/unverified content as available. The starter pathway is not exhaustive syllabus coverage.

**Implementation and change-control rule:** The approved curriculum-first architecture is implemented in the frontend prototype as of 25 October 2026. Preserve the approved Palette B, typography, spacing and current content/status wording unless separately approved. Update this master brief and the design specification together if the architecture changes in future. This decision supersedes any older wording in either document that instructs placing planning, pilot-preview or readiness panels below the Pathways catalogue.

### Current implementation state

As of 25 October 2026, the React + TypeScript frontend prototype implements four contextual pathway views inside the Pathways destination: (1) a catalogue containing only three programme/subject route cards; (2) a curriculum/subject destination listing the planned levels for that route; (3) a specific level destination with its three planning slots and distinct mapping/release statuses; and (4) a unit detail destination containing the relevant pilot preview metadata and readiness gates where applicable. The catalogue has no default-selected route and does not render unit plans, pilot previews or readiness checklists beneath its cards. Breadcrumbs and contextual navigation return to parent views, the app header reflects the selected curriculum context, and a consistent in-page Previous/Next control bar lets learners move to the parent or next supported destination without using browser controls.

The route model is a lightweight pathname-based frontend router (without adding a routing dependency). Canonical paths follow `/pathways/{programme}/{subject}`, then the existing official programme-level code, then `/units/unit-{sequence}`; the pilot lesson uses that unit path plus `/lesson`. Direct URLs render the appropriate destination, browser back/forward restores the destination from the address bar, breadcrumbs preserve programme/subject context, and each selected curriculum/level/unit/lesson view offers in-page Previous/Next controls. The next control is disabled or replaced by an explanation when the next content cannot be offered safely. Unknown paths render an unavailable-destination message. Routes are generated from the existing catalogue data only: no verified Cambridge IGCSE syllabus edition is assigned, so no IGCSE syllabus/grade-equivalent level routes are created. This is still a frontend prototype and does not add a database or persistent learner records. The catalogue in [`../src/content/pathways.ts`](../src/content/pathways.ts) contains 10 planned pathway/level entries and three unit slots per entry. The three course routes are IB MYP Language and Literature, Cambridge Lower Secondary English, and Cambridge IGCSE First Language English. IGCSE grade-equivalent bands remain provisional navigation aids, not separate qualifications or confirmed syllabus routes. The first IB MYP Year 1 unit remains approved for pilot preview only; official syllabus edition and objective mapping remain unverified, and separate rights, accessibility and release approvals remain outstanding. Authentication, database, persistent learner records, production grading, payments and production analytics are not implemented.

The first IB MYP Year 1 planning slot has a teacher/editor unit brief (`../src/content/pilotUnitDraft.ts`), a learner-safe lesson data file (`../src/content/pilotLearnerLesson.ts`), a non-answer review summary (`../src/content/pilotReviewSummary.ts`) and a separate teacher/editor source with answer keys (`../src/content/pilotLessonPack.ts`). Academic content review for pilot-preview version 1 was confirmed as passed by the project owner on 24 October 2026; the reviewer’s personal name was not supplied. The Lesson screen now provides an interactive learner preview with a passage, four teaching steps, four practice tasks, written-response fields and self-review checklists. Responses remain in temporary component state only; they are not graded or persisted.

The client app and readiness fixture use the learner-safe lesson and non-answer review summary. Neither the teacher/editor unit brief nor the teacher answer guide is imported into the client module graph. This is source separation for the static prototype, not a substitute for server-side authorization in production.

The public [IB MYP Language and literature page](https://www.ibo.org/programmes/middle-years-programme/curriculum/language-and-literature/) and its [subject brief marked From 2014](https://www.ibo.org/globalassets/new-structure/brochures-and-infographics/pdfs/myp-brief-language-literature-en.pdf) were checked on 24 October 2026. An IB-hosted [Language and literature guide reference](https://resources.ibo.org/data/m_1_langa_guu_1405_8_e.pdf) surfaced candidate Year 1 Criterion A strands A(ii) and A(iii); the detailed guide redirects to IB curriculum sign-in and the applicable current school-guide edition remains unconfirmed. These are candidate references, not verified mappings. `officialObjectiveCodes` remains empty, so syllabus mapping and the official-source/objective gates remain blocked. In the static readiness fixture, the pilot lesson and practice IDs, answer-key review and academic-review pass are now recorded. Separate rights review, accessibility review and explicit release approval remain outstanding. The content is approved for pilot preview only, not a released syllabus-mapped course. The pathway-navigation changes are deployed and live-verified as recorded in v2.8; this confirms the navigation milestone, not commercial readiness or curriculum/release approval. The prototype still has no database, authentication or persistent learner records. The commercial hosting choice remains open pending review of current vendor terms, security controls and operational requirements.

### Approved frontend typography, text-colour and palette guardrail

For every existing and future page, `docs/DESIGN_SPEC.md` Section 2 and the design tokens in `src/styles.css` are authoritative. Reuse the shared Manrope heading, DM Sans body and DM Mono metadata fonts, the approved size tokens, utility classes and semantic text-colour roles. Do not add one-off font families, smaller text, pale grey text on light backgrounds, or new grey hex values simply to style a new page.

The current text tokens are `--text-primary: #28242D`, `--text-secondary: #514B57` and `--text-inverse: #F7F8FC`; `--muted` is also `#514B57`. On 25 October 2026, the owner explicitly approved Palette B for the whole site: aubergine and contrast-tested dusty blue for brand emphasis and interaction; cool white and white for primary surfaces; soft lilac and pale blue-grey for learning panels; plum charcoal for selected dark sections; deep blue for positive feedback; and muted amber for improvement guidance. Buttercream is restricted to small accents. The design spec v0.6 and tokens in `src/styles.css` are the source of truth for exact palette and semantic roles. This change does not alter font families, typography sizes, weights, line heights, letter-spacing, layout spacing or feature behaviour. The earlier 1.5× increase to originally ≤10px typography has already been applied to the current CSS; do not scale it again. New non-decorative text must be at least 10.5px, and running text should normally be 13.5–15px or larger.

Any proposed change to these rules requires explicit founder approval and a coordinated update to the design spec and CSS tokens. Future-page work must preserve font weight, style, line-height, and letter-spacing unless a change is expressly approved.

## 2. Product vision and positioning

Build a curriculum-aware learning platform for IB and Cambridge learners, starting with English and adding Mathematics after the first English launch.

The product is **not** a tuition agency or tutor network. It is a structured independent-learning platform supported by a controlled human-grading service.

Core promise: **“Know what to practise next—and see whether you have improved.”**

The primary market gap to test is not a lack of notes alone. It is the gap between finding resources and making measurable progress: students need syllabus navigation, structured learning aids, strong questions, worked explanations, targeted practice, saved attempts, revision history and (as a premium service) trustworthy human assessment.

Grading is an important differentiator but is not the entire product. The free resources and paid study materials must be useful and polished enough to establish trust before a student purchases grading.

## 3. Target programmes and Stage 1 English scope

Curricula must not be treated as interchangeable. In the data model, keep programme, course, year/stage, subject, syllabus edition, skill objective and task/rubric identifiers separate.

Initial planned English pathways:

- IB MYP Language and Literature: Years 1–5, mapped approximately to school Grades 6–10 for familiar navigation.
- Cambridge Lower Secondary English: Stages 7–9, mapped to school-grade equivalents only as a user-facing convenience.
- Cambridge IGCSE First Language English: Grade 9–10 equivalent pathways, using the relevant current syllabus edition.

These are distinct pathways. “Grade 6–10” must not be used as if Cambridge IGCSE were a qualification for all five grades. Course and syllabus mapping must be verified against official specifications before content publication. Cambridge IGCSE English as a Second Language is not part of the first complete-content release; demand may be gathered for a later phase.

**Stage 1 is a starter pathway, not complete coverage of every syllabus.** Never market Stage 1 as an exhaustive course.

Initial content target, to be adjusted against the founder's final roadmap:

- 10 level/pathway entries.
- Approximately 3 skill units per pathway (about 30 units).
- Approximately 300 original short-form practice items across the initial pathways.
- Approximately 30 extended-response tasks across the initial pathways.
- Each pathway has a diagnostic, annotated example(s), common-mistake guidance, marking/assessment guidance and a route to the next skill.

These numbers are production targets, not permission to publish unverified content. Quality gates take precedence over item count. The founder will finalise the exact curriculum roadmap, sequence and skill coverage before bulk content creation.

## 4. The student-facing product

### Free Explorer — ₹0

- Curriculum/course discovery and syllabus map.
- Initial diagnostic and selected sample lesson(s).
- Selected questions and explanations that demonstrate quality.
- Partial access to the question bank and learning pathways.
- **One free human-graded task per student account**, selected from a syllabus-mapped task library.
- Free grading SLA: within 72 elapsed hours after the submission is accepted.
- One free assessment is total, not one per topic/course/grade. Changing a selected topic or pathway does not create another free review.

### Study Lab — proposed ₹199/month

- Access to released Stage 1 study materials.
- Structured curriculum aids, skill explanations, annotated examples and common errors.
- Searchable/filterable question bank.
- Answer explanations and marking guidance appropriate to each task.
- Diagnostic-led targeted practice and rule-based next-step recommendations.
- Timed practice/mini-mocks where available.
- Saved attempts, skill/error log and real-time progress dashboard.
- Monthly report generated automatically from existing analytics.
- No human grading included; grading credits are purchased separately.

₹199/month is a price hypothesis to validate with Indian families, not a proven willingness-to-pay figure.

### Future subject/product expansion
1. English first.
2. Mathematics using the same course/skill/question/attempt/progress engine.
3. Potential French, Spanish and German learning pathways after demand testing. The founder has background in these languages and can quality-check appropriate content. Start with one language only after English/Math demand and operations are validated.

## 5. Grading-credit commercial model

A grading credit represents **one clearly defined, syllabus-mapped assessment task**, not a universal word-count allowance. The task specification determines expected response format, response length, rubric, likely complexity and estimated grading effort.

Normal standard task target: about 15–20 minutes of grader time. Do not impose a generic word limit across all tasks.

Before a student submits, the platform must state:

- Task and curriculum mapping.
- What is included in the grading credit.
- The grading criteria/rubric family.
- The expected turnaround time.
- Whether the task requires more than one credit due to scope/complexity.

A full examination paper or complex multi-part task can require multiple credits. This must be explicit before submission, not decided after the student has submitted.

### Credit pack prices

- 2 credits: ₹798 (₹399 per credit).
- 5 credits: ₹1,995 (₹399 per credit).
- 10 credits: ₹3,990 (₹399 per credit).
- 20 credits: ₹7,980 (₹399 per credit).
- No bulk discount at launch; reviewer time per standard task is similar regardless of pack size.
- Credits valid for 6 months.
- Content subscription and grading credits are separate purchases.
- Regrading a revised response by a human consumes another credit.

At initial launch, 2- and 5-credit packs may be purchasable. 10- and 20-credit packs can be displayed as planned options but must remain unavailable until actual capacity supports their fulfilment.

### Turnaround SLAs

- Free human-graded task: within 72 elapsed hours after accepted submission.
- Paid standard task: within 48 elapsed hours after accepted submission.
- Urgent grading: within 24 elapsed hours, only by an eligible Master Grader and only when an urgent slot is available.
- Proposed urgent surcharge: ₹199 per urgent task, on top of the normal credit consumed.
- Turnaround hours include weekends. The system must not accept work under an SLA it cannot meet.

### Initial solo-grader capacity
Founder is the sole grader initially. Start with a conservative control limit:

- Up to 30 paid grading submissions per month.
- Target no more than 2 newly accepted paid submissions per day.
- Up to 4 free graded tasks per week.
- Up to 2 urgent tasks per week, counted inside the paid-review capacity rather than added on top.

These are initial capacity ceilings, not mandatory sales targets. Review actual grading duration and submission patterns after the pilot. Do not sell prepaid credit obligations that exceed the available fulfilment capacity. Show the capacity/queue status before submission. If no slot can meet the SLA, preserve the student's draft and credit without accepting the job.

## 6. Grader ratings, quality review and Master Grader status

Final grader rating uses two components, each weighted 50%:

`Final rating = (0.50 × verified client feedback score) + (0.50 × internal quality score)`

Both components are scored out of 5. Client feedback must come from verified completed tasks and cover the clarity, relevance, evidence and usefulness of feedback—not merely whether the student liked the mark.

Internal checks include:

- Curriculum and rubric alignment.
- Academic/marking accuracy.
- Whether feedback points to evidence in the student's response.
- Whether advice is actionable.
- Agreement between score, comments and rubric descriptors.
- Professionalism and consistency.

Founder/admins can increase or reduce an internal score after a comprehensive revaluation, with reasons and evidence recorded in an audit log. Invalid or abusive client ratings may be excluded only through documented moderation; do not silently delete negative reviews.

A new grader's rating remains provisional until they have at least 10 completed assessments and 5 verified client ratings.

Master Grader eligibility (proposed guardrails):

- At least 20 completed assessments.
- At least 10 verified client ratings.
- At least 4.75/5 overall rating.
- At least 95% SLA compliance.
- At least 4.75/5 across the latest 10 audited assessments.
- No unresolved serious quality complaints.

Admin can suspend/revoke Master Grader status if quality declines. At launch, the founder is labelled “Founding Academic Lead”; do not invent a performance rating before adequate assessment data exists. Urgent grading stays disabled until eligible capacity exists.

## 7. Private AI-assisted quality assurance

After the grader finalises an assessment, a private QA process may compare the grader's marks/comments with the founder-approved rubric and the student's task/response.

Potential QA outputs:

- Criterion alignment and omissions.
- Evidence support for comments.
- Mark/comment/rubric consistency.
- Missing important feedback.
- Actionability of next-step guidance.
- Contradictions or other concerns.
- QA status (e.g. green/amber/red), reasons and uncertainty/confidence indicator.

AI is a flagging assistant, not the final academic authority. Low-confidence flags must not automatically change marks or publicly penalise a grader. Significant flags can create an admin review task. The founder/authorised admin decides the final action.

The grader must not be able to read the private QA record. Enforce this with server-side authorization and database-level policies, not by merely hiding a UI element. Store QA records in a separate admin-only data structure.

Initial implementation can use a manually applied rubric/QA workflow with the API feature-flagged off. Enable OpenAI API calls only after the application flow is working and a spending limit is set. API keys must exist only in server-side environment variables. ChatGPT subscription access is not the same as OpenAI API billing.

Send the API only the minimum information required. Remove names, school/guardian contact details and other unnecessary identifiers. The product must be transparent about applicable retention and privacy policies and must not claim zero retention unless the actual configured service terms support that claim.

## 8. Autosave, versioning and administrator access

Every grader response autosaves while editing, with a visible save state. Preserve:

- Original student submission.
- Grader draft(s) and final assessment.
- All subsequent revised versions.
- Rubric/version used, scores and comments.
- Created/submitted/finalised/published timestamps.
- Changes to marks or comments, who made them and why.
- Admin QA reports and administrative actions.

The founder and authorised administrators must be able to retrieve assessment records even after publication or grader deactivation. Use role-based access with at least student/guardian, grader, admin and owner/super-admin roles. Admin roles should be individually assigned, auditable and revocable.

## 9. Real-time analytics and monthly report

The dashboard is the live source of truth; the monthly report is only a summary.

Students/guardians should see on login:

- Completed and attempted lessons/questions.
- Current skill/topic status and the evidence behind status changes.
- Saved attempts and revision history.
- Error log and recommended next objectives.
- Published human assessments and feedback.
- Pending submissions and due times.
- Remaining grading credits and credit-expiry dates.

Distinguish automatically checked practice from human-assessed work. Do not imply an AI score is an official IB/Cambridge grade or manufacture a grade prediction without validation. Monthly report is generated automatically from existing event/assessment data; no extra human grading is required.

## 10. Recommended technical approach and important Vercel constraint

Preferred maintainable architecture:

- Frontend: React + TypeScript.
- Source control: GitHub private repository.
- Database/auth/storage: Supabase, using role-based access and row-level security.
- Transactional email: Resend, added only as needed.
- Payments initially: manually verified UPI for a small pilot; later payment gateway + verified webhooks.
- AI QA: OpenAI API from server-side function only, feature-flagged until budget and privacy settings are reviewed.
- Domain: founder purchases and controls domain registration and DNS.

**Important Vercel policy constraint verified 23 October 2026:** Vercel's current Terms of Service state that its free Hobby plan is limited to personal/non-commercial use; commercial usage requires Pro or Enterprise. The terms also contain a model-training provision applicable to content on Hobby/trial Pro. Therefore, do not assume Vercel Hobby is an appropriate free host for a commercial learning platform or for student submissions. See: https://vercel.com/legal/terms and https://vercel.com/docs/limits/fair-use-guidelines.

The current React + TypeScript preview is deployed on Cloudflare Workers, and the pathway-navigation deployment is live-verified (see v2.8). This records the platform used for the prototype preview; it is not a final approval of the commercial hosting architecture and is not approval to store real student records. Before commercial use, verify current Cloudflare Workers product/plan terms, limits, data-handling practices, security controls and operational requirements. Keep the codebase portable; assess alternatives only against the founder's budget and actual launch requirements.

Do not commit credentials, `.env` files, API keys, student submissions or private data to GitHub. Use platform environment variables and rotate credentials immediately if exposed. See GitHub secret-scanning guidance: https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning.

Review current Supabase free-tier limits, pause/backup limitations and email sending limits before using them for production data. Export/backup important records and test restoration. Do not assume any free tier guarantees availability, backups or commercial rights.

## 11. Payments, plans and customer controls

- Study Lab subscription and review credits are separate entitlements.
- Track credit purchases/uses/refunds/expiry in an immutable or auditable ledger.
- Reserve a credit and fulfilment slot on acceptance; release/refund according to a clearly stated cancellation/failure policy.
- Exhausted credits block new human-reviewed submissions, but do not block free practice or access already included in Study Lab.
- Show price, credit requirement, estimated turnaround and SLA before submission.
- Do not accept additional work beyond the grading capacity limits.
- Do not let a student bypass the one-free-review rule by selecting another grade/topic or creating duplicate pathways; implement reasonable abuse safeguards without intrusive data collection.

## 12. First 30-day launch plan

### Days 1–15: Build English Stage 1

- Days 1–2: founder-finalised roadmap, syllabus mapping, content schema, role and database design.
- Days 3–5: repository, deployment, authentication, profiles, course/pathway pages.
- Days 6–8: reusable lessons, question bank, assessments, answers/explanations, diagnostic and rule-based next steps.
- Days 9–11: saved attempts, skill/error log, submission workflow, autosaved versioned grading interface and admin review.
- Days 12–13: integrate and quality-check the 10 initial pathways and practice items.
- Days 14–15: security/access tests, mobile QA, content verification, closed beta.

### Days 16–30: Validate and sell through LinkedIn

- Create educator pack: curriculum map, sample learning unit, question-bank excerpt, example of feedback, pricing and terms.
- Contact approximately 60 relevant educators with personalised outreach.
- Aim for approximately 10 substantive conversations and 3–5 pilot/referral partners.
- Invite students to use the free diagnostic, study materials and one free task-level graded review.
- Target 5–20 paying users by Day 30 as a hypothesis, not a guarantee.
- Measure activation, completion, revisions after feedback, paid conversion, review time, SLA performance and renewals.

LinkedIn is the only planned promotional channel for the initial months. Use helpful curriculum-specific posts and a sample diagnostic rather than generic ads. Do not assume reach or compliments equals paid demand.

## 13. Later sprints

- Mathematics: next 15-day content sprint after English is released and reviewed. Exact content sequence will be set by the founder's roadmap. Reuse the same platform architecture, add step-aware solutions and topic diagnostics.
- Foreign languages: survey demand after English/Math usage is understood; test one of French, Spanish or German first, based on demand and founder's quality-control capacity.
- Add more graders only after the rubric, training, calibration tasks, access controls, review QA and capacity planning work reliably.

## 14. Success metrics and operating gates

At minimum, measure:

- Diagnostic completion rate.
- First-week active learner rate.
- Practice completion and repeat attempts.
- Percentage of students who revise after receiving feedback.
- Free-to-paid conversion.
- Study Lab retention/renewals.
- Review turnaround compliance.
- Actual minutes per assessment.
- Reviewer consistency against the rubric.
- Refunds, disputes and complaint rates.
- Cost per paying subscriber and contribution after review/payment fees.

Do not scale marketing, prepaid credit sales or reviewer recruitment until service quality and actual usage justify it. The initial pricing, subscriber targets and demand estimates are hypotheses to validate, not guaranteed results.

## 15. Decisions still owned by the founder

The founder will finalise before bulk content creation:
1. Exact English syllabus roadmap, topics, task types and their sequence.
2. The rubric(s) for each task family and the criteria for multi-credit tasks.
3. Final brand/domain and public description.
4. The exact privacy, consent, refund, credit-expiry and service terms after appropriate review.
5. Whether to retain Cloudflare Workers for the commercial launch or adopt another hosting platform, after reviewing current vendor terms, pricing, data handling, security and operational requirements.
6. How academic-lead/reviewer calibration will be arranged before offering broad human-graded service.

The assistant must not invent these decisions or silently replace them with a generic curriculum.

---

## New-chat kickoff prompt

> We are continuing an approved product build. Read the attached `IB/IGCSE Learning Platform — Master Project Brief` completely and treat it as the source of truth. Do not silently change approved pricing, review-credit rules, SLAs, grader rating formula, curriculum scope, access-control requirements or the 15-day build/15-day validation plan. The founder has 18 years of IB, IGCSE and SAT tutoring experience and will initially be the sole grader and academic lead. The founder will finalise the curriculum roadmap. Start by summarising the current approved specification and identifying the immediate next action only; then proceed step by step, updating the master brief whenever a decision is explicitly approved. Keep all code, credentials and student data secure. Before choosing a vendor or relying on free-tier terms, verify current official documentation. The working name is a placeholder, not final. For frontend work, follow the locked typography and text-colour tokens in Section 1 and `docs/DESIGN_SPEC.md`; do not add ad-hoc font families, sizes or grey text colours, or change tokens without explicit approval.

## Official service-policy links to re-check before deployment

- Vercel Terms: https://vercel.com/legal/terms
- Vercel fair use/commercial use: https://vercel.com/docs/limits/fair-use-guidelines
- OpenAI transfer conversations between accounts: https://help.openai.com/en/articles/9106926-transferring-conversations-from-1-chatgpt-account-to-another-chatgpt-account
- GitHub secret scanning: https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning

**v2.2 change note — 25 October 2026:** The Pathways page received a spacing correction after visual review: reduce inter-group and planning-panel gaps by roughly half and tighten taxonomy-band-to-card spacing so each taxonomy clearly labels the cards immediately below. No typography or palette changes; the shared site-wide spacing system remains intact. The spacing adjustment remains applicable to catalogue groups; the below-catalogue planning-panel layout is superseded by v2.3.
