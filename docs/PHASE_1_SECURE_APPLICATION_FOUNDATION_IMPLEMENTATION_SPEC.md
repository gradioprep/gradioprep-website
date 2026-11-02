# Phase 1 — Secure Application Foundation Implementation Specification

**Version:** 0.2-draft  
**Date:** 2 November 2026  
**Status:** Founder-approved planning specification; Phase 1A build-ready execution plan is in `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`. Implementation is still NOT authorised by this document. No code, accounts, services, paid plans, real learner data, merge or deployment are included.  
**Parent decision register:** `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`  
**Related records:** `docs/PROJECT_MASTER_BRIEF.md`, `docs/DATA_MODEL.md`, `docs/FLAGSHIP_PDF_RESPONSE_GRADING_AND_TIMED_ANALYTICS_SPEC.md`, `docs/DIAGNOSTIC_AND_REMEDIAL_LEARNING_READINESS_STANDARD.md`, `docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md`, `docs/ENGLISH_STAGE_1_ROADMAP.md` and `docs/DESIGN_SPEC.md`.

## 1. Purpose and non-negotiable boundaries

Phase 1 establishes the security and persistence foundation required before PDF submission, OCR, human grading, feedback history, timed analytics or real learner accounts can be used.

This is an implementation blueprint, not a claim that any component exists. The approved Phase 0 choices remain binding. Do not substitute providers or regions, add a second application database, or widen the approved scope without a recorded Founder decision.

**Current authorisation:** planning, documentation and review only. This approval does not authorise:
- application, SQL, migration, Worker or infrastructure code;
- creating/configuring Supabase, R2, Azure or other service resources;
- purchasing/upgrading a plan, enabling paid usage or changing spend limits;
- connecting real learner accounts or processing real learner data;
- sending learner content to OCR, AI or backup processors;
- merging any PR, deploying, changing DNS or changing Cloudflare production configuration.

Use fictional/synthetic data only for all future development and hosted previews until separate privacy, security and live-pilot approvals are recorded.

## 2. Approved architecture and system boundaries

| Layer | Approved responsibility | Explicit exclusions |
|---|---|---|
| React/Vite client | Learner/staff UI; obtains and presents authenticated session; calls protected APIs | No privileged credentials, direct privileged writes or trusted role decisions |
| Cloudflare Workers | Existing app hosting and lightweight API/orchestration; authenticate requests, validate inputs, enforce operation-level authorization and call approved backend interfaces | No heavy PDF/OCR processing; no second database; no client-exposed secrets |
| Supabase Auth | Identity, sessions, password recovery and MFA support | Application roles must not be self-selected at signup |
| Supabase PostgreSQL, Mumbai `ap-south-1` | Single application database; constraints, transactions, RLS, audit records and versioned learning records | No Cloudflare D1 or parallel application database |
| Supabase private Storage, same project | Primary private source-PDF and response-object storage | No public learner buckets or permanent public object URLs |
| Supabase Pro | Required before real learner records; fresh plan/compute/usage quote and explicit budget approval first | Free plan is synthetic/development only |
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

- Supabase Pro is required before real learner records; reconfirm current plan, compute, backup retention, restore options and price at provisioning.
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
| 1A — Technical design lock | Reviewed schema map, endpoint contract, RLS matrix, threat model, secret inventory, migration/rollback and cost plan | Founder approves implementation scope, RTO/RPO proposal and any paid plan/account action separately |
| 1B — Auth and roles | Supabase Auth integration, account lifecycle, role assignments, MFA/staff invitation controls | Synthetic login, recovery, revocation and role-escalation tests pass |
| 1C — Protected API and database | Worker request validation, PostgreSQL schema, constraints, RLS, protected operations | Complete table-by-table RLS matrix and cross-role API tests pass |
| 1D — Private storage and audit | Private bucket policy, short-lived signed access, upload metadata/validation, append-only audit | Cross-account object denial and audit-integrity tests pass |
| 1E — Backup and recovery | Supabase database backup verification, R2 encrypted PDF backup design/implementation only after regional gate, deletion workflow | Isolated DB + object restore, checksum and deletion/expiry evidence pass |
| 1F — Security acceptance | Synthetic-data security regression, threat-model review, remediation and runbooks | No unresolved critical/high findings; Founder accepts evidence and authorises next phase separately |

