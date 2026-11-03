# Controlled Cloudflare Worker Preview

**Version:** 1.2-draft  
**Last reviewed:** 3 November 2026  
**Status:** Mandatory public verification workflow. The source workflow is .github/workflows/controlled-worker-preview.yml; the governing standard is docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md.

## Purpose

Every meaningful implementation PR should produce a publicly viewable, isolated Cloudflare Worker Preview as soon as its local/CI checks pass. This supports short GitHub implementation → automated test → public website verification → correction cycles. It is not production deployment and is not official release.

## Current workflow behavior

- Trigger: same-repository PRs opened, updated or reopened, targeting main or the active stacked integration branch feature/pdf-submission-grading-timers-plan.
- Trust restriction: this repository's owner-authored PRs only; fork PRs and untrusted PR authors do not receive the Cloudflare preview secret.
- Build: exact PR head SHA; Node 22; npm install --no-audit --no-fund; npm run build.
- Preview: if the existing repository secrets CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID are configured, run npx wrangler preview --name pr-<PR number> --json. This uses the existing Worker and its Preview capability; it does not call npx wrangler deploy.
- PR handoff: post/update a bot comment with the Preview URL and synthetic-data warning.
- Cleanup: when the PR closes, run npx wrangler preview delete --name pr-<PR number>.
- No DNS/zone permissions are required. No Custom Domain is created. Production deployment configuration remains unchanged.

A current Preview alias always serves the latest uploaded revision for that PR. Preserve the immutable per-deployment URL when recording which exact commit the Founder verified.

## How the Founder verifies

1. Open the draft PR and find the bot comment labelled **Public Cloudflare Preview ready**.
2. Open the Preview URL in a new browser tab.
3. Follow the PR's **Public verification handoff**: open the exact routes and perform the listed actions.
4. Check the page appearance, layout, navigation, direct links, Back/Forward behavior, relevant buttons/forms and desktop/mobile widths where relevant.
5. Report any mismatch in the PR conversation. The preview is updated automatically after the next PR commit.
6. Do not treat a passing build or automated browser test as Founder visual/functional verification.

The PR must state what backend is connected. During Phase 1B the Supabase Auth/DB/Storage stack is local and CI-only; the public Preview cannot connect to the developer's local Supabase instance. Publicly verify the app shell, Worker API route wiring, UI and safe failure states only. Real hosted sign-in/RLS end-to-end on a public Preview requires a separate, isolated hosted Supabase project populated with synthetic data and explicit provisioning approval. Use a suitable Free tier by default; any paid plan or usage requires a documented unavoidable need, a current cost breakdown and separate explicit Founder approval. See `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.

## Public preview safety

Cloudflare workers.dev Preview URLs are public by default. They include a no-index response signal, but this is not access control. Never enter or display real learner information, private teacher materials, secrets, tokens, real PDFs, real handwriting or customer data. Do not attach production resources. Use Cloudflare Access for confidential review previews. Keep synthetic test records obviously fictional.

## When preview does not appear

- First confirm the Build check passed.
- Open the Controlled Cloudflare Worker preview Actions run for the PR.
- Check whether CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID were available.
- If missing, the owner must configure restricted repository Actions secrets; never share the token in chat or commit it.
- If permission fails, correct only the preview token's Workers preview-upload permissions; do not add DNS/zone or production deployment permissions as a workaround.
- Until deployment succeeds, mark public verification as pending.

## Custom domain

Do not connect the custom domain to each PR Preview. Keep per-PR verification on workers.dev. Connect the exact Founder-confirmed custom domain only at Launch Candidate / Production Cutover after all launch gates and separate DNS/production approval. See docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md. Because the Worker is the application origin, Cloudflare Workers Custom Domain is the intended production method; do not create a generic Worker Route without a separately reviewed reason.

## Historical verification

The earlier controlled-preview implementation was exercised by PR #15 and PR #17. PR #15's documented run #20 and Build run #251 passed at that checkpoint; PR #15's preview URL was https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev. Those records prove that this workflow pattern previously succeeded, not that a current PR Preview is active today. The current PR's CI and preview result must be checked independently.
