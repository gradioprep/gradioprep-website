# Criterion Lab — Design Specification

**Version:** 2.13  
**Status:** Approved design system and curriculum-first navigation; the diagnostic/report experience is specified to use a predominantly white/cool-white canvas, accessible high-quality charts and minimal tables/data blocks. The MYP Grade 9 taxonomy, high-level blueprint, detailed task-level item map, flagship response/grading plan, 24-hour SLA and Phase 0 architecture/timer/retention/provider decisions are Founder-approved. The screens below are design requirements and should not be treated as implemented unless verified in the current Preview. Phase 1B local synthetic-only coding is explicitly approved and underway in draft PR #22. The initial local Auth/account and protected Worker API slice passed exact-head CI run #41473237444 (RLS, builds and 15/15 Chromium tests); a public branch Preview for code-bearing commit `50f4bb3` is deployed and awaiting Founder visual review. A further local/synthetic security increment now blocks suspended application accounts at RLS and Worker API layers and adds an explicit sign-out-only account state; its fresh CI and Preview verification are pending. Hosted provisioning, paid services, real learner data, merge and production deployment are not authorised.  
**Last updated:** 2 November 2026  
**Product name:** “Criterion Lab” is a working name only. Final brand and domain are not approved.  
**Source of truth:** [`PROJECT_MASTER_BRIEF.md`](PROJECT_MASTER_BRIEF.md)

> This document translates the agreed visual direction into a buildable interface specification. The master brief takes precedence if any design suggestion here conflicts with an approved product rule. This is a design and interaction plan, not a claim that the described product features are already implemented.

**Revision policy:** Approved or reviewed screens, interactions, tokens and design documentation can be changed later. Record substantive changes in version control, update this specification when it is affected, and re-review the impact before release. The locked fonts, typography, palette and text-colour rules remain in force unless a specific change is explicitly approved.

**Version 0.6 change note — 25 October 2026:** The owner approved Palette B: aubergine, dusty blue, soft lilac and plum charcoal, supported by cool-white and pale blue-grey surfaces. Buttercream is restricted to small accents rather than large backgrounds. The palette is implemented through consistent semantic roles inspired by established EdTech design-system practices; no competitor brand system is copied. Typography, type sizes, font weights, line heights, letter-spacing and layout spacing are unchanged.

**Version 0.7 change note — 25 October 2026:** Added a student-friendly visual system without changing typography: three coherent spacing tiers for within-section relationships, lesson steps and major section breaks; selective plum-charcoal feature bands; visual IB and Cambridge pathway introductions before the pathway cards; more generous, colour-coded lesson stages; and restrained decorative learning motifs. Use illustration-like CSS/SVG elements, clear numbered stages and semantic colours instead of noisy decoration. Keep the approved Palette B tokens unchanged.

**Version 0.8 change note — 25 October 2026:** Added slim taxonomy bands with a divider and explicit curriculum labels before each Pathways catalogue group (IB MYP, Cambridge Lower Secondary and Cambridge IGCSE). Added a consistent, generous vertical rhythm and distinct surface/accent treatments for unit planning, reviewed pilot preview and release-readiness sections. Typography, approved Palette B tokens and content/release rules remain unchanged.

**Version 1.0 change note — 25 October 2026:** Owner-approved curriculum-first information architecture. The Pathways page is a catalogue only. Curriculum/subject details, a specific year/stage/syllabus plan, and unit-level learning details live in their appropriate contextual destinations. This supersedes the earlier instruction in Section 6 to stack unit-planning, pilot-preview and release-readiness panels after the final Pathways card group. Existing palette, typography and spacing decisions remain unchanged.

**Version 1.1 change note — 25 October 2026:** Implemented the approved curriculum-first flow in the React prototype: Pathways catalogue → curriculum/subject → level → unit detail. The catalogue contains three route cards only and has no default-selected pathway details beneath them. Curriculum and level views show their own contextual choices and status notes; unit detail displays pilot/release metadata and readiness gates only for the selected unit. Breadcrumbs and contextual header text preserve orientation. Navigation initially used local component state. Palette B, typography and curriculum/release status records remain unchanged.

**Version 1.2 change note — 25 October 2026:** Added canonical pathname-based routes for the catalogue, each curriculum/subject destination, existing official programme-level destinations, unit details and the approved pilot lesson. Route rendering is derived from the current URL, with browser `popstate` handling for back/forward and contextual breadcrumb navigation. Routes are data-driven and intentionally exclude provisional IGCSE grade-equivalent bands or unverified syllabus editions. No design tokens, curriculum mapping, content review or release statuses changed. Build and live deployment outcomes must be confirmed independently.

**Version 1.3 change note — 25 October 2026:** Added Chromium browser tests for direct curriculum URLs, the catalogue-to-pilot-lesson journey, Back/Forward history, and unavailable provisional IGCSE routes. Tests run against locally served Wrangler assets in CI. The current Chromium suite passed all 9 tests and the associated Cloudflare preview build succeeded on commit `e7f3982aecacb8d069ce7a6877235bd538bf4d22`; see PR #10 for build and preview URLs. Keep this separate from the manual check of the Cloudflare preview and production site; do not mark a live deployment as verified until it has actually been checked. The approved palette, typography, layout and curriculum/release statuses are unchanged.

**Version 1.4 change note — 25 October 2026:** Added a consistent in-page Previous/Next control bar to supported curriculum, level, unit and lesson destinations. Keep navigation contextual and route-driven, maintain programme/subject identity, and show a plain explanation instead of an active link when no safe next destination exists. Cambridge IGCSE level navigation stays unavailable until its applicable syllabus/level structure is verified. Do not add a default-selected pathway or navigation bar to the Pathways catalogue itself. Chromium checks passed 11/11 in GitHub Actions run 63, and the corresponding Cloudflare preview build succeeded on commit `035b3a6d37d9df05dbe0ab6b2371b6fdc5998cb8`. Palette, typography, spacing tokens and academic/release statuses remain unchanged.



