# IB/IGCSE Learning Platform

The curriculum-aware IB and Cambridge learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Criterion Lab is a placeholder working name.** The final brand and domain have not been decided.

## Current status

The repository's React + TypeScript prototype now contains six clickable screens on `main` (including the pathway catalogue). The earlier five-screen preview was deployed to Cloudflare Workers; deployment of the latest pathway-catalogue change has not yet been independently confirmed:
- Public homepage and pathway discovery.
- Pathway catalogue with 10 planned English pathway entries; the first IB MYP Year 1 unit has an original working draft for academic review.
- Student dashboard.
- Lesson and sample practice interaction.
- Searchable and filterable question-bank prototype.
- Human-assessment feedback concept screen.

The assessment evidence toggle has been fixed and verified on the earlier deployed preview. The pathway catalogue is connected to the prototype navigation and displays the 10 planned English pathway entries grouped by programme, with three planned unit slots each. The first IB MYP Year 1 slot now has an original, clearly labelled working draft: a proposed learning objective, teaching sequence, invented micro-extract, practice prompt and review questions. The official IB subject page and date checked are recorded, but the source is broad rather than an edition-specific Year 1 specification; no official objective codes or approved mapping have been assigned. The eight-gate readiness checklist therefore remains blocked for source mapping and release. The six question-bank examples and illustrative demo lesson remain separate with unassigned curriculum metadata. The checklist and draft preview do not save changes to a database.

**This is a static design prototype, not a live learning product.** Dashboard numbers, activity, questions, rubric criteria, marks and feedback are fictional demonstration data. The sample lesson has not been verified against a specific syllabus edition. The answer check and filters are local prototype interactions; they do not save real learner records.

Not yet implemented: authentication, database, persistent learner records, released syllabus-mapped content, diagnostics, server-side saved attempts, real grading/submission workflows, payments, transactional email or production analytics.

## Initial planned pathways

- IB MYP Language and Literature — Years 1–5.
- Cambridge Lower Secondary English — Stages 7–9.
- Cambridge IGCSE First Language English — grade 9–10 equivalent learning bands, pending academic confirmation of the precise mapping.

These programmes are distinct. Course and syllabus mapping must be verified against official specifications before content publication. Stage 1 is a starter pathway, not exhaustive coverage.

## Project documents

- [Master project brief](docs/PROJECT_MASTER_BRIEF.md) — approved product and business rules.
- [Design specification](docs/DESIGN_SPEC.md) — approved visual system and screen behaviour.
- [English Stage 1 roadmap](docs/ENGLISH_STAGE_1_ROADMAP.md) — pathway planning draft; exact skill sequence awaits academic-lead approval.
- [Logical data model](docs/DATA_MODEL.md) — proposed content, learner-record and access-control structure; not a live database.
- [Typed pathway catalogue](src/content/pathways.ts) — 10 planned entries and 30 unit slots; the first slot has an unapproved draft focus.
- [Content types](src/content/model.ts) — shared TypeScript structures for pathway, unit and demonstration content.
- [Pilot unit draft](src/content/pilotUnitDraft.ts) — original working draft for IB MYP Year 1, not approved or released.
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
