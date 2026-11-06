# Public Preview, Verification and Custom-Domain Release Process

**Version:** 1.7-draft
**Date:** 6 November 2026  
**Status:** Product name is GradioPrep and the confirmed custom domain is `gradioprep.com`; the domain is not connected to the site and no DNS changes have been made. Cloudflare `workers.dev` branch Previews remain the normal development verification environment and are disconnected from hosted learner services. Founder-facing Preview requests are reserved for new, concrete and substantial learner/staff-visible features; routine, unchanged, backend-only and documentation-only changes do not trigger a Preview request. A branded custom-domain staging journey backed by an isolated hosted synthetic test environment is mandatory before final Diagnostic/Evaluation Report acceptance, after separate provisioning and DNS approvals. The canonical host (apex, `www` or staging subdomain) remains to be selected. Production custom-domain cutover remains a separate later gate. No hosted staging backend, branded host mapping, paid use, production deployment or DNS change is authorised by this document.
**Authority:** `docs/PROJECT_MASTER_BRIEF.md`; free-first cost decisions: `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`
**Related:** `docs/PHASE_1_SECURE_APPLICATION_FOUNDATION_IMPLEMENTATION_SPEC.md`, `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`, `docs/CONTROLLED_CLOUDFLARE_PREVIEW.md`, `docs/DESIGN_SPEC.md` and the approved Phase 0 decision register.

## 1. Founder-approved working model

GradiPrep uses GitHub implementation and automated verification continuously. A public Cloudflare Worker Preview is an occasional Founder-review aid, **not a required announcement or manual review for every PR, commit, fix or milestone**.

The Founder has directed that a Preview be brought to them only when a **new, concrete and substantial learner- or staff-visible feature** has been added and is ready for a useful visual/functional review. Do not repeatedly mention, resend or ask the Founder to inspect an unchanged, superseded or routine Preview. Do not ask for Preview review of documentation-only changes, internal security/database/RLS/API work without a visible workflow, refactors, tests/CI, maintenance or ordinary bug fixes. These changes still receive all appropriate automated/local checks and remain documented in GitHub; their build/deployment noise should not be promoted as a Founder task.

### Conditional Preview handoff

1. Implement the feature and complete its relevant automated checks first.
2. Decide whether the change adds a concrete, substantial learner/staff-visible capability. Internal-only changes do not qualify.
3. For a qualifying feature, add the hidden PR-body marker `<!-- founder-preview-required -->`. This is an internal engineering signal; the Founder does not need to edit labels or workflow settings.
4. The workflow may then deploy/update the PR's synthetic-data Worker Preview and provide one handoff.
5. Give the Founder a concise summary of the new capability, exact route(s), up to five focused user-action checks, the Preview URL for that feature revision, backend/data limitations and any decision required.
6. Do not request another review just because the same feature is redeployed or receives a minor correction. Ask again only for another substantial new visible feature.
7. Keep CI, code review, security and release gates in force regardless of whether a Preview is requested.

The Founder is not expected to inspect source code or review routine engineering deployments. A Preview is useful only when it exposes a meaningful new capability that can actually be checked.

## 2. When public preview is expected

| Work type | Founder Preview request |
|---|---|
| New, concrete and substantial learner/staff-visible feature or material new workflow | Yes, once the feature is implemented and relevant CI passes |
| New major page/route, learner interaction or staff workflow | Yes, when it adds a genuinely new capability, not for routine layout corrections |
| Documentation-only, internal security/RLS/database changes, backend/API work without new visible workflow | No |
| Refactoring, dependency/build/test/CI changes, ordinary bug fixes or maintenance | No |
| Redeployment or minor correction of a feature already reviewed | No; keep the deployment evidence in the PR without repeating the Founder request |
| Feature requiring hosted Auth/database connectivity | Separate hosted-resource approval still required; a Preview must never imply approval to provision |


## 3. Cloudflare Worker Preview operation

