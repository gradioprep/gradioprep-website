# Controlled Cloudflare Worker Preview

> **Current execution checkpoint — 9 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`; the repository is public. Exact application-code/test head `5df10f70c23a35bdf1759fcec8b12a36fca1a9c9` passed GitHub Actions [#42579642253](https://github.com/gradioprep/gradioprep-website/actions/runs/42579642253): all 19 PostgreSQL/RLS SQL test files, 33/33 Playwright tests, TypeScript/Worker/Vite builds and synthetic database/private-PDF backup/restore, cleanup and clean credential-free asset build. The separate `Workers Builds: gradioprep-website` check succeeded for the branch Preview build. The workflow run was branch-push triggered, so conditional PR Preview upload/comment steps were skipped and no PR Preview URL is claimed. No production deployment occurred. Use standard GitHub-hosted `ubuntu-latest`; do not start local Supabase/Docker or register a self-hosted runner. Hosted Supabase/R2, paid overage, real learner data, external processing, DNS/custom-domain changes, production deployment and PR merge remain separately gated.
**Version:** 1.8-draft
**Last reviewed:** 9 November 2026
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

The GitHub Actions portion is complete in workflow commit `dc13c80`: one owner-only push trigger on PR #22's dedicated branch, docs/Markdown exclusions and stale-run cancellation, with no parallel `pull_request` trigger. Relevant application, Worker, migration, SQL, browser, dependency, workflow and configuration changes remain covered on standard `ubuntu-latest`. The separate `build.yml` also filters docs/Markdown and cancels superseded runs. Full run [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308) passed Phase 1E synthetic acceptance: 601 SQL assertions/17 files, 31/31 Playwright, builds, DB/private-PDF backup/restore, cleanup and credential-free build. The remaining cost-control setting is Cloudflare Workers Builds: add documentation-only exclusions to production and Preview watch paths only after inspecting current account settings; do not change deployment commands, production branch, DNS, domains, bindings or secrets.

GitHub confirms the repository is public. Do not commit credentials, real learner data or confidential teacher material. Do not run Supabase on the user's Windows/WSL PC or register a local self-hosted runner. The disposable synthetic Supabase job runs on standard GitHub-hosted `ubuntu-latest`. All five spending budgets were last recorded as blocked. Workers Builds check 128687968955 passed on older commit `37e279d`; it is not a check for the current workflow head. Cloudflare settings, deployment commands, Worker configuration, DNS, custom domain, production resources and Preview state were not changed by the GitHub workflow or test-fix commits.
