# GradioPrep — English learning and assessment

> **Current execution checkpoint — 8 November 2026 (authoritative active status; older dated milestone records remain historical):** PR #22 is open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. The WSL2 checkout at `/home/gradioprep/src/gradioprep-website` is verified: local branch, remote branch and live PR head all match `2a582c42c071a7dda85d197672e9255398e55140`. **Phase 1C is complete** at verified code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`; exact-head CI [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests. **Phase 1D is verified** at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`; exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) passed 519 pgTAP assertions across 15 SQL files, builds, 31/31 Playwright tests and cleanup. **Phase 1E is partial and unverified:** its 35- and 47-assertion SQL suites have not run, and the backup/restore verifier remains unverified. Latest docs-head Actions run [#42460447569](https://github.com/gradioprep/gradioprep-website/actions/runs/42460447569), job `128668398248`, failed before runner assignment (runner ID 0, empty runner name, zero steps); it is an infrastructure failure, not test evidence. WSL2 Ubuntu, Docker Desktop integration, Docker Engine, Compose, Git and GitHub CLI are installed; GitHub CLI authentication for `gradioprep` and private-repository access are verified. **Current local pause point:** WSL cannot find `node`; `npm --version` returned `11.19.0`, but its executable path has not been verified. `package.json` requires Node `>=20.19.0`, and the current workflow pins Node 22, so install a WSL-native Node 22 runtime before running npm installs or project scripts. The PC has 8 GB DDR4 RAM while Docker/Ubuntu reports about 2.8 GiB; review the reduced-service Supabase footprint before starting the stack or changing memory settings. The workflow remains on `ubuntu-latest`; runner registration alone will not redirect jobs, and a separate security-reviewed workflow change is required. **All five GitHub spending budgets remain blocked.**
The curriculum-aware IB, Cambridge and CBSE English learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Product name:** GradioPrep. **Confirmed custom domain:** `gradioprep.com`; it is not connected to the site and no DNS changes have been made.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.22) and the shared tokens in `src/styles.css` for every page.

## Current status

The public deployment on `main` remains the static prototype and is not connected to hosted Supabase. Phase 1C is complete, Phase 1D is verified at its recorded checkpoint, and Phase 1E remains partial/unverified, with its 35- and 47-assertion SQL suites and backup/restore verifier not yet run. Latest docs-head Actions run [#42460447569](https://github.com/gradioprep/gradioprep-website/actions/runs/42460447569) failed before runner assignment with runner ID 0 and zero steps; it is not test evidence. As of 8 November 2026, WSL2, Docker Desktop integration, Git, GitHub CLI authentication and private-repository access are verified. The repository is cloned at `/home/gradioprep/src/gradioprep-website`, and the local branch, remote branch and live PR #22 head match `2a582c42c071a7dda85d197672e9255398e55140`. **The immediate local blocker is Node.js:** WSL cannot find `node`; npm reports `11.19.0`, but its path is not verified. Install WSL-native Node 22 to match the workflow before dependency installation. The PC has 8 GB RAM, while Docker/Ubuntu reports about 2.8 GiB; review the reduced-service Supabase footprint before starting the stack. See [the Windows WSL2 build environment guide](docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md).

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
- [Phase 1D private PDF/file controls acceptance matrix](docs/PHASE_1D_PRIVATE_PDF_FILE_CONTROLS_ACCEPTANCE_MATRIX.md) — verified local-only file security evidence.
- [Windows WSL2 build environment](docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md) — secure local CI recovery without GitHub-hosted job minutes.
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
