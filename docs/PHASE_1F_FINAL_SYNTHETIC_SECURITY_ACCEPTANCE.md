# Phase 1F — Final Synthetic Security Acceptance Evidence Crosswalk

**Version:** 0.1-draft  
**Date:** 8 November 2026  
**Status:** Evidence inventory prepared; final security acceptance is **not yet granted**.

## 1. Purpose and boundary

This document maps the verified Phase 1E synthetic CI baseline to the final Phase 1F security review. It is an evidence index and review checklist, not a declaration that every operational or adversarial scenario has passed.

PR #22 remains open, draft and unmerged. The verified application/migration head is `edc3340a579dc9ef4d27463143dd2bf90ddda1fe`; exact-code GitHub Actions run [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308) passed 601 PostgreSQL assertions across 17 SQL files, 31/31 Playwright tests, TypeScript/Worker/Vite builds and the synthetic database/private-PDF backup/restore verifier. Commits after that code head are documentation-only.

All Phase 1F work in this document is limited to source review and ephemeral hosted CI with synthetic fixtures. Do not start Supabase/Docker on the user's WSL computer, register a self-hosted runner, provision hosted Supabase/R2, use real learner data, change DNS/custom domains, deploy production, incur paid overages or merge PR #22 without separate approval.

## 2. Evidence baseline

| Area | Existing evidence | Current classification |
|---|---|---|
| PostgreSQL/RLS and protected-table permissions | 17 SQL files, including `protected_table_permissions.test.sql`, `role_scoped_access.test.sql`, `attempts_rls.test.sql`, `private_qa_records.test.sql` and `phase1c_adversarial_acceptance.test.sql`; all included in run #42473595308 | CI verified at the Phase 1E code head; Phase 1F still reviews coverage and negative cases |
| Identity, roles and revocation | `identity_roles.test.sql`, `role_revocation.test.sql`, `staff_invitations.test.sql`, `phase1c-races.spec.ts` | CI verified; confirm no missing privilege-escalation scenario in review |
| Assessment lifecycle and integrity | `assessment_workflow.test.sql`, `accepted_submissions.test.sql`, `workflow_integrity.test.sql`, `attempts.spec.ts` | CI verified; inspect boundary and replay cases against the adversarial matrix |
| Audit attribution and denial behaviour | `audit_context.test.sql`, `learner_write_audit.test.sql`, `privileged_write_audit.test.sql`, `audit.spec.ts`, `audit-assertions.ts` | CI verified for authored assertions; do not infer exhaustive route/outcome coverage |
| Private PDF controls | `phase1d_private_submission_files.test.sql`, browser coverage in `tests/account.spec.ts` and `tests/audit.spec.ts` | CI verified for the existing synthetic scenarios; review ownership, signed URL, direct Storage and cleanup denial cases |
| Account closure, legal holds and retention | `account_deletion_ledger.test.sql` (35 assertions), `account_closure_retention.test.sql` (47 assertions) | CI verified in #42473595308; external object deletion and real-data erasure are not proven |
| Backup and restoration | `scripts/phase1e-local-backup.mjs`, workflow step `npm run phase1e:backup:verify` | Synthetic round-trip verified; not evidence of hosted backup encryption, key custody, R2 lifecycle or disaster recovery |
| Build and browser regression | TypeScript/Worker/Vite builds; 31/31 Playwright tests | CI verified at the recorded code head |

## 3. Phase 1F review checklist

For each item, record the exact source/test reference, outcome, and whether a new regression test is required. A green aggregate CI run is not a substitute for reviewing what each assertion actually proves.

