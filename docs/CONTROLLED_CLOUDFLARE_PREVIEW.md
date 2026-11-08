# Controlled Cloudflare Worker Preview

> **Current execution checkpoint — 8 November 2026 (authoritative active state; prior environment-setup proposals are superseded):** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. The user's confirmed local WSL checkout was clean at `1caf00e134333f7effcdaf94ac0cb233218e295b`; the remote branch is now two documentation-only commits ahead: `d4ebfb114d874f2bde6dc65af2345f2ab88b30cf` and `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`. Fast-forward once before the next local repository operation; do not reclone or reinstall. Node `v22.23.4`, npm `10.9.9` and the 130-package dependency installation are already complete. **Memory snapshot:** Windows reports 5.94 GiB visible RAM and 1.44 GiB available; WSL reports 2.8 GiB total, 688 MiB used, 1.8 GiB free and 2.1 GiB available, with 1 GiB swap unused; Docker reports about 2.81 GiB and 4 CPUs, with no running containers. **Binding device rule:** do not start Supabase/Docker-based database testing on this Windows/WSL computer, do not register it as a persistent self-hosted runner, and do not change its WSL/Docker resource limits. Run synthetic Supabase tests only inside an ephemeral GitHub-hosted `ubuntu-latest` CI job. Keep the repository private. GitHub Actions run [#42466738041](https://github.com/gradioprep/gradioprep-website/actions/runs/42466738041) failed with no steps reported and no accessible logs; its cause and current Actions-minute usage are unconfirmed, so do not claim that a quota was exhausted. The GitHub check [Workers Builds: gradioprep-website](https://github.com/gradioprep/gradioprep-website/runs/128687968955) passed on commit `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`. All five GitHub spending budgets remain blocked. **Cloudflare:** the private repository is already connected to Workers Builds; automatic builds and previews are enabled, with `main` configured for production, `npm run build` as build command and `npx wrangler deploy` as production deploy command. Build watch-path exclusions are currently empty; configure documentation-only exclusions in a later reviewed settings change. The account build-limit check on 8 November reported that the limit had not been reached. Phase 1C is complete, Phase 1D verified and Phase 1E partial/unverified; its 35- and 47-assertion SQL suites and backup/restore verifier remain pending. Hosted Supabase is not provisioned. Any later isolated cloud test project, branded staging, paid use, real learner data, external processing/email, DNS change, production configuration/deployment or PR merge remains separately gated.
**Version:** 1.5-draft
**Last reviewed:** 8 November 2026
**Status:** Conditional public Preview upload for a newly added, substantial learner/staff-visible feature only. Routine/no-change previews are not Founder tasks. The governing standard is docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md.

## Purpose

A public Cloudflare Worker Preview is created for Founder inspection only when a concrete, substantial learner/staff-visible feature is ready. It is not required for docs-only, internal security/database/API work, refactors, tests, ordinary fixes or maintenance. Routine automatic build/deployment events remain engineering evidence and should not be repeatedly raised with the Founder.

## Current workflow behavior

- Founder-review gate: the PR body contains `<!-- founder-preview-required -->`; this marker is added internally only for a substantial new visible feature.
- Trust restriction: this repository's owner-authored PRs only; fork PRs and untrusted PR authors do not receive the Cloudflare preview secret.
- Build: exact PR head SHA; Node 22; npm install --no-audit --no-fund; npm run build.
- Preview: only after the Founder-review marker is present and CI passes, run npx wrangler preview --name pr-<PR number> --json with existing restricted secrets. Never call npx wrangler deploy.
- PR handoff: post/update a bot comment only for that qualifying feature review; never repeat an unchanged Preview request.
- Cleanup: when the PR closes, run npx wrangler preview delete --name pr-<PR number>.
- No DNS/zone permissions are required. No Custom Domain is created. Production deployment configuration remains unchanged.

Keep immutable Preview URLs in the engineering record for exact revision tracing. Do not repeatedly send the current alias or ask the Founder to re-check a redeployed/minor-corrected version of the same feature.

## How the Founder verifies

1. When a new substantial feature is ready for review, open the draft PR and find the bot comment labelled **Public Cloudflare Preview ready**.
2. Open the Preview URL in a new browser tab.
3. Follow the PR's **Public verification handoff**: open the exact routes and perform the listed actions.
4. Check the page appearance, layout, navigation, direct links, Back/Forward behavior, relevant buttons/forms and desktop/mobile widths where relevant.
5. Report any mismatch in the PR conversation. Minor corrections are handled in CI; do not expect repeated Founder review requests for the same feature.
6. Do not treat a passing build or automated browser test as Founder visual/functional verification.

