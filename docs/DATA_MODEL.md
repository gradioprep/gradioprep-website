# Logical Data Model — Curriculum, Practice and Assessment

**Status:** Provider-independent logical model with approved Supabase Auth/PostgreSQL/Storage architecture. Phase 1B and Phase 1C-A/B/C/D are verified at their recorded local-synthetic checkpoints. PR #22 remains open, draft and unmerged; verified code/test head `5dba933dce39b05c69a6616e5bb730d404e3b5a2`, exact-head run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 29/29 Playwright tests. No Preview or production deployment occurred for this checkpoint.

The endpoint authorization/audit matrix contains 29 HTTP method/path rows; all 25 Worker-audited routes have fail-closed audit-service outage coverage. Phase 1C-E correlation evidence is representative per distinct action, not exhaustive for every outcome. Successful persistence maps Worker `student_attempt_create` to `attempt_created` and `grader_assessment_draft_save` to `assessment_draft_saved`; denied/failed events retain Worker action names. The adversarial acceptance matrix maps existing actor/assurance, RLS, forgery, replay and passing concurrency evidence. Only simultaneous acceptance of the same invitation token and revocation/suspension racing an in-flight privileged request remain as synchronized Phase 1C-F tests. Phase 1D remains blocked.

The former browser-callable generic audit writers are revoked; only the trusted Worker service-role client can call `record_worker_audit_outcome`, and that client is restricted to audit ingestion. Application reads/writes remain caller-scoped. The protected physical inventory remains **25 tables (18 public, seven private)**. Credit purchasing, physical credit ledger, course entitlements, payment workflow and commercial Admin dashboard remain logical future records, not live tables. See `docs/PHASE_1C_ENDPOINT_AUTHORIZATION_AUDIT_MATRIX.md` and `docs/PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md`.

**Revision policy:** Any approved or reviewed part of this data model may be amended later. Record the change and reason in version control, update dependent documentation, and re-review changes that affect curriculum alignment, answer-key privacy, learner records or authorization.


**Verified Phase 1B MFA and staff-invitation implementation checkpoint — 3 November 2026:** PR #22 remains open, draft and unmerged on feature/phase-1b-local-auth-api. Exact verified commit: 1953bd1d9141f8033e00166cd10aee89a8d563e6. GitHub Actions run [#41598979870](https://github.com/gradioprep/gradioprep-website/actions/runs/41598979870) passed on that exact SHA: local Supabase reset/seed, PostgreSQL RLS and 24 staff-invitation pgTAP assertions, TypeScript/Vite/Worker build, 20/20 Playwright tests, local credential cleanup and clean public-Preview build. Tests verify owner AAL2 invitation create/list/revoke, role allow-list, email match and verified-email acceptance, AAL1 denial, invitation expiry/revocation/replay protections and admin/anonymous denial. Tokens are 256-bit random bearer values; only SHA-256 hashes are stored, expiry is capped at seven days, and no email is sent. A same-page hashchange listener consumes the fragment when the Account route is already mounted and removes the token from the visible URL. Cloudflare Workers Builds deployed the same exact commit; stable branch Preview is https://feature-phase-1b-local-auth-api-gradioprep-website.wandering-scene-1822.workers.dev and immutable Preview is https://98207523-gradioprep-website.wandering-scene-1822.workers.dev (deployment 98207523-8ea0-46c8-a6c7-20e3d9ea15f0). The public Preview is disconnected from hosted Supabase and displays the safe account-unavailable state; authenticated invitation flows were tested only against local synthetic Supabase. No hosted provisioning, real learner data, paid service, external email, merge, production deployment or DNS change occurred.

**Verified Phase 1C physical data-model slice — 3 November 2026:** On code commit `05544d1a394e2e480b7cd2dd9f55100b6998ee71` in draft PR #22, migrations add physical tables `public.task_versions`, `public.task_version_prompts`, `public.attempts`, `public.attempt_responses` and `public.grader_assignments`; the private schema adds `private.attempt_response_versions`. Worker operations support learner attempt listing, creation, reading, typed-response save and submit, grader queue/detail, and owner assignment. Narrow RPCs are `create_attempt`, `save_attempt_response`, `submit_attempt` and `assign_attempt_to_grader`. Database logic derives the learner from `auth.uid()`, validates active account/student role, published typed task and active enrolment, enforces the attempt state and prompt/task-version relationship, stamps submission time and generated word counts/response versions, and preserves previous response values in a private append-only history table. RLS scopes learner data to its owner; guardian read scope requires an active verified guardian link with explicit submission-view consent; grader reads are assignment-scoped and AAL2-protected; owner read/assignment requires AAL2; admin does not inherit grader or student access. The Worker uses caller-scoped authentication, and no service-role client is present. Exact-head run [#41613490244](https://github.com/gradioprep/gradioprep-website/actions/runs/41613490244) passed 116 SQL/pgTAP assertions across four files and 24/24 Playwright tests. This is a first slice, not a complete human-assessment or PDF submission data model.

## 1. Design rules

1. Keep programme, course, subject, level/year/stage, syllabus edition, objective, skill, task and rubric as distinct concepts.
2. A grade-equivalent label is display metadata, not the authoritative course identity.
3. Give content stable IDs and versions. Student attempts and assessments must preserve the content/rubric version actually used.
4. Store evidence of learning separately from calculated dashboard summaries. Never turn missing evidence into a zero or an invented mastery score.
5. Treat automatic practice checks and human assessments as different record types and label them differently in the interface.
6. Enforce access on the server and at the database level. Hiding a page or button is not security.
7. Use fictitious data in the prototype. Never place credentials, API keys, student submissions or private customer information in Git.
8. Do not enable paid email, payment, AI or other API services without the required cost, privacy and operational approval.

## 2. Core records and their relationships

This is a provider-independent logical model, not a complete live SQL schema. The identity/security subset described in the status and implementation-boundary notes is physically implemented in the local synthetic Supabase stack; the remaining records are still design-level. Names can be adapted during implementation as long as the relationships, constraints and access rules are preserved.

### Curriculum and content

