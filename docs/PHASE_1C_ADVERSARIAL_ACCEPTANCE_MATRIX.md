# Phase 1C-F — Adversarial Acceptance Matrix

**Status:** In progress. This is the consolidated evidence map for Phase 1C-F. Existing passing tests are recorded below; only the two synchronized race-condition cases in the final section remain to be implemented. Phase 1D is blocked until both pass and every other Phase 1C exit criterion is satisfied.

**Repository checkpoint:** PR #22, branch `feature/phase-1b-local-auth-api`, code/test head `5dba933dce39b05c69a6616e5bb730d404e3b5a2`; exact-head local synthetic CI run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds and **29/29 Playwright tests**. No Preview or production deployment occurred for this checkpoint.

## 1. Test boundaries and acceptance rules

All scenarios use disposable local Supabase, synthetic accounts and fictional records. No hosted database, real learner data, production credentials, email provider or external processor is used. Assertions must prove the observable Worker/API result and, where applicable, the database/RLS/transaction result. Passing a generic suite or successful build is not a substitute for direct evidence of the named scenario.

- **Covered / passing:** existing test evidence is named. Do not duplicate it.
- **Open:** no synchronized test currently proves the required race or invariant.
- **Blocked:** the Phase 1C exit gate is not met; Phase 1D must not start.

## 2. Actor and assurance matrix

| Actor / state | Boundary that must hold | Existing direct evidence | Status |
|---|---|---|---|
| Anonymous | No protected identity, learner, invitation, assessment, grading, audit or private-QA operation; no sensitive RPC execution or private-table access | `supabase/tests/identity_roles.test.sql`, `protected_table_permissions.test.sql`, `phase1c_adversarial_acceptance.test.sql`; API route checks in `tests/account.spec.ts` and `tests/attempts.spec.ts` | Covered / passing |
| Active Student, AAL1 | Own attempt/submission operations only; cannot alter actor, owner, state, timestamps, assignments, assessments or audit events; no cross-learner reads/writes | `supabase/tests/attempts_rls.test.sql`, `role_scoped_access.test.sql`, `accepted_submissions.test.sql`, `workflow_integrity.test.sql`, `phase1c_adversarial_acceptance.test.sql`; `tests/attempts.spec.ts` and `tests/audit.spec.ts` | Covered / passing |
| Linked Guardian, permitted active link and consent | Read only the linked learner's permitted records; no Student write, grader, Owner, private-QA or other learner access | `supabase/tests/role_scoped_access.test.sql`, `attempts_rls.test.sql`; Guardian API journey in `tests/attempts.spec.ts` | Covered / passing |
| Guardian with absent, revoked or insufficient-consent link | Deny access; do not reveal whether another learner's record exists | `supabase/tests/role_scoped_access.test.sql`, `attempts_rls.test.sql`, `role_revocation.test.sql` | Covered / passing |
| Assigned active Grader, AAL2 | Access only current assignments; grading draft and feedback publication use assigned grader identity; private QA and Owner controls remain denied | `supabase/tests/role_scoped_access.test.sql`, `assessment_workflow.test.sql`, `workflow_integrity.test.sql`; assigned queue/detail/draft/publish journey in `tests/attempts.spec.ts` and `tests/account.spec.ts` | Covered / passing |
| Grader at AAL1, unassigned or revoked | AAL1 is insufficient; no access to another grader's or revoked assignment; no stale assignment rights | `supabase/tests/role_scoped_access.test.sql`, `role_revocation.test.sql`, `assessment_workflow.test.sql`; AAL1 and assignment-denial routes in `tests/attempts.spec.ts` | Covered / passing |
| Operational Admin, including AAL2 | Admin does not inherit Grader or Owner permissions, assignment control, workflow transition or private-QA access | `supabase/tests/phase1c_adversarial_acceptance.test.sql`, `role_scoped_access.test.sql`, `private_qa_records.test.sql`; API journey in `tests/account.spec.ts` | Covered / passing |
| Owner at AAL1 | Protected Owner controls and private-QA actions are denied at Worker and database boundaries | `supabase/tests/phase1c_adversarial_acceptance.test.sql`, `private_qa_records.test.sql`, `assessment_workflow.test.sql`; AAL1 assertions in `tests/account.spec.ts` | Covered / passing |
| Active Owner at AAL2 | Owner-only role, invitation, assignment/reassignment, transition and private-QA operations are permitted only within database-enforced constraints | `supabase/tests/identity_roles.test.sql`, `role_scoped_access.test.sql`, `private_qa_records.test.sql`, `assessment_workflow.test.sql`; positive Owner routes in `tests/account.spec.ts` | Covered / passing |
| Suspended account | Valid Auth identity/session alone does not restore access; protected operations deny a suspended application account | `supabase/tests/identity_roles.test.sql`, `role_revocation.test.sql`; account/API journey in `tests/account.spec.ts` | Covered / passing for non-racing denial; racing case remains open below |

## 3. Forged-field, direct-access and workflow-integrity matrix

