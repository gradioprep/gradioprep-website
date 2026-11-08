# Phase 1F — Final Synthetic Security Acceptance Evidence Crosswalk

**Version:** 0.2-draft  
**Date:** 8 November 2026  
**Status:** Source review and remediation in progress. Final Phase 1F acceptance is **not yet granted**.

## 1. Purpose and boundary

This crosswalk maps the Phase 1E verified baseline and the new Phase 1F evidence to actual migrations, SQL tests, Worker behavior, Playwright coverage and operational runbooks. It is an evidence index, not a declaration of production readiness.

PR #22 remains open, draft and unmerged. Latest application/migration head: `b3e8da7a12d3cd5dcb2710151334a58976975965`. Exact-head hosted workflow [#42478042674](https://github.com/gradioprep/gradioprep-website/actions/runs/42478042674) is pending. The restore-policy increment at `b844e0a` passed [#42477476400](https://github.com/gradioprep/gradioprep-website/actions/runs/42477476400); the Phase 1E baseline at `edc3340` passed [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308).

All work remains synthetic-only and uses standard GitHub-hosted `ubuntu-latest`. Do not start Supabase/Docker on the user's WSL computer, register a self-hosted runner, provision hosted Supabase/R2, use real learner data, change DNS/custom domains, deploy production, incur paid overages or merge PR #22 without separate approval.

## 2. Evidence crosswalk

| Area | Source and test evidence reviewed | Disposition |
|---|---|---|
| Identity, roles and assurance | `identity_roles.test.sql`, `role_scoped_access.test.sql`, `role_revocation.test.sql`, `staff_invitations.test.sql`, `tests/account.spec.ts`, `tests/phase1c-races.spec.ts` | Synthetic role separation, AAL2 gates, revocation and suspended-account race controls are covered by earlier exact-head CI. No hosted Auth readiness is implied. |
| Protected-table/RPC access | `protected_table_permissions.test.sql`, `attempts_rls.test.sql`, role-scoped tests and migration grants | Anonymous/authenticated direct table permissions and narrow privileged RPC grants are covered. Service-role scope remains restricted to specific Worker audit/file lifecycle operations. |
| Cross-learner isolation | `phase1c_adversarial_acceptance.test.sql`, `attempts_rls.test.sql`, `phase1d_private_submission_files.test.sql`, `tests/attempts.spec.ts` | Synthetic own-learner/foreign-learner attempt and private-file boundaries, guessed IDs/paths, Guardian scope and Grader assignment checks are covered. |
| Assessment lifecycle, races and replay | `assessment_workflow.test.sql`, `accepted_submissions.test.sql`, `workflow_integrity.test.sql`, `tests/account.spec.ts`, `tests/phase1c-races.spec.ts` | Concurrent assignment/publication, single-use invitation race, in-flight role revocation/suspension and idempotency coverage are present. |
| Audit attribution and fail-closed behavior | `audit_context.test.sql`, `privileged_write_audit.test.sql`, `learner_write_audit.test.sql`, `tests/audit.spec.ts`, `worker/audit-contract.ts`, `worker/index.ts` | Existing route-level missing-service tests return HTTP 503. Phase 1F now also treats an explicit false RPC result as unacknowledged; a focused regression test is included. Combined exact-head CI is pending. |
| Audit sensitive-data exclusion | `20261108000200_phase1f_audit_role_reason_allowlist.sql`, `audit_context.test.sql`, `20261105000900_phase1c_worker_only_audit_ingestion.sql`, invitation tests | Fixed role-action categories replace free-form role reasons in audit metadata. Synthetic canary assertion is added but awaits combined exact-head CI. Invitation token/hash and invite URL exclusions are already tested. No full historical secret scan is claimed. |
| Private PDF ownership and Storage | `20261106000100_phase1d_private_submission_files.sql`, `phase1d_private_submission_files.test.sql`, `tests/attempts.spec.ts` | Private bucket, no direct browser metadata access, narrow Worker file RPCs, short signed access, guessed-path/direct Storage denial, cross-learner denial and expiry tests are present. The file feature remains an attachment to an existing queued typed submission, not the complete learner PDF workflow. |
| Restored RLS and Storage policy effectiveness | `scripts/phase1e-local-backup.mjs`, `verifyRestoredAuthorization()` | **Verified at code head `b844e0a`, CI #42477476400.** After DB restore the verifier checks own Student A attempt visibility, Student B attempt denial, direct private file-metadata denial, private bucket flag, Storage RLS and anonymous/authenticated object-list denial. The combined `b3e8da7` workflow is pending. |
| Retention, closure and legal holds | `account_deletion_ledger.test.sql` (35 assertions), `account_closure_retention.test.sql` (47 assertions), Phase 1E migrations | Synthetic request, approval, Owner+AAL2, legal-hold precedence including a hold after closure began, retention schedules and backup-expiry metadata are covered. Physical learner-row/external object erasure and a scheduled deletion worker are not implemented. |
| Operational runbooks | `docs/PHASE_1F_OPERATIONAL_SECURITY_RUNBOOKS.md` | Seven procedures are documented and initially reviewed: account/session compromise; secret rotation; cross-learner incident; malicious PDF; DB/Storage outage and restore; failed deletion/legal hold; backup integrity/key loss. Founder/security sign-off and provider-specific adaptation remain pending. |
| Build/browser/backup regression | `.github/workflows/phase1b-verification.yml`, TypeScript/Worker/Vite builds, Playwright, `phase1e:backup:verify` | Phase 1E baseline CI passed. The combined Phase 1F exact-head run #42478042674 is pending. |

