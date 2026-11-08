# Phase 1 — Secure Application Foundation Implementation Specification

> **Current execution checkpoint — 8 November 2026 (authoritative active status; older milestone records remain historical):** PR #22 is open, draft and unmerged; head branch `feature/phase-1b-local-auth-api`, base `docs/phase-1-secure-foundation-spec`. Live remote head at this checkpoint: `acfde1e9572d5149e8d4a857bfb32032db1dc45a`. The last recorded local checkout SHA is `2a582c42c071a7dda85d197672e9255398e55140`; the local branch/working-tree/head must be checked and fast-forwarded with `git pull --ff-only origin feature/phase-1b-local-auth-api` if behind. **Node.js setup is complete:** Node `v22.23.4`, npm `10.9.9`; both executables resolve inside `/home/gradioprep/.nvm/versions/node/v22.23.4/bin/`. Do not reinstall Node. Project dependencies have not yet been confirmed installed; run `npm install --no-audit --no-fund` only after verifying the checkout, then inspect tracked changes and lockfile status. **Do not start Supabase yet:** assess the reduced-service stack against the PC's 8 GB DDR4 RAM and the previously reported approximately 2.8 GiB available to Docker/Ubuntu; do not change memory limits. Phase 1C is complete; Phase 1D is verified; Phase 1E remains partial/unverified, including the 35- and 47-assertion SQL suites and backup/restore verifier. Exact-head Actions run [#42461053863](https://github.com/gradioprep/gradioprep-website/actions/runs/42461053863) failed with no job steps reported; runner-assignment metadata/logs were not retrievable, so do not classify it as a test failure or claim a runner ID. Earlier run [#42460447569](https://github.com/gradioprep/gradioprep-website/actions/runs/42460447569) is separately confirmed as a pre-runner-assignment failure (runner ID 0, zero steps). The workflow still targets `ubuntu-latest`; runner registration alone does not redirect jobs. A workflow change requires separate security review. All five GitHub spending budgets remain blocked. Local Supabase and synthetic data only; all existing hosted-service, paid-use, real-data, DNS, deployment and merge restrictions remain in force.


**Version:** 0.31-draft
**Date:** 8 November 2026  
**Status:** PR #22 remains open, draft and unmerged. Phase 1C is complete, Phase 1D is verified and Phase 1E remains partial/unverified. WSL-native Node 22.23.4/npm 10.9.9 installation is complete; local checkout fast-forward status and dependency installation remain to be verified. Do not start Supabase before the 8 GB PC / approximately 2.8 GiB Docker-visible memory assessment. Exact-head run #42461053863 failed without job steps reported; it is not test evidence.nthetic-data foundation is complete. Verified application-code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` passed exact-head CI [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858): 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests, including both synchronized Phase 1C-F races. The pre-closeout documentation baseline `61f99b4f010af691a5e6b731d6bd14b7ce4a539c` passed exact-head CI [#42166224976](https://github.com/gradioprep/gradioprep-website/actions/runs/42166224976) with the same database/build/browser checks, local-stack shutdown, local credential cleanup and credential-free public asset build. Phase 1C-E audit correlation is representative per distinct action, not exhaustive outcome coverage. Phase 1D private PDF/file controls are verified at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`; exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) passed 519 PostgreSQL/pgTAP assertions, TypeScript/Worker/Vite builds, 31/31 Playwright tests and cleanup. PR #22 remains open, draft and unmerged. No hosted provisioning, paid usage, real learner data, external processing/email, Preview/production deployment or DNS change is authorised.

**Parent decision register:** `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`  
**Related records:** `docs/PROJECT_MASTER_BRIEF.md`, `docs/DATA_MODEL.md`, `docs/PHASE_1C_ENDPOINT_AUTHORIZATION_AUDIT_MATRIX.md`, `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md`, `docs/FLAGSHIP_PDF_RESPONSE_GRADING_AND_TIMED_ANALYTICS_SPEC.md`, `docs/DIAGNOSTIC_AND_REMEDIAL_LEARNING_READINESS_STANDARD.md`, `docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md`, `docs/ENGLISH_STAGE_1_ROADMAP.md` and `docs/DESIGN_SPEC.md`.

**Parent decision register:** `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`  
**Related records:** `docs/PROJECT_MASTER_BRIEF.md`, `docs/DATA_MODEL.md`, `docs/FLAGSHIP_PDF_RESPONSE_GRADING_AND_TIMED_ANALYTICS_SPEC.md`, `docs/DIAGNOSTIC_AND_REMEDIAL_LEARNING_READINESS_STANDARD.md`, `docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md`, `docs/ENGLISH_STAGE_1_ROADMAP.md` and `docs/DESIGN_SPEC.md`.

## 1. Purpose and non-negotiable boundaries

Phase 1 establishes the security and persistence foundation required before PDF submission, OCR, human grading, feedback history, timed analytics or real learner accounts can be used.

The specification remains the binding implementation blueprint and acceptance contract, not a claim that all of Phase 1 is implemented. Phase 1B identity/MFA/staff invitations and Phase 1C protected APIs, PostgreSQL/RLS boundaries, assessment lifecycle, role separation and audit foundations have passed local synthetic acceptance in draft PR #22. Phase 1D private PDF/file controls, Phase 1E backup/recovery/deletion and Phase 1F final synthetic security acceptance remain incomplete and must be delivered in order. The exact Phase 1C exit evidence and handoff are recorded in Section 29. The approved Phase 0 choices remain binding. Do not substitute providers or regions, add a second application database, or widen the approved scope without a recorded Founder decision.

**Current authorisation:** implementation within the Founder-approved phased plan is authorised to proceed through reviewable code changes, draft PRs and automated tests; synthetic-data public Previews are requested for Founder review only when a new, concrete and substantial learner/staff-visible feature is ready. Phase 1B is explicitly limited to local Supabase and fictional/synthetic records. Do not repeatedly seek approval for an implementation step already included in the approved plan. This authorisation does **not** include:
- creating/configuring hosted Supabase, R2, Azure or other hosted resources;
- purchasing/upgrading a plan, enabling paid usage, allowing overages or changing spend limits;
- connecting real learner accounts or processing real learner data;
- sending learner content to OCR, AI or backup processors;
- merging any PR, deploying to production, changing DNS or changing Cloudflare production configuration.

