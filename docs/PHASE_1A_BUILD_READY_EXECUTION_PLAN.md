# Phase 1A — Build-Ready Execution Plan

**Version:** 0.2-draft  
**Date:** 2 November 2026  
**Status:** Founder-approved preparation step; Founder has separately authorised Phase 1B local synthetic-only coding. This is an execution-ready engineering plan, not proof of completed implementation or service provisioning. Production, DNS, hosted services and real data remain unauthorised.  
**Parent:** `docs/PHASE_1_SECURE_APPLICATION_FOUNDATION_IMPLEMENTATION_SPEC.md`  
**Authority:** `docs/PROJECT_MASTER_BRIEF.md` and the approved Phase 0 decision register.

## 1. Outcome of this preparation step

The purpose of Phase 1A is to remove avoidable design uncertainty so the next approved step can begin coding without reopening the architecture.

**Implementation route selected for the first coding step:** work against a local Supabase stack using fictional records, with no hosted Supabase project, paid plan, R2 bucket, AWS KMS key, Azure resource or real learner data. Supabase documents the local stack as a free, self-contained development environment for Auth, PostgreSQL and Storage; it requires the Supabase CLI and a Docker-compatible local runtime. This lets schema, Auth, RLS and Storage policies be tested before any remote service is considered.

The first code slice is **Phase 1B — local application foundation, Auth and role-aware identity**. It will add the Worker API gateway, local Supabase configuration/migrations/seed data, browser sign-in/out, a protected `/api/v1/me` endpoint and a first complete set of synthetic role/RLS tests. It will not implement learner PDF submissions, OCR, AI feedback, the grading queue or production integrations.

## 2. Repository inspection — verified starting point

The repository default branch was inspected on 2 November 2026. The current app is:

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

## 7. Local development, synthetic fixtures and CI

### 7.1 Local stack

Add the Supabase CLI configuration, migrations, seed data and database tests to the repository. Use a local Docker-compatible runtime (Docker Desktop or OrbStack on macOS are documented supported options) to run the local Supabase Auth, PostgreSQL and Storage stack. Keep all CLI state, local data and secrets out of Git. No remote project should be linked during the first code slice.

The local seed must create clearly fictional test users and records for:
- two students;
- two guardians, with one verified link and one unlinked/revoked case;
- two graders;
- one admin;
- one owner;
- at least one suspended/revoked account and one expired session case.

Do not use real email addresses, student names, handwritten samples, school identifiers or copies of any real learner work. Use reserved fictional domains and obviously synthetic labels.

### 7.2 CI pipeline

Extend the existing Build check in a separate implementation PR to:
1. Install the pinned Node and Supabase CLI versions.
2. Start the local Supabase stack on the GitHub-hosted runner.
3. Apply migrations and deterministic synthetic seed data.
4. Run SQL/RLS database tests.
5. Run Worker unit/API tests with stubbed provider endpoints where appropriate.
6. Run TypeScript checks and the existing Vite build.
7. Run the existing Playwright Chromium suite plus auth/route/role UI coverage.
8. Stop the local stack and ensure CI logs contain no secrets or synthetic user credentials.

CI must not authenticate to any remote Supabase project, use production Cloudflare bindings, create resources or process real learner data. Keep the existing controlled preview/deployment workflow unchanged.

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
- The new database tests pass from a clean local reset and in CI.

The first PR remains draft/unmerged for review. No hosted preview is enabled for the authenticated app unless it is using the local test backend or a separately approved isolated synthetic project. Do not deploy to production.

## 9. Backup and recovery decisions — proposal, not approval

For planning the eventual real-learner pilot, the recommended targets are:

| Measure | Proposed target | Conditions |
|---|---|---|
| Database RPO | At most 1 hour | Requires seven-day PITR and monitoring that the latest usable recovery point is no more than one hour behind; a configured PITR window alone is not proof that a recent recovery point exists |
| Accepted PDF object RPO | At most 15 minutes | Requires encrypted event-driven/15-minute replication to R2 and a verified object checksum; no real file replication until privacy/transfer/key approval |
| Service RTO | At most 8 business hours | Requires a documented operator, access to recovery keys, tested database-plus-object restore and a successful timed exercise |

These are **proposed service targets**, not current capabilities or promises. If PITR/replication is not funded or tests do not prove the targets, the service must publish the weaker tested recovery commitment and the Founder must approve it before real learner submissions are accepted.