## 3. Priority review findings and remediation

| Finding | Classification | Action/evidence |
|---|---|---|
| Restore verifier checked schema/policy counts but not restored authorization behavior | In-scope evidence gap | Fixed in `scripts/phase1e-local-backup.mjs`; restored allow/deny checks passed in #42477476400. |
| Protected-read audit helper treated `data === false` as a normal 404/denial rather than an unacknowledged audit result | In-scope fail-closed contract gap | Fixed: only `isAuditAcknowledged(data,error) === true` is accepted; otherwise the Worker returns HTTP 503. Focused Playwright regression is pending #42478042674. |
| Role-assignment audit copied free-text `role_assignments.reason` into `reason_category` | In-scope sensitive-data gap | Fixed by migration `20261108000200_phase1f_audit_role_reason_allowlist.sql`; audit now records only `role_granted`, `role_revoked` or `role_assignment_updated`. Canary regression awaits #42478042674. |
| No Phase 1F runbook documents existed | Documentation gap | Seven runbooks added in `PHASE_1F_OPERATIONAL_SECURITY_RUNBOOKS.md`; final Owner/security review remains. |

## 4. Explicit deferred requirements

1. **Hosted backup and encryption/key custody:** the verified backup tool is temporary, synthetic and local to the GitHub-hosted CI job. It is not an encrypted hosted backup service. Provider choice, key separation, key custody and recovery-key drills require separate architecture/privacy/cost approval.
2. **Physical deletion:** Phase 1E creates an auditable request, legal-hold and retention inventory. It does not prove deletion of real learner rows or external Storage/R2 objects; no scheduled deletion worker is implemented.
3. **Hosted outage and restore:** the seven runbooks describe required future procedures. A production restore cannot be executed from the local synthetic CI verifier; hosted provider backup, monitoring and restore readiness remain deferred.
4. **External processing and privacy:** external email/OCR/AI/backup processors, provider-region/transfer review, real learner data, statutory privacy notices and qualified legal review remain separate gates.
5. **Audit coverage:** coverage is representative per distinct action, not exhaustive for every route/outcome permutation. This review does not claim a complete historical secret scan.
6. **Runbook activation:** the seven documents need named on-call contacts, final provider-specific console steps, authorised escalation channels, recovery targets and Founder/security sign-off before operational activation.

## 5. Phase 1F exit criteria

Phase 1F remains open until:

- The exact combined application/migration head `b3e8da7` passes hosted CI [#42478042674](https://github.com/gradioprep/gradioprep-website/actions/runs/42478042674).
- Every review row has a source/test citation and a pass, gap or deferred disposition.
- Restored RLS/Storage allow/deny checks pass (already verified at #42477476400 and must also remain green on the combined head).
- False audit acknowledgements fail closed and role-reason canary text is excluded (awaiting combined CI).
- The seven runbooks receive final Founder/security review; provider-specific activation remains a pre-real-data operational gate.
- The Master Brief, implementation specification and matrices agree on status and remaining gates.
- Founder explicitly accepts the Phase 1F synthetic evidence and authorises the next phase separately.

Until those conditions are met, do not describe the Secure Application Foundation as fully closed or production-ready.

## 6. Current next action

Complete the pending exact-head hosted workflow #42478042674 and inspect its PostgreSQL, Worker/browser, backup/restore and cleanup steps. Repair only failures proven by that run. Do not trigger duplicate runs or start local services.

PR #22 remains open, draft and unmerged. No hosted services, paid usage, real learner data, external processing, DNS change, production deployment or merge is authorised by this plan.