| Record | Purpose and key fields | Relationships / rules |
|---|---|---|
| `programmes` | Stable ID, code, name, provider/authority | Examples: IB MYP, Cambridge Lower Secondary, Cambridge IGCSE |
| `subjects` | Stable ID, name | English first; other subjects later |
| `courses` | Stable ID, programme ID, subject ID, course name | Identifies a specific course within a programme |
| `pathways` | Stable ID, course ID, year/stage code, learner-facing label, optional grade-equivalent label, sort order | Never use grade-equivalent label as a replacement for programme/course/stage identity |
| `syllabus_editions` | ID, course ID, edition/code, effective period, official URL, verification status, checked date, reviewer | Edition must be explicitly verified; do not assume the latest version |
| `syllabus_objectives` | ID, syllabus-edition ID, reference/code, original-language summary, source reference | Use references accurately; avoid wholesale copying of protected syllabus text |
| `skills` | ID, stable skill code, learner-friendly name, description, version/status | Skills may be reused only where the mapping is valid |
| `skill_objective_mappings` | Skill ID, objective ID, mapping rationale, reviewer, review status | Many-to-many mapping; a skill can map to multiple objectives and vice versa |
| `units` | ID, pathway ID, title, sequence, release state, version | A pathway contains ordered units |
| `lessons` | ID, unit ID, title, learning objective, body metadata, sequence, release state, version | Content belongs to a unit and has a versioned lifecycle |
| `lesson_blocks` | ID, lesson version ID, block type, sequence, structured content | Allows text, worked example, callout and other reusable blocks |
| `tasks` | ID, task type, prompt/instructions, response type, expected minimum/ideal words, approved response range, PDF-enabled flag, optional task time allowance, timer/pause policy version, difficulty label where justified, estimated time, release state, version | Enable typed-or-PDF only for approved written tasks whose expected response is more than 20 words; keep typing available; store task/rubric timing metadata by version; do not expose answer keys by default |
| `task_skill_mappings` | Task ID, skill ID, mapping role/weight if approved, review status | Use mapping weights only if the academic method is documented and approved |
| `answer_keys` | Task version ID, expected answer, rationale/explanation, accepted variants as appropriate | Restrict access until the intended reveal state; keep production keys server-side |
| `rubrics` and `rubric_versions` | Stable rubric ID, version, task family, version date, approval state | Rubric versions are immutable once used for a published assessment |
| `rubric_criteria` | Rubric version ID, criterion ID, label, descriptor/levels, scoring rules | Task-specific rubric scope and score rules are explicit |
| `task_rubric_mappings` | Task version ID, rubric version ID, required credits, grading tier, credit-policy version, expected response format/range, ideal word target, predicted grader minutes, complexity metadata | Server-calculated tier and credit requirement are visible before submission; word bands are guidance, not learner input caps; task/rubric scope is versioned |

### Accounts, relationships and access

| Record | Purpose and key fields | Relationships / rules |
|---|---|---|
| `profiles` | Auth-provider user ID, display name, timezone/preferences, created/updated timestamps | Login credentials are managed by the authentication provider, not stored in plaintext application tables |
| `role_assignments` | User ID, role, assigned by, assigned at, revoked at | Roles include student/guardian, grader, admin and owner; role changes are auditable |
| `guardian_learner_links` | Guardian user ID, learner user ID, relationship, consent/verification state, timestamps | A guardian sees only learners with a valid authorized link |
| `course_enrolments` | Learner ID, pathway ID, status, start/end dates | Controls which pathway is on the learner's dashboard; a UI link alone never grants access |
| private.staff_invitations | Invitation ID, normalized invited email, allow-listed role (grader/admin), SHA-256 token hash, creator, created/expiry timestamps, accepter/accepted timestamp, revoker/revoked timestamp | Private-schema table with no direct client grants. Owner-only AAL2 RPCs create/list/revoke; acceptance requires an active account, the matching verified Auth email and AAL2. Tokens are single-use, expire within seven days, and are never stored or returned in plaintext after initial link creation. Creation, revocation and acceptance are audited. The local UI returns a fragment-based copy link only; no email is sent |

### Unit content planning and release readiness

The current frontend defines static unit-planning records as a code-level precursor to a future `unit_content_plans` table. Each plan should eventually record:

- Target unit/pathway IDs and exact content version.
- Official syllabus edition, source URL, date checked and verified objective codes.
- Approved learning objective.
- Linked lesson and practice-question IDs.
- Answer-key review state.
- Academic reviewer/date, content rights/source note and accessibility review state.
- Explicit release approver/date and release state.

The `src/content/unitReadiness.ts` helper calculates eight gates from these fields. The first IB MYP Year 1 pilot has an academic content-review pass recorded for preview version 1, and its learner lesson/practice IDs and answer-key review are represented in the static fixture. Official curriculum mapping remains unverified because the applicable guide edition has not been confirmed; official objective codes remain empty. Rights/accessibility reviews and explicit release approval remain outstanding.

The client imports learner-safe `src/content/pilotLearnerLesson.ts` for lesson content and `src/content/pilotReviewSummary.ts` for answer-free pathway/release metadata. Neither includes correct-answer IDs or model answers. The teacher/editor brief (`src/content/pilotUnitDraft.ts`) and teacher answer guide (`src/content/pilotLessonPack.ts`) are not imported into the client module graph. This is source separation for a prototype, not a production security boundary. Production must enforce learner/teacher access server-side and must not ship answer keys in unrestricted learner bundles. The readiness checklist is read-only and is not a database or release mechanism.
### Learning activity and progress evidence

| Record | Purpose and key fields | Relationships / rules |
|---|---|---|
| `attempts` | ID, learner ID, task version ID, status, started/saved/submitted timestamps | Owns one or more responses; separate from a human assessment |
| `attempt_responses` | ID, attempt ID, prompt/part ID if relevant, response version, response body or protected storage reference, saved timestamp | Version or otherwise preserve a response when meaningful edits occur |
| `automatic_checks` | Attempt/response ID, checker version, result, rationale, checked timestamp | Only for tasks with a documented automatic answer check; never label as human-graded |
| `learning_events` | ID, learner ID, event type, related record ID, event time, minimal metadata | Append-oriented evidence for lesson completion, question attempts, revision and other defined activity |
| `skill_evidence` | Learner ID, skill ID, evidence source ID/type, evidence date, method/version | Evidence records explain status changes; mastery/progress rules must be separately defined and approved |
| `recommendation_rules` | Rule ID/version, triggering conditions, action/skill, explanation, enabled state | Enables transparent rule-based next steps; do not call them AI recommendations |
| `recommendation_events` | Learner ID, rule version, reason, target, created time, outcome if known | Supports explanation and evaluation of recommendations |

### Human assessment, credits and administration