Use fictional/synthetic data only for development and any qualifying public feature Preview until the separate provisioning, privacy, security and live-pilot gates are satisfied. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.


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
- Apply verified email/account invitation for staff; public learner signup can create only the least-privileged student state. Before public real-learner use, require the learner's email to be verified before allowing access to real learner records or paid course/grading entitlements. Local synthetic CI may use preconfirmed test identities without sending email. The delivery provider/configuration is a later decision; no provider or paid email service is approved by this specification.
- Rate-limit sign-in, recovery, invitation and verification endpoints; use provider protections and abuse monitoring.
- Use secure browser session handling and avoid storing privileged tokens in application logs or analytics.
- Define account suspension, role revocation, compromised-account response and owner recovery procedures.
- Test stale sessions after role revocation, account suspension and guardian-link revocation.

MFA, recovery and email delivery configuration must be checked against current Supabase capabilities and cost/quotas before implementation. No paid email provider is implicitly approved. Normal learner email verification is a required pre-public access gate, but the local synthetic account configuration is not evidence that real delivery/confirmation is implemented.

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
- PDF only; maximum 10 MiB (10,485,760 bytes) and 10 pages per submission.
- Validate extension, declared MIME and file signature; do not trust the browser's content type.
- Reject encrypted/password-protected or malformed files unless a later approved handling path is designed.
- Calculate and store checksum, byte size, page count and upload state.
- Use short-lived signed access only after the Worker verifies ownership/assignment and current permission. Do not expose permanent public URLs.
- Separate temporary/incomplete upload objects from accepted originals; clean abandoned uploads under a documented schedule.
- Keep the original accepted PDF immutable. Corrections or replacement submissions create a new version and audit record.
- Treat uploaded PDFs as untrusted content. Render safely; do not execute embedded scripts or external links. Apply content-disarm/validation review if selected tooling requires it.
- Avoid retaining temporary page rasters; Phase 0 requires deletion immediately after OCR processing in the later OCR phase.