The PR must state what backend is connected. During Phase 1B the Supabase Auth/DB/Storage stack is local and CI-only; the public Preview cannot connect to the developer's local Supabase instance. Publicly verify the app shell, Worker API route wiring, UI and safe failure states only. Real hosted sign-in/RLS end-to-end on a public Preview requires a separate, isolated hosted Supabase project populated with synthetic data and explicit provisioning approval. Use a suitable Free tier by default; any paid plan or usage requires a documented unavoidable need, a current cost breakdown and separate explicit Founder approval. See `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.

## Public preview safety

Cloudflare workers.dev Preview URLs are public by default. They include a no-index response signal, but this is not access control. Never enter or display real learner information, private teacher materials, secrets, tokens, real PDFs, real handwriting or customer data. Do not attach production resources. Use Cloudflare Access for confidential review previews. Keep synthetic test records obviously fictional.

## When a qualifying feature Preview does not appear

- First confirm the Build check passed.
- Open the Controlled Cloudflare Worker preview Actions run for the PR.
- Check whether CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID were available.
- If missing, the owner must configure restricted repository Actions secrets; never share the token in chat or commit it.
- If permission fails, correct only the preview token's Workers preview-upload permissions; do not add DNS/zone or production deployment permissions as a workaround.
- Until deployment succeeds, mark public verification as pending.

## Custom domain

Do not connect the custom domain to each PR Preview. Keep per-PR verification on workers.dev. The roadmap now includes a separately approved branded staging-host check before final Diagnostic/Evaluation Report acceptance; this must use a confirmed staging subdomain, isolated staging Worker/backend, synthetic data and explicit DNS/hosted-resource approval. Do not attach an unfinished build to the production apex/canonical host as a shortcut. Production Custom Domain attachment remains a later Launch Candidate / Production Cutover gate after all release checks and separate DNS/production approval. Because the Worker is the application origin, Cloudflare Workers Custom Domain is the intended method; do not create a generic Worker Route without a separately reviewed reason. See docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md Section 9.

## Historical verification

The earlier controlled-preview implementation was exercised by PR #15 and PR #17. PR #15's documented run #20 and Build run #251 passed at that checkpoint; PR #15's preview URL was https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev. Those records prove that this workflow pattern previously succeeded, not that a current PR Preview is active today. The current PR's CI and preview result must be checked independently.


## Historical CI and Preview status — 7 November 2026 (superseded by Current Workers Builds integration and cost-control note)

The current local verification job still targets `ubuntu-latest`. Exact-head run [#42208654326](https://github.com/gradioprep/gradioprep-website/actions/runs/42208654326), attempt 4, failed before runner assignment; no build, SQL or browser step ran. WSL2 Ubuntu is installed, but Docker Desktop integration, Linux checkout and repository-scoped runner are pending. Do not expose Cloudflare Preview/deployment credentials to persistent self-hosted test execution; any future secret-bearing Preview step must remain isolated and separately permissioned. This documentation-only update does not request or create a Founder Preview.

## Current Workers Builds integration and cost-control note — 8 November 2026

Cloudflare's GitHub integration is already connected to the private `gradioprep/gradioprep-website` repository. Read-only inspection confirmed:
- Worker `gradioprep-website`, production branch `main`;
- automatic production builds and branch Previews enabled;
- production build/deploy commands `npm run build` and `npx wrangler deploy`;
- Preview build/deploy commands `npm run build` and `npx wrangler preview`;
- watch paths include all files and have no exclusions.

The account build-limit check reported that the limit had not been reached on 8 November 2026; the build-list query returned no records, so this is not proof of a recent successful build. Current Cloudflare documentation lists 3,000 free Workers Builds minutes/month, one concurrent build and a 20-minute timeout.

The current GitHub workflow also contains a marker-gated `wrangler preview` upload/comment path. Cloudflare Workers Builds may independently create branch Preview builds and PR comments. Before removing either Preview mechanism, verify the built-in branch Preview behavior and reconcile cleanup to avoid duplicate or orphaned Previews. The selected target is one clear Cloudflare deployment/Preview publisher, with GitHub Actions used for synthetic security/database/browser checks. No Preview credentials or persistent secrets should be exposed to a self-hosted runner.

The next reviewed cost-control changes are: (1) exclude documentation-only paths from both Cloudflare production and Preview watch paths; (2) add docs-only path exclusions and remove PR `edited` from the heavy GitHub verification triggers; (3) review `build.yml` for duplicate build/browser runs. Keep relevant source, Worker, migrations, SQL/browser tests, dependencies, workflows and configuration covered.

The repository remains private. Do not run Supabase on the user's Windows/WSL PC or register a local self-hosted runner. The disposable Supabase job runs on GitHub's hosted machine. All five GitHub spending budgets remain blocked; GitHub Actions run #42466738041 failed without steps/logs and does not prove minute exhaustion. Workers Builds check 128687968955 passed on the documentation head. No build settings, deployment commands, Worker config, DNS, custom domain, production resource or Preview were changed/created by this documentation update.