The Founder-review upload/comment gate is in `.github/workflows/phase1b-verification.yml` and runs only when the hidden PR-body marker `<!-- founder-preview-required -->` is present. The separate `.github/workflows/controlled-worker-preview.yml` cleanup remains responsible for deleting a PR preview on close. The automation:
- runs on same-repository pull requests targeting `main` or the active stacked integration base `feature/pdf-submission-grading-timers-plan`;
- is restricted to pull requests created by the repository owner account `gradioprep`;
- builds the exact PR head revision;
- uses the existing repository Actions secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, if configured;
- uses an account-restricted Workers preview token and calls only `npx wrangler preview --name pr-<number>`;
- posts or updates a clearly labelled Preview URL comment only for a qualifying feature-review request;
- removes that PR's Preview when the PR is closed.

The workflow must not use `npx wrangler deploy`, modify DNS, create a Custom Domain, change production settings, create new Cloudflare accounts/products or configure any live database. No production permission or DNS/zone permission should be included in the preview token. The separate production deployment workflow remains unchanged and must never be called by preview automation.

If a qualifying feature-review request is made and deployment fails, record the provider/permission failure and continue local tests. If no qualifying feature marker is present, no Preview failure or pending Founder review should be reported; this is an intentional skip, not a failed gate.

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

Only a qualifying new visible-feature PR needs a concise **Founder Preview handoff** with:

1. **What changed on the website:** visible, plain-language description.
2. **Where to verify:** clickable Preview URL and exact route(s) to open.
3. **What to test:** no more than five focused checks, written as user actions.
4. **Automated checks:** build, test names and exact pass/fail totals.
5. **What is not yet connected:** local-only backend, mock state or deferred integration, stated honestly.
6. **Known issues:** anything Founder should expect to see.
7. **Decision required:** explicit next approval, or confirmation that no approval is needed yet.

For major flows, provide a short click-by-click verification sequence suitable for a non-coder. Keep the wording concise and avoid asking the Founder to read code or infer what has changed.

For a qualifying feature review, update the engineering record with the exact immutable deployment URL and commit that were built and tested. A correction, redeployment or retest of the same feature updates engineering traceability only; it does not trigger a new Founder Preview request by itself. Ask for another review only when the correction materially changes the learner/staff-visible behaviour or adds another concrete, substantial capability. Do not repeatedly resend an unchanged or superseded Preview URL.

## 5. Public website verification is not production release

A Cloudflare Worker Preview is the standard public verification environment. It is not the official live website and does not require connecting the custom domain.

Keep three destinations distinct:
- **Local development:** local React/Worker and local Supabase synthetic stack.
- **Public branch Preview:** temporary PR-specific `workers.dev` URL; current code, synthetic data only, no-index, not production.
- **Official live website:** production Worker on the confirmed custom domain after separate launch approval and DNS/domain configuration.

Never call the Preview URL the official production site. Never promote a Preview to production automatically when its PR is reviewed, closed or merged.

## 6. Custom-domain connection stage

The **production** custom domain should be connected only at the Launch Candidate / Production Cutover checkpoint, after launch-readiness gates and separate explicit production approval. This production cutover is distinct from the mandatory branded **staging**-domain verification in Section 9, which must pass before final acceptance of the Diagnostic and Evaluation Report. Continue feature development through isolated per-PR `workers.dev` Previews; do not attach a domain to every development build.

### 6.1 Before connecting the domain

Confirm and record:
- the exact registered domain and the desired canonical host (apex, `www`, or another chosen host);
- who controls the registrar account and whether the domain's active DNS zone is already on Cloudflare;
- the intended production Worker and the final production environment variables/secrets;
- a tested fallback/rollback route and current production deployment state;
- final HTTPS, security headers, redirects, canonical URLs, robots/indexing rules, SPA deep links and error pages;
- authentication redirect allow-list and email confirmation/password-recovery callbacks;
- backup/restore, retention/deletion, monitoring, privacy/legal, accessibility, security and content/release approvals.

The confirmed custom domain is `gradioprep.com`. The canonical host (apex, `www` or staging subdomain) remains to be selected and recorded. The domain is not connected to the site; no DNS changes have been made. Do not add, remove or change DNS records, nameservers or Cloudflare custom-domain mappings without separate explicit approval.

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

### 6.3 Mandatory pre-acceptance branded staging subdomain

