# Phase 1 — Secure Application Foundation Implementation Specification

**Version:** 0.16-draft
**Date:** 3 November 2026  
**Status:** Phase 1A preparation is complete. Phase 1B local Auth/MFA/staff invitations and the Founder-approved visual review are complete. The first Phase 1C typed-attempt/assignment-scoped grader slice remains the foundation; the current Phase 1C-A protected-table security hardening is now implemented and verified at commit `ee275ca714c9bfb6bb44f580c2b1e827106975d4` in PR #22 by exact-head run [#41646515558](https://github.com/gradioprep/gradioprep-website/actions/runs/41646515558): 215/215 PostgreSQL/pgTAP assertions across six SQL files and 24/24 Playwright tests passed, with fresh local Supabase reset/seed, TypeScript/Vite/Worker builds, cleanup and clean public-Preview asset build. Cloudflare Workers Builds deployed the same commit to immutable Preview https://f26a4358-gradioprep-website.wandering-scene-1822.workers.dev; it has no hosted Supabase connection. Phase 1C remains in progress; remaining work and exit gates are recorded in Section 20. PR #22 remains open, draft and unmerged. All implementation remains local-Supabase/synthetic-only; hosted resources, paid use, real learner data, external processing, merge, production and DNS changes remain separately gated. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.
**Parent decision register:** `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`  
**Related records:** `docs/PROJECT_MASTER_BRIEF.md`, `docs/DATA_MODEL.md`, `docs/FLAGSHIP_PDF_RESPONSE_GRADING_AND_TIMED_ANALYTICS_SPEC.md`, `docs/DIAGNOSTIC_AND_REMEDIAL_LEARNING_READINESS_STANDARD.md`, `docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md`, `docs/ENGLISH_STAGE_1_ROADMAP.md` and `docs/DESIGN_SPEC.md`.

## 1. Purpose and non-negotiable boundaries

Phase 1 establishes the security and persistence foundation required before PDF submission, OCR, human grading, feedback history, timed analytics or real learner accounts can be used.

This remains the binding implementation blueprint and acceptance contract, not a claim that every planned component is implemented. The verified Phase 1B subset (local Auth, Worker endpoints, profile/role foundation, MFA controls and secure staff invitations) exists only in the local synthetic Supabase stack and draft PR #22. Subsequent checkpoints—including protected grader/admin data operations, private-file workflows, backup/restore and security acceptance—remain incomplete unless separately recorded as verified in Sections 11 and 17–18. The approved Phase 0 choices remain binding. Do not substitute providers or regions, add a second application database, or widen the approved scope without a recorded Founder decision.

**Current authorisation:** implementation within the Founder-approved phased plan is authorised to proceed through reviewable code changes, draft PRs, automated tests and synthetic-data public Previews. Phase 1B is explicitly limited to local Supabase and fictional/synthetic records. Do not repeatedly seek approval for an implementation step already included in the approved plan. This authorisation does **not** include:
- creating/configuring hosted Supabase, R2, Azure or other hosted resources;
- purchasing/upgrading a plan, enabling paid usage, allowing overages or changing spend limits;
- connecting real learner accounts or processing real learner data;
- sending learner content to OCR, AI or backup processors;
- merging any PR, deploying to production, changing DNS or changing Cloudflare production configuration.

Use fictional/synthetic data only for development and hosted previews until the separate provisioning, privacy, security and live-pilot gates are satisfied. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.


## 2. Approved architecture and system boundaries

| Layer | Approved responsibility | Explicit exclusions |
|---|---|---|
| React/Vite client | Learner/staff UI; obtains and presents authenticated session; calls protected APIs | No privileged credentials, direct privileged writes or trusted role decisions |
| Cloudflare Workers | Existing app hosting and lightweight API/orchestration; authenticate requests, validate inputs, enforce operation-level authorization and call approved backend interfaces | No heavy PDF/OCR processing; no second database; no client-exposed secrets |
| Supabase Auth | Identity, sessions, password recovery and MFA support | Application roles must not be self-selected at signup |
| Supabase PostgreSQL, Mumbai `ap-south-1` | Single application database; constraints, transactions, RLS, audit records and versioned learning records | No Cloudflare D1 or parallel application database |
| Supabase private Storage, same project | Primary private source-PDF and response-object storage | No public learner buckets or permanent public object URLs |
| Supabase Free / Pro | Free is the default starting plan if tested availability, capacity, backup/restore and privacy requirements can be met. Pro is an optional paid fallback only where an essential requirement cannot be met on a suitable free arrangement; recheck current price/compute/usage and obtain explicit approval first. | Free projects may pause after inactivity and lack automatic downloadable DB backups; do not accept real data until these risks are controlled and tested. |
| Cloudflare R2 | Secondary encrypted PDF-object backup only, subject to regional-transfer and privacy approval | Not primary app storage, not a database, not approved for real learner objects until transfer gates pass |
| PDF.js | In-app rendering and digital text extraction | Does not replace original PDF |
| Azure Document Intelligence Read | Later Phase 2 scanned-page OCR, intended Central India, subject to exact region/service validation | Not part of Phase 1 provisioning or real-data testing |
| Cloudflare Workers AI | Later teacher-only stateless draft suggestions, after separate gates | Not part of Phase 1 provisioning; no automatic publication |

The Workers API is the single application-facing orchestration boundary. Supabase remains the sole system of record for application data. Do not create duplicate role, submission, grading or credit state in Workers storage.

### 2.1 Request and trust flow

1. The client obtains a Supabase Auth session and sends its access token to the Worker over HTTPS.
2. The Worker validates token signature, issuer, audience, expiry and subject against the configured Supabase project. Reject missing, malformed, expired or wrong-project tokens.
3. The Worker validates the request schema, size, allowed state transition and rate limit.
4. The Worker derives the actor from the verified token; it never trusts a client-supplied user ID, role, grader assignment, credit balance or ownership claim.
5. Database operations use the authenticated user's JWT where supported so PostgreSQL RLS evaluates the actual user. Any narrowly privileged server operation must use a separately reviewed, server-only credential/role, expose only a specific operation, and independently re-check actor, scope and state.
6. PostgreSQL constraints, transaction rules and RLS remain the final data boundary. Storage policies independently enforce object access.
7. Return only fields permitted for the actor and workflow state. Never return service credentials, answer keys, private QA or unrelated learner data.

Do not rely solely on decoded JWT claims for mutable role assignments. Role revocation must take effect promptly; use database-backed role/assignment checks for sensitive operations or a documented short-lived claim-refresh design. Never let a user update their own role assignment.

## 3. Identity, roles and account lifecycle

### 3.1 Roles

Use the five approved roles and enforce least privilege:

| Role | Allowed scope | Explicitly denied |
|---|---|---|
| Student | Own profile, enrolments, attempts, own original submissions, own published feedback and permitted own progress | Other learners, unpublished feedback, answer keys before reveal, grader/admin functions |
| Guardian | Only records for a verified, active guardian–learner link and approved consent scope | Unlinked learners, private grader notes, owner QA, unrelated account data |
| Grader | Assigned submissions only; minimum task, rubric, original response and transcript data required to grade | Unassigned submissions, other graders' queue, private QA, provider-ranking data, role management |
| Admin | Minimum operational records and actions explicitly assigned to the admin function | Unnecessary full database access; owner-only QA unless separately granted |
| Owner / super-admin | Full authorised operational and QA access, with strong authentication and attributable audit | Unlogged or shared-account activity |

A role is an authorization grant, not a UI label. Implement role assignment in a protected table with user ID, role, grantor, granted time, revocation time, reason and status. Enforce allowed role values and prevent duplicate active assignments. Only the owner or a specifically authorised role-management operation may grant/revoke roles. Never accept a role from signup metadata or a client request.

Guardian links require verification, documented consent/authority state, active dates and revocation. A guardian relationship must not be inferred from matching names or email addresses. Grader access is assignment-scoped and time-bounded where appropriate.

### 3.2 Authentication controls

- Supabase Auth owns password storage and authentication lifecycle; GradiPrep never stores plaintext passwords.
- Support secure sign-in, sign-out, verified account recovery and session revocation.
- Require MFA for graders, admins and owner accounts before access to protected staff operations; prefer phishing-resistant MFA where supported and practical.
- Apply verified email/account invitation for staff; public signup can create only the least-privileged student state, subject to approved enrolment policy.
- Rate-limit sign-in, recovery, invitation and verification endpoints; use provider protections and abuse monitoring.
- Use secure browser session handling and avoid storing privileged tokens in application logs or analytics.
- Define account suspension, role revocation, compromised-account response and owner recovery procedures.
- Test stale sessions after role revocation, account suspension and guardian-link revocation.

MFA, recovery and email delivery configuration must be checked against current Supabase capabilities and cost/quotas before implementation. No paid email provider is implicitly approved.

## 4. PostgreSQL schema, constraints and RLS

The logical model in `DATA_MODEL.md` remains the domain authority. Phase 1 maps its relevant records to PostgreSQL; it does not author curriculum content or change academic taxonomies.

### 4.1 Initial protected table groups

Implement only the schema needed for secure account and assessment foundations. Do not build unrelated payment, marketing or full curriculum administration systems in Phase 1.

- Identity/access: `profiles`, `role_assignments`, `guardian_learner_links`, `course_enrolments`.
- Versioned task metadata: `tasks` / task versions, `rubrics` / rubric versions, `task_rubric_mappings`; keep answer keys in a restricted table/schema.
- Learner work: `attempts`, `attempt_responses`, `assessment_submissions`, `submission_versions`.
- Staff workflow: `grader_assignments`, `assessments`, `assessment_versions`, `criterion_results`.
- Evidence and controls: `learning_events` only where needed, `assessment_audit_events`, `admin_audit_log`, `private_qa_records`, and a minimal deletion/retention job ledger.
- Storage metadata: object ID/path, owning learner/submission, checksum, MIME/size/page count, lifecycle status and timestamps. Do not store raw file bytes in PostgreSQL.

Use UUID primary keys, foreign keys, unique constraints, check constraints and indexes for ownership/assignment joins. Store timestamps in UTC. Preserve immutable task/rubric/submission versions referenced by accepted work. Use transactions for submission acceptance, grader assignment, publishing feedback, role changes and deletion state transitions.

Do not implement a mutable client-controlled credit balance. If credits are later enabled, the append-only ledger and server-authoritative reservation/settlement rules in the data model apply; credit/payment activation is outside Phase 1.

### 4.2 RLS policy matrix

Enable RLS on every table containing account, learner, submission, response, grading, audit, role, guardian or private QA data. Default to deny. Write explicit SELECT/INSERT/UPDATE/DELETE policies per table; do not use a broad authenticated-user policy.

| Data | Student | Guardian | Grader | Admin | Owner |
|---|---|---|---|---|---|
| Own profile | Own only | Own only | Own only | Operational minimum | Authorised |
| Learner profile | Own | Verified linked learner, limited fields | Assigned submission context only | Minimum operational | Authorised |
| Attempts/responses/PDF | Own | Only if consent/link scope permits | Assigned submission only | Minimum operational | Authorised |
| Published feedback | Own | Verified linked learner only | Assigned work as permitted | Operational minimum | Authorised |
| Draft feedback/assessment | No | No | Assigned draft only | Only where role requires | Authorised |
| Answer keys/private QA | No, except designed answer reveal | No | No private QA; only required rubric/task | No by default | Authorised |
| Role assignments | No | No | No | No self-service; delegated only | Grant/revoke |
| Guardian links | No arbitrary writes | Own link state/limited view | No | Verify/revoke if delegated | Authorised |
| Audit records | No | No | No general audit access | Scoped operational events | Authorised |

For every policy, test both allowed and denied paths using actual authenticated test identities. Verify anonymous access is denied for private tables. Prevent users from changing owner IDs, learner IDs, grader IDs, status, published state, role, credit or timestamps to escape policy. Use database constraints/triggers or protected RPCs for immutable/server-owned fields.

Review any `SECURITY DEFINER` function individually: fixed safe search path, minimum owner privileges, explicit argument validation, no caller-controlled dynamic SQL, and tests for cross-tenant access. Avoid privileged bypass-RLS credentials in normal request paths. If a bypass is unavoidable for a narrowly scoped system operation, document why, restrict the operation, keep the key only in Worker secrets, and add explicit ownership/role checks plus audit events.

## 5. Protected API contract

The first implementation should expose a small, versioned Worker API. Exact route names may be adjusted during code review, but the authorization semantics are mandatory.

