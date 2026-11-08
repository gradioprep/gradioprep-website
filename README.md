# GradioPrep — English learning and assessment

> **Current execution checkpoint — 8 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. GitHub confirms the repository is **public**. The last user-reported clean WSL checkout is `1caf00e134333f7effcdaf94ac0cb233218e295b`; this session cannot inspect the local Windows/WSL files, so local cleanliness and synchronization are unverified. The remote branch has advanced since that report. Before further local work, inspect `git status --short --branch`, then fast-forward with `git pull --ff-only origin feature/phase-1b-local-auth-api` only if the working tree is clean; do not reclone or reinstall. Node 22.23.4, npm 10.9.9 and the 130-package install were last reported complete. **Do not start Supabase/Docker locally or register a self-hosted runner.** The heavy verification workflow now runs once on pushes to PR #22's dedicated branch `feature/phase-1b-local-auth-api` by the repository owner `gradioprep`; it ignores `docs/**` and Markdown-only changes and cancels superseded runs for the same branch. There is no parallel `pull_request` trigger or PR-description event. Commit `dc13c80` implements this single-trigger design. Standard `ubuntu-latest` and all database, SQL, build, browser and Phase 1E backup/restore steps remain. A passing post-change CI result is not yet confirmed. Previous run [#42466941118](https://github.com/gradioprep/gradioprep-website/actions/runs/42466941118) failed in about two seconds with zero job steps and unavailable logs; it proves neither a test failure nor quota exhaustion. Phase 1C is complete, Phase 1D verified, Phase 1E partial/unverified, and Phase 1F remains gated on Phase 1E acceptance. Hosted CI retry attempt 2 [#42466941118](https://github.com/gradioprep/gradioprep-website/actions/runs/42466941118) executed the 35-assertion deletion-ledger suite successfully. The 47-assertion closure/retention suite stopped at test line 82 because the fixture's separate clock readings violated the exact SLA constraint by one microsecond; its fixture was corrected in test-only commit `26fbea0`. The other 15 SQL files passed in that attempt. Current full run [#42473310987](https://github.com/gradioprep/gradioprep-website/actions/runs/42473310987) is running on the corrected branch head. The 47 assertions still need a successful run, and the browser/PDF + database backup/restore round-trip remain unverified. Cloudflare Workers Builds remains connected, but its watch-path exclusions have not been changed. No hosted Supabase, paid usage, DNS/custom-domain change, production deployment, real learner data or merge is authorised. All five GitHub spending budgets were last recorded as blocked.
The curriculum-aware IB, Cambridge and CBSE English learning platform described in the master project brief (`docs/PROJECT_MASTER_BRIEF.md`). The design direction is defined in `docs/DESIGN_SPEC.md`.

**Product name:** GradioPrep. **Confirmed custom domain:** `gradioprep.com`; it is not connected to the site and no DNS changes have been made.

**Current visual system:** approved Palette B—aubergine, dusty blue, soft lilac and plum charcoal, with cool-white and pale blue-grey surfaces, plus restrained semantic deep-blue and muted-amber feedback accents. Typography remains locked. Follow the current approved `docs/DESIGN_SPEC.md` (v2.22) and the shared tokens in `src/styles.css` for every page.

## Current status

The deployment on `main` remains the existing static prototype and is not connected to hosted Supabase. Phase 1C is complete, Phase 1D is verified and Phase 1E remains partial/unverified. The last user-reported clean WSL checkout is `1caf00e134333f7effcdaf94ac0cb233218e295b`, but this session could not inspect the local checkout; do not claim local synchronization. Node 22.23.4/npm 10.9.9 and 130 installed packages were last reported complete. **Do not start Supabase or database containers on this PC.** The GitHub workflow now runs once for relevant pushes to PR #22's dedicated head branch, excludes docs/Markdown, cancels stale runs and preserves the complete suite on `ubuntu-latest`. Workflow commit `dc13c80` is confirmed; full validation run #42473310987 is in progress. The previous run #42466941118 failed before any job step ran, with unavailable logs; no test or quota cause is established. The repository is public. Cloudflare Workers Builds remains connected; see the execution model below and the current Windows/WSL guide.

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

