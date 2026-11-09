> **Current authorization/audit checkpoint — 9 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Exact application-code/test head `ef9dfd23e5964bb53ceb4a461beef7534449883b` passed [GitHub Actions #42566527169](https://github.com/gradioprep/gradioprep-website/actions/runs/42566527169): 661 PostgreSQL assertions across 19 SQL files, 33/33 Playwright tests, builds and synthetic database/private-PDF backup/restore. The route inventory now contains **34 HTTP method/path rows**, including the Phase 2 PDF-only submission and transcript-review endpoints; **29 route rows use Worker audit-outcome ingestion**. The private PDF read route continues to record access outcome transactionally in its database authorization RPC. The two pre-existing private-PDF Worker audit actions are preserved and regression-tested. The successful run was branch-push triggered; no PR Preview URL or production deployment is claimed. Seven Phase 1F operational runbooks and hosted/production approval gates remain separate. Continue synthetic-only; no real learner data, hosted services, external processing, paid usage, DNS changes, PR merge or production deployment are authorised.





**Historical Phase 1C baseline:** PR #22's original 29 HTTP method/path rows are retained in the route table below as the Phase 1C route set. The subsequent Phase 1D and Phase 2 extensions are recorded after the original matrix. The Phase 1D checkpoint reached 26 protected tables (18 public, eight private), 32 route rows and 27 Worker-audited routes. Current counts after Phase 2 are recorded in the Phase 2 route extension below. This is an implementation map, not a grant of additional scope. Business-data access remains on the caller-scoped Supabase client; the separate service-role client is restricted to Worker audit ingestion and the narrow private-file/transcript lifecycle.

## Audit and correlation rules

1. After bearer verification and live-session validation, the Worker generates a fresh UUID request ID. It forwards that ID through the caller-scoped PostgREST client and the separate audit-ingestion client. Authenticated API responses expose the same generated value in `X-Request-ID`; caller-supplied correlation values are not trusted.
2. State-changing success events are written by the business RPC in the same database transaction as the successful operation. The Worker-only audit RPC may record only denied/failed write outcomes. A rollback cannot leave a successful operation event behind.
3. Protected reads use an allowlisted Worker action with `success`, `denied` or `failed` outcome. Two read RPCs (staff-invitation list and private-QA list) write their success event inside the database RPC; the Worker records their denial/failure outcomes through the audit service.
4. The staff-invitation acceptance failure helper is a separate caller-scoped RPC: it derives invitation state, account, AAL and email evidence in SQL; it does not accept a caller-selected reason, invitation ID, token or email as audit payload. Successful acceptance is audited transactionally by the acceptance RPC.
5. When a route requires Worker audit ingestion and the audit client/key is missing, the RPC errors, or the RPC does not return an explicit `true` acknowledgement, that route fails closed with HTTP 503. Routes with no audit event are explicitly marked below; malformed or unauthenticated requests rejected before a verified caller context do not create an actor audit event.

## Route matrix

| HTTP endpoint | Required identity, role, assurance and scope | Success audit | Denied/failed audit and target | Missing audit service |
|---|---|---|---|---|
| `GET /api/health` | Public; health metadata only | None | None | Not applicable |
| `GET /api/v1/me` | Active authenticated account; own profile and active roles only | None; identity/profile lookup is not a learning/privileged workflow event | No API audit event is written before a verified account context; auth/session failures are returned without a learning audit event | Not applicable |
| `PATCH /api/v1/me` | Active authenticated account; self-only `display_name` update, strict allowlist | None; routine self-service display-name update is outside the current privileged/learning audit scope | No diagnostic/privileged audit event | Not applicable |
| `POST /api/v1/admin/roles/revoke` | Owner role and AAL2 enforced by `revoke_role_assignment`; active target role, final-owner invariant; target user/role validated | `role_revoked` trigger event; target = affected `role_assignment` row ID | `owner_role_revocation`; target = requested target user ID (Worker-side failure context); Worker records database-derived denial or safe failed outcome | 503 |
| `GET /api/v1/admin/staff-invitations` | Owner + AAL2 enforced by `list_staff_invitations`; invitation metadata only | `staff_invitations_listed` inserted by the list RPC | `staff_invitations_listed`; target = null collection; denial/failure recorded by Worker | 503 on Worker-recorded denial/failure; successful list uses the atomic RPC event |
| `POST /api/v1/admin/staff-invitations` | Owner + AAL2; restricted Grader/Admin role, verified email format, rate/capacity checks | `staff_invitation_created` written transactionally by create RPC; target = new invitation ID; token is never logged | `staff_invitation_created`; target = null on pre-insert failure; safe denial/failure only | 503 |
| `POST /api/v1/admin/staff-invitations/:invitationId/revoke` | Owner + AAL2; existing pending invitation and allowed state transition | `staff_invitation_revoked` written transactionally by revoke RPC | `staff_invitation_revoked`; target = invitation ID | 503 |
| `POST /api/v1/staff-invitations/accept` | Authenticated active invitee; pending, unexpired, unused invitation; verified email match and AAL2; invitation token hashed before lookup | Successful role grant and acceptance event are in the acceptance RPC transaction | `audit_staff_invitation_acceptance_failure` derives the failure from token hash/current actor and writes a denial/state event only when an invitation is resolved; token/hash/email are not stored | Uses caller-scoped DB helper rather than Worker service-role audit client; the helper's false/error acknowledgement fails closed with 503 |
| `GET /api/v1/learner/attempts` | Active Student; own attempts only | `student_attempt_list_authorized` | Same action; target = null; Worker action records success/denied/failed with `student_self` or safe denial/failure category | 503 |
| `POST /api/v1/learner/attempts` | Active Student; published typed task and active enrolment in task pathway; actor/attempt state are DB-derived | `attempt_created` in create RPC transaction; target = created attempt ID | `student_attempt_create`; target = requested task-version ID; denial/failed outcome only | 503 for a denied/failed operation whose Worker audit is unavailable; transactional success is recorded by the operation RPC |
| `GET /api/v1/learner/attempts/:attemptId` | Active Student; row must belong to current learner | `student_attempt_read_authorized` | Same action; target = attempt ID | 503 |
| `PUT /api/v1/learner/attempts/:attemptId/responses/:promptId` | Active Student; own in-progress attempt; prompt must belong to the attempt's task; bounded typed response | `attempt_response_saved` in response-save RPC transaction; version archive and event are atomic | `student_attempt_response_save`; target = attempt ID | 503 for denied/failed operation if Worker audit unavailable; successful save uses transactional event |
| `POST /api/v1/learner/attempts/:attemptId/submit` | Active Student; own in-progress attempt; required prompt response/state checks in DB | `attempt_submitted` in submit RPC transaction | `student_attempt_submit`; target = attempt ID. Cross-learner IDs resolve as the non-enumerating `attempt_not_found` (`P0002`) and are recorded as `failed/resource_not_found`, not an ownership-revealing denial | 503 for denied/failed operation if Worker audit unavailable |
| `GET /api/v1/learner/submissions` | Active Student; own assessment submissions only | `student_submission_list_authorized` | Same action; target = null collection | 503 |
| `POST /api/v1/learner/submissions` | Active Student; published typed task, active pathway enrolment, published rubric mapping and prompt; capacity and idempotency enforced in DB | `assessment_submission_accepted` (operation-owned acceptance event) in acceptance transaction | `student_assessment_submission_accept`; target = task-version ID | 503 for denied/failed operation if Worker audit unavailable |
| `GET /api/v1/learner/submissions/:submissionId` | Active Student; exact submission must belong to current learner | `student_submission_read_authorized` | Same action; target = submission ID | 503 |
| `POST /api/v1/admin/submissions/:submissionId/assign` | **Owner + AAL2**, not operational Admin; target submission must be assignable and grader eligible | `assessment_submission_assigned` in assignment RPC transaction | `owner_submission_assignment`; target = submission ID | 503 |
| `POST /api/v1/owner/submissions/:submissionId/reassign` | Owner + AAL2; existing active assignment, allowed state and eligible new Grader | `assessment_submission_reassigned` in reassignment RPC transaction | `owner_submission_reassignment`; target = submission ID | 503 |
| `POST /api/v1/owner/submissions/:submissionId/transition` | Owner + AAL2; allowed workflow transition and state preconditions | Transition RPC emits `assessment_submission_unassigned`, `assessment_submission_withdrawn` or `assessment_submission_closed` according to target state | `owner_submission_transition`; target = submission ID | 503 |
| `GET /api/v1/owner/assessment-versions/:assessmentVersionId/private-qa` | Owner + AAL2; private QA only for the requested assessment version | `private_qa_records_read` inserted atomically by read RPC | Same action; target = assessment-version ID | 503 for Worker-recorded denial/failure; success uses atomic RPC event |
| `POST /api/v1/owner/assessment-versions/:assessmentVersionId/private-qa` | Owner + AAL2; strict typed checks/status/explanation/reviewer-action payload limits | `private_qa_record_created` in create RPC transaction | `owner_private_qa_record_create`; target = assessment-version ID | 503 |
| `GET /api/v1/grader/submissions` | Active Grader + AAL2; returns submissions only with an active assignment to that Grader | `grader_submission_queue_authorized` | Same action; target = null collection | 503 |
| `GET /api/v1/grader/submissions/:submissionId` | Active Grader + AAL2; exact submission must have a current assignment to that Grader | `grader_submission_read_authorized` | Same action; target = submission ID | 503 |
| `PUT /api/v1/grader/submissions/:submissionId/draft` | Active Grader + AAL2; active assignment to that Grader; immutable draft/version rules | `assessment_draft_saved` in draft-save RPC transaction | `grader_assessment_draft_save`; target = submission ID | 503 |
| `POST /api/v1/grader/submissions/:submissionId/publish` | Active Grader + AAL2; active assignment, complete valid draft and publish-state checks | `assessment_feedback_published` on first publish or `assessment_feedback_edited` for a subsequent human revision, transactionally | `grader_assessment_feedback_publish`; target = submission ID | 503 |
| `GET /api/v1/admin/submissions/queue` | **Owner + AAL2**, not operational Admin; Owner queue scope | `owner_submission_queue_authorized` | Same action; target = null collection | 503 |
| `GET /api/v1/grader/queue` | Active Grader + AAL2; assigned attempts only | `grader_attempt_queue_authorized` | Same action; target = null collection | 503 |
| `GET /api/v1/grader/attempts/:attemptId` | Active Grader + AAL2; exact attempt must have a current assignment to that Grader | `grader_attempt_read_authorized` | Same action; target = attempt ID | 503 |
| `POST /api/v1/admin/attempts/:attemptId/assign` | **Owner + AAL2**, not operational Admin; submitted/unassigned attempt and eligible Grader | `attempt_assigned_to_grader` in assignment RPC transaction; target = new `grader_assignment` ID | `owner_attempt_assignment`; target = attempt ID | 503 |

## Request-level failure and exclusion semantics

- Missing/invalid bearer tokens, malformed JSON/field allowlists, unsupported methods and unknown routes can be rejected before a verified caller context exists. They do not fabricate an actor audit event.
- For every route that invokes `auditProtectedReadOutcome` or `auditPrivilegedWriteOutcome`, the Worker must not return the underlying success/denial/failure response unless the required audit write is acknowledged. The only client-visible fallback is the appropriate 503 audit-unavailable response.
- The acceptance-failure helper is deliberately distinct and must be tested as a database-derived, caller-scoped operation. No raw token, token hash, bearer token, invitation email, learner response, grader feedback, private-QA content, signed URL, credential or raw database error is an audit field.
- The health endpoint, authenticated self-profile read and routine self-service display-name edit are intentionally outside the diagnostic/privileged audit event set. Revisit only if an explicit account-profile audit requirement is approved; do not silently expand the audit payload or scope.

## Current verified audit-correlation evidence — 5 November 2026

Exact-head CI [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) passed on `5dba933dce39b05c69a6616e5bb730d404e3b5a2`: 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 29/29 Playwright tests. The exact run skipped Preview upload/comment steps; no Preview or production deployment occurred.

**Route-level fail-closed coverage:** all 25 Worker-audited routes are exercised with the audit service/key/acknowledgement unavailable. Expected behaviour is HTTP 503 with a generated `X-Request-ID`. The 29-row matrix also identifies routes intentionally outside the audit set or rejected before a verified caller context.

**Worker action to persisted-event mapping:**

| Worker route/action | Successful persisted business event | Denied/failed Worker audit action |
|---|---|---|
| `POST /api/v1/learner/attempts` — `student_attempt_create` | `attempt_created` | `student_attempt_create` |
| `PUT /api/v1/grader/submissions/:submissionId/draft` — `grader_assessment_draft_save` | `assessment_draft_saved` | `grader_assessment_draft_save` |

Successful write events are inserted transactionally by the operation RPC. The Worker-only service-role audit RPC records allowlisted denied/failed outcomes; these action names intentionally differ from the successful business-event names in the two cases above.

**Correlation scope:** Phase 1C-E has **representative per-distinct-action persisted request-ID/event correlation coverage**, not exhaustive coverage of every possible outcome for every route. Existing Playwright assertions use `tests/audit-assertions.ts` to check persisted actor, actor-role snapshot, action, target type/ID, outcome, safe reason, exact Worker response request ID and transaction ID. Representative cases include Student attempt list/create, own attempt and submission reads/writes, cross-learner denials and non-enumerating failures, linked Guardian and Grader access boundaries, Owner/operational Admin boundaries, staff-invitation acceptance/create/list/revoke, private-QA actions, grader draft save/replay and feedback publication. This is deliberately representative per distinct action, not an exhaustive matrix of all outcome variants.

**Already-passing synchronized concurrency and replay tests — retain without duplication:**
- Competing Owner assignments for the same attempt: one success and one conflict, with only one active assignment and the expected audit evidence.
- Competing feedback publications: one success and one conflict, exactly one published version and one publication event.
- Duplicate human-assessment submission/idempotency replay and draft revision/replay checks.

These are existing passing tests in `tests/account.spec.ts`, `tests/attempts.spec.ts`, `supabase/tests/accepted_submissions.test.sql`, `assessment_workflow.test.sql` and `workflow_integrity.test.sql`; see the consolidated coverage map in `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md`. Do not duplicate them.

## Phase 1C-F synchronized adversarial acceptance — verified

The two synchronized synthetic tests that were previously outstanding are now implemented and passed at exact code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`, run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858). The complete workflow passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests.

| Case | Verified synchronized result | Direct evidence |
|---|---|---|
| Same single-use staff-invitation token accepted simultaneously by two independent synthetic AAL2 sessions | One HTTP 200 acceptance and one safe HTTP 410 `invitation_already_used`; exactly one active Grader role, one successful `staff_invitation_accepted` event and one failed/conflict event. Both distinct request IDs correlate to the expected actor, action, invitation target and outcome. No token/hash disclosure in the losing response. | `tests/phase1c-races.spec.ts`, test “two independent AAL2 sessions accepting one invitation token produce one grant and one success” |
| Owner role revocation racing an in-flight privileged attempt assignment | The request was paused before the assignment RPC, the Owner role was revoked, and the released request returned HTTP 403. The correlated `owner_attempt_assignment` denial event exists and no grader assignment was created; a subsequent request also remained denied. | `tests/phase1c-races.spec.ts`, second race test |
| Owner account suspension racing an in-flight privileged attempt assignment | The request was paused before the assignment RPC, the Owner account was suspended, and the released request returned HTTP 403. The correlated denial event exists, no grader assignment was created, and the current-account endpoint returned `account_unavailable`. | Same test, separate suspension subcase |

The test-only barrier is backed by a dynamically created RLS-protected table in disposable local Supabase and an atomic service-role-only arrival RPC. The Worker control path requires both the local host and ignored local secret. No migration, hosted table or production authorization bypass was added.

Existing synchronized Owner attempt-assignment concurrency, feedback-publication concurrency and duplicate-submission idempotency tests remain covered and were not duplicated. Phase 1C-E remains representative per-distinct-action request-ID/event correlation coverage, not exhaustive outcome coverage. This paragraph records the Phase 1C exit checkpoint before the later Phase 1D increment. The Phase 1D file routes and their verified acceptance are recorded in the current extension at the end of this matrix. PR #22 remains open, draft and unmerged. No Preview/production deployment, hosted provisioning, paid use, real learner data, external processing or DNS/custom-domain change occurred or is authorised.

## Phase 1C final exit closeout — 6 November 2026

Phase 1C is closed at the local-Supabase/synthetic-data boundary. The protected physical inventory is **25 tables (18 public, seven private)**. This matrix covers **29 HTTP method/path rows**; **25 Worker-audited routes** have fail-closed HTTP 503 coverage for missing audit service/key/acknowledgement. The code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` passed exact-head CI [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) with 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests, including both synchronized Phase 1C-F race tests.

Audit correlation remains **representative per distinct action**, not exhaustive coverage of all possible route/outcome combinations. Successful persisted-event mappings remain Worker `student_attempt_create` → `attempt_created` and `grader_assessment_draft_save` → `assessment_draft_saved`; denied/failed audit events retain the Worker action names. Application reads/writes remain caller-scoped; the separate service-role client is restricted to audit ingestion.

The pre-closeout docs-only baseline `61f99b4f010af691a5e6b731d6bd14b7ce4a539c` passed [#42166224976](https://github.com/gradioprep/gradioprep-website/actions/runs/42166224976). At the time of this Phase 1C closeout, Phase 1D was the next phase; it has since been implemented and verified in the Phase 1D extension below. This closeout does not imply private Storage, PDF upload, OCR, full grader queue, branded staging, hosted services or public learner readiness. PR #22 remains open, draft and unmerged; no Preview/production deployment, hosted provisioning, paid use, real learner data, email delivery or DNS change occurred or is authorised.


## Phase 1D route extension — historical total: 32 rows (superseded by Phase 2 extension below)

The 29-row Phase 1C matrix above is retained as the historical Phase 1C route set. At the Phase 1D checkpoint, its three private-file routes brought the matrix to **32 HTTP method/path rows**.

| Route | Authorization and validation | Transactional success audit | Worker denial/failure audit | Fail-closed behaviour |
|---|---|---|---|---|
| `POST /api/v1/learner/submissions/:submissionId/file` | Active Student; exact own queued/uploadable submission; one multipart PDF; Worker validates extension, MIME, signature, parseability/encryption, size and page count; opaque non-overwriting object path | Metadata-only file-upload event associated with the submission/file version; no PDF content or signed URL in audit | Worker action for upload denial/failure; safe target and reason only | HTTP 503 if required Worker audit outcome cannot be acknowledged |
| `GET /api/v1/submissions/:submissionId/file` | Own Student; linked Guardian with verified submission-view consent; current assigned Grader+AAL2; or Owner+AAL2; database rechecks active identity and scope before 60-second signed access | File-read allow/deny event written by the database authorization RPC | Database-derived denial/state event; no raw object key, signed URL or file content | Caller receives the established safe authorization/error response; database event is transactional |
| `POST /api/v1/owner/submission-files/cleanup` | Owner+AAL2; claims and cleans expired/incomplete pending uploads, bounded to 50 per call | Metadata-only cleanup/abandonment event after Storage confirms object absence | Worker action for cleanup denial/failure; safe target/reason only | HTTP 503 if required Worker audit outcome cannot be acknowledged |

**Phase 1D checkpoint totals (historical):** 26 protected tables (18 public, eight private); 32 route rows; 27 Worker-audited routes (the prior 25 plus upload and cleanup); file-read allow/deny is recorded inside its database authorization RPC. Phase 1C-E audit correlation remains representative per distinct action, not exhaustive outcome coverage. Phase 1D exact-head verification is [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947).


## Phase 2 PDF-only and teacher transcript-review route extension — current total: 34 rows

Phase 2 adds two Worker routes to the historical 32-row Phase 1D inventory, bringing the current matrix to **34 HTTP method/path rows**. The current protected physical inventory remains **26 tables (18 public, eight private)**. There are **29 Worker-audited route rows** (27 at the Phase 1D checkpoint, plus PDF submission and transcript review); PDF file reads continue to use their transactional database authorization/audit RPC.

| Route | Authorization and validation | Transactional success audit | Worker denial/failure audit | Fail-closed behaviour |
|---|---|---|---|---|
| `POST /api/v1/learner/pdf-submissions` | Active Student; active account/enrolment; published task, prompt and rubric; explicit task PDF opt-in and `ideal_words > 20`; only `typed_pdf` or `pdf_only` multipart shape; Worker validates signature/parseability/encryption, 10 MiB and 10-page limits. Reservation and acceptance use the shared serialized capacity/idempotency lifecycle. | `assessment_submission_accepted` and file/transcript-v1 records are created by the finalization RPC in the acceptance transaction. | `student_assessment_submission_accept`; safe task/submission target and fixed failure category, without PDF/text payload. | HTTP 503 if the required Worker audit outcome cannot be acknowledged. |
| `PUT /api/v1/submissions/:submissionId/transcript` | Active Grader with a current assignment or active Owner; AAL2; accepted private source PDF; reviewable submission state; exact page count/order/status and bounded content; expected latest transcript version must match. | `submission_transcript_version_appended` is inserted by the append RPC in the same transaction as the new immutable transcript version. | `staff_submission_transcript_review`; target = submission ID; denial/conflict/failure category only, not review note or learner text. | HTTP 503 if the required Worker audit outcome cannot be acknowledged. |

The transcript-review route's successful business event is written by the RPC; the Worker audit action covers denied/failed outcomes. A stale expected-version save returns a conflict and does not overwrite the latest version. The migration preserves the previously established `student_submission_file_upload` and `owner_submission_file_cleanup` Worker audit actions; the two allowlist regression assertions passed.

Exact combined verification: application-code/test head `ef9dfd23e5964bb53ceb4a461beef7534449883b`, [GitHub Actions #42566527169](https://github.com/gradioprep/gradioprep-website/actions/runs/42566527169), 661 PostgreSQL assertions/19 files, 33/33 Playwright tests, builds and synthetic backup/restore. Audit correlation remains representative by distinct action, not exhaustive for every route/outcome combination.


## Phase 1F audit-contract and metadata-safety extension — 8 November 2026

The Worker audit contract now accepts only an explicit boolean `true` with no RPC error. Both `auditProtectedReadOutcome` and `auditPrivilegedWriteOutcome` return HTTP 503 when the audit service is unavailable, the RPC errors, or the RPC explicitly returns `false`. The Playwright suite contains a focused contract regression covering true, false and error values. The combined exact-head hosted run [#42478042674](https://github.com/gradioprep/gradioprep-website/actions/runs/42478042674) is pending; do not mark this additional coverage passed until it completes.

Migration `20261108000200_phase1f_audit_role_reason_allowlist.sql` removes free-form role-assignment reason text from audit `reason_category`; the trigger records only `role_granted`, `role_revoked` or `role_assignment_updated`. A synthetic canary assertion in `audit_context.test.sql` verifies the submitted free text is absent. This test also awaits #42478042674.

Audit correlation remains representative per distinct action, not exhaustive over every route/outcome permutation. See the Phase 1F crosswalk for current evidence and deferred hosted/production boundaries.


## Phase 1F audit metadata minimisation — 8 November 2026

The active migration sequence fixes both identified free-text audit paths: role-assignment reason text is replaced with fixed role action categories, with grants attributed to `granted_by` and revocations to `revoked_by`; draft-archive explanations remain in private immutable draft history while audit metadata records only `draft_archived`. SQL canaries cover exclusion and attribution. Full combined verification is pending at [#42479011331](https://github.com/gradioprep/gradioprep-website/actions/runs/42479011331).


## Phase 1F exact-head technical verification and formal acceptance boundary — 8 November 2026

The complete Phase 1F synthetic suite passed on application/test head `746727d0c103efb8ad2fa59374a9c2c5557ba1a7`, exact-head hosted CI [#42479406070](https://github.com/gradioprep/gradioprep-website/actions/runs/42479406070): 609 PostgreSQL assertions across 17 SQL files, 32/32 Playwright tests, TypeScript/Worker/Vite builds, synthetic database/private-PDF backup and restore, restored authorization checks, corrupt-archive rejection, local Supabase shutdown, local credential cleanup and clean credential-free asset build. The workflow skipped Cloudflare Preview steps; no Preview or production deployment occurred.

Technical synthetic evidence includes restored RLS/Storage allow-deny checks; audit missing/error/false-acknowledgement fail-closed behavior; role grant/revocation actor attribution; fixed audit categories and free-text exclusions for role changes and draft archival; private history preservation; deterministic retention fixtures; private PDF ownership/direct-access controls; and existing retention/legal-hold/closure tests. Coverage is representative per distinct audit action, not exhaustive for every route/outcome permutation.

**Formal Phase 1F acceptance is not yet granted.** The seven operational runbooks require Founder/security review, named operational contacts and provider-specific adaptation before activation. Hosted backup encryption/key custody, physical learner/object deletion, scheduled retention execution, production monitoring, provider-specific activation, real-data privacy/legal review and branded hosted staging remain deferred approval gates. The synthetic CI backup verifier is not a production restore service. PR #22 remains open, draft and unmerged.