# GradioPrep — English learning and assessment

> **Current execution checkpoint — 8 November 2026 (authoritative active status; older milestone records remain historical):** PR #22 is open, draft and unmerged; head branch `feature/phase-1b-local-auth-api`, base `docs/phase-1-secure-foundation-spec`. Live remote head at this checkpoint: `acfde1e9572d5149e8d4a857bfb32032db1dc45a`. The last recorded local checkout SHA is `2a582c42c071a7dda85d197672e9255398e55140`; the local branch/working-tree/head must be checked and fast-forwarded with `git pull --ff-only origin feature/phase-1b-local-auth-api` if behind. **Node.js setup is complete:** Node `v22.23.4`, npm `10.9.9`; both executables resolve inside `/home/gradioprep/.nvm/versions/node/v22.23.4/bin/`. Do not reinstall Node. Project dependencies have not yet been confirmed installed; run `npm install --no-audit --no-fund` only after verifying the checkout, then inspect tracked changes and lockfile status. **Do not start Supabase yet:** assess the reduced-service stack against the PC's 8 GB DDR4 RAM and the previously reported approximately 2.8 GiB available to Docker/Ubuntu; do not change memory limits. Phase 1C is complete; Phase 1D is verified; Phase 1E remains partial/unverified, including the 35- and 47-assertion SQL suites and backup/restore verifier. Exact-head Actions run [#42461053863](https://github.com/gradioprep/gradioprep-website/actions/runs/42461053863) failed with no job steps reported; runner-assignment metadata/logs were not retrievable, so do not classify it as a test failure or claim a runner ID. Earlier run [#42460447569](https://github.com/gradioprep/gradioprep-website/actions/runs/42460447569) is separately confirmed as a pre-runner-assignment failure (runner ID 0, zero steps). The workflow still targets `ubuntu-latest`; runner registration alone does not redirect jobs. A workflow change requires separate security review. All five GitHub spending budgets remain blocked. Local Supabase and synthetic data only; all existing hosted-service, paid-use, real-data, DNS, deployment and merge restrictions remain in force.
The curriculum-aware IB, Cambridge and CBSE English learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Product name:** GradioPrep. **Confirmed custom domain:** `gradioprep.com`; it is not connected to the site and no DNS changes have been made.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.22) and the shared tokens in `src/styles.css` for every page.

## Current status

The public deployment on `main` remains a static prototype and is not connected to hosted Supabase. Phase 1C is complete, Phase 1D is verified at its recorded checkpoint, and Phase 1E remains partial/unverified. Node 22/npm setup is complete in WSL; verify the local checkout and install project dependencies before any Supabase startup. The exact-head Actions run #42461053863 failed without reported job steps; no test result can be inferred. Review the reduced-service Supabase memory footprint before starting the stack. See [the Windows WSL2 build environment guide](docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md).

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