| Operation | Actor and checks | Data effect |
|---|---|---|
| `GET /api/v1/me` | Authenticated user | Own profile and effective permissions only |
| `GET /api/v1/me/roles` | Authenticated user | Own active role labels; no grantor secrets |
| `GET /api/v1/learner/submissions` | Student; derive learner ID from token | Own submission metadata only |
| `GET /api/v1/learner/submissions/:id` | Student ownership; published/allowed state | Own permitted submission and published feedback |
| `POST /api/v1/submissions` | Student; enrolment/task eligibility; server limits | Create submission draft/acceptance through transaction |
| `POST /api/v1/submissions/:id/accept` | Student owner; valid complete upload and capacity/entitlement checks | Server stamps accepted time and 24-hour due time; idempotent |
| `GET /api/v1/grader/queue` | Grader; assigned workload | Assigned submissions only, oldest accepted first |
| `GET /api/v1/grader/submissions/:id` | Active assignment and permitted state | Task, rubric, original response and required extraction only |
| `POST /api/v1/grader/submissions/:id/assign` | Delegated admin/owner only | Audited assignment transition |
| `POST /api/v1/grader/submissions/:id/feedback` | Assigned grader; schema and rubric validation | Save draft/publish only via explicit human action; version and audit |
| `POST /api/v1/admin/roles` | Owner/delegated role administrator; MFA | Audited grant/revoke |
| `POST /api/v1/admin/guardian-links` | Authorised verifier; evidence/consent workflow | Audited verify/revoke |
| `POST /api/v1/privacy/deletion-requests` | Verified subject/authorised guardian or owner workflow | Create request; do not synchronously erase unrelated records |

All write operations require schema validation, size limits, CSRF/origin protections appropriate to the chosen session pattern, rate limits and safe error handling. Use idempotency keys for acceptance, upload completion, assignment and feedback publication. Never trust client-supplied `accepted_at`, `grading_due_at`, role, assignment, ownership or audit actor. Server timestamps determine the 24-hour grading SLA.

Phase 1 may implement only the minimum endpoints needed to validate authentication, roles, protected reads/writes, audit and storage. The PDF workflow, OCR, AI suggestions, timer UI and full grading queue remain later phases.

## 6. Private Storage and file controls

Create private buckets only after separate infrastructure provisioning approval. Use a non-guessable object key that does not expose a learner's name, email or other personal identifier. Store an ownership mapping in PostgreSQL and enforce both Storage policies and application authorization.

Initial flagship pilot limits from Phase 0:
- PDF only; maximum 10 MB and 10 pages per submission.
- Validate extension, declared MIME and file signature; do not trust the browser's content type.
- Reject encrypted/password-protected or malformed files unless a later approved handling path is designed.
- Calculate and store checksum, byte size, page count and upload state.
- Use short-lived signed access only after the Worker verifies ownership/assignment and current permission. Do not expose permanent public URLs.
- Separate temporary/incomplete upload objects from accepted originals; clean abandoned uploads under a documented schedule.
- Keep the original accepted PDF immutable. Corrections or replacement submissions create a new version and audit record.
- Treat uploaded PDFs as untrusted content. Render safely; do not execute embedded scripts or external links. Apply content-disarm/validation review if selected tooling requires it.
- Avoid retaining temporary page rasters; Phase 0 requires deletion immediately after OCR processing in the later OCR phase.

Test that direct bucket access, guessed object paths, expired signed links, cross-learner paths and revoked grader assignments are denied. A signed URL is a bearer capability until expiry; use short expiry and do not log it.

## 7. Audit and operational security records

Create append-oriented, access-restricted audit events for:
- role grants/revocations, MFA/security administration and account suspension;
- guardian-link verification/revocation;
- privileged data access where technically available and policy-approved;
- submission creation, acceptance, version changes and deletion requests;
- grader assignment/reassignment;
- assessment draft/final/publish/edit and rubric/version references;
- storage upload, accepted-object access, deletion and backup/restore operations;
- retention jobs, legal holds, exceptions and completion evidence.

Each event should contain event ID, UTC timestamp, authenticated actor ID, actor role at event time, action, target type/ID, outcome, reason/category where required, correlation/request ID and minimal before/after references. Do not copy full learner responses, PDFs, passwords, tokens, signed URLs or unnecessary sensitive information into logs. Keep audit data separate from ordinary application telemetry; learners, guardians and graders cannot browse the general audit log.

Make application-level audit writes transactionally coupled to the action where possible. Restrict update/delete privileges on audit tables; test attempted tampering. Define retention for each audit class consistently with Phase 0's 12-/24-month records and any mandatory legal hold. The Phase 0 policy's 24-month feedback/version history and 12-month timer-event period must not be silently shortened.

## 8. Backup, encryption and recovery design

### 8.1 Database

- Supabase Free is the first plan to evaluate. Pro is an optional fallback only if no suitable free arrangement can meet an essential requirement; its current starting price, compute, backups, egress, storage, tax and overage must be rechecked and explicitly approved before activation.
- Confirm the actual daily backup schedule, seven-day retention and restore mechanism for the selected project/plan.
- Backups must include schema, data, constraints, policies, functions and migration history needed for a usable restore.
- Restrict backup/restore access to owner-authorised operators; record every restore.
- Do not treat a database backup as a file-object backup.

### 8.2 PDF objects

- Supabase private Storage is the primary store.
- Cloudflare R2 is the approved secondary PDF-object backup target only, not the primary store or database.
- Do not copy real learner objects to R2 until cross-border transfer, location, processor terms, encryption/key custody and privacy/legal approval pass.
- Back up only required original objects and metadata; verify checksums and object-to-database references.
- Encrypt backup objects before transfer using envelope encryption. Select and document a key-management/recovery method before implementation; keep key-encryption keys separate from R2 credentials and backups, restrict access, rotate under a documented procedure and test recovery. Do not invent a residency guarantee from R2's APAC location hint.
- Enforce the Phase 0 maximum 30-day backup expiry after source deletion. A deletion request must mark backup objects for expiry and retain only minimal non-content evidence.

### 8.3 Recovery targets and tests

Founder-approved numeric RTO/RPO values are not yet recorded. Before provisioning, propose and obtain explicit approval for:
- RPO: maximum acceptable time of learner-data loss;
- RTO: maximum acceptable service restoration time;
- backup frequency and independent verification frequency;
- owner/operator availability and recovery-key custody.

Do not claim a recovery target until demonstrated. Test a database restore and corresponding PDF-object restore into an isolated synthetic-data project/bucket. Verify schema/migrations, foreign keys, checksums, submission-to-file links, RLS, Storage policies, Worker configuration/secrets re-entry, audit continuity and sign-in. Test a partial restore and a failed/corrupt backup scenario. A restore test must not overwrite production or use real learner records.

## 9. Retention, deletion and account closure

Implement the exact Phase 0 retention schedule; do not create a conflicting period:
- Original PDF, raw extraction and corrected transcript: active enrolment, then 12 months after formal course completion, recorded withdrawal or administrative closure.
- Published feedback, rubric outcomes and feedback-version/edit audit history: 24 months after that formal end event.
- Event-level timer records: 12 months after the attempt.
- Temporary rendered page images: delete immediately after OCR processing.
- Azure analysis result: retrieve and promptly call its Delete Analyze Result API in the later OCR phase.
- Encrypted off-site PDF backups: expire within 30 days after source deletion.
- Verified deletion requests: action within 30 days, subject to documented legal hold.

