# Phase 0 Architecture, Privacy and Data-Governance Decisions

> **Current execution checkpoint — 8 November 2026 (authoritative active state; prior environment-setup proposals are superseded):** PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`, based on `docs/phase-1-secure-foundation-spec`. The user's last confirmed clean WSL checkout is `1caf00e134333f7effcdaf94ac0cb233218e295b`; the remote branch has since advanced through documentation-only infrastructure/CI reconciliations. Run one `git pull --ff-only origin feature/phase-1b-local-auth-api` before the next local repository operation; do not reclone or reinstall. Node `v22.23.4`, npm `10.9.9` and the 130-package dependency installation are already complete. **Memory snapshot:** Windows reports 5.94 GiB visible RAM and 1.44 GiB available; WSL reports 2.8 GiB total, 688 MiB used, 1.8 GiB free and 2.1 GiB available, with 1 GiB swap unused; Docker reports about 2.81 GiB and 4 CPUs, with no running containers. **Binding device rule:** do not start Supabase/Docker-based database testing on this Windows/WSL computer, do not register it as a persistent self-hosted runner, and do not change its WSL/Docker resource limits. Run synthetic Supabase tests only inside an ephemeral GitHub-hosted `ubuntu-latest` CI job. Keep the repository private. GitHub Actions run [#42466941118](https://github.com/gradioprep/gradioprep-website/actions/runs/42466941118) failed with no steps reported and no accessible logs; its cause and current Actions-minute usage are unconfirmed, so do not claim that a quota was exhausted. The GitHub check [Workers Builds: gradioprep-website](https://github.com/gradioprep/gradioprep-website/runs/128687968955) passed on commit `37e279d93f0f5ad82ccfa29f51cca0031f1f806b`; the later check for commit `2a6f1108fd0d86d3da0fda44b7811f3c4d5fdd14` was still in progress at the last status read. All five GitHub spending budgets remain blocked. **Cloudflare:** the private repository is already connected to Workers Builds; automatic builds and previews are enabled, with `main` configured for production, `npm run build` as build command and `npx wrangler deploy` as production deploy command. Build watch-path exclusions are currently empty; configure documentation-only exclusions in a later reviewed settings change. The account build-limit check on 8 November reported that the limit had not been reached. Phase 1C is complete, Phase 1D verified and Phase 1E partial/unverified; its 35- and 47-assertion SQL suites and backup/restore verifier remain pending. Hosted Supabase is not provisioned. Any later isolated cloud test project, branded staging, paid use, real learner data, external processing/email, DNS change, production configuration/deployment or PR merge remains separately gated.
**Version:** 1.3
**Decision date:** 2 November 2026  
**Last updated:** 8 November 2026
**Status:** Phase 0 decisions approved by the Founder. Phase 0 is complete. These are approved design decisions, not authority to create accounts, incur costs, configure services, process real learner data, merge, deploy or release.  
**Applies to:** Shared Grades 6–12 written-response, PDF submission, human grading, feedback and timed-analytics platform.

## 1. Architecture decisions

1. **Application hosting:** Retain the existing Cloudflare Workers deployment for the React application and lightweight request/API orchestration. Do not run CPU-heavy PDF processing or OCR inside a Worker.
2. **Authentication, database and primary private file storage:** Use one consolidated **Supabase** project for Supabase Auth, PostgreSQL and private Supabase Storage. The primary project region is the specific AWS **South Asia (Mumbai), `ap-south-1`** region. Do not use Cloudflare D1 or introduce a second application database.
3. **Free-first live-data plan:** Keep the approved single Supabase project and Mumbai (`ap-south-1`) region, but use the Free plan as the starting cost candidate wherever it can meet the tested security, capacity, availability, backup/restore and privacy requirements. The Free plan has 500 MB database, 1 GB file storage and 50,000 monthly active users; it may pause after seven days of low activity and does not include automatic downloadable database backups. Supabase CLI logical exports are available, but database dumps do not back up Storage API file objects. Supabase Pro (currently advertised from USD 25/month before possible usage/compute additions) is an optional fallback only if a documented requirement cannot be met safely on Free or another suitable free arrangement. It is not an automatic prerequisite or pre-approved purchase. Real learner data remains blocked until the chosen plan's recovery, availability, capacity and privacy gates pass and the Founder separately authorises the live-data pilot. Follow `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.
4. **Database and file backup:** Supabase database backups do **not** include Storage API file objects. On Free, assess scheduled/manual Supabase CLI logical exports and an independently protected file-object backup; test both restore paths together. Pro daily backups, if later selected, provide seven days of database recovery but still do not include Storage API objects. Maintain a separate encrypted backup of private PDF objects and required metadata. **Cloudflare R2** remains the selected secondary backup target only; it is not primary application storage or a second database. Its 10 GB-month Free allowance may suit an early backup set, but its APAC location hint is best-effort, not an India residency guarantee. No real learner content may be replicated to R2 until transfer/residency, encryption/key custody and privacy review pass. If no free arrangement can meet the tested recovery commitment, keep live submissions blocked or present the unavoidable paid option for a decision. A documented restore test must restore both database records and original PDF objects.
5. **Digital PDFs:** Use Mozilla **PDF.js** in the application for rendering the original PDF and extracting its embedded digital text. This is the first path and avoids an external OCR request where a usable text layer exists.
6. **Scanned pages and handwriting OCR:** Use **Microsoft Azure AI Document Intelligence Read (`prebuilt-read`, v4 API)** as the selected OCR integration, with **Central India** (`centralindia`) as the intended resource region. Confirm exact resource/region availability before activation; do not silently fail over to another country/region. The service is external processing, not in-house OCR. Use PDF.js first for digital text. For the F0 free tier, enforce the documented 4 MB input limit, two-page analysis limit, 1 request/second limit and 500 pages/month quota. The approved 10 MB/10-page upload remains a product cap; if F0 is used, render/process eligible pages individually and keep each request within 4 MB. Benchmark synthetic handwriting/print quality first. Enforce the monthly quota in GradiPrep. Quota exhaustion or OCR failure must never reject or destroy an accepted original PDF; the teacher grades from the original. S0 is metered and requires an exact regional quote and explicit cost approval.
7. **AI feedback drafts:** Use **Cloudflare Workers AI** for on-demand generation of exactly ten teacher-only suggestions, subject to synthetic evaluation and model selection. The free allowance is 10,000 Neurons/day. Use standard stateless inference only: no AI Gateway logging, caching, asynchronous/batch file storage or other stateful content-retaining feature. Do not write prompts or outputs to application logs. No paid inference beyond the free allocation unless a separately priced exception is approved; on quota exhaustion or service failure, the teacher writes feedback manually. AI suggestions remain drafts and are never published without human action.
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

