# Controlled Cloudflare Worker Preview

> **Current execution checkpoint — 7 November 2026 (authoritative active status; older dated milestone records remain historical):** PR #22 is open, draft and unmerged on `feature/phase-1b-local-auth-api`; pre-reconciliation head `2cf7304b8d2ae6b3c8363dd68e97d608682bd0bb`. **Phase 1C is complete** at code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`; exact-head Actions [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests. **Phase 1D is verified** at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`; exact-head Actions [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) passed 519 pgTAP assertions across 15 SQL files, builds, 31/31 Playwright tests and cleanup. **Phase 1E backup/recovery/deletion is partial and unverified:** migrations `20261106000200_phase1e_account_deletion_ledger.sql` and `20261106000300_phase1e_account_closure_retention_plan.sql` exist; paired tests `account_deletion_ledger.test.sql` (`plan(35)`) and `account_closure_retention.test.sql` (`plan(47)`) have not run. Exact-head Actions [#42208654326](https://github.com/gradioprep/gradioprep-website/actions/runs/42208654326), attempt 4, failed before runner assignment: job `127868964485` has runner ID 0, no runner name and no steps; **no SQL tests executed**. This is not a SQL pass or failure. Windows WSL2 Ubuntu is installed; Linux user is `gradioprep`. Docker Desktop/WSL integration, Linux-side checkout and repository-scoped self-hosted runner remain pending. The current workflow still targets `ubuntu-latest` until a separate reviewed change. **All five GitHub spending budgets remain blocked.** Statements below dated before this checkpoint are historical evidence; their former active/next-step status is superseded here.
**Version:** 1.4-draft  
**Last reviewed:** 4 November 2026  
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


## Current CI and Preview status — 7 November 2026

The current local verification job still targets `ubuntu-latest`. Exact-head run [#42208654326](https://github.com/gradioprep/gradioprep-website/actions/runs/42208654326), attempt 4, failed before runner assignment; no build, SQL or browser step ran. WSL2 Ubuntu is installed, but Docker Desktop integration, Linux checkout and repository-scoped runner are pending. Do not expose Cloudflare Preview/deployment credentials to persistent self-hosted test execution; any future secret-bearing Preview step must remain isolated and separately permissioned. This documentation-only update does not request or create a Founder Preview.