| Review item | Required review | Acceptance evidence / disposition |
|---|---|---|
| Role and assurance boundaries | Student, Guardian, Grader, Admin/Owner; AAL2 requirements for privileged operations; revoked and suspended identities | Cross-check `identity_roles`, `role_scoped_access`, `role_revocation`, `staff_invitations` and relevant Worker route tests against the endpoint matrix |
| Direct table/RPC access | Authenticated and anonymous direct access; browser-callable privileged RPCs; grants and service-role scope | Cross-check `protected_table_permissions`, migration grants and the endpoint matrix; record any RPC without a specific denial assertion |
| Cross-learner isolation | Guessed IDs, foreign submission/file IDs, Guardian consent and Grader assignment boundaries | Cross-check `phase1c_adversarial_acceptance`, `attempts_rls` and private-file browser tests |
| Lifecycle race/replay safety | Concurrent transitions, stale state, duplicate requests, retries and idempotency | Cross-check `workflow_integrity`, `assessment_workflow`, race Playwright tests and account closure/hold tests |
| Audit fail-closed behaviour | Audit writer unavailable, invalid actor/context, denied operations, missing correlation context, and no sensitive payload leakage | Review `audit_context`, `privileged_write_audit`, `learner_write_audit`, Worker audit ingestion and `audit-assertions.ts`; explicitly identify untested failure modes |
| Private PDF isolation | Object ownership, path guessing, direct Storage, signed URL expiry, malformed files, cleanup and no content/token leakage into audit | Cross-check the Phase 1D SQL and Playwright scenarios; verify the actual route/RPC/storage policies, not only test names |
| Closure, legal holds and retention | Owner/AAL2 gate, legal hold precedence, retention windows, state transitions, audit and retry behaviour | Recheck the 35- and 47-assertion suites and identify the boundary between DB metadata and external object erasure |
| Restore integrity and policy preservation | Restored schema, RLS and Storage policy effectiveness, data ownership after restore, checksum failure and corrupt archive rejection | Existing verifier checks a synthetic database/private-PDF round trip and rejects a corrupt archive. Separately review whether restored RLS/Storage policies are exercised by denial/allow tests after restore; counts alone are insufficient |
| Secret and sensitive-data handling | No credentials in repository, logs, artifacts or audit payloads; no private learner content in public outputs | Review workflow env-file lifecycle, artifact/log output and audit payload allow-list; no claim of a complete historical secret scan |
| Operational readiness boundary | Seven operational runbooks required by the implementation specification | Record as outstanding documentation/operational readiness unless the runbooks are found and reviewed; do not silently treat test coverage as runbook completion |

## 4. Explicit limitations and deferred work

1. **Backup encryption/key custody:** the Phase 1E verifier is a temporary synthetic local backup/restore mechanism and is explicitly not an encrypted hosted-backup service. Encryption-provider selection, key separation, key custody and recovery-key procedures remain deferred pending a separate architecture/cost approval.
2. **External object deletion:** the SQL retention inventory and synthetic restore verifier do not prove deletion of an actual R2 object or physical erasure from a hosted provider. Do not provision R2 to close this gap without separate approval.
3. **Restored policy effectiveness:** matching schema/policy counts is not enough. Confirm that post-restore authorization tests demonstrate both allowed owner-scoped access and denied cross-learner/direct access. If not covered, add a synthetic regression test.
4. **Audit exhaustiveness:** existing tests cover representative actions and outcomes. They do not establish exhaustive coverage of every HTTP route/outcome permutation. Document the precise tested matrix and any intentional omissions.
5. **Operational runbooks:** the seven required runbooks are an independent deliverable. A test passing does not replace incident response, account compromise, leaked secret, cross-learner disclosure, malicious PDF, outage, failed deletion or backup-integrity procedures.
6. **Production and real-data controls:** hosted backup, encryption at rest/in transit configuration, provider-region/transfer review, restore drills, external email, monitoring, real learner data and branded staging remain separate gates.

## 5. Phase 1F exit criteria

Phase 1F may be marked complete only after all of the following are recorded:

- Each checklist row has a source/test reference and a clear pass, gap, or deferred disposition.
- Every in-scope gap has a regression test and passing exact-head hosted CI, or a documented reason why it is outside this synthetic phase.
- Restored RLS and Storage policy effectiveness is demonstrated by actual authorization assertions, not only object/count checks.
- Audit fail-closed behaviour and sensitive-payload exclusions have explicit evidence.
- The seven operational runbooks are either present and reviewed or explicitly tracked as a remaining release-readiness dependency; their absence must not be represented as completed.
- The implementation specification and Master Brief agree on Phase 1F status and remaining approval gates.

Until these criteria are met, the Secure Application Foundation must not be described as fully closed or production-ready.

## 6. Next execution sequence

1. Read the referenced SQL tests, Worker routes/RPC grants and Playwright assertions against the review checklist.
2. Record exact gaps with file/line references; do not add speculative features.
3. Implement the smallest synthetic-only security regression slice for the first evidenced in-scope gap.
4. Run the existing full hosted workflow once on the resulting relevant code revision.
5. Update this crosswalk and the source-of-truth documents with exact commit and CI evidence.

No local services, self-hosted runners, hosted resources, DNS changes, production deployments, paid usage, real learner data or PR merge are required or authorised by this plan.