Apply the binding free-first policy in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`: target US$0 recurring infrastructure spend for the first 12 months from 3 November 2026; review actual usage and possible upgrades at 100+ subscribers, without automatic upgrading. Supabase Free, Cloudflare Workers Free, R2 Free, Azure F0 and Workers AI's daily free allowance are the starting candidates only where their limits meet the approved requirements.

- No automatic plan upgrades, paid overage, spend-cap removal or spend-limit changes.
- A paid option requires evidence that no suitable free/open-source/local option can meet an essential requirement, a current provider quote and the Founder's explicit approval before activation.
- Hard-stop OCR and AI calls at their free quotas unless a specific paid exception is approved. Preserve accepted PDFs for manual grading.
- Monitor database, file storage, egress, requests, CPU, OCR pages, AI neurons and backup operations; alert before quota exhaustion and prevent silent charges.
- Free-tier limitations must be addressed by tested controls or must keep real-data acceptance blocked. Do not weaken privacy, security, residency or restore requirements to stay free.


## 7. Decision status and next gate

**Phase 0 is complete.** The decisions above close the Phase 0 architecture, timer, retention, provider, upload-limit and access-control choices. They do not close implementation, legal/privacy, quality or release gates.

**Next phase: Phase 1 — Secure application foundation.** The phased implementation plan and architecture are Founder-approved; Phase 1B local synthetic-only coding has already been explicitly authorised and is underway. Continue implementation in the approved sequence with synthetic data, draft PRs, CI and public Preview verification; do not request implementation re-approval for steps already included in the approved plan. This does not authorise hosted resource provisioning, paid services, real learner data, external OCR/AI/backup processing, merge, production deployment or DNS changes. These remain separate billing, privacy, security and release gates. Before real learner data, the chosen free or paid plan must pass availability, capacity, backup/restore and privacy tests. Apply `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.

## 8. Official references checked 3 November 2026

