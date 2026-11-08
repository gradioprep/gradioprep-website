# Phase 1D — Private PDF/File Controls Acceptance Matrix

> **Authoritative current checkpoint — 8 November 2026:** Repository `gradioprep/gradioprep-website` is public; PR #22 remains open, draft and unmerged. Phase 1D private-file backend controls remain verified. The Phase 2 task-level PDF eligibility increment is verified at `b6dc72f3534b873b63536f5a994fe5027ddcc162`, exact-head CI [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739), which passed 619 PostgreSQL assertions/17 files, 32/32 Playwright tests, builds, synthetic DB/private-PDF backup/restore and cleanup. It adds no new table; it enforces task opt-in and the greater-than-20-word threshold, and records typed/typed-PDF response mode only after private-file acceptance. Founder accepted Phase 1F technical security evidence for synthetic data only. Operational/production conditions remain outstanding. Hosted services, real data, costs, DNS, merge and production deployment require separate approval.

**Status:** Phase 1D private PDF/file controls remain verified at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`, exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947). Subsequent Phase 1E/1F synthetic technical gates have passed and the Founder accepted Phase 1F technical evidence for the documented synthetic scope. The first Phase 2 optional-PDF eligibility increment passed exact-head CI [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739).

## 1. Scope and boundary

This increment implements the private-file backend foundation only. All testing used disposable local Supabase and synthetic accounts/records. No hosted bucket/backend, paid usage, real learner file, external OCR/AI processor, email, public Preview, production deployment, DNS change or merge was involved.

The file route attaches a PDF to an existing queued human-assessment submission. The existing submission-acceptance RPC remains typed-response only. This increment does **not** implement the full learner-facing optional PDF choice/upload journey or a PDF-only submission acceptance path. OCR, page extraction, corrected transcripts, split-screen grading workspace, full feedback UX and timer/analytics remain later work.

## 2. Storage, validation and lifecycle

| Control | Implemented behaviour |
|---|---|
| Bucket | Local Supabase Storage bucket `private-submissions`; non-public; declared PDF MIME only; maximum 10 MiB (10,485,760 bytes) |
| Metadata | Private table `private.submission_files`; RLS enabled; no direct table grants to browser roles or service_role; narrow server-only lifecycle RPCs |
| Object keys | Opaque UUID-based paths; no learner name, email or other personal identifier |
| PDF validation | Worker validates extension, declared MIME, actual `%PDF-` signature, parser success, encryption state, byte size and page count |
| Limits | PDF only; maximum 10 MiB and 10 pages; malformed/encrypted/password-protected files rejected |
| Integrity | Worker computes SHA-256; stores size, MIME, page count, file version and upload lifecycle timestamps/status |
| Accepted originals | Metadata is immutable; Storage upload does not overwrite; a replacement upload creates a new file version/path |
| Temporary uploads | Pending uploads expire after 15 minutes; incomplete/expired objects enter a cleanup-pending state |
| Read access | Database rechecks active account, own-learner scope, Guardian consent, current Grader assignment+AAL2 or Owner+AAL2 before Worker issues a 60-second signed URL |
| Audit | Metadata-only upload, access and cleanup events; PDFs, answer text, signed URLs and tokens are not written to audit records |
| Cleanup | Owner+AAL2 endpoint claims up to 50 expired/incomplete uploads, removes objects and records abandonment only after Storage confirms object absence. A scheduled cleanup runner is not implemented. |

## 3. Worker routes

| Route | Access and purpose |
|---|---|
| `POST /api/v1/learner/submissions/:submissionId/file` | Active Student; exact own queued/uploadable submission; one multipart PDF; Worker validates and stores privately |
| `GET /api/v1/submissions/:submissionId/file` | Own Student; or linked Guardian with verified submission-view consent; or current assigned Grader+AAL2; or Owner+AAL2; returns authorized short-lived signed access |
| `POST /api/v1/owner/submission-files/cleanup` | Owner+AAL2; claims and cleans expired/incomplete pending objects |

The protected physical inventory is **26 tables (18 public, eight private)**. The endpoint matrix contains **32 HTTP method/path rows** (29 existing Phase 1C routes plus these three). The prior 25 Worker-audited routes remain; upload and cleanup bring Worker-audited routes to **27**. File-read allow/deny is written transactionally through its database authorization RPC. Ordinary business-data reads and writes remain caller-scoped; the Worker service-role client is limited to audit ingestion and this narrow file/Storage lifecycle.

## 4. Test evidence

Dedicated SQL file `supabase/tests/phase1d_private_submission_files.test.sql` provides **25 pgTAP assertions** covering private bucket configuration, metadata permissions, RLS, service-only RPC grants, upload metadata, learner ownership, Guardian/Grader/Owner scope and assurance, revoked Grader denial, accepted-file immutability, expired upload denial and cleanup transitions.

Playwright coverage includes anonymous upload/read denial; invalid extension, MIME and signature; malformed/encrypted PDF rejection; over-limit page/byte rejection; valid private upload/download; direct Storage object access denied for anonymous and authenticated browsers; guessed object paths denied; one-second signed URL rejected after expiry; cross-learner access denied; and unassigned Grader access denied.

Synthetic account fixtures are deliberately isolated: Student C is used for cross-learner testing, Guardian D for the global-signout test, Student A for the MFA/submission journey and Student B for the separate account-recovery journey. This prevents parallel browser tests from revoking another test's session.

## 5. Acceptance and next step

Phase 1D passed exact-head local synthetic CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) including SQL/RLS, build, Playwright, cleanup and asset build. **Historical next-phase statement (superseded):** Phase 1E backup, recovery and deletion has since passed the exact-code synthetic CI run recorded above; Phase 1F is the next secure-foundation milestone. Phase 1F final synthetic security acceptance follows only after Phase 1E passes. The full flagship learner PDF/OCR/grading workflow remains future work. Branded staging on `gradioprep.com` with an isolated hosted synthetic backend remains mandatory before final Diagnostic/Evaluation Report acceptance and requires separate hosted-resource/DNS approval.

## Phase 1E handoff status — 7 November 2026

Phase 1D remains verified at the checkpoint above; that does not claim that later Phase 1E work passed. Migrations `20261106000200_phase1e_account_deletion_ledger.sql` and `20261106000300_phase1e_account_closure_retention_plan.sql` exist with paired tests declaring 35 and 47 assertions. **Historical handoff — superseded by the verified Phase 1E checkpoint above:** At that earlier point both SQL suites were untested and run #42208654326 had no assigned runner. The subsequent exact-code hosted CI run passed both suites as part of 601 PostgreSQL assertions across 17 SQL files. No self-hosted runner was needed or should be registered.

## 6. Phase 1F restored Storage/RLS authorization evidence — 8 November 2026

The synthetic backup/restore verifier now checks the restored database under application roles after restoring the database dump. It confirms the `private-submissions` bucket remains non-public, Storage object RLS remains enabled, Student A retains visibility of own seeded attempts but not Student B's attempt, authenticated browser users cannot directly read `private.submission_files`, and anonymous/authenticated roles cannot list objects in the private bucket. The script retains the existing private-PDF checksum round trip and corrupt-archive rejection.

This post-restore authorization verifier passed at application code head `b844e0a`, exact-head GitHub Actions run [#42477476400](https://github.com/gradioprep/gradioprep-website/actions/runs/42477476400). Combined Phase 1F head `b3e8da7` is being re-verified in [#42478042674](https://github.com/gradioprep/gradioprep-website/actions/runs/42478042674), currently pending.

This remains synthetic CI evidence only. It is not proof of hosted RLS/Storage configuration, hosted backup encryption/key custody, R2 lifecycle, external-object deletion or production disaster recovery. The complete learner-facing optional PDF submission/OCR/grading feature remains out of scope.


## Historical Phase 1F exact-head technical verification and formal acceptance boundary — superseded by Section 7

The complete Phase 1F synthetic suite passed on application/test head `746727d0c103efb8ad2fa59374a9c2c5557ba1a7`, exact-head hosted CI [#42479406070](https://github.com/gradioprep/gradioprep-website/actions/runs/42479406070): 609 PostgreSQL assertions across 17 SQL files, 32/32 Playwright tests, TypeScript/Worker/Vite builds, synthetic database/private-PDF backup and restore, restored authorization checks, corrupt-archive rejection, local Supabase shutdown, local credential cleanup and clean credential-free asset build. The workflow skipped Cloudflare Preview steps; no Preview or production deployment occurred.

Technical synthetic evidence includes restored RLS/Storage allow-deny checks; audit missing/error/false-acknowledgement fail-closed behavior; role grant/revocation actor attribution; fixed audit categories and free-text exclusions for role changes and draft archival; private history preservation; deterministic retention fixtures; private PDF ownership/direct-access controls; and existing retention/legal-hold/closure tests. Coverage is representative per distinct audit action, not exhaustive for every route/outcome permutation.

**Formal Phase 1F acceptance is not yet granted.** The seven operational runbooks require Founder/security review, named operational contacts and provider-specific adaptation before activation. Hosted backup encryption/key custody, physical learner/object deletion, scheduled retention execution, production monitoring, provider-specific activation, real-data privacy/legal review and branded hosted staging remain deferred approval gates. The synthetic CI backup verifier is not a production restore service. PR #22 remains open, draft and unmerged.


## 7. Phase 2 task-level optional PDF eligibility — verified extension — 8 November 2026

The Phase 1D private bucket and file lifecycle remain the trusted backend for the first Phase 2 optional-PDF increment. Append-only migration `20261108000400_phase2_optional_pdf_response_eligibility.sql` adds `task_versions.pdf_response_enabled` (default false) and database constraint `task_versions_pdf_response_threshold_check`, requiring `ideal_words > 20` when PDF response is enabled. It adds `assessment_submissions.response_mode` (`typed` / `typed_pdf`) and a database guard that blocks direct or premature typed-PDF state changes.

The Worker and upload lifecycle RPC both enforce task opt-in and threshold. Finalisation rechecks eligibility and changes the submission to `typed_pdf` only in the same transaction that accepts the private PDF. Synthetic MYP task A opts in; synthetic Cambridge task B remains typed-only. SQL coverage includes the 20-word boundary, typed-only denial without a pending file record and forged response-mode rejection. Existing 10 MB/10-page PDF validation, private Storage, opaque non-overwriting paths, ownership/assignment checks, signed URL expiry, audit and cleanup remain unchanged.

Exact-head CI [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739) passed 619 PostgreSQL assertions across 17 SQL files, 32/32 Playwright tests, TypeScript/Worker/Vite builds, synthetic backup/restore, shutdown and credential cleanup. No Preview was deployed because this was backend-only. This increment does not add PDF-only submission acceptance, OCR, a teacher split-screen or learner-facing upload UI. No hosted services, external processing, paid use or real learner data were introduced.
