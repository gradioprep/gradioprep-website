# Public Preview, Verification and Custom-Domain Release Process

> **Current execution checkpoint — 8 November 2026:** PR #22 remains open, draft and unmerged on feature/phase-1b-local-auth-api; the repository is public. Current application/branch head is 4f4be588880fd51abe628544a5af84102b5e59ca. Exact-head CI [#42490565745](https://github.com/gradioprep/gradioprep-website/actions/runs/42490565745) passed database reset/seed, PostgreSQL RLS and TypeScript/Worker/Vite builds, but Playwright finished 32/33: the typed-only task submission test received HTTP 404 assessment_task_not_available instead of expected HTTP 201; backup/restore was skipped. The previous backend-only code head b6dc72f3534b873b63536f5a994fe5027ddcc162 passed [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739) including 619 PostgreSQL assertions, 32/32 browser tests and synthetic backup/restore. The local WSL checkout remains unverified. Use standard GitHub-hosted ubuntu-latest; do not start local Supabase/Docker or register a self-hosted runner. Hosted Supabase/R2, paid usage, external processing, real learner data, DNS/custom-domain changes, production deployment and PR merge remain separately gated.


**Version:** 2.1-draft
**Date:** 8 November 2026
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

The approved synthetic Auth/PostgreSQL/Storage/RLS verification runs against a disposable Supabase stack **inside the ephemeral GitHub-hosted `ubuntu-latest` CI job**, not on the user's Windows/WSL computer. Do not start local Supabase/Docker containers on that PC or register it as a self-hosted runner. A public Cloudflare Preview can verify the deployed app shell, UI, Worker routing and safe non-sensitive states; it cannot connect to the ephemeral CI database.

Do not fake or claim end-to-end hosted Auth/RLS verification on a public Preview. A later Preview requiring working hosted authentication/database, or the mandatory branded staging journey, may use a separate isolated Supabase cloud project with synthetic data only after separate provisioning approval and restricted credentials. No hosted project is authorised now.

This separation keeps the user's computer clear of the database stack and avoids prematurely provisioning a hosted backend or exposing learner data.

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
| Phase 1B–1F | In-scope secure-foundation implementation; disposable synthetic Supabase runs inside GitHub-hosted CI; Cloudflare Workers Builds handles the connected app build/Preview path | Proceed through the approved sequence with draft PR/CI evidence; do not run Supabase on the user's PC; hosted provisioning, paid spend, real data, merge and production release remain separate gates |
| Later hosted synthetic integration | Isolated hosted Supabase + Preview end-to-end auth/API using the Free tier where suitable | Separate hosted-resource provisioning approval; any paid plan or usage requires a documented unavoidable need and explicit cost approval; synthetic data only |
| Flagship phases 2–5 | PDF, extraction/OCR, grader workflow, feedback, timer/analytics | One Founder Preview when a phase adds a concrete, substantial learner/staff-visible capability that is ready for review; backend-only increments and routine sub-slices remain CI/local verification only; external services require separate approvals |
| Branded staging provisioning | Create dedicated staging subdomain/Worker, isolated hosted synthetic backend, restricted staging Auth callbacks and synthetic-account reset process | Requires separate explicit hosted-resource, DNS/domain and paid-cost approvals; synthetic data only |
| Founder’s branded-staging test | Founder personally verifies the complete Diagnostic and Evaluation Report journey on a branded host with an isolated hosted synthetic backend | Mandatory before final Diagnostic/Report acceptance; separate hosted-resource, DNS/domain and paid-cost approvals; synthetic accounts only |
| Limited live participant pilot | Invitation-only test with 2–3 participants after the Founder’s staging test | Separate privacy/legal, security, safeguarding, guardian-consent, provider/hosting and cost approvals; initially free |
| Initial public free release | Open the completed Diagnostic and complete Evaluation Report (plus approved free starter resources) to the intended public audience | Pilot findings resolved and separate Founder release approval; no paid service claims |
| Full commercial launch | Open the complete broader service including Remedial Course and paid grading | Remedial, credit, entitlement, payment, refund, Admin and operational gates accepted; separate production approval |
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

