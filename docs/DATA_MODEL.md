# Logical Data Model — Curriculum, Practice and Assessment

**Status:** Provider-independent logical model with the approved first implementation mapping: Supabase Auth, PostgreSQL and private Storage in Mumbai (`ap-south-1`). Phase 0 architecture, timer and retention decisions are approved. The local synthetic-only Phase 1B subset in draft PR #22 covers profiles, role assignments, guardian links, course enrolments, restricted audit records and private staff invitations. The first Phase 1C physical slice adds versioned task prompts, learner-owned typed attempts/responses, grader assignments and a private append-only response-version archive, with Worker/RPC paths and role-scoped RLS. Code commit `05544d1a394e2e480b7cd2dd9f55100b6998ee71` passed exact-head run [#41613490244](https://github.com/gradioprep/gradioprep-website/actions/runs/41613490244): 116 PostgreSQL/pgTAP assertions across four SQL files and 24/24 Playwright tests, plus local Supabase reset/seed and application builds. The current immutable public Preview is https://b4391d8e-gradioprep-website.wandering-scene-1822.workers.dev; it is not connected to hosted Supabase. This is local synthetic infrastructure only, not hosted provisioning, a production account service or a real learner record store. The physical Phase 1C scope and remaining gaps are recorded in the Master Brief v4.46 and Phase 1 specification Section 20.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`
**Goal:** Define the provider-independent relationships and permission boundaries for the platform. The approved first implementation mapping is Supabase Auth/Postgres/Storage in Mumbai; a defined identity/security subset is now implemented in the local synthetic stack described above. This model is not a claim that all planned learning, submission, grading or storage records are live. Supabase Pro and all third-party service costs/terms must be reconfirmed and separately authorised before real learner data.

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
| `task_rubric_mappings` | Task version ID, rubric version ID, required credits, expected response format/scope | Define what one credit covers before the learner submits |

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
| `assessment_submissions` | ID, learner ID, task version ID, status, accepted time, due time/SLA, credit requirement | Acceptance is a server-side operation that checks capacity and entitlement before committing |
| `submission_versions` | Submission ID, version number, response snapshot/protected storage reference, created by/time | Preserve the original accepted response and every later revision; do not overwrite history |
| `grader_assignments` | Submission ID, grader user ID, assigned by/time, status | Graders may access only assignments they are authorized to grade |
| `assessments` | Submission ID, grader ID, rubric version ID, draft/final/published state, timestamps | A draft is not visible as published feedback |
| `assessment_versions` | Assessment ID, version number, score summary where valid, comments, author, timestamp, change reason | Preserve drafts/final versions and record reasons for changes; never replace a published version silently |
| `criterion_results` | Assessment version ID, criterion ID, mark where applicable, evidence excerpt/reference, comment | Score, comment and evidence must align with the selected rubric |
| `assessment_audit_events` | Assessment/criterion ID, actor, change, reason, timestamp | Append-oriented audit trail for mark/comment edits and administrative decisions |
| `credit_ledger` | Learner ID, transaction type, credit delta, purchase/use/refund/expiry reference, task/submission reference, actor, timestamp | Auditable source of truth; never trust a client-supplied balance or let the browser directly modify credits |
| `capacity_slots` or equivalent server-side controls | Date/window, accepted workload, available capacity, applicable SLA | Acceptance must be blocked when it cannot meet the promised SLA; preserve draft and entitlement safely |
| `private_qa_records` | Assessment ID/version, checks, status, explanation, uncertainty, reviewer action | Admin/owner only; graders and learners cannot read this record |
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

**Implementation boundary:** The physically implemented local synthetic subset in draft PR #22 includes the Phase 1B identity/security records (profiles, role assignments, guardian–learner links, course enrolments, restricted audit events and private staff invitations) plus the first Phase 1C typed-attempt/grader-access records (`task_versions`, `task_version_prompts`, `attempts`, `attempt_responses`, `grader_assignments` and private `attempt_response_versions`) and their narrow Worker/RPC paths. The typed attempt queue/detail and assignment feature is not the complete accepted human-assessment workflow. `assessment_submissions`, full submission/version and rubric/criterion records, assessment/feedback versions and publication, private QA, PDF objects/storage, OCR, timers and credit-ledger activation remain incomplete or logical-design-only. This is local Supabase with synthetic fixtures only, not hosted provisioning, real learner data or a production-ready account service.


**Historical Phase 0 and cost-policy approval note — 3 November 2026 (implementation checkpoint superseded by Master Brief v4.45):** The logical records for PDF submissions, page extraction, feedback drafts/versions, grader SLA and timers remain a design proposal only. Supabase Mumbai Auth/Postgres/Storage, Azure Read OCR (intended Central India), Cloudflare Workers AI stateless drafts, Cloudflare R2 encrypted secondary object backup, 10 MB/10-page file caps, advisory no-pause timer policy and the retention/deletion matrix are Founder-approved. The Founder-approved free-first policy targets US$0 recurring infrastructure subscriptions and paid API usage for 3 November 2026–2 November 2027, with a non-automatic service review at 100+ subscribers. Free-tier shortcomings must be controlled and tested before real learner data; paid upgrades require proof of necessity and explicit cost approval. Hosted resource provisioning, paid plans/usage and real learner data remain separate gates. Local synthetic-only Phase 1B coding is separately approved and underway in draft PR #22; suspended-account RLS/Worker denial and sign-out behavior passed exact-head CI run #41500536318, with 16/16 browser tests. The exact tested Preview and remaining Founder visual-review gate are recorded in the Master Brief v4.37.


## Phase 1 security implementation cross-reference — 2 November 2026

The Phase 1 specification is the implementation-level companion to this provider-independent model. It requires database-backed role assignments, guardian-link verification, assignment-scoped grader access, immutable task/rubric/submission version references, UTC timestamps, transactional state changes, default-deny RLS and private Storage policies. It also specifies API actor derivation from verified identity, server-owned fields, audit records, deletion controls and synthetic cross-role tests. The local synthetic Phase 1B increment now includes private staff invitations, owner+AAL2 management, verified-email+AAL2 acceptance, token-hash-only storage and append-only audit events, with exact-head SQL/API/browser evidence recorded in the Master Brief v4.45. The data model does not authorise hosted resource provisioning, paid plans/usage or real learner data. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`; preserve this document's logical relationships and data definitions if physical table names or migrations are refined.


**Historical Phase 1A/1B implementation handoff — 3 November 2026 (superseded by the Phase 1C checkpoint above):** The original identity migration and Phase 1B staff-invitation migration remain implemented as described in the historical record. Phase 1C has since added typed attempts/responses, response-version archiving and assignment-scoped grader reads in the local synthetic stack. The broader accepted assessment submission, PDF object, human grading/feedback version, timer and credit workflows remain later incomplete slices; do not create speculative unused tables merely to accelerate PR #22.
