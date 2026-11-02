# Public Preview, Verification and Custom-Domain Release Process

**Version:** 1.0-draft  
**Date:** 2 November 2026  
**Status:** Founder-requested mandatory engineering/build-process standard. Apply to every implementation milestone and relevant pull request.  
**Authority:** `docs/PROJECT_MASTER_BRIEF.md`  
**Related:** `docs/PHASE_1_SECURE_APPLICATION_FOUNDATION_IMPLEMENTATION_SPEC.md`, `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`, `docs/CONTROLLED_CLOUDFLARE_PREVIEW.md`, `docs/DESIGN_SPEC.md` and the approved Phase 0 decision register.

## 1. Founder-approved working model

GradiPrep will use a disciplined **GitHub implementation → automated verification → public Cloudflare Preview → Founder visual/functional verification → correction → refreshed Preview** loop.

This is a core feature of the build process, not an optional final QA activity. Do not defer public verification until an entire phase or feature is complete when a useful, safe vertical slice can be previewed earlier.

The Founder is not expected to inspect source code. Each implementation PR must therefore provide a human-readable view of the actual running website, a clear summary of what changed, what to check, what has passed, what remains incomplete, and the next approval required.

### Mandatory cycle

1. **Agree the small implementation slice.** State the learner/staff-visible change and acceptance criteria before coding.
2. **Implement on a dedicated GitHub branch.** Keep changes focused; do not make unrelated redesigns or architecture changes.
3. **Run automated checks first.** TypeScript/build, relevant unit/API/database/RLS tests, existing Playwright regression tests and security checks must pass before public preview deployment.
4. **Deploy the branch to its Cloudflare Worker Preview.** Use `npx wrangler preview`, never `npx wrangler deploy` for PR verification. Each PR receives its own `pr-<number>` Preview and an immutable deployment URL for the exact revision.
5. **Post the Preview URL on the PR automatically.** If credentials or deployment are unavailable, explicitly record why; never imply that public verification happened.
6. **Founder verifies the actual page.** Open the Preview URL and test the relevant page/flow. Verify the visual design, navigation, direct URLs, responsive layout and relevant interactions—not only screenshots or CI.
7. **Correct and re-preview promptly.** Address findings in the same PR, rerun checks, update the same Preview alias and preserve the immutable URL/checkpoint for comparison.
8. **Record acceptance.** Update the PR and source-of-truth status with CI results, preview URL/revision, Founder verification outcome, known gaps and next gate.

A completed milestone is not considered publicly verified until the Founder has inspected the deployed Preview and the result is recorded. Automated tests and public visual review are complementary, not interchangeable.

## 2. When public preview is expected

| Work type | Required public verification |
|---|---|
| Layout, design, navigation, copy, static page or responsive UI | Preview every coherent UI slice before closing its implementation PR |
| Authentication screens/session states | Preview the UI; real sign-in and token/session behavior are verified against local Supabase in CI first |
| Protected API or database behavior | Test Auth/API/RLS with local synthetic Supabase in CI; deploy the public Worker Preview to verify the public app shell, routing and safe failure states |
| A feature requiring real hosted Auth or database connectivity | Use a dedicated hosted synthetic-only test project only after separate explicit provisioning approval; then include end-to-end Preview verification |
| PDF upload, OCR, AI, grading or analytics | Verify UI and simulated/synthetic flows early; live external service integration remains separately gated by region, privacy, legal, quality and cost approval |
| Documentation-only change | Build checks as appropriate; public preview only if the PR also changes rendered website content or behavior |

Do not wait for an entire multi-week phase if a working slice can be safely tested. Prefer short vertical slices that result in a useful public Preview.

## 3. Cloudflare Worker Preview operation

The workflow is split by responsibility so public Preview deployment cannot race ahead of database/security tests:

- **Phase 1B PRs targeting `docs/phase-1-secure-foundation-spec`:** `.github/workflows/phase1b-verification.yml` runs the complete local synthetic pipeline in one job: Supabase local stack, environment setup, schema/seed reset, pgTAP RLS tests, browser and Worker type/build checks, Playwright navigation/account/API tests, and local-stack shutdown. It removes `.dev.vars` and `.env.local`, rebuilds a clean public asset bundle with no local Supabase values, and only then runs `npx wrangler preview --name pr-<number>`. The PR receives the Preview URL after all tests pass.
- **General website PRs:** `.github/workflows/build.yml` continues to run the standard TypeScript/Vite and Playwright regression checks.
- **Preview cleanup:** `.github/workflows/controlled-worker-preview.yml` is cleanup-only. It deletes a PR's named Preview when that PR closes.

