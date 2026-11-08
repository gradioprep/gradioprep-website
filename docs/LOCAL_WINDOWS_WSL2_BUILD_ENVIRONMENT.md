# Windows/WSL2 Developer Environment — Local Supabase Disabled

**Status date:** 8 November 2026  
**Repository:** private `gradioprep/gradioprep-website`, PR #22  
**Authority:** `docs/PROJECT_MASTER_BRIEF.md`, `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md` and `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`.

## 1. Binding decision

**Do not run Supabase or its Docker database containers on this Windows/WSL computer. Do not register this computer as a GitHub self-hosted runner.** The user's senior developer advised against local Supabase because of the risk to this machine. The observed available memory reinforces that precaution. The approved testing route is an ephemeral GitHub-hosted `ubuntu-latest` job that starts synthetic Supabase services inside the hosted job, not on the user's PC.

Do not attempt to solve this by increasing WSL/Docker RAM, changing swap/CPU settings, installing a second Docker Engine or starting a reduced Supabase stack locally. This is not a temporary "wait for more RAM" instruction; local Supabase is removed from the user's device workflow.

## 2. Verified computer and installed tools

The user provided these read-only readings on 8 November 2026:

| Environment | Total / limit | Used | Free | Available |
|---|---:|---:|---:|---:|
| Windows physical RAM | 5.94 GiB visible | — | — | 1.44 GiB |
| WSL2 | 2.8 GiB | 688 MiB | 1.8 GiB | 2.1 GiB |
| Docker daemon | 2.81 GiB | — | — | Not separately reported |
| WSL swap | 1.0 GiB | 0 | 1.0 GiB | 1.0 GiB |

Docker reports four CPUs. `docker ps` listed no running containers at the time of the check.

Already installed and verified:
- WSL2 Ubuntu, Linux user `gradioprep`.
- Docker Desktop WSL integration, Docker Engine 29.9.2 and Compose 5.6.1.
- Git and GitHub CLI; GitHub CLI is authenticated to the private `gradioprep` repository.
- Node.js 22.23.4 and npm 10.9.9 using nvm.
- `npm install --no-audit --no-fund` completed and installed 130 packages. `node_modules/` is ignored; the generated `package-lock.json` is intentionally not committed.

Do not reinstall Node or dependencies. No additional local environment setup is required for the selected CI route. The WSL/Docker installation may remain in place but must remain idle for Supabase/CI work.

## 3. Repository synchronisation checkpoint

The user confirmed a clean local checkout at `1caf00e134333f7effcdaf94ac0cb233218e295b` on `feature/phase-1b-local-auth-api`. The remote branch has advanced through documentation-only infrastructure/CI reconciliations after the user's confirmed local head. Before the next local repository operation, run one `git pull --ff-only origin feature/phase-1b-local-auth-api`; do not reclone or reinstall tools. PR #22 remains open, draft and unmerged.

## 4. Where database tests run

The checked-in `.github/workflows/phase1b-verification.yml` uses `runs-on: ubuntu-latest`. Its `npx supabase start --exclude ...` command runs inside a temporary GitHub-hosted machine. It creates only disposable synthetic test data, runs database/RLS tests, builds and browser tests, stops Supabase and removes ignored local environment files at the end.

**This does not start Supabase on the user's computer.** The runner is hosted by GitHub and is separate from Windows, WSL and Docker Desktop on the user's machine. Keep this isolation. Never redirect the workflow to `self-hosted`, `gradioprep-wsl2` or another label referring to this computer.

The current workflow has documentation-trigger inefficiencies: a push to the feature branch can run the full job even when only Markdown changes, and PR `edited` events can run it again. A later workflow change should ignore docs-only changes and remove `edited` from the heavy test trigger, while retaining all security-relevant source, migration, SQL, browser, dependency, workflow and configuration files. Review the separate `build.yml` for duplicate checks. These workflow changes have not yet been made.

## 5. Existing Cloudflare Workers Builds integration

Read-only inspection of the connected Cloudflare account on 8 November 2026 confirmed:

