# GradioPrep — English learning and assessment

> **Current execution checkpoint — 8 November 2026 (authoritative active state; prior environment-setup proposals are superseded):** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. The user's confirmed local WSL checkout was clean at `1caf00e134333f7effcdaf94ac0cb233218e295b`; the remote branch is now two documentation-only commits ahead: `d4ebfb114d874f2bde6dc65af2345f2ab88b30cf` and `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`. Fast-forward once before the next local repository operation; do not reclone or reinstall. Node `v22.23.4`, npm `10.9.9` and the 130-package dependency installation are already complete. **Memory snapshot:** Windows reports 5.94 GiB visible RAM and 1.44 GiB available; WSL reports 2.8 GiB total, 688 MiB used, 1.8 GiB free and 2.1 GiB available, with 1 GiB swap unused; Docker reports about 2.81 GiB and 4 CPUs, with no running containers. **Binding device rule:** do not start Supabase/Docker-based database testing on this Windows/WSL computer, do not register it as a persistent self-hosted runner, and do not change its WSL/Docker resource limits. Run synthetic Supabase tests only inside an ephemeral GitHub-hosted `ubuntu-latest` CI job. Keep the repository private. GitHub Actions run [#42466738041](https://github.com/gradioprep/gradioprep-website/actions/runs/42466738041) failed with no steps reported and no accessible logs; its cause and current Actions-minute usage are unconfirmed, so do not claim that a quota was exhausted. The GitHub check [Workers Builds: gradioprep-website](https://github.com/gradioprep/gradioprep-website/runs/128687968955) passed on commit `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`. All five GitHub spending budgets remain blocked. **Cloudflare:** the private repository is already connected to Workers Builds; automatic builds and previews are enabled, with `main` configured for production, `npm run build` as build command and `npx wrangler deploy` as production deploy command. Build watch-path exclusions are currently empty; configure documentation-only exclusions in a later reviewed settings change. The account build-limit check on 8 November reported that the limit had not been reached. Phase 1C is complete, Phase 1D verified and Phase 1E partial/unverified; its 35- and 47-assertion SQL suites and backup/restore verifier remain pending. Hosted Supabase is not provisioned. Any later isolated cloud test project, branded staging, paid use, real learner data, external processing/email, DNS change, production configuration/deployment or PR merge remains separately gated.
The curriculum-aware IB, Cambridge and CBSE English learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Product name:** GradioPrep. **Confirmed custom domain:** `gradioprep.com`; it is not connected to the site and no DNS changes have been made.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.22) and the shared tokens in `src/styles.css` for every page.

## Current status

The public deployment on `main` remains the existing static prototype and is not connected to hosted Supabase. Phase 1C is complete, Phase 1D is verified and Phase 1E remains partial/unverified. The user's WSL checkout is clean at `1caf00e134333f7effcdaf94ac0cb233218e295b` before this documentation-only update. Node 22.23.4/npm 10.9.9 and the 130-package dependency installation are complete. Windows has 1.44 GiB available RAM; WSL has 2.1 GiB available. **Do not start Supabase or database containers on this PC.** Database/security tests run in an ephemeral GitHub-hosted CI job, not on the user's device. The latest exact-head GitHub Actions run #42466738041 failed without reported steps or accessible logs, so no test failure or exhausted-minute cause is established. The Workers Builds check for commit 37e279d passed. The repository remains private. Cloudflare Workers Builds is already connected; see the execution model below and the current Windows/WSL guide.

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
- [Phase 1D private PDF/file controls acceptance matrix](docs/PHASE_1D_PRIVATE_PDF_FILE_CONTROLS_ACCEPTANCE_MATRIX.md) — verified synthetic-CI file-security evidence.
- [Windows/WSL2 developer environment](docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md) — records the no-local-Supabase rule, memory assessment and hosted CI strategy.
- [Free-first infrastructure and cost policy](docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md) — current GitHub Actions and Cloudflare Workers Builds controls.
- [Public Preview and custom-domain release process](docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md) — synthetic Preview, staging and production approval gates.
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

## Build, test and deployment execution

- **Keep GitHub private.** The repository contains unpublished product plans, assessment specifications and security architecture as well as application code. The absence of a hard-coded API key is not, by itself, sufficient reason to publish the complete repository and its history.
- **Cloudflare Workers Builds** is already connected to this private repository. It is configured for automatic builds, branch previews and the `main` production branch. Its current watch-path configuration includes all files and excludes none, so documentation-only commits can trigger builds. A later reviewed configuration change should exclude documentation-only paths.
- **GitHub Actions** remains the security/test runner on ephemeral `ubuntu-latest` machines. The Supabase CLI stack started by the workflow exists inside that hosted job, uses synthetic fixtures and is stopped/removed at the end. It does not run on the user's PC.
- Configure GitHub workflow path filters so documentation-only commits and PR-description edits do not start the heavyweight database/browser suite. Keep relevant schema, Worker, application, test and workflow changes covered.
- Never register this Windows/WSL computer as a persistent self-hosted runner or start local Supabase on it. Do not change local resource limits to make local Supabase fit.
- A separate free Supabase cloud project is a later option only if hosted end-to-end testing actually requires it. It is not needed for the current CI database tests and must not be provisioned without separate approval.

## Local development

Node.js 22.23.4/npm 10.9.9 and dependencies are already installed inside WSL. The user does not need to reinstall them or run local database containers. A browser-only Vite development session may be used later if specifically needed, but database/security verification must stay on the hosted CI runner. Do not run `npm run supabase:start`, `npx supabase start` or a self-hosted Actions runner on this PC.

## Deployment

The current application is hosted on [Cloudflare Workers](https://gradioprep-website.wandering-scene-1822.workers.dev). Cloudflare Workers Builds is the existing Git-connected build/deployment integration; it is configured for the `main` production branch and branch previews. The current account limit check reported that the free build allowance had not been reached, but this is not proof of a recent successful build. A Preview is not production approval or evidence of hosted Supabase functionality. Keep production deployment, domain/DNS changes and hosted backend provisioning behind their existing separate approvals.

## Security rules

- Keep this repository private.
- Never commit API keys, passwords, `.env` files, student submissions or private customer information.
- Add secrets only through the hosting provider's environment settings when needed.
- Use `docs/PROJECT_MASTER_BRIEF.md` as the source of truth. Update it when a decision is explicitly approved.

## Approved roadmap and commercial-policy update — 6 November 2026

The Master Brief, Grading Credit and Remedial Access Policy, Data Model, Flagship PDF Response Grading and Timed Analytics Specification and English Stage 1 Roadmap record the approved additions. They extend the existing architecture and phases; they do not create a second app or database.

Current catalogue: free Diagnostic + complete Evaluation Report (₹999 stated value); standalone Remedial Course ₹1,999; 2 credits ₹1,500; 5 credits ₹3,750; Gold 10 credits ₹7,500; Platinum 20 credits ₹14,999. Only Diwali offers are free Diagnostic/report and Platinum 20 credits plus Remedial Course for ₹7,999. Board-neutral tariff: 1–50 words=1; 51–150=2; 151–350=3; above 350 add one credit per additional 100 words or part thereof. Time credits are one per 20 predicted grader minutes; final credits are max(word-based, time-based). These are documented decisions, not implemented pricing UI, checkout, payment, ledger, entitlements, queue search or promotions.