Supabase Pro daily backups alone are daily and cover the database, not Storage API file objects. Without PITR, the database RPO may be up to the last daily backup (potentially almost 24 hours); a daily database dump does not restore deleted PDF objects. Restore tests must independently verify both database and file objects. Supabase documentation states Pro projects have seven days of daily backups and that Storage API objects are not included.

### 9.1 Recommended encryption design for secondary objects

Recommended candidate for Founder review: **AWS KMS customer-managed symmetric key in Mumbai (`ap-south-1`)**, with client-side envelope encryption before writing each backup object to R2. Use a fresh random data-encryption key per object; encrypt the object using authenticated encryption (AES-256-GCM); wrap the data key with the KMS key; store only the wrapped key, algorithm/version and required non-sensitive metadata beside the encrypted object. Keep KMS permissions separate from R2 read/write credentials and restrict decryption to the recovery operator. Test key rotation and full restore before enabling real-data replication.

AWS publishes a base KMS customer-managed key price of USD 1/month per key and a free tier of 20,000 eligible requests/month; request pricing depends on operation type. This is a candidate estimate only. AWS lists a Mumbai KMS regional endpoint, but account availability, identity federation/credential handling from Workers, DPA, legal transfer, recovery and exact bill must be validated before selection or provisioning. Do not use a long-lived unrestricted AWS administrator key in Worker secrets. If a narrowly scoped, safely rotated credential or supported short-lived identity flow cannot be implemented, choose another reviewed KMS integration instead.

R2 remains the secondary file-backup destination only. Its APAC location hint is not an India residency guarantee. A decision to use AWS KMS does not by itself authorise sending real PDFs to R2 or any cross-border processing.

## 10. Current cost picture and no-cost development path

### Local synthetic development

- Supabase local CLI stack: no Supabase subscription or hosted usage charge; local machine/container resources are required.
- Cloudflare Worker local development and GitHub Actions checks: no new account or remote service required. Do not enable remote bindings.
- No paid Supabase plan, R2 bucket, KMS key, Azure resource or Workers AI endpoint is required for the first code slice.

### Future hosted / real-data costs to reconfirm before provisioning

- Supabase Pro: official current documentation describes USD 25/month before extra usage, with USD 10 monthly compute credits covering a Micro project, 8 GB database disk, 250 GB egress and seven days of daily backups. Larger compute and overages change the invoice.
- Supabase 7-day PITR: approximately USD 100/month at the published hourly rate; it requires at least Small compute. The official example totals USD 130/month for one Pro project with Small compute and 7-day PITR after the USD 10 compute credit (Pro USD 25 + Small USD 15 + PITR USD 100 − credit USD 10). PITR add-on charges are not covered by the Spend Cap.
- Cloudflare Workers current usage-based free allocation: 10 million requests and 30 million CPU-ms/month; current overage rates must be checked against the account plan before going live.
- Cloudflare R2 current free monthly usage: 10 GB storage, 1 million Class A and 10 million Class B operations; additional usage is charged. Actual backup storage/operation volume must be modelled.
- AWS KMS candidate: USD 1/month for one customer-managed key; published free usage is 20,000 eligible requests/month, with exclusions for certain APIs.

These figures are current published USD examples checked 2 November 2026, not an approved budget, invoice estimate or promise. Tax, currency conversion, email delivery, monitoring, recovery and other services may add costs. No auto-upgrade or paid overage is authorised. Recheck official pricing before any provisioning.

## 11. Account access required by stage

| Stage | Required access | Not required |
|---|---|---|
| First coding slice, local only | GitHub repository write for a draft branch/PR; GitHub Actions CI; local Docker-compatible runtime | Supabase hosted account/project, Cloudflare account changes, AWS/Azure account, billing owner, production credentials |
| Later isolated hosted synthetic test | Supabase project owner only for creating the isolated project/plan; restricted developer access for migrations; separate review of Cloudflare preview access | Production learner records or production credentials |
| Real learner pilot | Founder-owned Supabase billing/ownership and recovery; least-privilege project developer/operator; Cloudflare Worker deployment authority; separately reviewed backup/KMS rights; legal/privacy reviewer | Shared accounts or general admin credentials for all developers |

For the first code slice, do not ask the Founder for any password, API key, recovery code, billing details or remote credentials. The local CLI and Docker-compatible runtime are sufficient.

## 12. Remaining decisions and blockers

**Can be coded locally in the next step:** Worker API entrypoint, browser auth client, Supabase local config/migrations, profiles and role assignments, safe helper functions, first RLS policies, synthetic fixtures, tests, CI and no-data API responses.

