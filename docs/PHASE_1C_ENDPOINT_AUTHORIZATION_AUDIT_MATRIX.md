# Phase 1C endpoint-to-authorization and audit matrix

**Scope:** PR #22 local Worker/API surface at code/test head `5dba933dce39b05c69a6616e5bb730d404e3b5a2`, exact-head GitHub Actions run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808). The run passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 29/29 Playwright tests. It was a branch push; Preview upload/comment steps were skipped and no Preview or production deployment occurred for this checkpoint. This matrix contains 29 HTTP method/path rows. The 25 Worker-audited routes have missing-audit-service/key/acknowledgement fail-closed coverage. This is an implementation map, not a grant of additional scope. Business-data access remains on the verified caller-scoped Supabase client; the separate service-role client is used only for `record_worker_audit_outcome`. The physical data inventory remains 25 tables (18 public, seven private).

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

## Phase 1C-F adversarial acceptance — remaining gaps

The consolidated actor/assurance and attack-surface evidence matrix is `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md`. It maps anonymous, Student, linked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner access at relevant AAL levels, plus suspension, revocation, cross-learner isolation, forged fields, direct table/RPC bypass, sequential replay/idempotency and the already-passing concurrency tests.

**Only two synchronized synthetic tests remain open:**
1. Simultaneous acceptance of the same single-use staff-invitation token. Assert exactly one acceptance/role grant and one `staff_invitation_accepted` event; the competing request must fail safely with no duplicate grant/event.
2. Revocation or account suspension racing an in-flight privileged request. Use deterministic synchronization at the authorization/transaction boundary. A stale preflight role/account snapshot must never permit a privileged side effect after revocation/suspension has taken effect. Assert the final authorization state, side effect and audit evidence.

Do not duplicate the already-passing Owner assignment, feedback-publication or duplicate-submission concurrency tests. Keep all new tests local-Supabase and synthetic-only.

**Phase gate:** Phase 1C-E is representative per-distinct-action correlation coverage, not exhaustive outcome coverage. Phase 1C-F remains open until both synchronized race tests pass exact-head synthetic CI. Phase 1D remains blocked until every Phase 1C exit criterion is documented and passes. PR #22 remains open, draft and unmerged. No hosted backend/resource, paid use, real learner data, email delivery, external processing, merge, Preview deployment, production deployment or DNS/custom-domain change is authorised.