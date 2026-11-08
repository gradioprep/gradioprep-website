# Phase 1C-F — Adversarial Acceptance Matrix

> **Current execution checkpoint — 8 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`; the repository is public. Verified application/migration head: `edc3340a579dc9ef4d27463143dd2bf90ddda1fe`; subsequent commits are documentation-only. Exact-code CI [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308) passed 601 PostgreSQL assertions/17 SQL files, 31/31 Playwright tests, builds and synthetic database/private-PDF backup/restore. Phase 1E is complete for synthetic CI only. Phase 1F security evidence review is outstanding; see `docs/PHASE_1F_FINAL_SYNTHETIC_SECURITY_ACCEPTANCE.md`. Hosted resources, real data, DNS, production deployment and PR merge remain separately gated.


**Historical Phase 1C-F closeout status (superseded):** The synchronized adversarial acceptance passed at code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`, exact-head run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858). Phase 1D and Phase 1E were subsequently implemented and verified; current Phase 1F acceptance is tracked in `docs/PHASE_1F_FINAL_SYNTHETIC_SECURITY_ACCEPTANCE.md`.

**Latest verified repository checkpoint:** PR #22, branch `feature/phase-1b-local-auth-api`, code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`; exact-head local synthetic CI run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds and **31/31 Playwright tests**, including both synchronized Phase 1C-F races. Local-stack shutdown, local credential cleanup and clean credential-free public-preview asset build passed. The public Preview creation/update and PR Preview-link steps were skipped; no public Preview or production deployment occurred.

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
| Suspended account | Valid Auth identity/session alone does not restore access; protected operations deny a suspended application account | `supabase/tests/identity_roles.test.sql`, `role_revocation.test.sql`; account/API journey and synchronized in-flight assignment case in `tests/account.spec.ts` and `tests/phase1c-races.spec.ts` | Covered / passing, including the synchronized race in Section 5 |

## 3. Forged-field, direct-access and workflow-integrity matrix

| Attack / invariant | Existing evidence | Status |
|---|---|---|
| Caller forges actor identity, role, ownership or role-assignment fields | Database derives identity from `auth.uid()`; `identity_roles.test.sql`, `role_scoped_access.test.sql`, `attempts_rls.test.sql`, `phase1c_adversarial_acceptance.test.sql` | Covered / passing |
| Caller forges workflow state, submission timestamps, word count or response version | `attempts_rls.test.sql`, `workflow_integrity.test.sql`, `accepted_submissions.test.sql`; API payload regression checks in `tests/attempts.spec.ts` | Covered / passing |
| Direct protected table mutation or private-table read | `protected_table_permissions.test.sql`, `phase1c_adversarial_acceptance.test.sql`, `private_qa_records.test.sql`, `audit_context.test.sql` | Covered / passing |
| Direct RPC privilege bypass or browser-forged audit outcome | `phase1c_adversarial_acceptance.test.sql`, `privileged_write_audit.test.sql`, `learner_write_audit.test.sql`; Worker-only service-role grant is checked in SQL | Covered / passing |
| Duplicate attempt/assessment submission and idempotent replay | `accepted_submissions.test.sql`, `workflow_integrity.test.sql`; submission replay checks in `tests/attempts.spec.ts` | Covered / passing |
| Invitation token expiry, revocation, email mismatch, AAL2 requirement, sequential replay rejection and simultaneous same-token acceptance | `staff_invitations.test.sql`, `tests/account.spec.ts`, `tests/phase1c-races.spec.ts` | Covered / passing, including the synchronized race in Section 5 |
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

## 5. Completed synchronized Phase 1C-F synthetic race acceptance

