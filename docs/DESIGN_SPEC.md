# Criterion Lab — Design Specification

**Version:** 0.1  
**Status:** Design direction agreed; page specifications prepared for implementation  
**Last updated:** 23 October 2026  
**Product name:** “Criterion Lab” is a working name only. Final brand and domain are not approved.  
**Source of truth:** [`PROJECT_MASTER_BRIEF.md`](PROJECT_MASTER_BRIEF.md)

> This document translates the agreed visual direction into a buildable interface specification. The master brief takes precedence if any design suggestion here conflicts with an approved product rule. This is a design and interaction plan, not a claim that the described product features are already implemented.

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
| Paper | `#F5F4EE` | Main warm page background |
| Surface | `#FCFCF8` | Primary cards and reading surfaces |
| Ink | `#202923` | Main text and high-emphasis controls |
| Muted | `#68736B` | Supporting text; not for tiny low-contrast text |
| Forest | `#244D3A` | Primary actions, active navigation and key accents |
| Forest dark | `#193A2C` | Dark feature panels and footer accents |
| Soft lime | `#D9EDAB` | Rare positive accent, not a default background for every card |
| Soft coral | `#E98D70` | Small highlights, focus details and occasional illustration accents |
| Border | `#DFE3D9` | Separators and understated card boundaries |

Use the palette with restraint. Most screens should be paper/surface with ink text and one forest-green action. Reserve coral and lime for small moments. Status must never be communicated by colour alone; pair it with text or an icon.

### Typography

- **Headings:** Manrope or a similar clear, modern display sans-serif; compact but not cramped.
- **Body and learning content:** DM Sans or a highly readable equivalent. Prioritise long-form reading comfort.
- **Metadata and technical labels:** DM Mono sparingly for small uppercase labels, section indexes and dates.
- Provide sensible system-font fallbacks. A third-party font failing to load must not break layout.

Use sentence case for headings and controls. Reserve uppercase mono labels for short metadata only. Avoid making long paragraphs uppercase or excessively letter-spaced.

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

Desktop: brand at left; Pathways and Our approach in the centre/right; one clear primary action at the far right. Mobile: preserve the brand and a compact, accessible menu.

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
- Do not use fake sample numbers in a real student account. During development, sample data must be unmistakably labelled as demonstration data and kept separate from production.
- Charts need readable labels, a concise takeaway and an accessible textual/table alternative.
- Empty state: explain how to create the first meaningful record (for example, complete a diagnostic or attempt a question).
- Differentiate learning activity, automatically checked practice and published human assessment visually and in wording.

## 6. Screen specification C — Pathway, lesson and practice

### Pathway view

Show the curriculum hierarchy rather than flattening all courses into “Grade 6–10.” Keep programme, course, year/stage, subject, syllabus edition, skill objective and task/rubric identifiers separate in the underlying model.

Within each pathway, group content into understandable units and skill objectives. Distinguish content that is available now from items that are planned. Label the first release as a starter pathway, not complete syllabus coverage.

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

- Each question must have its task context, instructions and response format.
- Reveal answer explanations and marking guidance only in the intended interaction state.
- Make attempt status clear: not started, in progress, saved, submitted or checked, as applicable.
- Indicate whether a response is automatically checked or requires human assessment.
- Preserve attempts and revisions according to the eventual data model. Do not represent an automatically checked answer as a human grade.
- Do not add arbitrary points, streaks or competitive leaderboards without an explicit product decision.

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
- Demonstration data is clearly labelled and cannot be mistaken for live student data.
- No unapproved business, syllabus, privacy or pricing decision has been introduced.