**Version 1.6 change note — 26 October 2026:** Added a controlled, unlinked Cambridge Lower Secondary English 0861 Stage 7 Unit 1 v1.3 preview route for interface accessibility testing only (draft PR [#15](https://github.com/gradioprep/gradioprep-website/pull/15)). It reuses the approved font, typography, colour and surface tokens; introduces a visible unreleased-status notice, keyboard skip link, semantic section headings, accessible expandable word-help/model panels, task-specific text-field names with associated prompts, mobile reflow and a clear-all action. This is a test route, not normal navigation or release approval. No teacher/editor answer pack is in the client import graph; answers are not scored or persisted. GitHub Actions Build check [#229](https://github.com/gradioprep/gradioprep-website/actions/runs/40307651156) passed the TypeScript/Vite build and 17/17 Chromium tests. The final regression test verifies the clear-all action resets both typed responses and the warm-up radio choice. CI runs against local Wrangler assets; no dedicated hosted branch-preview URL is verified. Manual screen-reader and broader accessibility testing remain separate gates. No production deployment or public release is implied.

**Version 1.7 change note — 26 October 2026:** Final keyboard and responsive checks refined the Stage 7 preview: the skip link now transfers focus to the main lesson content, the exit-check question is programmatically associated with its response field, and the responsive-layout test covers 320/390/768/1024 CSS-pixel widths. Build check [#231](https://github.com/gradioprep/gradioprep-website/actions/runs/40308612925) passed the TypeScript/Vite build and 17/17 Chromium tests on commit `841c26ab5f3c0bd24d32cc88d839af015353eff9`. This remains limited automated evidence, not full accessibility certification, and is not approval to release. The preview remains unmerged and no production deployment is made.


**Version 1.5 change note — 25 October 2026:** PR [#10](https://github.com/gradioprep/gradioprep-website/pull/10) merged as `7d8d4ff53eaab5cef468bc4e0d3b633e51907e25`; the production Cloudflare Workers build `99301a5d-91f7-4939-af95-f356f20268a7` succeeded and deployed at `2026-10-25T17:26:16.522Z` (UTC). The owner confirmed the live Pathways journey, in-page Previous/Next controls, browser Back/Forward and direct URLs. GitHub Actions run #64 passed with 11/11 Chromium browser tests. This is navigation verification for the preview deployment—not commercial release approval—and does not change the palette, typography, spacing, curriculum mapping, academic review or release gates.

## 1. Design direction

### Product feeling

Create a high-end, calm, editorial learning product: academically credible, visually engaging, warm and contemporary. It should feel designed for thoughtful secondary-school learners and trusted by parents—not like a school administration portal, a generic template, or a children's game.

The agreed mix is:

- **Brilliant — primary visual and lesson-design influence:** clear visual hierarchy, polished instructional cards, focused interactive practice and strong explanations.
- **Khan Academy — analytics influence:** transparent learner progress, activity history and skills that can be understood rather than opaque overall scores.
- **Duolingo — learning-progression influence only:** understandable stages, small milestones and a clear next action. Do not copy its mascot-led identity, loud palette, gems, leaderboards or game-heavy reward language.

Reference URLs:
- https://brilliant.org/
- https://support.khanacademy.org/hc/en-us/articles/360032987591-How-can-I-understand-my-progress-in-Khan-Academy
- https://blog.duolingo.com/new-duolingo-home-screen-design/

### Five design principles

1. **One obvious next action.** Every major screen should help the learner see what to do next.
2. **Evidence over decoration.** A progress mark or recommendation must be supported by recorded activity, a defined rule or a published assessment.
3. **Curriculum context stays visible.** Do not blend IB MYP, Cambridge Lower Secondary and Cambridge IGCSE into a single undifferentiated course.
4. **Human assessment feels rigorous and useful.** Make criteria, evidence, comments and next steps easy to follow.
5. **Delight comes from craft.** Use typography, spacing, diagrams, subtle transitions and detailed feedback—not visual noise.

## 2. Visual system

### Colour tokens

| Token | Hex | Use |
|---|---|---|
| Cool white | `#F7F8FC` | Default page canvas and large reading surfaces |
| White | `#FFFFFF` | Cards, forms and focused reading areas |
| Aubergine | `#48264F` | Brand identity, primary actions, key heading emphasis and prominent links |
| Deep aubergine | `#351D3B` | Hover/focus treatment for primary actions and selected dark sections |
| Accessible dusty blue | `#527391` | Secondary brand colour, interactive features, selected controls and visual wayfinding |
| Deep blue | `#36556F` | Positive feedback and student-response labels; pair with explicit wording/icons |
| Soft lilac | `#E9E2F0` | Questions, model-answer panels and selected section emphasis |
| Pale blue-grey | `#DCE6F1` | Student-response surfaces and supporting learning panels |
| Plum charcoal | `#302B35` | Dark hero/closing panels, preview banner and high-contrast inverse-text areas |
| Muted amber | `#80500F` | Constructive next steps and improvement feedback; never a red/error shorthand |
| Buttercream accent | `#F4E9D8` | Tiny decorative accents only; not a page or large section background |
| Primary text | `#28242D` | Main text and high-emphasis controls |
| Supporting text | `#514B57` | Supporting paragraphs, descriptions and labels on light backgrounds |
| Border | `#D8D1E0` | Soft lilac-toned separators and understated card boundaries |

Use an established, role-based EdTech design-system approach: a small set of brand anchors, semantic surface/foreground roles, consistent interaction states and contrast checks. The dominant impression should come from cool white and white reading surfaces, with measured alternation between soft lilac and pale blue-grey learning surfaces. Use aubergine for brand identity and primary actions, accessible dusty blue for secondary emphasis and interactive features, and plum charcoal for selected dark panels rather than making every section dark. Keep buttercream to tiny accents. Use deep blue for strengths/positive feedback and muted amber for constructive next steps. Avoid using either as generic decoration; status must never be communicated by colour alone, so pair every status with a clear label and/or icon. Keep text/background contrast at WCAG 2.2 AA levels and validate actual foreground/background pairs.





**Design-system rationale:** This is an original GradiPrep palette using common, proven EdTech interface principles—not a copy of another company's branding. Khan Academy's published Wonder Blocks work describes semantic colour tokens organised by role and intensity, tested against contrast requirements; Coursera's brand guidance emphasises a consistent blue, black and white palette. GradiPrep applies the transferable principles of role-based colour, restrained accents, readable light surfaces and tested contrast to its own aubergine/blue/lilac identity.

References: [Khan Academy — rebuilding its colour system](https://blog.khanacademy.org/how-we-rebuilt-khan-academys-color-system-from-the-ground-up/); [Coursera — brand guide](https://about.coursera.org/brand-guide/BrandGuidelines/).

### Semantic colour coding across every learning feature

The following meanings are global and must remain consistent on all screens:

| Learning element | Visual treatment | Purpose |
|---|---|---|
| Headings | Preserve the existing dual-colour heading treatment: aubergine plus dusty blue | Brand hierarchy and orientation; do not change heading structure or typography |
| Questions and prompts | Soft-lilac surface with aubergine heading/label | Makes the task being asked visually distinct |
| Student responses | Pale-blue surface with deep-blue label or border | Identifies the learner's own thinking without implying it is correct or incorrect |
| Analysis / reasoning | Aubergine accent, with readable neutral body text | Signals interpretation, reasoning and evidence-linking |
| Model answers / worked examples | Soft-lilac surface with aubergine heading | Distinguishes an exemplar from a student's submitted response |
| Interactive features and tools | Dusty-blue accents and selected-state treatments | Shows where a learner can act or interact |
| Positive feedback / strengths | Deep-blue label or icon plus explicit wording such as “What you did well” | Recognises a specific demonstrated strength; blue is not a substitute for evidence |
| Improvement feedback / next steps | Muted-amber label or icon plus explicit wording such as “What to improve next” | Frames a concrete next action without red/green judgement coding |
| General comments | Supporting text colour on white or cool-white surfaces | Keeps explanatory feedback readable and neutral |
| Section backgrounds | Alternate cool white, white, soft lilac, pale blue-grey and occasional plum-charcoal sections | Creates visible section breaks without changing the meaning of semantic feedback colours |

These meanings apply to existing and future pages, including the dashboard, lesson/practice, question bank and assessment feedback. Never rely on colour alone: keep visible text labels, adequate contrast and accessible focus states. This palette update must not change typography, spacing, page content, feature behaviour or section-break composition; section-break and feature-guidance improvements will be discussed as a separate next step.

### Typography

- **Headings:** Manrope, with the approved display fallback stack.
- **Body and learning content:** DM Sans. This includes questions, instructions, explanations, comments, feedback and other sentences students or parents read.
- **Metadata and technical labels:** DM Mono, used sparingly for short labels, section indexes and dates.
- Use the font-family tokens in `src/styles.css`; do not add a new font family or a page-specific substitute without explicit approval.
- Use sentence case for headings and controls. Reserve uppercase mono labels for short metadata only. Avoid long uppercase paragraphs and excessive letter-spacing.
- Text weights, line heights and letter-spacing remain part of the existing component design. A text-colour adjustment alone must not change them.

### Locked typography and text-colour rules for all future pages

The authoritative implementation is the shared custom properties and reusable helpers in `src/styles.css`. Treat these as a locked design system, not as suggestions to reinterpret for each page.

**Font-family tokens**

| Token | Value and role |
|---|---|
| `--font-body` | DM Sans with Arial/sans-serif fallback; running text and controls |
| `--font-display` | Manrope with DM Sans/Arial/sans-serif fallback; headings |
| `--font-mono` | DM Mono with monospace fallback; concise metadata |
| `--display` / `--mono` | Compatibility aliases to the display and mono tokens already used by existing components |

**Approved size tokens for new pages**

| Token | Value | Use |
|---|---:|---|
| `--type-caption` | 10.5px | Brief, non-essential captions only |
| `--type-label` | 12px | Short labels and interface metadata |
| `--type-body-small` | 13.5px | Supporting explanations |
| `--type-body` | 15px | Default running text |
| `--type-body-large` | 16px | Prominent or comfortable reading text |
| `--type-card-title` | 18px | Card and compact-panel headings |
| `--type-section-title` | clamp(29px, 4vw, 39px) | Section headings |
| `--type-page-title` | clamp(42px, 5vw, 65px) | Main page headings |

Use the existing utility classes `.type-page-title`, `.type-section-title`, `.type-body`, `.type-supporting`, `.type-label` and `.type-caption` where they fit. For new pages, do not introduce text smaller than 10.5px; body text should normally be 13.5–15px or larger. The existing 6px/9px values are legacy prototype-specific results of the earlier size adjustment and must not be copied into new student/parent reading content.

**Approved text-colour roles**

| Token | Value | Rule |
|---|---|---|
| `--text-primary` | `#28242D` | Primary headings, questions and body text on light surfaces |
| `--text-secondary` | `#514B57` | Supporting paragraphs, descriptions, labels and other muted neutral text on light surfaces |
| `--text-inverse` | `#F7F8FC` | Text on dark aubergine or plum-charcoal surfaces |
| `--ink` / `--muted` | Existing aliases | Keep components compatible; `--ink` is `#28242D` and `--muted` is `#514B57` |

An earlier text-colour refinement darkened supporting text for legibility. The palette updates use cool-white reading surfaces, soft-lilac and pale blue-grey panels, and role-based text hues. For future pages, use the semantic text tokens rather than inventing pale text colours or adding one-off grey hex values. Aubergine, dusty blue, lilac, pale blue-grey and muted amber remain limited to their defined roles, not as arbitrary paragraph text.

**One-time changes already applied — do not repeat them**

- Font-size values and font shorthand sizes that were 10px or below before the earlier typography change were multiplied by 1.5, including responsive overrides. Font family, weight/boldness, font style, letter-spacing and line-height were preserved. The current CSS contains the final values; do not run the scaling operation again.
- Grey/sage text declarations used on light backgrounds were darkened in the subsequent text-colour refinement. The current CSS and tokens are the source of truth; do not revert to the earlier lighter values.
- A future page must inherit these tokens and helpers. Do not reset global typography, introduce a separate palette, or change token values unless the owner explicitly approves the change and this document is updated in the same work.

Maintain accessible contrast: target WCAG 2.2 AA contrast of at least 4.5:1 for normal text and 3:1 for large text, and test actual foreground/background combinations. Never use colour alone to communicate state.

### Layout, surfaces and motion

- Use generous whitespace, a consistent spacing scale, readable line lengths and strong alignment.
- Default to thin, neutral borders; use shadows only to create meaningful depth, not on every card.
- Use modest corner radii (approximately 4–12 px depending on component). Avoid excessive pill-shaped UI.
- Use simple line icons consistently. Do not use emoji as the primary icon system.
- Use motion only to clarify state changes; respect `prefers-reduced-motion`.
- Make reading and assessment screens quieter than marketing sections.
- Aim for a distinctive editorial composition with occasional diagrams or visual summaries, not giant empty hero space.

## 3. Shared navigation and components

### Public website navigation

Desktop: brand at left; Pathways and Our approach in the centre/right; one clear primary action at the far right. When authentication is available, label the entry simply **Sign in** (not “Sign in / account”). Mobile: preserve the brand and a compact, accessible menu.

Footer: concise navigation, working-name disclaimer until the brand is approved, and only legal/contact links that actually exist and have been reviewed.

### Signed-in application shell

After account functionality exists, use a consistent app shell:
- Header: brand, current programme/course context, notifications only if implemented, and account menu.
- Main navigation: Dashboard, Pathways, Practice, Saved work, Assessments and Profile, showing only destinations that are implemented and authorized for the current role.
- Main content: one page title, a brief context line, then the principal action/content.
- Keep student, guardian, grader, admin and owner permissions enforced on the server and database. Hiding a link is not an access-control mechanism.

### Reusable components

Build a small consistent library rather than custom one-off visuals on every page:

- Primary, secondary and text buttons, with clear focus/hover/disabled states.
- Programme/course/stage breadcrumb.
- Pathway and lesson cards.
- Text-labelled status chips: Planned, Available, In progress, Completed, Draft, Submitted and Published, used only where accurate.
- Progress bar with accompanying text and an accessible value.
- Skill-status row with a short explanation of the evidence behind the status.
- Question card, answer/explanation reveal and saved-attempt indicator.
- Search, filter controls, clear-filters action and result count.
- Rubric criterion row, evidence excerpt, grader comment and recommended next step.
- Activity timeline, loading skeleton, empty state, retryable error state and confirmation dialog.

A visible control must perform the action its label promises. Do not present disabled/future features as if they are working.

## 4. Screen specification A — Public homepage

### Purpose

Explain who the platform serves, why curriculum-aware practice is different, and how to explore an appropriate English pathway. It should earn trust without overselling course coverage or outcomes.

### Page structure

1. **Slim preview/status banner during development.** Clearly identify the site as an early preview until the owner approves a public launch.
2. **Header.** Working wordmark and concise navigation.
3. **Hero.** A distinctive headline, one-sentence value proposition, primary pathway CTA and secondary “how it works” CTA. Use an abstract learning diagram, annotated-example motif or tasteful typographic composition—not generic stock photos of students.
4. **Programme pathways.** Three clearly separated cards:
   - IB MYP Language and Literature — Years 1–5.
   - Cambridge Lower Secondary English — Stages 7–9.
   - Cambridge IGCSE First Language English — grade 9–10 equivalent pathways.
5. **How it works.** Three understandable steps: find the skill, practise with purpose, review evidence and choose the next step.
6. **What makes learning useful.** Syllabus navigation, examples and explanations, targeted practice, saved work and human assessment as that functionality becomes available.
7. **Stage 1 scope note.** State that the starter pathway is not exhaustive syllabus coverage and that course mapping is verified before publication.
8. **Footer.** Minimal, accurate and reviewed.

### Behaviour and content rules

- The primary CTA should lead to real pathway content when available. Until then, use a clear preview/coming-soon state rather than a dead button.
- Never invent student numbers, pass rates, testimonials, reviews or learning outcomes.
- Do not imply that the site provides official IB/Cambridge grades or guaranteed academic results.
- Do not publish unverified syllabus mapping.
- Pricing and legal terms are not to be invented in the design. Show them only after the owner approves the relevant public wording.
- Use “Criterion Lab” as a provisional label only; the final brand remains an owner decision.

## 5. Screen specification B — Student dashboard

### Purpose

On login, let a student or guardian understand current learning activity, progress evidence, pending work and the next useful action. The dashboard is a live view of recorded activity; a monthly report is only a summary.

### Recommended hierarchy

1. **Context and next action.** Show the learner's selected programme, course and stage. Where sufficient recorded data exists, offer a clear continue-learning or next-practice action.
2. **Progress overview.** Completed and attempted lessons/questions, with definitions or links to the supporting activity. Avoid an unexplained single “overall grade.”
3. **Skill map.** Skills/topics with status and concise evidence for status changes. Use “not assessed yet” when evidence is absent; do not translate missing data into zero mastery.
4. **Recommended next objectives.** Use the approved diagnostic-led, rule-based approach. Explain the reason for a recommendation; do not label it AI-generated if it is rule-based.
5. **Recent activity and saved work.** Attempts, revisions, available feedback and access to the relevant saved record.
6. **Error log.** Repeated errors and linked skills or practice only when those relationships are supported by stored data.
7. **Human assessments.** Published feedback, pending submissions and due times where applicable. Clearly distinguish automatically checked practice from human-assessed work.
8. **Grading credits.** Remaining credits and expiry dates when credit features are implemented.
9. **Monthly report entry point.** Summarise existing dashboard data; the report must not imply a separate human review.

### Analytics rules

- Every number must come from an identified data source and have a stable definition.
- Use dates and comparison periods explicitly. Do not show “improved” unless the underlying comparable attempts support it.
- Do not invent grade predictions, official-equivalent grades or unsupported mastery percentages.
- Do not expose invented learner metrics in learner-facing states or present synthetic data as live activity. If no real learner records exist, retain the dashboard cards and show truthful, contextual empty states. Sample metrics may be used only in an isolated internal test view that is not presented as a learner account.
- Charts need readable labels, a concise takeaway and an accessible textual/table alternative.
- Empty state: explain how to create the first meaningful record (for example, complete a diagnostic or attempt a question).
- Differentiate learning activity, automatically checked practice and published human assessment visually and in wording.

## 6. Screen specification C — Pathway, lesson and practice

### Approved curriculum-first navigation and pathway views

The hierarchy below is mandatory for new work and supersedes any older instruction in this specification that places selected-pathway details below the catalogue.

1. **Pathways catalogue:** This is a comparison/discovery page. Retain the slim taxonomy bands and visible dividers for IB MYP, Cambridge Lower Secondary and Cambridge IGCSE. Cards show the programme/subject route, concise description, relevant levels and accurate availability caveats, with a clear action to open that route. The catalogue must not render a default-selected curriculum, unit plan, pilot preview, release-readiness checklist or other level-specific planning details beneath the cards. Do not leave a hidden or expanded detail panel at the end of the catalogue.
2. **Curriculum and subject page:** After a pathway is selected, identify the programme and subject/course, explain the route and show only the levels or verified syllabus choices supported for that route.
3. **Year, stage or verified syllabus page:** Selecting a level opens its own contextual destination. Put the level-specific unit plan here, along with the applicable learning objectives, unit sequence, assessment approach, available learning materials and clear content/review/mapping/release statuses.
4. **Unit detail/learning view:** Selecting a unit opens its own detail/learning destination with the unit purpose, skills, constituent lessons, practice, explanations and relevant assessment activities.

Use a clear breadcrumb pattern such as “Pathways / IB MYP / Language and Literature / Year 1 / Unit 1”, adapting each crumb to the actual data model. Keep programme, subject/course, year/stage, qualification, syllabus edition, objective, unit, task and rubric identifiers separate. Direct links must display the curriculum context and offer a way back to the parent page.

Reusable templates are encouraged; generic or interchangeable curriculum content is not. A page may share its layout with another curriculum, but its plan, objectives, unit sequence, assessment requirements and mapping must be specific to the selected programme, subject, level and applicable syllabus edition. Grade-equivalent labels are navigation aids only and do not establish a separate qualification or syllabus. In particular, do not treat Cambridge IGCSE grade-equivalent entries as separate curricula without official verification and an approved roadmap.

Keep statuses distinct: academic content review, official curriculum mapping, rights review, accessibility review and release approval are separate gates. Never let a review-passed label imply verified official mapping or released syllabus coverage. The starter pathway is not exhaustive syllabus coverage.

### Pathway content model and display rules

- Show the curriculum hierarchy rather than flattening all courses into “Grade 6–10.”
- Group content into understandable units and skill objectives on the relevant level/unit destination, not on the general catalogue.
- Distinguish content available now from content that is planned.
- Keep the approved taxonomy-band styling and the Pathways-specific spacing refinements on the catalogue; do not move level-specific panels into the catalogue merely to reuse their existing styling.
- The curriculum-first architecture is implemented in the current prototype through four contextual views: catalogue, curriculum/subject, level and unit detail. The views use pathname-based URLs, not temporary view-selection state. Direct links resolve from current catalogue data; browser back/forward restores the URL-selected destination. Breadcrumbs and contextual Previous/Next controls preserve programme/subject, level and unit identity. Each supported curriculum, level, unit and lesson view offers an in-page back action and a forward action when the next destination is supported; where no safe next destination exists, the interface explains why. The Pathways catalogue remains unselected and has no Previous/Next bar. Routes are created only for supported programme levels; a provisional grade-equivalent label or unverified syllabus does not become a standalone route. Unknown URLs show an unavailable-destination message. The catalogue must remain free of selected-pathway plans, pilot previews and readiness checklists. Changes to this hierarchy require explicit review and coordinated updates to both source-of-truth documents. The PR #10 navigation changes are merged, deployed to the Cloudflare Workers preview and live-verified by the owner; see version 1.5 above. This does not imply commercial launch readiness or change any content/release gate.

### Lesson view

Recommended layout:
- Breadcrumb and visible curriculum/skill context.
- A clear learning objective and, where useful, “what success looks like.”
- Short explanation, annotated example(s), common mistakes and relevant assessment/marking guidance.
- A focused practice activity attached to the skill.
- A next-step action at the end, based on the content actually available.
- A save/attempt state that is understandable and does not silently discard student work.

Keep the reading column comfortable on desktop and remove side-by-side distractions on narrow screens. Use annotation, highlighting and small diagrams only where they clarify the English skill.

### Practice interaction

- Each question must have its task context, instructions and response format, including a question-specific expected word count/range and ideal target for every typed response.
- Each typed-response field must display a real-time current/ideal counter (for example 38/50, then 59/50 when the learner goes over). Update on typing, paste, edit, deletion and clear-all.
- The denominator is an ideal target, not a maximum. Never truncate/reject text, disable the field, block submission or set maxLength based on the target. Preserve the entire learner response above the target.
- Apply the counter retrospectively to every existing typed-response field and to every new field from first integration. This is a client-side writing aid, not a grade, score, save or submission feature.
- Count lexical words consistently: letters/digits form words, punctuation-only tokens do not count, and contractions/hyphenated compounds count as one. Expose the changing count accessibly without disrupting typing.
- For objective/closed questions, provide immediate question-specific feedback after the learner checks/submits: the correct answer, the reasoning that makes it correct, and why each alternative does not fit. Ordering tasks must explain the chronological, causal, referential or logical sequence.
- For typed responses configured for AI-assisted practice feedback, provide immediate feedback grounded in the learner's actual answer, the exact excerpt and the item's approved criteria. Identify a supported strength, a specific missing/weak link and one useful next step.
- Reveal model responses and full marking guidance only in the intended post-attempt state. Never reveal answer keys or hidden criteria before the learner's attempt.
- Make attempt status clear: not started, in progress, saved, submitted or checked, as applicable.
- Indicate whether a response is automatically checked, AI-assisted practice feedback or requires human assessment. These are distinct from official IB/Cambridge grades.
- Preserve attempts and revisions according to the eventual data model. Do not represent an automatically checked or AI-assisted answer as a human grade.
- Do not add arbitrary points, streaks or competitive leaderboards without an explicit product decision.

**Implementation status:** The current static prototypes do not perform genuine automated marking, question-specific AI evaluation, server submission or persistence. Self-review checklists are not a substitute. Treat the above as target requirements until separately implemented, secured and verified.

## 7. Screen specification D — Question bank

### Purpose

Allow a learner to find practice that matches their curriculum and skill objective, attempt it, understand the explanation and return to past work.

### Search and filters

Search should accept ordinary words from a skill/topic or task title. Filters should be based on the curriculum data model:
- Programme.
- Course/pathway.
- Year/stage.
- Subject.
- Syllabus edition, where verified and available.
- Skill objective.
- Task type where the content supports it.

Show only meaningful filter options for the selected pathway. Do not present syllabus editions or task types that have not been checked and populated. Provide a clear-filters control, a visible result count and an understandable no-results message.

### Result cards

Each result should show the task title, programme/course context, stage, skill objective, task type and relevant availability state. A result should make it clear whether it is a short-form practice item or an extended-response task where that distinction is present in the content data.

Avoid exposing answer keys before the intended reveal state. Provide a direct action to start/reopen a question, and an accurate indicator if the learner has a saved attempt or previous explanation.

### Empty, loading and error states

- **No filters/results:** suggest widening or clearing filters, not changing curriculum to an unrelated one.
- **No released content:** explain that content for this pathway is still being prepared.
- **Loading:** retain the filter context and use a calm skeleton.
- **Failure:** show a retry path without pretending the result set is empty.

## 8. Screen specification E — Human-assessment feedback

### Purpose

Make founder-led grading transparent, evidence-based and genuinely useful. This screen is one of the product's trust-defining experiences.

### Before submission

Show the mapped task and curriculum, what one credit includes, the rubric/criteria family, expected response format, whether additional credits are required and the turnaround time before the student commits. State scope and credit requirements before submission, not afterwards.

The master brief specifies:
- Free human-graded task: within 72 elapsed hours after an accepted submission.
- Paid standard task: within 48 elapsed hours after an accepted submission.
- Urgent grading: within 24 elapsed hours only when an eligible Master Grader and an urgent slot exist; keep this disabled until eligibility and capacity support it.

The interface must respect actual capacity. If the promised SLA cannot be met, preserve the draft and credit without accepting the job.

### Published feedback screen

Recommended hierarchy:
1. **Assessment summary:** task title, curriculum mapping, submitted/finalised/published timestamps where relevant, status and whether the assessment was human-graded.
2. **Overall outcome:** show the awarded result only where the rubric defines a valid score. Do not imply an official IB/Cambridge grade.
3. **Criterion-by-criterion feedback:** show the criterion/rubric descriptor, mark if applicable, clear comment and evidence from the learner's response.
4. **What worked well / what to improve:** concise, specific and constructive, tied to response evidence.
5. **Next practice steps:** link comments to skills/questions where the mapping exists.
6. **History:** show relevant revisions and published versions to the authorized user without erasing prior records.
7. **Regrade/next submission guidance:** explain the applicable credit rule and turnaround before the user acts.

Do not show draft feedback as published. Student/guardian views must not expose internal grader QA records, confidential admin notes or private model outputs. Enforce separation with server-side authorization and database policies, not merely hidden UI elements.

At initial launch, label the founder “Founding Academic Lead.” Do not manufacture a public grader rating before sufficient assessment data exists. If feedback ratings are eventually shown, follow the master brief's verified-feedback and internal-quality methodology.

## 9. Responsive behaviour and accessibility

- Start with a polished desktop layout but ensure the same core flow works on mobile.
- On small screens, stack cards, use full-width main actions and collapse nonessential navigation without hiding important status information.
- Tables such as rubrics should transform into clearly labelled stacked rows on narrow screens rather than requiring horizontal scrolling wherever possible.
- Use semantic headings, labelled form fields, keyboard-operable controls, visible focus states and useful error text.
- Meet WCAG 2.2 AA contrast targets wherever practical; test text, controls, focus indicators and charts.
- Never encode meaning in colour alone. Provide labels/icons and chart text alternatives.
- Support zoom and reduced motion. Touch targets should be comfortably tappable.
- Use plain, respectful language. Avoid shaming terms for weak areas or incorrect answers.

## 10. Trust, privacy and security requirements visible in the interface

- Never put API keys, passwords, `.env` files, real student submissions or private customer information in Git.
- Use fictitious data for interface development and screenshots.
- Show only the records allowed for the current authenticated role. The backend and database must independently enforce authorization.
- Do not expose private AI-assisted QA to graders or learners unless a later approved policy explicitly defines a safe public output.
- Make save/submission status visible. Errors must not quietly lose work.
- Privacy, consent, refund, expiry and service terms remain owner decisions until reviewed; do not invent final legal language.
- Do not claim zero retention, absolute security or guaranteed results.


### Answer-key and feedback security

- Learner-facing bundles may contain only the selected task stimulus (a verified public-domain excerpt when it exceeds 250 words, or an approved platform-original passage of 250 words or fewer), question, instructions and fields needed to attempt the task. Do not include teacher-only answers or rationales.
- Correct-answer IDs, full answer keys, per-option rationale, model responses, private rubrics and teacher notes stay server-side behind access controls when live marking is introduced.
- The server returns only the feedback authorised for the current attempt/reveal state; never send the full teacher pack to the browser.
- Do not describe the current preview/self-check interactions as automated grading. A secure Worker endpoint, validation, rate limiting and privacy design are required before live AI-assisted evaluation.

## 11. Implementation sequence

This specification defines the target experience. Build in small, reviewable stages:

1. **Design-system pass:** apply shared colours, typography, spacing, responsive rules, buttons, cards and status styles.
2. **Public homepage pass:** refine the current preview against Sections 2 and 4, keeping the working-name and starter-pathway caveats accurate.
3. **Static screen prototypes:** create the dashboard, lesson/practice, question-bank and assessment-feedback screens using clearly labelled, fictitious demonstration data. These are visual prototypes only—not real accounts, persistence or grading.
4. **Review:** check desktop/mobile layouts, accessible interaction states, empty/error/loading states and wording against this spec.
5. **Functional foundations:** only after the screens are agreed, connect curriculum content and then implement authentication, saved attempts, assessment workflows and database-backed analytics according to the master brief's security and access-control requirements.
6. **Deployment choice:** verify vendor plans and terms before commercial launch or before handling real student data.

Do not silently expand the approved curriculum, change pricing or credit rules, relax SLAs, introduce new roles, or imply that a prototype feature is live.

## 12. Definition of design-ready

The design can be considered ready for functional implementation when:
- The five key public/learner screens follow the shared design system.
- Every screen has defined loading, empty, error and populated states.
- Curriculum identity is visible and programme pathways stay distinct.
- Analytics labels and definitions map to actual planned records.
- Automatically checked practice and human assessment are unmistakably distinct.
- All visible controls have a defined action.
- Mobile, keyboard and accessibility checks are documented.
- No invented learner data is shown in learner-facing states. When real records are not available, the screen uses a purposeful, contextual empty state; synthetic sample values remain confined to an isolated internal test view.
- No unapproved business, syllabus, privacy or pricing decision has been introduced.


**Version 0.9 change note — 25 October 2026:** Tightened vertical spacing on the Pathways page by approximately half for transitions between curriculum groups and the selected-pathway planning panels. Taxonomy bands now sit close to their group headings and cards, rather than being visually centred between adjacent content blocks. Keep this spacing adjustment scoped to catalogue groups; preserve the shared site-wide spacing system and existing typography/palette. The former below-catalogue planning-panel placement is superseded by version 1.0.


## 13. Controlled preview — Cambridge Stage 7 Unit 1 v1.3

This route is reserved for interface testing: `/preview/cambridge-lower-secondary/english/stage-7/unit-1`. Keep it out of ordinary navigation. Present a persistent, visible status panel stating that the page is a controlled preview and the unit is **not released or student-ready**. Do not label it as fully curriculum-mapped or Cambridge-approved.

Use the approved global design tokens rather than creating a second visual system. The preview should include:
- one page-level heading, ordered section headings and a keyboard-reachable skip link that transfers focus to the main content;
- native radio inputs with associated visible labels and keyboard interaction;
- native `details/summary` elements for optional worked-model and vocabulary help;
- learner passage rendered as selectable text, with no decorative photo or image dependency;
- one visible label per text area, a unique task-specific accessible name, and a programmatic association to each task prompt, including the exit-check prompt;
- strong visible focus, high-contrast status treatment, responsive layout at narrow widths, and a clear-all action that resets every temporary learner input;
- plain notice that responses remain in the open page only, are not graded, sent to the server or saved to an account.

Do not import the teacher/editor review pack, answer key, correct-answer IDs or grading notes into the client module graph. Do not add the route to the catalogue, breadcrumbs, or ordinary next/previous navigation. Keep this controlled preview branch-based and unmerged. CI checks using the local Wrangler server provide automated smoke evidence only; do not represent them as a live hosted-preview review or a complete accessibility audit. Manual keyboard/focus, screen-reader, zoom/reflow and cross-browser checks remain necessary before any accessibility gate can be called complete.


## 14. Final automated interaction and reflow evidence — 26 October 2026

On final controlled preview test commit `841c26ab5f3c0bd24d32cc88d839af015353eff9`, [Build check #231](https://github.com/gradioprep/gradioprep-website/actions/runs/40308612925) passed the TypeScript/Vite build and all 17 Chromium tests. The preview-specific tests check (1) direct rendering with an explicit unreleased status; (2) skip-link keyboard operation and focus transfer to the main content; (3) task-specific names for all 14 response fields and programmatic associations for all guided, independent and exit-check prompts; (4) horizontal reflow/overflow at 320, 390, 768 and 1024 CSS-pixel viewports; (5) clearing all temporary response input including the warm-up radio selection; and (6) representative WCAG AA text-contrast samples. These automated checks do not replace manual assistive-technology review, broad WCAG evaluation, human suitability review or formal release approval. The CI browser uses local Wrangler assets; no dedicated hosted Cloudflare preview URL is verified.


## 15. Hosted preview and workflow permission verification — 27 October 2026

The original controlled-preview workflow built the application and created the preview, but failed when the GitHub token attempted to read/update the pull-request conversation. The workflow now keeps the default token at `contents: read`, grants `pull-requests: write` only to the preview job, and keeps cleanup read-only. [Controlled preview run #14](https://github.com/gradioprep/gradioprep-website/actions/runs/40524206707) passed, including the “Update the pull request with the preview URL” step. [Build check #245](https://github.com/gradioprep/gradioprep-website/actions/runs/40524206694) passed the TypeScript/Vite build and 17/17 Chromium tests on commit `127a7b82ccda52536b4bfd78e603499cd47281d6`.

Cloudflare's Preview API confirmed the isolated `pr-15` URL [https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev/preview/cambridge-lower-secondary/english/stage-7/unit-1](https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev/preview/cambridge-lower-secondary/english/stage-7/unit-1); its `deployed_on` field returned `2026-10-27T14:46:23Z` UTC at the verification check. The six preview-specific automated tests cover unreleased status, skip-link focus transfer, accessible names and prompt associations for all 14 response fields, no horizontal overflow at 320/390/768/1024 CSS-pixel widths, clear-all behavior including the warm-up choice, and sampled text contrast. All browser tests use local Wrangler assets. The execution environment could not independently fetch the hosted page for a manual visual smoke review; founder visual review remains open. Manual screen-reader, keyboard/focus, 200%/400% zoom/reflow, text-to-speech and cross-browser checks remain necessary. The preview stays unlinked from normal navigation, public unless Cloudflare Access is configured, and unreleased. No merge, production deployment, or DNS update occurred.


**Version 1.9 change note — 30 October 2026:** Added mandatory question-specific length, objective answer reasoning, distractor/sequence explanation, immediate item-specific formative feedback and server-side answer-key boundaries. See `docs/TEACHER_PACK_AND_FEEDBACK_STANDARD.md`. This documents the approved target behaviour; it does not claim the current preview screens implement automatic marking or AI feedback.


**Version 2.1 change note — 30 October 2026:** Implemented the typed-response counter interaction on the MYP Year 1 Unit 1 v3 lesson. All six textareas use the shared `ResponseWordCountTextarea` component and one lexical counter helper; each shows the approved current/ideal count, including values above the target. Ideal targets are 20, 50, 75, 55, 55 and 50 words in entry/Q2/Q3/Q4/Q5/exit order. Existing expected ranges, prompts and content remain unchanged. The counter is visually secondary, uses existing design-system typography and colour tokens, is programmatically associated with its textarea and updates through a polite assistive-technology status. There is no cap, `maxLength`, grading, persistence or submission behavior. Automated checks are in `tests/word-counter.spec.ts`; CI verification for the latest commit is pending.

**Version 2.2 change note — 31 October 2026:** The shared MYP response textarea now associates the learner's response field with its task/entry/exit prompt, the expected response-range guidance and the live current/ideal count through `aria-describedby`. The browser test checks all three ID references, the visible prompt/range and the accessible name. This supplements (and does not replace) the polite live counter status. CI run #295 passed 16/16 Chromium tests. Manual screen-reader, keyboard/focus, zoom/reflow, contrast and cross-browser checks remain required before release.


**Version 2.3 change note — 31 October 2026:** Added a feature-specific design specification for the pre-curriculum diagnostic, evaluation report and remedial analytics. The report canvas is predominantly white/cool white, with restrained approved Palette B accents and accessible chart-first presentation. This does not change the global palette, typography, navigation or application architecture and does not claim any diagnostic feature is implemented.

## 16. Diagnostic, evaluation and remedial analytics experience

### 16.1 Visual direction

Use a predominantly **white/cool-white background** for the diagnostic flow, evaluation report and analytics. The experience should feel like a premium, high-end EdTech assessment product: calm, spacious, precise and easy to interpret. Do not use a black or dark dashboard theme.

- Keep large report surfaces white/cool white; use existing cards, borders and semantic surface tokens.
- Use aubergine for primary headings/actions and dusty blue for secondary navigation, chart series or comparisons.
- Use soft lilac and pale blue-grey sparingly for grouped learning panels or chart annotations.
- Reserve muted amber for constructive next steps and areas requiring attention; it must not imply failure or punishment.
- Use deep blue for strengths/positive findings only with explicit labels; never encode meaning with colour alone.
- Do not alter fonts, typography sizes, spacing scale, global palette tokens or existing page/navigation architecture.

### 16.2 Analytics layout and visual hierarchy

The evaluation report should prioritise, in order:

1. A concise learning-readiness overview with an explanation of what the result means.
2. A clear skill-profile visual with direct labels and readable scales.
3. A small number of skill-level bar/radar or other meaningful charts, accompanied by short explanations.
4. Evidence-backed strengths and improvement priorities, each linked to the remedial course.
5. The personalised remedial plan, normally five 60-minute sessions; show six or seven only where evaluation analytics justify the additional time.

Minimise tables and dense data blocks. Avoid repeating the same score in several visual forms. Use a table only where comparison truly requires rows/columns. Provide concise explanatory text beside a chart rather than expecting students to infer meaning from colours or labels alone.

### 16.3 Chart selection and accuracy

- Use horizontal bars for comparable skill or sub-skill results; label the scale, skill and available evidence.
- Use a radar/spider chart only where a small set of comparable dimensions can be read without overlap or distortion.
- Use a circle/donut/proportion chart only when the displayed categories form a meaningful whole and denominators are clear.
- Use line graphs only for at least two valid measurements over time (for example diagnostic baseline and a genuinely comparable post-course check); never invent a trend from one test.
- Use explicit chart titles, labels, units/scale and explanatory annotations. Include a text equivalent for assistive technology and ensure contrast in actual data marks and labels.
- Avoid false precision, unvalidated norm comparisons, arbitrary percentages and misleading axis scales. Where evidence is limited, show that limitation visibly.

The chart calculation and displayed figure must be traceable to the underlying diagnostic responses and approved scoring rules. Never display internal provider percentiles, ordinal ranks, provider test-taker counts or their ranking methodology in learner/parent reports, downloads, dashboard views or report payloads, including logged-in views. Do not include such fields in the learner-report data model or client bundle. These are internal research records only. An attractive visual is not a substitute for measurement validity.

### 16.4 Responsive and accessible presentation

Charts must remain understandable on narrow screens, at 200%/400% zoom and with keyboard/screen-reader use. Do not use colour as the only indicator of strength, status or priority. Supply readable text summaries/labels; make tooltips optional rather than the sole source of information. Keep the same semantic heading hierarchy and focus order as the existing site.


**Version 2.4 Founder decision update — 31 October 2026:** The MYP Grade 9 provider research is approved; the draft taxonomy/blueprint is awaiting Founder review. Provider ranking data and its 50/50 basis are internal-only and must not appear in learner/parent reports or logged-in views. The remedial plan should use five 60-minute sessions where sufficient, extending to six or seven only when evaluation analytics justify it.


**Version 2.5 diagnostic design-status update — 1 November 2026 (historical checkpoint; superseded by v2.6):** The Founder approved the Grade 9 IB MYP Year 4 skill taxonomy and high-level 90-minute/two-sitting blueprint. At that checkpoint the task-level item map was still under review. The current item-map approval and the flagship PDF-response/grading/timed-analytics design requirements are recorded in v2.6 below. No UI or data model has been implemented by the design approval. All provider ranking/percentile data and methodology remain excluded from learner-facing screens, report payloads and client bundles. Palette, typography, navigation and page architecture remain unchanged.


### 16.5 PDF response and teacher/grader workspace — approved plan, not implemented

For a written response with an approved expected response greater than 20 words, the student task panel offers two clearly labelled choices: **Type response** (default) or **Upload PDF**. PDF is optional. The typed response retains its approved response range and live word counter; the file chooser accepts PDF only. Do not display JPG/PNG upload controls. Enforce the approved initial pilot cap of 10 MB and 10 pages per PDF, with clear validation and page-count feedback. The upload screen shows file validation, page count, processing state, and a clear retry/fallback message without discarding a typed draft.

The teacher/grader queue is chronological, oldest submission first. Each entry displays priority and deadline separately, along with elapsed time and time remaining. The question/prompt and the curriculum, programme/course, grade/year/stage, subject and task identifiers appear above the grading workspace. The task-specific rubric is an expandable panel.

For PDF submissions, use a split screen: original PDF viewer on the left and page-aligned extracted text on the right, with page navigation and visible extraction confidence/failure markers. The original PDF remains authoritative. On small screens, use accessible tabs or stacked panels while maintaining page alignment. Typed submissions use the same workspace, with the typed answer shown instead of the PDF viewer.

The feedback authoring panel shows exactly ten AI-drafted suggestions, clearly identified as drafts, plus a custom-feedback text area. Teachers can select/edit suggestions and add their own comments. The only student-visible content is the human-submitted published feedback. On successful teacher edit, refresh the learner-visible feedback immediately; preserve old versions privately in the audit history. Use the approved design system and keep answer keys, private grader notes, AI drafts and internal QA data out of the learner bundle.

### 16.6 Task countdown and grading SLA display — approved timer policy and 24-hour grading SLA

For a timed task, show a task-specific countdown and elapsed duration. Use explicit accessible warning states and do not rely on colour alone. The exact timer allowance comes from task configuration; the interface must not derive an arbitrary time limit from word count.

The teacher queue displays the approved 24-hour grading target with elapsed and remaining time. Priority labels are based on time remaining: Priority 1 (more than 0 and up to 10 hours), Priority 2 (more than 10 and up to 20 hours), Priority 3 (more than 20 hours), and a separate overdue state. Queue order remains oldest accepted submission first. After feedback is published, show actual turnaround and the time remaining before the deadline (or how late it was) immediately before the feedback on both teacher and student views. Editing later feedback does not reset first-publication turnaround.

The approved timer is advisory and server-authoritative; it continues through refresh, disconnection and hidden/background tabs. The first release has no learner pause/resume. At zero, preserve the response and do not auto-submit, truncate, delete, lock or block saving/submission. Authorised teacher/admin extensions or untimed accommodations are permitted only with an audit event; do not store diagnoses. Record minimal start/save/submit/expiry/adjustment events only—no keystroke, focus or browsing surveillance. Label the measure elapsed response time, compare only suitably similar tasks/skills/allowances, interpret alongside accuracy and human rubric results, and never infer ability/mastery from speed alone. Upload/OCR processing time is excluded. The full timer, privacy and retention policy is in `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`.



## 13. Secure application foundation — design dependency, 2 November 2026

The interface must treat authorization as a server/database responsibility, not a visual state. Hiding navigation, answer keys, grader controls or learner records in React is never a security boundary. Authenticated screens must render only data returned by the protected API for the current actor. Student views are limited to the learner's own records and published feedback; guardian views require a verified authorised link; grader views are assignment-scoped; admin/owner controls are separately protected and audited. Private PDF access uses short-lived, permission-checked links. Loading, expired-session, forbidden, revoked-access and unavailable-service states must be clear and accessible without exposing record existence or private content. The initial sign-in/account screen, local Supabase Auth flow and protected `/api/v1/me` Worker API are implemented in Phase 1B PR #22 and verified against local synthetic data. On the public Preview, the account screen intentionally states that authentication is not connected and tells visitors not to enter account details. This does not constitute a hosted/live account system or completion of all role-specific protected screens. The next local security increment adds a clear suspended-account state that hides profile/role details and offers sign-out; the Worker and database deny protected access even while the Supabase Auth session remains valid. Automated verification of this increment is pending. See the Phase 1 implementation specification for the binding role matrix and API/RLS controls.


## 14. Authentication and protected API design dependency — 2 November 2026

The Phase 1A build-ready plan (`docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`) specifies the minimum initial authenticated journey: React sign-in/sign-out and session states; same-origin Worker API; protected current-user profile/role response; explicit anonymous, expired, forbidden and revoked-session states. The static assets and current route-driven navigation must remain unchanged outside authenticated routes. Role-driven controls are display affordances only; server authorization and PostgreSQL RLS decide access. Do not expose roles as a client-selectable signup field, show a guardian view without a verified link, or show grader tools without an active assignment. The initial sign-in/current-account journey is implemented as a local-only Phase 1B slice in PR #22; its synthetic signup, profile read/update and sign-out flow passed Chromium tests. The public Preview remains disconnected from Supabase. Guardian, grader, admin and owner workflows remain design requirements until their separately scoped implementation and tests are complete.


## 15. Public Preview as a design verification requirement — 2 November 2026

The Founder has made public verification a mandatory build-process feature. Every meaningful UI or interaction change should be shown on the current PR's public Cloudflare Worker Preview as soon as CI passes. The Founder reviews the actual running UI before the milestone is accepted; automated screenshots/tests alone do not replace this. Keep the Preview alias current after fixes and preserve the exact immutable deployment URL that was inspected. The PR handoff must state the user-visible change, exact route(s), short click-by-click checks, CI results, current backend limitations and next approval gate. See `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`. For PR #22, Cloudflare published the latest code-bearing branch revision `50f4bb3` with successful Build and Deployment status; manual Founder review remains pending. The Phase 1B Actions workflow's own Preview step was skipped on the push event, so the current link is the Cloudflare branch Preview, not a Preview uploaded by that job.

During Phase 1B the backend remains local Supabase with synthetic data; public previews must never imply a hosted login/database is active. Show clear, accessible unauthenticated, expired-session, forbidden and backend-unavailable states without disclosing private record existence. Public `workers.dev` previews are not production and no-index is not access control. The custom domain is connected later at Launch Candidate / Production Cutover, not for every PR. Do not change the approved palette, typography or curriculum visual hierarchy to implement this workflow.


## 17. Whole-site learner-facing copy and temporary-content cleanup

**Mandatory timing:** For Cycle 1, complete this sweep immediately after the Grade 9 / IB MYP Year 4 diagnostic and its evaluation report/analytics have been completed and checked, and before authoring any remedial lesson, practice activity or remedial teacher/editor material. It applies to the entire website, not only the diagnostic or dashboard pages.

**Coverage:** Inspect every route, component and visible state, including the public homepage, header/navigation/footer, pathways, curriculum/course and level views, unit and lesson pages, practice/question-bank screens, dashboard, diagnostic, evaluation report and analytics, sign-in states, feedback/profile areas, preview/status surfaces, and populated, empty, loading, error, disabled/locked and responsive variants. Search source content as well as browser-visible text; shared components and repeated copy count across every page where they appear.

**Remove internal notes from the interface:** Development explanations, planning instructions, editor notes, QA warnings, TODOs and messages intended for the project team must live in source comments or internal documentation, never as learner-facing copy. This includes instructions such as “Do not infer syllabus coverage from the placeholder.” State curriculum limitations in clear learner language only where a learner genuinely needs to know them.

**Preserve the design:** Do not remove a band, card, heading, panel, taxonomy strip, visual group, navigation element, spacing tier or designed empty-state container just because its current text is temporary. Replace the copy inside the existing structure or show an appropriate, purposeful empty state in the same component. Preserve Palette B, locked typography, hierarchy and spacing. Replacements must be specific to the page, curriculum context and actual state, not generic filler.

**Known examples and intended direction:**

| Current visible text / issue | Required user-facing treatment |
|---|---|
| “Demonstration dashboard. All learner activity and numbers below are fictional examples to show the intended experience.” | Do not show this internal disclaimer to learners. Keep the dashboard overview band and metric cards; use actual data when available. Until then, show a useful empty-state message such as “Complete your first diagnostic or practice activity to start building your learning record.” Do not leave fictional counts looking like real learner progress. |
| “This planning slot has no confirmed unit focus yet. Do not infer syllabus coverage from the placeholder.” | Replace the note with the heading “Your next learning focus” and the contextual explanation “Once your course plan is set, this space will show the selected unit, the skills you will practise and your next activities.” Keep the planning band/card and its visual placement. Keep the syllabus-verification warning internal. |
| “Unit focus to be confirmed.” | Replace with “Your next unit is being prepared” and the explanation “Your course plan will show the unit’s key skills and the activities that help you practise them.” Do not imply a unit or official syllabus mapping has already been confirmed. |
| “Sign in / account” | Use “Sign in” only. |

**Code traceability:** Use the conventional searchable TODO: comment marker for development follow-up. Centralise temporary UI copy in a single content module (for example, src/content/temporaryCopy.ts) and export named TEMP_COPY_ constants; reference these constants from components rather than duplicating literal temporary strings. Never render a TODO or TEMP_COPY marker to users. Do not introduce an ad-hoc visible marker such as #TT. During the sweep, search for TEMP_COPY_ and TODO:, check every occurrence and value, replace or remove each one, and delete the temporary registry/references when no temporary UI copy remains.

**Acceptance checks:** Maintain an inventory of all website routes and states; test every item in that inventory at desktop and mobile widths. Add automated browser/content checks for the known phrases and other internal-note patterns, and verify that no temporary marker or team-facing instruction appears in rendered pages. Confirm that empty states explain the relevant next action, every displayed metric is backed by real or explicitly isolated test data, no syllabus coverage is inferred from an unconfirmed placeholder, and all existing visual bands/cards remain intact. Record the routes reviewed, tests, corrected copy and any genuine remaining limitations. The Founder then verifies the refreshed public Preview before the Cycle 1 remedial content work proceeds.