| Record | Purpose and key fields | Relationships / rules |
|---|---|---|
| `assessment_submissions` | ID, learner ID, task version ID, status, accepted time, due time/SLA, grading tier, required credits, credit-policy version, entitlement/credit-reservation reference | Acceptance is server-side; snapshot the task/rubric/tier/credit/SLA requirement and check capacity, course/task eligibility and entitlement before committing |
| `submission_versions` | Submission ID, version number, response snapshot/protected storage reference, created by/time | Preserve the original accepted response and every later revision; do not overwrite history |
| `grader_assignments` | Submission ID, grader user ID, assigned by/time, status | Graders may access only assignments they are authorized to grade |
| `assessments` | Submission ID, grader ID, rubric version ID, draft/final/published state, timestamps | A draft is not visible as published feedback |
| `assessment_versions` | Assessment ID, version number, score summary where valid, comments, author, timestamp, change reason | Preserve drafts/final versions and record reasons for changes; never replace a published version silently |
| `criterion_results` | Assessment version ID, criterion ID, mark where applicable, evidence excerpt/reference, comment | Score, comment and evidence must align with the selected rubric |
| `assessment_audit_events` | Assessment/criterion ID, actor, change, reason, timestamp | Append-oriented audit trail for mark/comment edits and administrative decisions |
| `credit_ledger` | Learner ID, transaction type (purchase/reserve/consume/release/refund/expiry/adjustment), credit delta, purchase/use/refund/expiry reference, task/submission reference, policy version, actor, timestamp, reason | Append-only audit source of truth; server-derived entries only; never trust a client-supplied balance or let the browser modify credits |
| `capacity_slots` or equivalent server-side controls | Date/window, accepted workload, available capacity, applicable SLA | Acceptance must be blocked when it cannot meet the promised 24-hour SLA; preserve draft and entitlement safely |
| `course_entitlements` | Learner ID, course/pathway, entitlement source/type, status, grantor/provider transaction, effective start/end/expiry, reason, created/revoked timestamps | Separate from grading credits; supports Study Lab, complimentary cohort grants and paid course access; purchase activation follows trusted payment confirmation |
| `payment_transactions` | Learner ID, provider/reference, product/purchase type, amount/currency, status, trusted confirmation/webhook reference, refund/chargeback metadata, timestamps | Future logical record; idempotent, server-verified and auditable; do not activate credits/course entitlement from client claims |
| `credit_policy_versions` | Version, tier bands, credit unit, predicted-time formula, effective dates, approval reference | Freeze the applicable pricing/credit policy version on every accepted submission; never retroactively reprice it |
| `private_qa_records` | Assessment-version ID, QA revision, checks, status, explanation, uncertainty, reviewer action, reviewer and timestamp | Physically implemented as `private.private_qa_records`; RLS enabled, no direct client table grants, append-only. The `create_private_qa_record` and `get_private_qa_records` RPCs independently require an active Owner at AAL2. Student, verified guardian, grader and operational Admin access is denied. No delegated QA-grant pathway is implemented. |
| `admin_audit_log` | Actor, action, target record, reason, timestamp, minimal before/after reference | Privileged actions and role changes must be individually attributable and auditable |

### PDF written responses, OCR, grading feedback and timing

These are proposed logical records to extend the existing human-assessment model. They are not live tables or migrations.

| Record | Purpose and key fields | Relationships / rules |
|---|---|---|
| submission_files | Submission ID, private storage object key, original file name for display, verified MIME/signature, byte size, page count, checksum, upload/accept timestamps, retention state | Original PDF only; maximum 10 MB and 10 pages in pilot; no public URLs; non-identifying object keys; assignment-scoped file access |
| submission_page_extractions | Submission/file ID, page number, extraction method (PDF text layer/OCR), raw text, confidence/status, coordinates, processing timestamp, error metadata | One record per page/method/version; raw extraction is immutable; teacher-corrected transcript is separately versioned |
| transcript_corrections | Submission/page ID, corrected text, editor, timestamp, change reason, source extraction version | Never overwrite original PDF or raw OCR; teacher correction is an auditable grading aid |
| feedback_suggestion_sets | Submission ID, task/rubric version, model/prompt version, generation time, quota/cache status, ten proposed suggestions | Private teacher-only draft; not student-visible and never auto-published |
| feedback_suggestion_items | Suggestion-set ID, item index, suggested text, optional criterion/skill tag | Exactly ten suggestions per successful generation set; selection/editing by the teacher is recorded in the published feedback version |
| timer_sessions | Attempt/submission ID, task timing-rule version, server start/submit timestamps, elapsed response duration, authorised adjustment/extension and accommodation mode | Advisory countdown; server clock continues in background/after refresh; no learner pause/resume; upload/OCR time excluded; adjustments are authorised and audited |
| timer_events | Timer session ID, event type (start/save/expire/submit/authorised adjustment), server event time, minimal non-content context | Append-oriented; no keystroke/focus/browsing surveillance; no learner pause/resume events; do not trust client-only elapsed values |
| submission_sla_events | Submission ID, accepted time, due time, first feedback publication time, actual turnaround, remaining/overdue duration, SLA state | 24-hour target snapshot is fixed at acceptance; later edits do not reset the original SLA clock |
| feedback_visibility_events | Feedback version ID, published/updated time, learner-visible state | Only human-submitted published feedback is visible to the learner; a successful edit updates the latest visible version and preserves history |

The grading queue is a query/view over accepted submissions and grader assignments, not an independent editable ordering. It sorts by server-recorded accepted timestamp ascending; the priority label is computed from time remaining and does not change chronological order.

### Submission and grading states

Use explicit state transitions such as draft → uploading → accepted/processing → queued → assigned → grading → feedback published → closed, plus failed/withdrawn states where justified. An OCR failure or quota limit must not destroy the accepted original PDF or block the grader from viewing it. A submission is accepted only after the original file is privately stored and its task/learner association is verified.

### Provider and cost decision boundary

**Phase 0 provider decision:** implement the logical model first on a single Supabase project using Auth, PostgreSQL and primary private Storage in Mumbai (`ap-south-1`); do not use D1 or a second database. Use Supabase Free first if tested availability, capacity, security and full backup/restore controls meet the agreed requirements; do not accept real learner records until those controls are demonstrated. Supabase Pro is an optional paid fallback only where no suitable free arrangement meets an essential requirement, with exact cost and separate approval. Cloudflare R2 is a secondary encrypted file-backup target only; its APAC location hint is best-effort and does not guarantee India residency. PDF.js is the in-app digital-text route; Azure Document Intelligence Read (`prebuilt-read`, intended Central India region) is the selected external handwriting OCR integration; Cloudflare Workers AI is the selected stateless on-demand teacher-draft service. All exact service terms, actual region availability, external processing, cross-border transfer, privacy notices/consent and cost gates must pass before real learner data or paid services are used. No providers are connected today.

### 2A. Commercial access and grading-credit invariants

The commercial access and tier definitions are governed by docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md. The full diagnostic/report and designated free resources remain free; a meaningful starter remedial activity is free; the full personalised remedial course requires a Study Lab or expressly granted course entitlement. Human grading credits are independent of course entitlements.

Use the approved default tier bands (Standard 1 credit, Premium 2, Elite 3, Custom 4+) and server-side time formula max(1, ceiling(predicted_grader_minutes / 20)). Task word ranges are indicative guidance only. The 10 MB/10-page PDF cap is not a pricing unit. No extra debit may be based only on actual word count, PDF page count or OCR use. The required tier/credits and policy version must be visible before acceptance and snapshotted at acceptance.

The one complimentary human-grade entitlement is one Standard task per learner account. The shared 24-hour elapsed-time SLA applies to every accepted human-graded task, including the complimentary task. Purchases, reservations, use, releases, refunds, expiry, course-entitlement changes and Admin grants are server-authoritative, versioned and auditable. Ordinary learner email verification is required before real learner-record access/paid entitlements; provider delivery is a later implementation decision.

