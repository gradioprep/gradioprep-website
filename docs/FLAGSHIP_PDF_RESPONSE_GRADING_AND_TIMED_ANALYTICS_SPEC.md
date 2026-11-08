# Flagship PDF Response, Teacher Grading and Timed Analytics — Implementation Plan

**Version:** 1.4
**Date:** 6 November 2026  
**Status:** The flagship typed/PDF response, human-grading, feedback-publication and timer/analytics plan remains approved but is not implemented as a complete learner/staff workflow. Phase 1F synthetic security evidence was accepted by the Founder on 8 November 2026. The backend task-level PDF eligibility/response_mode slice passed exact-head CI at b6dc72f3534b873b63536f5a994fe5027ddcc162 / [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739). The learner-facing typed-response and optional-PDF selector/upload journey has since been added at 4f4be588880fd51abe628544a5af84102b5e59ca, but exact-head CI [#42490565745](https://github.com/gradioprep/gradioprep-website/actions/runs/42490565745) is not green: PostgreSQL RLS and builds passed, while Playwright finished 32/33 because the typed-only task test received HTTP 404 assessment_task_not_available instead of expected HTTP 201. Backup/restore was skipped. The UI increment is therefore not yet accepted. PDF.js extraction, scanned-page OCR, complete teacher/grader workspace, feedback publication and timer/analytics remain future work. PR #22 remains open, draft and unmerged; hosted resources, real learner data, external processing, costs, DNS, merge and production deployment require separate approval.



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
11. A student task countdown is required and feeds accuracy/rubric-linked analytics under the approved advisory timer policy in the Phase 0 decision register. No learner pause/resume, hard stop, auto-submit or response deletion is permitted.
12. All accepted human-grading submissions, including the one-time complimentary human-grading task whose calculated requirement is one credit, use one 24-hour elapsed-time target from server acceptance to first publication of human feedback. This supersedes the older differentiated free/paid/urgent SLA proposal; no urgent surcharge is part of the initial commercial model.
13. Each eligible task has a server-calculated credit requirement before acceptance under the current universal word/time tariff: fixed accepted-word bands through 350 words, then one additional credit per complete or partial 100-word band; time credits are one per 20 predicted grader minutes; final requirement is the maximum of word- and time-based credits, never their sum. The same tariff applies to IB, Cambridge and CBSE. The approved package prices are in the Grading Credit and Remedial Access Policy; no Standard/Premium/Elite price tier or ₹399-per-credit hypothesis remains current.

## 2. Task configuration and response selection

Each authored written task must specify:
- the expected minimum/ideal word target and approved response range under the Teacher-Pack standard;
- whether PDF is enabled (enabled by default when the expected response target is greater than 20 words, unless the task is explicitly unsuitable for PDF);
- accepted response mode: typed only or typed plus PDF;
- whether the task is timed, its task-specific approved time allowance and timer-policy version; learner pause/resume is disabled in the first release under the approved Phase 0 policy;
- the exact rubric version and criteria used for human grading;
- the skill/subskill and curriculum/course/level metadata needed for analytics;
- expected grader minutes, task complexity/parts, predicted grader minutes, word-based credits, time-based credits, final required credits and credit-policy version, all approved and calculated server-side before submission acceptance.

The PDF option is a second response route, not a compulsory route and not a way to bypass the task's instructions, response range, deadline or academic criteria. Do not infer PDF eligibility solely from the number of words a learner has already typed; use the approved task configuration. The typed ideal-word counter is guidance, not a cap. Expected words inform effort but do not trigger a post-submission debit. The PDF 10 MB/10-page cap is a file safeguard, not a price unit. Do not charge more solely for PDF mode, page count within the cap, OCR use or actual words above the ideal target. Set and show credits before acceptance; additional independent tasks require explicit pre-acceptance confirmation.

## 3. PDF submission and extraction workflow

### 3.1 Upload and validation

- Accept application/pdf only. Check file signature/magic bytes as well as extension and MIME type; do not trust browser-supplied content type.
- Reject corrupt, password-locked, empty or unsupported PDFs with a clear learner-facing explanation and preserve any existing typed draft.
- Enforce the approved pilot cap of 10 MB and 10 pages per PDF. Validate page count and file size before acceptance; never silently expand either limit.
- Use a random, non-identifying object key. Never use a learner's name or email in the object path.
- Upload to a private storage bucket. Generate short-lived, submission-scoped access for authorised student/assigned grader/owner only. Do not publish public bucket URLs or expose permanent storage credentials.
- Record upload start, completion and accepted submission separately. The 24-hour grading clock starts only at the server-confirmed accepted submission timestamp, not when an upload begins or OCR finishes.

### 3.2 Digital-text PDFs

Use Mozilla PDF.js in the application to render the original PDF and read its existing text layer. This is an in-house/open-source first route; it avoids an external OCR call for digitally generated PDFs. PDF.js provides page rendering and text extraction APIs; pin and review a stable release before implementation.

### 3.3 Scanned PDFs and handwriting

For scanned pages without a useful text layer, render each PDF page internally and send only the page raster needed for OCR to the approved OCR processor. The page raster is temporary processing data and must not be accepted or stored as a separate learner upload. Preserve page number/order and any returned word/line positions and confidence data.

**Selected pilot OCR integration:** Microsoft Azure AI Document Intelligence Read (`prebuilt-read`, v4 API), with Central India (`centralindia`) as the intended resource region. Confirm service availability for the exact resource at provisioning; do not silently fail over to another region. This is external processing, not in-house OCR. Complete the synthetic handwriting/print quality benchmark and privacy/terms/region review before any real learner content is sent. The F0 route is limited to the first two PDF pages per request, 4 MB input, 1 request/second and 500 pages/month. Process one internally rendered page image per request, each below 4 MB, and enforce the monthly quota. Quota exhaustion or OCR failure must never reject or destroy an accepted original PDF; the teacher grades from the original.

Tesseract.js is not the default for handwriting: its project FAQ states that its models are built for printed text and generally perform poorly on handwriting. It may be evaluated for printed text only, but it must not silently replace handwriting-capable OCR.

### 3.4 Extraction quality and teacher comparison

For every page, record digital_text, ocr_complete, low_confidence, no_text_detected, failed or equivalent explicit state. Store raw extraction output separately from any teacher-corrected transcript. Show:
- original PDF page and extracted text for the same page side by side;
- page index/navigation and total pages;
- extraction method and status;
- low-confidence words/lines and missing/blank-page warnings where returned;
- a clear indication that OCR may omit or misread handwriting.

The original PDF remains authoritative. A teacher may correct the transcript for grading convenience, but the original OCR output and correction history remain preserved. Low-confidence or failed extraction must not block the learner's accepted submission or prevent the teacher from grading directly from the PDF.

### 3.5 Credit and pricing safeguards for PDF submissions

The original PDF remains authoritative, but the PDF route does not create a separate per-page tariff. Do not multiply credits by PDF pages or file size. Use the approved task/rubric scope and predicted grader minutes to calculate required credits before acceptance. Digital extraction and scanned-page OCR are processing methods, not learner-billable tier changes. If the request is for an additional independent assessment or a broader paper than the selected task, disclose the revised scope and price and obtain learner confirmation before acceptance. Never apply a surprise post-submission debit.

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

**Selected AI provider:** Cloudflare Workers AI for on-demand generation of exactly ten teacher-only draft suggestions, after synthetic evaluation/model selection. Use standard stateless inference only; do not enable AI Gateway logging/caching, batch/file uploads or other stateful content-retaining features, and do not write prompts/outputs to application logs. Its currently documented free allocation is 10,000 Neurons/day. Do not enable paid overage; when quota is exhausted or the service is unavailable, use manual teacher feedback. External-processing privacy/terms/consent gates apply before real learner content is sent.

## 6. Grading deadline and priority calculations

- accepted_at is a trusted server UTC timestamp.
- grading_due_at = accepted_at + 24 hours. This is the sole launch target for all accepted human-grading submissions, including the one-time complimentary task whose requirement is one credit; it supersedes the older proposed 72-hour free / 48-hour paid Standard / separate urgent 24-hour SLA tiers.
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
- server-recorded elapsed response duration, approved allowance and any authorised/audited adjustment; no active-attention or learner pause-duration metric;
- task mode: typed or PDF;
- timer mode and whether an attempt was timed/untimed or received an accommodation;
- comparable attempts only, with time allowance and task context.

Speed must not be treated as inherently better. Report accuracy and duration together; compare only sufficiently similar tasks/skills and do not infer ability, mastery or a learner rank from speed alone. Exclude upload/OCR processing time from the learner's writing duration.

**Approved Phase 0 timer policy:** countdown is advisory, not a hard stop. The server starts and owns the clock; it continues through refresh, disconnection and hidden/background tabs. The first release has no learner pause/resume. At zero, preserve the saved response and never auto-submit, truncate, delete, lock or block saving/submission solely due to expiry. An authorised teacher/admin may grant a logged extension or untimed accommodation; record only the setting/reason category, authoriser and timestamp, never a diagnosis. A verified platform outage may receive an audited allowance adjustment or untimed attempt. Record only minimal start/save/submit/expiry/adjustment events—no keystrokes, screenshots, focus or browsing surveillance. Label the metric “elapsed response time”, not active attention; compare only comparable tasks/skills/rubrics/allowances and interpret alongside accuracy and human rubric evidence. Speed alone must not imply ability/mastery/rank. Upload/OCR duration is excluded.

## 8. Security, privacy and retention

- Add authenticated student, grader, admin and owner roles. Enforce permissions at the server and database/storage layer, not only in React UI.
- Students can access only their own PDFs, extracted text and published feedback. Graders can access only assigned submissions. Owner-only QA and ranking data remain inaccessible to graders/students/guardians.
- Store PDFs in private object storage; keep API secrets server-side; use short-lived signed access; validate content and protect the PDF viewer against untrusted document behaviour.
- Use synthetic records for development and hosted previews. No real student submissions, handwriting or personally identifiable data may be uploaded to a public preview.
- Before sending any PDF page or answer to an external OCR/AI provider, review provider terms, processing region, retention, subprocessors, security, data-use policy and the required student/parent privacy notice/consent. Minimise submitted fields; do not send student name/email unless strictly necessary.
- Apply and test the approved retention/deletion/anonymisation schedule in `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md` before accepting real student records.

**Approved Phase 0 retention policy:** source PDFs, raw extraction and corrected transcripts remain while the learner is enrolled/active, then for 12 months after formal course completion, recorded withdrawal or administrative course closure (whichever ends the learner's course participation). Published feedback, rubric outcomes and version/edit audit history remain for 24 months after that formal end event; event-level timer records remain for 12 months after the attempt. Delete internally rendered page images immediately after OCR processing. After retrieving an Azure result, call its Delete Analyze Result API promptly rather than relying on the 24-hour service retrieval window. Verified deletion requests are actioned within 30 days, subject to a documented legal hold. Encrypted off-site object backups expire within 30 days of source deletion. An open/inactive course does not start the post-course clock; flag prolonged inactivity for an authorised owner closure review rather than silently retaining it indefinitely or auto-deleting it. See the Phase 0 decision register for the data-class matrix and deletion controls.

## 9. Architecture and cost approach

**Approved Phase 0 architecture:** keep Cloudflare Workers as the current application host and lightweight API/orchestration layer. Use a single Supabase project for Auth, PostgreSQL and primary private Storage in the specific Mumbai region (`ap-south-1`); do not use Cloudflare D1 or add another application database. Use Supabase Free first if measured availability, capacity and tested backup/restore controls meet requirements; Pro is an optional paid fallback only if no suitable free arrangement can meet an essential requirement and a separate cost decision is approved. Supabase database backups do not include Storage objects, and Free projects may pause after inactivity; address these with tested recovery/availability controls before real learner records. Use encrypted Cloudflare R2 only as a secondary off-site PDF-object backup target; its Free quota is limited and its APAC location hint is not an India-residency guarantee. No real learner content may be replicated there until transfer/residency/privacy and key-management controls pass. Use PDF.js for digital text; Azure Document Intelligence Read (`prebuilt-read`, intended Central India region) is the selected scanned-page OCR integration, subject to live resource/region validation and synthetic quality/privacy gates. Use Azure F0 free quota where fit; S0 is metered and needs an exact quote and explicit cost approval. Cloudflare Workers AI is the selected on-demand teacher-draft service; use only its daily free allocation unless a specific paid exception is approved; use manual feedback when quota is exhausted. Use stateless standard inference without logging/caching/stateful features. Do not process real learner text with external services until the privacy, legal, contract, region and consent gates are passed. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md` and the complete provider decisions in `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`.

Current published free-tier references checked on 3 November 2026; the binding budget policy and service-level cost table are in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`. Recheck current pricing, terms, quota and exact regional availability before provisioning or enabling each selected provider:
- **Supabase Free:** 500 MB database, 1 GB file storage, 50 MB max upload, 50,000 monthly active users and 5 GB cached + 5 GB uncached egress; free projects may pause after seven days of low activity and do not include automatic downloadable DB backups. Supabase CLI logical exports can be used, but do not include Storage API file objects. Real-data use depends on a tested full recovery and availability design; Free is not automatically accepted or rejected.
- **Cloudflare R2 Free:** 10 GB-month storage, 1 million Class A and 10 million Class B operations per month, free egress. Could be a PDF object-storage alternative, but adding it beside Supabase increases integration and access-control complexity.
- **Cloudflare Workers Free:** 100,000 requests/day and 10 ms CPU per HTTP invocation. Use for lightweight APIs/orchestration only, not in-Worker OCR or CPU-heavy PDF processing.
- **Cloudflare Workers AI:** 10,000 Neurons/day free allocation. Respect quota failures and do not enable paid overage automatically.
- **Azure AI Document Intelligence Read F0:** current free quota 500 pages/month; 4 MB input/document limit; first two PDF pages per analysis request; 1 analysis request/second. Page-by-page image processing is a possible workaround for the two-page-per-request ceiling, not the monthly quota.
- **Mozilla PDF.js:** open-source in-app PDF rendering and digital text extraction; prefer before external OCR.

The project should follow the free-first budget objective: US$0 recurring infrastructure subscriptions and paid API usage for 3 November 2026–2 November 2027, with a review at 100+ subscribers, not an automatic upgrade. Add usage dashboards/alerts and hard safeguards before using quotas. Never assume a free tier provides backups, an SLA, unlimited usage or production-grade recovery. A free-tier gap must be controlled or it keeps real-data use blocked; it does not automatically authorise payment.

## 10. Phased roadmap — approved 2 November 2026

| Phase | Scope | Completion gate |
|---|---|---|
| 0. Specification and architecture decision | **Complete:** Founder-approved architecture, region/provider choices, role matrix, 10 MB/10-page file cap, advisory timer rules, retention/deletion matrix and external-processing gates are recorded in `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`. | Phase 0 decision register is approved; no resources or services are provisioned. |
| 1. Secure application foundation | Approved implementation sequence underway: Phase 1B and Phase 1C-A/B/C/D verified with local synthetic data; complete 1C-E audit/workflow integrity and 1C-F adversarial acceptance before Phase 1D private file/storage, backup/recovery and security acceptance. | Full Phase 1C exit matrix and cross-role/security tests pass; Phase 1D/1E/1F gates pass before OCR/AI or real-data work. |
| 2. PDF submission and extraction | Implement PDF-only validation/upload, digital-text extraction, scanned-page OCR, page mapping, confidence/error states and original-vs-extracted teacher split-screen. | Synthetic PDF test set (digital, scanned, handwriting, rotated, faint, skewed, mixed blank pages, corrupt/password PDF) passes agreed quality and accessibility thresholds. |
| 3. Teacher queue and grading | Implement chronological queue, 24-hour grading clock, approved priority bands, task/question metadata, expandable rubric, assigned grader workspace and status. | Due-time boundaries, oldest-first ordering, role permissions and overdue cases pass tests. |
| 4. Feedback and learner dashboard | Add ten on-demand teacher-only AI drafts, human editing/custom comments, submit/edit, version audit and expandable learner feedback. | No AI auto-publication; no prompt/output content logging or stateful AI retention; edits become visible only after save confirmation; audit history works. |
| 5. Countdown and analytics | Add task-specific countdown, elapsed-time events, approved timer policy, accuracy/score linkage and comparable accuracy-speed analytics. | Timer boundaries, authorised adjustment/accommodation behaviour, duration validity and analytics labels are human-validated against the approved Phase 0 policy. |
| 6. MYP Year 4 controlled pilot | Test the full student → submission → OCR → grader → feedback → learner journey using synthetic data first and a separately approved limited pilot later. | Founder approval of exact flow, OCR quality, accessibility, privacy, workload and cost. |
| 7. Grades 6–12 rollout | Reuse shared components and task metadata across approved curricula/grades, adapting rubrics and timing per task. | Each curriculum/grade receives its own content/assessment validation; no generic rubric or timing assumption is copied across tracks. |

The approved 24-hour grading target applies to the shared human-grading workflow. It is not an assessment time allowance and is separate from the student's task countdown.

## 11. Immediate work order and gates

1. The MYP Year 4 taxonomy, high-level blueprint and detailed task-level item map/scoring specification are Founder-approved.
2. This flagship feature's phased plan, 24-hour grading target and Phase 0 architecture/timer/retention/provider decisions are Founder-approved; Phase 0 is complete. See `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`.
3. **Completed secure foundation:** Phase 1C, 1D and 1E passed their synthetic technical gates; the Founder accepted Phase 1F technical security evidence for the documented synthetic scope on 8 November 2026. Operational and production controls remain separate deferred gates.
4. **Completed Phase 2 first backend slice:** task-level PDF opt-in, the greater-than-20-word database threshold, persisted `response_mode` and upload-start/finalisation enforcement are implemented and passed exact-head CI [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739) with 619 SQL assertions/17 files and 32/32 Playwright tests. This covers typed text plus an optional PDF attachment only.
5. **Next flagship implementation order:** build the learner-facing optional PDF selection/upload interaction using task metadata and the verified Worker route. Then implement PDF.js digital extraction, scanned-page OCR only after its separate privacy/provider approval, the teacher PDF/text review workspace, grading queue/search, feedback publication and timer/analytics. No external OCR/AI or hosted services are authorised by this handoff.
6. Continue the approved shared submission/grader/timer experience in synthetic-only increments, then build and pilot-validate the free Cycle 1 diagnostic and complete Evaluation Report. Complete the mandatory whole-website learner-facing copy cleanup before remedial authoring; then build the personalised remedial course, free starter activity and outcome check. Commercial entitlement/payment implementation is a later prerequisite to paid sales, not a blocker to the free diagnostic/report. Cambridge Grade 6 remains blocked until Cycle 1 is complete and the Founder directs the transition. Apply `docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md` and `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.

## 12. Official technical references checked 2 November 2026

The product pricing/credit policy does not alter the approved infrastructure provider choices or budget gates. See docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md for infrastructure spend and docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md for customer pricing, credit packs, curriculum-frequency calculation, PDF safeguards and the future entitlement/payment roadmap.

## 13. Historical credit-tier and curriculum-frequency proposal — 4 November 2026 (superseded by current policy)

Each authored human-graded task must carry expected response range/ideal words, task parts, rubric criteria, predicted grader minutes, response mode, tier, required credits and credit-policy version. The server derives the requirement from approved metadata before acceptance using max(1, ceiling(predicted_grader_minutes / 20)). The approved default mapping is Standard 1 credit (up to 20 predicted minutes), Premium 2 (21–40), Elite 3 (41–60), and Custom 4+ (over 60 minutes or broader task). Word bands (up to 50, 51–150, 151–350) are indicative task defaults, not caps.

For each curriculum/grade/course, calculate independently gradable response-task frequency and marks share from representative assessment materials. Use frequency and tier credit weights to forecast expected credit mix; use marks as an academic cross-check, not as a substitute for grading effort. The CBSE ~50-word example must be verified for the selected grade/subject/exam series. Do not copy proportions across IB, Cambridge and CBSE.

Credit policy does not price PDF pages or OCR. The pilot PDF cap remains 10 MB/10 pages. PDF or scanned response grading uses the same task-tier rule and teacher effort estimate. The learner sees tier/credits/price before acceptance; actual word count beyond the ideal target does not create a retrospective debit. Refer to docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md for the complete algorithm, competitor research, packs and access sequence.


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


**Version 0.3 Phase 1 planning cross-reference — 2 November 2026:** The detailed Phase 1 secure application foundation plan is now recorded separately. It is a documentation-only planning result and does not authorise implementation, provisioning, paid plans, real learner data, external OCR/AI/backup processing, merge or deployment. The later PDF/OCR/grading/timer phases remain dependent on passing Phase 1 security, private-file access, audit, backup/restore and deletion tests. Preserve all Phase 0 provider, file-limit, timer, SLA, role and retention decisions.


**Version 0.4 Phase 1A engineering handoff — 2 November 2026:** The build-ready preparation for Phase 1 is in `docs/PHASE_1A_BUILD_READY_EXECUTION_PLAN.md`. The first coding slice is local synthetic-only Auth, protected Worker API, profiles/roles and RLS. It does not implement PDF submission, OCR, grading, AI suggestions, timer analytics or remote backups. The flagship feature phases remain downstream of the secure foundation and their separate privacy, regional, quality and cost gates. Actual MYP Year 4 diagnostic item authoring remains gated until the flagship feature is implemented and pilot-validated; Cambridge Grade 6 remains blocked.


**Version 0.5 historical Preview workflow — superseded by the Founder direction recorded 3 November 2026:** GitHub implementation and automated checks remain required for all slices. Request Founder Preview review only when a new, concrete and substantial learner/staff-visible feature is ready; do not repeatedly surface routine deployments, unchanged previews, internal backend/security work, fixes, tests or documentation changes. Preview only with synthetic data. Real OCR/AI or hosted database connectivity remains separately gated. The public Preview is not production, and custom-domain connection remains at Launch Candidate / Production Cutover after separate DNS/production approval. See `docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md`.

## 14. Historical secure-foundation checkpoint — superseded by Section 15

The flagship plan and 24-hour grading target remain approved; they do not imply that learner-facing PDF submission, OCR, teacher workspace, full analytics or diagnostic/report workflows are already built. PR #22 remains a draft, open and unmerged local-synthetic implementation.

**Verification:** code-bearing commit `f5097ba8bae0eee4c420e8e5081f90287f3149ee` passed exact-head run [#41984620018](https://github.com/gradioprep/gradioprep-website/actions/runs/41984620018): 534 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds, 27/27 Playwright tests, local cleanup and clean public-preview asset build. The documentation-only head `1f1195de965d40631879dc140dcca4b8a447cf54` passed [#41985668001](https://github.com/gradioprep/gradioprep-website/actions/runs/41985668001). No public Preview was deployed.

**Current blocker and next order:** Phase 1B and Phase 1C-A/B/C/D are verified at their recorded local-synthetic checkpoints. Phase 1C-E now includes audit-context enrichment, protected-read and privileged-write outcome groundwork, learner write outcomes, staff-invitation list/create/revoke handling, Owner private-QA read error handling and database-derived invitation-acceptance denial/state events. **Phase 1C-E remains partial:** the generic `audit_privileged_write_outcome` and `audit_protected_read_outcome` RPCs still let an authorised caller create a misleading `failed` audit event by calling the RPC directly without executing the underlying protected operation. The next code slice must bind failures to real operations, add direct-RPC abuse and genuine-failure tests, and add Worker route/integration tests for staff-invitation and private-QA outcomes. Phase 1C-F adversarial acceptance remains incomplete; Phase 1D remains blocked until all Phase 1C exit criteria pass. The immediate work is to prevent caller-forged generic failure events and add route-level integration coverage; only then complete the whole 1C-E matrix and 1C-F adversarial acceptance. Phase 1D remains blocked. All work is local-Supabase/synthetic-only. Branded staging on the purchased domain with a separate hosted synthetic backend remains a later mandatory pre-acceptance gate after explicit approvals.


## 15. Historical Worker-only audit-outcome hardening — 5 November 2026 (superseded by current status in Section 16)

**Verified implementation update — 5 November 2026:** PR #22 remains open, draft and unmerged. Code head `3c4b4a71718b795855a9dd41346c80d1a1f85c39`; exact-head GitHub Actions run [#41992302366](https://github.com/gradioprep/gradioprep-website/actions/runs/41992302366) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **27/27 Playwright tests**, local Supabase shutdown, local credential cleanup and clean public-preview asset build. The workflow was a branch push, so no public/Founder Preview was uploaded. Migration `20261105000900_phase1c_worker_only_audit_ingestion.sql` introduces `record_worker_audit_outcome`, callable only by `service_role`; the old browser-callable generic audit outcome RPCs are revoked. The Worker uses its server-only service-role client solely for audit ingestion, with verified actor identity and allowlisted actions, outcomes and safe reason categories; business reads/writes remain on the caller-scoped client. Audit writes fail closed if the Worker audit key is absent or the database does not acknowledge the event. The local service-role key is kept in ignored `.dev.vars` and is not copied to browser `.env.local`/Vite variables. Browser direct-RPC forgery tests, trusted-writer tests and the existing Playwright invitation/private-QA/account API journey pass. Phase 1C-E remains partial pending the complete endpoint-to-audit/authorization matrix and targeted failure-injection/correlation acceptance; Phase 1C-F remains open and Phase 1D remains blocked. No hosted resources, real learner data, paid usage, merge, deployment or DNS changes occurred.

The new service-role-only `record_worker_audit_outcome` function closes the browser-forgeable generic audit-writer path. The Worker keeps application reads/writes caller-scoped and uses a separate service-role Supabase client only for audit ingestion. The local service-role key is kept in ignored `.dev.vars`, not browser/Vite variables. Direct browser-RPC abuse, trusted audit-write semantics and the account/API route flows pass the exact-head tests. The route matrix still needs per-endpoint persisted audit correlation and explicit audit-service outage/failure injection before Phase 1C-E can be signed off.

The flagship learner-facing PDF workflow, OCR, teacher workspace, full analytics and Diagnostic/Evaluation Report remain approved plans, not implemented capabilities. Phase 1C-E remains partial; Phase 1C-F remains open; Phase 1D remains blocked. No Preview was deployed. The approved product scope, timing, access and grading policies are unchanged.

## 16. Submission queue search and management — approved addition, 6 November 2026

Extend the existing queue/workspace; do not add a separate service, search database or application.

Search permitted learner name/reference, exact or partial submission ID, task/assessment title and curriculum/task metadata. Do not make email, response text or private notes default search keys. Do not disclose out-of-scope record existence.

Composable filters: board/programme (IB, Cambridge, CBSE), grade/year/stage, subject, pathway/unit/task, accepted date/range, workflow state, assignment (assigned to me; Owner-authorised team states), response format (typed/PDF), PDF extraction/review state and SLA category (normal, approaching, urgent, overdue). Filters combine; show active filters and clear/reset actions.

Default order remains accepted_at ascending (oldest first), with stable unique tie-breaker. SLA priority is a separate indicator and never silently reorders. Overdue submissions remain visible.

Use existing PostgreSQL and same-origin Worker APIs. Validate/bound parameters; debounce browser input; filter/search server-side after authorization; use stable cursor/keyset pagination; return only actor-authorised fields. Add indexes based on measured query plans and synthetic load tests. Owner remains Owner+AAL2; Grader remains Grader+AAL2 and active-assignment scoped. Enforce scope before search, counts, filters and pagination. No-store authenticated responses; never log search strings or private response content.

Initial UX: 25 records per page, further pages on demand; accessible loading, no-match, error, active-filter and reset states. Acceptance tests cover name/reference and ID search, combined filters, board metadata, oldest-first ordering, stable pagination, SLA/overdue visibility, PDF states, cross-Grader denial, Owner/Grader scope, tampered parameters and no duplicate/omitted page-boundary records. Planned only; not implemented.


The approved downstream sequence is Phase 1D private file controls, Phase 1E backup/recovery/deletion and Phase 1F synthetic security acceptance; then complete the existing submission/grader queue workflow with its approved search/filter layer, PDF review, rubric-based human grading and publication; then timer/analytics and pilot validation. Cycle 1 Diagnostic and complete Evaluation Report remain free; the full Remedial Course and commercial systems follow the approved roadmap. Branded staging on `gradioprep.com` with an isolated hosted synthetic backend is a mandatory pre-acceptance gate, subject to separate approvals.

## 17. Current secure-foundation dependency status — 6 November 2026

Phase 1C is complete at the local synthetic boundary. Its exact code/test checkpoint `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481` passed [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) with 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests, including synchronized invitation-token acceptance and Owner revocation/account-suspension races. Phase 1C-E audit correlation remains representative per distinct action, not exhaustive outcome coverage.

Phase 1D private PDF/file backend controls are verified locally. They provide safe file upload, metadata, private object access and cleanup only; they do not add the full learner PDF response flow, OCR, corrected transcript, teacher review workspace, grading queue search, human feedback publication UI or student timer/analytics. It does not yet implement the full PDF response, OCR, teacher review workspace, grading queue search, human feedback publication UI or student timer/analytics. Those remain subject to the order and gates in this specification. Diagnostic item authoring remains blocked until the flagship feature is pilot-validated; branded synthetic staging remains mandatory before final Diagnostic/Report acceptance.


## 18. Founder acceptance and next implementation increment — 8 November 2026

The Founder accepted the Phase 1F technical security evidence for the documented synthetic-data testing scope on 8 November 2026. The exact-head suite passed 609 PostgreSQL assertions across 17 SQL files, 32/32 Playwright tests, builds and synthetic backup/restore checks in [#42479406070](https://github.com/gradioprep/gradioprep-website/actions/runs/42479406070). This does not establish production readiness. Hosted backups, physical deletion, monitoring, named operational contacts, provider-specific procedures and privacy/legal approval remain outstanding.

The approved next work is the shared flagship response/grading workflow, synthetic data only. The first narrow implementation slice enforces the approved optional PDF rule at the database/Worker boundary: PDF attachments are allowed only where task metadata explicitly opts in and the expected written response is greater than 20 words. The accepted submission records whether it is typed or typed-plus-PDF; test both allow and deny paths. No PDF-only submission or OCR is included in this slice. No external OCR/AI processor, hosted service or paid resource may be used.


## 19. Verified task-level optional PDF eligibility increment — 8 November 2026

The first backend slice of the approved PDF-response pathway is implemented. Tasks default to typed-only; a task must explicitly set `pdf_response_enabled=true`, and the database requires `ideal_words > 20`. Accepted submissions start with `response_mode='typed'`; the only permitted transition to `typed_pdf` requires a queued submission, eligible task and accepted private PDF. The trusted Worker and database RPCs enforce task eligibility at upload start and finalisation. SQL tests cover the 20-word boundary, typed-only denial, no pending file on denial and forged response-mode rejection.

Exact-head CI [#42484474739](https://github.com/gradioprep/gradioprep-website/actions/runs/42484474739) passed 619 PostgreSQL assertions/17 SQL files, 32/32 Playwright tests, TypeScript/Worker/Vite builds, synthetic backup/restore and cleanup. The workflow skipped Preview intentionally; this was a backend-only change. No OCR or external processor was called.

**Next:** implement the learner-facing optional PDF selector and upload interaction, driven by task metadata, preserving the existing typed option and clearly identifying tasks that do not permit PDF. PDF-only submission, extraction/OCR, split-screen teacher grading, feedback UI and timer/analytics follow as separate increments.


## 20. Milestone batching, synthetic validation and staged learner testing — 8 November 2026

The Founder approved implementation in coherent feature milestones instead of requesting an instruction for each small technical step. Continue the approved synthetic-only work through related implementation, automated testing and documentation batches. The current first task is to resolve the failing typed-only Playwright case on 4f4be588880fd51abe628544a5af84102b5e59ca and rerun the full pipeline. Do not weaken the database PDF-eligibility rule or role/security checks to make the test pass.

Continue in this order:
1. Complete and verify the learner typed/optional-PDF journey, then implement PDF-only acceptance where required by the approved design, PDF.js digital-text extraction and safe transcript versioning.
2. Complete scanned-PDF OCR quality tests using synthetic fixtures. Any external OCR service, provider account, cost or transfer of real learner content requires separate approval; no OCR provider should be called by default.
3. Complete the teacher/grader split workspace, chronological oldest-first queue and approved search/filter controls, rubric-based human grading and human-only feedback publication/versioning.
4. Implement the advisory countdown, server-authoritative elapsed-time events and validated accuracy/speed analytics under the Phase 0 rules.
5. Run the complete shared flagship workflow as a **synthetic pilot**: fictional learner submits typed/PDF work; teacher/grader reviews original and extracted evidence; human feedback is published; learner can view it; SLA/timer and access controls are verified. This synthetic validation is the “pilot-validated” prerequisite for actual MYP Year 4 diagnostic item authoring; it is not a 2–3 person live pilot.
6. Author the approved MYP Year 4 diagnostic items, answer/key and teacher/editor scoring pack; implement the Diagnostic and complete free Evaluation Report; validate scoring, calculations, confidence labels, chart interpretation, responsiveness, keyboard and screen-reader accessibility, rights and academic suitability.
7. Provision branded staging with an isolated hosted synthetic backend only after separate approval for the hosted resources, DNS/custom-domain mapping and any costs. The Founder then tests the complete synthetic journey there before final Diagnostic/Report acceptance.
8. After the Founder’s staging test is satisfactory, a separate invitation-only, free pilot with 2–3 participants may proceed only after all required privacy/legal, security, safeguarding, parent/guardian consent where applicable, provider and cost approvals. Analyse feedback and correct material defects before public-release approval.

The initial free public release (Diagnostic + complete Evaluation Report and approved free starter activity/resources) is separate from the later full commercial launch. Paid grading, credits, the Remedial Course and related entitlements/payments must not be represented as available until implemented and accepted. See the authoritative sequence in docs/DIAGNOSTIC_READINESS_CYCLE_REGISTER.md and the release gates in docs/PUBLIC_PREVIEW_AND_CUSTOM_DOMAIN_RELEASE_PROCESS.md.
