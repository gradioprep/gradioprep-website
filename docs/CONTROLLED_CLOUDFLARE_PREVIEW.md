# Controlled Cloudflare Worker Preview

**Version:** 1.2-draft  
**Last reviewed:** 2 November 2026  
**Status:** Mandatory public verification workflow. The governing standard is `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`.

## Purpose

Every meaningful implementation PR should produce a publicly viewable, isolated Cloudflare Worker Preview after its required automated checks pass. The Founder uses that Preview to inspect the actual website, not source code. This is not production deployment or official release.

## Phase 1B workflow — tests first, Preview second

The canonical Phase 1B workflow is `.github/workflows/phase1b-verification.yml`, triggered by same-repository PRs targeting `docs/phase-1-secure-foundation-spec`. It runs in this order:

1. Installs dependencies.
2. Starts the local Supabase Auth/PostgreSQL/Storage stack with synthetic data only.
3. Writes ignored local-only environment files containing only the local API URL and publishable key.
4. Resets the local database, applies migrations and loads fictional seed accounts.
5. Runs PostgreSQL pgTAP/RLS tests.
6. Type-checks/builds the browser and Worker.
7. Runs existing navigation plus account/API Playwright tests.
8. Stops local Supabase.
9. Deletes `.dev.vars` and `.env.local`, rebuilds clean public-preview assets with no local Supabase values.
10. Only after all previous steps pass, deploys the PR-specific Cloudflare Worker Preview and posts/updates its URL on the PR.

If the SQL/RLS, TypeScript, build or browser tests fail, this workflow does not update the public Preview for that commit. This protects the Founder from checking a revision that has not passed its full automated gate.

The standard `.github/workflows/build.yml` remains responsible for the general website build/regression checks. The separate `.github/workflows/controlled-worker-preview.yml` is cleanup-only: it deletes the named Preview when the PR closes.

## How the Founder verifies

1. Open the draft PR and find the bot comment labelled **Public Cloudflare Preview ready**.
2. Open the Preview URL in a new browser tab.
3. Follow the PR's **Public verification handoff**: open the exact routes and perform the listed actions.
4. Check the page appearance, layout, navigation, direct links, Back/Forward behavior, relevant buttons/forms and desktop/mobile widths where relevant.
5. Report any mismatch in the PR conversation. The Preview is refreshed after the next PR commit passes all required checks.
6. Do not treat a passing build or automated browser test as Founder visual/functional verification.

Every PR must state what backend is connected. During Phase 1B, the Supabase Auth/DB/Storage stack is local and CI-only. The public Preview cannot reach it. The Preview verifies the actual UI, Worker routes and safe states only; synthetic sign-in, session, API and RLS behavior are checked locally by CI. A hosted synthetic backend requires separate explicit provisioning/cost approval.

## Public-preview safety

Cloudflare `workers.dev` Preview URLs are public by default. They include a no-index response signal, but this is not access control. Never enter or display real learner information, private teacher materials, secrets, tokens, real PDFs, real handwriting or customer data. Do not attach production resources. Use Cloudflare Access for confidential review previews. Keep synthetic test records obviously fictional.

The Phase 1B pipeline deletes local environment files and rebuilds the public bundle before deployment. Never copy local Supabase URLs, local keys, passwords or service credentials into the public Preview.

## When preview does not appear

- First inspect the **Phase 1B local security and public Preview** or **Build check** Actions result relevant to that PR.
- For Phase 1B, confirm the local Supabase/RLS, Worker/browser build and Playwright steps all passed before expecting a Preview.
- Check whether `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` were available.
- If missing, the owner must configure restricted repository Actions secrets; never share the token in chat or commit it.
- If permission fails, correct only the preview token's Workers preview-upload permissions; do not add DNS/zone or production deployment permissions as a workaround.
- Until deployment succeeds, mark public verification as pending.

## Custom domain

Do not connect the custom domain to each PR Preview. Keep per-PR verification on `workers.dev`. Connect the exact Founder-confirmed custom domain only at Launch Candidate / Production Cutover after all launch gates and separate DNS/production approval. See `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`. Because the Worker is the application origin, Cloudflare Workers Custom Domain is the intended production method; do not create a generic Worker Route without a separately reviewed reason.

## Historical verification

- PR #21's earlier public Preview successfully deployed at `https://pr-21-gradioprep-website.wandering-scene-1822.workers.dev`; its build/navigation checks passed.
- PR #22's current draft Preview is `https://pr-22-gradioprep-website.wandering-scene-1822.workers.dev`. The link is public unless Cloudflare Access is enabled. It is an unreleased synthetic-data-only Preview, not production. A Preview URL being deployed is not proof that the Founder has visually accepted that revision.
- The Phase 1B automated workflow was subsequently refined so local RLS/build/browser tests complete before the Preview deployment step. Check the current run for the exact PR head commit before recording an acceptance result.