Phase 1 must implement a deletion-request ledger and a controlled deletion workflow design. Verify the requester and scope; identify linked files, derived text, feedback and processor copies; apply legal hold only with reason, authority and review date; execute deletion/anonymisation; confirm backup expiry; retain only minimal non-content evidence. Do not erase assessment records prematurely or promise immediate physical erasure from immutable backups. Account closure must revoke sessions and access, resolve guardian/grader relationships, and invoke the approved record-retention workflow.

## 10. Synthetic-data security and acceptance tests

Use named synthetic identities for each role, at least two students, two guardians, two graders, one admin and one owner, plus unlinked/disabled accounts. All names, answers, files and identifiers must be fictitious. Include two tenants/courses where needed to test isolation.

Required tests:
1. Anonymous user cannot read or write protected tables, API routes or private objects.
2. Student A cannot read/change Student B's profile, attempt, response, submission, PDF or feedback by changing IDs, paths, payloads or HTTP methods.
3. Guardian A cannot access an unlinked learner; revoked/expired consent removes access promptly.
4. Grader A cannot read or modify an unassigned submission or another grader's private notes/QA.
5. Grader cannot access answer keys, provider rankings, private QA or owner-only administration.
6. Admin has only delegated operational scope; admin cannot grant self owner access.
7. Owner actions require MFA and produce attributable audit events.
8. Client cannot forge role, actor, ownership, assignment, accepted timestamp, due time, credit or published state.
9. Role revocation, account suspension and session expiry invalidate protected access as specified.
10. RLS tests cover SELECT, INSERT, UPDATE and DELETE for every sensitive table, including malicious ownership reassignment.
11. Storage tests cover public listing, guessed keys, expired signed URLs, wrong-user downloads, wrong-grader downloads, MIME spoofing, malformed/encrypted PDFs and 10 MB/10-page limits.
12. API tests cover invalid schema, oversized body, rate limits, replay, idempotency and concurrent acceptance/assignment/publish operations.
13. Audit tests cover missing events, actor attribution, restricted reads and attempted update/delete tampering.
14. Backup tests cover encryption, key separation, checksum validation, database plus PDF restore, retention expiry and deletion propagation.
15. Restore tests confirm RLS and Storage policies are active after restore; no test uses or restores production data.
16. Security regression suite runs in CI on every relevant PR and reports failures without exposing secrets or learner content.

Automate RLS and API tests in CI where feasible. Add a manual security review for policy coverage, privileged credentials, role escalation, key custody and restore evidence. No critical or high-severity security finding may remain open for Phase 1 acceptance unless the Founder explicitly accepts a documented exception after independent risk review.

## 11. Phase 1 delivery checkpoints and evidence

| Checkpoint | Deliverable | Required evidence / exit gate |
|---|---|---|
| 1A — Technical design lock | Reviewed schema map, endpoint contract, RLS matrix, threat model, secret inventory, migration/rollback and cost plan | Implementation scope is already Founder-approved. RTO/RPO targets remain proposals to resolve before real-data readiness; any hosted resource or paid account action is separately reviewed under the free-first policy. |
| 1B — Auth and roles | Supabase Auth integration, account lifecycle, role assignments, MFA/staff invitation controls | Synthetic sign-in, password recovery, suspended-account denial, global session revocation, owner TOTP/AAL2 role revocation, and secure staff invitation create/list/revoke/acceptance pass exact-head CI. The 24-case invitation SQL suite and 20/20 browser suite pass. Any future grader/admin protected operation must require AAL2 at the Worker/database boundary before it is exposed. |
| 1C — Protected API and database | Worker request validation, PostgreSQL schema, constraints, RLS, protected operations | Complete table-by-table RLS matrix and cross-role API tests pass |
| 1D — Private storage and audit | Private bucket policy, short-lived signed access, upload metadata/validation, append-only audit | Cross-account object denial and audit-integrity tests pass |
| 1E — Backup and recovery | Supabase database backup verification, R2 encrypted PDF backup design/implementation only after regional gate, deletion workflow | Isolated DB + object restore, checksum and deletion/expiry evidence pass |
| 1F — Security acceptance | Synthetic-data security regression, threat-model review, remediation and runbooks | No unresolved critical/high findings; Founder accepts evidence and authorises next phase separately |

Proceed through the approved checkpoints in sequence. Each code checkpoint requires reviewable CI and public Preview evidence. A checkpoint review does not re-authorise the plan or require repeated permission to begin the next in-scope implementation step. Keep PR #22 draft and unmerged until the Founder separately approves merge. No production deployment is included in Phase 1 approval.