A checkpoint can be held for review without starting the next. Each code checkpoint requires a separate draft PR and reviewable CI. Keep PRs draft and unmerged until the Founder separately approves the relevant merge. No production deployment is included in Phase 1 approval.

## 12. Costs, account ownership and permissions

### 12.1 Known and unknown costs

- Supabase Pro is the approved live-data prerequisite, advertised in Phase 0 from USD 25/month. Reconfirm current subscription, selected compute, backups, egress, storage, tax and overage before provisioning. No plan has been purchased.
- R2 charges depend on stored object volume and operation counts; the APAC hint does not guarantee India residency. No real-data replication is authorised.
- Cloudflare Workers may incur usage charges depending on current plan/traffic; existing hosting is not approval for new paid features or spend-limit changes.
- MFA/email delivery, independent key management, security monitoring and external review may add costs. Confirm exact provider and quote before selection.
- Azure OCR and Workers AI are later phases and are not to be provisioned or enabled as part of Phase 1.
- Do not enable auto-upgrades, paid overage or automatic spend-cap increases.

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

## 14. Decisions still required before implementation

These are genuine unresolved operational choices, not permission to change the approved architecture:

1. Founder approval of numeric RTO/RPO targets and restore-test cadence.
2. Confirm Supabase Pro price/compute/backup details for the chosen Mumbai project at the time of provisioning.
3. Confirm the exact Worker-to-Supabase server access pattern and whether any privileged operation truly requires a server-only bypass credential.
4. Select and approve the envelope-encryption key-management/recovery method for R2 object backups; verify India transfer/residency implications before real-data use.
5. Confirm account invitation, email verification and recovery delivery settings and any associated provider cost.
6. Confirm whether a separate independent security reviewer is required and approve the budget if so.
7. Complete qualified privacy/legal review of applicable India DPDP commencement/rules and learner/guardian notices before any real learner data or external processor use.

No item above permits provisioning by default. The Founder must separately approve implementation and any chargeable account action.

## 15. Explicit out-of-scope items

Phase 1 does not implement PDF extraction/OCR, AI feedback drafts, the grading queue UI, the timer UI/analytics, curriculum diagnostics, report charts, remedial courses, payment/credit purchasing, commercial launch, public signup at scale or production rollout. It prepares the security foundation those later phases depend on.

**Diagnostic sequencing remains unchanged:** MYP Year 4 actual item authoring stays gated until the flagship feature is implemented and pilot-validated. Cambridge Grade 6 remains blocked until Cycle 1 is complete and the Founder directs transition.

## 16. Approval and change control

This specification is a planning deliverable prepared after the Founder approved the Phase 1 plan in principle. It does not grant implementation, provisioning, spending, data-processing, merge or deployment authority.

Before any implementation begins, the Founder must separately approve:
- the reviewed technical design and unresolved operational decisions;
- the named implementation checkpoint(s);
- the exact services/accounts and any costs;
- the synthetic-data test scope;
- the repository/PR branch scope.

Before real learner data, external OCR/AI processing, R2 replication, live pilot, merge or deployment, obtain the separate approvals and legal/privacy/quality evidence defined by the Phase 0 register and flagship specification.

Any change to the approved provider, region, database, backup target, retention, role boundary or data-processing scope requires a documented decision and reconciliation of every dependent source-of-truth record.


## 17. Build-ready execution path — 2 November 2026

The exact repository starting point, local-first implementation path, API/client integration choices, initial schema/RLS slice, test fixtures, CI plan, proposed RTO/RPO and current cost scenarios are specified in `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`. That document is the engineering handoff for the next coding step. The first slice is local-only with Supabase CLI and synthetic data; it requires a Docker-compatible runtime but no hosted Supabase project or paid account. It adds the Cloudflare Worker API entrypoint while retaining Static Assets and React route behavior, browser Auth with `@supabase/supabase-js`, Worker request authentication through the current `@supabase/server` pattern, and the first profile/role/RLS migration and tests. The service-role key is not required. No implementation has started. A separate explicit Founder approval is still required before the first code commit. Proposed production RTO/RPO targets and AWS KMS are not approved decisions; they block real-data backup readiness, not local synthetic coding.
