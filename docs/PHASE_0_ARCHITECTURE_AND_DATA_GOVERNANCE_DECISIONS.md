# Phase 0 Architecture, Privacy and Data-Governance Decisions

**Version:** 1.0  
**Decision date:** 2 November 2026  
**Status:** Phase 0 decisions approved by the Founder. Phase 0 is complete. These are approved design decisions, not authority to create accounts, incur costs, configure services, process real learner data, merge, deploy or release.  
**Applies to:** Shared Grades 6–12 written-response, PDF submission, human grading, feedback and timed-analytics platform.

## 1. Architecture decisions

1. **Application hosting:** Retain the existing Cloudflare Workers deployment for the React application and lightweight request/API orchestration. Do not run CPU-heavy PDF processing or OCR inside a Worker.
2. **Authentication, database and primary private file storage:** Use one consolidated **Supabase** project for Supabase Auth, PostgreSQL and private Supabase Storage. The primary project region is the specific AWS **South Asia (Mumbai), `ap-south-1`** region. Do not use Cloudflare D1 or introduce a second application database.
3. **Live-data plan:** Use Supabase **Pro** before any real learner records are accepted. The Free plan is restricted to synthetic/development data because it can pause after inactivity and has no automatic database backups. Pro is currently advertised from USD 25/month, but compute, egress, storage and usage can add cost; reconfirm the full quote before provisioning. No plan has been purchased.
4. **Database and file backup:** Supabase Pro daily database backups provide a seven-day recovery window, but Supabase database backups do **not** include Storage API file objects. Maintain a separate encrypted off-site backup of private PDF objects and required metadata. **Cloudflare R2** is the selected secondary backup target only; it is not the application-facing primary storage and is not a second database. Use an APAC location hint where appropriate, but this is best-effort placement, not a residency guarantee. Do not replicate real learner content to R2 until cross-border transfer, residency, encryption/key management and privacy review are complete. A documented restore test must restore both database records and original PDF objects.
5. **Digital PDFs:** Use Mozilla **PDF.js** in the application for rendering the original PDF and extracting its embedded digital text. This is the first path and avoids an external OCR request where a usable text layer exists.
6. **Scanned pages and handwriting OCR:** Use **Microsoft Azure AI Document Intelligence Read (`prebuilt-read`, v4 API)** as the selected OCR integration, with **Central India** (`centralindia`) as the intended resource region. Confirm service availability for this exact resource/region at provisioning; do not silently fail over to another country/region. The service is external processing, not in-house OCR. Use a synthetic handwriting/print quality benchmark before any real learner content is sent. For the F0 pilot pathway, enforce the documented 4 MB per-request input limit, first-two-PDF-pages-per-request limit, 1 request/second limit and 500 pages/month quota. Process one internally rendered page image per request, each below 4 MB. Enforce the monthly quota in GradiPrep. Quota exhaustion or OCR failure must never reject or destroy an already accepted original PDF; the teacher grades from the original.
7. **AI feedback drafts:** Use **Cloudflare Workers AI** for on-demand generation of exactly ten teacher-only suggestions, subject to synthetic evaluation and model selection. Use standard stateless inference only: no AI Gateway logging, caching, asynchronous/batch file storage or other stateful content-retaining feature. Do not write prompts or outputs to application logs. No automatic paid overage; when quota is exhausted or AI is unavailable, the teacher writes feedback manually. AI suggestions remain drafts and are never published without human action.
8. **Upload limits:** Accept PDF only. Enforce a maximum of **10 MB and 10 pages per submission** in the initial pilot, in addition to signature/MIME validation. This is a product safeguard, not the provider's maximum. Internally rendered OCR page images are transient processing artefacts, each below the OCR request limit; they are not accepted uploads or retained alternate submissions.
9. **Provider-independent logical data model:** Keep the logical model and records portable, but implement its first provider mapping on Supabase. All access checks must be server-side, backed by PostgreSQL Row Level Security and private storage policies/signed access. Never expose service-role keys or permanent storage credentials to the browser.

## 2. Approved student timer policy

- The countdown is **advisory**, not a hard stop. The task-specific allowance is set by the academic author for each task and version.
- The timer starts when the server records the learner's accepted task start. It is server-authoritative and continues through refresh, disconnection and a hidden/background browser tab. The first release has no learner-controlled pause/resume.
- At zero, preserve the learner's saved response. Do not auto-submit, truncate, delete, lock or block saving/submission solely because the countdown reached zero.
- An authorised teacher/admin may grant a time extension or untimed accommodation before or during an attempt. Record the reason category, amount/setting, authorising role, actor and timestamp. Do not collect or store a diagnosis or unnecessary medical information. A verified platform outage or documented disruption may be handled through an audited allowance adjustment or a new untimed attempt.
- Record only the minimum task-timing events required for start, saved response, submit, expiry and authorised adjustment. Do not collect keystrokes, screenshots, browsing history, focus/attention signals or hidden-tab surveillance.
- Analytics must label the measure **elapsed response time**, not active attention or time-on-task. Compare duration only across sufficiently similar tasks, skills, rubric versions and allowances; interpret it with accuracy and human rubric results. Speed is not inherently better and must not determine a learner's ability, mastery, rank or badge. Exclude upload and OCR processing time.

## 3. Approved retention and deletion policy

