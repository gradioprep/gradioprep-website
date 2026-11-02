# Flagship PDF Response, Teacher Grading and Timed Analytics — Implementation Plan

**Version:** 0.1-draft  
**Date:** 2 November 2026  
**Status:** Phased plan approved by the Founder on 2 November 2026. The 24-hour grading target and priority bands are approved. This is a planning/specification record only: no code, database, authentication, storage bucket, external OCR account, AI endpoint, DNS, Cloudflare configuration or deployment has been changed.  
**Applies to:** Shared written-response and human-grading experience for Grades 6–12 across approved curricula.  
**Owner / academic authority:** Founder / project owner.

## 1. Approved product decisions

1. For a written-response task whose approved expected response is **more than 20 words**, the learner may either type the answer or upload it as a PDF. PDF is optional; typing remains available. Task metadata must explicitly enable this alternative. Existing response-length guidance and live word counter remain in force for typed answers.
2. Uploaded student work is accepted as PDF only. JPG, JPEG, PNG and other image files are not accepted as learner uploads. The system may temporarily render PDF pages as image data internally for OCR; these are processing artefacts only and are not accepted uploads or retained alternative submission formats.
3. Retain the original PDF as the authoritative submission. Extracted text is an aid for the teacher/grader and must be shown beside the original PDF, with page alignment, extraction status and confidence/low-confidence indicators.
4. Teacher/grader queue order is chronological: earliest accepted submission first. Priority is shown independently and must not silently reorder the queue.
5. Each queue entry shows its question/prompt and task metadata above the grading workspace: curriculum, programme/course, grade/year/stage, subject, task/part ID, submission reference, submitted time, elapsed time, deadline, remaining time, assigned grader and current status. The task's exact rubric is expandable and read-only during grading, except through the separately authorised rubric versioning process.
6. AI may produce exactly ten task-specific feedback suggestions using the submitted response and approved rubric. AI suggestions are drafts only. The teacher/grader selects, edits and/or supplements them with custom feedback; only the human-submitted feedback is published.
7. Published feedback appears under the corresponding task in the learner's dashboard as an expandable section. A grader may edit published feedback; after the save succeeds, the latest version becomes visible to the learner without waiting for a new release. Keep prior versions and the editor/time/reason in an audit history.
8. Every accepted human-grading submission has a **24-hour elapsed-time grading target**, measured from the server-recorded acceptance/submission timestamp to the time final feedback is published. Display times in the user's timezone while retaining UTC timestamps internally.
9. Approved grading priority bands, based on time remaining until the 24-hour target:
   - **Priority 1 — Urgent:** more than 0 and up to 10 hours remaining.
   - **Priority 2 — Approaching:** more than 10 and up to 20 hours remaining.
   - **Priority 3 — Normal:** more than 20 hours remaining.
   - **Overdue:** the deadline has passed. Display separately; do not hide overdue submissions.
10. On successful grading, show both the actual turnaround and the time remaining before the 24-hour deadline (or the amount overdue). Show this immediately before the published feedback on both the teacher/grader and learner views.
11. A student task countdown is required and its time data will feed analytics alongside task accuracy and rubric results. The detailed pause/resume, expiry and accommodation rules remain a separate policy decision.

## 2. Task configuration and response selection

Each authored written task must specify:
- the expected minimum/ideal word target and approved response range under the Teacher-Pack standard;
- whether PDF is enabled (enabled by default when the expected response target is greater than 20 words, unless the task is explicitly unsuitable for PDF);
- accepted response mode: typed only or typed plus PDF;
- whether the task is timed, the approved time allowance, and whether the learner can pause;
- the exact rubric version and criteria used for human grading;
- the skill/subskill and curriculum/course/level metadata needed for analytics.

The PDF option is a second response route, not a compulsory route and not a way to bypass the task's instructions, response range, deadline or academic criteria. Do not infer PDF eligibility solely from the number of words a learner has already typed; use the approved task configuration.

## 3. PDF submission and extraction workflow

### 3.1 Upload and validation

- Accept application/pdf only. Check file signature/magic bytes as well as extension and MIME type; do not trust browser-supplied content type.
- Reject corrupt, password-locked, empty or unsupported PDFs with a clear learner-facing explanation and preserve any existing typed draft.
- Establish a safe pilot file-size/page-count cap before implementation. Do not silently adopt an unlimited PDF size or page count.
- Use a random, non-identifying object key. Never use a learner's name or email in the object path.
- Upload to a private storage bucket. Generate short-lived, submission-scoped access for authorised student/assigned grader/owner only. Do not publish public bucket URLs or expose permanent storage credentials.
- Record upload start, completion and accepted submission separately. The 24-hour grading clock starts only at the server-confirmed accepted submission timestamp, not when an upload begins or OCR finishes.