Complete the shared flagship workflow and validate it synthetically before actual MYP Year 4 diagnostic item authoring. Build the Diagnostic and complete Evaluation Report, then obtain separate approvals and provision isolated branded staging. The Founder must pass the complete branded-domain synthetic journey before final Diagnostic/Report acceptance. Only then may a separate, approved, invitation-only free pilot with 2–3 participants begin. Resolve pilot findings and obtain separate Founder release approval before the initial public free Diagnostic/Report release. Paid services and full commercial launch remain later gates. Per-PR workers.dev Preview is not evidence of hosted authentication or end-to-end persistence.



## Current CI, Cloudflare build and release separation — 8 November 2026

The user's Windows/WSL computer must not run Supabase/Docker database containers and must not host a persistent self-hosted Actions runner. The synthetic Supabase stack runs only inside GitHub-hosted `ubuntu-latest` CI. Device readings and installed-tool inventory are recorded in `docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md`; this session did not reopen the WSL filesystem.

GitHub confirms the repository connected to Cloudflare Workers Builds is public. Automatic builds and Previews are enabled; `main` is the configured production branch. Production build/deploy commands remain `npm run build` and `npx wrangler deploy`; Preview commands remain `npm run build` and `npx wrangler preview`. Production and Preview watch-path exclusions are still empty. This workflow change did not alter Cloudflare settings. Documentation-only exclusions remain a separate reviewed account-setting task; do not change deployment commands, production branch, DNS, custom domains, Worker bindings or secrets.

The GitHub workflow correction is committed as `dc13c80`. The heavy suite runs once on pushes to PR #22's dedicated head branch by owner `gradioprep`, ignores `docs/**` and Markdown-only changes, and cancels stale runs through branch-scoped concurrency. There is no parallel `pull_request` or PR-description trigger. The separate build workflow also ignores docs/Markdown and cancels superseded runs; it remains skipped for PR #22's stacked base. Relevant source, Worker, migration, SQL, browser, dependency, workflow and configuration changes remain covered on standard `ubuntu-latest`.

The initial attempts exposed a one-microsecond synthetic fixture mismatch and a legal-hold RPC state mismatch. Test-only commit `26fbea0` and append-only migration `edc3340` corrected them. Full run [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308) passed 601 SQL assertions/17 files, 31/31 Playwright tests, TypeScript/Worker/Vite builds, private-PDF/database backup/restore, cleanup and credential-free build. The verifier restored one database snapshot and one PDF checksum and rejected a corrupt archive. All five spending budgets remain blocked; there is no evidence of paid overage or Actions-minute exhaustion. The repository is public: never commit credentials, real learner data or confidential teacher content. A Free Supabase cloud project remains a possible later hosted integration/staging resource only, requires separate approval, and is not provisioned. No DNS or production setting was changed by these workflow/documentation changes.


## 10. Milestone batching and founder-testing handoff — 8 November 2026

The Founder approved coherent implementation milestones rather than a separate “implement the next step” prompt for every routine subtask. Engineering should continue the approved synthetic-only roadmap in related batches, with relevant code, automated tests, verification evidence and source-of-truth documentation. Keep app-code/test and docs-only commits distinguishable where appropriate. Report at meaningful milestone boundaries; do not ask for repeated approvals for routine work already within scope. Pause for a genuine blocker or a separate approval gate. Founder-facing Preview handoffs remain conditional on a new, substantial visible capability and passing relevant checks.

The test audiences and release gates are:
1. **Synthetic engineering validation:** fictional learners and synthetic tasks/PDFs in disposable CI; this validates feature correctness and is the pilot-validation gate before actual MYP diagnostic item authoring.
2. **Founder’s own test:** complete Diagnostic and Evaluation Report on branded staging using isolated hosted synthetic data; required before final acceptance.
3. **2–3 invited pilot participants:** only after the Founder’s own test passes and all real-data, privacy/legal, security, safeguarding, consent, provider/hosting and cost approvals are granted. Start invitation-only and free.
4. **Initial public free release:** after pilot findings are resolved and a separate release approval is granted, open the completed free Diagnostic and Report plus approved free starter resources. This is not the full commercial launch.
5. **Full commercial launch:** only after the Remedial Course, credits, entitlement/payment/refund flows, Admin controls and production operational requirements are implemented and accepted.

No user-facing live pilot or public release may be inferred from synthetic CI, a workers.dev Preview or the Founder’s synthetic staging test. Hosted staging and DNS mapping remain separate approvals; production domain cutover and production deployment remain later separate gates.
