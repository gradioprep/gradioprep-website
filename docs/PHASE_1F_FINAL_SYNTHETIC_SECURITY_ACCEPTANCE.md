# Phase 1F — Final Synthetic Security Acceptance Evidence Crosswalk


> **Authoritative current checkpoint — 8 November 2026:** Repository `gradioprep/gradioprep-website` is public. PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Verified application/test head: `746727d0c103efb8ad2fa59374a9c2c5557ba1a7`; latest Phase 1F security migration head: `5011ec73669ddd3f94e4618a508e63f5ee698fc8`. Exact-head GitHub Actions run [#42479406070](https://github.com/gradioprep/gradioprep-website/actions/runs/42479406070) passed 609 PostgreSQL assertions across 17 SQL files, TypeScript/Worker/Vite builds, 32/32 Playwright tests, synthetic database/private-PDF backup and restore, restored authorization checks, corrupt-archive rejection, local Supabase shutdown, local credential cleanup and a clean credential-free asset build. The restore report recorded one restored database snapshot and one protected PDF checksum. Cloudflare Preview steps were skipped; no Preview or production deployment occurred. Seven Phase 1F runbooks are documented; Founder/security review and provider-specific activation remain outstanding. Local WSL checkout was not inspected and remains unverified. Use standard GitHub-hosted `ubuntu-latest`; do not start local Supabase/Docker or register a self-hosted runner. Hosted Supabase/R2, paid usage, real learner data, external processors, DNS/custom-domain changes, production deployment and PR merge remain separately gated.
**Version:** 0.4-draft
**Date:** 8 November 2026  
**Status:** Phase 1F source review, implementation and exact-head synthetic CI evidence are complete for the documented scope. Formal Phase 1F acceptance is **not yet granted**; Founder/security review and explicit approval remain pending.

## 1. Purpose and boundary

This crosswalk maps the Phase 1E verified baseline and the new Phase 1F evidence to actual migrations, SQL tests, Worker behavior, Playwright coverage and operational runbooks. It is an evidence index, not a declaration of production readiness.

PR #22 remains open, draft and unmerged. Latest application/migration head: `5011ec73669ddd3f94e4618a508e63f5ee698fc8`. Exact-head hosted workflow [#42479011331](https://github.com/gradioprep/gradioprep-website/actions/runs/42479011331) is pending. Earlier Phase 1F runs exposed the role-audit actor-priority defect and a microsecond-sensitive retention fixture; both corrections are included in the current head. The restore-policy increment at `b844e0a` passed [#42477476400](https://github.com/gradioprep/gradioprep-website/actions/runs/42477476400); the Phase 1E baseline at `edc3340` passed [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308).

All work remains synthetic-only and uses standard GitHub-hosted `ubuntu-latest`. Do not start Supabase/Docker on the user's WSL computer, register a self-hosted runner, provision hosted Supabase/R2, use real learner data, change DNS/custom domains, deploy production, incur paid overages or merge PR #22 without separate approval.

## 2. Evidence crosswalk

| Area | Source and test evidence reviewed | Disposition |
|---|---|---|
| Identity, roles and assurance | `identity_roles.test.sql`, `role_scoped_access.test.sql`, `role_revocation.test.sql`, `staff_invitations.test.sql`, `tests/account.spec.ts`, `tests/phase1c-races.spec.ts` | Synthetic role separation, AAL2 gates, revocation and suspended-account race controls are covered by earlier exact-head CI. No hosted Auth readiness is implied. |
| Protected-table/RPC access | `protected_table_permissions.test.sql`, `attempts_rls.test.sql`, role-scoped tests and migration grants | Anonymous/authenticated direct table permissions and narrow privileged RPC grants are covered. Service-role scope remains restricted to specific Worker audit/file lifecycle operations. |
| Cross-learner isolation | `phase1c_adversarial_acceptance.test.sql`, `attempts_rls.test.sql`, `phase1d_private_submission_files.test.sql`, `tests/attempts.spec.ts` | Synthetic own-learner/foreign-learner attempt and private-file boundaries, guessed IDs/paths, Guardian scope and Grader assignment checks are covered. |
| Assessment lifecycle, races and replay | `assessment_workflow.test.sql`, `accepted_submissions.test.sql`, `workflow_integrity.test.sql`, `tests/account.spec.ts`, `tests/phase1c-races.spec.ts` | Concurrent assignment/publication, single-use invitation race, in-flight role revocation/suspension and idempotency coverage are present. |
| Audit attribution and fail-closed behavior | `audit_context.test.sql`, `privileged_write_audit.test.sql`, `learner_write_audit.test.sql`, `tests/audit.spec.ts`, `worker/audit-contract.ts`, `worker/index.ts` | Existing route-level missing-service tests return HTTP 503. Phase 1F now also treats an explicit false RPC result as unacknowledged; a focused regression test is included. Combined exact-head CI is pending. |
| Audit sensitive-data exclusion | `20261108000200_phase1f_audit_role_reason_allowlist.sql`, `20261108000300_phase1f_audit_draft_archive_reason_allowlist.sql`, `audit_context.test.sql`, `role_revocation.test.sql`, `workflow_integrity.test.sql`, invitation tests | Role reasons and draft-archive explanations no longer enter audit metadata. Revocations are attributed to the actual revoking actor. Full archive explanations remain only in intended private history. Canary regressions await exact-head CI #42479011331. Invitation token/hash and invite URL exclusions are also tested. No full historical secret scan is claimed. |
| Private PDF ownership and Storage | `20261106000100_phase1d_private_submission_files.sql`, `phase1d_private_submission_files.test.sql`, `tests/attempts.spec.ts` | Private bucket, no direct browser metadata access, narrow Worker file RPCs, short signed access, guessed-path/direct Storage denial, cross-learner denial and expiry tests are present. The file feature remains an attachment to an existing queued typed submission, not the complete learner PDF workflow. |
| Restored RLS and Storage policy effectiveness | `scripts/phase1e-local-backup.mjs`, `verifyRestoredAuthorization()` | **Verified at code head `b844e0a`, CI #42477476400.** After DB restore the verifier checks own Student A attempt visibility, Student B attempt denial, direct private file-metadata denial, private bucket flag, Storage RLS and anonymous/authenticated object-list denial. The combined `b3e8da7` workflow is pending. |
| Retention, closure and legal holds | `account_deletion_ledger.test.sql` (35 assertions), `account_closure_retention.test.sql` (47 assertions), Phase 1E migrations | Synthetic request, approval, Owner+AAL2, legal-hold precedence including a hold after closure began, retention schedules and backup-expiry metadata are covered. Physical learner-row/external object erasure and a scheduled deletion worker are not implemented. |
| Operational runbooks | `docs/PHASE_1F_OPERATIONAL_SECURITY_RUNBOOKS.md` | Seven procedures are documented and initially reviewed: account/session compromise; secret rotation; cross-learner incident; malicious PDF; DB/Storage outage and restore; failed deletion/legal hold; backup integrity/key loss. Founder/security sign-off and provider-specific adaptation remain pending. |
| Build/browser/backup regression | `.github/workflows/phase1b-verification.yml`, TypeScript/Worker/Vite builds, Playwright, `phase1e:backup:verify` | Phase 1E baseline CI passed. The combined Phase 1F exact-head run #42479011331 is pending. |

## 3. Priority review findings and remediation

| Finding | Classification | Action/evidence |
|---|---|---|
| Restore verifier checked schema/policy counts but not restored authorization behavior | In-scope evidence gap | Fixed in `scripts/phase1e-local-backup.mjs`; restored allow/deny checks passed in #42477476400. |
| Protected-read audit helper treated `data === false` as a normal 404/denial rather than an unacknowledged audit result | In-scope fail-closed contract gap | Fixed: only `isAuditAcknowledged(data,error) === true` is accepted; otherwise the Worker returns HTTP 503. Focused Playwright regression is pending #42478042674. |
| Role-assignment audit copied free-text `role_assignments.reason` into `reason_category`, and actor selection preferred the historical grantor | In-scope sensitive-data and attribution gap | Fixed by migration `20261108000200_phase1f_audit_role_reason_allowlist.sql`: grant uses `granted_by`, revocation uses `revoked_by`, and the category is fixed. Role-revocation assertions await #42479011331. |
| Draft archive audit copied free-text archive reason into `reason_category` | In-scope sensitive-data gap | Fixed by migration `20261108000300_phase1f_audit_draft_archive_reason_allowlist.sql`; the full explanation remains only in private immutable history and audit uses `draft_archived`. Four SQL assertions await #42479011331. |
| Retention fixture sampled ordered timestamps independently | Synthetic regression determinism gap | Fixed in `account_closure_retention.test.sql` by using transaction-stable `now()` for both publication timestamps; production constraint and retention logic are unchanged. |
| No Phase 1F runbook documents existed | Documentation gap | Seven runbooks added in `PHASE_1F_OPERATIONAL_SECURITY_RUNBOOKS.md`; final Owner/security review remains. |

## 4. Explicit deferred requirements

1. **Hosted backup and encryption/key custody:** the verified backup tool is temporary, synthetic and local to the GitHub-hosted CI job. It is not an encrypted hosted backup service. Provider choice, key separation, key custody and recovery-key drills require separate architecture/privacy/cost approval.
2. **Physical deletion:** Phase 1E creates an auditable request, legal-hold and retention inventory. It does not prove deletion of real learner rows or external Storage/R2 objects; no scheduled deletion worker is implemented.
3. **Hosted outage and restore:** the seven runbooks describe required future procedures. A production restore cannot be executed from the local synthetic CI verifier; hosted provider backup, monitoring and restore readiness remain deferred.
4. **External processing and privacy:** external email/OCR/AI/backup processors, provider-region/transfer review, real learner data, statutory privacy notices and qualified legal review remain separate gates.
5. **Audit coverage:** coverage is representative per distinct action, not exhaustive for every route/outcome permutation. This review does not claim a complete historical secret scan.
6. **Runbook activation:** the seven documents need named on-call contacts, final provider-specific console steps, authorised escalation channels, recovery targets and Founder/security sign-off before operational activation.

## 5. Phase 1F exit criteria

Technical synthetic verification is complete. Formal Phase 1F acceptance remains open until:

- The exact application/test head `746727d` passes hosted CI [#42479406070](https://github.com/gradioprep/gradioprep-website/actions/runs/42479406070).
- Every review row has a source/test citation and a pass, gap or deferred disposition.
- Restored RLS/Storage allow/deny checks pass (already verified at #42477476400 and must also remain green on the combined head).
- False audit acknowledgements fail closed; role grant/revocation actor attribution is correct; free-text role reasons and draft-archive explanations are excluded from audit metadata (awaiting #42479011331).
- The seven runbooks receive final Founder/security review; provider-specific activation remains a pre-real-data operational gate.
- The Master Brief, implementation specification and matrices agree on status and remaining gates.
- Founder explicitly accepts the Phase 1F synthetic evidence and authorises the next phase separately.

Until those conditions are met, do not describe the Secure Application Foundation as fully closed or production-ready.

## 6. Current next action

Complete Founder/security review of the evidence crosswalk and seven operational runbooks, record residual risks and required revisions, and obtain explicit acceptance. No further CI run is needed unless code or tests change. Do not start local services.

PR #22 remains open, draft and unmerged. No hosted services, paid usage, real learner data, external processing, DNS change, production deployment or merge is authorised by this plan.


## 7. Latest audit metadata review — 8 November 2026

A scan of the current migrations' audit inserts and reason-category paths found two free-text categories, both addressed on current head `5011ec7`:

- Role-assignment audit: grants use `granted_by`; revocations use `revoked_by`; `reason_category` uses only the fixed action name. The test verifies the revoking Owner, `role_revoked`, and exclusion of the supplied free-text explanation.
- Draft archival: private immutable `assessment_draft_history.archive_reason` keeps the full explanation; the security audit stores only `draft_archived`. Four pgTAP assertions cover preservation and exclusion.

Other reason values reviewed are fixed internal categories or enum-like inputs validated against finite allowlists (for example file-rejection categories and deletion/legal-hold decision categories). The scan does not constitute a complete historical secret scan.

The latest SQL review also exposed a flaky test fixture: independent `clock_timestamp()` calls could make `first_published_at` slightly later than `published_at`. The fixture now uses the same transaction-stable `now()`; no production constraint or retention code was changed. Historical pre-final-verification note (superseded by exact-head CI #42479406070): Exact-head hosted CI [#42479011331](https://github.com/gradioprep/gradioprep-website/actions/runs/42479011331) is pending.


## Phase 1F exact-head technical verification and formal acceptance boundary — 8 November 2026

The complete Phase 1F synthetic suite passed on application/test head `746727d0c103efb8ad2fa59374a9c2c5557ba1a7`, exact-head hosted CI [#42479406070](https://github.com/gradioprep/gradioprep-website/actions/runs/42479406070): 609 PostgreSQL assertions across 17 SQL files, 32/32 Playwright tests, TypeScript/Worker/Vite builds, synthetic database/private-PDF backup and restore, restored authorization checks, corrupt-archive rejection, local Supabase shutdown, local credential cleanup and clean credential-free asset build. The workflow skipped Cloudflare Preview steps; no Preview or production deployment occurred.

Technical synthetic evidence includes restored RLS/Storage allow-deny checks; audit missing/error/false-acknowledgement fail-closed behavior; role grant/revocation actor attribution; fixed audit categories and free-text exclusions for role changes and draft archival; private history preservation; deterministic retention fixtures; private PDF ownership/direct-access controls; and existing retention/legal-hold/closure tests. Coverage is representative per distinct audit action, not exhaustive for every route/outcome permutation.

**Formal Phase 1F acceptance is not yet granted.** The seven operational runbooks require Founder/security review, named operational contacts and provider-specific adaptation before activation. Hosted backup encryption/key custody, physical learner/object deletion, scheduled retention execution, production monitoring, provider-specific activation, real-data privacy/legal review and branded hosted staging remain deferred approval gates. The synthetic CI backup verifier is not a production restore service. PR #22 remains open, draft and unmerged.