# IB/IGCSE Learning Platform

The curriculum-aware IB and Cambridge learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Criterion Lab is a placeholder working name.** The final brand and domain have not been decided.

## Current status

The React + TypeScript prototype has six clickable screens, including Pathways and an interactive Lesson & practice preview. The earlier preview was deployed to Cloudflare Workers; deployment of the latest changes has not been independently confirmed.

The first IB MYP Year 1 pilot lesson, **How writers shape meaning**, passed academic content review for pilot-preview version 1, as confirmed by the project owner on 24 October 2026. It includes an original reading passage, four teaching stages, four practice tasks, written-response fields and self-review checklists. Responses are temporary to the open preview, are not graded and are not saved.

The client imports [`src/content/pilotLearnerLesson.ts`](src/content/pilotLearnerLesson.ts), which contains no correct-answer IDs or model answers. The teacher/editor answer source, [`src/content/pilotLessonPack.ts`](src/content/pilotLessonPack.ts), is not imported into the client application. This is not yet a production authorization system.

**Important:** the content is approved for a pilot preview only. Official IB guide edition/objective mapping is still unverified; `officialObjectiveCodes` remains empty. Separate rights review, accessibility review and explicit release approval are outstanding, so the unit is not a released syllabus-mapped course. The existing demo question-bank content remains separate with unassigned curriculum metadata.

Not yet implemented: authentication, database, persistent learner records, released syllabus-mapped content, diagnostics, server-side saved attempts, real grading/submission workflows, payments, transactional email or production analytics. The updated app build and fresh Cloudflare deployment have not been independently confirmed.

## Initial planned pathways

- IB MYP Language and Literature — Years 1–5.
- Cambridge Lower Secondary English — Stages 7–9.
- Cambridge IGCSE First Language English — grade 9–10 equivalent learning bands, pending academic confirmation of the precise mapping.

These programmes are distinct. Course and syllabus mapping must be verified against official specifications before content publication. Stage 1 is a starter pathway, not exhaustive coverage.

## Revision and future-change policy

Any approved or reviewed feature, content item or document may be updated later. Approval is version-specific, not a permanent freeze. Keep changes in Git history, record the reason and version, update dependent documents, and re-review material changes. Existing explicit approval rules for business decisions and design tokens still apply.

## Project documents

- [Master project brief](docs/PROJECT_MASTER_BRIEF.md) — approved product and business rules.
- [Design specification](docs/DESIGN_SPEC.md) — approved visual system and screen behaviour.
- [English Stage 1 roadmap](docs/ENGLISH_STAGE_1_ROADMAP.md) — tracks the reviewed pilot preview and the remaining curriculum mapping/release gates.
- [Logical data model](docs/DATA_MODEL.md) — proposed content, learner-record and access-control structure; not a live database.
- [Typed pathway catalogue](src/content/pathways.ts) — 10 planned entries and 30 unit slots; the first slot is approved for pilot preview but remains officially unmapped.
- [Content types](src/content/model.ts) — shared TypeScript structures for pathway, unit and demonstration content.
- [Pilot unit brief](src/content/pilotUnitDraft.ts) — reviewed for pilot preview; candidate objective references and official mapping remain unverified.
- [Learner-safe pilot lesson](src/content/pilotLearnerLesson.ts) — reviewed lesson and practice prompts without answer keys.
- [Teacher/editor answer guide](src/content/pilotLessonPack.ts) — teacher-only source with model answers; do not import into the client application.
- [Pilot unit review sheet](docs/PILOT_UNIT_REVIEW.md) — academic content review pass, remaining release checks and revision guardrails.
- [Unit readiness rules](src/content/unitReadiness.ts) — calculates release gates from source evidence, content links and review records; current records remain planning-only.

## Technology

- React
- TypeScript
- Vite
- Cloudflare Workers for the current deployed preview

## Local development

Use Node.js 20.19+ (or 22.12+), run `npm install`, then `npm run dev` to start the development preview. Run `npm run build` to check TypeScript and generate a production build.

## Deployment

The current prototype is deployed to Cloudflare Workers. Keep the codebase portable and verify the selected Cloudflare product's current terms, limits and data-handling requirements before commercial launch or before handling real student information. The current preview is not production-ready for authenticated accounts or student records.

## Security rules

- Keep this repository private.
- Never commit API keys, passwords, `.env` files, student submissions or private customer information.
- Add secrets only through the hosting provider's environment settings when needed.
- Use `docs/PROJECT_MASTER_BRIEF.md` as the source of truth. Update it when a decision is explicitly approved.