| Setting | Existing value |
|---|---|
| Worker | `gradioprep-website` |
| GitHub repository | `gradioprep/gradioprep-website` (private) |
| Production branch | `main` |
| Automatic builds | Enabled |
| Branch Previews | Enabled |
| Build command | `npm run build` |
| Production deploy command | `npx wrangler deploy` |
| Preview command | `npx wrangler preview` |
| Watch paths | Include `*`; exclude list is empty |

The Cloudflare account build-limit endpoint reported that the limit had not been reached and showed a refresh date of 30 November 2026. The current build-list query returned no records; a successful current build has therefore not been newly verified by this inspection. Cloudflare's current Workers Builds documentation lists 3,000 free build minutes per month, one concurrent build and a 20-minute timeout.

The selected direction is to retain this existing Git-connected Workers Builds integration for normal application builds/deployments and branch Previews. Add documentation-only exclusions to production and Preview watch paths after a reviewed configuration change; keep application, Worker, migration, test and configuration files included. Do not alter production deployment commands/branch, DNS, custom domains, Worker bindings or secrets as part of path filtering. No Cloudflare settings were changed by this documentation update.

## 6. GitHub Actions billing and repository visibility

The repository remains private. GitHub's public-repository standard-runner allowance is not a sufficient reason to publish GradioPrep's full source and its internal strategy/security records. Public visibility would expose the complete repository history, branches, PRs, documentation, Actions logs and artifacts. Reconsider it only after a deliberate open-source/IP decision and full history/secret review.

For private repositories, GitHub-hosted Actions minutes depend on the owner account's GitHub plan and included usage. The account's current plan/remaining minutes have not been verified. The latest exact-head run `#42466941118` failed without reporting job steps and its logs were unavailable. That does not establish whether the failure was caused by an included-minute limit, a runner/queue issue or another configuration problem. Do not label the cause as quota exhaustion without evidence. All five GitHub spending budgets remain blocked; do not unblock them or permit paid overage.

## 7. Conditional hosted Supabase option

A separate Supabase Free project may be considered later if the team needs a real hosted Auth/API/Storage integration test or branded staging journey that cannot be proved through the disposable CI stack. Supabase currently permits up to two active Free projects per eligible account, but Free projects may pause after a week of insufficient database activity. Do not assume project capacity is available or that Free means always-on.

A hosted test project is not needed for the current database/RLS CI tests and is not provisioned. Even a free hosted project requires separate explicit approval, a dedicated synthetic-only purpose, restricted credentials, no production linkage, and a reviewed reset/backup/restore/deletion process. The future branded staging requirement remains separate and mandatory before final Diagnostic/Evaluation Report acceptance; its hosted project/Worker/DNS approvals still apply.

## 8. Current project status and next steps

- Phase 1C: complete.
- Phase 1D: verified.
- Phase 1E: partial/unverified. The 35- and 47-assertion SQL suites and the backup/restore verifier remain pending.
- Phase 1F: follows Phase 1E acceptance.
- PR #22: open, draft and unmerged; no merge or production release is authorised.

Next engineering sequence: (1) add GitHub docs-only workflow path filters and remove unnecessary PR-edited triggering; (2) configure Cloudflare Workers Builds watch-path exclusions; (3) verify a new branch Preview/build and exact-head hosted CI; (4) run the pending Phase 1E suites and backup/restore verifier in GitHub-hosted ephemeral CI. Reconcile duplicate Preview deployment paths before removing either existing mechanism.

## 9. Approval boundaries

This guide does not authorise:
- starting Supabase/Docker database containers on the user's computer or registering a local self-hosted runner;
- creating or linking any hosted Supabase project, even on the Free plan;
- making the GitHub repository public;
- changing GitHub spending budgets, billing, overage or paid usage;
- changing Cloudflare build/deployment settings, production Worker configuration, bindings, secrets, custom domains or DNS;
- production deployment, PR merge, real learner data, external processing/email or public launch.

Use synthetic data only until the appropriate independent security, privacy and release approvals are granted.