- **GitHub visibility is public.** Repository content, branches, PRs and history may be viewed publicly. Never commit credentials, tokens, private learner/teacher records or unapproved confidential material. This records current visibility; it is not a claim that the full repository history has been security-scanned.
- **Cloudflare Workers Builds** is already connected to this public repository. It is configured for automatic builds, branch previews and the `main` production branch. Its current watch-path configuration includes all files and excludes none, so documentation-only commits can trigger builds. A later reviewed configuration change should exclude documentation-only paths.
- **GitHub Actions** remains the security/test runner on ephemeral `ubuntu-latest` machines. The Supabase CLI stack started by the workflow exists inside that hosted job, uses synthetic fixtures and is stopped/removed at the end. It does not run on the user's PC.
- **GitHub Actions** runs the comprehensive synthetic database/security/build/browser suite once on relevant pushes to PR #22's dedicated branch. It ignores `docs/**` and Markdown-only diffs, and cancels stale runs for the same branch. Application, Worker, migration, SQL/browser test, dependency, workflow and configuration changes remain covered. The separate `build.yml` retains the `main` push/manual build path, ignores docs/Markdown and skips PR #22's stacked base.
- Never register this Windows/WSL computer as a persistent self-hosted runner or start local Supabase on it. Do not change local resource limits to make local Supabase fit.
- A separate free Supabase cloud project is a later option only if hosted end-to-end testing actually requires it. It is not needed for the current CI database tests and must not be provisioned without separate approval.

## Local development

Node.js 22.23.4/npm 10.9.9 and dependencies are already installed inside WSL. The user does not need to reinstall them or run local database containers. A browser-only Vite development session may be used later if specifically needed, but database/security verification must stay on the hosted CI runner. Do not run `npm run supabase:start`, `npx supabase start` or a self-hosted Actions runner on this PC.

## Deployment

The current application is hosted on [Cloudflare Workers](https://gradioprep-website.wandering-scene-1822.workers.dev). Cloudflare Workers Builds is the existing Git-connected build/deployment integration; it is configured for the `main` production branch and branch previews. The current account limit check reported that the free build allowance had not been reached, but this is not proof of a recent successful build. A Preview is not production approval or evidence of hosted Supabase functionality. Keep production deployment, domain/DNS changes and hosted backend provisioning behind their existing separate approvals.

## Security rules

- The repository is public; do not add credentials, real learner data or confidential teacher materials.
- Never commit API keys, passwords, `.env` files, student submissions or private customer information.
- Add secrets only through the hosting provider's environment settings when needed.
- Use `docs/PROJECT_MASTER_BRIEF.md` as the source of truth. Update it when a decision is explicitly approved.

## Approved roadmap and commercial-policy update — 6 November 2026

The Master Brief, Grading Credit and Remedial Access Policy, Data Model, Flagship PDF Response Grading and Timed Analytics Specification and English Stage 1 Roadmap record the approved additions. They extend the existing architecture and phases; they do not create a second app or database.

Current catalogue: free Diagnostic + complete Evaluation Report (₹999 stated value); standalone Remedial Course ₹1,999; 2 credits ₹1,500; 5 credits ₹3,750; Gold 10 credits ₹7,500; Platinum 20 credits ₹14,999. Only Diwali offers are free Diagnostic/report and Platinum 20 credits plus Remedial Course for ₹7,999. Board-neutral tariff: 1–50 words=1; 51–150=2; 151–350=3; above 350 add one credit per additional 100 words or part thereof. Time credits are one per 20 predicted grader minutes; final credits are max(word-based, time-based). These are documented decisions, not implemented pricing UI, checkout, payment, ledger, entitlements, queue search or promotions.