These are logical future records/rules, not a claim that the physical credit, payment, entitlement or commercial Admin tables/routes are already implemented.

## 3. Important constraints

- Use stable IDs (UUIDs or equivalent) for internal records. Use human-readable codes for programmes, syllabus editions, skills and content IDs where useful.
- Add database constraints for required links, uniqueness and valid states; do not rely only on form validation.
- A published content item points to an exact reviewed version. Corrections create a new version and require review.
- An accepted submission stores the task version, rubric version, required credits, accepted timestamp and SLA snapshot. Later changes to a task or standard must not rewrite an existing obligation.
- Credit balance is calculated from ledger entries. Purchases, reservations, usage, releases, refunds and expiry are explicit events, not an editable balance field.
- Prevent duplicate free human-review entitlement server-side. Changing course/topic must not grant another free assessment.
- Only a trusted server operation may accept submissions, reserve/release credits, calculate due times, publish assessment versions or change privileged roles.
- Store timestamps consistently (normally UTC) and render them in the learner's appropriate timezone.
- Do not keep unnecessary sensitive details. Enforce the approved Phase 0 retention matrix: original PDF/raw extraction/corrected transcript during course activity plus 12 months after formal course completion, recorded withdrawal or administrative closure; published feedback/rubric results/version audit for 24 months after that formal end event; event-level timing for 12 months after attempt; verified deletion requests within 30 days subject to legal hold. Open/inactive courses require a restricted owner closure review; do not silently auto-delete or retain indefinitely without review.
- Delete temporary rendered page images immediately after OCR. Retrieve then delete Azure analysis results promptly using its Delete Analyze Result API. Expire encrypted off-site file backups within 30 days of source deletion.
- Apply role-scoped deletion, legal-hold exception records and external processor deletion; do not claim instant erasure from immutable backups.

## 4. Access-control outline

These are minimum rules to translate into server checks and database policies (such as row-level security when using a provider that supports it).

| Role | Minimum access |
|---|---|
| Visitor | Only explicitly public, published preview content and metadata |
| Student | Own profile, enrolments, attempts, saved responses, published assessments and credits |
| Guardian | Permitted learner records only through a valid, authorized guardian–learner link |
| Grader | Only assigned submissions and the task/rubric data needed to grade them; no private QA record |
| Admin | Operational records needed for assigned duties; all privileged access is attributable and auditable |
| Owner / super-admin | Full authorised operational access, including private QA and role management, with audit trails |

Additional protections:

- No public access to learner records, submissions, assessment drafts, answer keys before release or internal QA.
- Validate ownership/assignment for reads and writes at the server/database boundary.
- Use least privilege. Do not give every admin or grader full database-owner credentials.
- Do not expose privileged service keys to React/Vite client code.
- Keep private AI-QA data in a separate restricted table or schema, not merely a hidden field on a record graders can read.
- Content editing/publishing and role changes require authorized server-side actions and an audit record.
- Staff invitations are not role selectors: only an owner with an AAL2 session can manage them; invitees receive only the role recorded on the invitation after they prove control of the matching verified Auth email and complete MFA. Never trust invitation request fields as authority.

## 5. Build order

1. Approve the content fields, pathway mapping workflow and initial pilot pathway.
2. Create versioned content fixtures/types using the model; keep current demo content explicitly marked as fictional.
3. Complete `docs/PILOT_UNIT_REVIEW.md` with the academic lead, confirm the applicable MYP guide and whether candidate strands A(ii), A(iii), both or neither fit, then use the readiness gates to track verified mapping, reviewed lesson/practice content and approvals before release.
3. Implement the already Founder-approved Supabase Auth/Postgres/Storage mapping in Mumbai within the approved phased sequence, using the Free tier first where its tested limits meet requirements. Hosted resource provisioning remains separately gated; any paid plan/usage requires a documented unavoidable need, current quote and explicit Founder approval. Reconfirm current plan/terms and exact region before activation.
4. Create database migrations and enforce least-privilege access policies, PostgreSQL RLS and private storage access. Establish encrypted R2 secondary object backup only after region/transfer review; test database and file restore together.
5. Add authentication and profiles, then pathway enrolments and published content reads.
6. Add saved attempts and progress evidence; test that two learners cannot see each other's records.
7. Add submission/credit/capacity transactions, then versioned grader workflow and admin-only QA.
8. Before a real learner pilot, test role boundaries, backup/restore, deletion/retention operations and mobile use.

**Implementation boundary:** The physically implemented local synthetic subset in draft PR #22 includes Phase 1B identity/security and staff-invitation records; Phase 1C typed attempts/responses and private response history; accepted human-assessment submissions and immutable task/rubric/response versions; grader assignment/reassignment and workflow transitions; rubric/criterion outcomes and private assessment drafts/history; and private academic-QA records. The Worker uses caller-scoped Supabase access, while protected database RPCs/triggers enforce actor, role, AAL, ownership, state, audit and version rules. The current protected inventory is 25 tables (18 public, seven private). The audit-context enrichment adds actor-role snapshots, request UUIDs and PostgreSQL transaction IDs to new private audit events. This remains a local Supabase/synthetic-only implementation, not hosted provisioning, real learner data, production Auth or a fully accepted Phase 1 security foundation. PDF objects/storage, OCR, timer UI/analytics, credit-ledger activation and commercial entitlement/payment records remain future scope.


**Historical Phase 0 and cost-policy approval note — 3 November 2026 (implementation checkpoint superseded by Master Brief v4.45):** The logical records for PDF submissions, page extraction, feedback drafts/versions, grader SLA and timers remain a design proposal only. Supabase Mumbai Auth/Postgres/Storage, Azure Read OCR (intended Central India), Cloudflare Workers AI stateless drafts, Cloudflare R2 encrypted secondary object backup, 10 MB/10-page file caps, advisory no-pause timer policy and the retention/deletion matrix are Founder-approved. The Founder-approved free-first policy targets US$0 recurring infrastructure subscriptions and paid API usage for 3 November 2026–2 November 2027, with a non-automatic service review at 100+ subscribers. Free-tier shortcomings must be controlled and tested before real learner data; paid upgrades require proof of necessity and explicit cost approval. Hosted resource provisioning, paid plans/usage and real learner data remain separate gates. Local synthetic-only Phase 1B coding is separately approved and underway in draft PR #22; suspended-account RLS/Worker denial and sign-out behavior passed exact-head CI run #41500536318, with 16/16 browser tests. The exact tested Preview and remaining Founder visual-review gate are recorded in the Master Brief v4.37.


## Phase 1 security implementation cross-reference — 2 November 2026