### 3.2 Digital-text PDFs

Use Mozilla PDF.js in the application to render the original PDF and read its existing text layer. This is an in-house/open-source first route; it avoids an external OCR call for digitally generated PDFs. PDF.js provides page rendering and text extraction APIs; pin and review a stable release before implementation.

### 3.3 Scanned PDFs and handwriting

For scanned pages without a useful text layer, render each PDF page internally and send only the page raster needed for OCR to the approved OCR processor. The page raster is temporary processing data and must not be accepted or stored as a separate learner upload. Preserve page number/order and any returned word/line positions and confidence data.

**Preferred pilot OCR candidate:** Microsoft Azure AI Document Intelligence Read (prebuilt-read), subject to a handwriting-quality pilot, regional availability, security/privacy review and explicit provider approval. Its current documentation describes printed and handwritten text extraction, page/word positions and language support including English. The F0 tier is limited: only the first two pages of a PDF are processed per request, the request/document limit is 4 MB, and the free analysis quota is 500 pages per month with a 1 request/second F0 limit. If used, design a one-page-at-a-time processing path for PDFs beyond two pages, with each temporary page image under the applicable 4 MB input limit; the overall free quota still remains 500 pages/month. Do not represent this as unlimited free OCR. Confirm the exact endpoint, page accounting, supported input and region in a live test before selecting it.

Tesseract.js is not the default for handwriting: its project FAQ states that its models are built for printed text and generally perform poorly on handwriting. It may be evaluated for printed text only, but it must not silently replace handwriting-capable OCR.

### 3.4 Extraction quality and teacher comparison

For every page, record digital_text, ocr_complete, low_confidence, no_text_detected, failed or equivalent explicit state. Store raw extraction output separately from any teacher-corrected transcript. Show:
- original PDF page and extracted text for the same page side by side;
- page index/navigation and total pages;
- extraction method and status;
- low-confidence words/lines and missing/blank-page warnings where returned;
- a clear indication that OCR may omit or misread handwriting.

The original PDF remains authoritative. A teacher may correct the transcript for grading convenience, but the original OCR output and correction history remain preserved. Low-confidence or failed extraction must not block the learner's accepted submission or prevent the teacher from grading directly from the PDF.

## 4. Teacher/grader queue and grading workspace

The queue is ordered by accepted_at ascending (oldest first). Each submission card displays:
- student identity/reference appropriate to the teacher's permission;
- curriculum, programme/course, grade/year/stage, subject, pathway/unit and task ID;
- full task question/prompt and response instructions above the workspace;
- accepted submission time, time elapsed, due time, time remaining and priority;
- assigned grader and queue/grading state;
- expandable task-specific rubric and response-length guidance.

For a PDF response, the grading workspace uses a responsive split screen: original PDF viewer on one side and page-aligned extracted text on the other. On narrow screens, show the same content in accessible tabs/stacked panels without losing page synchronisation. For a typed response, show the learner's exact accepted text in the response panel; do not display an empty PDF viewer.

The rubric must be available without navigating away from the submission. Grader permissions are assignment-scoped. A grader must not gain access to another grader's unassigned submissions or owner-only QA/administration records.

## 5. AI suggestions, human feedback and versioning

- Generate ten suggestions only on a teacher action or first grading open, not on every page refresh.
- Ground suggestions in the exact prompt, task rubric and submitted response. Do not invent text that is not present in the student's answer or infer a skill diagnosis beyond the available evidence.
- Label suggestions as AI drafts. The teacher can select, edit, discard or combine them and can add unlimited custom text within defined safe limits.
- Never publish AI output automatically. A human must submit the final feedback.
- After a successful submit/edit, update the learner dashboard from the committed latest version and show a saved confirmation. Do not claim success before the save is confirmed.
- Store the feedback version, author, timestamp, selected AI suggestion references, final teacher text, rubric version and edit reason in the protected audit trail. The learner sees only the current published feedback and the approved turnaround information, not internal drafts or private grader notes.

**Initial AI candidate:** Cloudflare Workers AI, on-demand and quota-aware, with response caching and a non-AI fallback. Current Cloudflare documentation states a free allocation of 10,000 Neurons/day; above that, the Free plan does not continue processing, while the Paid plan charges for overage. Do not call a paid service or enable automatic overage without explicit approval.

## 6. Grading deadline and priority calculations