A branded staging host is **required**, not optional, before final Diagnostic/Evaluation Report acceptance (see Section 9). After the exact purchased domain and canonical hostname are confirmed by the Founder, use a dedicated subdomain such as `staging.<confirmed-domain>`, a separate staging Worker and an isolated hosted synthetic test backend. Verify DNS and certificate/TLS setup, HTTPS redirects and the complete synthetic learner journey. Staging backend/Worker provisioning and DNS/custom-domain mapping each require separate explicit approval; any paid resource or usage also requires separate cost approval. The ordinary per-PR `workers.dev` Preview remains the default development environment and is not evidence that branded hosted authentication or persistence works.

## 7. Release sequence and approval gates

| Stage | Work | Approval / verification |
|---|---|---|
| Every implementation PR | Relevant build, database/RLS, API, security and browser checks | CI evidence; no routine Founder Preview request |
| New substantial learner/staff-visible feature | One public synthetic-data Preview after checks pass | One focused Founder review of the new capability |
| Phase 1B–1F | In-scope implementation of the approved secure foundation, with local synthetic services first and public Preview verification | Proceed through the approved sequence with draft PR/CI evidence; hosted provisioning, paid spend, real data, merge and production release remain separate gates |
| Later hosted synthetic integration | Isolated hosted Supabase + Preview end-to-end auth/API using the Free tier where suitable | Separate hosted-resource provisioning approval; any paid plan or usage requires a documented unavoidable need and explicit cost approval; synthetic data only |
| Flagship phases 2–5 | PDF, extraction/OCR, grader workflow, feedback, timer/analytics | One Founder Preview when a phase adds a concrete, substantial learner/staff-visible capability that is ready for review; backend-only increments and routine sub-slices remain CI/local verification only; external services require separate approvals |
| Branded staging before Diagnostic/Report acceptance | Dedicated staging subdomain, separate Worker and isolated hosted synthetic backend; full public synthetic journey | Mandatory pre-acceptance gate; separate explicit hosted-resource, DNS/domain and paid-cost approvals; synthetic data only |
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


## 9. Pre-launch branded staging-domain verification (added 4 November 2026)

The Founder has clarified that the public website experience—including authentication, navigation, the Diagnostic and Evaluation Report—must be verified on a branded custom-domain staging host before final Diagnostic/Report acceptance. This staging gate is mandatory and is not production cutover. Therefore, domain readiness and branded staging verification are now explicit pre-launch roadmap gates; they are not deferred entirely until production cutover.

### 9.1 Staging host, not premature production cutover

- The confirmed custom domain is `gradioprep.com`. Select and record the canonical staging/production hostname separately; no DNS changes have been made and the site is not connected to the domain. Any DNS record, nameserver or Cloudflare custom-domain change still requires separate explicit approval.
- After separate explicit approval, configure a dedicated staging subdomain (for example, `staging.<confirmed-domain>`) to an isolated staging Worker and isolated hosted test backend. Use synthetic accounts and records only.
- Do not connect staging to production Auth, database, storage, email credentials or learner records. Configure the staging Auth Site URL and narrow confirmation/recovery callback allow-list for the staging host only.
- Verify TLS/HTTPS, canonical redirects, API and SPA routes, navigation, direct/deep links, refresh and browser Back/Forward.
- Execute the complete synthetic public journey: registration, email confirmation, sign-in, sign-out, password recovery, Diagnostic start/submission, Evaluation Report generation, learner-dashboard access, persistence and role/access restrictions.
- Record the exact host, Worker revision, backend identity (without secrets), test account/data scope, results and any defects. No real learner data or live customer registration is permitted in staging.

### 9.2 Approval and production boundaries

Staging-host provisioning, hosted test-backend provisioning and any DNS/custom-domain mapping each require explicit Founder approval before execution; paid resources/usage require separate cost approval. This section does not authorise any of them. If staging cannot be safely isolated, leave the check as a launch blocker; do not route the production apex/canonical host to an unfinished build as a workaround.

Production Custom Domain attachment, production Auth redirects, production DNS/nameserver changes, production deployment, opening public registration and official launch remain separate explicit approval gates under Section 6. A successful staging test is necessary pre-launch evidence but is not production release approval.

### 9.3 Revised acceptance order

Complete Phase 1 security/file foundations and shared flagship workflows; obtain approvals and provision isolated staging; pass the full branded-domain synthetic journey; then accept the Grade 9 Diagnostic and Evaluation Report and complete the remaining release gates. The Diagnostic/Report remain free. Do not treat per-PR workers.dev Preview as evidence of working hosted authentication or end-to-end persistence.
