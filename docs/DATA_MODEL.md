# Logical Data Model — Curriculum, Practice and Assessment

**Status:** Proposed implementation blueprint; no database or real learner records are connected yet.
**Source of truth:** `PROJECT_MASTER_BRIEF.md`
**Goal:** Define relationships and permission boundaries before connecting the current prototype to a database. This document is provider-independent; the master brief's proposed Supabase approach still requires a current plan/terms review before real student data is stored.

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

This is a logical model, not yet a live SQL schema. Names can be adapted during implementation as long as the relationships, constraints and access rules are preserved.

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
| `tasks` | ID, task type, prompt/instructions, response type, difficulty label where justified, estimated time, release state, version | Use for practice, diagnostics and extended-response tasks; do not expose answer keys by default |
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

### Unit content planning and release readiness

The current frontend code also defines a `unit_content_plans`-style record for planning each pathway unit. Its intended fields include:

- Target unit/pathway IDs and a content version.
- Official syllabus edition, source URL, date checked and objective codes.
- Approved learning objective.
- Linked lesson and practice-question IDs.
- Answer-key review state.
- Academic reviewer/date, content rights/source note and accessibility review state.
- Explicit release approver/date and release state.

The `src/content/unitReadiness.ts` helper calculates eight gates from this evidence. A source edition/objective mapping and a learning objective are blocking requirements; missing lesson/practice content, reviews and approvals cannot be assumed complete. The first IB MYP Year 1 planning record retains the public subject-page URL and date checked. The pilot pack in `src/content/pilotUnitDraft.ts` also records the public subject-brief URL and two candidate Year 1 Criterion A strands found in an IB-hosted guide search result. Since opening the detailed guide redirects to IB curriculum sign-in and the applicable school-guide edition remains unconfirmed, the candidate strands are stored separately from `officialObjectiveCodes`; mapping remains unverified. The pack now includes a worked response and explanatory annotations, but it remains a draft, is not linked to the demo lesson and has no release approval. Current records are static planning fixtures. The Pathways screen's checklist is read-only and is not a content editor, database or release mechanism.

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

## 3. Important constraints

- Use stable IDs (UUIDs or equivalent) for internal records. Use human-readable codes for programmes, syllabus editions, skills and content IDs where useful.
- Add database constraints for required links, uniqueness and valid states; do not rely only on form validation.
- A published content item points to an exact reviewed version. Corrections create a new version and require review.
- An accepted submission stores the task version, rubric version, required credits, accepted timestamp and SLA snapshot. Later changes to a task or standard must not rewrite an existing obligation.
- Credit balance is calculated from ledger entries. Purchases, reservations, usage, releases, refunds and expiry are explicit events, not an editable balance field.
- Prevent duplicate free human-review entitlement server-side. Changing course/topic must not grant another free assessment.
- Only a trusted server operation may accept submissions, reserve/release credits, calculate due times, publish assessment versions or change privileged roles.
- Store timestamps consistently (normally UTC) and render them in the learner's appropriate timezone.
- Do not keep unnecessary sensitive details. Access, retention, consent and deletion practices must follow owner-approved privacy terms and the chosen provider's actual settings.
- Avoid permanent deletion of records needed for grading/audit history; design a documented retention/anonymisation policy before production.

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

## 5. Build order

1. Approve the content fields, pathway mapping workflow and initial pilot pathway.
2. Create versioned content fixtures/types using the model; keep current demo content explicitly marked as fictional.
3. Review `src/content/pilotUnitDraft.ts` with the academic lead, confirm the applicable MYP guide and whether candidate strands A(ii), A(iii), or both fit, then use the readiness gates to track verified mapping, finished lesson/practice links and reviews before release.
3. Choose and verify the database/auth provider's current terms, limits, backup and restore approach before creating production records.
4. Create database migrations and enforce least-privilege access policies.
5. Add authentication and profiles, then pathway enrolments and published content reads.
6. Add saved attempts and progress evidence; test that two learners cannot see each other's records.
7. Add submission/credit/capacity transactions, then versioned grader workflow and admin-only QA.
8. Before a real learner pilot, test role boundaries, backup/restore, deletion/retention operations and mobile use.

**Not implemented:** These tables are a planning model, not a claim that authentication, a database, row-level security, saved records or real assessment workflows exist today.