- accepted_at is a trusted server UTC timestamp.
- grading_due_at = accepted_at + 24 hours.
- remaining = grading_due_at - current_server_time.
- Queue display sort: accepted_at ASC; do not sort by priority.
- Priority 3 applies while remaining is greater than 20 hours; Priority 2 applies after 20 hours and until more than 10 hours remain; Priority 1 applies from 10 hours remaining through the deadline; Overdue applies after the deadline.
- On published_at, calculate actual turnaround (published_at - accepted_at) and remaining time (grading_due_at - published_at). If positive, show the actual time remaining when feedback was published; if negative, show how late it was. Preserve exact timestamps for audit.
- If a teacher edits feedback after publication, do not reset the original grading SLA. Show the original first-published turnaround and record the latest edit separately.
- Do not pause the SLA clock for weekends, holidays, OCR delays or queue inactivity unless the Founder later approves a different service calendar.

## 7. Student countdown and timed analytics

Each timed task has a task-specific allowance configured by the academic author. The interface must show a clear countdown, elapsed time and accessible warning states. Timer events must be recorded using server-validated timestamps; do not rely solely on a browser interval or an untrusted client duration.

The analytics should link:
- objective-task accuracy to actual task and skill IDs;
- human-graded written response results to the exact rubric version and criterion outcomes;
- task completion duration and (where approved) active/pause duration;
- task mode: typed or PDF;
- timer mode and whether an attempt was timed/untimed or received an accommodation;
- comparable attempts only, with time allowance and task context.

Speed must not be treated as inherently better. Report accuracy and duration together; compare only sufficiently similar tasks/skills and do not infer ability, mastery or a learner rank from speed alone. Exclude upload/OCR processing time from the learner's writing duration.

**Still awaiting Founder policy decision:** whether the countdown is advisory or hard-stop; whether time continues when the browser is in the background; whether pause/resume is permitted; how accommodations or connectivity interruptions affect the clock; and whether any timed task may auto-submit at zero. The safe proposed default is advisory warnings, preserve the response at zero, and do not auto-submit or delete work. This is a recommendation, not an approved rule.

## 8. Security, privacy and retention

- Add authenticated student, grader, admin and owner roles. Enforce permissions at the server and database/storage layer, not only in React UI.
- Students can access only their own PDFs, extracted text and published feedback. Graders can access only assigned submissions. Owner-only QA and ranking data remain inaccessible to graders/students/guardians.
- Store PDFs in private object storage; keep API secrets server-side; use short-lived signed access; validate content and protect the PDF viewer against untrusted document behaviour.
- Use synthetic records for development and hosted previews. No real student submissions, handwriting or personally identifiable data may be uploaded to a public preview.
- Before sending any PDF page or answer to an external OCR/AI provider, review provider terms, processing region, retention, subprocessors, security, data-use policy and the required student/parent privacy notice/consent. Minimise submitted fields; do not send student name/email unless strictly necessary.
- Define retention/deletion/anonymisation for original PDFs, raw OCR output, corrected transcripts, feedback versions and timing events before accepting real student records.

**Still awaiting Founder policy decision:** retention period for submissions and audit history, deletion/anonymisation rules, OCR provider/region and whether an external service may process real student writing. No real-student OCR processing is approved by approval of this plan alone.

## 9. Architecture and cost approach

The current frontend is deployed using Cloudflare Workers, but the existing docs/DATA_MODEL.md already records Supabase as the proposed Auth/database direction, subject to vendor and plan review. Preserve that proposal as the baseline for evaluation; do not silently replace it with Cloudflare D1 or introduce a second database. Compare a consolidated Supabase Auth/Postgres/Storage pilot against Cloudflare storage options using the same security, backup, residency, retention and cost criteria.

Current published free-tier references checked on 2 November 2026 (verify again before actual provider selection):
- **Supabase Free:** 500 MB database, 1 GB file storage, 50 MB max upload, 50,000 monthly active users and 5 GB cached + 5 GB uncached egress; free projects pause after one week of inactivity and automatic backups are not included. Suitable for a limited pilot only if storage and recovery controls are acceptable.
- **Cloudflare R2 Free:** 10 GB-month storage, 1 million Class A and 10 million Class B operations per month, free egress. Could be a PDF object-storage alternative, but adding it beside Supabase increases integration and access-control complexity.
- **Cloudflare Workers Free:** 100,000 requests/day and 10 ms CPU per HTTP invocation. Use for lightweight APIs/orchestration only, not in-Worker OCR or CPU-heavy PDF processing.
- **Cloudflare Workers AI:** 10,000 Neurons/day free allocation. Respect quota failures and do not enable paid overage automatically.
- **Azure AI Document Intelligence Read F0:** current free quota 500 pages/month; 4 MB input/document limit; first two PDF pages per analysis request; 1 analysis request/second. Page-by-page image processing is a possible workaround for the two-page-per-request ceiling, not the monthly quota.
- **Mozilla PDF.js:** open-source in-app PDF rendering and digital text extraction; prefer before external OCR.

