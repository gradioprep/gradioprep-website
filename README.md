# IB/IGCSE Learning Platform

The curriculum-aware IB and Cambridge learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Criterion Lab is a placeholder working name.** The final brand and domain have not been decided.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.19) and the shared tokens in `src/styles.css` for every page.

## Current status

The public deployment on `main` remains the previously verified static prototype and is not connected to hosted Supabase. Draft PR #22 contains the local synthetic Supabase Auth/PostgreSQL/Worker foundation; it remains open, draft and unmerged. The current verified code/test head is `5dba933dce39b05c69a6616e5bb730d404e3b5a2`; exact-head GitHub Actions run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds and **29/29 Playwright tests**. The run's Preview upload/comment steps were skipped; **no Preview or production deployment occurred for this checkpoint**.

Phase 1C-E now has representative per-distinct-action persisted audit correlation coverage, not exhaustive outcome coverage. The 29-row endpoint authorization/audit matrix records 25 Worker-audited routes with fail-closed audit-outage tests. Worker action `student_attempt_create` maps to successful persisted event `attempt_created`; Worker action `grader_assessment_draft_save` maps to successful persisted event `assessment_draft_saved`. The consolidated Phase 1C-F matrix maps existing actor/assurance, RLS, forged-field, replay and concurrency tests. Only two synchronized synthetic race tests remain open: simultaneous acceptance of one invitation token, and revocation/suspension racing an in-flight privileged request. Phase 1D remains blocked until all Phase 1C exit criteria pass.

All current implementation verification uses local Supabase and synthetic records only. No hosted resource, paid usage, real learner data, external processing, merge, Preview deployment, production deployment or DNS/custom-domain change is authorised. The main-branch static prototype is not a production learner service, and the PDF workflow, Diagnostic/Evaluation Report, remedial course, commercial Admin dashboard, credit ledger and payment/checkout are not yet implemented. Do not enter real learner data or imply that the current public site is a released syllabus-mapped course.
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
- [Logical data model](docs/DATA_MODEL.md)
- [Phase 1C endpoint authorization/audit matrix](docs/PHASE_1C_ENDPOINT_AUTHORIZATION_AUDIT_MATRIX.md) — 29-route authorization and audit mapping, including the 25 Worker-audited routes.
- [Phase 1C-F adversarial acceptance matrix](docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md) — existing security evidence and the two remaining synchronized race tests. — logical content, learner-record and access-control structure; selected identity/assessment records are implemented only in the local synthetic PR/CI environment, not in a hosted production database.
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
