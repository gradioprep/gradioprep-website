# GradioPrep — English learning and assessment

The curriculum-aware IB, Cambridge and CBSE English learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Product name:** GradioPrep. **Confirmed custom domain:** `gradioprep.com`; it is not connected to the site and no DNS changes have been made.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.22) and the shared tokens in `src/styles.css` for every page.

## Current status

The public deployment on `main` remains the previously verified static prototype and is not connected to hosted Supabase. Draft PR #22 remains open, draft and unmerged. Verified application-code head: `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`; exact-head run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds and **31/31 Playwright tests**, including both synchronized Phase 1C-F race tests. After that exact-head documentation CI run, 23 documentation-only commits advanced the branch through `732ad90ce10eb7d407f2370d426958da36925713`, reconciling the approved catalogue, universal word/time tariff, free Diagnostic/report, standalone course entitlement, queue-search/filter design and downstream roadmap across 12 source-of-truth files. This resumed reconciliation removes the remaining active legacy SLA text from the Design Spec, replaces the superseded tier/Study Lab summary in the Data Model, and labels the earlier Phase 1A checkpoint as historical. A fresh exact-head CI run is required for this final documentation state; check PR #22 Actions before treating the documentation gate as complete. Preview creation/update steps were skipped on the cited earlier run; **no new public Preview or production deployment occurred**.

Phase 1C-E evidence remains representative per distinct action, not exhaustive outcome coverage. The Phase 1C closeout inventory was 25 tables (18 public, seven private), 29 HTTP method/path rows and 25 Worker-audited routes. Phase 1D adds `private.submission_files`, bringing the protected inventory to **26 tables (18 public, eight private)**, and three file routes, bringing the endpoint matrix to **32 rows**. Two new file write routes use Worker audit-outcome ingestion (27 Worker-audited routes total); file-read allow/deny is recorded inside its database authorization RPC. Both synchronized Phase 1C-F races pass: simultaneous same-token invitation acceptance, and role revocation/account suspension racing an in-flight privileged assignment. Existing assignment/publication concurrency and duplicate-submission idempotency tests were retained. **Phase 1C is now closed** at the local synthetic acceptance boundary after final review of the 25-table protected inventory, 29-route authorization/audit matrix, 25 fail-closed audited routes and adversarial evidence. Exact code/test evidence is run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858); the pre-closeout documentation baseline passed run [#42166224976](https://github.com/gradioprep/gradioprep-website/actions/runs/42166224976). Phase 1D private PDF/file controls are implemented and verified at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`; exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) passed 519 PostgreSQL/pgTAP assertions across 15 SQL files, TypeScript/Worker/Vite builds, 31/31 Playwright tests, local Supabase shutdown, local credential cleanup and clean credential-free asset build. Phase 1C-E correlation remains representative per distinct action, not exhaustive outcome coverage.

All current implementation verification uses local Supabase and synthetic records only. No hosted resource, paid usage, real learner data, external processing, merge, Preview deployment, production deployment or DNS/custom-domain change is authorised. The main-branch static prototype is not a production learner service, and the complete learner-facing PDF selection/upload journey, OCR, split-screen grader workspace, full grading/feedback flow, timer/analytics, Diagnostic/Evaluation Report, remedial course, commercial Admin dashboard, credit ledger and payment/checkout are not yet implemented. Do not enter real learner data or imply that the current public site is a released syllabus-mapped course.
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
- [Phase 1C endpoint authorization/audit matrix](docs/PHASE_1C_ENDPOINT_AUTHORIZATION_AUDIT_MATRIX.md) — updated 32-route authorization and audit mapping, including the Phase 1D file routes.
- [Phase 1D private PDF/file controls acceptance matrix](docs/PHASE_1D_PRIVATE_PDF_FILE_CONTROLS_ACCEPTANCE_MATRIX.md) — verified local-only file security, upload/access/cleanup boundaries and exact CI evidence.
- [Phase 1C-F adversarial acceptance matrix](docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md) — mapped actor/assurance and attack-surface evidence, including the two now-passing synchronized race tests.
- [Grading credit and remedial access policy](docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md) — approved universal word/time credit tariff, package prices, separate course entitlement, free access and commercial implementation sequence; specifications only, not live payment or credit processing.
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

## Approved roadmap and commercial-policy update — 6 November 2026

The Master Brief, Grading Credit and Remedial Access Policy, Data Model, Flagship PDF Response Grading and Timed Analytics Specification and English Stage 1 Roadmap record the approved additions. They extend the existing architecture and phases; they do not create a second app or database.

Current catalogue: free Diagnostic + complete Evaluation Report (₹999 stated value); standalone Remedial Course ₹1,999; 2 credits ₹1,500; 5 credits ₹3,750; Gold 10 credits ₹7,500; Platinum 20 credits ₹14,999. Only Diwali offers are free Diagnostic/report and Platinum 20 credits plus Remedial Course for ₹7,999. Board-neutral tariff: 1–50 words=1; 51–150=2; 151–350=3; above 350 add one credit per additional 100 words or part thereof. Time credits are one per 20 predicted grader minutes; final credits are max(word-based, time-based). These are documented decisions, not implemented pricing UI, checkout, payment, ledger, entitlements, queue search or promotions.