The Phase 1 specification is the implementation-level companion to this provider-independent model. It requires database-backed role assignments, guardian-link verification, assignment-scoped grader access, immutable task/rubric/submission version references, UTC timestamps, transactional state changes, default-deny RLS and private Storage policies. It also specifies API actor derivation from verified identity, server-owned fields, audit records, deletion controls and synthetic cross-role tests. The local synthetic Phase 1B increment now includes private staff invitations, owner+AAL2 management, verified-email+AAL2 acceptance, token-hash-only storage and append-only audit events, with exact-head SQL/API/browser evidence recorded in the Master Brief v4.45. The data model does not authorise hosted resource provisioning, paid plans/usage or real learner data. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`; preserve this document's logical relationships and data definitions if physical table names or migrations are refined.


**Historical Phase 1A/1B implementation handoff — 3 November 2026 (superseded by the Phase 1C checkpoint above):** The original identity migration and Phase 1B staff-invitation migration remain implemented as described in the historical record. Phase 1C has since added typed attempts/responses, response-version archiving and assignment-scoped grader reads in the local synthetic stack. The broader accepted assessment submission, PDF object, human grading/feedback version, timer and credit workflows remain later incomplete slices; do not create speculative unused tables merely to accelerate PR #22.


## 6. Phase 1C physical implementation inventory and planned records — 3 November 2026

The following inventory distinguishes records that now exist in local synthetic Supabase from remaining logical design. The current implementation has 23 protected physical tables; PDF/file/OCR, private QA and later operational records remain future work.

| Physical table group | Status |
|---|---|
| `public.profiles`, `public.role_assignments`, `public.guardian_learner_links`, `public.course_enrolments` | Phase 1B implemented |
| `private.security_audit_events`, `private.staff_invitations` | Phase 1B implemented; restricted append-oriented audit and private invitation lifecycle |
| `public.task_versions`, `public.task_version_prompts`, `public.attempts`, `public.attempt_responses`, `public.grader_assignments` | Phase 1C initial typed-attempt/assignment slice |
| `private.attempt_response_versions` | Phase 1C initial slice; private append-only response archive |
| `public.rubrics`, `public.rubric_versions`, `public.rubric_criteria`, `public.task_rubric_mappings`, `public.assessment_submissions`, `public.submission_versions` | Phase 1C-B accepted human-assessment submissions and immutable task/rubric/response snapshots |
| `private.grading_capacity_config` | Phase 1C-B capacity configuration; no direct browser table access |
| `public.submission_grader_assignments`, `public.assessment_versions`, `public.criterion_results` | Phase 1C-C scoped grader assignments, immutable published feedback and criterion outcomes |
| `private.assessment_drafts` | Phase 1C-C private grader draft state; no direct browser table access |

The first Phase 1C exact-head checkpoint is commit `05544d1a394e2e480b7cd2dd9f55100b6998ee71`, run [#41613490244](https://github.com/gradioprep/gradioprep-website/actions/runs/41613490244): 116 PostgreSQL/pgTAP assertions and 24/24 Playwright tests passed, with local Supabase reset/seed, TypeScript/Vite/Worker builds, cleanup and a clean public-Preview build. The immutable public Preview is https://b4391d8e-gradioprep-website.wandering-scene-1822.workers.dev and is not connected to hosted Supabase.

**Planned but not yet physical:** any additional audit/event structures required after the 1C-E/F operation matrix, PDF/file/object metadata, extraction/OCR and transcript-correction records, timer session/event records, and remaining operational records identified by the exit matrix. The rubric, accepted-submission, grader-assignment, assessment-version, criterion-result, private-draft/history and private academic-QA records listed in the physical inventory are implemented and must not be described as logical-only.

Access remains default-deny. The student, guardian, grader, admin and owner boundaries are enforced by a combination of grants, RLS, protected RPCs and Worker checks; the remaining Phase 1C work must complete and test the full matrix for every table and operation. Admin does not inherit owner or private QA access. AAL2 is required independently at Worker and database boundaries for every privileged grader/owner/admin operation. The public Preview only demonstrates the safe disconnected shell; authenticated operations remain local synthetic-Supabase tests.


### 6.1 Verified Phase 1C-A security and access baseline — 3 November 2026

The original Phase 1C-A baseline (before migrations 1C-B and 1C-C) comprised 12 protected tables: nine public tables (`profiles`, `role_assignments`, `guardian_learner_links`, `course_enrolments`, `task_versions`, `task_version_prompts`, `attempts`, `attempt_responses`, `grader_assignments`) and three private tables (`security_audit_events`, `staff_invitations`, `attempt_response_versions`). RLS is enabled on all 12. Private audit, invitation and response-history tables have no direct browser table grants; audit rows are appended only through protected database functions/triggers, and response history is append-only.

Two hardening migrations are present:
- `20261103000600_phase1c_role_scope_hardening.sql`: task metadata reads are limited to eligible enrolled students, verified consent-authorised guardians with a linked attempt, active assigned graders at AAL2, or owners at AAL2. Owner-wide identity-table reads also require AAL2 at the database boundary.
- `20261103000700_phase1c_private_audit_and_revoked_assignment_rls.sql`: enables RLS on private security audit with no client policy and prevents graders from reading revoked assignment rows. Owner AAL2 inspection remains permitted.

Actual role-based regression tests are in `supabase/tests/protected_table_permissions.test.sql` and `supabase/tests/role_scoped_access.test.sql`, alongside existing identity/attempt/revocation/invitation suites. They verify table inventory/RLS, anonymous/private/direct-write denials, student row ownership, guardian scopes/consent/revocation, active and revoked grader assignment scope, admin non-inheritance, owner AAL1/AAL2 boundary, suspended-account denial and manipulated ownership/state/timestamps.

Exact-head verification on `ee275ca714c9bfb6bb44f580c2b1e827106975d4`: run [#41646515558](https://github.com/gradioprep/gradioprep-website/actions/runs/41646515558), **215/215 PostgreSQL assertions across six SQL files and 24/24 Playwright tests passed**; local synthetic Supabase reset/seed, TypeScript/Worker/Vite builds, shutdown/credential cleanup and clean Preview asset build passed. Immutable branch Preview https://f26a4358-gradioprep-website.wandering-scene-1822.workers.dev contains no hosted Supabase backend. Authenticated behaviour was verified only against local synthetic data. The Founder visual review for this new revision remains separate.

This is the verified 1C-A baseline for the original 12 tables; it is not the current total or the completed Phase 1C exit matrix. The 1C-B/C additions and their latest verification are recorded in Section 6.2. Delegated admin/private-QA records, broader audit coverage and remaining 1C-D/E/F adversarial acceptance are still open. Each new protected table and Worker operation requires default-deny grants, RLS/role expectations, AAL rules and actual allow/deny tests.


### 6.2 Verified Phase 1C-B accepted submissions and Phase 1C-C human assessment/feedback — 3 November 2026

The physical inventory now totals **23 protected tables: 18 public and five private**. The 11 additions after the 12-table Phase 1C-A baseline are:

- Public: `rubrics`, `rubric_versions`, `rubric_criteria`, `task_rubric_mappings`, `assessment_submissions`, `submission_versions`, `submission_grader_assignments`, `assessment_versions`, `criterion_results`.
- Private: `grading_capacity_config`, `assessment_drafts`.

Migration `20261103000800_phase1c_accepted_human_submissions.sql` implements the published task/rubric mapping and accepted submission lifecycle. `accept_assessment_submission` derives learner identity from `auth.uid()`, validates active student/account/enrolment and published task/rubric, serialises capacity checks, snapshots capacity/load, uses a caller-supplied idempotency key safely, stores the original response as immutable submission version 1 and sets server-owned `accepted_at` plus the exact 24-hour `grading_due_at`. Its pgTAP suite verifies capacity and idempotency boundaries, immutable snapshots and cross-role visibility.

Migration `20261103000900_phase1c_human_assessment_feedback.sql` implements scoped submission assignment, private criterion-level draft grading, draft retrieval/save and explicit human publication. `publish_assessment_feedback` creates immutable `assessment_versions` and `criterion_results`; learners read only the latest published version. Private drafts are not directly readable from client table access. The pgTAP suite verifies assigned/unassigned/revoked grader, AAL1/AAL2, learner/guardian/admin/owner separation, draft protection, publication and immutable versions.

The corrected revoked-grader test preserves the actual submission ID before revocation, asserts the submission exists and has an active assignment for the grader, then supplies that same ID to both denial RPC checks. Both pass with `42501 / grader_assessment_forbidden`.

Exact-head CI: [run #41668857175](https://github.com/gradioprep/gradioprep-website/actions/runs/41668857175) on `d2e825746aa814de1f100ef2d8daa2e841d91c80` passed **361 PostgreSQL/pgTAP assertions across eight SQL files and 27/27 Playwright tests**, fresh local synthetic Supabase reset/seed, TypeScript/Worker/Vite builds and cleanup. No Preview was requested for this backend-only change, and no hosted Supabase, paid service or real learner record was used.

Phase 1C-D operational role separation and private academic-QA records are implemented and verified at their recorded checkpoints. The former caller-invokable generic audit-writer weakness was addressed by revoking browser execution and restricting `record_worker_audit_outcome` to the trusted Worker service role. The current Phase 1C-E gap is complete per-distinct-action persisted event/request-ID correlation, not the prior browser-invokable writer design. Phase 1C-F adversarial acceptance remains open; Phase 1D remains blocked until the complete Phase 1C exit gate passes. PDF storage/OCR, timers and real-data readiness remain later/incomplete scope.


### 6.3 Historical Phase 1C-D operational role separation checkpoint — superseded by Section 6.8

**Verified checkpoint — 4 November 2026:** Code head `c1647c7c7048b1d791c3d24f59ed51168f219d51` in PR #22; exact-head GitHub Actions run [#41828382786](https://github.com/gradioprep/gradioprep-website/actions/runs/41828382786) passed the local synthetic Supabase reset/seed, PostgreSQL/RLS checks, TypeScript/Worker/Vite builds, 27/27 Playwright tests and clean public-preview asset build. This is the historical 1C-D checkpoint, not the current branch state.

Phase 1C-D operational role separation remains verified. Phase 1C-E correlation coverage and Phase 1C-F adversarial acceptance have since progressed; the current checkpoint and outstanding work are recorded in Section 6.8 and the Master Brief Section 27. Phase 1D remains blocked until every Phase 1C exit criterion passes.

The commercial Admin dashboard, course entitlement and credit-ledger records above are logical design only. They must be implemented after the secure foundation and in the sequence in `docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md`; do not mistake Phase 1C's delegated backend role controls for a learner-facing Admin console.


### 6.4 Historical Phase 1C-E audit-context enrichment checkpoint — superseded by Section 6.7

Migration `20261105000100_phase1c_audit_context_enrichment.sql` adds three metadata columns to the existing `private.security_audit_events` table without changing the 25-table inventory or direct client permissions:

- `actor_roles`: application roles derived at event-write time from active database role assignments and active account status; never copied from caller-supplied role metadata.
- `request_id`: the UUID generated by the trusted Worker and forwarded in the Supabase request header; PostgreSQL validates it and generates a replacement UUID when missing or invalid.
- `transaction_id`: the PostgreSQL transaction identifier, allowing related audit writes in one transaction to be grouped.

A private database trigger applies the enrichment to new audit inserts. These fields are correlation/evidence metadata only and are never authorization inputs. They do not expose audit rows to authenticated clients, weaken append-only protection or store learner response, feedback, private-QA or credential content. The Worker continues to use the caller-scoped Supabase client.

Exact-head run [#41971855781](https://github.com/gradioprep/gradioprep-website/actions/runs/41971855781) passed the new `supabase/tests/audit_context.test.sql` checks together with the complete local synthetic PostgreSQL/RLS suite, builds, 27/27 Playwright tests and cleanup. The complete 1C-E operation audit matrix and the 1C-F adversarial acceptance matrix remain open; Phase 1D remains blocked.


### 6.5 Historical Phase 1C-E protected-read and write-outcome checkpoint — superseded by Section 6.6

**Verified exact-head implementation — 5 November 2026:** Code head `8ef011c7927a8f7c5d20da372fb3aca789d74663` on PR #22, branch `feature/phase-1b-local-auth-api`. Exact-head GitHub Actions run [#41981770337](https://github.com/gradioprep/gradioprep-website/actions/runs/41981770337) passed fresh local Supabase startup, reset and synthetic seed; all PostgreSQL/RLS/pgTAP tests; TypeScript, Worker and Vite builds; Playwright **27/27**; local Supabase shutdown; local-only credential-file cleanup; and clean public-preview asset build without local credentials. The exact-head Cloudflare Workers Builds check [#127093826637](https://github.com/gradioprep/gradioprep-website/runs/127093826637) also passed. Founder-facing Preview deployment/comment steps were skipped because this is a backend/security increment and adds no substantial new learner/staff-visible feature.

**Completed 1C-E audit coverage in this verified slice:**
- Protected reads now record allowlisted success only after retrieval, record authorised query failures separately, and record database-derived denials for missing role, ownership/assignment scope or AAL2. The Worker preserves the established 403 role/MFA responses and non-enumerating 404 responses.
- Privileged Owner and assigned-Grader operations record denials and post-RPC failures in addition to the existing transactionally written success events. The allowlist covers Owner role revocation, attempt/submission assignment and reassignment, submission transition, private-QA creation, and assigned-Grader draft save and feedback publication.
- Learner mutations cover attempt creation, typed-response save, attempt submission and human-assessment submission acceptance. Database checks bind attempt operations to the owning active student, and bind task operations to an active enrolment plus a published typed task; assessment acceptance also requires a published mapped rubric and prompt.
- Failure reasons are drawn from a safe fixed vocabulary. A caller cannot create a success event or pass response text, feedback, QA content, bearer tokens, token hashes, idempotency keys, credentials or raw database error strings into the audit record. Existing private, append-only audit-table permissions remain unchanged.

Migrations `20261105000300` through `20261105000600` implement protected-read outcomes, privileged-write outcomes, learner-write outcomes and preservation of the precise `assignment_required` denial category. The test additions are `audit_context.test.sql`, `privileged_write_audit.test.sql` and `learner_write_audit.test.sql`. No tables were added; the protected-table inventory remains **25 (18 public, seven private)**.

**Historical next step at this checkpoint:** the staff-invitation and private-QA outcome paths were still pending. They were subsequently implemented in migrations `20261105000700` and `20261105000800`; the current remaining work is recorded in Section 6.6. This historical increment did not complete Phase 1C-E.

**Phase 1C-F remains open:** complete the consolidated adversarial acceptance matrix across anonymous, Student, linked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner at relevant AAL1/AAL2 states. Retain coverage for suspension, revocation, cross-learner isolation, forged actor/role/ownership/assignment/state/timestamps, replay, concurrency and direct table/RPC bypass. Phase 1D remains blocked until all Phase 1C exit criteria pass exact-head synthetic CI.

PR #22 remains **open, draft and unmerged**. Work used local Supabase and synthetic records only. No hosted resource, paid service, real learner data, external processor, production deployment, domain/DNS change or merge was used or authorised.

The audit additions do not add or widen logical domain tables or direct client grants. Existing learner answer and assessment feedback content remains in its protected domain records; the security audit stream contains only actor, allowlisted action, resource identifier, outcome, safe reason category and server-enriched correlation metadata.

### 6.6 Historical Phase 1C-E staff-invitation/private-QA outcome checkpoint — superseded by Section 6.7

**Verified code head:** `f5097ba8bae0eee4c420e8e5081f90287f3149ee` on PR #22, branch `feature/phase-1b-local-auth-api`. Exact-head run [#41984620018](https://github.com/gradioprep/gradioprep-website/actions/runs/41984620018) passed 534 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds, 27/27 Playwright tests, local Supabase shutdown, credential cleanup and clean public-preview asset build. Documentation reconciliation head `1f1195de965d40631879dc140dcca4b8a447cf54` passed the same workflow in [#41985668001](https://github.com/gradioprep/gradioprep-website/actions/runs/41985668001). No public/Founder Preview was deployed: both workflows were branch-push events, while the upload step requires a qualifying pull-request event plus the Founder-preview marker.

**Implemented since Section 6.5:** migration `20261105000700_phase1c_staff_invitation_and_private_qa_audit.sql` extends the protected-read allowlist for staff-invitation collection and Owner private-QA reads, adds staff-invitation create/revoke failure action handling, updates Worker outcomes and makes the privileged-write audit helper acknowledge only an inserted event. Migration `20261105000800_phase1c_audit_invitation_failure_integrity.sql` replaces the caller-category-based acceptance-failure helper with a token-hash-bound, database-derived helper. It records only verified invitation denials/state conflicts, never stores invitation token/email data, and declines to create a failure event when the invitation is otherwise eligible for acceptance. The regression tests cover the new behaviour and private audit-table permission boundary. No new tables were added; the inventory remains **25 (18 public, seven private)**.

**Still open — do not sign off Phase 1C-E:** the generic `audit_privileged_write_outcome` and `audit_protected_read_outcome` RPCs still accept authorised callers' allowlisted `failed` inputs directly. A caller can therefore create a misleading failure event without running the associated business operation. Bind failure evidence to operation execution or another trusted, browser-inaccessible attestation; test both forged direct-RPC attempts and genuine operation failures. Add explicit Worker route/integration tests for staff-invitation list/create/revoke/accept and Owner private-QA read failure/denial paths, including HTTP response preservation, non-enumerating behaviour and fail-closed handling.

**Next order:** finish the generic audit-integrity correction and Worker route coverage; reconcile the full endpoint-to-audit/authorization matrix; then complete Phase 1C-F adversarial acceptance across anonymous, Student, linked Guardian, assigned/unassigned/revoked Grader, operational Admin and Owner at relevant AAL1/AAL2 states, including suspension, revocation, cross-learner isolation, forged fields, replay, concurrency and direct table/RPC bypass. Phase 1C-E remains partial, Phase 1C-F remains open and Phase 1D remains blocked. All work remains local-Supabase/synthetic-only; hosted provisioning, spend, real learner data, merge, production deployment and DNS changes require separate approval.


### 6.7 Historical Worker-only audit-outcome boundary — superseded by Section 6.8

**Verified implementation update — 5 November 2026:** PR #22 remains open, draft and unmerged. Code head `3c4b4a71718b795855a9dd41346c80d1a1f85c39`; exact-head GitHub Actions run [#41992302366](https://github.com/gradioprep/gradioprep-website/actions/runs/41992302366) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **27/27 Playwright tests**, local Supabase shutdown, local credential cleanup and clean public-preview asset build. The subsequent docs-only reconciliation head `9aba3a52f192d8a9987c51a01c5eed8e21f71764` passed exact-head run [#41993692326](https://github.com/gradioprep/gradioprep-website/actions/runs/41993692326); this verifies documentation reconciliation, not a new functional-code change. The workflow was a branch push, so no public/Founder Preview was uploaded. Migration `20261105000900_phase1c_worker_only_audit_ingestion.sql` introduces `record_worker_audit_outcome`, callable only by `service_role`; the old browser-callable generic audit outcome RPCs are revoked. The Worker uses its server-only service-role client solely for audit ingestion, with verified actor identity and allowlisted actions, outcomes and safe reason categories; business reads/writes remain on the caller-scoped client. Audit writes fail closed if the Worker audit key is absent or the database does not acknowledge the event. The local service-role key is kept in ignored `.dev.vars` and is not copied to browser `.env.local`/Vite variables. Browser direct-RPC forgery tests, trusted-writer tests and the existing Playwright invitation/private-QA/account API journey pass. Phase 1C-E remains partial pending the complete endpoint-to-audit/authorization matrix and targeted failure-injection/correlation acceptance; Phase 1C-F remains open and Phase 1D remains blocked. No hosted resources, real learner data, paid usage, merge, deployment or DNS changes occurred.

Migration `20261105000900_phase1c_worker_only_audit_ingestion.sql` adds `public.record_worker_audit_outcome`. It is SECURITY DEFINER, uses a fixed action/resource/outcome/reason allowlist and grants EXECUTE only to `service_role`. EXECUTE is revoked from browser roles for this RPC and the legacy generic audit-writer functions. The trusted Worker uses a separate service-role Supabase client only for audit insertion; all application reads and writes stay on the verified caller-scoped client. Successful write audit records continue to be inserted transactionally by the business operation. The new RPC accepts successful protected reads, allowlisted denials and allowlisted failures, and rejects write-success fabrication and unsafe error text. No new logical or physical domain tables are required.

The service-role key is stored only in the ignored local Worker `.dev.vars`; it is not copied to browser `.env.local`/Vite variables. The Worker fails closed if the audit service is not configured or does not acknowledge its insert. SQL tests verify privilege boundaries and audit metadata; Playwright covers the invitation/private-QA/account API route journey. The full endpoint-to-audit row-correlation matrix and audit-service failure-injection coverage remain open. Protected inventory remains 25 tables (18 public, seven private). Phase 1C-E remains partial; Phase 1C-F remains open; Phase 1D remains blocked.


### 6.8 Historical Phase 1C-E route audit-correlation and Phase 1C-F acceptance checkpoint — superseded by Section 6.9

**Verified code/test checkpoint:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. The verified code/test head is `5dba933dce39b05c69a6616e5bb730d404e3b5a2`; exact-head GitHub Actions run [#42041037808](https://github.com/gradioprep/gradioprep-website/actions/runs/42041037808) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds and **29/29 Playwright tests**. Local Supabase shutdown, local credential cleanup and the credential-free public-preview asset build also passed. This was a branch push; Preview upload/comment steps were skipped. **No Preview or production deployment occurred for this code/test checkpoint.**

**Documentation-only checkpoint:** The subsequent 14-commit reconciliation changed documentation only, including this data model, README, Master Brief, endpoint authorization/audit matrix and the new Phase 1C-F adversarial acceptance matrix. It did not change application, migration, test or deployment files. Documentation head `570f98b12cd73132ccaaa81bd5dd7a4cd6f30e5c` passed exact-head GitHub Actions run [#42048319137](https://github.com/gradioprep/gradioprep-website/actions/runs/42048319137): 494 pgTAP assertions/14 SQL files, all TypeScript/Worker/Vite builds and 29/29 Playwright tests. Preview upload/comment steps were skipped; no Preview or production deployment occurred.

The endpoint authorization/audit matrix contains **29 HTTP method/path rows**. Its **25 Worker-audited routes** have missing-audit-service/key/acknowledgement fail-closed coverage (HTTP 503 and generated `X-Request-ID`). Phase 1C-E has **representative per-distinct-action persisted event/request-ID correlation coverage**, not exhaustive outcome coverage for every route or every possible outcome. Assertions check persisted actor, actor-role snapshot, action, target, outcome, safe reason, exact Worker response request ID and transaction ID for representative paths. Successful Worker action/event mappings are `student_attempt_create` → `attempt_created` and `grader_assessment_draft_save` → `assessment_draft_saved`; denied/failed outcomes retain Worker action names.

The former browser-callable generic audit outcome writers are revoked; only the trusted Worker service role can call `record_worker_audit_outcome`. Application data access remains caller-scoped; the separate service-role client is used only for audit ingestion. The current 25-table protected inventory is unchanged (18 public, seven private).

Existing synchronized tests for competing Owner attempt assignments and feedback publication, plus duplicate-submission idempotency/replay, are already passing and must not be duplicated. The consolidated [Phase 1C-F adversarial acceptance matrix](PHASE_1C_ADVERSARIAL_ACCEPTANCE_MATRIX.md) maps the existing actor/assurance, RLS, forged-field, replay, direct-bypass and concurrency evidence.

**Only two synchronized synthetic Phase 1C-F tests remain open:**
1. Simultaneous acceptance of the same single-use staff-invitation token, using independent synthetic authenticated requests and deterministic test-only synchronization; assert exactly one acceptance, role grant and persisted acceptance event, with safe rejection of the competing request.
2. Revocation of the privileged actor's role or suspension of that actor's account racing an in-flight privileged request; test both revocation and suspension orderings at the authorization/transaction boundary and assert that stale preflight authorization cannot permit a side effect after the access change takes effect.

Use deterministic barriers/observable database lock states, not timing sleeps; do not add a production bypass. Phase 1C-F remains open until both tests pass exact-head local synthetic CI. **Phase 1D remains blocked until every Phase 1C exit criterion is documented and passes.** All activity remains local-Supabase/synthetic-only. No hosted provisioning, paid usage, real learner data, external processing, email delivery, merge, Preview deployment, production deployment or DNS/custom-domain change is authorised. Do not request a Founder Preview for docs, tests or backend/security work.


### 6.9 Verified Phase 1C-F synchronized race acceptance — 5 November 2026

**Exact verified code/test head:** `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` on PR #22, branch `feature/phase-1b-local-auth-api`. Exact-head local synthetic GitHub Actions run [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) completed successfully. The workflow passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **31/31 Playwright tests**, local Supabase shutdown, local-only environment-file cleanup and the credential-free public-preview asset build. The Cloudflare Workers Builds check also passed. Public Preview creation/update and PR Preview-link steps were skipped. **No public Preview or production deployment occurred.**

Both previously outstanding synchronized Phase 1C-F cases are implemented and passing:

1. **Same-token invitation acceptance:** two independent synthetic AAL2 sessions hit the deterministic barrier immediately before the acceptance RPC and submitted the same single-use invitation token. The result was one HTTP 200 acceptance and one safe HTTP 410 `invitation_already_used`; exactly one active Grader role; one successful and one failed/conflict `staff_invitation_accepted` audit event; distinct request IDs correlated to actor/action/invitation target/outcome; and no token/hash disclosure.
2. **Revocation/suspension racing privileged assignment:** separate synthetic submitted attempts and synchronized pre-RPC barriers were used for role revocation and account suspension. In each subcase the access change committed before the paused request resumed; the privileged assignment returned HTTP 403, a correlated `owner_attempt_assignment` denial event was recorded, and no grader assignment was created. Follow-up authorization checks remained denied.

The barrier is disposable local test plumbing: a synthetic test creates an RLS-protected table in local Supabase, and an atomic service-role-only arrival RPC coordinates the Worker requests. Worker control is additionally guarded by the local host and ignored local secret. No production migration, hosted table or production authorization bypass was added. CI reset/stopped local Supabase and removed local-only environment files.

Existing Owner assignment concurrency, feedback-publication concurrency and duplicate-submission idempotency tests were retained without duplication. Phase 1C-E remains **representative per-distinct-action persisted request-ID/event correlation coverage**, not exhaustive outcome coverage. The required successful event mappings remain Worker `student_attempt_create` → `attempt_created` and Worker `grader_assessment_draft_save` → `assessment_draft_saved`.

**Sequencing:** the two previously outstanding synchronized Phase 1C-F cases now have exact-head passing evidence. Phase 1D was not implemented or started in this change. Keep it unstarted until the final source-of-truth documentation reconciliation has itself passed exact-head CI and the Phase 1C exit record is fully reconciled. PR #22 remains open, draft and unmerged. No hosted provisioning, paid use, real learner data, external processing/email, public Preview, production deployment, DNS change or merge occurred or is authorised.