The project should remain within free tiers for the initial fictional/synthetic pilot where feasible. Add usage dashboards/alerts and hard safeguards before using quotas. Never assume a free tier provides backups, an SLA, unlimited usage or production-grade recovery.

## 10. Phased roadmap — approved 2 November 2026

| Phase | Scope | Completion gate |
|---|---|---|
| 0. Specification and architecture decision | Finalise data flow, provider comparison, security/privacy review, role matrix, file limits, timer policy and retention policy. Keep the schema provider-independent. | Founder approves the technical decision record and unresolved policies. |
| 1. Secure application foundation | Implement approved authentication, student/grader/admin roles, protected API, database records, private object storage, assignment permissions and audit events. | Role-isolation, private-file access, backup/restore and deletion tests pass. |
| 2. PDF submission and extraction | Implement PDF-only validation/upload, digital-text extraction, scanned-page OCR, page mapping, confidence/error states and original-vs-extracted teacher split-screen. | Synthetic PDF test set (digital, scanned, handwriting, rotated, faint, skewed, mixed blank pages, corrupt/password PDF) passes agreed quality and accessibility thresholds. |
| 3. Teacher queue and grading | Implement chronological queue, 24-hour grading clock, approved priority bands, task/question metadata, expandable rubric, assigned grader workspace and status. | Due-time boundaries, oldest-first ordering, role permissions and overdue cases pass tests. |
| 4. Feedback and learner dashboard | Add ten cached/on-demand AI drafts, human editing/custom comments, submit/edit, version audit and expandable learner feedback. | No AI auto-publication; edits become visible only after save confirmation; audit history works. |
| 5. Countdown and analytics | Add task-specific countdown, elapsed-time events, timer policy, accuracy/score linkage and comparable accuracy-speed analytics. | Timer boundaries, pause/accommodation decisions, duration validity and analytics labels are human-validated. |
| 6. MYP Year 4 controlled pilot | Test the full student → submission → OCR → grader → feedback → learner journey using synthetic data first and a separately approved limited pilot later. | Founder approval of exact flow, OCR quality, accessibility, privacy, workload and cost. |
| 7. Grades 6–12 rollout | Reuse shared components and task metadata across approved curricula/grades, adapting rubrics and timing per task. | Each curriculum/grade receives its own content/assessment validation; no generic rubric or timing assumption is copied across tracks. |

The approved 24-hour grading target applies to the shared human-grading workflow. It is not an assessment time allowance and is separate from the student's task countdown.

## 11. Immediate work order and gates

1. The MYP Year 4 taxonomy, high-level blueprint and detailed task-level item map/scoring specification are Founder-approved. The map approval is recorded separately from this new feature.
2. This flagship feature's phased plan and 24-hour grading target are approved. The feature is the next platform prerequisite before actual MYP diagnostic item authoring and before the later report/analytics experience is built around submitted responses.
3. Complete Phase 0 provider comparison, technical architecture and privacy/retention/timer decision record. Do not create accounts, enable paid services, create buckets/databases, deploy or change DNS as part of this documentation approval.
4. Actual coding/infrastructure execution requires the relevant Phase 0 decision and explicit implementation authorisation. Existing curriculum queues remain deferred; Cambridge Grade 6 research remains blocked until Cycle 1 is complete and the Founder directs the transition.

## 12. Official technical references checked 2 November 2026

- Supabase pricing and limits: https://supabase.com/pricing
- Supabase upload limits: https://supabase.com/docs/guides/storage/uploads/file-limits
- Supabase backup and inactivity cautions: https://supabase.com/kb/faqs/platform/database-only-cost
- Cloudflare Workers limits: https://developers.cloudflare.com/workers/platform/limits/
- Cloudflare R2 pricing: https://developers.cloudflare.com/r2/pricing/
- Cloudflare R2 presigned URLs: https://developers.cloudflare.com/r2/api/s3/presigned-urls/
- Cloudflare Workers AI pricing: https://developers.cloudflare.com/workers-ai/platform/pricing/
- Azure Document Intelligence Read OCR model and limits: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/prebuilt/read?view=doc-intel-4.0.0
- Azure Document Intelligence handwriting language support: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/language-support/ocr?view=doc-intel-4.0.0
- Azure Document Intelligence pricing: https://azure.microsoft.com/en-us/pricing/details/document-intelligence/
- Tesseract.js handwriting FAQ: https://github.com/naptha/tesseract.js/blob/master/docs/faq.md
- Mozilla PDF.js getting started/API: https://mozilla.github.io/pdf.js/getting_started/ and https://mozilla.github.io/pdf.js/api/index.html