- Supabase regions: https://supabase.com/docs/guides/platform/regions
- Supabase pricing and limits: https://supabase.com/pricing
- Supabase Free-plan inactivity pausing: https://supabase.com/kb/faqs/platform/free-project-pausing
- Supabase Free-plan manual database exports: https://supabase.com/kb/faqs/platform/free-plan-backups
- Cloudflare Workers Free/Paid limits and pricing: https://developers.cloudflare.com/workers/platform/limits/ and https://developers.cloudflare.com/workers/platform/pricing/
- Cloudflare R2 Free quota and pricing: https://developers.cloudflare.com/r2/pricing/
- Cloudflare Workers AI Free allocation and pricing: https://developers.cloudflare.com/workers-ai/platform/pricing/
- Supabase backups and Storage API exclusion: https://supabase.com/docs/guides/platform/backups
- Azure Document Intelligence Read model and input limits: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/concept-read
- Azure Document Intelligence F0 quota and pricing: https://azure.microsoft.com/en-us/pricing/details/document-intelligence/
- Azure Document Intelligence v4 encryption, 24-hour analysis-result availability and delete API: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/authentication/encrypt-data-at-rest?view=doc-intel-4.0.0
- Azure region list: https://learn.microsoft.com/en-us/azure/reliability/regions-list?tabs=all
- Cloudflare Workers AI data use: https://developers.cloudflare.com/workers-ai/platform/data-usage/
- Cloudflare R2 data location and best-effort location hints: https://developers.cloudflare.com/r2/reference/data-location/
- India's DPDP Act, 2023: https://www.meity.gov.in/static/uploads/2024/02/Digital-Personal-Data-Protection-Act-2023.pdf
- India's DPDP Rules, 2025 and enforcement timeline: https://www.meity.gov.in/documents/act-and-policies/digital-personal-data-protection-rules-2025-gDOxUjMtQWa

**Approval boundary:** The Founder approved these Phase 0 architecture/provider/timer/retention decisions on 2 November 2026 and subsequently approved the phased implementation plan, including Phase 1B local synthetic-only coding. This decision record does not authorise paid spending, hosted resource provisioning, real learner data or external learner-content processing, PR merge, production deployment, DNS or Cloudflare production configuration changes. Apply the free-first policy in `docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md`.

## Historical implementation-status note — 7 November 2026 (superseded by Section 9)

The approved retention and deletion schedule above remains binding and unchanged. Phase 1E has only partial local implementation: request/legal-hold and account-closure/retention-inventory migrations are present, but their 35- and 47-assertion SQL tests have not run. Current code does not claim physical erasure of learner content or private Storage objects; R2 backup-object rows are metadata only and no R2 resource has been provisioned. No change is made to the existing 12-month, 24-month or 30-day periods, legal-hold exception, external-processing restrictions or real-data approval gate.

## 9. Current build, test and device execution decision — 8 November 2026

The Phase 0 architecture/provider decisions above remain unchanged. This section clarifies where approved synthetic testing is executed.

- The user must **not** run Supabase/Docker database containers on the Windows/WSL computer and must not register that computer as a persistent self-hosted GitHub runner. Windows reported 1.44 GiB available RAM; the senior developer advised against local Supabase.
- The existing GitHub Actions workflow runs `supabase start` only inside an ephemeral GitHub-hosted `ubuntu-latest` job. This is the approved execution location for disposable synthetic PostgreSQL/RLS/API/browser tests. It is not the user's local computer and is not a hosted Supabase project.
- Cloudflare Workers Builds is already connected to the private repository for app build/deployment and branch Previews. Its documentation-only watch-path exclusions are not configured yet. GitHub workflow path filters for documentation-only changes are also pending.
- Keep the repository private. Public visibility would disclose internal product, curriculum, assessment and security materials as well as code/history.
- A separate Supabase Free project is a later fallback only for hosted end-to-end integration or the mandatory branded staging journey. Up to two active Free projects may be available per eligible account, but Free projects can pause after a week of insufficient database activity. Account capacity must be checked and provisioning explicitly approved before any project is created. No hosted test project is authorised now.
- The latest GitHub Actions run #42466941118 failed without reported steps or accessible logs; Cloudflare's Workers Builds check passed on the preceding documentation head. Do not treat it as proof of exhausted minutes. Keep all GitHub spending budgets blocked; no overage or plan change is authorised.

This execution clarification does not change the selected Supabase provider/region, data model, backup target, OCR/AI provider selection, privacy requirements, real-data approval gate, domain plan or production release controls.
