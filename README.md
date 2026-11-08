# GradioPrep — English learning and assessment

> **Current execution checkpoint — 8 November 2026 (authoritative active state; earlier dated records are historical):** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. The user has fast-forwarded the WSL checkout to `480e019e3a3b9f4ce07b257fd5bd15d7fc68cc7f`; local HEAD, origin and PR head matched, and the working tree was clean. **Node/dependencies:** Node `v22.23.4`, npm `10.9.9`, both at `/home/gradioprep/.nvm/versions/node/v22.23.4/bin/`; `npm install --no-audit --no-fund` succeeded and added 130 packages. The workflow intentionally does not commit `package-lock.json`; the local working tree is clean. **Current WSL/Docker memory snapshot:** WSL `free -h`: 2.8 GiB total, 688 MiB used, 1.8 GiB free, 2.1 GiB available; swap 1.0 GiB total, none used. Docker daemon: `MemTotal=3,020,513,280` bytes (approximately 2.81 GiB), 4 CPUs. `docker ps` reports no running containers. The PC has 8 GB DDR4 RAM; current Windows available physical RAM is still unreported. **Resource decision: HOLD — do not start Supabase or change WSL/Docker limits until the Windows free-memory reading is reviewed.** The workflow excludes Studio, Logflare, Vector, Edge Runtime, Postgres Meta, Realtime and Supavisor, retaining PostgreSQL, Auth, Storage API, imgproxy, Kong, Mailpit and PostgREST. Supabase recommends at least 7 GB RAM for all local services but publishes no minimum for this exact reduced set. Phase 1C is complete; Phase 1D is verified; Phase 1E remains partial/unverified: the 35- and 47-assertion SQL suites and local backup/restore verifier have not passed. Latest exact-head Actions run [#42463591504](https://github.com/gradioprep/gradioprep-website/actions/runs/42463591504) failed with no job steps reported and unavailable logs; this is not evidence of a test failure, and the precise cause is unknown. Workflow remains on `ubuntu-latest`; runner registration alone does not redirect jobs, and any self-hosted-runner change requires separate security review. All five GitHub spending budgets remain blocked. Local Supabase and synthetic data only; all hosted-service, paid-use, real-data, external-processing/email, DNS, deployment and merge restrictions remain in force.
The curriculum-aware IB, Cambridge and CBSE English learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Product name:** GradioPrep. **Confirmed custom domain:** `gradioprep.com`; it is not connected to the site and no DNS changes have been made.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.22) and the shared tokens in `src/styles.css` for every page.

## Current status

The public deployment on main remains the static prototype and is not connected to hosted Supabase. Phase 1C is complete; Phase 1D is verified; Phase 1E remains partial/unverified. The WSL checkout is synchronised at 480e019e3a3b9f4ce07b257fd5bd15d7fc68cc7f with a clean working tree. Node 22.23.4/npm 10.9.9 and the successful 130-package npm install are confirmed. WSL reports 2.8 GiB total and 2.1 GiB available; Docker sees 2.81 GiB and 4 CPUs, with no containers running. The Windows free-memory reading is still required. Do not start local Supabase before reviewing that reading. Exact-head Actions run #42463591504 ended without any reported job steps; no test failure is established. See the Windows WSL2 build environment guide.

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