| Data class | Retention from course completion / task completion | End-of-period action |
|---|---|---|
| Original PDF, raw extraction and teacher-corrected transcript | While the learner is enrolled/active; then 12 months after formal course completion, recorded withdrawal or administrative course closure (whichever ends participation) | Securely delete content and object copies; keep only a minimal non-content deletion audit where necessary |
| Published feedback, rubric outcomes and feedback-version/edit audit history | 24 months after formal course completion, recorded withdrawal or administrative course closure | Delete or irreversibly anonymise, subject to a documented legal hold |
| Event-level task timer records | 12 months after the task attempt | Delete or retain only irreversibly de-identified aggregates |
| Internally rendered page images/raster files | Temporary processing only | Delete immediately after the OCR request has completed/returned; never treat as a learner submission or long-term record |
| Azure Document Intelligence analysis result | Retrieve, then call the Delete Analyze Result API as soon as the result has been safely ingested | Do not rely on the service's 24-hour availability window as GradiPrep retention; confirm deletion in synthetic tests |
| Encrypted off-site file backups | Maximum 30 days | Expire backup copies within 30 days of the source record's scheduled deletion |

A verified deletion request is actioned within **30 days**, subject to a valid legal hold or other mandatory retention obligation. For this policy, the course's formal end event is recorded completion, recorded withdrawal or administrative course closure; the post-course retention clock starts from that recorded event. An open/inactive course does not silently reset or suspend a deletion clock forever: prolonged inactivity must create a restricted owner review task to confirm continued enrolment or formally close the course, not an automatic deletion. Propagate deletion to application storage, derived OCR/transcript content and external processors where applicable. Backup copies expire within the stated maximum backup window; do not promise immediate physical erasure from immutable backups. Record the request, scope, completion and any exception without retaining deleted content. Audit/legal-hold exceptions require restricted access, reason and review date.

## 4. Roles and access boundaries

| Role | Access rule |
|---|---|
| Student | Only the student's own profile, attempts, original submissions and published feedback |
| Guardian | Only a learner with a valid, verified and authorised guardian–learner relationship |
| Grader | Only assigned submissions and the rubric/task information needed to grade; no owner-only QA, provider rankings or unrelated learner records |
| Admin | Minimum operational scope required for assigned duties; all privileged access attributable and audited |
| Owner / super-admin | Full authorised operational and QA access, with auditable role and data access |

Enforce these boundaries at the API, PostgreSQL/RLS and storage layers. UI hiding alone is not authorisation. Use short-lived, submission-scoped access to files. Keep AI drafts, answer keys, raw private QA and internal provider rankings out of learner/guardian responses and client bundles.

## 5. Privacy, external processing and minors

Azure OCR and Workers AI are external processors. Cloudflare R2 is an additional external backup location. Before any real learner content or personally identifiable information is sent to any of them, complete a documented review of current terms, data-processing agreements, subprocessors, exact processing/storage locations, retention/deletion controls, encryption, international transfers, lawful basis, privacy notices and any required parent/guardian consent. Assess the applicable law for each learner's jurisdiction; include a specific India review of the DPDP Act 2023, the DPDP Rules 2025 and their staged commencement where relevant. Obtain qualified privacy/legal review; this record is not legal advice and does not assert compliance.

Use synthetic/fictitious data only until those gates and the separate real-data pilot approval are satisfied. Do not use student content for model training, advertising or unrelated analytics. No targeted advertising or behavioural/attention tracking is permitted.

## 6. Cost and quota controls

- No automatic plan upgrades, paid overage or spend-cap changes.
- Supabase Pro, Azure OCR and any R2 backup usage require a fresh cost check and explicit provisioning/budget approval before activation.
- Hard-stop OCR calls at the approved monthly quota and rate limit. Preserve accepted PDFs for manual grading.
- Use Workers AI only within the approved free allocation unless separately approved; otherwise fall back to human-authored feedback.
- Track usage, failure and quota events without logging learner content. Alert before quota exhaustion.

## 7. Decision status and next gate

**Phase 0 is complete.** The decisions above close the Phase 0 architecture, timer, retention, provider, upload-limit and access-control choices. They do not close implementation, legal/privacy, quality or release gates.

**Next phase: Phase 1 — Secure application foundation.** It comprises Supabase Auth, role assignment, server-side API, PostgreSQL schema/RLS, private storage and short-lived access, audit events, encrypted backup design, restore/deletion tests and synthetic-data security testing. Phase 1 must not begin until the Founder separately authorises implementation and any required account/plan costs. Real learner data, external OCR/AI and the limited live pilot each require their own explicit approval after the relevant privacy and quality gates.

## 8. Official references checked 2 November 2026

- Supabase regions: https://supabase.com/docs/guides/platform/regions
- Supabase pricing and limits: https://supabase.com/pricing
- Supabase backups and Storage API exclusion: https://supabase.com/docs/guides/platform/backups
- Azure Document Intelligence Read model and input limits: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/concept-read
- Azure Document Intelligence F0 quota and pricing: https://azure.microsoft.com/en-us/pricing/details/document-intelligence/
- Azure Document Intelligence v4 encryption, 24-hour analysis-result availability and delete API: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/authentication/encrypt-data-at-rest?view=doc-intel-4.0.0
- Azure region list: https://learn.microsoft.com/en-us/azure/reliability/regions-list?tabs=all
- Cloudflare Workers AI data use: https://developers.cloudflare.com/workers-ai/platform/data-usage/
- Cloudflare R2 data location and best-effort location hints: https://developers.cloudflare.com/r2/reference/data-location/
- India's DPDP Act, 2023: https://www.meity.gov.in/static/uploads/2024/02/Digital-Personal-Data-Protection-Act-2023.pdf
- India's DPDP Rules, 2025 and enforcement timeline: https://www.meity.gov.in/documents/act-and-policies/digital-personal-data-protection-rules-2025-gDOxUjMtQWa

**Approval boundary:** The Founder approved these Phase 0 decisions on 2 November 2026. No account, paid plan, database, storage bucket, Azure resource, AI endpoint, code implementation, merge, production deployment, DNS or Cloudflare configuration change is authorised by this decision record alone.