**Verified completion — secure staff invitations (3 November 2026):** Owner-only AAL2 invitation creation, listing and revocation are implemented. Invitations are restricted to grader and admin, use a cryptographically random single-use token with only its SHA-256 hash stored, expire within seven days, and are accepted only by an active account whose Auth email is verified and matches the invitation, with an AAL2 session. Invitation and role changes are audited. All database access is through narrowly scoped SECURITY DEFINER RPCs with explicit authorization; the Worker uses only the caller-scoped client and no service-role/admin client. The local UI returns a copyable synthetic-only URL in a fragment, sends no email, and consumes the fragment on initial load or same-page navigation. Exact-head CI run [#41598979870](https://github.com/gradioprep/gradioprep-website/actions/runs/41598979870) passed all 24 invitation SQL checks and 20/20 browser tests on commit 1953bd1d9141f8033e00166cd10aee89a8d563e6. The public Preview remains disconnected from hosted Supabase; do not provision a hosted backend to make invitation actions work publicly. Remaining guardrail: any future grader/admin protected API or data operation must enforce AAL2 in its server/database authorization path and add corresponding cross-role tests. No grader/admin protected data workflow is introduced by this invitation slice.

## 12. Costs, account ownership and permissions

**Cost authority:** `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md` supersedes any earlier implication in this specification that Supabase Pro or another paid service is an assumed prerequisite. The architecture/provider selection remains approved; the paid plan is not.

### 12.1 Known and unknown costs

The binding budget rule is the free-first policy in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`: target US$0 recurring infrastructure subscriptions and paid API usage for the first 12 months from 3 November 2026, and review upgrades at 100+ subscribers without automatically purchasing them. Current service-by-service quotas, dated indicative prices and approval requirements are recorded in that policy.

- Supabase Free is the first plan to evaluate. Supabase Pro is an optional fallback, currently advertised from USD 25/month before additional compute/usage, only if no suitable free arrangement can meet an essential requirement. It is not an approved mandatory spend.
- Supabase Free inactivity pausing and missing automatic downloadable DB backups must be addressed with tested controls before real learner records. Database exports do not back up Storage API file objects.
- R2 Free may cover an early secondary backup volume, but regional-transfer and residency controls still apply; no real-data replication is authorised until they pass.
- Cloudflare Workers Free is the default while measured usage/CPU stays within its limits. Workers Paid currently starts at USD 5/month but is not an automatic upgrade.
- Azure OCR and Workers AI remain later features; use free quotas and manual fallback where feasible. S0 OCR, paid AI usage, PITR, KMS, paid email and other upgrades require a current price/usage estimate and explicit approval.
- Do not enable auto-upgrades, paid overage, spend-cap removal or automatic spend-limit increases. Do not infer spending approval from this architecture.


### 12.2 Account permissions

| Account | Minimum permission/action |
|---|---|
| GitHub | Repository write permission to create documentation/implementation branches and draft PRs; no merge or deployment permission needed for this planning step |
| Supabase | Founder/organisation owner for initial project and billing decisions; restricted developer access for implementation; separate production operator |
| Cloudflare | Existing Worker project access only when a separately approved implementation task requires it; R2/account billing owner only for later approved backup setup |
| Backup/key-management provider | Founder owns billing and recovery authority; backup operator receives least-privilege write/read/restore scope |
| Azure | No access or resource needed in Phase 1; later separate approval for OCR |
| Workers AI | No new endpoint or paid configuration in Phase 1; later separate approval |

Use individual named accounts, MFA and least privilege. Do not share passwords, recovery codes, service-role keys or encryption keys in chat, GitHub or source code.

## 13. Threat model and operational runbooks

Threat actors include unauthenticated internet users, malicious/compromised learners, compromised staff accounts, accidental staff misuse, exposed credentials, malicious PDF content, cross-tenant API mistakes, backup compromise and provider/service failure.

Primary mitigations: verified identity, least privilege, database RLS, private Storage policies, server-derived actor identity, short-lived object access, input/file validation, rate limits, secret isolation, MFA, audit trails, encrypted backups, tested restore and retention/deletion automation.

Before Phase 1 acceptance, document concise runbooks for:
- compromised account/session and role revocation;
- leaked key or secret rotation;
- suspected cross-learner access/data incident;
- malicious/invalid PDF and upload abuse;
- database/storage outage and restore;
- failed deletion or legal hold;
- backup integrity failure and recovery-key loss.

Incident response must preserve relevant non-content evidence, restrict access, assess notification obligations with qualified counsel and avoid placing learner content in incident tickets or chat.

## 14. Decisions required before hosted or real-data readiness

These are later operational decisions; they do not block local synthetic implementation already authorised within the approved plan:

1. Propose and agree numeric RTO/RPO targets and restore-test cadence before accepting real learner submissions. The current Phase 1A values are proposals, not approved commitments.
2. Test Supabase Free inactivity handling, manual database exports, file-object backups, full restore and capacity in the intended Mumbai configuration. Compare any failed requirement with the exact current Pro/backup quote only if no suitable free arrangement meets it.
3. Confirm the exact Worker-to-Supabase server access pattern and whether any privileged operation truly requires a server-only bypass credential.
4. Select and approve the envelope-encryption key-management/recovery method for any R2 object backups; evaluate suitable free options first and verify India transfer/residency implications before real-data use. AWS KMS remains an unselected candidate, not an approved provider.
5. Confirm account invitation, email verification and recovery delivery settings; use included/free delivery where suitable and disclose any unavoidable cost first.
6. Confirm whether a separate independent security reviewer is required; any external budget must be quoted and separately approved.
7. Complete qualified privacy/legal review of applicable India DPDP commencement/rules and learner/guardian notices before any real learner data or external processor use.

No item above authorises paid spend, hosted resource provisioning or real-data use by default. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.


## 15. Explicit out-of-scope items

Phase 1 does not implement PDF extraction/OCR, AI feedback drafts, the grading queue UI, the timer UI/analytics, curriculum diagnostics, report charts, remedial courses, payment/credit purchasing, commercial launch, public signup at scale or production rollout. It prepares the security foundation those later phases depend on.

**Diagnostic sequencing remains unchanged:** MYP Year 4 actual item authoring stays gated until the flagship feature is implemented and pilot-validated. Cambridge Grade 6 remains blocked until Cycle 1 is complete and the Founder directs transition.

## 16. Approval and change control

This specification records the Founder-approved implementation plan and its technical boundaries. The approved sequence authorises in-scope implementation through draft PRs, CI and synthetic Preview verification; Phase 1B local synthetic-only coding is explicitly approved. Do not ask again for approval of steps already included in that plan.

Separate approval is still required before:
- creating/configuring hosted service resources, even on a free tier where the current project record requires provisioning approval;
- purchasing/upgrading a plan, enabling chargeable use, permitting overages or changing spend limits;
- processing real learner data or sending learner content to external processors;
- changing the approved provider, region, database, backup target, retention, role boundary or data-processing scope;
- merging a PR, deploying to production, changing DNS or launching publicly.

The free-first policy in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md` governs every proposed service cost. No item in this specification implies spending authority.

Any change to the approved provider, region, database, backup target, retention, role boundary or data-processing scope requires a documented decision and reconciliation of every dependent source-of-truth record.



## 17. Build-ready execution path — 3 November 2026

**Verified Phase 1B MFA and secure staff-invitation checkpoint — 3 November 2026:** PR #22 remains open, draft and unmerged on feature/phase-1b-local-auth-api. Exact verified commit: 1953bd1d9141f8033e00166cd10aee89a8d563e6. GitHub Actions run [#41598979870](https://github.com/gradioprep/gradioprep-website/actions/runs/41598979870) passed on that exact SHA. The run passed a fresh local Supabase reset/seed, PostgreSQL RLS and the 24-case staff-invitation pgTAP suite, TypeScript/Vite/Worker build, 20/20 Playwright tests, local-stack shutdown, local credential-file cleanup and clean public-Preview build. Browser coverage includes owner AAL1 denial, owner AAL2 create/list/revoke, duplicate and email-mismatch denial, verified invitee TOTP/AAL2 acceptance, revoked/expired/replay denial, anonymous/admin denial, and same-page invitation-link consumption. The code stores only a SHA-256 hash of a 256-bit random invitation token, limits roles to grader/admin, caps expiry at seven days, requires a verified matching email and AAL2 to accept, and audits invitation/role changes. No real email is sent; no service-role client is present. The run was triggered by branch push, so its explicit PR Preview steps were skipped; Cloudflare Workers Builds independently deployed the same exact revision. Stable branch Preview: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. Immutable Preview: https://98207523-gradioprep-website.wandering-scene-1822.workers.dev (deployment 98207523-8ea0-46c8-a6c7-20e3d9ea15f0). The public Preview is disconnected from hosted Supabase and deliberately shows the safe backend-unavailable account state. Verify the website shell/navigation there; verify authenticated invitation interactions only against local synthetic Supabase in CI. Do not enter credentials or real learner data. No hosted resources, paid service, real learner data, external email, merge, production deployment or DNS change occurred.


## 18. Mandatory public Preview verification

All Phase 1 implementation work must follow `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`. Each meaningful code PR must pass local/CI checks, deploy a per-PR Cloudflare Worker Preview with `npx wrangler preview`, and provide the Founder with a concise non-coder verification handoff. Public inspection is expected after each useful vertical slice; do not wait until Phase 1 is wholly complete. The workflow `.github/workflows/controlled-worker-preview.yml` is restricted to same-repository owner-authored PRs on the approved base branches, uses the existing Worker Preview capability, posts the PR Preview URL and cleans up when the PR closes. It must never call the production deploy command, change DNS or provision another service.

For Phase 1B, local Supabase Auth/PostgreSQL/Storage with synthetic records is authoritative for backend tests. A public Preview cannot connect to that local stack. Verify UI/routes/Worker routing/safe failure states publicly, and validate actual sign-in, identity, RLS and storage permissions in local CI. A hosted synthetic backend is a separate approval gate. Public Preview URLs are not access-controlled by their no-index header and must contain no sensitive data. Custom domain remains a later, separately approved Production Cutover action.

**PR #22 previous Preview record — 3 November 2026 (superseded by Section 19):** At that point, the branch Preview used application code from verified commit `1953bd1` and the then-current docs-only commit `e217143`. Cloudflare Workers Builds succeeded; stable branch URL: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev; immutable current deployment: https://afeb0448-gradioprep-website.wandering-scene-1822.workers.dev (deployment `afeb0448-1d68-4e3e-95ff-41f252470508`). The GitHub Actions run [#41600693673](https://github.com/gradioprep/gradioprep-website/actions/runs/41600693673) passed all local-Supabase, RLS, build and 20/20 browser tests on the same docs-only head. The application has no hosted Supabase authentication/backend connection; the public account page deliberately displays the safe backend-unavailable state. Invitation UI and Auth flows are exercised only against local synthetic Supabase in CI. Do not enter credentials or real learner data. This Preview is not production-ready and does not authorise hosted provisioning, paid services, merge, production deployment or DNS changes.

**Previous branch-tip deployment — 3 November 2026 (superseded by Section 19):** The documentation-only revision `e21714371065e290b9912828ba89610688d4f668` passed exact-head CI run [#41600693673](https://github.com/gradioprep/gradioprep-website/actions/runs/41600693673) and was deployed by Cloudflare Workers Builds. Immutable deployment recorded at that time: `https://afeb0448-gradioprep-website.wandering-scene-1822.workers.dev` (deployment `afeb0448-1d68-4e3e-95ff-41f252470508`); stable branch alias: `https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev`. This documentation-only deployment contains the same application code as verified code commit `1953bd1`; it has no hosted Supabase/Auth connection. The public account screen intentionally shows the backend-unavailable state. Founder visual/functional review of the shell, navigation and safe account-unavailable state is the immediate next gate; do not enter credentials or real learner data.

## 19. Historical Phase 1B exact-head correction and Founder review record — 3 November 2026 (superseded by Section 20)

**Historical note:** The pending Founder visual/functional review stated below was subsequently approved on 3 November 2026. The branch head, CI evidence, Preview deployment and current Phase 1C progress are superseded by Section 20. This section is retained as a dated audit record.

**Exact current branch state:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, at commit `edae7fc4fdbaa62712a6e3e052ef5117d9aa3293`. The homepage sign-in entry was simplified to **“Sign in”**, with its arrow marked decorative for assistive technology. A regression test checks the exact accessible button name, navigation to `/account`, and the expected account page heading.

**Verified CI:** GitHub Actions run [#41604461931](https://github.com/gradioprep/gradioprep-website/actions/runs/41604461931) passed on that exact SHA. It passed isolated local Supabase startup, fresh reset and synthetic seed, PostgreSQL RLS, TypeScript plus Worker/Vite build, **21/21 Playwright tests**, local Supabase shutdown, deletion of `.dev.vars` and `.env.local`, and the clean public-Preview build. The Playwright suite includes the new homepage sign-in regression together with direct pathway-route coverage, Previous/Next and browser-history navigation, intentionally unavailable IGCSE grade-equivalent routes, the account/API flows and all existing local MFA/staff-invitation tests. This does not repeat or expand the completed invitation implementation. An earlier regression-test attempt failed before browser execution because of an over-escaped regular-expression literal; the test was rewritten using exact URL-path and heading assertions, and this final exact-head run passed.

**Verified Cloudflare Preview:** Cloudflare Workers Builds independently completed a successful build and deployment for `edae7fc`. Immutable Preview: https://0898c277-gradioprep-website.wandering-scene-1822.workers.dev (deployment `0898c277-3d4c-4d21-9496-f2e0215e0701`, 3 November 2026 at 08:36:17 UTC). Stable branch alias: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. The public Preview has no hosted Supabase/Auth connection; its safe backend-unavailable Account state is intentional. Do not enter credentials, invitation links or real learner data. Actual Auth, MFA, role, RLS and invitation operations remain tested only against local synthetic Supabase in CI.

**Pending Founder gate:** Automated checks and deployment do not constitute a visual review. The Founder must inspect the exact Preview for the homepage and Sign in entry; pathway catalogue and direct routes; Previous/Next and browser Back/Forward; and direct `/account` with its safe backend-unavailable state. Record any visual/functional findings and correct/redeploy the same PR before closing this gate. The review has not yet been recorded as complete.

**Next implementation checkpoint after Founder review:** proceed to **Phase 1C — protected API and database** under the already-approved sequence. Implement only the minimum scoped protected operations; complete the table-by-table default-deny RLS matrix and actual cross-role allow/deny tests; derive actor and ownership from verified server identity; reject caller-controlled ownership, role, assignment, state and timestamps; and validate requests at the Worker boundary. Every future privileged grader/admin API or database operation must require **AAL2 at both applicable Worker and database authorization boundaries**, with negative tests for anonymous, student, guardian, grader, admin, owner/AAL1 and owner/AAL2 contexts as applicable. Preserve least privilege, audit events and caller-scoped access; do not introduce a service-role bypass without a separately documented and approved necessity. Staff-invitation work remains complete and is not to be reimplemented.

No hosted service/resource, paid usage, real learner data, external email/AI/OCR processing, PR merge, production deployment or DNS/custom-domain change is included or authorised by this checkpoint.


## 20. Verified Phase 1C first vertical slice and remaining completion gates — 3 November 2026

**Current branch and approval state:** PR #22 is open, draft and unmerged on `feature/phase-1b-local-auth-api`. The exact Phase 1C code commit is `05544d1a394e2e480b7cd2dd9f55100b6998ee71`. The Founder-approved implementation sequence permits in-scope local synthetic coding and CI without repeated approval. The Phase 1B public-shell visual/functional review is approved; that approval does not mean the broader Phase 1 security gates are complete.

**Implemented first slice:** Migrations `20261103000300_phase_1c_attempts_and_grader_access.sql`, `20261103000400_phase1c_response_version_archive.sql` and `20261103000500_phase1c_attempt_creation_rpc.sql` add versioned typed-task prompts, learner-owned `attempts` and `attempt_responses`, active/revoked `grader_assignments`, and private `private.attempt_response_versions`. Worker operations cover learner attempt list/create/read, typed-response save and submit, grader queue/detail, and owner assignment. Database RPCs are `create_attempt`, `save_attempt_response`, `submit_attempt` and `assign_attempt_to_grader`. Task/enrolment eligibility, actor identity and learner ownership are checked server/database-side; response word counts, response version numbers and timestamps are database-generated. Previous response values are archived in an append-only private table. Attempt creation and privileged assignment are narrow database operations; direct client response/assignment mutations are not the security boundary.

**Authorization and isolation evidenced:** Learners can access only their own permitted attempts; guardian access requires an active verified link and explicit submission-view consent, and is limited to that learner. A grader can read only active assigned submitted work, and grader queue/detail require AAL2 at the Worker and database/RLS layers. Owner attempt inspection and grader assignment require AAL2 at both boundaries. Admin does not implicitly inherit grader or learner access. The Worker uses the caller-scoped client; no service-role client was introduced. The current slice is not the full human-assessment, PDF-submission, rubric or feedback-publication workflow.

**Exact-head verification:** GitHub Actions run [#41613490244](https://github.com/gradioprep/gradioprep-website/actions/runs/41613490244) passed on `05544d1a394e2e480b7cd2dd9f55100b6998ee71`: **116 PostgreSQL/pgTAP assertions across four SQL test files; 24/24 Playwright tests**; fresh local Supabase reset and synthetic seed; TypeScript, Worker and Vite builds; clean shutdown and local credential-file cleanup; and clean public-Preview build. The tests cover learner ownership and forged fields, typed response versioning and post-submit edit denial, guardian link/consent scope and role denial, grader assignment isolation/AAL1 denial/AAL2 access, admin separation, owner AAL1 denial/AAL2 access and assignment controls.

**Cloudflare public Preview:** Cloudflare Workers Builds independently deployed the same application revision. Immutable Preview: https://b4391d8e-gradioprep-website.wandering-scene-1822.workers.dev (deployment `b4391d8e-bffe-4ad2-94d5-bd1e92117931`, deployed 3 November 2026 at 09:45:10 UTC). Stable branch alias: https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. It is disconnected from hosted Supabase and shows the safe backend-unavailable account state; protected interactions were tested only against local synthetic Supabase. Do not enter credentials, invitation links or real learner data. Do not claim that hosted authentication, database or grader operations work in the Preview.

**Remaining Phase 1C work — all required before Phase 1D:**

1. Complete and reconcile the full table-by-table permission/RLS matrix for every protected identity, enrolment, attempt, submission, grading, feedback, audit and QA record. Test relevant SELECT/INSERT/UPDATE/DELETE paths at both Worker and database boundaries; keep default-deny and least privilege.
2. Complete the accepted assessment/submission data lifecycle and immutable links to exact task, rubric and content versions. Preserve submission versions and server-owned accepted/due timestamps. Keep typed practice attempts distinct from human-assessment submissions and later PDF object storage.
3. Complete the grader workflow beyond queue/detail: authorised assignment, reassignment/revocation, work-state transitions, rubric/criterion-level results and saved drafts. Preserve immutable assessment/feedback versions and allow learner visibility only after explicit authorised human publication.
4. Enforce role separation: graders see only active assignments; operational admins receive only explicitly scoped operational access and do not inherit grader, owner or private academic-QA permissions; private QA remains owner/explicitly authorised only.
5. Implement append-oriented audit evidence for privileged reads where feasible and for assignments, submissions, grading changes, publication, role/link changes and administrative actions, without logging learner response content or secrets.
6. Implement server-authoritative capacity and the approved fixed 24-hour grading SLA: acceptance checks capacity before commitment; accepted time and due time are immutable snapshots; idempotency prevents duplicate acceptance; queue ordering is oldest accepted first; never accept work that cannot meet the promised SLA.
7. Expand synthetic cross-role and negative testing across anonymous, student, guardian, assigned/unassigned/revoked grader, admin, owner AAL1/AAL2 and suspended accounts. Include cross-learner/grader isolation, consent/revocation, manipulated ownership/role/state/timestamps, replay, concurrency and direct-table/RPC bypass attempts.
8. After each coherent slice, run the complete local Supabase reset/seed and SQL/API/browser/build/cleanup checks, deploy the public Worker Preview, and provide the Founder with the exact commit, immutable URL, backend limitation and concise review instructions. Update all dependent source-of-truth records after verified changes.

**Phase 1C exit gate:** Phase 1C is not complete merely because the current first-slice run passed. Do not begin Phase 1D until every Phase 1C item above is implemented, cross-role/security-tested, documented and reviewed against this specification. Phase 1D private file/storage controls, PDF validation (10 MB/10 pages), private object access, backup/recovery and file-retention work remain subsequent work. Any hosted Storage/R2/resource provisioning, paid usage, external processing or real learner data requires its separate explicit approval; no such provisioning is authorised here.


### 20.1 Phase 1C physical inventory, default-deny matrix and remaining scope — 3 November 2026

This inventory is grounded in migrations present on the current PR #22 branch. It is a security inventory, not a declaration that every logical record in `DATA_MODEL.md` has been created.

**Physically implemented protected records**

| Schema/table | Implemented purpose | Current access boundary |
|---|---|---|
| `public.profiles` | Account profile/status | Authenticated self-read and own display-name update; owner-scoped operational access as policy permits |
| `public.role_assignments` | Application role grants/revocations | Self/owner-scoped read; no direct browser mutation; protected owner AAL2 RPC for revocation |
| `public.guardian_learner_links` | Verified guardian relationship and consent scopes | Participant/owner-scoped read; no direct browser mutation |
| `public.course_enrolments` | Learner pathway enrolment | Learner/guardian/owner-scoped read; no direct browser mutation |
| `private.security_audit_events` | Append-only security/role/attempt events | No direct browser table access; trigger/RPC append only |
| `private.staff_invitations` | Single-use staff invitation lifecycle | No direct browser table access; narrow owner AAL2/verified-invitee RPCs |
| `public.task_versions` | Immutable typed task version metadata | Published task read for eligible active roles; owner inspection requires AAL2 |
| `public.task_version_prompts` | Version-bound typed prompts | Published task prompt read; owner inspection requires AAL2 |
| `public.attempts` | Learner-owned typed practice attempts | Learner own, guardian consent/link scope, assigned grader AAL2, owner AAL2; narrow creation/submission RPCs |
| `public.attempt_responses` | Current typed response per prompt | Same attempt scope; response mutation only through learner-owned save RPC |
| `public.grader_assignments` | Active/revoked attempt-to-grader assignment | Assigned grader AAL2 and owner AAL2 read; assignment only through owner AAL2 RPC |
| `private.attempt_response_versions` | Append-only prior response snapshots | RLS enabled, no browser grants; database trigger appends versions |

**Default-deny role matrix for the implemented records**

| Record group | Anonymous | Student | Guardian | Grader | Admin | Owner AAL1 | Owner AAL2 |
|---|---|---|---|---|---|---|---|
| Own profile | Deny | Own only | Own only | Own only | Own only | Deny privileged view | Authorised owner scope |
| Role assignments | Deny | Own read | Own read | Own read | Own read | Deny privileged view | Owner-scoped read/revoke |
| Guardian links | Deny | Participant scope | Participant scope | Deny | Deny | Deny privileged view | Owner scope |
| Enrolments | Deny | Own only | Linked learner + consent scope | Deny | Deny | Deny privileged view | Owner scope |
| Published task versions/prompts | Deny | Eligible published tasks | Published task metadata only where link scope permits | Published task metadata needed for assigned work | Deny | Deny owner-only draft view | Owner inspection |
| Attempts/responses | Deny | Own only | Active verified link + explicit submission consent | Active assigned submitted work only, AAL2 | Deny | Deny | Owner inspection, AAL2 |
| Grader assignments | Deny | Deny | Deny | Own active assignment only, AAL2 | Deny | Deny | Owner inspection, AAL2 |
| Private audit/invitation/version archives | Deny | Deny | Deny | Deny | Deny by default | Deny | Narrow owner RPCs only where explicitly defined; no general table grants |

This matrix records intended minimum access and must be verified against PostgreSQL grants, RLS policies, RPC execution grants and Worker route checks. Any unlisted operation is denied. Admin does not inherit grader, owner or private academic-QA rights. Owner AAL2 is required independently at Worker and database boundaries for privileged operations; a UI check or Worker-only check is insufficient.

**Not yet physical / not yet complete in Phase 1C:** accepted human-assessment submissions; immutable accepted submission versions; capacity slots/ledger reservations; server-fixed accepted/due timestamps and 24-hour SLA events; rubric/rubric-version and task-rubric mapping; grader assignment lifecycle for submissions; assessment/assessment-version and criterion-result records; versioned human feedback with draft/publish states; learner-visible published-feedback reads; scoped admin workflow; private academic-QA records; expanded append-oriented audit events; idempotency keys; oldest-accepted-first submission queue; and comprehensive cross-role/AAL1/AAL2 adversarial tests. These remain implementation work, not live schema. PDF objects, OCR, private file access and file-retention processing remain Phase 1D or later.

The current protected inventory at this checkpoint is 12 tables total: nine public and three private. Phase 1C added five public tables (`task_versions`, `task_version_prompts`, `attempts`, `attempt_responses`, `grader_assignments`) and one private table (`attempt_response_versions`); the other four public and two private tables are Phase 1B records. No other assessment/submission/feedback tables are implied by the logical model. Reconcile this inventory after each migration and test milestone.

### 20.2 Verified Phase 1C-A protected-table security baseline — 3 November 2026

**Code and policy changes:** Migration `20261103000600_phase1c_role_scope_hardening.sql` replaces broad published-task reads with a single resource-scope helper: students require an active enrolment for the task pathway; guardians require an active verified link plus explicit submission-view consent and an associated learner attempt; graders require AAL2 and an active assignment to submitted work for that task; owner inspection requires AAL2. Admin receives no implicit learner/task access. The same migration makes owner-wide reads of profiles, role assignments, guardian links and enrolments require AAL2 inside PostgreSQL; own/participant-scoped reads remain available under their own role rules.

Migration `20261103000700_phase1c_private_audit_and_revoked_assignment_rls.sql` enables RLS on `private.security_audit_events` without creating a browser-facing policy, and replaces the grader assignment read policy so a grader can see only their active assignment row(s) at AAL2. Owner inspection of active/revoked assignment records remains AAL2-only. Private audit writes continue through existing SECURITY DEFINER trigger/RPC paths; no client table grants are added.

**Actual role and operation tests:** `protected_table_permissions.test.sql` checks the 12 protected tables, RLS flags, anonymous/private direct grants and denied direct mutations. `role_scoped_access.test.sql` checks student/guardian/grader/admin/owner visibility against synthetic data, cross-learner isolation, consent and link revocation, AAL1/AAL2 boundaries, grader assignment revocation, admin separation and suspended-account denial. The existing identity, attempt, invitation and role-revocation tests remain in the suite. The combined suite passed **215/215 pgTAP assertions across six SQL files**.

**Exact-head verification:** run [#41646515558](https://github.com/gradioprep/gradioprep-website/actions/runs/41646515558) passed on `ee275ca714c9bfb6bb44f580c2b1e827106975d4`: local Supabase migration/reset/seed, 215/215 PostgreSQL assertions, TypeScript/Worker/Vite build, 24/24 Playwright tests, Supabase shutdown, local credential cleanup and clean public-Preview asset build. No hosted Supabase service was used.

**Cloudflare Preview:** immutable URL https://f26a4358-gradioprep-website.wandering-scene-1822.workers.dev; stable branch alias https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. The Preview is disconnected from hosted Supabase; it proves the public shell/build only. Authenticated role and RLS behaviour was tested against local synthetic Supabase in CI. This Preview has not yet had Founder visual verification for this new revision.

**Scope still open:** this is a verified security hardening baseline for the currently implemented 12 protected tables, not completion of every future operation or Phase 1C. Submission, rubric, assessment, criterion, feedback, delegated admin and private academic-QA records do not yet exist physically; their own grants/RLS/Worker policies and tests must be added with their migrations. Full privileged-read audit coverage, capacity/idempotency, the fixed 24-hour SLA and adversarial replay/concurrency tests also remain incomplete. Continue to keep Phase 1D blocked.

