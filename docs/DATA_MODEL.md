> **Authoritative current checkpoint — 11 November 2026:** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. The PA Listening rollback application/test commit `bc6efdaee987110acd55cdc1ed655a4676e01ec2` passed exact-head GitHub Actions [#42956397671](https://github.com/gradioprep/gradioprep-website/actions/runs/42956397671). The latest branch HEAD `57faa3c0728e2f89667bbe88745aca22fb3373be` adds documentation-only commits after that tested code snapshot. Current PA capture remains 15 unscored RV/LC observations; no Listening is active in PA, SA1 or SA2. Read-only milestone/report reuse findings and next build order are recorded in §6.23. Protected physical inventory remains 34 tables (22 public, 12 private); no curriculum-unit membership, milestone progression or composite segment Evaluation Report relation is yet implemented.

**Status:** Phase 1C, Phase 1D, Phase 1E and Phase 1F technical synthetic evidence remain verified for their accepted scope. Phase 2 submission, transcript review, timer/accommodation, immutable attempt linkage, published-assessment analytics and the first unscored Diagnostic evidence-capture slice have exact-head synthetic CI evidence. Diagnostic response content remains outside score/report processing; no final scoring or Evaluation Report is produced by the current delivery. Hosted backup, deletion/retention operational activation, monitoring, external processing, commercial ledger/entitlements and production-readiness gates remain separate.

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

The Phase 1D file metadata record `private.submission_files` is physically implemented and verified locally. The remaining extraction, transcript, feedback-suggestion and timing records below are logical proposals only; they are not live tables or migrations.

| Record | Purpose and key fields | Relationships / rules |
|---|---|---|
| `private.submission_files` | Submission ID, private storage object key, original file name for display, verified MIME/signature, byte size, page count, checksum, upload/accept timestamps, lifecycle state | **Physically implemented** by migration `20261106000100_phase1d_private_submission_files.sql`; local non-public `private-submissions` bucket; PDF only, 10 MiB/10-page limits; opaque non-overwriting object keys; immutable accepted metadata; Worker-mediated assignment-scoped signed access. Exact-head acceptance: #42189786947. |
| submission_page_extractions | Submission/file ID, page number, extraction method (PDF text layer/OCR), raw text, confidence/status, coordinates, processing timestamp, error metadata | One record per page/method/version; raw extraction is immutable; teacher-corrected transcript is separately versioned |
| transcript_corrections | Submission/page ID, corrected text, editor, timestamp, change reason, source extraction version | Never overwrite original PDF or raw OCR; teacher correction is an auditable grading aid |
| feedback_suggestion_sets | Submission ID, task/rubric version, model/prompt version, generation time, quota/cache status, ten proposed suggestions | Private teacher-only draft; not student-visible and never auto-published |
| feedback_suggestion_items | Suggestion-set ID, item index, suggested text, optional criterion/skill tag | Exactly ten suggestions per successful generation set; selection/editing by the teacher is recorded in the published feedback version |
| `private.attempt_timer_sessions` | Attempt ID, learner, task-version ID, snapshotted allowance/policy version, server start time | Physically implemented; private, RLS-enabled, no direct client grants and immutable. NULL allowance represents an untimed task. |
| `private.attempt_timer_events` | Attempt ID, event type, actor, server timestamp; for adjustments, delta/effective allowance, accommodation mode, fixed reason category and authoriser | Physically implemented; append-only and metadata-only. Never store response text, diagnoses, keystrokes, focus or browsing signals. Adjustment records are authorised and audited. |
| submission_sla_events | Submission ID, accepted time, due time, first feedback publication time, actual turnaround, remaining/overdue duration, SLA state | 24-hour target snapshot is fixed at acceptance; later edits do not reset the original SLA clock |
| feedback_visibility_events | Feedback version ID, published/updated time, learner-visible state | Only human-submitted published feedback is visible to the learner; a successful edit updates the latest visible version and preserves history |

The grading queue is a query/view over accepted submissions and grader assignments, not an independent editable ordering. It sorts by server-recorded accepted timestamp ascending; the priority label is computed from time remaining and does not change chronological order.

### Submission and grading states

Use explicit state transitions such as draft → uploading → accepted/processing → queued → assigned → grading → feedback published → closed, plus failed/withdrawn states where justified. An OCR failure or quota limit must not destroy the accepted original PDF or block the grader from viewing it. A submission is accepted only after the original file is privately stored and its task/learner association is verified.

### Provider and cost decision boundary

**Phase 0 provider decision:** implement the logical model first on a single Supabase project using Auth, PostgreSQL and primary private Storage in Mumbai (`ap-south-1`); do not use D1 or a second database. Use Supabase Free first if tested availability, capacity, security and full backup/restore controls meet the agreed requirements; do not accept real learner records until those controls are demonstrated. Supabase Pro is an optional paid fallback only where no suitable free arrangement meets an essential requirement, with exact cost and separate approval. Cloudflare R2 is a secondary encrypted file-backup target only; its APAC location hint is best-effort and does not guarantee India residency. PDF.js is the in-app digital-text route; Azure Document Intelligence Read (`prebuilt-read`, intended Central India region) is the selected external handwriting OCR integration; Cloudflare Workers AI is the selected stateless on-demand teacher-draft service. All exact service terms, actual region availability, external processing, cross-border transfer, privacy notices/consent and cost gates must pass before real learner data or paid services are used. No providers are connected today.

### 2A. Commercial access and grading-credit invariants

The commercial access, catalogue and tariff are governed by `docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md`. The complete Diagnostic and Evaluation Report remain permanently free (₹999 is stated reference value only), and at least one meaningful starter remedial activity remains free. The full Remedial Course is a separate ₹1,999 course entitlement; the superseded ₹199/month Study Lab proposal is not a current product. Human-grading credits are independent of course entitlements.

Apply the same server-side tariff to IB, Cambridge and CBSE:
- Accepted words 1–50 = 1 credit; 51–150 = 2; 151–350 = 3.
- Above 350 words, add one credit for each complete or partial additional 100-word band. For positive counts above 350, word credits = 3 + ceiling((accepted_word_count − 350) / 100); zero-word graded submissions are not accepted.
- Time credits = max(1, ceiling(predicted_grader_minutes / 20)).
- Final required credits = max(word_credits, time_credits), never their sum.

The approved regular catalogue is 2 credits for ₹1,500; 5 for ₹3,750; Gold 10 for ₹7,500; and Platinum 20 for ₹14,999. The only Diwali offers are the permanently free Diagnostic/report and the Platinum 20-credit plus full Remedial Course bundle for ₹7,999. Prices and entitlements are policy-controlled and must be snapshotted at purchase/acceptance. Store INR amounts in integer paise.

The one complimentary human-grading entitlement is one task per learner account and may be used only when the server-calculated total requirement is exactly one credit. The shared 24-hour elapsed-time SLA applies to every accepted human-graded task, including this complimentary task. The 10 MB/10-page PDF cap is a file-safety limit, not a pricing unit; no extra debit may be based only on PDF page count, OCR use or words beyond the ideal target. No retrospective debit is permitted.

Purchases, reservations, consumption, releases, refunds, expiry, course-entitlement changes and Admin grants are server-authoritative, versioned and auditable. Ordinary learner email verification is required before real learner-record access/paid entitlements; provider delivery is a later implementation decision.

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

**Implementation boundary:** The physically implemented local synthetic subset in draft PR #22 includes Phase 1B identity/security and staff-invitation records; Phase 1C typed attempts/responses and private response history; accepted human-assessment submissions and immutable task/rubric/response versions; grader assignment/reassignment and workflow transitions; rubric/criterion outcomes and private assessment drafts/history; private academic-QA records; and Phase 1D private PDF file metadata/object lifecycle. The Worker uses caller-scoped access for ordinary business data. Its isolated service-role client is limited to audit ingestion and the narrow Phase 1D file/Storage RPC lifecycle. The current protected inventory is **28 tables (18 public, 10 private)**. This remains a local Supabase/synthetic-only implementation, not hosted provisioning, real learner data, production Auth or a fully accepted Phase 1 security foundation. OCR and the learner-facing PDF selection journey remain outside this data-model increment. The advisory timer and staff extension/untimed-accommodation API are implemented and passed exact-code-head CI #42591455986 on application-code/test commit `eae6ab23cdf7d5eaf48019d9b747d0bda9b85bf1`; timed-attempt linkage and validated rubric/elapsed-response analytics remain future scope. Credit-ledger activation and commercial entitlement/payment records also remain future scope.


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

## Founder-approved logical extensions — 6 November 2026 (design only)

Preserve the existing Supabase/PostgreSQL model and Worker authorization boundary. These are logical requirements, not deployed tables or migrations.

- Versioned product catalogue: product ID/version, type, INR price in integer paise, credit quantity, included course entitlement, effective dates and approval reference. Snapshot price/benefits on purchase.
- Campaign configuration: campaign ID/version, eligible bundle, exact start/end timestamps, India-time display metadata, price, entitlements and status. Validate server-side.
- Purchase fulfilment: trusted payment/manual reconciliation reference, idempotency key, status, catalogue/campaign version, amount/currency and separate credit/course grant references. Platinum Diwali purchase must idempotently grant 20 credits and course entitlement.
- Credit calculation snapshot: accepted word count, tokenizer/version, predicted grader minutes, word credits, time credits, final maximum, tariff version and learner confirmation. Universal schedule: 1–50=1; 51–150=2; 151–350=3; above 350 add one per additional 100 words or part thereof. Time is one credit per 20 predicted minutes. Never sum estimates or debit retrospectively.
- Queue support: stable metadata/joins for board/programme, grade, subject, pathway/unit/task, accepted timestamp, status, response format, PDF extraction status and assignment scope. Add indexes based on query plans/load tests. Search permitted learner name/reference and submission ID; do not expose email or private response text by default. Enforce role/assignment scope before filters/counts/pagination.
- Course entitlements remain separate from the append-only grading credit ledger. Platinum bundle grants both; standalone course grants course access only.

No physical schema, RLS, RPC or migration is authorised by this documentation-only amendment.


### 6.10 Approved commercial catalogue and distinct entitlement model — 6 November 2026 (logical design only)

The current catalogue is owned by `docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md`:

| Product | Approved price | Benefit |
|---|---:|---|
| Diagnostic + complete Evaluation Report | Free (₹999 stated reference value) | Complete report; permanently free |
| Standalone Remedial Course | ₹1,999 | Full course entitlement |
| 2-credit pack | ₹1,500 | 2 human-grading credits |
| 5-credit pack | ₹3,750 | 5 human-grading credits |
| Gold Plan | ₹7,500 | 10 human-grading credits |
| Platinum Plan | ₹14,999 | 20 human-grading credits |

The only Diwali offers are free Diagnostic + complete report, and Platinum (20 grading credits plus separate full Remedial Course entitlement) for ₹7,999. The bundle's listed component reference value is ₹16,998. No other offer, discount or bonus credit is approved. Exact campaign timestamps and India-time display are required before activation.

Credit tariff must be applied consistently across boards: fixed word bands of 1–50=1, 51–150=2 and 151–350=3; above 350, add one credit per complete or partial 100 words. Time credits are max(1, ceiling(predicted grader minutes/20)); final required credits are max(word credits,time credits), never their sum. Price and benefit snapshots are server-authoritative and stored in integer paise. Course entitlements are separate from the append-only human-grading credit ledger; Platinum Diwali fulfillment grants both, while standalone course purchase grants course access only.

These are logical requirements, not physical tables, migrations, RLS policies, RPCs or deployed payment features.

### 6.11 Phase 1C closeout and next physical-model dependency — 6 November 2026

The Phase 1C database and protected-API model has passed its local synthetic acceptance. The implemented protected inventory is **25 tables (18 public and seven private)**, with RLS/permission and cross-role evidence in exact-head CI [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858). That code/test head passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests, including the synchronized invitation-acceptance and Owner-revocation/account-suspension races.

The final closeout does not add tables or migrations. Phase 1C-E audit correlation is representative per distinct action, not exhaustive outcome coverage. Phase 1D private PDF/file controls remain unimplemented and are the next physical-storage dependency; do not treat the logical commercial catalogue, credit ledger or course-entitlement records above as deployed functionality.


## Phase 1E current schema status — 7 November 2026

The current branch contains the request/hold and retention schema migrations: `private.account_deletion_requests`, `private.account_deletion_legal_holds`, `private.retention_items` and `private.retention_backup_objects`. The retention/backup table is a metadata inventory; it does not itself prove that backup objects exist or that physical erasure has occurred. R2-related rows remain unused pending separate regional, transfer, encryption and key-custody approval. The paired SQL tests declare 35 and 47 pgTAP assertions and both passed in run [#42473595308](https://github.com/gradioprep/gradioprep-website/actions/runs/42473595308), as part of 601 assertions across 17 SQL files. Test-only commit `26fbea0` uses one captured acceptance timestamp to derive the due time. Append-only migration `edc3340` allows the Owner/AAL2 legal-hold RPC to accept an executing closure request and transition it to on-hold, while retaining its validation, locking and audit controls. The `phase1e-local-backup.mjs` verifier passed: one database snapshot restored, one private PDF object restored with checksum, and a corrupt archive rejected. Cleanup passed. This is synthetic hosted-CI evidence only; it does not prove hosted R2 backup or real-data erasure. Phase 0 retention durations and legal-hold rules remain unchanged.


## 6.12 Phase 2 optional PDF response eligibility — verified synthetic schema increment — 8 November 2026

Append-only migration `20261108000400_phase2_optional_pdf_response_eligibility.sql` makes the optional PDF alternative explicit at task and submission levels without adding a table:

| Physical field / control | Purpose and invariant |
|---|---|
| `public.task_versions.pdf_response_enabled` | Boolean task-level opt-in; defaults to false, so tasks remain typed-only unless explicitly enabled. |
| `task_versions_pdf_response_threshold_check` | Database constraint permits opt-in only when `ideal_words > 20`. A 20-word task cannot enable PDF response. |
| `public.assessment_submissions.response_mode` | Records `typed` by default and `typed_pdf` only after an eligible private PDF is accepted. |
| `private.guard_assessment_submission_response_mode()` | Prevents direct or premature mode changes. The only permitted transition is queued `typed` to `typed_pdf`, for an opted-in task above the threshold with an accepted private file. |
| Replaced `begin_submission_file_upload` / `finalize_submission_file_upload` RPCs | Recheck task eligibility at upload start and finalisation. Finalisation changes response mode in the same transaction as private-file acceptance; browser roles still cannot call these RPCs directly. |

Synthetic fixtures set the MYP task to opt in and keep the Cambridge task typed-only. The private-file SQL suite now has 35 assertions, including the boundary, deny path, absence of a pending file record on denial and rejection of a forged `typed_pdf` state. Existing PDF type/size/page validation, private Storage, opaque path, ownership, assignment, audit, fail-closed and cleanup controls remain in force.

Exact-head CI [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739) passed 619 PostgreSQL assertions across 17 SQL files, 32/32 Playwright tests, TypeScript/Worker/Vite builds, synthetic DB/private-PDF backup and restore (`backup_restore_verified`), Supabase shutdown, temporary credential cleanup and credential-free asset build. This is synthetic GitHub-hosted CI evidence only.

**Scope boundary:** this is the backend rule for typed text plus an optional PDF attachment. PDF-only submission acceptance, PDF.js extraction, scanned-page OCR, teacher split-screen, grading queue/search UI, feedback publication and timer/analytics remain future increments. No new table, hosted service, external processor or cost was introduced.


## 6.13 Historical Phase 2 PDF-only submission and transcript records — superseded by Section 6.14

Migration `20261108000500_phase2_pdf_only_and_transcripts.sql` adds PDF-only acceptance while preserving `typed` and `typed_pdf` modes. Task eligibility remains controlled by `task_versions.pdf_response_enabled` and `ideal_words > 20`. The existing `private-submissions` bucket and `private.submission_files` metadata model are reused; original PDF bytes remain private and authoritative.

| Physical record / control | Purpose and invariant |
|---|---|
| `private.pdf_submission_reservations` | Holds a capacity slot during a bounded 15-minute upload window; learner/task/rubric/mode/idempotency and opaque object path are immutable. Accepted/released/expired states are terminal. Direct table access is revoked. |
| `private.enforce_submission_capacity_with_pdf_reservations()` | Serializes against the existing singleton grading-capacity row and includes active non-expired PDF holds in the queue count; prevents typed acceptance from consuming a reserved slot and prevents cross-mode idempotency-key reuse. |
| `public.begin_pdf_assessment_submission()` | Authenticated active Student RPC; rechecks task release, enrolment, published rubric, prompt and PDF eligibility; opens or replays an idempotent reservation. |
| `private.submission_transcript_versions` | Private, append-only, numbered transcript records linked to the accepted submission and immutable private file record. Version 1 stores extraction method `pdfjs`, page-aligned JSON, combined text, extraction state and verification state. UPDATE/DELETE is blocked. |
| `public.finalize_pdf_assessment_submission()` | Worker-only transaction that rechecks active Student, task/enrolment/rubric and private object existence, creates the accepted submission/file/transcript, records the idempotency key, and starts the 24-hour SLA from final `accepted_at`. |
| `public.get_authorized_submission_transcript()` | Worker-only read RPC that first applies the same database file-authorization scope, then returns the latest transcript version. |
| Reservation cleanup RPCs | Mark failed uploads for cleanup; Owner+AAL2 claims expired/incomplete object paths; Worker removes the private object before the reservation becomes expired. |

The learner app uses PDF.js to extract existing digital text in the browser, preserving page numbering. Each page is either `digital_text` or `no_text_layer`; a page without text is stored with an empty text field and is not OCRed or guessed. Initial transcript state is `complete`, `partial` or `none`; verification state begins as `unverified` because browser-supplied extraction is not authoritative. The original PDF is always the evidence source. The table supports future append-only correction versions, but the write endpoint/UI and teacher correction audit workflow are not included in this increment.

Synthetic SQL coverage is added in `supabase/tests/phase2_pdf_only_transcripts.test.sql`; Playwright coverage exercises PDF-only acceptance, page alignment/no-text flagging and the 24-hour SLA. The final Playwright test revision `7875b98` also checks bad PDF signatures and the 11-page rejection boundary. **The latest code/test head is `7875b98b60ab7b8d4809c05d0a93a804b46f92a4`, following UI changes in `432a0a3c4b649610f683a25da4d311480049d761` and database hardening in `f5e25909576ff17ac30e1c0bf4f68bcdbd39dda7`; its exact-head CI result is not verified in the current record.** Do not use the earlier `86c0099` run as evidence for this migration. Keep this schema increment pending until the branch-push verification workflow is confirmed and all tests pass. No hosted database/storage, external OCR, cost or real learner record was used.


## 6.14 Phase 2 teacher transcript review and immutable version append — verified synthetic schema increment — 9 November 2026

Exact application-code/test head `ef9dfd23e5964bb53ceb4a461beef7534449883b` passed [GitHub Actions #42566527169](https://github.com/gradioprep/gradioprep-website/actions/runs/42566527169), including the full migration reset, 661 PostgreSQL assertions across 19 SQL files, 33/33 Playwright tests, builds and backup/restore.

No additional physical table is introduced. Migration `20261109000100_phase2_teacher_transcript_review.sql` extends the existing `private.submission_transcript_versions` relation:

| Physical field/control | Purpose and invariant |
|---|---|
| `extraction_method = 'teacher_review'` | Distinguishes human-reviewed append versions from initial browser-side PDF.js extraction. |
| `review_note` | Nullable, bounded private explanation (3–240 trimmed characters) stored on the transcript version; never copied into audit metadata. |
| `public.append_submission_transcript_version(...)` | Service-role-only RPC. Validates active account, Owner or currently assigned Grader role, AAL2, submission state, accepted source PDF, latest transcript version and expected version. |
| Submission row lock and expected-version comparison | Serializes concurrent changes and rejects stale reviews with `submission_transcript_version_conflict`; prevents silent overwrite. |
| Page-aligned JSON validation | Requires exact page count/order and bounded text/status values; permits explicit human transcription for pages with no digital text layer. |
| Immutable insert and audit | Creates the next transcript version and an audit event in the same transaction; previous versions and original private PDF bytes are never updated or deleted. |

The Worker route is `PUT /api/v1/submissions/:submissionId/transcript`; it validates the bounded body, authenticates the caller, enforces active staff role and AAL2, and invokes the service-only RPC. `teacher_corrected` records changed text; `teacher_verified` records an unchanged reviewed transcript. These labels do not mean OCR was performed. The original private PDF remains authoritative.

The responsive Account-page panel places the original private PDF beside the editable transcript. It exposes queue selection to an Owner or Grader, permits a latest-version reload, bounded review note and correction/verification save. The exact-head synthetic browser flow appended version 2 after human transcription of a page without a text layer, then version 3 after unchanged verification.

The migration also replaces `record_worker_audit_outcome` and explicitly retains existing `student_submission_file_upload` and `owner_submission_file_cleanup` allowlist entries. Two pgTAP assertions protect those legacy actions; the cross-learner upload-denial browser check passed.

The full run reports `backup_restore_verified`, one restored database snapshot and two restored private-PDF checksums; a corrupt archive is rejected. This is synthetic CI evidence only. No new hosted data service or external OCR dependency was introduced. PR #22 remains open, draft and unmerged.


## 6.15 Historical Phase 2 advisory timer baseline — superseded by Section 6.16 — 9 November 2026

Migration `20261109000200_phase2_advisory_attempt_timers.sql` adds exactly two private physical tables: `private.attempt_timer_sessions` and `private.attempt_timer_events`. The former snapshots the task-version allowance and timer-policy version at server-recorded attempt start; the latter records append-only event type, actor and server timestamp only. Both tables have RLS enabled, direct browser/service-role table grants revoked and update/delete mutation blocked. The learner-self RPC `public.get_learner_attempt_timer(uuid)` uses the database clock, calculates elapsed/remaining values and records expiry once. The learner panel displays timed/untimed task allowance and advisory countdown; the Worker excludes timer details from Grader attempt reads. Expiry does not auto-submit or block response saves/submission.

At this historical checkpoint, the advisory timer slice had been implemented on code commit `5f4e5c44e9d10fc285d3961d2c3a963fa3df5f1d`; its exact-head CI was still pending at that time. The previous 26-table inventory (18 public, eight private) is retained as the pre-timer baseline; the current physical inventory is **28 tables (18 public, 10 private)**. Timer adjustment/accommodation records were then still to be implemented; Section 6.16 records their later implementation and successful CI verification. Timed-attempt-to-assessment linkage and rubric/elapsed-response analytics remain future scope.

## 6.16 Phase 2 staff timer extensions and untimed accommodations — implemented; exact-code-head CI passed — 9 November 2026

Application-code/test commit `eae6ab23cdf7d5eaf48019d9b747d0bda9b85bf1` adds the authorised staff adjustment slice. It introduces no physical tables: the current schema remains **28 tables (18 public, 10 private)**.

| Component | Implemented control |
|---|---|
| `POST /api/v1/staff/attempts/:attemptId/timer-adjustments` | Strictly accepts an extension or untimed mode with one allow-listed reason category; rejects free text and extra request fields. |
| Worker staff-role check | Requires an active Grader, Admin or Owner role and AAL2 before invoking the caller-scoped RPC. |
| Database authorization | Independently checks active account, AAL2 and approved roles; a Grader must have an active assignment for the target attempt. |
| Extension bounds | Increment is 60–43,200 seconds; resulting allowance cannot exceed 86,400 seconds. Only an in-progress attempt with a timer session can be adjusted. |
| Untimed accommodation | Sets the effective allowance/deadline to NULL without changing the original timer-session snapshot. |
| Immutable event and audit | Appends an adjustment event with actor, timestamp, delta/effective setting, accommodation mode and fixed reason category. The database writes the success audit in the same transaction. No diagnosis or free-text explanation is stored. |
| Worker failure audit | The allowlisted Worker action `staff_attempt_timer_adjustment` records denied/failed request metadata. The audit migration retains existing transcript-review, PDF-upload and private-file-cleanup actions. |
| Synthetic regression tests | SQL covers Owner AAL2 extension/untimed controls, Student denial, unassigned-Grader denial, audit records and NULL mode rejection. Playwright covers Student denial, Owner extension, learner-visible allowance update, untimed state, and later response save/submission. |

The implementation passed exact-code-head CI on `eae6ab23cdf7d5eaf48019d9b747d0bda9b85bf1` in [GitHub Actions #42591455986](https://github.com/gradioprep/gradioprep-website/actions/runs/42591455986). The successful workflow completed PostgreSQL/RLS reset and tests, TypeScript/Worker/Vite builds, Playwright, synthetic private-PDF/database backup/restore, cleanup and the clean credential-free Preview-assets build. The run was push-triggered, so PR Preview creation/comment steps were skipped; no PR Preview URL is claimed. The prior #42579642253 run remains historical evidence for the preceding PDF/grading increment, not the adjustment-specific verification.

The next data-model increment is the transaction-safe linkage from a submitted timed attempt to the matching learner/task-version human-scored submission. Require same learner and task version, submitted state, eligible task and idempotent one-to-one linkage. Then derive accuracy from the immutable published assessment and exact rubric version, and elapsed response from server timer/adjustment history; exclude upload/OCR time and clearly label timed, extended and untimed outcomes.

## 6.17 Phase 2 immutable timed-attempt assessment links — verified synthetic schema increment — 9 November 2026

Migration `20261109000600_phase2_timed_attempt_assessment_linkage.sql` adds one private physical table and composite identity constraints to the existing attempt/submission parents. Exact application/test snapshot `95be230d07223411538f1e90e4507a043680730e` passed GitHub Actions [#42642106215](https://github.com/gradioprep/gradioprep-website/actions/runs/42642106215): **721 SQL assertions across 21 files and 35/35 Playwright tests**, plus builds, synthetic DB/private-PDF backup/restore, corrupt-archive rejection, cleanup and clean credential-free Preview-assets build.

| Physical record / constraint | Purpose and invariant |
|---|---|
| `private.timed_attempt_assessment_links` | Private immutable identity link; stores link ID, attempt ID, assessment submission ID, learner ID, task-version ID, learner-scoped idempotency key and server link timestamp only. No response text, marks or analytics are stored. |
| Composite attempt uniqueness/FK | `public.attempts(id, learner_id, task_version_id)` must match the stored link's attempt, learner and task version. |
| Composite submission uniqueness/FK | `public.assessment_submissions(id, learner_id, task_version_id)` must match the stored submission, same learner and same task version. |
| Unique attempt and submission constraints | A timed attempt can be linked once and an assessment submission can be linked once. |
| `UNIQUE (learner_id, idempotency_key)` | A learner cannot reuse a key for a different pair; identical pair/key retries replay the original link. |
| RLS, grants and immutability trigger | RLS is enabled, direct access is revoked from browser roles/service role, direct UPDATE/DELETE is rejected and normal account-deletion cascades remain possible. |

The authenticated Student-only Worker route `POST /api/v1/learner/attempts/:attemptId/assessment-link` invokes `public.link_timed_attempt_assessment_submission(uuid, uuid, uuid)`. The RPC takes a transaction advisory lock for the learner/idempotency key and row locks for both parent rows. It rechecks same learner/task version, submitted attempt and submitted timer event, active enrolment, published task and exact mapped published rubric, linkable assessment status and response evidence. Typed response requires immutable version 1; PDF-backed responses require an accepted private source and immutable transcript version 1 and task PDF eligibility.

Success writes the link and a success audit record atomically. Worker denial/failure outcomes use the existing metadata-only audited path. The Playwright regression verifies replay identity under concurrent duplicate requests, idempotency conflict, one-to-one conflicts, pre-submit, cross-task, cross-learner and withdrawn-submission denial. The corrected independent Student C fixture uses `cccccccc-cccc-4ccc-8ccc-cccccccccccc` for both enrolment setup and cleanup.

**Current protected physical inventory: 29 tables (18 public, 11 private).** This is synthetic CI evidence; it does not create an analytics result, change the timer policy, provide hosted backup or establish production readiness. The next model increment for analytics must preserve an immutable published assessment/rubric reference and derive elapsed response from server timer/adjustment history, excluding upload/OCR processing duration.


## 6.18 Phase 2 rubric-version-bound attainment and elapsed-response analytics — verified synthetic schema increment — 10 November 2026

Migration 20261110000100_phase2_rubric_attainment_elapsed_analytics.sql adds one private physical table. Exact application/test snapshot 363608c1c449a46388a7f14862021f2782f49cd0 passed GitHub Actions [#42756087000](https://github.com/gradioprep/gradioprep-website): **776 SQL assertions across 22 files and 35/35 Playwright tests**, plus TypeScript/Worker/Vite builds, synthetic database/private-PDF backup/restore (one database snapshot, two PDF checksums; corrupt archive rejected), local stack shutdown, credential cleanup and clean Preview-assets build. The protected physical inventory is now **30 tables (18 public, 12 private)**.

| Physical record / field family | Purpose and invariant |
|---|---|
| private.assessment_response_analytics | One private immutable derivation per published assessment version. Primary key references public.assessment_versions; records assessment/submission/learner/task/rubric and version identities plus response mode. |
| timed-attempt relationship | Stores the immutable link ID and attempt ID only when an attempt-to-assessment link exists. The link itself already enforces exact learner/task-version identity and one-to-one use. |
| attainment fields | Published awarded score, exact maximum/denominator, percentage, attainment status, criterion counts and criterion-level score snapshot. |
| criterion validation | Derivation verifies complete, unique criteria for the exact rubric version; criterion IDs and code/title/descriptor/max-point snapshots must match that published rubric; criterion totals must agree with the published assessment total and maximum. |
| elapsed-response fields | Nullable server-derived seconds, explicit validity status, timer mode, policy version, base/effective allowance, accommodation mode and adjustment count. |
| comparability fields | Exact-context key and explicit eligibility/exclusion status. Key binds task version, rubric version, response mode, timer-policy version, timer mode, accommodation and base/effective allowance. |

The deferred constraint trigger derives analytics after the publication transaction has inserted all criterion_result rows. It reads only public.assessment_versions, public.criterion_results, public.assessment_submissions and the immutable timed link/timer history; it never reads private.assessment_drafts. Each human publication/edit version receives a separate immutable analytics row, and the guarded read returns the latest published version.

Elapsed response is floor(submitted_at − timer_session.started_at), after checking the link identity, submitted attempt state and learner-authored private submitted timer event. It does not use browser timing or client-provided duration. PDF upload, accepted-file, transcript creation/extraction and OCR timestamps are not used. Missing/unlinked/invalid timer data is labelled and the elapsed value remains NULL; no duration is fabricated.

Regular timed, extended and untimed accommodation are distinct labels. Timer-session allowance is preserved separately from the latest append-only adjustment-derived effective allowance. Exact-context group keys prevent timed/extended/untimed and differing task/rubric/response-mode/allowance contexts from being pooled. The system does not calculate speed ranks, cohort percentiles or public comparisons. A future aggregate comparison still needs separately validated sample-sufficiency and academic interpretation rules.

The analytics relation has RLS enabled and direct grants revoked from PUBLIC, anon, authenticated and service_role. The authenticated read RPC and Worker route expose only the latest published analytics row to an active AAL2 Grader with the active submission assignment; the Worker performs an independently checked metadata-only audit. Learner/guardian routes do not include analytics, and unpublished grader drafts remain private. No response text, final feedback text, diagnosis, keystrokes, focus/attention signals, rank or percentile fields are stored.

This is synthetic schema/CI evidence only; it does not establish production readiness or approve hosted resources, paid usage, real learner data, external OCR/AI, DNS, merge or production deployment.


## 6.19 Typed-plus-PDF file/transcript version lineage correction — verified exact-head synthetic CI — 10 November 2026

Application/test head `51fdde6d3191054b34f3ad0f8d141cbc99d233e6` passed [GitHub Actions #42770920114](https://github.com/gradioprep/gradioprep-website/actions/runs/42770920114), including the 35/35 Playwright suite. The application correction is represented by append-only migration `20261110000400_phase2_typed_pdf_source_bound_linkage.sql` (introduced on parent `94aec23`) and its late-file-version browser regression.

An optional typed-plus-PDF upload creates an immutable pending file-version record before validation. Rejected attempts remain in history and can consume earlier file-version numbers. The accepted file and immutable transcript are therefore paired by the exact `private.submission_transcript_versions.source_file_id = private.submission_files.id` relationship, not by assuming both records are version 1. The timed-attempt linker still requires the accepted file to belong to the same assessment submission and learner, and requires its source-bound transcript; a rejected or pending file cannot satisfy the acceptance check.

The PDF-only reservation/finalization path remains separately validated. Typed-only submissions still require their immutable original response version. No table, column, key or physical relation was added by this correction; protected inventory remains **30 tables (18 public, 12 private)**. This update clarifies existing record/version semantics only and is backed by synthetic CI, not hosted backup or production acceptance.

## 6.20 Historical Phase 2 Diagnostic attempt and 15-observation baseline — 10 November 2026 (superseded for Listening by Section 6.21)

Exact application/test HEAD `12b0a4d47dedb2bd0fc7396cc36824145d437e21` passed [GitHub Actions #42814204466](https://github.com/gradioprep/gradioprep-website/actions/runs/42814204466): **825 SQL assertions across 23 test files, 36/36 Playwright tests**, TypeScript/Worker/Vite builds, synthetic database/private-PDF backup and restore (one database snapshot and two private-PDF checksums; corrupt archive rejected), shutdown, local credential cleanup and clean credential-free Preview-assets build.

Migration `20261110000500_phase2_diagnostic_attempts.sql` adds these four public physical relations:

| Physical relation | Purpose and invariant |
|---|---|
| `public.diagnostic_versions` | Versioned Diagnostic identity, pathway, release state and administration envelope. |
| `public.diagnostic_observations` | Version-bound observation ID/code, group, sitting, sequence, response kind and explicit learner-capture flag. |
| `public.diagnostic_attempts` | One learner-owned attempt per Diagnostic version, idempotency key, status and database timestamps. |
| `public.diagnostic_response_versions` | Append-only response revisions, tied to an attempt and observation, with database save timestamps. |

All four relations have RLS enabled. Authenticated access is SELECT-only at the table grant layer; direct browser writes are revoked. Version and observation visibility requires an active account and either an enrolled active Student viewing a published pathway version or an Owner with AAL2. Attempt visibility is limited to the active Student who owns it; response visibility is derived through that learner-owned attempt. Private `security_audit_events` is reused; no new private audit table is introduced.

Writes use narrow SECURITY DEFINER RPCs with fixed search paths and database-derived actor identity. `create_diagnostic_attempt` checks active Student role, published version and active enrolment, resumes the existing learner/version attempt idempotently, and audits start/resume. `save_diagnostic_response` locks the learner-owned in-progress attempt, validates the observation is enabled and validates the exact bounded response envelope, then appends a revision; identical retries do not create another revision. A mutation trigger rejects UPDATE/DELETE of response versions, and an insert trigger writes metadata-only audit events. `submit_diagnostic_attempt` locks the attempt and requires one saved response for every observation currently marked `learner_capture_enabled` before changing state to submitted. Submitted evidence is immutable.

Migration `20261110000600_phase2_diagnostic_language_context.sql` extends the private response validator for LC01–LC05 and broadens the existing save/submit RPCs from an RV-only filter to the enabled observation set. It introduces **no new table or column**. The current synthetic version enables 10 Read & View observations plus 5 Language in Context observations (15 total); it reserves the sequence range for Listening but does not enable Listening capture. The Worker validates the outer request envelope, preserves the attempt and response-code URL captures, requires an active Student, and relies on the same strict observation-specific response contract. The learner UI supports start/resume, save progress, final submit and submitted-state read-only rendering.

This increment does **not** implement Listening, the remaining 20 mapped observations, scoring, answer-key access, criterion weights, cut scores, automatic marking, AI feedback, cohort percentiles, Evaluation Report generation or public learner release. The synthetic seed uses a published test version solely to exercise the enrolment/RLS path; it is not a live release state. Listening remains gated on a standardised human-produced recording and human quality review. This is synthetic CI evidence only and does not establish production readiness or authorise hosted resources, real learner data, external processing, paid usage, DNS, merge or production deployment.


## 6.21 Historical Listening-in-PA experiment — withdrawn from PA by Founder direction — 11 November 2026

The provisional Listening expansion was implemented on application/test head `262db4668110a77661bdd283bb3dd7eda5c91b35` and passed exact-head GitHub Actions #42951322767 (833 SQL/pgTAP assertions across 23 files and 36/36 Playwright tests). It enabled L01–L05, taking the synthetic attempt to 20 observations, and streamed a VOA Learning English audio candidate.

That was a technical experiment only. It was withdrawn from PA scope because the existence of Listening as a broad language skill did not prove that a separate Listening task was a necessary, directly mapped component of the MYP Year 4 PA. A public-domain asset also did not establish curricular necessity, appropriate assessment placement or MYP criterion/strand alignment. Do not treat the 20-observation build or its CI as the accepted PA design.

The new forward migration `20261111000200_phase2_remove_listening_from_preliminary_assessment.sql` supersedes that experiment without rewriting prior migrations. It restores the pre-Listening RV/LC response contract, disables any existing Listening rows for capture, and sets the synthetic MYP PA version duration to 80 minutes. The historical Listening rows/old migration remain for audit and rollback history; they are not enabled PA observations. Listening is reserved for Milestone 3 / SA3, never PA, SA1 or SA2, and only where route-specific official mapping is verified.

## 6.22 Preliminary Assessment scope correction and milestone assessment design boundary — 11 November 2026

**Current PA design:** 15 enabled observations in the existing secure learner-owned attempt: 10 Read & View and 5 Language in Context. The intended PA envelope is 80 minutes (Sitting 1 = 35 minutes; Sitting 2 = 45 minutes). The current application implements only RV01–RV09 (with RV07a/RV07b distinct) and LC01–LC05: 15 evidence observations. The wider MYP PA item map v0.2 plans 30 observations in total after adding five Analytical Writing, five Creative/Purposeful Production and five Speaking/Presenting evidence dimensions; these additional 15 are not yet in the learner application.

**Rollback implementation:** application/test candidate head is pending exact-head successful CI; first attempt #42955376995 on parent `7cf6fcd9880e3aab249328645e72136614b2d621` failed due malformed dollar quoting in a negative SQL assertion. The quoting was corrected in `bc6efdaee987110acd55cdc1ed655a4676e01ec2`; GitHub Actions #42956397671 is pending on this exact commit. Do not accept the rollback until the full workflow passes.

The current implementation reuses the four existing public RLS-protected Diagnostic relations; there is no new table or column. Existing learner ownership, bounded response envelopes, append-only response revisions, metadata-only audit and completion-gated submission remain. The Worker route does not accept L01–L05 in the PA. The synthetic seed enables 15 observations and contains no active Listening observation. The forward migration also disables any historic L group row that may exist in an already-seeded PA database, so it cannot be captured by an old or stale client.

**Milestone / SA data-model boundary:** no Milestone, SA1/SA2/SA3 or segment Evaluation Report relation is implemented by this correction. The product model is specified in `docs/ASSESSMENT_CURRICULUM_MAPPING_AND_MILESTONE_STANDARD.md`: a Milestone is the set of curriculum units completed in a progress segment; its SA assesses that unit set; the segment Evaluation Report is separate from the Overall Progress Tracker. Before proposing new tables, audit/reuse existing curriculum unit membership/progression records, `public.assessments`, `public.assessment_versions`, `public.criterion_results`, `private.assessment_response_analytics` and existing timer/attempt linkage. Preserve each immutable assessment/rubric/content/mapping version and the unit set actually assessed. Do not add milestone/report tables until a reuse/gap analysis demonstrates they are needed.

**Listening placement:** the L group code remains available as a future task family; it is not globally removed from the schema. No L observations are active in the PA, SA1 or SA2. SA3 Listening may be designed only after the M3 units and exact official board/course/session/component mapping have been approved. No real learner data, external audio/AI processing, hosted resource, cost or production action is introduced here.

## 6.23 Verified PA rollback and read-only milestone / report-record reuse audit — 11 November 2026

**Exact rollback verification:** Application/test commit `bc6efdaee987110acd55cdc1ed655a4676e01ec2` passed GitHub Actions [#42956397671](https://github.com/gradioprep/gradioprep-website/actions/runs/42956397671), run 572, attempt 1, on GitHub-hosted `ubuntu-24.04`. The workflow checked out that exact SHA and completed its local Supabase security/RLS tests, TypeScript/Worker/Vite build, Playwright suite, synthetic database/private-PDF backup/restore, local shutdown, credential cleanup and clean public-preview asset build. The Cloudflare Preview create/update steps were skipped; no Preview deployment is claimed. PR #22 is still open, draft and unmerged. Its later branch HEAD `57faa3c0728e2f89667bbe88745aca22fb3373be` is nine commits ahead of the tested code commit; the intervening changes are documentation-only, so the application/test snapshot remains the verified `bc6efda` commit. This does not claim that a later application-code change has been tested.

**Read-only physical-record audit:** the existing architecture contains useful assessment records, but it cannot yet represent M1/M2/M3 curriculum-unit sets or produce distinct composite segment Evaluation Reports. The static frontend pathway/unit-planning objects are not database records and are not a substitute for persistent progression history.

| Required capability | Existing reusable records | Reuse boundary / gap |
|---|---|---|
| M1/M2/M3 unit catalogue and membership | `src/content/pathways.ts` creates three planned unit slots per pathway; `src/content/unitReadiness.ts` holds static planning/readiness objects. | These are code-level planning fixtures. The slots are mostly empty and are not a persisted route/syllabus/unit catalogue, versioned milestone set or learner unit-completion record. No physical curriculum-unit membership/progression relation is present in the inspected migrations. **Gap.** |
| PA attempt and baseline evidence | `public.diagnostic_versions`, `public.diagnostic_observations`, `public.diagnostic_attempts`, `public.diagnostic_response_versions`. | Reusable for versioned, unscored PA definition, learner attempt and append-only response evidence. They do not currently link observations to verified official route outcomes or create PA analytics/Evaluation Reports. |
| SA1/SA2/SA3 task attempts | `public.attempts`, `public.assessment_submissions`, `public.submission_versions`, plus `private.timed_attempt_assessment_links`. | Reusable at individual task/submission level. Timed linkage enforces matching learner/task identity and one-to-one attempt/submission pairing. No relation groups those task attempts into a specific immutable SA/milestone unit set. |
| Rubric identity and versions | `public.rubrics`, `public.rubric_versions`, `public.rubric_criteria`, `public.task_rubric_mappings`. | Reuse. Rubric versions are immutable once used; task versions can bind to an exact rubric version. |
| Criterion-level results | `public.assessment_versions`, `public.criterion_results`. | Reuse for human-published assessment versions. Criterion results snapshot criterion code/title/descriptor and score/feedback. These are per published task-submission assessment, not a multi-task segment report. |
| Published human feedback | `public.assessment_versions.overall_feedback`, `public.criterion_results`, `public.publish_assessment_feedback(...)`. | Reuse as immutable, versioned human feedback publication. This is not the complete Evaluation Report combining analytics, approved feedback and the report presentation. |
| Private assessment analytics | `private.assessment_response_analytics`. | Reuse as an input: it is derived per published `assessment_version_id` and records rubric-bound attainment/criterion snapshots, elapsed-response/timer metadata and comparability status. It is limited to the linked human-assessment path; it is not PA-attempt analytics or an M1/M2/M3 aggregate report. |
| Segment Evaluation Reports | No existing composite report/version relation identified. | **Gap.** Need an immutable PA/SA segment report snapshot with exact route, unit-set version, assessment/item versions, official mappings, learner evidence, rubric version, analytics, confidence/limitations and teacher-approved feedback references. |
| Overall Progress Tracker | No persisted milestone/unit-progress model identified. | **Gap.** Must remain a separate longitudinal view over unit/milestone progress and links to segment reports; it must not overwrite or replace those reports. |

**Naming clarification:** for the implemented human-grading path, the physical objects are `public.assessment_submissions` and `public.assessment_versions`; do not assume a physical `public.assessments` table. A submission is a task-level human-grading record, and an assessment version is its immutable published grading/feedback version.

**Reuse decision:** retain the current Diagnostic attempt/response model for PA evidence; retain task submissions, timed links, rubric versions, criterion results and published assessment versions for individual human-graded SA tasks; use private assessment analytics only as a component input. Do not repurpose per-task assessment versions as an aggregate Evaluation Report.

**Next physical implementation order:** (1) academically lock exact learner-route and syllabus-edition identifiers; (2) establish the persistent curriculum-unit catalogue/version model and immutable M1/M2/M3 unit-set membership; (3) add route-specific item/task-to-official-outcome mapping records with `DIRECT`/unmapped review state; (4) link each SA attempt/submission to the exact milestone/unit-set version and assessed item versions; (5) add immutable, versioned segment Evaluation Report snapshots that reference published feedback and eligible analytics; (6) keep the Overall Progress Tracker as a separate cumulative unit-progress view. Add schema only in that order and with synthetic SQL/Playwright regression tests. Do not seed MYP Year 4, Cambridge or CBSE unit membership until the precise route and official curriculum mappings are academically verified.

**MYP Year 4 mapping gate:** see the item-by-item audit in `docs/curriculum/IB_MYP_G9_DIAGNOSTIC_ITEM_MAP_AND_SCORING_SPEC.md` §5.1. The 30 observations have candidate subject-strand fits only; no exact Year 4 descriptor/progression has been verified. The required academic review and any exclusions/revisions must precede learner-app expansion.