**Must remain blocked until later explicit approval:** hosted Supabase Pro project, Cloudflare production Worker changes, R2 bucket/object replication, AWS KMS or any external key-management service, paid PITR, real learner records, real PDFs, Azure OCR, Workers AI and live pilot.

**Requires Founder decision before real-data readiness:** whether to accept the proposed RTO/RPO targets and their cost; whether AWS KMS is approved as the secondary-backup key manager; current service quotes and legal/privacy approval. These decisions do not prevent local synthetic coding of the Auth/API/RLS foundation.

## 13. Exact next step

After the Founder separately authorises coding, implement only **Phase 1B — Local Auth, Worker API and role foundation** on a new branch based on the approved documentation branch. Deliver a draft PR with migrations, synthetic seed data, API and UI, RLS tests, Worker tests, CI results and an updated implementation status. Do not merge, deploy, provision hosted services or accept real learner data. Continue to Phase 1C–1F only after the prior checkpoint is reviewed and accepted.

This plan does not change the existing diagnostic sequence: MYP Year 4 actual diagnostic item authoring remains gated until the flagship feature is implemented and pilot-validated; Cambridge Grade 6 remains blocked.


## 14. Official technical references checked 2 November 2026

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


## 15. Mandatory public verification loop

The Founder has directed that public website verification must occur throughout implementation, not be postponed until the end of a phase. Follow `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md` for the mandatory GitHub → automated checks → Cloudflare Worker Preview → Founder verification → correction/re-preview cycle. The PR must provide an updated public `workers.dev` Preview URL and an immutable deployment URL for each reviewed revision, a plain-language visible-change summary, exact routes and short click-by-click checks, CI results, connected-backend status and any limitations. Do not close a coherent implementation milestone as verified until the Founder has inspected the deployed Preview.

The controlled preview workflow `.github/workflows/controlled-worker-preview.yml` is included in this source branch and supports PRs targeting `main` and the active stacked integration branch. It uses the existing Cloudflare Worker Preview capability and `npx wrangler preview`, never `npx wrangler deploy`; it posts the Preview URL and removes the Preview when the PR closes. Previews are public unless Access is enabled and must contain synthetic data only. During Phase 1B, authentication/RLS tests run against local Supabase in CI; the public Preview cannot reach the private local database, so the handoff must state this honestly. Do not provision hosted Supabase merely to make a preview login work; that needs separate approval.

**Current approval:** Founder has approved Phase 1B coding with local Supabase and synthetic data only. No hosted project, paid plan, real data, merge, production deployment, DNS or custom-domain connection is approved. The custom domain connects at the Launch Candidate / Production Cutover checkpoint after feature, security, accessibility, content, privacy and recovery gates; it is not needed for per-PR public verification.


## 16. Phase 1B implementation progress and tests-first Preview gate — 2 November 2026

Phase 1B coding is underway in draft PR #22. It adds the first local Auth/Worker/profile-role/RLS slice with fictional identities only. The local Supabase stack starts, environment files are written, and the first migration/seed have applied in CI. The initial pgTAP run exposed four assertion-format failures: the SQLSTATE/permission-denied behavior was correct, but the test helper arguments treated the expected description as exact error text. The assertions have been corrected to validate SQLSTATE only; the corrected run is pending. Do not mark the slice complete until corrected RLS tests, Worker/browser build and Playwright acceptance all pass.

The Phase 1B workflow is `.github/workflows/phase1b-verification.yml`. It runs local Supabase → migration/seed → pgTAP RLS → Worker/browser TypeScript and Vite build → Playwright → local stack shutdown → deletion of `.dev.vars`/`.env.local` → clean public-preview rebuild → `npx wrangler preview`. Public Preview is uploaded only after the complete security/build/browser pipeline passes. The generic `.github/workflows/build.yml` handles general site PRs and skips duplicate work for PRs targeting this Phase 1B base. `.github/workflows/controlled-worker-preview.yml` is cleanup-only. This avoids a public Preview racing ahead of security tests.

The `pr-22` Preview that was deployed before the final tests-first workflow was added is still useful for checking its safe account-not-connected state, but it is not verification of the latest code revision. A new Preview must be posted only after the latest head commit passes every required test. The public Preview cannot reach local Supabase; it verifies UI, Worker routing and safe states only. No hosted project, paid service, real learner record, merge, production deploy or DNS change is included.
