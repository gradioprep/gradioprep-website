# Phase 1D — Private PDF/File Controls Acceptance Matrix

> **Current execution checkpoint — 8 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`; the repository is public. Current PR head: `28f5ac45e43d1ff079b20d2aa9aab4ad1ba25a38`. Verified application/migration head: `edc3340a579dc9ef4d27463143dd2bf90ddda1fe`; all commits after that code head are documentation-only. The local WSL checkout was not inspected in this session and remains unverified. Before local work, check `git status --short --branch`; only if clean, fast-forward from origin. Do not start local Supabase/Docker or register a self-hosted runner. Workflow `dc13c80` uses one owner-only push trigger for the dedicated PR branch, ignores docs/Markdown-only changes and cancels stale branch runs; it retains standard `ubuntu-latest` and the complete synthetic SQL/build/browser/backup suite. Exact-code CI [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308) passed 601 PostgreSQL assertions across 17 SQL files, 31/31 Playwright tests, TypeScript/Worker/Vite builds and the database/private-PDF backup/restore round trip. Phase 1E is verified complete for synthetic CI only. Phase 1F security evidence review is the next milestone. Hosted Supabase, R2, paid overage, real learner data, DNS/custom-domain changes, production deployment and PR merge remain separately gated.
**Status:** Phase 1D private PDF/file controls remain verified at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`, exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947). Subsequent Phase 1E work passed exact-code hosted synthetic CI [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308): 601 PostgreSQL assertions/17 SQL files, 31/31 Playwright tests, builds, database/private-PDF backup/restore and cleanup. Phase 1E is verified complete for the synthetic scope. Phase 1F final security evidence review is next. Historical Phase 1D test totals and dated handoff records below remain historical and do not describe current active status.

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