# Phase 1D — Private PDF/File Controls Acceptance Matrix

**Status:** Phase 1D implementation is verified at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef` in PR #22, exact-head CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947). The workflow passed local Supabase startup/reset/seed, **519 PostgreSQL/pgTAP assertions across 15 SQL files**, TypeScript/Worker/Vite builds, **31/31 Playwright tests**, local Supabase shutdown, local-only credential cleanup and the clean credential-free asset build. Preview creation/update steps were skipped; no public Preview or production deployment occurred.

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

Phase 1D passed exact-head local synthetic CI [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) including SQL/RLS, build, Playwright, cleanup and asset build. The next secure-foundation phase is **Phase 1E — backup, recovery and deletion**. Phase 1F final synthetic security acceptance follows. The full flagship learner PDF/OCR/grading workflow remains future work. Branded staging on `gradioprep.com` with an isolated hosted synthetic backend remains mandatory before final Diagnostic/Evaluation Report acceptance and requires separate hosted-resource/DNS approval.