The Phase 1B workflow is restricted to same-repository pull requests created by the repository owner account `gradioprep`. It uses the existing repository Actions secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, if configured, with an account-restricted Workers preview token. It does not use `npx wrangler deploy`.

The workflows must not modify DNS, create a Custom Domain, change production settings, create new Cloudflare accounts/products or configure any live database. No production permission or DNS/zone permission should be included in the preview token. The separate production deployment workflow remains unchanged and must never be called by preview automation.

If any local Supabase, SQL/RLS, build or browser test fails, the Phase 1B job stops and does not upload/update a public Preview for that revision. If tests pass but Preview credentials/deployment are unavailable, record the reason and keep public verification pending; never imply Preview deployment succeeded.

### 3.1 Public-preview safety

Cloudflare Worker Preview URLs are public unless Cloudflare Access is separately enabled. The `workers.dev` Preview response includes a no-index signal, but no-index is not access control and does not make confidential content safe.

Therefore:
- Use fictional/synthetic users, responses, PDFs and records only.
- Never add learner names, contact details, school data, real responses, handwriting, access tokens, passwords, API keys, recovery codes or private teacher/QA material.
- Do not connect a public Preview to production Auth, production databases, production buckets or real processor credentials.
- Use least-privilege preview credentials and do not expose secrets to browser bundles or PR comments.
- Keep unreleased curriculum clearly marked and do not link test routes into normal learner navigation.
- Restrict Preview access with Cloudflare Access when the preview includes confidential internal review or material that must not be publicly reachable.

### 3.2 Important distinction for Phase 1B

The approved first coding slice uses **local Supabase only**. Its Auth, PostgreSQL, Storage and RLS integration must run locally and in CI against synthetic identities. A public Cloudflare Preview can verify the actual deployed app shell, UI, Worker routing and non-sensitive states, but it cannot reach the developer's private local Supabase instance.

Do not fake or claim end-to-end hosted Auth/RLS verification on the public Preview. For any later public Preview that needs a working hosted login or database, first obtain separate approval to provision an isolated hosted Supabase project with synthetic data and separately restricted preview credentials. No hosted project is authorised by this document.

This separation is intentional: it allows frequent public website verification without prematurely provisioning services or exposing learner data.

## 4. Founder-facing verification handoff

Every implementation PR must include a concise **Public verification handoff** with:

1. **What changed on the website:** visible, plain-language description.
2. **Where to verify:** clickable Preview URL and exact route(s) to open.
3. **What to test:** no more than five focused checks, written as user actions.
4. **Automated checks:** build, test names and exact pass/fail totals.
5. **What is not yet connected:** local-only backend, mock state or deferred integration, stated honestly.
6. **Known issues:** anything Founder should expect to see.
7. **Decision required:** explicit next approval, or confirmation that no approval is needed yet.

For major flows, provide a short click-by-click verification sequence suitable for a non-coder. Keep the wording concise and avoid asking the Founder to read code or infer what has changed.

The PR should be refreshed and its Preview URL updated after each correction. Use immutable deployment URLs when recording which exact revision the Founder reviewed. Do not mark a verification outcome from a Preview that has since been superseded without identifying the older revision.

## 5. Public website verification is not production release

A Cloudflare Worker Preview is the standard public verification environment. It is not the official live website and does not require connecting the custom domain.

Keep three destinations distinct:
- **Local development:** local React/Worker and local Supabase synthetic stack.
- **Public branch Preview:** temporary PR-specific `workers.dev` URL; current code, synthetic data only, no-index, not production.
- **Official live website:** production Worker on the confirmed custom domain after separate launch approval and DNS/domain configuration.

Never call the Preview URL the official production site. Never promote a Preview to production automatically when its PR is reviewed, closed or merged.

## 6. Custom-domain connection stage

The custom domain should be connected at the **Launch Candidate / Production Cutover checkpoint**, after the required public Preview iterations and the complete launch-readiness gates have passed. The website should be developed and publicly verified through PR Previews throughout Phase 1 and subsequent feature phases; it is not necessary to attach the custom domain to every development build.

### 6.1 Before connecting the domain

Confirm and record:
- the exact registered domain and the desired canonical host (apex, `www`, or another chosen host);
- who controls the registrar account and whether the domain's active DNS zone is already on Cloudflare;
- the intended production Worker and the final production environment variables/secrets;
- a tested fallback/rollback route and current production deployment state;
- final HTTPS, security headers, redirects, canonical URLs, robots/indexing rules, SPA deep links and error pages;
- authentication redirect allow-list and email confirmation/password-recovery callbacks;
- backup/restore, retention/deletion, monitoring, privacy/legal, accessibility, security and content/release approvals.