| ID | Synchronized race | Verified result | Direct evidence | Status |
|---|---|---|---|---|
| 1C-F-RACE-01 | **Two independent AAL2 sessions simultaneously accept the same single-use staff-invitation token.** | A local-only deterministic barrier held both requests immediately before the acceptance RPC. The exact-head Playwright test passed: one HTTP 200 acceptance, one safe HTTP 410 `invitation_already_used`, exactly one active Grader role, one successful and one failed/conflict `staff_invitation_accepted` event, distinct request IDs with actor/action/target/outcome correlation, and no token/hash disclosure. | `tests/phase1c-races.spec.ts`; exact-head run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) | **Covered / passing** |
| 1C-F-RACE-02a | **Owner role revocation races with an in-flight privileged attempt assignment.** | A valid synthetic submitted attempt and deterministic pre-RPC barrier were used. Revocation committed before the request resumed; the request returned HTTP 403, wrote the correlated `owner_attempt_assignment` denial event and created zero grader assignments. A subsequent request was also denied after revocation. | `tests/phase1c-races.spec.ts`; exact-head run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) | **Covered / passing** |
| 1C-F-RACE-02b | **Owner account suspension races with an in-flight privileged attempt assignment.** | A separate valid synthetic submitted attempt and barrier were used. Suspension committed before the request resumed; the request returned HTTP 403, wrote the correlated denial event and created zero grader assignments. The current-account endpoint also returned `account_unavailable`. | `tests/phase1c-races.spec.ts`; exact-head run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) | **Covered / passing** |

The test-only barrier uses a dynamically created RLS-protected table in disposable local Supabase and an atomic service-role-only arrival RPC. Worker control also requires the local host and ignored local secret. No database migration, hosted barrier table or production authorization bypass was added. The workflow reset/stopped local Supabase and removed local-only environment files.

## 6. Exit gate and sequencing

The Phase 1C exit evidence in this matrix is satisfied. The actor/assurance, RLS, forged-field, direct-bypass, replay/idempotency, assignment/publication concurrency, representative audit-correlation and both synchronized Phase 1C-F race cases passed at application-code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`, exact-head run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858). This includes one successful and one safely rejected simultaneous acceptance of the same invitation token, plus denial of privileged assignment when Owner-role revocation or account suspension takes effect in flight.

The final closeout reconciled the 25-table protected inventory (18 public, seven private), 29 endpoint rows, 25 Worker-audited routes with fail-closed audit-outage coverage, this actor/assurance matrix and the endpoint authorization/audit matrix. Phase 1C-E remains **representative per-distinct-action coverage**, not exhaustive outcome coverage.

The latest pre-closeout documentation baseline `61f99b4f010af691a5e6b731d6bd14b7ce4a539c` passed exact-head CI [#42166224976](https://github.com/gradioprep/gradioprep-website/actions/runs/42166224976) with 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests. Phase 1C is now closed at the local synthetic boundary. **Historical Phase 1D handoff:** Phase 1D was the next workstream at this Phase 1C checkpoint. It has since been implemented and verified; see the Phase 1D regression dependency below.

PR #22 remains open, draft and unmerged. The exact-head workflow was a branch-push run; Preview creation/update steps were skipped and no public Preview or production deployment occurred. No hosted provisioning, paid usage, real learner data, external processing/email, merge, production deployment or DNS/custom-domain change is authorised.


## 7. Phase 1D private-file adversarial acceptance — verified

Phase 1D file-control adversarial coverage passed exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947): 25 dedicated pgTAP assertions plus the 31/31 Playwright suite, within 519 pgTAP assertions across 15 SQL files. Verified negative and boundary cases include anonymous upload/read denial; invalid extension, declared MIME and PDF signature; malformed, encrypted/password-protected files; byte/page limits; direct Storage and guessed-object-path denial for browser roles; expired signed-link denial; cross-learner denial; unassigned/revoked Grader denial; accepted-file metadata immutability; expired pending-upload denial and Owner+AAL2 cleanup. Positive cases cover valid private upload/download and authorized short-lived access. All tests use synthetic local Supabase only.

**Current combined acceptance position:** Phase 1C-F remains passed; Phase 1D private-file controls are verified. Current inventory is 26 protected tables (18 public, eight private) and 32 API route rows. The full learner-facing optional PDF submission journey, OCR, corrected transcript, split-screen grader workspace, full feedback workflow, queue search, timer/analytics and hosted/real-data acceptance remain outside this increment. Phase 1E backup/recovery/deletion is verified for synthetic CI; Phase 1F final security acceptance is next.
