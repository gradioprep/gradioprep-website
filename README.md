# IB/IGCSE Learning Platform

The curriculum-aware IB and Cambridge learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Criterion Lab is a placeholder working name.** The final brand and domain have not been decided.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.19) and the shared tokens in `src/styles.css` for every page.

## Current status

The React + TypeScript prototype has six clickable screens, including Pathways and an interactive Lesson & practice preview. PR #10 (URL-based pathway navigation and in-page Previous/Next controls) is merged to `main` as `7d8d4ff53eaab5cef468bc4e0d3b633e51907e25` and deployed to [Cloudflare Workers](https://gradioprep-website.wandering-scene-1822.workers.dev). Production build `99301a5d-91f7-4939-af95-f356f20268a7` succeeded; the owner confirmed the live pathway flow, Previous/Next controls, browser Back/Forward and direct URLs. GitHub Actions run #64 passed, with 11/11 Chromium browser tests. This verifies the navigation milestone, not a commercial launch.

The first IB MYP Year 1 pilot lesson, **How writers shape meaning**, passed academic content review for pilot-preview version 1, as confirmed by the project owner on 24 October 2026. It includes an original reading passage, four teaching stages, four practice tasks, written-response fields and self-review checklists. Responses are temporary to the open preview, are not graded and are not saved.

The client imports [`src/content/pilotLearnerLesson.ts`](src/content/pilotLearnerLesson.ts) for the lesson and [`src/content/pilotReviewSummary.ts`](src/content/pilotReviewSummary.ts) for non-answer pathway/release metadata. Neither contains correct-answer IDs or model answers. The teacher/editor unit brief and answer source, [`src/content/pilotUnitDraft.ts`](src/content/pilotUnitDraft.ts) and [`src/content/pilotLessonPack.ts`](src/content/pilotLessonPack.ts), are not imported into the client module graph. This is source separation for the static prototype, not a production authorization system.

**Important:** the content is approved for a pilot preview only. Official IB guide edition/objective mapping is still unverified; `officialObjectiveCodes` remains empty. Separate rights review, accessibility review and explicit release approval are outstanding, so the unit is not a released syllabus-mapped course. The existing demo question-bank content remains separate with unassigned curriculum metadata.

**Implementation status — distinguish the deployed site from the unmerged build:** The public deployment on `main` remains a static prototype preview and is not connected to hosted Supabase. Draft PR #22 contains the local synthetic Supabase Auth/PostgreSQL/Worker foundation. Phase 1B and Phase 1C-A/B/C/D are verified at their recorded local-synthetic checkpoints. Phase 1C-E has Worker-only audit-outcome ingestion: browser-facing generic audit writers are revoked, the trusted Worker uses its server-only service-role client only for allowlisted audit events, business reads/writes remain caller-scoped, and missing audit service/acknowledgement fails closed. The latest PR branch head `203926d6db83e7003bfd4ee1a5c42e9d89c1f034` passed exact-head [run #42005970837](https://github.com/gradioprep/gradioprep-website/actions/runs/42005970837): 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 29/29 Playwright tests, plus local cleanup and clean public-preview assets. The 29-row endpoint matrix and fail-closed checks for 25 Worker-audited routes are recorded, with selected persisted request-ID correlations and concurrency tests passing; the complete per-action persisted audit-correlation matrix and consolidated Phase 1C-F adversarial signoff remain open. Phase 1D remains blocked. The GitHub Actions Preview upload was skipped for the branch-push event; Cloudflare Workers Builds separately published a public branch-shell Preview at [the immutable deployment](https://eca62996-gradioprep-website.wandering-scene-1822.workers.dev), disconnected from hosted Supabase and unsuitable for live Auth/API or real-data testing. This is not a Founder Preview request or production deployment. The deployed public shell still does not provide real hosted learner accounts, production persistence or a live grading service. Branded custom-domain staging backed by a separate isolated hosted synthetic backend remains mandatory before final Diagnostic/Evaluation Report acceptance, subject to separate hosted-resource and DNS/domain approval; production cutover is a distinct later gate. The full learner-facing PDF workflow, diagnostic and evaluation report, remedial course, commercial Admin dashboard, credit ledger, payment/checkout, ordinary student email-delivery integration and production analytics are not yet implemented. Do not enter real learner data or imply that the current public site is a released syllabus-mapped course or production learner service.

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
- [Logical data model](docs/DATA_MODEL.md) — logical content, learner-record and access-control structure; selected identity/assessment records are implemented only in the local synthetic PR/CI environment, not in a hosted production database.
- [Grading credit and remedial access policy](docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md) — approved tier allocation, curriculum-frequency method, free/paid access and commercial implementation sequence; specifications only, not live payment or credit processing.
- [Typed pathway catalogue](src/content/pathways.ts) — 10 planned entries and 30 unit slots; the first slot is approved for pilot preview but remains officially unmapped.
- [Content types](src/content/model.ts) — shared TypeScript structures for pathway, unit and demonstration content.
- [Pilot unit brief](src/content/pilotUnitDraft.ts) — teacher/editor source; candidate objective references and official mapping remain unverified.
- [Pilot review summary](src/content/pilotReviewSummary.ts) — answer-free curriculum and release metadata for Pathways.
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

The current prototype is deployed to [Cloudflare Workers](https://gradioprep-website.wandering-scene-1822.workers.dev); the live deployment of the pathway-navigation milestone has been confirmed. This is a preview, not a commercial-launch or real-student-data approval. Keep the codebase portable and verify the current Workers product/plan terms, limits, security controls and data-handling requirements before commercial use.

## Security rules

- Keep this repository private.
- Never commit API keys, passwords, `.env` files, student submissions or private customer information.
- Add secrets only through the hosting provider's environment settings when needed.
- Use `docs/PROJECT_MASTER_BRIEF.md` as the source of truth. Update it when a decision is explicitly approved.