The exact domain name is not fixed by this process. Do not guess between previously discussed spellings or add records until the Founder confirms the purchased domain and canonical host.

### 6.2 Connect to the production Worker

Because the Cloudflare Worker is the application origin, use a **Workers Custom Domain** rather than a generic Worker Route. Cloudflare's Custom Domain flow creates the required DNS records and issues the certificates; the domain must belong to an active Cloudflare zone. If the registrar is elsewhere, confirm the zone and nameserver arrangement first. Do not change nameservers or DNS without explicit Founder approval.

The final sequence is:
1. Founder confirms exact domain, canonical host and DNS/registrar control.
2. Verify that the domain's zone is active in the intended Cloudflare account.
3. Prepare the production Worker configuration and verify the exact production build in a stable Preview.
4. Configure the Supabase Auth Site URL to the canonical HTTPS site and add only the exact permitted production callback URLs. Retain only the required localhost and controlled Preview callbacks; use the narrowest possible preview pattern. Do not use broad wildcard production redirects.
5. With separate Founder cutover approval, attach the confirmed Custom Domain to the production Worker in Cloudflare **Workers & Pages → Worker → Settings → Domains & Routes → Add → Custom Domain**, or the equivalent reviewed Wrangler configuration.
6. Confirm DNS, TLS certificate issuance, HTTPS canonical redirects and SPA/API routes. Test sign-in, sign-out, email confirmation, password recovery and callback URLs against the production host using synthetic test accounts before opening real registration.
7. Run the production smoke test and Founder acceptance. Keep rollback instructions and the previous known-good Worker version available.

Custom Domain creation, DNS/nameserver changes, production deployment, Auth production redirect changes and public launch each require their relevant explicit approval. This document does not authorise them.

### 6.3 Optional branded staging subdomain

If a persistent branded verification address is genuinely useful before launch, a separate subdomain such as `staging.<confirmed-domain>` may be evaluated after the custom domain is confirmed. It requires its own Worker Preview/domain mapping, DNS/certificate review, strict synthetic-data isolation and separate Founder DNS approval. It is optional; the per-PR `workers.dev` Preview is the default because it is automatic, isolated and avoids unnecessary DNS work.

## 7. Release sequence and approval gates

| Stage | Work | Approval / verification |
|---|---|---|
| Every implementation PR | Build, tests, public branch Preview, Founder visual/functional verification | Founder verifies the actual Preview before milestone acceptance |
| Phase 1B–1F | Local synthetic Auth/RLS/API/storage/audit/backup/restore/security foundation | Separate approvals for each implementation checkpoint; no public hosted learner data |
| Later hosted synthetic integration | Isolated hosted Supabase + Preview end-to-end auth/API | Separate provisioning and cost approval; synthetic data only |
| Flagship phases 2–5 | PDF, extraction/OCR, grader workflow, feedback, timer/analytics | Public preview each coherent slice; external services only after separate approvals |
| Controlled pilot / diagnostic cycle | Full MYP Year 4 synthetic journey then separately authorised limited live pilot | Founder/privacy/security/academic/accessibility/cost approvals |
| Launch Candidate / Production Cutover | Connect confirmed custom domain; final production smoke test | Separate explicit production/domain/DNS approval |
| Official launch | Open the approved public site and learner access | Founder release approval |

MYP Year 4 actual diagnostic item authoring remains gated until the flagship feature is implemented and pilot-validated. Cambridge Grade 6 remains blocked until Cycle 1 is complete and the Founder directs transition.

## 8. Official technical references checked 2 November 2026

- Cloudflare Workers Previews and branch-specific URLs: https://developers.cloudflare.com/workers/previews/
- Cloudflare Worker Preview setup: https://developers.cloudflare.com/workers/previews/get-started/
- Cloudflare Preview URL no-index and public access behavior: https://developers.cloudflare.com/workers/versions-and-deployments/preview-urls/
- Cloudflare Workers Custom Domains: https://developers.cloudflare.com/workers/configuration/routing/custom-domains/
- Cloudflare Workers Routes versus Custom Domains: https://developers.cloudflare.com/workers/configuration/routing/routes/
- Supabase Auth redirect URLs and exact production Site URL: https://supabase.com/docs/guides/auth/redirect-urls
- Controlled preview workflow in this repository: `.github/workflows/controlled-worker-preview.yml`
