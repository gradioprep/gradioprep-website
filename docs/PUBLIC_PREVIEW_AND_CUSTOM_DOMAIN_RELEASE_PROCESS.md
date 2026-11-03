# Public Preview, Verification and Custom-Domain Release Process

**Version:** 1.2-draft
**Date:** 3 November 2026  
**Status:** Founder-requested mandatory engineering/build-process standard. Apply to every implementation milestone and relevant pull request. PR #22's latest exact-head CI and Cloudflare Preview status are recorded in Section 3.3; Founder visual review remains pending.  
**Authority:** `docs/PROJECT_MASTER_BRIEF.md`; free-first cost decisions: `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`
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

The canonical automation is `.github/workflows/controlled-worker-preview.yml`. It:
- runs on same-repository pull requests targeting `main` or the active stacked integration base `feature/pdf-submission-grading-timers-plan`;
- is restricted to pull requests created by the repository owner account `gradioprep`;
- builds the exact PR head revision;
- uses the existing repository Actions secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, if configured;
- uses an account-restricted Workers preview token and calls only `npx wrangler preview --name pr-<number>`;
- posts or updates a clearly labelled Preview URL comment on the PR;
- removes that PR's Preview when the PR is closed.

The workflow must not use `npx wrangler deploy`, modify DNS, create a Custom Domain, change production settings, create new Cloudflare accounts/products or configure any live database. No production permission or DNS/zone permission should be included in the preview token. The separate production deployment workflow remains unchanged and must never be called by preview automation.

If the PR build passes but Preview deployment does not, record the missing credential, permission or provider failure in the PR/check summary. Continue local tests, but mark public verification as pending and repair the preview path promptly. Do not silently skip the Preview gate.

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

### 3.3 Verified Phase 1B PR #22 checkpoint — 3 November 2026

**Verified Phase 1B checkpoint — 3 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, ; the last application-code revision verified in the recorded CI run is `ad82f0875737e337ea52b2918a04d0d17cd14f36` (the later free-first policy changes are documentation-only). The suspended synthetic-user fixture/authentication setup is corrected without weakening RLS or bypassing tests. Application-code verification run [#41500536318] on commit `ad82f0875737e337ea52b2918a04d0d17cd14f36`(https://github.com/gradioprep/gradioprep-website/actions/runs/41500536318) passed the fresh local Supabase reset and synthetic seed, PostgreSQL RLS tests, application/Worker builds, all 16/16 Playwright browser tests, local-stack shutdown, removal of local-only environment files, and the clean public-Preview build. The browser flow verifies successful Auth sign-in, protected `/api/v1/me` denial with `403 account_unavailable`, denied profile update, and sign-out for the suspended application account. No hosted Supabase, real learner data or production service was used. CI now caches npm package downloads and Playwright Chromium binaries; this successful run exercised the cold-cache path. A warm-cache run is still required to confirm cache hits and measure any time saving; the database is deliberately reset and reseeded on every run and is never cached. Cloudflare's linked Workers Builds integration deployed the exact tested revision; the Phase 1B Actions workflow's explicit Preview steps were skipped because this was a branch-push event, not a pull-request event. Stable branch Preview: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. Immutable deployment for this exact commit: https://4275c88c-gradioprep-website.wandering-scene-1822.workers.dev. The Preview is public, synthetic-only and disconnected from hosted Supabase; do not enter credentials or real learner data. Founder visual review remains pending. No merge, production deployment, DNS/Cloudflare production change, hosted provisioning or paid service is authorised.


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
| Phase 1B–1F | In-scope implementation of the approved secure foundation, with local synthetic services first and public Preview verification | Proceed through the approved sequence with draft PR/CI evidence; hosted provisioning, paid spend, real data, merge and production release remain separate gates |
| Later hosted synthetic integration | Isolated hosted Supabase + Preview end-to-end auth/API using the Free tier where suitable | Separate hosted-resource provisioning approval; any paid plan or usage requires a documented unavoidable need and explicit cost approval; synthetic data only |
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