| Attack / invariant | Existing evidence | Status |
|---|---|---|
| Caller forges actor identity, role, ownership or role-assignment fields | Database derives identity from `auth.uid()`; `identity_roles.test.sql`, `role_scoped_access.test.sql`, `attempts_rls.test.sql`, `phase1c_adversarial_acceptance.test.sql` | Covered / passing |
| Caller forges workflow state, submission timestamps, word count or response version | `attempts_rls.test.sql`, `workflow_integrity.test.sql`, `accepted_submissions.test.sql`; API payload regression checks in `tests/attempts.spec.ts` | Covered / passing |
| Direct protected table mutation or private-table read | `protected_table_permissions.test.sql`, `phase1c_adversarial_acceptance.test.sql`, `private_qa_records.test.sql`, `audit_context.test.sql` | Covered / passing |
| Direct RPC privilege bypass or browser-forged audit outcome | `phase1c_adversarial_acceptance.test.sql`, `privileged_write_audit.test.sql`, `learner_write_audit.test.sql`; Worker-only service-role grant is checked in SQL | Covered / passing |
| Duplicate attempt/assessment submission and idempotent replay | `accepted_submissions.test.sql`, `workflow_integrity.test.sql`; submission replay checks in `tests/attempts.spec.ts` | Covered / passing |
| Invitation token expiry, revocation, email mismatch, AAL2 requirement and sequential replay rejection | `staff_invitations.test.sql`; invitation journey and acceptance-denial correlation in `tests/account.spec.ts` | Covered / passing for sequential replay; simultaneous acceptance remains open below |
| Grading draft replay/versioning and immutable published assessment/criterion results | `assessment_workflow.test.sql`, `workflow_integrity.test.sql`; draft replay and published-version assertions in `tests/account.spec.ts` | Covered / passing |
| Worker audit outage or missing acknowledgement | The 25 Worker-audited route cases in `tests/audit.spec.ts` require HTTP 503 and a generated request ID when the audit service is absent; invitation-helper false acknowledgement is separately covered in `tests/account.spec.ts` | Covered / passing |
| Persisted audit correlation | Representative actions are asserted using `tests/audit-assertions.ts`, which checks actor, role snapshot, persisted action, target, outcome, safe reason, exact request ID and transaction ID. Endpoint mapping is documented in `docs/PHASE_1C_ENDPOINT_AUTHORIZATION_AUDIT_MATRIX.md` | Representative per-distinct-action coverage; not exhaustive outcome coverage |

## 4. Concurrency evidence — retain, do not duplicate

| Existing synchronized test | Expected and verified result | Evidence | Status |
|---|---|---|---|
| Competing Owner assignments of the same attempt | Exactly one assignment succeeds; the competing request conflicts; one assignment and its audit event persist | `tests/account.spec.ts` concurrent attempt-assignment assertions; `supabase/tests/workflow_integrity.test.sql` | Covered / passing |
| Competing feedback publications for one submission | Exactly one publication succeeds; the competing request conflicts; exactly one assessment version and one publication audit event persist | `tests/account.spec.ts` concurrent publication assertions; `supabase/tests/assessment_workflow.test.sql` and `workflow_integrity.test.sql` | Covered / passing |
| Duplicate accepted-submission request / idempotency replay | A repeated key does not create a second accepted submission or duplicate operation event | `supabase/tests/accepted_submissions.test.sql`, `workflow_integrity.test.sql`, `tests/attempts.spec.ts` | Covered / passing |

These tests are already passing. Do not add duplicate assignment, publication or ordinary idempotency race tests.

## 5. Only outstanding synchronized Phase 1C-F tests

| ID | Race to test | Required synchronization and assertions | Status |
|---|---|---|---|
| 1C-F-RACE-01 | **Two requests simultaneously accept the same staff-invitation token.** | Use two independently authenticated synthetic invitee requests and a deterministic test-only barrier so both reach the token-acceptance boundary before either can commit. Release them together against the same single-use token. Assert exactly one acceptance/role grant and one persisted `staff_invitation_accepted` event; the other request must receive the defined safe already-used/conflict response, with no second role assignment, no second acceptance event and no token disclosure. Verify the invitation is consumed once and all state is consistent after both requests settle. The barrier must exist only in local test plumbing; do not add a production bypass or sleep-based timing guess. | **Open — implement** |
| 1C-F-RACE-02 | **Role revocation or account suspension races with an in-flight privileged request.** | Add deterministic synchronization between the request's initial authentication/session check and its privileged database operation. Run separate synthetic subcases for (a) revoking the actor's required role and (b) suspending the actor's account while a protected privileged request is paused. Control ordering at the authorization/transaction boundary. If revocation/suspension commits before the privileged operation acquires its authoritative authorization state, the request must be denied and produce no privileged side effect. If the operation has already acquired the required database lock/authorization state first, it may complete before the revocation/suspension; subsequent requests must then be denied. In no ordering may a stale preflight role/account snapshot authorize a privileged side effect after revocation/suspension has taken effect. Assert final role/account state, privileged record state and correlated audit event(s). Keep the barrier/test hook strictly local and synthetic. | **Open — implement** |

## 6. Exit gate and sequencing

Phase 1C-F is **not complete** while either synchronized case above lacks deterministic passing evidence. Add only these two missing test scenarios after mapping current fixtures and hooks; do not alter or duplicate the passing concurrency tests in Section 4.

After both tests pass at the exact PR head, reconcile this matrix, the endpoint authorization/audit matrix, Master Brief, Secure Application Foundation Specification, Data Model, Diagnostic Readiness Cycle Register, Diagnostic/Remedial Learning Readiness Standard, Phase 1A execution plan, English Stage 1 roadmap, README and PR #22. Run the complete local synthetic CI at the exact new head.

**Phase 1D remains blocked** until every Phase 1C exit criterion — including 1C-E representative audit correlation, the consolidated 1C-F matrix and both synchronized race tests — has direct passing evidence at the exact head. No hosted resource, paid usage, real learner data, email delivery, external processing, merge, Preview/production deployment or DNS/custom-domain change is authorised by this matrix.
