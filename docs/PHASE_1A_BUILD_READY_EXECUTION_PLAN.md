# Phase 1A — Build-Ready Execution Plan

> **Current execution checkpoint — 9 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`; GitHub confirms the repository is public. Exact application-code/test head `5df10f70c23a35bdf1759fcec8b12a36fca1a9c9` passed [GitHub Actions #42579642253](https://github.com/gradioprep/gradioprep-website/actions/runs/42579642253): all 19 PostgreSQL/RLS SQL test files, 33/33 Playwright tests, TypeScript/Worker/Vite builds, synthetic database/private-PDF backup/restore (one DB snapshot and two PDF checksums; corrupt archive rejected), Supabase shutdown, local credential cleanup and clean credential-free build. This is the exact application/test revision; later docs-only commits are distinct. Phase 1F synthetic technical evidence remains accepted only for its documented test scope. Phase 2 PDF-only submission, transcript review, AAL2 Grader private-file retrieval and human grading draft/publication are verified synthetic workflows. Next is the server-authoritative advisory timer and timing/accuracy analytics. Do not run local Supabase/Docker, create a hosted service, incur cost, use real learner data, change DNS, merge or deploy to production without separate approval. Local WSL checkout remains unverified.
**Version:** 0.36-draft
**Date:** 8 November 2026
**Status:** Phase 1C, Phase 1D, Phase 1E and Phase 1F technical evidence are verified for their accepted synthetic-only scopes. Local WSL synchronization is not verified. Do not run local Supabase/Docker or a self-hosted runner. Current exact application/test head `5df10f70c23a35bdf1759fcec8b12a36fca1a9c9` passed [#42579642253](https://github.com/gradioprep/gradioprep-website/actions/runs/42579642253): all 19 PostgreSQL/RLS SQL test files, 33/33 Playwright, TypeScript/Worker/Vite builds, private database/PDF backup/restore, shutdown, local credential cleanup and credential-free build. Cloudflare Workers Builds also reported a successful branch Preview build; the Actions PR Preview handoff was skipped for the push event. Timer persistence/UI and validated accuracy/elapsed-response analytics are the next implementation milestone.

**Parent:** `docs/PHASE_1_SECURE_APPLICATION_FOUNDATION_IMPLEMENTATION_SPEC.md`  
**Authority:** `docs/PROJECT_MASTER_BRIEF.md` and the approved Phase 0 decision register.

## 1. Outcome of Phase 1A preparation and Phase 1B implementation status

The purpose of Phase 1A is to remove avoidable design uncertainty so the next approved step can begin coding without reopening the architecture.

**Implementation route selected for the first coding step:** use a disposable Supabase stack with fictional records inside a GitHub-hosted CI job. Do not run Supabase or its Docker containers on the user's Windows/WSL computer, and do not register that computer as a persistent self-hosted runner. No hosted Supabase project, paid plan, R2 bucket, AWS KMS key, Azure resource or real learner data is needed for the current synthetic CI tests.

The first code slice was **Phase 1B — local application foundation, Auth and role-aware identity**. It added the Worker API gateway, local Supabase configuration/migrations/synthetic fixtures, browser sign-in/out and recovery, the protected `/api/v1/me` endpoint, role/suspension controls, MFA safeguards and the secure staff-invitation lifecycle. The invitation/security slice passed exact code-bearing CI on commit `1953bd1` and the latest documentation-only branch tip passed CI as recorded in Section 13. This does not implement learner PDF submissions, OCR, AI feedback, the grading queue, the complete protected grader/admin data workflow, hosted services or production integrations.

## 2. Repository inspection — historical pre-Phase 1B baseline (2 November 2026)

The repository default branch was inspected on 2 November 2026, before the Phase 1B changes in PR #22. The following describes the historical starting point for this plan; it is not the current feature-branch state:

- React 19.1 with TypeScript 5.9 and Vite 7.
- Cloudflare Wrangler 4.152 serving the built `dist/` directory as Static Assets.
- Playwright Chromium tests run using `npx wrangler dev`.
- The existing `wrangler.jsonc` has an `assets` directory and SPA fallback, but no Worker `main` entrypoint or API handler.
- `package.json` currently contains React and the frontend/build/test tools; no Supabase SDK or Supabase CLI setup is present.
- The existing application screens are prototype screens with sample content; there is no authentication, protected API, persistent learner database or live submission workflow.
- The active parent branch used by the documentation PR has a Build workflow triggered for pull requests to any base branch. Keep the implementation PR stacked on the approved documentation branch so it inherits that workflow; do not rebase older content PRs or alter production deployment triggers.

The actual first implementation must preserve the present route-driven React navigation and existing design tokens. Do not rewrite the application framework or redesign unrelated pages.

## 3. Selected technical integration for the first code slice

### 3.1 Browser authentication

Use the official `@supabase/supabase-js` browser client for email/password sign-in, sign-out, session refresh and account recovery flows. Only the Supabase project URL and publishable key may be exposed to browser code. A publishable key is not an authorization control: RLS remains mandatory. The browser must not query application tables directly; application data access goes through the same-origin Worker API.

The browser SDK normally persists and refreshes the user's session. Keep the session handling entirely inside the supported SDK; never write passwords, access tokens or refresh tokens to custom application logs or application tables. Use the PKCE-capable supported flow, restrict redirect URLs, apply a strict Content Security Policy, avoid unsafe HTML insertion and keep third-party scripts out of authenticated pages. The chosen SPA design does not require SSR cookies; do not add `@supabase/ssr` solely to solve a problem the app does not have.

### 3.2 Worker authentication and data access

Use Supabase's current `@supabase/server` package for the Cloudflare Worker API. Supabase's current package-selection guide explicitly lists Workers as a target for `@supabase/server` when the user's identity arrives in an `Authorization: Bearer <JWT>` request header. The documented `withSupabase({ auth: 'user' }, ...)` path supplies a caller-scoped client that respects RLS.

For each protected request:
1. Read the bearer token from the request header; reject missing or malformed credentials.
2. Use the supported `@supabase/server` authentication wrapper to validate the user session and construct the caller-scoped Supabase context.
3. Read the actor identity from that verified context only.
4. Query only the required profile/role data using the caller-scoped client.
5. Let PostgreSQL RLS enforce row access. Return only the allowed fields.
6. Use `Cache-Control: no-store` for authenticated responses. Do not log tokens, request bodies, private learner content or signed URLs.

Do not manually decode a JWT and treat its claims as verified. Do not copy the user's ID or role from request JSON. Do not use `service_role` / secret keys in the browser or in normal Worker request paths. The first code slice requires no service-role key. Do not create an admin client or endpoint just to make the implementation easier.

Pin the package version used in the first implementation PR and verify its Worker runtime compatibility in CI before expanding the API surface. If the package API changes before coding, use its then-current supported Worker pattern rather than copying an outdated example.

### 3.3 Worker entrypoint and static asset routing

Preserve the existing Cloudflare Workers Static Assets approach. Add a Worker entrypoint (proposed path: `worker/index.ts`) to `wrangler.jsonc`, with the existing `dist/` assets and SPA fallback retained. Configure an `ASSETS` binding and selectively invoke the Worker first for `/api/*`; all ordinary page and asset requests should continue through the existing static-asset route. Do not migrate the app to a different hosting service or introduce Cloudflare D1.

Keep Worker TypeScript compilation separate from the current browser TypeScript configuration (proposed `tsconfig.worker.json`). Generate the Worker environment types from the Wrangler configuration with `wrangler types`; do not hand-maintain a conflicting `Env` interface. Use a minimal Worker handler with explicit route matching, method checks, request validation, bounded body reads and structured errors. API paths must not fall through to the SPA's `index.html`.

This is a minimal static-assets-plus-API Worker pattern. Do not introduce the Cloudflare Vite plugin unless an actual build limitation requires it.

## 4. First database migration and identity model

Use the Supabase CLI local project and checked-in SQL migration files as the single schema source of truth. No schema changes made only in a hosted dashboard may be treated as canonical.

The first migration set should be deliberately small:

| Table | First-slice purpose | Important constraints |
|---|---|---|
| `public.profiles` | Minimal profile keyed to the Supabase Auth user ID | One-to-one FK to `auth.users`; display name only; no password or duplicate credential storage |
| `public.role_assignments` | Effective role grants and immutable grant/revoke history | Allowed roles only: student, guardian, grader, admin, owner; actor and UTC timestamps; partial unique index prevents duplicate active grants |
| `public.guardian_learner_links` | Verified relationship and consent scope | Distinct guardian and learner IDs; pending/verified/revoked state; verifier and timestamps; no relationship inferred from a name or email match |
| `public.course_enrolments` | Defines the learner's active course/pathway access | Learner ID, pathway/course identifier, state and dates; never grant access merely because a route exists |
| `private.security_audit_events` or equivalent restricted audit table | Records role grants/revocations and privileged account changes | Append-only for application roles; actor, action, target, result and UTC timestamp; no passwords, tokens or response text |

Profile creation may be performed by a narrowly scoped database trigger on Auth user creation. It must create only the minimum profile row; user metadata must never create a privileged role. Role grants are not available from public signup and are not writable by the ordinary authenticated user. Synthetic roles are loaded only by local seed data. No public owner-creation flow is built; production owner bootstrap is a later manually controlled, audited operation.

Keep the broader assessment/submission tables for a later migration when the relevant checkpoint begins. Do not build unused records or expose answer keys in this first slice.

## 5. RLS and helper-function implementation rules

- Enable RLS on every exposed table before granting any table privileges.
- Default to no access; grant only the minimum SQL permissions required for each operation.
- Write separate policies for SELECT, INSERT, UPDATE and DELETE. Do not write one broad policy for all authenticated users.
- A student can read their own profile, their own role labels and their own enrolment rows; they cannot insert or modify a role grant.
- A guardian can read only their own link record and the limited profile/records of a learner linked through an active verified relationship with the approved scope.
- A grader cannot see submissions or learner data through the profile/role foundation merely by having a grader role. Assignment-scoped access will be added with the grading tables in a later migration.
- Admin is not automatically owner. No admin can grant themselves owner status.
- Owner access is explicit, MFA-protected in the application layer and attributable in the audit trail.

Where role/link checks would otherwise create recursive RLS policy queries, use narrowly scoped helper functions in a non-exposed `private` schema. For any `SECURITY DEFINER` helper: set an empty/fixed safe `search_path`, schema-qualify every referenced object, avoid dynamic SQL, revoke default execution from PUBLIC, grant execution only where needed and test its behavior as every synthetic role. Prefer `SECURITY INVOKER` elsewhere. Do not expose helper functions through the public Data API.

RLS verification must use actual local Supabase JWT-authenticated identities, not only mocked Worker tests. Use Supabase's documented database-test workflow (SQL tests under `supabase/tests/` and `supabase test db`) for anonymous and authenticated allow/deny cases. Each sensitive table must have explicit coverage for all four operations.

## 6. Minimal first API contract

| Endpoint | Authentication | First-slice behavior |
|---|---|---|
| `GET /api/health` | None | Returns a static service-health response only; no secret, region or internal configuration details |
| `GET /api/v1/me` | Valid Supabase user JWT | Returns the current user's minimal profile and active role labels using the caller-scoped RLS client |
| `PATCH /api/v1/me` | Valid Supabase user JWT | Allows only approved self-editable profile fields (initially display name); rejects role, email, account state, ID and timestamp changes |

No endpoint for assigning roles, reading arbitrary profiles, guardians viewing child data, grader queues, answer keys, submissions, file uploads, credits or admin operations is part of the first slice. Those operations require later explicit route/policy implementation and tests.

## 7. Synthetic development, fixtures and hosted CI

### 7.1 Synthetic database environment — hosted CI only

The project retains Supabase CLI configuration, migrations, seed data and database tests in the repository. **Run the disposable Supabase stack only inside the ephemeral GitHub-hosted `ubuntu-latest` verification job.** That job uses fictional identities and records, resets the database for each run, and stops the stack/cleans local-only files at completion. This is the existing workflow's meaning of "local Supabase": local to the isolated hosted job, not local to the user's Windows/WSL computer.

Do not run `npm run supabase:start`, `npx supabase start` or Docker-based database tests on the user's PC. Do not increase WSL/Docker memory, install another Docker Engine or register a persistent self-hosted runner. The available Windows RAM is 1.44 GiB and the senior developer advised against local Supabase. Keep the existing WSL/Docker installation idle for these tests.

### 7.2 GitHub Actions security and browser pipeline

The current verification workflow uses `runs-on: ubuntu-latest`; the GitHub-hosted environment, not the user's computer, performs these steps:

1. Check out the exact trusted PR/push revision and install the repository's Node 22 dependencies.
2. Start the reduced Supabase services within the ephemeral hosted job.
3. Write ignored local-only CI environment files and reset the disposable database with synthetic fixtures.
4. Run PostgreSQL RLS/pgTAP tests.
5. Type-check/build the Worker and browser application and run the Playwright Chromium suite.
6. Run the Phase 1E backup/restore verifier when its suites are ready.
7. Stop Supabase, remove local-only environment files and complete any credential-free asset/build checks.

Keep the database reset and synthetic data inside the job; never cache database state or upload secrets/test-user credentials. Continue to use least-privilege job permissions and same-repository trust checks. Do not expose Cloudflare deployment credentials to a persistent self-hosted runner.

**Completed GitHub Actions efficiency correction — commit `dc13c80`:** the full workflow has one push trigger scoped to `feature/phase-1b-local-auth-api` and owner `gradioprep`; docs/Markdown changes are ignored and branch-scoped concurrency cancels stale runs. It has no `pull_request` or PR-description trigger, avoiding duplicate full runs. Standard `ubuntu-latest`, dependency installation, synthetic Supabase reset/seed, full SQL tests, Worker/browser build, Playwright, the Phase 1E backup/restore verifier and cleanup are retained. The separate `build.yml` also ignores docs/Markdown and cancels stale runs; it continues to skip PR #22's stacked base. Current run `#42473595308` is the active end-to-end verification.

### 7.3 Cloudflare application builds and Previews

The repository is already connected to Cloudflare Workers Builds. Read-only inspection confirmed automatic builds and branch Previews are enabled, with `main` as the production branch, `npm run build` as the build command and `npx wrangler deploy` as the production deploy command. Preview builds use `npm run build` and `npx wrangler preview`. Use this existing integration for normal app build/deployment; do not create a second hosting service.

Current watch-path settings include every file and exclude none, so Markdown-only updates may still trigger Cloudflare builds. A later reviewed settings change should exclude documentation-only paths for both production and Preview builds while preserving application, Worker, migration, test and configuration paths. Do not change the production branch, production deploy command, DNS, domain, Worker bindings or secrets under this plan.

### 7.4 Public repository and hosted Supabase fallback

GitHub confirms the repository is public. Treat its source, history, branches, PRs and Actions logs/artifacts as publicly visible. Do not commit credentials, real learner data or confidential teacher materials. This is an observed visibility state, not a claim that every historical artifact has been scanned.

A separate Supabase Free project may be considered only for a later hosted end-to-end integration/staging requirement. It is not needed for current security database tests, and its creation still requires separate explicit approval, synthetic-only data and restricted credentials. Free projects may pause after a week of insufficient activity; do not assume always-on staging.

## 8. First-slice acceptance gate

The first coding PR is accepted only when all of the following pass:

- Existing site navigation and direct routes remain functional.
- Static assets continue to be served normally; `/api/*` does not return the SPA shell.
- Sign-in, sign-out, session refresh and invalid/expired-session handling pass with local synthetic users.
- Protected API routes reject anonymous, malformed, expired and wrong-context tokens.
- `/api/v1/me` returns only the caller's profile and active role labels.
- A student cannot read or alter another user's profile or role assignment by changing request IDs or HTTP verbs.
- Guardian access is absent for unlinked/revoked learners and restricted to the documented verified link scope.
- Admin cannot grant owner access; public signup cannot select or modify roles.
- RLS tests cover SELECT/INSERT/UPDATE/DELETE for every first-slice protected table with anon and each synthetic role.
- No service-role key, database password or other privileged secret is present in browser code, static assets, source-controlled config, test output or logs.
- Existing TypeScript/Vite and Playwright checks still pass.
- The new database tests pass from a clean reset inside the ephemeral GitHub-hosted CI Supabase environment.

The first PR remains draft/unmerged for review. No hosted preview is enabled for the authenticated app unless it is using the local test backend or a separately approved isolated synthetic project. Do not deploy to production.

## 9. Backup and recovery decisions — proposal, not approval

**Cost-policy cross-reference:** The free-first rule and 12-month US$0 recurring-spend target are binding in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`. The RTO/RPO figures below are engineering proposals only, not a commitment to buy PITR, R2, KMS or any other paid service.

For planning the eventual real-learner pilot, the recommended targets are:

| Measure | Proposed target | Conditions |
|---|---|---|
| Database RPO | At most 1 hour | Requires seven-day PITR and monitoring that the latest usable recovery point is no more than one hour behind; a configured PITR window alone is not proof that a recent recovery point exists |
| Accepted PDF object RPO | At most 15 minutes | Requires encrypted event-driven/15-minute replication to R2 and a verified object checksum; no real file replication until privacy/transfer/key approval |
| Service RTO | At most 8 business hours | Requires a documented operator, access to recovery keys, tested database-plus-object restore and a successful timed exercise |

These are **proposed service targets**, not current capabilities or promises. If PITR/replication is not funded or tests do not prove the targets, the service must publish the weaker tested recovery commitment and the Founder must approve it before real learner submissions are accepted.

Supabase Pro daily backups alone are daily and cover the database, not Storage API file objects. Without PITR, the database RPO may be up to the last daily backup (potentially almost 24 hours); a daily database dump does not restore deleted PDF objects. Restore tests must independently verify both database and file objects. Supabase documentation states Pro projects have seven days of daily backups and that Storage API objects are not included.

### 9.1 Recommended encryption design for secondary objects

No key-management provider has been selected or approved. Evaluate a secure free option or suitable existing platform-supported key management first. AWS KMS is only an unselected candidate for comparison, not a recommended purchase or implementation default. If a later threat/recovery design proves a paid key manager unavoidable, present the exact cost and alternatives before seeking approval. The envelope-encryption design, if adopted, must use a customer-managed symmetric key with client-side envelope encryption before writing each backup object to R2.

AWS KMS has been listed at approximately USD 1/month per customer-managed key, plus applicable requests, but this is a dated comparison figure only. It is not in the approved architecture baseline, does not authorise account creation, and must not be included as a committed monthly expense. Any key provider must pass identity, key-custody, recovery, region and privacy review.

R2 remains the secondary file-backup destination only. Its APAC location hint is not an India residency guarantee. A decision to use AWS KMS does not by itself authorise sending real PDFs to R2 or any cross-border processing.

## 10. Current cost picture and free-first 12-month operating target

### Hosted synthetic development and cost model

- Disposable Supabase CLI stack: run only inside the ephemeral GitHub-hosted `ubuntu-latest` CI job; no Supabase subscription or local PC containers are required for current database tests.
- GitHub-hosted Actions minutes for the private repository depend on the owner account's plan. The current account plan and remaining minute balance have not been verified; the latest no-step failure does not prove minutes were exhausted.
- Cloudflare Workers Builds is the existing application build/deployment integration. Its Free allowance is currently documented as 3,000 build minutes/month, one concurrent build and a 20-minute timeout. The Cloudflare account limit check on 8 November reported the limit had not been reached; a recent completed build was not returned by the build-list query.
- Keep all five GitHub spending budgets blocked. Do not use a self-hosted WSL runner or make the repository public to avoid minute usage.
- No cloud Supabase project, paid plan, R2 bucket, KMS key, Azure resource or paid Workers AI endpoint is required or authorised for current Phase 1E test preparation.

### Future hosted services — dated cost snapshot, not an approved spend

The binding rule is in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`: target US$0 recurring infrastructure subscriptions and paid API use from 3 November 2026 through 2 November 2027; review actual needs at 100+ subscribers but do not automatically upgrade. The figures below were checked 3 November 2026 and must be rechecked before any activation.

| Service | Free-first allowance | Paid exposure if proven unavoidable |
|---|---|---|
| Supabase | Free: 500 MB database, 1 GB Storage, 50,000 MAU, 5 GB egress + 5 GB cached egress; may pause after 7 days of low activity; manual CLI DB exports, no automatic downloadable DB backups | Pro starts at $25/month, plus possible compute/usage. PITR 7-day option is about $100/month and requires at least Small compute; a previous published sample total is about $130/month after the compute credit. PITR is not approved or required by default. |
| Cloudflare Workers | Free: 100,000 Worker requests/day and 10 ms CPU per HTTP request; static assets free/unlimited | Paid minimum $5/month/account; 10 million requests and 30 million CPU-ms included, with usage charges beyond. |
| Cloudflare R2 | Free: 10 GB-month, 1 million Class A and 10 million Class B operations, free egress | Standard storage above allowance $0.015/GB-month; operation overages apply. APAC placement hint is not India-residency assurance. |
| Azure Document Intelligence Read | F0: 500 pages/month, 4 MB/document, 2 pages per analysis and 1 request/second | S0 is metered per page. Confirm exact Central India rate before use. |
| Cloudflare Workers AI | 10,000 Neurons/day free | Usage above the allocation requires Workers Paid (minimum $5/month) and is $0.011/1,000 Neurons above the free allocation. |
| GitHub Actions | Ephemeral `ubuntu-latest` hosted jobs for synthetic Supabase/RLS, API and browser testing; suppress docs-only triggers | Private-repository included minutes depend on the account plan; usage above included minutes may cost. Keep all five spending budgets blocked and do not enable overage. |
| AWS KMS / other key manager | No provider selected; assess suitable free options first | AWS KMS candidate reference is about $1/customer-managed key/month plus requests; not an approved default. |

These base prices are not an additive stack. Supabase Pro, Workers Paid, PITR, AWS KMS, Azure S0, paid email and other paid APIs are **not** planned subscriptions. The only cost target is zero recurring infrastructure cost unless an evidence-backed exception is approved.

### Decision rules before a paid exception

- Demonstrate the exact essential requirement the free option fails, with measured test evidence.
- Compare free/open-source/local alternatives and the operational consequence of staying free.
- Present current fixed monthly cost, variable usage formula, minimum compute/add-ons, tax and currency caveats, and likely monthly total for a realistic volume.
- Obtain the Founder's explicit approval before enabling billing, paid usage, overages or a paid resource.
- Keep auto-upgrades, spend-cap removal and paid fallbacks disabled.
- At 100+ active subscribers, review actual usage; this is not an automatic upgrade event.
- If a free service cannot meet security, recovery, availability, residency or capacity requirements and no safe free arrangement exists, keep real-data acceptance blocked until a decision is made. Do not weaken requirements simply to reach the $0 target.


## 11. Account access required by stage

| Stage | Required access | Not required |
|---|---|---|
| First coding slice, hosted synthetic CI | GitHub repository write for a draft branch/PR; GitHub Actions hosted CI; existing Cloudflare Git build connection | Local Docker/Supabase runtime, Supabase hosted project, Cloudflare account changes, AWS/Azure account, billing owner, production credentials |
| Later isolated hosted synthetic test | Explicitly approved isolated synthetic project; use the free tier if suitable; restricted developer access for migrations; separate review of Preview access | Production learner records or production credentials; any paid plan/usage without a separately approved cost exception |
| Real learner pilot | Founder-owned Supabase billing/ownership and recovery; least-privilege project developer/operator; Cloudflare Worker deployment authority; separately reviewed backup/KMS rights; legal/privacy reviewer | Shared accounts or general admin credentials for all developers |

For the first code slice, do not ask the Founder for any password, API key, recovery code, billing details or remote credentials. The disposable hosted CI workflow is sufficient for current synthetic database testing; do not start Supabase on the user's computer.

## 12. Remaining decisions and blockers

**Can proceed in the next implementation step:** Phase 1E SQL migration/test work and its backup/restore verifier, with all database execution inside the ephemeral GitHub-hosted Supabase CI job. No local PC Supabase setup is part of the route.

**Must remain blocked until their specific gates pass:** hosted Supabase or other hosted resource provisioning, Cloudflare production Worker changes, R2 bucket/object replication, any key-management service, paid PITR, real learner records, real PDFs, Azure OCR, Workers AI and live pilot. Use free tiers by default where suitable; any paid plan/usage requires a documented unavoidable need and explicit cost approval.

**Requires Founder decision before real-data readiness:** final tested RTO/RPO commitment; backup/key-management method and regional-transfer controls; any hosted plan or unavoidable paid service (with exact quote); and legal/privacy approval. The proposed RTO/RPO targets and AWS KMS are not approved purchases. These decisions do not prevent local synthetic coding or other in-scope implementation already authorised by the plan.

## 13. Historical Phase 1B next-step record (superseded by Section 16)

**Historical note:** The pending Founder visual-review item and the statement that Phase 1C had not started below were accurate only at that earlier checkpoint. The Founder subsequently approved the Phase 1B shell review, and Phase 1C first-slice implementation and verification are now recorded in Section 16. Retain this dated snapshot for traceability; do not follow it as the current next step.

**Verified Phase 1B MFA and staff-invitation checkpoint — 3 November 2026:** PR #22 remains open, draft and unmerged on feature/phase-1b-local-auth-api. Exact verified commit: 1953bd1d9141f8033e00166cd10aee89a8d563e6. GitHub Actions run [#41598979870](https://github.com/gradioprep/gradioprep-website/actions/runs/41598979870) passed on that exact head. It passed local Supabase reset/seed, PostgreSQL/RLS plus 24 staff-invitation SQL assertions, TypeScript/Vite/Worker builds, 20/20 Playwright browser tests, local stack shutdown, local environment cleanup and clean public-Preview build. Browser coverage includes owner AAL1/AAL2 boundaries; create/list/revoke; grader/admin allow-listing; duplicate pending, email mismatch, anonymous/admin denial; same-page invitation-link consumption; invitee verified-email plus TOTP/AAL2 acceptance; and revoked/expired/replayed token rejection. Invitations store only a SHA-256 hash of a random 256-bit token, expire within seven days, and generate a copyable fragment URL without sending email. No service-role client is used. Cloudflare Workers Builds independently deployed the same commit; the Phase 1B Actions Preview upload/comment steps were skipped for the push event. Stable branch Preview: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. Immutable Preview: https://98207523-gradioprep-website.wandering-scene-1822.workers.dev (deployment 98207523-8ea0-46c8-a6c7-20e3d9ea15f0). The public Preview is disconnected from hosted Supabase; inspect the shell/navigation and safe account-unavailable state only. Invitation interactions were verified only in local synthetic CI.

**Staff invitation implementation step — complete and verified:** Owner-managed staff invitation creation/listing/revocation and invitee acceptance are implemented and pass the exact-head checks recorded above. Database RPCs enforce owner+AAL2 management, a grader/admin-only role set, one-time token-hash storage, seven-day expiry, verified-email matching, AAL2 acceptance and audit records. The Worker uses only the caller-scoped client and no service-role/admin client. The public Preview does not connect to hosted Auth or send mail; authenticated interactions were verified against local synthetic Supabase. The next remaining security guardrail is to require AAL2 on any future grader/admin protected API/data operation when those endpoints are introduced, with database/Worker tests at that point. The next broader planned checkpoint is Phase 1C — protected API and database; it is not started by this invitation slice.

**Latest exact-head UI correction, CI and Preview — 3 November 2026:** The latest code-bearing homepage correction is in commit `4e3321026b2aa552244a4bcdc1b60fd889a2e8a5`; the current branch head `edae7fc4fdbaa62712a6e3e052ef5117d9aa3293` additionally contains the corrected Playwright regression assertions. The homepage entry now reads **Sign in** and its arrow is decorative. Exact-head Actions run [#41604461931](https://github.com/gradioprep/gradioprep-website/actions/runs/41604461931) passed on `edae7fc`: local Supabase startup/reset and synthetic seed, PostgreSQL RLS, TypeScript/Worker/Vite build, **21/21 Playwright tests**, stack shutdown, local credential cleanup and clean public-Preview build. The first regression-test attempt had a syntax error caused by an over-escaped regex; the test was fixed to use an exact URL pathname predicate and exact heading assertion before the successful run. Cloudflare Workers Builds independently deployed the exact current branch head successfully. Stable Preview: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. Immutable Preview: https://0898c277-gradioprep-website.wandering-scene-1822.workers.dev (deployment `0898c277-3d4c-4d21-9496-f2e0215e0701`, 3 November 2026 at 08:36:17 UTC). The public account route has no hosted Supabase/Auth connection and intentionally displays the safe backend-unavailable state; do not enter credentials or real learner data. **Immediate next action:** Founder visual/functional review of the latest Preview (homepage and Sign in, pathways/direct URLs, Previous/Next and browser Back/Forward, and direct `/account` safe state). Automated CI and successful deployment do not complete this manual review. After the Founder review and any required corrections/re-preview, proceed to Phase 1C — protected API and database with table-by-table RLS, cross-role API tests and AAL2 enforced at the Worker/database authorization boundary for every future privileged grader/admin operation. PR #22 remains open, draft and unmerged. No hosted provisioning, paid service, real learner data, external email, merge, production deployment or DNS change is authorised.

This plan does not change the existing diagnostic sequence: MYP Year 4 actual diagnostic item authoring remains gated until the flagship feature is implemented and pilot-validated; Cambridge Grade 6 remains blocked.


## 14. Official technical references checked 3 November 2026

- Supabase local development (CLI, container runtime, free local stack): https://supabase.com/docs/guides/local-development
- Supabase local migration workflow: https://supabase.com/docs/guides/local-development/database-migrations
- Supabase RLS and database tests: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase server package selection; `@supabase/server` header-based auth and Workers support: https://supabase.com/docs/guides/auth/choosing-a-server-package
- Supabase project regions: https://supabase.com/docs/guides/platform/regions
- Supabase data-residency and transfer FAQ: https://supabase.com/legal/privacy-resources/data-residency-and-transfers-faq
- Supabase daily backups and Storage object exclusion: https://supabase.com/docs/guides/platform/backups
- Supabase Pro and compute-cost example: https://supabase.com/kb/faqs/platform/database-only-cost
- Supabase PITR pricing and billing example: https://supabase.com/docs/guides/platform/manage-your-usage/point-in-time-recovery
- Cloudflare Workers Static Assets binding and selective Worker-first routing: https://developers.cloudflare.com/workers/static-assets/binding/
- Cloudflare React/Vite application with API Worker: https://developers.cloudflare.com/workers/framework-guides/web-apps/react/
- Cloudflare current usage-based billing summary: https://developers.cloudflare.com/billing/understand/usage-based-billing/
- Cloudflare Worker secrets: https://developers.cloudflare.com/workers/configuration/secrets/
- AWS KMS pricing: https://aws.amazon.com/kms/pricing/
- AWS KMS regional endpoints: https://docs.aws.amazon.com/general/latest/gr/kms.html

Region selection establishes the location for the Supabase primary project data and backups, but it is not by itself a legal compliance conclusion or a guarantee that all support/telemetry/subprocessor processing stays in India. Review the current DPA and data-residency FAQ before real-data approval.


## 15. Conditional Founder Preview review

The Founder has clarified that public Preview links should not be repeatedly surfaced for routine engineering changes. Follow `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`: all affected code still receives appropriate local/CI verification, but ask the Founder to inspect a public Preview **only when a new, concrete and substantial learner/staff-visible feature is ready**.

Do not request Founder Preview review for documentation-only changes, internal security/RLS/database changes, backend/API changes without a visible user workflow, refactors, test/CI updates, ordinary bug fixes, maintenance, or redeployments that add no substantial visible feature. Keep automated build/deployment results in engineering records without repeatedly telling the Founder about unchanged previews. A correction/redeploy of the same feature does not by itself trigger another Preview request.

The Phase 1B verification workflow uses the hidden PR-body marker `<!-- founder-preview-required -->` to gate its public Preview upload/comment. Add this marker internally only when a qualifying visible feature is ready for Founder review. The Founder does not need to manage labels or workflow settings. Never use `npx wrangler deploy`, change DNS or provision another service for this review. Previews remain synthetic-only and are not production.

For internal Phase 1B/1C backend and authorization work, local Supabase CI is authoritative. The public Worker cannot reach that private database. Do not provision hosted Supabase just to make a Preview login work; that needs separate approval.

**Current approval:** Founder has approved Phase 1B coding with local Supabase and synthetic data only. No hosted project, paid plan, real data, merge, production deployment, DNS or custom-domain connection is approved. The custom domain connects at the Launch Candidate / Production Cutover checkpoint after feature, security, accessibility, content, privacy and recovery gates; it is not needed for per-PR public verification.


## 16. Historical Phase 1C first-slice checkpoint — superseded by Section 16.10

**Verified state:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`; Phase 1C code commit `05544d1a394e2e480b7cd2dd9f55100b6998ee71` passed exact-head GitHub Actions run [#41613490244](https://github.com/gradioprep/gradioprep-website/actions/runs/41613490244). Evidence: 116 PostgreSQL/pgTAP assertions across four SQL files, 24/24 Playwright tests, local Supabase reset/seed, TypeScript/Vite/Worker builds, clean stack shutdown/credential cleanup and clean public-Preview build. Cloudflare Workers Builds deployed the same application revision to immutable Preview https://b4391d8e-gradioprep-website.wandering-scene-1822.workers.dev; it has no hosted Supabase connection. The Phase 1B public-shell visual/functional review has already been approved. Do not repeat staff-invitation work.

**Completed Phase 1C first slice:** versioned typed-task prompts; learner-owned attempts/responses; database-generated response word counts, versions and timestamps; private append-only response history; learner list/create/read/save/submit API; grader queue/detail scoped to active assignments with AAL2; owner AAL2 assignment; guardian reads limited by verified active link plus explicit submission-view consent; admin denial by default. RPCs: `create_attempt`, `save_attempt_response`, `submit_attempt`, `assign_attempt_to_grader`. This is not full human assessment/PDF submission or grading/feedback functionality.

**Next-session work order — finish Phase 1C before Phase 1D:**

1. Inspect current migrations, Worker routes, database functions, RLS policies and tests; make a table-by-table inventory of implemented versus missing protected operations. Do not redo passing work.
2. Finish the full default-deny RLS and Worker authorization matrix across all remaining protected records, with actual allow/deny tests for anonymous/student/guardian/grader/admin/owner, AAL1/AAL2, suspended accounts, revoked links/assignments and cross-learner isolation.
3. Complete assessment/submission metadata and immutable task/rubric/submission version relationships; implement the full grader workflow, criterion-level results, immutable assessment/feedback versions and explicit human-only publication. Keep drafts/QA private; admins must not inherit owner, grader or QA rights.
4. Complete append-only audit coverage for privileged access and changes, and server-authoritative capacity/idempotency plus the fixed 24-hour SLA. Acceptance and due-time snapshots are server-controlled and immutable; queue order is oldest accepted first; do not accept work beyond tested capacity.
5. Add negative tests for forged actor/owner/role/assignment/state/timestamps, replay, concurrency, direct table writes and RPC misuse. Verify the Worker and database enforce each privileged AAL2 boundary independently.
6. Run the full local synthetic CI after each coherent slice; request a Founder Preview only when a substantial new learner/staff-visible feature has been added; routine backend/security work is verified locally and kept in the engineering record. Update the master brief, implementation specification, plan and data model on every verified milestone.

**Phase 1C exit criteria:** full protected-table RLS/permissions matrix; complete non-file submission/grading/feedback lifecycle; restricted admin/private-QA separation; audit and 24-hour SLA/capacity evidence; cross-role and adversarial tests passing; current source-of-truth records reconciled; latest CI and Preview evidence recorded. Do not mark Phase 1C complete until all are satisfied.

**Phase 1D boundary:** begin private file/storage and audit/file controls only after Phase 1C exits. The 10 MB/10-page PDF limits, file-signature/MIME checks, private non-identifying object keys, assignment-scoped access, immutable original/correction history, short-lived signed access, deletion/retention and backup/recovery controls belong to that later phase. Any hosted Storage/R2 provisioning, paid resource, external processing or real learner data remains separately gated and is not authorised by this plan.


### 16.1 Phase 1C physical inventory and execution slices — 3 November 2026

The first Phase 1C slice adds five public tables: `task_versions`, `task_version_prompts`, `attempts`, `attempt_responses` and `grader_assignments`; plus the private `attempt_response_versions` archive. The current protected inventory is 12 tables total: nine public and three private; `profiles`, `role_assignments`, `guardian_learner_links`, `course_enrolments`, `security_audit_events` and `staff_invitations` are Phase 1B records. The actual implementation inventory, grants, policies and per-role access expectations are specified in Section 20.1/20.2 of the implementation specification and Section 6 of `DATA_MODEL.md`.

The Phase 1C slices and their current status are:
- **1C-A — table inventory and default-deny enforcement:** verify every existing protected table, role, operation and AAL boundary; add actual PostgreSQL and Worker allow/deny tests. Do not infer safety from RLS being enabled alone.
- **1C-B — accepted submission lifecycle (implemented and exact-head CI verified in Section 16.3):** separate typed practice attempts from human assessment submissions; immutable task/rubric/submission snapshots; server-only acceptance, capacity, idempotency and fixed 24-hour due-time snapshot; oldest-accepted-first queue.
- **1C-C — human assessment and feedback (implemented and exact-head CI verified in Section 16.3):** criterion-level rubric results; immutable assessment/feedback versions; grader draft/save/final transitions; explicit human publication; learner reads only published versions.
- **1C-D — operational role separation:** authorised grader reassignment/revocation and state transitions; minimal delegated admin operations; private academic-QA access restricted to active Owner at AAL2 only; no delegated QA-grant mechanism exists. Admin never inherits owner/QA rights.
- **1C-E — audit and workflow integrity:** append-oriented audit coverage, replay-safe operations, deterministic queue ordering and server-authoritative state transitions.
- **1C-F — adversarial acceptance:** anonymous/student/guardian/grader/admin/owner tests at AAL1/AAL2, including suspension, revocation, cross-learner isolation, forged actor/owner/role/assignment/state/timestamps, RPC/table bypass and concurrent duplicate acceptance.

The Phase 1C exit gate remains all six slices implemented and verified, exact-head CI passing, all four source-of-truth documents reconciled, and a Founder Preview review only where a substantial new learner/staff-visible feature was added. Phase 1D remains blocked.


### 16.2 Verified Phase 1C-A protected-table security baseline — 3 November 2026

**Completed and verified:** migrations `20261103000600_phase1c_role_scope_hardening.sql` and `20261103000700_phase1c_private_audit_and_revoked_assignment_rls.sql` enforce enrolment/consent/active-assignment-scoped task metadata, owner-wide identity reads at AAL2 in PostgreSQL, RLS on private security audit with no browser policy, and active-only grader assignment-row reads. New/updated pgTAP files cover the 12 currently protected tables, default-deny grants, direct-write denial, student/guardian/grader/admin/owner row scope, AAL1/AAL2, suspension, consent/revocation and cross-learner isolation.

Exact-head run [#41646515558](https://github.com/gradioprep/gradioprep-website/actions/runs/41646515558) passed on `ee275ca714c9bfb6bb44f580c2b1e827106975d4`: **215/215 PostgreSQL assertions across six SQL files; 24/24 Playwright tests**; local Supabase reset/seed, TypeScript/Vite/Worker builds, shutdown/credential cleanup and clean public-Preview asset build. The Cloudflare branch Preview independently deployed the same commit to https://f26a4358-gradioprep-website.wandering-scene-1822.workers.dev. It remains disconnected from hosted Supabase, so protected API/RLS verification is the local synthetic-CI evidence, not the public Preview.

**Historical next-slice note:** this Phase 1C-A checkpoint originally identified 1C-B as next. Phase 1C-B and 1C-C have since been implemented and verified; see Section 16.3. Do not repeat completed invitation, typed-attempt or accepted-submission work.

**Open Phase 1C exit gates:** human-assessment/grading/feedback lifecycle, criterion-level rubric results, grader reassignment/state transitions, delegated admin/private academic-QA separation, broader append-oriented audit coverage, capacity/idempotency and fixed 24-hour SLA, replay/concurrency/adversarial tests and their source-of-truth/Preview evidence. Phase 1D remains blocked; PR #22 remains draft and unmerged.


### 16.3 Verified Phase 1C-B accepted submissions and Phase 1C-C human grading/feedback — 3 November 2026

**Exact verified head:** `d2e825746aa814de1f100ef2d8daa2e841d91c80`; PR #22 remains open, draft and unmerged. GitHub Actions [run #41668857175](https://github.com/gradioprep/gradioprep-website/actions/runs/41668857175) passed **361 PostgreSQL/pgTAP assertions across eight SQL files and 27/27 Playwright tests**, fresh local Supabase reset/seed, TypeScript/Worker/Vite build, Supabase shutdown, local-only credential cleanup and clean public-Preview asset build. Preview upload/comment steps were skipped intentionally because this backend-only change did not request a Founder Preview.

**1C-B verified:** `20261103000800_phase1c_accepted_human_submissions.sql` implements published rubric/task mappings, accepted human-assessment submissions and immutable original submission versions. Server-side acceptance validates the active learner/enrolment/task/rubric, serialises capacity checks, snapshots capacity and open workload, makes identical retries idempotent, rejects altered key reuse, and fixes acceptance and 24-hour due timestamps on the server. Tests cover capacity-full/disabled fail-closed cases, idempotency, ownership, immutable snapshots and cross-role access.

**1C-C verified:** `20261103000900_phase1c_human_assessment_feedback.sql` implements scoped submission grader assignments, private criterion-level grading drafts, draft retrieval/save and explicit human publication. It validates the full rubric criterion set and marks, creates immutable feedback/criterion-result versions, consumes drafts on publication and exposes only the latest published feedback to learners. Tests cover role/AAL boundaries, unassigned/revoked grader denial, admin non-inheritance, private drafts and immutable published outcomes.

**Revocation regression fix:** Before revoking the synthetic grader, the SQL test saves the existing submission ID and asserts that the target grader has an active assignment. Both revoked-grader denial RPC calls use that preserved ID and pass with `42501 / grader_assessment_forbidden`.

**Historical next-step note — superseded 4 November 2026:** Phase 1C-D operational role separation has passed exact-head CI run #41828382786 on commit c1647c7c7048b1d791c3d24f59ed51168f219d51. The current next steps are 1C-E expanded audit/workflow integrity, 1C-F full adversarial acceptance, and any remaining table-by-table Worker/database permission gaps. Keep Phase 1D blocked until the entire Phase 1C exit gate passes. Use local Supabase and synthetic records only; do not request a Founder Preview for routine backend/security work.


### 16.4 Verified Phase 1C-D completion and integrated commercial/diagnostic roadmap — 4 November 2026

**Historical checkpoint notice — superseded by Section 16.12 and the 6 November commercial amendment:** The implementation evidence below remains a dated record of the Phase 1C-D checkpoint. Its old immediate-next-step, subscription, tier and payment-sequencing assumptions are historical only; use Section 16.12, Master Brief Section 18 and the current Grading Credit and Remedial Access Policy for present status and downstream order.

**Latest verified state:** PR #22 remains open, draft and unmerged on feature/phase-1b-local-auth-api. Phase 1C-D operational role separation passed exact-head GitHub Actions run [#41828382786](https://github.com/gradioprep/gradioprep-website/actions/runs/41828382786) on commit c1647c7c7048b1d791c3d24f59ed51168f219d51. The run passed local synthetic Supabase reset/seed, PostgreSQL/RLS tests, TypeScript/Worker/Vite builds, 27/27 Playwright tests, cleanup and clean public-Preview asset build. Do not redo verified 1C-D work. The next logical slice is 1C-E audit/workflow integrity; follow with 1C-F adversarial acceptance and close any remaining operation-specific authorization gaps. Phase 1D remains blocked until the full Phase 1C exit gate passes.

**Commercial and learning-readiness decisions approved for future integration:** See docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md. The full diagnostic and evaluation report remain free, followed by a meaningful free starter remedial activity. Full remedial-course access uses the proposed Study Lab entitlement or an approved complimentary grant. Human grading uses separate 1/2/3/4+ Standard/Premium/Elite/Custom credits with a 20-minute unit of predicted grader effort and the curriculum-frequency calculation. One Standard task is free per learner account. One 24-hour SLA applies to all accepted human grading. Task word bands do not become input caps; PDF file limits are not pricing units; no surprise credit deductions are permitted. Normal learner email verification is required before live learner-record/paid entitlement access.

**Integrated work order after Phase 1C:**

1. Finish 1C-E, 1C-F and the complete 1C exit matrix; maintain local synthetic-only tests.
2. Complete 1D private PDF/file controls and original-file preservation, PDF.js extraction and transcript controls.
3. Complete 1E database/object backup, restore, retention/deletion and 1F security acceptance/runbooks.
4. Complete the shared learner submission, grader workspace, human feedback publication and timer/analytics experience; validate task metadata for response range, rubric scope, predicted grader minutes, tier and required credits.
5. Build and validate Cycle 1 Grade 9 / IB MYP Year 4 free diagnostic and complete report only after the flagship feature is implemented and pilot-validated.
6. Complete the existing mandatory whole-website learner-facing copy cleanup immediately after report validation and before remedial content authoring.
7. Author the evidence-based remedial course (five sessions by default, six/seven only where justified), free starter activity and outcome check.
8. Before any paid course/grading launch, implement ordinary learner email verification, course-entitlement service, append-only credit ledger, trusted payment confirmation/checkout, controlled 2/5-credit pack availability, commercial Admin dashboard, access grants/refunds and capacity safeguards.
9. Keep Cambridge Grade 6 blocked until Cycle 1 is complete and the Founder directs the transition.

The commercial layer must not delay the free diagnostic/report. The Admin dashboard and payment/credit UI are distinct future product work, not part of the present 1C security slice. No provider, live payment, hosted resource, external processor or paid usage is selected or authorised by these roadmap entries. Founder-facing Preview review remains reserved for new substantial visible features; routine backend/doc/CI changes do not trigger a Preview request.


### 16.5 Custom-domain staging verification added to the pre-launch critical path — 4 November 2026

**Documentation decision:** The custom domain must no longer be left solely to the final production cutover if the Founder needs the complete public experience checked before the planned launch. Add a branded, isolated staging-host verification checkpoint before final Diagnostic/Evaluation Report acceptance. The exact purchased domain and canonical hostname must first be reconfirmed with the Founder; use a dedicated staging subdomain on that domain (or another explicitly approved staging mapping) and a separate staging Worker/backend. This is not a production-domain cutover and must not point staging at production data or credentials.

**Updated next-step order:**
1. Finish exact-head CI for the private academic-QA slice and complete Phase 1C-E/F plus all remaining Phase 1C exit criteria. Do not advance to 1D until the exit gate passes.
2. Complete Phase 1D private PDF/file controls, Phase 1E backup/recovery/retention, and Phase 1F security acceptance/runbooks.
3. Implement and validate the shared learner submission, PDF handling, grader workspace, human-only feedback publication and timer/analytics workflows.
4. Obtain separate approval for an isolated hosted synthetic test environment and custom-domain staging/DNS configuration. Confirm registrar/Cloudflare zone ownership, canonical host, TLS, redirects, Supabase Auth Site URL and exact confirmation/recovery callback allow-list. No hosted provisioning, paid usage or DNS changes are authorised by this roadmap entry itself.
5. On the branded staging host, run the complete public journey with synthetic accounts and data: sign-up, email confirmation, sign-in/out, password recovery, navigation, direct/deep links, refresh, Back/Forward, Diagnostic start/submit, Evaluation Report generation, learner-dashboard access, persistence and role/access restrictions. Record results and resolve failures.
6. Only after shared flagship workflows are pilot-validated and the branded public journey passes, complete final acceptance of the free Grade 9 IB MYP Year 4 Diagnostic and Evaluation Report. Then perform the mandatory whole-website learner-facing copy cleanup before remedial authoring.
7. Keep production Worker/custom-domain cutover, production Auth redirect configuration, opening public registration and official launch as distinct later gates requiring explicit Founder approval.

**No premature production changes:** Continue ordinary development/CI on local synthetic Supabase and per-PR workers.dev Previews. Do not connect the apex/canonical production host to an unfinished application merely to test it. A staging subdomain may be used only after explicit approval and with isolated hosted resources; if a safe staging mapping is not available, keep the domain check as a documented launch blocker rather than silently changing production DNS. See `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`.


### 16.6 Historical Phase 1C-E/private academic-QA checkpoint — superseded by Section 16.7

The earlier 5 November snapshot described the guardian-at-AAL2 test quoting failure and the need for an exact-head rerun. The delimiters were corrected, and the next full synthetic run passed. Current verification evidence and the audit-context enhancement are recorded in Section 16.7.

### 16.7 Historical Phase 1C-E audit-context checkpoint — superseded by Section 16.10

**Verified state:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Last verified code-bearing commit: `d6de31c467817ad83e864760d61d2e8ab5e112ed`. Exact-head GitHub Actions run [#41971855781](https://github.com/gradioprep/gradioprep-website/actions/runs/41971855781) passed local Supabase reset/seed, all PostgreSQL/RLS/pgTAP tests, TypeScript/Worker/Vite builds, 27/27 Playwright tests, cleanup and clean public-preview asset build. Cloudflare Workers Builds passed for the exact commit. No Founder-facing Preview was requested for this backend-only increment. No Founder-facing Preview was needed or requested for this backend-only slice.

**Completed 1C-E increment:** migration `20261105000100_phase1c_audit_context_enrichment.sql` and test `audit_context.test.sql` add database-derived active-role snapshots, trusted Worker-generated request-correlation UUIDs with database fallback, and PostgreSQL transaction IDs to new private audit events. It does not change table count, direct client privileges or authorization decisions. Learner response/feedback/QA content and secrets are not copied into audit records.

**Remaining sequence:** 1C-E remains partial. Complete the operation-by-operation Worker/database audit and authorization matrix, including success/denied/failed outcomes for protected reads and state-changing operations, and test that failures do not create misleading success evidence. Then complete 1C-F adversarial acceptance across anonymous/student/guardian/grader/Admin/Owner, AAL1/AAL2, suspension/revocation, cross-learner isolation, forged actor/ownership/role/assignment/state/timestamps, replay, concurrency and direct table/RPC bypass. Keep Phase 1D blocked until every Phase 1C exit criterion is implemented, reconciled and passes full exact-head synthetic CI. Local Supabase and synthetic data only; no hosted resources, spend, real learner data, merge, production deployment or DNS changes are authorised.

**Branded staging gate:** After the secure foundation and shared flagship workflows are complete, obtain separate approval for an isolated hosted synthetic backend, separate staging Worker and branded staging subdomain on the exact Founder-confirmed purchased domain. Verify the complete public journey before final Diagnostic/Report acceptance. Production cutover, Auth redirects, public registration and launch remain separate later approvals.

### 16.8 Historical Phase 1C-E protected-read and write-outcome checkpoint — superseded by Section 16.10

**Verified exact-head implementation — 5 November 2026:** Code head `8ef011c7927a8f7c5d20da372fb3aca789d74663` on PR #22, branch `feature/phase-1b-local-auth-api`. Exact-head GitHub Actions run [#41981770337](https://github.com/gradioprep/gradioprep-website/actions/runs/41981770337) passed fresh local Supabase startup, reset and synthetic seed; all PostgreSQL/RLS/pgTAP tests; TypeScript, Worker and Vite builds; Playwright **27/27**; local Supabase shutdown; local-only credential-file cleanup; and clean public-preview asset build without local credentials. The exact-head Cloudflare Workers Builds check [#127093826637](https://github.com/gradioprep/gradioprep-website/runs/127093826637) also passed. Founder-facing Preview deployment/comment steps were skipped because this is a backend/security increment and adds no substantial new learner/staff-visible feature.

**Completed 1C-E audit coverage in this verified slice:**
- Protected reads now record allowlisted success only after retrieval, record authorised query failures separately, and record database-derived denials for missing role, ownership/assignment scope or AAL2. The Worker preserves the established 403 role/MFA responses and non-enumerating 404 responses.
- Privileged Owner and assigned-Grader operations record denials and post-RPC failures in addition to the existing transactionally written success events. The allowlist covers Owner role revocation, attempt/submission assignment and reassignment, submission transition, private-QA creation, and assigned-Grader draft save and feedback publication.
- Learner mutations cover attempt creation, typed-response save, attempt submission and human-assessment submission acceptance. Database checks bind attempt operations to the owning active student, and bind task operations to an active enrolment plus a published typed task; assessment acceptance also requires a published mapped rubric and prompt.
- Failure reasons are drawn from a safe fixed vocabulary. A caller cannot create a success event or pass response text, feedback, QA content, bearer tokens, token hashes, idempotency keys, credentials or raw database error strings into the audit record. Existing private, append-only audit-table permissions remain unchanged.

Migrations `20261105000300` through `20261105000600` implement protected-read outcomes, privileged-write outcomes, learner-write outcomes and preservation of the precise `assignment_required` denial category. The test additions are `audit_context.test.sql`, `privileged_write_audit.test.sql` and `learner_write_audit.test.sql`. No tables were added; the protected-table inventory remains **25 (18 public, seven private)**.

**Remaining Phase 1C-E work:** complete denied/failed audit outcomes for staff-invitation create/revoke/accept and privileged staff-invitation list/private-QA reads, then reconcile the full endpoint-to-audit/authorization matrix. Phase 1C-E is still partial; this verified increment is not Phase 1C completion.

**Phase 1C-F remains open:** complete the consolidated adversarial acceptance matrix across anonymous, Student, linked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner at relevant AAL1/AAL2 states. Retain coverage for suspension, revocation, cross-learner isolation, forged actor/role/ownership/assignment/state/timestamps, replay, concurrency and direct table/RPC bypass. Phase 1D remains blocked until all Phase 1C exit criteria pass exact-head synthetic CI.

PR #22 remains **open, draft and unmerged**. Work used local Supabase and synthetic records only. No hosted resource, paid service, real learner data, external processor, production deployment, domain/DNS change or merge was used or authorised.

**Historical next-order note:** the staff-invitation/private-QA coverage described above was subsequently implemented and verified at exact head `f5097ba8bae0eee4c420e8e5081f90287f3149ee`; see Section 16.9 for the current verified state and remaining audit-integrity blocker.

### 16.9 Historical Phase 1C-E staff-invitation and private-QA outcome audit checkpoint — superseded by Section 16.10

**Exact-head verification:** Code head: `f5097ba8bae0eee4c420e8e5081f90287f3149ee`. Exact-head GitHub Actions run [#41984620018](https://github.com/gradioprep/gradioprep-website/actions/runs/41984620018) passed on 5 November 2026. It passed local Supabase startup/reset and synthetic seeding, all **534 pgTAP assertions across 14 SQL test files**, TypeScript/Worker/Vite builds, **27/27 Playwright tests**, local Supabase shutdown, local credential-file cleanup and the clean public-preview asset build. This was a `push` event; the workflow's public Preview upload requires an eligible `pull_request` event with the `<!-- founder-preview-required -->` marker, so Preview deployment/comment steps were skipped. No hosted preview, hosted Supabase, production deployment or DNS change occurred.

**Implemented increment:** The code increment comprises commits `688456763cc87e75bb68264707b0e0905c06c4dd`, `82b4f956e39b4a8652f55ebfe943a3934c31b1fe` and `f5097ba8bae0eee4c420e8e5081f90287f3149ee` on PR #22. Migration `20261105000700_phase1c_staff_invitation_and_private_qa_audit.sql` adds protected-read allowlist coverage for the Owner staff-invitation collection and Owner private-QA records, adds failed-outcome action handling for staff-invitation creation/revocation, and updates the Worker routes for invitation list/create/revoke and private-QA read error paths. The privileged-write audit RPC now returns `true` only when it inserts an event; the Worker treats a missing/false audit acknowledgement as unavailable and fails closed. Migration `20261105000800_phase1c_audit_invitation_failure_integrity.sql` replaces the caller-category-based invitation-acceptance failure helper with a one-argument, database-derived helper: it resolves the SHA-256 token hash to the private invitation, derives AAL/account/email/state denials, never stores the token or email in the event, and refuses to create a failure event when the invitation is otherwise eligible for acceptance. SQL tests cover these paths, private audit-table permission boundaries, an eligible invitee's attempted false-failure event, and continued success of the actual acceptance RPC. No tables were added; the protected inventory remains **25 tables (18 public, seven private)**.

**Audit-integrity blocker:** **Audit-integrity blocker — Phase 1C-E is not closed:** the generic `audit_privileged_write_outcome` and `audit_protected_read_outcome` RPCs still accept an allowlisted `failed` outcome and safe reason category from an authenticated caller when database role/resource checks say that caller is authorised. A caller can therefore invoke an audit RPC directly, without attempting the corresponding business operation, and create a misleading failed event. The new invitation-acceptance helper avoids this particular issue by deriving denial/state outcomes itself, but the generic failure paths remain forgeable. The next implementation must bind failure evidence to the protected operation itself (for example, a database-controlled operation wrapper that executes/catches the real operation and appends its failure event outside the failed subtransaction, or another server-only attestation that a browser caller cannot invoke or fabricate). Add direct-RPC abuse tests proving authorised callers cannot invent failures and operation-level tests proving genuine failures are still recorded. Also add explicit Worker route/integration tests for the new invitation and private-QA error paths; the SQL suite and general Playwright suite do not by themselves prove each route's audit call, HTTP response and fail-closed behavior.

The acceptance-failure helper records only database-derived denial/state failures. It does not accept a caller-supplied failure category and does not log an otherwise-eligible pending invitation as failed. Unexpected failures in a valid invitation acceptance still need to be captured by the actual operation-bound failure path. The 534 pgTAP assertions and 27/27 Playwright tests pass, but they do not by themselves close the generic false-failure issue or prove each Worker HTTP route's audit call.

**Remaining Phase 1C-E / 1C-F order:** **Next implementation order:** first close the generic false-failure audit gap for protected reads and privileged writes using operation-bound evidence, with direct-RPC abuse and genuine-failure regression tests. Add Worker route/integration coverage for staff-invitation list/create/revoke/accept and private-QA read denial/failure paths, preserving the established HTTP status and non-enumerating behaviour. Then complete the full endpoint-to-audit/authorization matrix and Phase 1C-F adversarial acceptance across anonymous, Student, linked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner at relevant AAL1/AAL2 states, including suspension, revocation, cross-learner isolation, forged fields, replay, concurrency and direct table/RPC bypass. Phase 1C-E remains partial; Phase 1D remains blocked until the complete Phase 1C exit gate passes exact-head synthetic CI.

PR #22 remains open, draft and unmerged. The workflow's Preview upload/comment steps were skipped because this was a `push` event; clean public-preview assets were built, but no public preview was deployed. All work used local Supabase and synthetic records only. No hosted resources, paid usage, real learner data, production deployment, DNS change or merge was made or authorised.


### 16.10 Historical Phase 1C-E audit-correlation and Phase 1C-F acceptance checkpoint — superseded by Section 16.11

**Current Phase 1C security checkpoint — 5 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Verified code/test head: `5dba933dce39b05c69a6616e5bb730d404e3b5a2`; exact-head GitHub Actions run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) completed successfully. The isolated local-Supabase workflow passed **494 pgTAP assertions across 14 SQL files**, TypeScript, Worker and Vite builds, and **29/29 Playwright tests**; cleanup and the credential-free public-preview asset build also passed. The run was a branch push; Preview upload/comment steps were skipped. **No Preview or production deployment occurred for this checkpoint.**

Phase 1C-E has **representative per-distinct-action persisted audit correlation coverage**, not exhaustive coverage of every possible outcome for every route. The 29-row endpoint authorization/audit matrix records 25 Worker-audited routes, each with fail-closed HTTP 503 coverage when the audit service/key/acknowledgement is unavailable. Persisted-event assertions validate actor, actor-role snapshot, action, target, outcome, safe reason, request ID and transaction ID for representative actions and outcomes. The audit action/event mapping is explicit: Worker `student_attempt_create` → successful persisted event `attempt_created`; Worker `grader_assessment_draft_save` → successful persisted event `assessment_draft_saved`. Denied/failed requests retain the corresponding Worker action names. This evidence is representative per distinct action and must not be described as exhaustive outcome coverage.

The service-role-only `record_worker_audit_outcome` RPC remains restricted to the trusted Worker audit-ingestion client; business reads and writes remain caller-scoped. Existing adversarial coverage is mapped in `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md`. Already-passing synchronized concurrency checks for competing Owner attempt assignments and feedback publication, plus duplicate-submission idempotency, are retained and must not be duplicated. **Only two synchronized Phase 1C-F tests remain outstanding:** (1) simultaneous acceptance of the same staff-invitation token; and (2) a revocation or account-suspension race against an in-flight privileged request. Phase 1C-F remains open until both tests pass exact-head synthetic CI. Phase 1D remains blocked until every Phase 1C exit criterion passes.

All work remains local-Supabase/synthetic-only. No hosted-resource provisioning, paid usage, real learner data, external processing, email delivery, merge, Preview deployment, production deployment or DNS/custom-domain change is authorised. Do not request a Founder Preview for documentation, tests or backend/security work; request one only after adding a substantial new learner/staff-visible capability.

**Canonical evidence records:**
- `docs/PHASE_1C_ENDPOINT_AUTHORIZATION_AUDIT_MATRIX.md` — 29 route rows, 25 Worker-audited routes, authorization, event mapping and representative persisted correlation evidence.
- `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md` — actor/assurance and attack-surface evidence; both synchronized Phase 1C-F race tests now pass. Phase 1C-E remains representative per-distinct-action persisted audit correlation, not exhaustive outcome coverage.

**Next implementation order:**
1. Finish the final Phase 1C exit-criteria review across the endpoint authorization/audit matrix, adversarial matrix, code and tests. Do not reimplement or duplicate the passing synchronized races, attempt-assignment/publication concurrency or duplicate-submission idempotency.
2. Reconcile the remaining Phase 1C current-status records and run exact-head local synthetic CI after the documentation-only closeout.
3. Once every Phase 1C exit criterion is documented, reviewed and passing at the exact PR head, begin Phase 1D private PDF/file controls, then Phase 1E backup/recovery/deletion and Phase 1F synthetic security acceptance.
4. Add the approved submission-queue search/filter layer inside the existing flagship grader queue, not as a separate service, after/in conjunction with the existing queue implementation.

**Do not** provision hosted services, incur paid usage, process real learner data, send external email, merge, deploy Preview/production or change DNS/custom-domain settings without the relevant separate explicit approval. No Founder Preview is requested for backend/security/tests/docs.

### 16.11 Verified Phase 1C-F synchronized race acceptance — 5 November 2026

**Exact verified code/test head:** `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` on PR #22, branch `feature/phase-1b-local-auth-api`. Exact-head local synthetic GitHub Actions run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) completed successfully. The workflow passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **31/31 Playwright tests**, local Supabase shutdown, local-only environment-file cleanup and the credential-free public-preview asset build. The Cloudflare Workers Builds check also passed. Public Preview creation/update and PR Preview-link steps were skipped. **No public Preview or production deployment occurred.**

Both previously outstanding synchronized Phase 1C-F cases are implemented and passing:

1. **Same-token invitation acceptance:** two independent synthetic AAL2 sessions hit the deterministic barrier immediately before the acceptance RPC and submitted the same single-use invitation token. The result was one HTTP 200 acceptance and one safe HTTP 410 `invitation_already_used`; exactly one active Grader role; one successful and one failed/conflict `staff_invitation_accepted` audit event; distinct request IDs correlated to actor/action/invitation target/outcome; and no token/hash disclosure.
2. **Revocation/suspension racing privileged assignment:** separate synthetic submitted attempts and synchronized pre-RPC barriers were used for role revocation and account suspension. In each subcase the access change committed before the paused request resumed; the privileged assignment returned HTTP 403, a correlated `owner_attempt_assignment` denial event was recorded, and no grader assignment was created. Follow-up authorization checks remained denied.

The barrier is disposable local test plumbing: a synthetic test creates an RLS-protected table in local Supabase, and an atomic service-role-only arrival RPC coordinates the Worker requests. Worker control is additionally guarded by the local host and ignored local secret. No production migration, hosted table or production authorization bypass was added. CI reset/stopped local Supabase and removed local-only environment files.

Existing Owner assignment concurrency, feedback-publication concurrency and duplicate-submission idempotency tests were retained without duplication. Phase 1C-E remains **representative per-distinct-action persisted request-ID/event correlation coverage**, not exhaustive outcome coverage. The required successful event mappings remain Worker `student_attempt_create` → `attempt_created` and Worker `grader_assessment_draft_save` → `assessment_draft_saved`.

**Sequencing:** the two previously outstanding synchronized Phase 1C-F cases now have exact-head passing evidence. Phase 1D was not implemented or started in this change. Keep it unstarted until the final source-of-truth documentation reconciliation has itself passed exact-head CI and the Phase 1C exit record is fully reconciled. PR #22 remains open, draft and unmerged. No hosted provisioning, paid use, real learner data, external processing/email, public Preview, production deployment, DNS change or merge occurred or is authorised.


### 16.12 Historical closeout plan — superseded by Section 16.13

Both synchronized Phase 1C-F race tests now have exact-head passing evidence (application-code head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`, run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858)). The previously CI-verified docs-only baseline before the 6 November continuation, `69423db70fd2ff1f45c57e8b8589a95673d00c4c`, passed run [#42163013589](https://github.com/gradioprep/gradioprep-website/actions/runs/42163013589): 494 pgTAP assertions across 14 SQL files, builds and 31/31 Playwright tests; no Preview was deployed. Phase 1C-E remains representative per-distinct-action audit correlation, not exhaustive outcome coverage. The remaining gate is the final whole-Phase-1C exit-criteria/documentation review; Phase 1D is not started.

Approved downstream order: Phase 1D private PDF/file controls; 1E backup/recovery/deletion; 1F synthetic security acceptance; existing flagship grader queue and workflow with the approved queue-search/filter layer; typed/PDF submission, grading and human publication; timer/analytics; Cycle 1 Grade 9 / IB MYP Year 4 Diagnostic and permanently free complete Evaluation Report; whole-site learner-facing copy cleanup; standalone Remedial Course; then commercial catalogue, append-only credit ledger, distinct course entitlements, trusted payment fulfilment and the two Diwali offers. Branded staging on `gradioprep.com` with an isolated hosted synthetic backend remains required before final Diagnostic/Report acceptance, but hosted resources and DNS/custom-domain mapping require separate explicit approvals.

This is a planning/status record only. It does not implement any downstream capability or authorise hosted provisioning, paid usage, real learner data, merge, deployment or DNS changes.

### 16.13 Phase 1C closeout complete and next implementation handoff — 6 November 2026

**Phase 1C exit decision: COMPLETE** for the approved local-Supabase/synthetic-data scope. Application-code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` passed exact-head CI [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858): 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests, including same-token invitation acceptance and Owner revocation/account-suspension races. The final review reconciled the 25-table protected inventory (18 public, seven private), 29 HTTP method/path rows, 25 Worker-audited routes with fail-closed audit-outage coverage, the actor/assurance matrix and representative persisted request-ID/event correlation. Audit correlation is representative per distinct action, not exhaustive outcome coverage.

The closeout does not claim overall Phase 1 or real-data readiness. Phase 1D private PDF/file controls have been implemented and verified locally; Phase 1E backup/recovery/deletion and Phase 1F final synthetic security acceptance follow. Continue local-only synthetic development. PR #22 remains open, draft and unmerged. No merge, hosted resource, paid use, real learner data, external processing/email, Preview/production deployment or DNS change is authorised. Branded staging on `gradioprep.com` with an isolated hosted synthetic backend remains a separate mandatory gate before final Diagnostic/Report acceptance and requires separate approval.


## Historical local CI recovery and Phase 1E handoff — 7 November 2026 (superseded by Current CI and device execution decision)

WSL2 Ubuntu is installed; Linux user `gradioprep`. Docker Desktop/WSL integration, private repository checkout inside Linux and repository-scoped runner remain pending. The current `.github/workflows/phase1b-verification.yml` still targets `ubuntu-latest`; it will not use a self-hosted runner until a separate security-reviewed workflow change explicitly targets its labels. See `docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md`.

Use a repository-scoped, unprivileged Linux runner, outside the checkout, and only for trusted same-repository activity. Keep least-privilege token permissions. Do not expose Cloudflare, R2, hosted Supabase, production or Preview secrets to persistent test execution. Do not run fork/untrusted PR code or use `pull_request_target` to execute it. Self-hosted job minutes avoid GitHub-hosted Actions-minute consumption; artifact/cache storage and local PC/electricity/internet may still cost. All five spending budgets remain blocked.

Phase 1E is partial/unverified: the request/legal-hold and retention-plan migrations are present; the paired SQL suites plan 35 and 47 assertions and have not run. Exact-head run #42208654326 attempt 4 failed before runner assignment and ran no steps. Next implementation after runner setup is to run/fix both test files, verify local backup/restore and deletion/retention, then complete Phase 1F only after Phase 1E passes.

## Historical WSL2/GitHub connection checkpoint — 8 November 2026 (superseded by Current CI and device execution decision)

Verified: Windows PC has 8 GB DDR4 RAM; WSL2 Ubuntu runs as `gradioprep`; Docker Desktop 4.98.0 integration is enabled; Docker Engine 29.9.2, Compose 5.6.1, Git 2.43.0 and GitHub CLI 2.103.3 are installed. Docker/Ubuntu currently reports about 2.8 GiB total memory, so do not start full Supabase or increase memory limits until a safe resource review is completed.

**Authentication completed — 8 November 2026:** active GitHub account `gradioprep`, HTTPS Git protocol and private-repository access are verified by `gh auth status` and `gh repo view`. **Resume point:** clone under `/home/gradioprep/src`, verify `feature/phase-1b-local-auth-api` and the live PR #22 head, then review safe Supabase resource requirements. Do not share device codes, passwords or tokens. The workflow still targets `ubuntu-latest`; a separate security-reviewed workflow edit is required before a repository-scoped runner can receive jobs. Phase 1E's 35- and 47-assertion SQL suites remain unrun. All five spending budgets remain blocked. See `docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md`.


## Current CI and device execution decision — 8 November 2026

This decision supersedes any earlier instruction in this plan to run Supabase on the user's own Windows/WSL computer or to configure a WSL self-hosted runner.

Windows reports 1.44 GiB available physical RAM. WSL reports 2.1 GiB available, and Docker reports approximately 2.81 GiB total with no running containers. In accordance with the senior developer's advice, the local Supabase route is rejected. The GitHub Actions workflow's `supabase start` step runs inside GitHub's temporary hosted runner and does not use the user's local memory.

GitHub confirms the repository is public. Cloudflare Workers Builds remains connected; production/Preview watch-path exclusions are still empty and require a separate reviewed account-setting change. GitHub Actions uses one owner-only push trigger on the dedicated PR branch, docs/Markdown exclusions and stale-run cancellation. Run [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308) passed 601 PostgreSQL assertions/17 files, 31/31 Playwright tests, builds, backup/restore and cleanup. The verifier restored one DB snapshot and one private PDF checksum, and rejected a corrupt archive. Test fixture commit `26fbea0` and append-only legal-hold migration `edc3340` were validated by that run. All five spending budgets remain blocked.

Phase 1E is verified complete for synthetic acceptance. The next engineering task is Phase 1F final synthetic security acceptance against the existing adversarial and endpoint authorization/audit matrices. Hosted Supabase staging, paid usage, real data, DNS, production deployment and PR merge remain separately gated. Hosted Supabase staging, paid usage, real data, DNS, production deployment and PR merge remain separately gated.