**Phase 1D implementation:** the local migration creates the non-public \`private-submissions\` bucket (PDF MIME only, 10 MiB limit) and private metadata table \`private.submission_files\`. Browser roles have no direct file-metadata or object access; the Worker is the only Storage client and invokes narrow service-role-only lifecycle RPCs. Upload validates extension, declared MIME, PDF signature, parseability/encryption, byte size and page count; computes SHA-256; stores through opaque random object keys; records file version and lifecycle metadata; and uses non-overwriting upload. Accepted file metadata is immutable. Pending uploads expire after 15 minutes; Owner+AAL2 can invoke the cleanup endpoint to claim and remove incomplete/expired objects. A scheduled cleanup runner is not implemented. The Worker issues a 60-second signed URL only after the database rechecks active account, learner ownership/Guardian consent, current Grader assignment and AAL2 requirements.

Exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) passed 519 PostgreSQL/pgTAP assertions across 15 SQL files, TypeScript/Worker/Vite build, 31/31 Playwright tests, shutdown, secret cleanup and clean credential-free asset build. Dedicated tests verify direct/guessed path denial, signed-link expiry, cross-learner isolation, malformed/encrypted PDFs, file/page limits, accepted-file immutability and cleanup. No hosted bucket/backend or real file data was provisioned. See \`docs/PHASE_1D_PRIVATE_PDF_FILE_CONTROLS_ACCEPTANCE_MATRIX.md\`.

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

Make application-level audit writes transactionally coupled to the action where possible. Restrict update/delete privileges on audit tables; test attempted tampering. Define retention for each audit class consistently with Phase 0's 12-/24-month records and any mandatory legal hold. The Phase 0 policy's 24-month feedback/version history and 12-month timer-event period must not be silently shortened. Phase 1C has implemented and tested the core identity, protected-workflow, role and audit events; storage upload/access/deletion and backup/restore audit events are added with their respective later phases.

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
| 1C — Protected API, database and core audit | Worker request validation, PostgreSQL schema, constraints, RLS, protected operations, append-only audit outcomes and actor/role/request correlation | 25-table protected inventory (18 public, seven private); 29 endpoint rows; all 25 Worker-audited routes fail closed on audit outage; actor/assurance and cross-role API tests; representative audit correlation; both synchronized Phase 1C-F races pass exact-head synthetic CI |
| 1D — Private PDF/file controls (VERIFIED) | Private local bucket and metadata table; Worker-mediated upload/access/cleanup; PDF validation, SHA-256, immutable file versions and assignment-scoped signed access | Verified at `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`, exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947): 519 SQL/RLS assertions, build, 31/31 Playwright tests, shutdown, credential cleanup and clean asset build passed |
| 1E — Backup, recovery and deletion (NEXT) | Supabase database backup verification, R2 encrypted PDF backup design/implementation only after regional gate, deletion workflow | Isolated DB + object restore, checksum and deletion/expiry evidence pass |
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

Phase 1 does not implement PDF extraction/OCR, AI feedback drafts, the grading queue UI, the timer UI/analytics, curriculum diagnostics, report charts, remedial courses, payment/credit purchasing, the learner-facing commercial Admin dashboard, course-entitlement/paywall UI, payment checkout, physical credit ledger or public learner email-delivery integration. It prepares the security foundation those later phases depend on. Normal learner email verification is required before real public learner-record access and paid entitlements, but provider/delivery implementation remains a later pre-launch task. The detailed future commercial product rules are in docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md.

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


## 18. Conditional public Preview and Founder review

All Phase 1 implementation work must follow `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`, as updated by the Founder on 3 November 2026. The local synthetic Supabase, database/RLS, Worker, build and browser checks remain mandatory according to the affected code. **A Founder-facing Preview request is conditional:** bring a Preview to the Founder only when a new, concrete and substantial learner/staff-visible capability is ready for meaningful review. Do not repeatedly mention or request inspection of routine, unchanged or superseded Previews.

Documentation-only changes, internal security/RLS/database changes, backend/API work without a new visible workflow, refactoring, test/CI changes, maintenance and ordinary bug fixes do not require a Founder Preview request. Keep any automatic build/deployment evidence in the repository record; do not surface it as another review request. A re-deploy or minor correction to the same feature does not trigger another review request. For a qualifying new feature, provide one concise handoff with its exact route(s), up to five user-action checks, the relevant Preview URL, limitations and any decision required.

The workflow `.github/workflows/phase1b-verification.yml` must create/update a Founder-review Preview only when the PR explicitly carries the hidden marker `<!-- founder-preview-required -->` in its body. This is an internal automation gate, not a task for the Founder. Add the marker only when the new visible feature is ready for review. The cleanup workflow remains separate. Preview automation must use only `npx wrangler preview`; it must never call the production deploy command, change DNS or provision another service.

For Phase 1B/1C backend work, local Supabase Auth/PostgreSQL with synthetic records is authoritative. A public Preview cannot connect to that local stack. Validate sign-in, identity, role, RLS, acceptance, idempotency and protected database operations in local CI. A Preview may demonstrate a new visible app workflow or its safe disconnected state, but must not be represented as hosted-backend end-to-end evidence. Public Preview URLs are not access-controlled by a no-index header and must contain no sensitive data. Custom domain remains a later, separately approved Production Cutover action.

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
4. Enforce role separation: graders see only active assignments; operational admins receive only explicitly scoped operational access and do not inherit grader, owner or private academic-QA permissions; private QA is restricted to an active Owner at AAL2; delegated QA grants are not implemented.
5. Implement append-oriented audit evidence for privileged reads where feasible and for assignments, submissions, grading changes, publication, role/link changes and administrative actions, without logging learner response content or secrets.
6. Implement server-authoritative capacity and the approved fixed 24-hour grading SLA: acceptance checks capacity before commitment; accepted time and due time are immutable snapshots; idempotency prevents duplicate acceptance; queue ordering is oldest accepted first; never accept work that cannot meet the promised SLA.
7. Expand synthetic cross-role and negative testing across anonymous, student, guardian, assigned/unassigned/revoked grader, admin, owner AAL1/AAL2 and suspended accounts. Include cross-learner/grader isolation, consent/revocation, manipulated ownership/role/state/timestamps, replay, concurrency and direct-table/RPC bypass attempts.
8. After each coherent slice, run the complete affected local Supabase reset/seed and SQL/API/browser/build/cleanup checks. Request a Founder-facing Preview only when the slice adds a concrete, substantial learner/staff-visible feature; for internal backend/security work, keep any build/deployment evidence in engineering records without asking for inspection. Update all dependent source-of-truth records after verified changes.

**Phase 1C exit gate:** Phase 1C is not complete merely because any individual slice passes its checks. Do not begin Phase 1D until every Phase 1C item above is implemented, cross-role/security-tested, documented and reviewed against this specification. Phase 1D private file/storage controls, PDF validation (10 MB/10 pages), private object access, backup/recovery and file-retention work remain subsequent work. Any hosted Storage/R2/resource provisioning, paid usage, external processing or real learner data requires its separate explicit approval; no such provisioning is authorised here.


### 20.1 Phase 1C physical inventory, default-deny matrix and remaining scope — 3 November 2026

This is the **3 November 2026 historical 12-table baseline** grounded in migrations present at that checkpoint. It is retained for traceability only; later migrations expanded the physical inventory. The current inventory is 25 protected tables (18 public, seven private), reconciled in Section 20.5. It is a security inventory, not a declaration that every logical record in `DATA_MODEL.md` has been created.

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

**Historical 3 November scope snapshot (superseded):** At this earlier baseline, accepted human-assessment submissions, immutable accepted submission versions, capacity/SLA records, rubric/task-rubric mappings, submission grader workflow, assessment/criterion-result records, versioned feedback, scoped admin workflow and private academic-QA records had not yet been implemented. Subsequent 1C-B/C and QA migrations added those physical records. Current 1C-E/F and operation-specific gaps are listed in Section 20.5. PDF objects, OCR, private file access and file-retention processing remain Phase 1D or later.

Historical inventory at this 3 November checkpoint: 12 tables total (nine public and three private); superseded by the current 25-table inventory in Section 20.5. Phase 1C added five public tables (`task_versions`, `task_version_prompts`, `attempts`, `attempt_responses`, `grader_assignments`) and one private table (`attempt_response_versions`); the other four public and two private tables are Phase 1B records. No other assessment/submission/feedback tables are implied by the logical model. Reconcile this inventory after each migration and test milestone.

### 20.2 Verified Phase 1C-A protected-table security baseline — 3 November 2026

**Code and policy changes:** Migration `20261103000600_phase1c_role_scope_hardening.sql` replaces broad published-task reads with a single resource-scope helper: students require an active enrolment for the task pathway; guardians require an active verified link plus explicit submission-view consent and an associated learner attempt; graders require AAL2 and an active assignment to submitted work for that task; owner inspection requires AAL2. Admin receives no implicit learner/task access. The same migration makes owner-wide reads of profiles, role assignments, guardian links and enrolments require AAL2 inside PostgreSQL; own/participant-scoped reads remain available under their own role rules.

Migration `20261103000700_phase1c_private_audit_and_revoked_assignment_rls.sql` enables RLS on `private.security_audit_events` without creating a browser-facing policy, and replaces the grader assignment read policy so a grader can see only their active assignment row(s) at AAL2. Owner inspection of active/revoked assignment records remains AAL2-only. Private audit writes continue through existing SECURITY DEFINER trigger/RPC paths; no client table grants are added.

**Actual role and operation tests:** `protected_table_permissions.test.sql` checks the 12 protected tables, RLS flags, anonymous/private direct grants and denied direct mutations. `role_scoped_access.test.sql` checks student/guardian/grader/admin/owner visibility against synthetic data, cross-learner isolation, consent and link revocation, AAL1/AAL2 boundaries, grader assignment revocation, admin separation and suspended-account denial. The existing identity, attempt, invitation and role-revocation tests remain in the suite. The combined suite passed **215/215 pgTAP assertions across six SQL files**.

**Exact-head verification:** run [#41646515558](https://github.com/gradioprep/gradioprep-website/actions/runs/41646515558) passed on `ee275ca714c9bfb6bb44f580c2b1e827106975d4`: local Supabase migration/reset/seed, 215/215 PostgreSQL assertions, TypeScript/Worker/Vite build, 24/24 Playwright tests, Supabase shutdown, local credential cleanup and clean public-Preview asset build. No hosted Supabase service was used.

**Cloudflare Preview:** immutable URL https://f26a4358-gradioprep-website.wandering-scene-1822.workers.dev; stable branch alias https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev. The Preview is disconnected from hosted Supabase; it proves the public shell/build only. Authenticated role and RLS behaviour was tested against local synthetic Supabase in CI. No Founder Preview review is requested for this internal security-only revision; the automated/local evidence is the applicable verification.

**Historical scope note — superseded by Section 20.3:** this 1C-A record describes the original 12-table protected-data baseline before the later accepted-submission and human-feedback migrations. Its statement that submission, rubric, assessment, criterion and feedback records did not yet exist was accurate at that earlier checkpoint only. Those records are now physically implemented and CI-verified as described in Section 20.3. The remaining Phase 1C exit work is 1C-D operational role separation, 1C-E comprehensive audit/workflow integrity, 1C-F adversarial acceptance and any remaining operation-specific Worker/database matrix gaps. Keep Phase 1D blocked until those gates pass.



### 20.3 Verified Phase 1C-B accepted-submission and Phase 1C-C human-feedback lifecycle — 3 November 2026

**Exact verified revision:** PR #22 remains open, draft and unmerged. Commit `d2e825746aa814de1f100ef2d8daa2e841d91c80` passed Exact-head GitHub Actions run [#41668857175](https://github.com/gradioprep/gradioprep-website/actions/runs/41668857175) passed **361 PostgreSQL/pgTAP assertions across eight SQL files and 27/27 Playwright tests**, plus fresh local Supabase reset/seed, TypeScript/Worker/Vite builds, cleanup and clean public-Preview asset build. The workflow intentionally skipped public Preview upload/comment because this backend-only revision did not carry the Founder-facing Preview marker. No new Preview was requested.

**Phase 1C-B migration and physical records:** `20261103000800_phase1c_accepted_human_submissions.sql` adds public `rubrics`, `rubric_versions`, `rubric_criteria`, `task_rubric_mappings`, `assessment_submissions` and `submission_versions`, plus private `grading_capacity_config`. The `accept_assessment_submission` RPC derives the learner from `auth.uid()`, checks active account/student role, active enrolment, published typed task and published mapped rubric, and records the exact task/rubric relationship. It serialises capacity decisions by locking the singleton configuration row, snapshots capacity/load, creates an immutable accepted response version and stores a server-generated acceptance time and fixed 86,400-second/24-hour due time. An idempotency key returns the original submission on an identical retry and rejects reuse with different task/response data. The SQL test checks capacity-full and capacity-disabled fail-closed behaviour, replay and snapshot protection.

**Phase 1C-C migration and physical records:** `20261103000900_phase1c_human_assessment_feedback.sql` adds public `submission_grader_assignments`, `assessment_versions` and `criterion_results`, plus private `assessment_drafts`. RPCs are `assign_submission_to_grader`, `save_assessment_draft`, `get_assessment_draft` and `publish_assessment_feedback`. Draft saves validate the exact immutable rubric criteria and score limits; publication creates immutable assessment/criterion-result versions and consumes the private draft; learners see only the latest published version. Tests exercise student, guardian, assigned/unassigned/revoked grader, owner AAL1/AAL2 and admin boundaries, private draft protection, human publication and immutable published records.

**Revoked-grader regression:** The final test captures the actual existing submission ID before the assignment is revoked, asserts the submission exists and the target grader has an active assignment, and passes the preserved ID to both draft-read and publication RPC denial checks. Both now pass with the expected `42501 / grader_assessment_forbidden`.

**Historical physical inventory at the 4 November 1C-B/C checkpoint:** 23 protected tables total — 18 public and five private. This snapshot is superseded by the 25-table current inventory in Section 20.5; the earlier 12-table baseline in Sections 20.1/20.2 is also historical.

**Remaining Phase 1C exit work — updated 4 November 2026:** 1C-D operational role separation is complete and verified in Section 20.4. Remaining items are 1C-E comprehensive audit/workflow integrity, including privileged-read evidence where feasible; 1C-F adversarial cross-role/AAL1/AAL2, replay/concurrency and direct table/RPC-bypass acceptance; and any remaining operation-specific Worker/database matrix gaps. Do not begin Phase 1D until all Phase 1C exit criteria are implemented, tested, documented and reconciled. PDF files/storage, OCR, timer UI/analytics and real learner-data readiness remain later gated work.


## 20.4 Verified Phase 1C-D operational role separation — 4 November 2026

**Exact verified code head:** c1647c7c7048b1d791c3d24f59ed51168f219d51 in PR #22. Exact-head GitHub Actions run [#41828382786](https://github.com/gradioprep/gradioprep-website/actions/runs/41828382786) passed local Supabase reset/seed with synthetic fixtures, PostgreSQL/RLS tests, TypeScript/Worker/Vite builds, 27/27 Playwright tests, cleanup and the clean public-Preview asset build.

Phase 1C-D operational role separation is complete and verified. The remaining Phase 1C work is 1C-E audit/workflow integrity, 1C-F adversarial acceptance and any residual operation-specific authorization gaps. Do not begin Phase 1D until every Phase 1C exit criterion is implemented, cross-role/security-tested, reconciled across source-of-truth records and verified at the exact PR head.

This completion concerns backend/API role separation and its tests. It does not create the future learner-facing commercial Admin dashboard for course grants, payment/credit exceptions or refunds. That dashboard, course entitlement/payment system, physical credit ledger and ordinary public learner-email delivery remain future product implementation; see docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md. PR #22 remains open, draft and unmerged, and no hosted resources, paid usage, real learner data, merge or production deployment are authorised.


## 20.5 Historical Phase 1C-E, private academic-QA and failed intermediate test checkpoint — 5 November 2026 (superseded by Section 20.6)

**Historical note:** Earlier on 5 November, the private-QA guardian-at-AAL2 denial assertions failed PostgreSQL parsing because of malformed dollar-quote delimiters. That issue was corrected in commit `868987b5a2151660d486390636d23f6261ae34df`; the subsequent exact-head run [#41969991332](https://github.com/gradioprep/gradioprep-website/actions/runs/41969991332) passed the full synthetic CI. The test-fix and result are retained in GitHub history; the current verified code-bearing state is recorded in Section 20.6.

The private academic-QA implementation remains owner-only at AAL2, with RLS, no direct client table grants, append-only records and no delegated QA-grant mechanism. The current physical inventory remains 25 protected tables (18 public and seven private). Section 20.6 records the audit-context enrichment and remaining 1C-E/F closure requirements.

## 20.6 Historical Phase 1C-E audit-context checkpoint — superseded by Section 25

**Repository and exact-head verification:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Last verified code-bearing commit: `d6de31c467817ad83e864760d61d2e8ab5e112ed`. Exact-head GitHub Actions run [#41971855781](https://github.com/gradioprep/gradioprep-website/actions/runs/41971855781) passed local Supabase reset/seed, all PostgreSQL/RLS/pgTAP tests, TypeScript/Worker/Vite builds, 27/27 Playwright tests, cleanup and clean public-preview asset build. Cloudflare Workers Builds passed for the exact commit. No Founder-facing Preview was requested for this backend-only increment. The full workflow passed fresh local Supabase startup, reset and synthetic seed; all PostgreSQL/RLS/pgTAP tests; builds; browser checks; local-stack shutdown and credential cleanup. No Founder-facing Preview upload/review was needed for this internal backend/security slice.

**Audit-context implementation:** Migration `20261105000100_phase1c_audit_context_enrichment.sql` adds `actor_roles`, `request_id` and `transaction_id` to the existing private append-only audit table. A database trigger derives the actor's active application roles from protected role/profile records, records the request ID forwarded by the trusted Worker (or generates a replacement UUID when missing/invalid), and records PostgreSQL's transaction ID. The Worker generates the request UUID inside its trusted request context and forwards it through the caller-scoped Supabase client. These values are correlation/evidence metadata only; they are not authorization inputs. The enrichment applies to new audit inserts without changing the 25-table inventory, widening client grants or allowing direct audit-table access. The audit schema continues to exclude learner response, feedback and private-QA payload fields. New test `supabase/tests/audit_context.test.sql` checks database-derived roles, request correlation, invalid-header fallback, transaction grouping and denial of direct audit-table reads.

**Verified status:** 1C-A/B/C/D remain verified at their recorded exact checkpoints. This is a verified 1C-E increment only; 1C-E is not closed. Remaining work is to map every protected Worker endpoint and privileged state-changing database operation to its required metadata-only audit event; specify and test success/denied/failed outcomes; ensure failed operations cannot leave misleading partial-success events; and close remaining operation-specific Worker/database authorization gaps. Never log answer text, feedback/QA content, credentials, bearer tokens, signed URLs or unnecessary personal data.

**Phase 1C-F remains incomplete:** Complete the consolidated adversarial matrix for anonymous, student, verified linked guardian, assigned/unassigned/revoked grader, operational Admin and Owner at AAL1/AAL2 as applicable. Include suspended accounts, revoked links/assignments, cross-learner isolation, forged actor/owner/role/assignment/state/timestamps, replay, concurrent duplicate acceptance/assignment/publication, direct table mutation and RPC bypass/misuse. Record both allowed and denied operations at Worker and database boundaries. The 25-table inventory remains 18 public and seven private.

**Historical next-order note:** the next staff-invitation/private-QA outcome slice is recorded in Section 24. The remaining generic failure-audit integrity gap, route-level Worker integration tests and consolidated 1C-F matrix supersede the earlier immediate order. All current work remains local Supabase with synthetic records only; staging/hosted resource, DNS, spend, real-data, merge and production gates remain separate.

## 22. Historical commercial and remedial-access proposal — 4 November 2026 (superseded by current 6 November policy)

The grading tier, curriculum-frequency, learner free/paid access and commercial implementation rules are defined in docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md. They are approved product specifications, not Phase 1 implementation authorisation.

- The full diagnostic and evaluation report and a meaningful starter remedial activity remain free. The full personalised remedial programme is accessed by a separate Study Lab/course entitlement or an explicit complimentary grant.
- Human grading credits are independent of course entitlements. The approved task tiers are Standard (1), Premium (2), Elite (3) and Custom (4+), with task complexity/predicted grader time determining the final server-side value. The one free grading entitlement is one Standard task per learner account.
- All accepted human-grading work, including free Standard work, shares the approved 24-hour elapsed-time target. This supersedes older differentiated free/paid/urgent SLA proposals.
- Normal public learner accounts must verify email before real learner-record access or paid entitlement access. The current local synthetic setup, staff invitation flow and absence of a configured email provider do not establish that public learner email verification delivery is already implemented.
- The future commercial Admin dashboard handles delegated entitlement/credit/payment exceptions and complimentary grants. It must not inherit Owner, grader or private academic-QA rights. Phase 1C operational admin role separation is a backend security boundary, not this future dashboard.
- The physical credit ledger, course entitlement/payment records, checkout/payment provider, email-delivery provider and customer-facing Admin UI are outside Phase 1. Phase 1C-D is verified; continue local synthetic implementation with 1C-E and 1C-F, then proceed through the later 1D/1E/1F security sequence only after the full Phase 1C exit gate passes. Do not delay free diagnostic/report work on a payment provider; do not sell or unlock paid access before entitlements and trusted payment/ledger controls are implemented.

Latest Phase 1C-D exact-head verification: commit c1647c7c7048b1d791c3d24f59ed51168f219d51, run [#41828382786](https://github.com/gradioprep/gradioprep-website/actions/runs/41828382786), passed. Phase 1C-E and 1C-F remain before Phase 1D. PR #22 stays open, draft and unmerged. No hosted provisioning, paid service, real learner data, external processing, merge or production deployment is authorised.


## 23. Historical Phase 1C-E protected-read and learner/privileged-write checkpoint — superseded by Section 25

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

## 24. Historical Phase 1C-E staff-invitation/private-QA outcome checkpoint — superseded by Section 25

**Exact-head verification:** Code head: `f5097ba8bae0eee4c420e8e5081f90287f3149ee`. Exact-head GitHub Actions run [#41984620018](https://github.com/gradioprep/gradioprep-website/actions/runs/41984620018) passed on 5 November 2026. It passed local Supabase startup/reset and synthetic seeding, all **534 pgTAP assertions across 14 SQL test files**, TypeScript/Worker/Vite builds, **27/27 Playwright tests**, local Supabase shutdown, local credential-file cleanup and the clean public-preview asset build. This was a `push` event; the workflow's public Preview upload requires an eligible `pull_request` event with the `<!-- founder-preview-required -->` marker, so Preview deployment/comment steps were skipped. No hosted preview, hosted Supabase, production deployment or DNS change occurred.

**Implemented increment:** The code increment comprises commits `688456763cc87e75bb68264707b0e0905c06c4dd`, `82b4f956e39b4a8652f55ebfe943a3934c31b1fe` and `f5097ba8bae0eee4c420e8e5081f90287f3149ee` on PR #22. Migration `20261105000700_phase1c_staff_invitation_and_private_qa_audit.sql` adds protected-read allowlist coverage for the Owner staff-invitation collection and Owner private-QA records, adds failed-outcome action handling for staff-invitation creation/revocation, and updates the Worker routes for invitation list/create/revoke and private-QA read error paths. The privileged-write audit RPC now returns `true` only when it inserts an event; the Worker treats a missing/false audit acknowledgement as unavailable and fails closed. Migration `20261105000800_phase1c_audit_invitation_failure_integrity.sql` replaces the caller-category-based invitation-acceptance failure helper with a one-argument, database-derived helper: it resolves the SHA-256 token hash to the private invitation, derives AAL/account/email/state denials, never stores the token or email in the event, and refuses to create a failure event when the invitation is otherwise eligible for acceptance. SQL tests cover these paths, private audit-table permission boundaries, an eligible invitee's attempted false-failure event, and continued success of the actual acceptance RPC. No tables were added; the protected inventory remains **25 tables (18 public, seven private)**.

**Operation and audit semantics:** The acceptance-failure helper now accepts only the token hash, derives denial/state outcomes using the current actor's active-account, AAL2, verified-email, email-match and invitation-state checks, and returns false without writing when a pending invitation is otherwise eligible. Unknown hashes are not attributed to an invitation. This prevents a caller from selecting a failure reason to manufacture an acceptance-failure event. It does not yet prove that all other generic failed outcomes correspond to a real failed business operation.

**Outstanding integrity requirement:** **Audit-integrity blocker — Phase 1C-E is not closed:** the generic `audit_privileged_write_outcome` and `audit_protected_read_outcome` RPCs still accept an allowlisted `failed` outcome and safe reason category from an authenticated caller when database role/resource checks say that caller is authorised. A caller can therefore invoke an audit RPC directly, without attempting the corresponding business operation, and create a misleading failed event. The new invitation-acceptance helper avoids this particular issue by deriving denial/state outcomes itself, but the generic failure paths remain forgeable. The next implementation must bind failure evidence to the protected operation itself (for example, a database-controlled operation wrapper that executes/catches the real operation and appends its failure event outside the failed subtransaction, or another server-only attestation that a browser caller cannot invoke or fabricate). Add direct-RPC abuse tests proving authorised callers cannot invent failures and operation-level tests proving genuine failures are still recorded. Also add explicit Worker route/integration tests for the new invitation and private-QA error paths; the SQL suite and general Playwright suite do not by themselves prove each route's audit call, HTTP response and fail-closed behavior.

**Phase exit gates:** Phase 1C-E remains partial; Phase 1C-F adversarial acceptance remains incomplete. **Next implementation order:** first close the generic false-failure audit gap for protected reads and privileged writes using operation-bound evidence, with direct-RPC abuse and genuine-failure regression tests. Add Worker route/integration coverage for staff-invitation list/create/revoke/accept and private-QA read denial/failure paths, preserving the established HTTP status and non-enumerating behaviour. Then complete the full endpoint-to-audit/authorization matrix and Phase 1C-F adversarial acceptance across anonymous, Student, linked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner at relevant AAL1/AAL2 states, including suspension, revocation, cross-learner isolation, forged fields, replay, concurrency and direct table/RPC bypass. Phase 1C-E remains partial; Phase 1D remains blocked until the complete Phase 1C exit gate passes exact-head synthetic CI. The existing protected inventory remains 25 tables (18 public and seven private). The clean public-preview asset build passed, but the workflow's deployment step was skipped on the push event; no public preview was deployed. Branded staging with an isolated hosted synthetic backend remains a later, separate approval gate.


## 25. Historical Worker-only audit-outcome hardening — superseded by Section 26

**Exact-head verification:** **Verified implementation update — 5 November 2026:** PR #22 remains open, draft and unmerged. Code head `3c4b4a71718b795855a9dd41346c80d1a1f85c39`; exact-head GitHub Actions run [#41992302366](https://github.com/gradioprep/gradioprep-website/actions/runs/41992302366) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **27/27 Playwright tests**, local Supabase shutdown, local credential cleanup and clean public-preview asset build. The workflow was a branch push, so no public/Founder Preview was uploaded. The subsequent docs-only reconciliation head `9aba3a52f192d8a9987c51a01c5eed8e21f71764` passed exact-head run [#41993692326](https://github.com/gradioprep/gradioprep-website/actions/runs/41993692326); the follow-on reconciliation is a separate docs-only revision. Migration `20261105000900_phase1c_worker_only_audit_ingestion.sql` introduces `record_worker_audit_outcome`, callable only by `service_role`; the old browser-callable generic audit outcome RPCs are revoked. The Worker uses its server-only service-role client solely for audit ingestion, with verified actor identity and allowlisted actions, outcomes and safe reason categories; business reads/writes remain on the caller-scoped client. Audit writes fail closed if the Worker audit key is absent or the database does not acknowledge the event. The local service-role key is kept in ignored `.dev.vars` and is not copied to browser `.env.local`/Vite variables. Browser direct-RPC forgery tests, trusted-writer tests and the existing Playwright invitation/private-QA/account API journey pass. Phase 1C-E remains partial pending the complete endpoint-to-audit/authorization matrix and targeted failure-injection/correlation acceptance; Phase 1C-F remains open and Phase 1D remains blocked. No hosted resources, real learner data, paid usage, merge, deployment or DNS changes occurred.

**Implemented:** Migration `20261105000900_phase1c_worker_only_audit_ingestion.sql` adds the SECURITY DEFINER RPC `public.record_worker_audit_outcome` with EXECUTE granted only to `service_role`; browser roles cannot invoke it. The legacy `audit_protected_read_outcome`, `audit_authorized_protected_read` and `audit_privileged_write_outcome` functions have no API-role execution grants. Worker application reads/writes continue to use the verified caller-scoped Supabase client. A separate service-role client is instantiated only for the narrow audit-ingestion RPC and is supplied through the Worker runtime, never through Vite/browser variables. The Worker passes the verified actor ID, fixed allowlisted action/target/outcome/failure category and generated request ID. Successful writes remain audited transactionally by the operation RPC; this ingestion function only accepts success for protected reads. Missing audit key or missing/false audit acknowledgement fails closed.

**Security tests:** Updated SQL tests deny direct browser execution of the old and new generic audit writers, prove the service role can record legitimate protected-read and operation failure/denial outcomes, and verify actor-role/request/transaction metadata, safe category allowlists and rejection of unsafe error text or forged write success. The 27/27 local Playwright run covers the real Worker route journey for invitation create/list/revoke/accept and Owner private-QA, including AAL1/AAL2, mismatch, revoked/replay and non-enumerating status cases. The full route-to-audit row correlation matrix and audit-service outage injection are still not complete.

**Phase gates:** Phase 1C-E remains partial until the complete endpoint-to-audit/authorization matrix and targeted route audit-correlation/failure-injection cases pass. Phase 1C-F cross-role/AAL1/AAL2 acceptance remains open, including suspension, role/link/assignment revocation, Guardian isolation, assigned/unassigned/revoked Grader boundaries, Admin restrictions, Owner boundaries, forged fields, replay, concurrency and direct table/RPC bypass. Phase 1D remains blocked until all Phase 1C exit criteria pass exact-head synthetic CI. The protected physical inventory remains 25 tables (18 public, seven private); no tables were added. No Preview, hosted resources, real learner data, paid usage, merge, production deployment or DNS/domain changes occurred.


## 26. Historical Phase 1C-E route audit-correlation and Phase 1C-F acceptance checkpoint — superseded by Section 27

**Current Phase 1C security checkpoint — 5 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Verified code/test head: `5dba933dce39b05c69a6616e5bb730d404e3b5a2`; exact-head GitHub Actions run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) completed successfully. The isolated local-Supabase workflow passed **494 pgTAP assertions across 14 SQL files**, TypeScript, Worker and Vite builds, and **29/29 Playwright tests**; cleanup and the credential-free public-preview asset build also passed. The run was a branch push; Preview upload/comment steps were skipped. **No Preview or production deployment occurred for this checkpoint.**

Phase 1C-E has **representative per-distinct-action persisted audit correlation coverage**, not exhaustive coverage of every possible outcome for every route. The 29-row endpoint authorization/audit matrix records 25 Worker-audited routes, each with fail-closed HTTP 503 coverage when the audit service/key/acknowledgement is unavailable. Persisted-event assertions validate actor, actor-role snapshot, action, target, outcome, safe reason, request ID and transaction ID for representative actions and outcomes. The audit action/event mapping is explicit: Worker `student_attempt_create` → successful persisted event `attempt_created`; Worker `grader_assessment_draft_save` → successful persisted event `assessment_draft_saved`. Denied/failed requests retain the corresponding Worker action names. This evidence is representative per distinct action and must not be described as exhaustive outcome coverage.

The service-role-only `record_worker_audit_outcome` RPC remains restricted to the trusted Worker audit-ingestion client; business reads and writes remain caller-scoped. Existing adversarial coverage is mapped in `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md`. Already-passing synchronized concurrency checks for competing Owner attempt assignments and feedback publication, plus duplicate-submission idempotency, are retained and must not be duplicated. **Only two synchronized Phase 1C-F tests remain outstanding:** (1) simultaneous acceptance of the same staff-invitation token; and (2) a revocation or account-suspension race against an in-flight privileged request. Phase 1C-F remains open until both tests pass exact-head synthetic CI. Phase 1D remains blocked until every Phase 1C exit criterion passes.

All work remains local-Supabase/synthetic-only. No hosted-resource provisioning, paid usage, real learner data, external processing, email delivery, merge, Preview deployment, production deployment or DNS/custom-domain change is authorised. Do not request a Founder Preview for documentation, tests or backend/security work; request one only after adding a substantial new learner/staff-visible capability.

**Implementation mapping:** Worker route action `student_attempt_create` creates successful transactional event `attempt_created`; Worker route action `grader_assessment_draft_save` creates successful transactional event `assessment_draft_saved`. Worker action names are used for denied/failed audit ingestion. The endpoint matrix is the canonical route/action/event mapping; the adversarial acceptance matrix is the canonical existing-test and remaining-gap map.

The two outstanding synchronized tests are simultaneous single-token invitation acceptance and an in-flight privileged request racing role revocation/account suspension. Existing attempt-assignment and feedback-publication concurrency tests and duplicate-submission idempotency are already covered and must not be duplicated. Phase 1D remains blocked.

## 27. Verified Phase 1C-F synchronized race acceptance — 5 November 2026

**Exact verified code/test head:** `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` on PR #22, branch `feature/phase-1b-local-auth-api`. Exact-head local synthetic GitHub Actions run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) completed successfully. The workflow passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **31/31 Playwright tests**, local Supabase shutdown, local-only environment-file cleanup and the credential-free public-preview asset build. The Cloudflare Workers Builds check also passed. Public Preview creation/update and PR Preview-link steps were skipped. **No public Preview or production deployment occurred.**

Both previously outstanding synchronized Phase 1C-F cases are implemented and passing:

1. **Same-token invitation acceptance:** two independent synthetic AAL2 sessions hit the deterministic barrier immediately before the acceptance RPC and submitted the same single-use invitation token. The result was one HTTP 200 acceptance and one safe HTTP 410 `invitation_already_used`; exactly one active Grader role; one successful and one failed/conflict `staff_invitation_accepted` audit event; distinct request IDs correlated to actor/action/invitation target/outcome; and no token/hash disclosure.
2. **Revocation/suspension racing privileged assignment:** separate synthetic submitted attempts and synchronized pre-RPC barriers were used for role revocation and account suspension. In each subcase the access change committed before the paused request resumed; the privileged assignment returned HTTP 403, a correlated `owner_attempt_assignment` denial event was recorded, and no grader assignment was created. Follow-up authorization checks remained denied.

The barrier is disposable local test plumbing: a synthetic test creates an RLS-protected table in local Supabase, and an atomic service-role-only arrival RPC coordinates the Worker requests. Worker control is additionally guarded by the local host and ignored local secret. No production migration, hosted table or production authorization bypass was added. CI reset/stopped local Supabase and removed local-only environment files.

Existing Owner assignment concurrency, feedback-publication concurrency and duplicate-submission idempotency tests were retained without duplication. Phase 1C-E remains **representative per-distinct-action persisted request-ID/event correlation coverage**, not exhaustive outcome coverage. The required successful event mappings remain Worker `student_attempt_create` → `attempt_created` and Worker `grader_assessment_draft_save` → `assessment_draft_saved`.

**Sequencing:** the two previously outstanding synchronized Phase 1C-F cases now have exact-head passing evidence. Phase 1D was not implemented or started in this change. Keep it unstarted until the final source-of-truth documentation reconciliation has itself passed exact-head CI and the Phase 1C exit record is fully reconciled. PR #22 remains open, draft and unmerged. No hosted provisioning, paid use, real learner data, external processing/email, public Preview, production deployment, DNS change or merge occurred or is authorised.


## 28. Historical Phase 1 closeout plan — superseded by Section 29

Both synchronized Phase 1C-F tests passed exact-head synthetic CI on application-code head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`, run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858). The latest prior docs-only head `69423db70fd2ff1f45c57e8b8589a95673d00c4c` passed exact-head run [#42163013589](https://github.com/gradioprep/gradioprep-website/actions/runs/42163013589). Phase 1C-E coverage remains representative per distinct action, not exhaustive outcomes. Complete the final Phase 1C exit-criteria/documentation review before Phase 1D. Phase 1D, 1E and 1F remain unstarted.

The approved queue-search/filter capability is an extension of the existing grader queue/workspace only; it must preserve same-origin Worker APIs, existing PostgreSQL, role/assignment scope, no-store results, privacy-safe search fields and oldest-accepted-first default. Do not create a second app, database or search provider. Commercial catalogue/ledger/course entitlements/payment fulfilment remain later local-synthetic implementation, separate from the secure-foundation schema and requiring their own acceptance gates.

The current commercial authority is `docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md`; it supersedes Section 22's older subscription and per-credit hypotheses. No payment/ledger/course-entitlement functionality is implemented by this specification update. PR #22 remains draft/open/unmerged; no hosted provisioning, paid usage, real learner data, merge, Preview/production deployment or DNS change is authorised.

## 29. Verified Phase 1C final exit closeout and Phase 1D handoff — 6 November 2026

**Phase 1C exit decision: COMPLETE** for the approved local-Supabase/synthetic-data scope. The application-code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` on PR #22 passed exact-head synthetic CI [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858): **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds and **31/31 Playwright tests**, including both synchronized Phase 1C-F races. The pre-closeout docs-only branch head `61f99b4f010af691a5e6b731d6bd14b7ce4a539c` passed exact-head CI [#42166224976](https://github.com/gradioprep/gradioprep-website/actions/runs/42166224976) with the same database/build/browser checks, local Supabase shutdown, local credential cleanup and credential-free public asset build.

The closeout review verified:
- **Protected data:** 25 tables in total (18 public and seven private), with RLS/permission and cross-role test evidence.
- **HTTP authorization:** 29 HTTP method/path rows in the endpoint matrix.
- **Audit outage:** all 25 Worker-audited routes fail closed with HTTP 503 when the audit service/key/acknowledgement is unavailable.
- **Adversarial acceptance:** anonymous, Student, linked/unlinked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner/AAL1/AAL2 boundaries; forged-field, direct table/RPC bypass, replay, idempotency and existing concurrency cases; same-token invitation acceptance and Owner role-revocation/account-suspension races.
- **Audit limit:** Phase 1C-E correlation is representative per distinct action, not exhaustive outcome coverage. Successful mappings remain Worker `student_attempt_create` → `attempt_created` and `grader_assessment_draft_save` → `assessment_draft_saved`.

**Next implementation:** Phase 1D private PDF/file controls. Phase 1E backup/recovery/deletion and Phase 1F final synthetic security acceptance follow. The flagship learner PDF/OCR/grading workflow, queue-search UI, timer/analytics, Diagnostic/Evaluation Report, Remedial Course and commercial ledger/payment systems remain unimplemented or separately gated. Branded staging on `gradioprep.com` with an isolated hosted synthetic backend is still mandatory before final Diagnostic/Report acceptance; hosted provisioning and DNS mapping require separate explicit approval.

PR #22 remains **open, draft and unmerged**. All Phase 1C verification used disposable local Supabase and synthetic identities/data. Exact-head workflows were branch-push runs; Preview creation/update steps were skipped. No Preview or production deployment, hosted resource, paid usage, real learner data, external processing/email, merge or DNS change occurred or is authorised.


## 30. Phase 1D private PDF/file controls — verified local-synthetic checkpoint — 6 November 2026

Phase 1D is **verified and complete for the approved local-Supabase/synthetic-data scope**. Code/test head \`251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef\` on PR #22 passed exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website): local Supabase startup/reset/seed, 519 pgTAP assertions across 15 SQL files, TypeScript/Worker/Vite build, 31/31 Playwright tests, Supabase shutdown, local-only credential cleanup and clean credential-free asset build. The workflow was a branch push; Preview/deployment steps were skipped.

The migration \`20261106000100_phase1d_private_submission_files.sql\` adds the local non-public \`private-submissions\` bucket (PDF-only declared MIME, 10 MiB maximum) and \`private.submission_files\` metadata table. The Worker mediates upload, authorization, signed access and cleanup. PDFs are checked for extension, declared MIME, signature, parser validity/encryption, size and page count; checksum and immutable file-version metadata are stored. Upload paths are opaque and non-overwriting. Temporary uploads expire after 15 minutes. The file-access RPC rechecks active account, learner ownership, verified Guardian submission consent, current Grader assignment plus AAL2, or Owner plus AAL2 before returning metadata for a 60-second signed URL. Explicit cleanup uses an Owner+AAL2 endpoint; no scheduled cleanup runner is claimed.

The inventory is now **26 protected tables (18 public, eight private)** and **32 HTTP method/path rows**. Two file write routes use Worker audit-outcome ingestion; file-read authorization/denial is recorded inside the database RPC. The Worker service-role client remains isolated and is used only for audit ingestion and this narrow Phase 1D file/Storage lifecycle; ordinary business reads/writes remain caller-scoped.

The implementation is not the complete flagship feature. Submission acceptance remains typed-response only; the file route attaches a PDF to an existing queued submission. The learner-facing optional PDF selection/upload journey, OCR/extraction, corrected transcript, split-screen grading workspace, queue search, full feedback UX, timer/analytics and Diagnostic/Report are not implemented. Phase 1E backup/recovery/deletion is next; retain the separate branded synthetic-staging and approval gates before final Diagnostic/Report acceptance.


## Current Phase 1E and CI handoff — 7 November 2026

Phase 1C is complete and Phase 1D is verified at the recorded code/test checkpoints above. Phase 1E is partial and unverified. The present migrations are paired with `supabase/tests/account_deletion_ledger.test.sql` (`plan(35)`) and `supabase/tests/account_closure_retention.test.sql` (`plan(47)`); both suites remain untested. Actions #42208654326 attempt 4 failed before runner assignment, so no SQL was executed.

Windows WSL2 Ubuntu is installed as user `gradioprep`; Docker Desktop/WSL integration is verified. GitHub CLI authentication and access to the private repository were verified on 8 November 2026. The Linux-side checkout and repository-scoped runner remain pending. Follow `docs/LOCAL_WINDOWS_WSL2_BUILD_ENVIRONMENT.md`. The workflow must be separately updated from `ubuntu-latest` to a trusted repository runner label after a security review; merely registering the runner will not switch it. Restrict execution to trusted same-repository code, use least-privilege permissions and keep deployment/Preview credentials off the persistent runner. All five GitHub spending budgets remain blocked.

The Phase 1E migration/test/restore work remains local-Supabase and synthetic-only. R2 rows are metadata only, not proof of hosted backup. Preserve Phase 0 retention/legal-hold decisions and all separate hosted-resource, privacy, cost, data, deployment, DNS and merge gates.