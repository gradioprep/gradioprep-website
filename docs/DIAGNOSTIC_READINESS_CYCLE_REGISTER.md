# Diagnostic Readiness Cycle Register

**Version:** 1.19
**Last updated:** 5 November 2026  
**Status:** Cycle 1 Grade 9 / IB MYP Year 4 provider research, taxonomy, item map, flagship task/PDF/grading/timing plan, 24-hour SLA and Phase 0 decisions are approved. Phase 1B and Phase 1C-A/B/C/D are verified locally using synthetic data. Phase 1C-E now has Worker-only audit ingestion; generic browser-callable audit writers are revoked and the Worker fails closed when its server-only audit service is unavailable. Exact-head commit `3c4b4a71718b795855a9dd41346c80d1a1f85c39`; exact-head run [#41992302366](https://github.com/gradioprep/gradioprep-website/actions/runs/41992302366) passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 27/27 Playwright tests. No public Preview was deployed. Phase 1C-E remains partial pending full endpoint-to-audit reconciliation and targeted route audit-correlation/failure-injection checks; Phase 1C-F and the full Phase 1C exit gate remain incomplete. PR #22 remains open, draft and unmerged; Phase 1D remains blocked. The Diagnostic/Report remains unbuilt and item authoring remains gated by flagship-feature implementation and pilot validation. Branded custom-domain staging backed by isolated hosted synthetic data remains mandatory before final Diagnostic/Report acceptance, after separate approvals. Cycle 2 remains blocked. Hosted provisioning, paid spend, real learner data/external processing, merge, production deployment and DNS remain separate gates.

## 1. Binding order

| Order | Requested school-grade target | Working curriculum alignment | Current status |
|---:|---|---|---|
| 1 | Grade 9 — IB MYP Language and Literature | MYP Year 4 is confirmed by the Founder for the relevant school/programme context; do not reopen this as an assumption. Official MYP programme age band: 11–16; individual chronological age not separately supplied | Provider research, taxonomy/high-level blueprint and detailed item map approved; flagship feature plan, 24-hour grading target and Phase 0 decisions approved; Phase 1B and Phase 1C-A/B/C/D locally implemented and CI-verified with synthetic data; 1C-E partial, 1C-F and complete 1C exit gate incomplete (latest verified code-bearing commit `d6de31c` passed exact-head synthetic CI run #41971855781; 1C-E partial and 1C-F incomplete); Phase 1D blocked. Branded-domain synthetic staging journey is required before final Diagnostic/Evaluation Report acceptance after separate approvals. Flagship learner/grader experience and Cycle 1 diagnostic/report remain unbuilt |
| 2 | Grade 6 — Cambridge English | Exact Cambridge stage and English route remain to be verified. Cambridge Primary Stage 6 / English 0058 is a candidate only where the learner age and first-language route support it. Cambridge Lower Secondary Stage 7 is not a substitute for the requested Grade 6 target | Second cycle; blocked until Cycle 1 is complete and the founder directs the transition |

Grade 9 = MYP Year 4 is a Founder-confirmed placement for Cycle 1, not an unresolved mapping. Cambridge Grade 6 remains a requested school-grade label whose exact official stage/course must be established during Cycle 2 scope lock. Never substitute Cambridge Lower Secondary Stage 7 for Grade 6.

## 2. Official context checks for planning only

### IB MYP Grade 9 / Year 4 — Founder-confirmed

The Founder has confirmed that Grade 9 corresponds to MYP Year 4 in the relevant school/programme context. Record this as confirmed and do not ask for another confirmation. The IB describes the MYP as a programme for ages 11–16 and allows five-year and abbreviated implementations; this context does not override the Founder-confirmed school placement. No official MYP objective/criterion mapping is inferred from this grade/year confirmation.

Official public sources checked 31 October 2026:

- [IB Middle Years Programme](https://www.ibo.org/programmes/middle-years-programme/) — age range and five-year programme with shorter formats.
- [IB MYP eligibility and flexible implementation](https://www.ibo.org/programmes/middle-years-programme/what-is-the-myp/who-can-offer-the-myp/is-my-school-eligible-to-offer-the-myp/) — authorised shortened implementations.
- [IB MYP curriculum](https://www.ibo.org/programmes/middle-years-programme/curriculum/) — subject groups and Years 4–5 flexibility.

### Cambridge Grade 6

Cambridge uses Primary and Lower Secondary stages rather than a universal "Grade 6" label. Cambridge Primary consists of six stages and Stage 6 is typically the final primary year, with learners reaching approximately age 11; Cambridge allows stages to be adjusted to local school context. Cambridge Primary English 0058 is a first-language English course, with a separate route for learners using English as an additional language.

The exact Cambridge Grade 6 course/stage cannot be locked from the phrase "Grade 6" alone. During Cycle 2 scope lock, confirm the school-grade context, learner age and English-course route from official sources. Do not use Lower Secondary Stage 7 merely because some school structures place Grade 6 learners at that age; Stage 7 is not an approved replacement for the requested target.

Official public sources checked 31 October 2026:

- [Cambridge Primary stage ages](https://help.cambridgeinternational.org/hc/en-gb/articles/360000048218-At-what-age-should-children-start-following-Cambridge-Primary-curriculum-frameworks) — six stages, final stage around age 11, with local flexibility.
- [Cambridge Primary Checkpoint age and transition](https://help.cambridgeinternational.org/hc/en-gb/articles/360000055178-Which-age-group-of-learners-is-the-Cambridge-Primary-Checkpoint-for-and-when-is-the-transition-to-Cambridge-Lower-Secondary) — end of Stage 6 is typically around age 11.
- [Cambridge Primary English 0058](https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-primary/curriculum/english/) — first-language English course and four skills.

This is a limited scope/identity check, not the diagnostic Top Five, a full curriculum review or an official Grade 6 equivalence claim.

## 3. Cycle completion record

Each cycle follows the requirements and approval gates in `docs/DIAGNOSTIC_AND_REMEDIAL_LEARNING_READINESS_STANDARD.md`:

1. Scope lock and official context.
2. Separate Top Five diagnostic/evaluation provider audit.
3. Skill taxonomy, diagnostic blueprint and item plan.
4. Validated diagnostic and separate teacher/editor pack.
5. Evaluation report and analytics.
6. Mandatory whole-website learner-facing copy cleanup after diagnostic/report validation and before remedial authoring.
7. Personalised remedial course (five × 60-minute sessions recommended; up to seven sessions maximum, as needed to address every improvement area).
8. Post-course outcome check.
9. Complete student-journey integration and QA.
10. Founder approval; only then consider the next cycle when explicitly directed.

| Feature / gate | Cycle 1: Grade 9 IB MYP | Cycle 2: Grade 6 Cambridge |
|---|---|---|
| Official grade/year/course scope locked | Complete (Founder-confirmed) | Blocked |
| Diagnostic Top Five research | Complete; Founder-approved | Blocked |
| Skill taxonomy and high-level blueprint approved | Complete; Founder-approved 1 Nov 2026 | Blocked |
| Detailed task-level item map and scoring specification | Complete; Founder-approved 2 Nov 2026 | Blocked |
| Flagship PDF response, teacher grading and timed analytics plan | Complete; phased plan and 24-hour grading target approved 2 Nov 2026 | Blocked |
| Flagship feature implementation and pilot QA | In progress, not complete: Phase 1B and Phase 1C-A/B/C/D are locally verified using synthetic data. Phase 1C-E has the new invitation/private-QA audit-outcome increment but remains partial because generic false-failure audit events can still be fabricated through direct audit-RPC calls and Worker route/integration tests remain outstanding. Phase 1C-F and the full Phase 1C exit gate remain open; Phase 1D private PDF/file controls remain blocked. Learner-facing PDF/extraction, teacher workspace, timer/analytics and pilot QA remain outstanding. Branded custom-domain staging with an isolated hosted synthetic backend is mandatory before final Diagnostic/Evaluation Report acceptance, subject to separate approvals. | Blocked |
| Actual diagnostic item authoring and teacher/editor scoring pack | Paused until the shared response/task metadata and core feature are implemented and validated | Blocked |
| Diagnostic built and validated | Not started | Blocked |
| Evaluation report and analytics built/validated | Not started | Blocked |
| Whole-site learner-facing copy cleanup after diagnostic/report QA and before remedial authoring | Not started; mandatory before remedial work | Blocked |
| Personalised remedial course (five sessions preferred; six/seven only if analytics justify) and teacher pack complete | Not started | Blocked |
| Post-course check validated | Not started | Blocked |
| Integration and full QA passed | Not started | Blocked |
| Founder approval for complete cycle | Not started | Blocked |


**Historical platform checkpoint — 5 November 2026; superseded by Section 25:** The prior verified head `d6de31c467817ad83e864760d61d2e8ab5e112ed` and run [#41971855781](https://github.com/gradioprep/gradioprep-website/actions/runs/41971855781) recorded the audit-context enrichment only. Subsequent protected-read/write, learner-outcome, staff-invitation and private-QA work is recorded in the current Section 25. The previous note remains as history and must not be treated as the current next-step or code checkpoint.

Before final acceptance of that Diagnostic/Report, the public experience must be exercised on a branded staging host on the Founder-confirmed purchased domain, backed by a separate isolated hosted synthetic test environment. Verify Auth (including confirmation and recovery), HTTPS/TLS and redirects, navigation/deep links/refresh/Back/Forward, Diagnostic submission, report generation, dashboard persistence and role/access restrictions. Staging Worker/backend provisioning, DNS/custom-domain mapping and paid usage each require separate approval; none is authorised by this record. Production-domain cutover and launch remain later separate approvals. Keep the existing whole-website learner-facing copy-cleanup gate after Diagnostic/Report validation and before remedial authoring; Cycle 2 Cambridge Grade 6 remains blocked.

**Historical verified platform prerequisite checkpoint — 3 November 2026:** Phase 1C-B accepted human-assessment submissions and Phase 1C-C human assessment/feedback are implemented and verified on `d2e825746aa814de1f100ef2d8daa2e841d91c80`, exact-head run [#41668857175](https://github.com/gradioprep/gradioprep-website/actions/runs/41668857175) passed 361 PostgreSQL/pgTAP assertions across eight SQL files and 27/27 Playwright tests, plus reset/seed, TypeScript/Worker/Vite builds and cleanup. This is backend infrastructure progress, not a learner-facing Diagnostic or Evaluation Report implementation. The approved Grade 9/MYP Year 4 provider research, skill blueprint and item map remain complete; actual item authoring and the Diagnostic/report build are still gated by completion and validation of the shared flagship feature.

## 4. Existing curriculum-content work — preserved and deferred

The diagnostic-first decision changes the immediate work order only. It does not delete, rewrite, approve or release existing curriculum units or teacher packs.

- MYP Year 1 Unit 1 v4 on PR #14 remains founder-approved for its exact content, human academic review and age/level/context suitability. Unit-level rights/territory, image/context, manual accessibility and release gates remain open.
- Cambridge Lower Secondary Stage 7 Unit 1 v1.3, its completed Stage 7 Top Five audit and controlled preview remain existing records. The Stage 7 teacher-pack/counter migration and its outstanding gates are deferred; Stage 7 is not Cycle 2.
- CBSE Grade 6 Unit 1 v1.0 remains its exact-version academic-content candidate; its planned Top Five, pack/counter work and remaining review gates are deferred.
- PRs #12, #14, #15, #16 and #17 remain separate draft/unmerged candidates/previews; PR #19 records the approved MYP diagnostic research/blueprint/item map, and PR #20 records the approved flagship feature plan. Both remain draft/unmerged. PR #16's older base is not rebased or altered by this decision.

The former Unit 1 rotation and queued migration plans are historical work queues only. They do not determine the next task while the diagnostic cycles are active. After both diagnostic cycles are approved, the Founder / project owner will specify the next curriculum-content order and scope. This may include completing multiple units for Grade 9 IB MYP or Cambridge Grade 6 before switching to another level, or another explicitly selected order. The former Unit 1 rotation remains inactive unless explicitly reinstated by the founder.


## 5. Cycle 1 — Grade 9 IB MYP Language and Literature

**Status:** The Top Five research, taxonomy/high-level blueprint, detailed item map/scoring specification, flagship response/grading/timer plan, 24-hour grading target and Phase 0 decisions are Founder-approved. Phase 0 is complete and the approved implementation sequence is underway; Phase 1B local synthetic-only work remains in draft PR #22. The suspended-account Auth/Worker/API/RLS/UI flow passed PostgreSQL RLS CI and 16/16 Chromium tests in run #41500536318 on application-code commit `ad82f0875737e337ea52b2918a04d0d17cd14f36`. The branch Preview is deployed and awaits Founder visual review. The free-first policy targets US$0 recurring infrastructure costs through 2 November 2027, with 100+ subscribers as a review point only. Hosted provisioning, paid use, real learner data, external processing, merge, production deployment and DNS remain separate gates. MYP diagnostic implementation and question authoring have not started. Provider percentile evidence remains internal in `docs/internal/DIAGNOSTIC_PROVIDER_RANKING_REGISTER.md`.

**Confirmed placement:** Grade 9 = MYP Year 4, as explicitly confirmed by the Founder for the relevant school/programme context.


**Founder clarification — 31 October 2026:** Five 60-minute sessions are preferred wherever evaluation analytics show comprehensive coverage is possible. Extend to six or seven only where the analytics justify additional teaching/practice time; never exceed seven sessions.


**Founder decision — 31 October 2026:** The Top Five provider research is approved. Provider percentiles use the internal 50/50 actual test-taker / independent research method; all ranking data and methodology are excluded from learner/parent reports, including logged-in views. The draft MYP Year 4 taxonomy/blueprint is submitted for review. Five remedial sessions are preferred; extend to six or seven only when evaluation analytics justify it.


**Founder approval update — 2 November 2026:** The Founder approved the detailed MYP Year 4 item map/scoring specification (35 evidence observations, not 35 independent long questions; all 23 subskills, six MYP skill areas and four criterion profiles remain mapped), the flagship response/grading/timed-analytics feature plan and the 24-hour elapsed-time grading target. A subsequent Phase 0 decision approval closed architecture, provider/region, role, file-limit, timer and retention questions; see `docs/PHASE_0_ARCHITECTURE_AND_DATA_GOVERNANCE_DECISIONS.md`. Phase 0 is complete. Phase 1B local synthetic-only coding was subsequently approved and is underway in draft PR #22. No hosted project, paid service, real learner data, OCR/AI processing, merge or production deployment is authorised. Cambridge Grade 6 remains blocked; all existing curriculum-unit queues remain deferred.


**Phase 1 planning update — 2 November 2026:** The detailed secure-foundation specification is complete as a draft documentation deliverable. It sets out Auth and role controls, protected Worker APIs, PostgreSQL/RLS, private Storage, audit, encrypted backup/restore/deletion and synthetic-data security acceptance. At this earlier planning checkpoint, no implementation had started; this was superseded when Phase 1B local synthetic-only coding was approved and begun in draft PR #22. Cycle 1 remains the only active diagnostic cycle; MYP Year 4 item authoring remains gated until the flagship feature is implemented and pilot-validated. Cambridge Grade 6 remains blocked. No account, paid service, database, storage, OCR/AI endpoint, real-data processing, merge or deployment is authorised.


**Phase 1A status — 2 November 2026:** Engineering preparation is complete. The proposed Phase 1B code slice is local-only: Supabase CLI/Auth/PostgreSQL/Storage with fictional seed records, React browser Auth, Worker API authentication, initial profile/role migration, RLS and synthetic CI tests. No remote service, billing, real learner data or external OCR/AI/backup processor is used. Phase 1B local synthetic-only coding is now approved and underway in draft PR #22; no hosted project or paid service is included. Cycle 1 actual item authoring remains gated until the flagship feature is implemented and pilot-validated; Cycle 2 Cambridge Grade 6 stays blocked.


## 6. Mandatory whole-site learner-facing copy cleanup

**Cycle 1 position:** Immediately after the Grade 9 / IB MYP Year 4 diagnostic and evaluation report/analytics have been completed and checked, and before any remedial lesson, practice activity or remedial teacher/editor content is authored.

**Scope:** The entire website, every route and every visible state—not only the dashboard or diagnostic journey. Follow docs/DESIGN_SPEC.md Section 17 for the route/state inventory, known text examples, learner-facing replacement direction, preservation of layout bands/cards, searchable TODO:/TEMP_COPY_ convention and acceptance checks.

**Acceptance:** All internal planning/editor/development notes and temporary placeholder wording are removed from rendered UI and replaced with accurate context-specific copy or useful empty states; no fabricated metrics are presented as live; no unverified unit/syllabus focus is implied; the current visual hierarchy and all bands/cards remain intact; automated content checks and desktop/mobile browser review pass; corrections and reviewed routes are recorded; and the Founder verifies the refreshed Preview. Remedial authoring stays blocked until this row is marked complete.



### Phase 1B platform checkpoint — 2 November 2026

PR #22 remains draft/open/unmerged. Run #41473170539 passed on the preceding revision `97d2bb4`; the latest exact-head run #41473237444 passed on code-bearing revision `50f4bb3`. It verifies local Supabase synthetic fixtures, `identity_roles.test.sql` RLS assertions, the browser/Worker builds and 15/15 Chromium tests. Cloudflare's branch Preview is current for that revision and is not connected to hosted Supabase; manual Founder review is pending. The Phase 1B workflow's own Preview steps were skipped on the push event. Use the exact URLs recorded in Master Brief v4.35, not the older `pr-22` alias.

The diagnostic cycle remains at the pre-authoring stage. MYP Year 4 actual diagnostic authoring is still gated by flagship implementation and pilot validation. The whole-site copy cleanup remains not started and must stay after Cycle 1 diagnostic/report QA and before remedial authoring. Cambridge Grade 6 remains blocked.

### Phase 1B suspended-account security increment — 2 November 2026

A local synthetic suspended-account fixture and fail-closed access rules are being added to PR #22, with Worker/API and browser regression tests. Verification is pending. This remains platform security work only: Cycle 1 diagnostic authoring has not started; the whole-site copy-cleanup gate remains not started and stays after Cycle 1 diagnostic/report validation but before remedial authoring; Cambridge Grade 6 remains blocked.


## 7. Approved free-first course access and grading-credit model — 4 November 2026

The detailed binding rules are in docs/GRADING_CREDIT_AND_REMEDIAL_ACCESS_POLICY.md. Apply them to each cycle only with its own verified task inventory:
- The initial diagnostic and complete evaluation report are free; provide at least one meaningful free starter remedial activity.
- The full personalised remedial programme uses the proposed ₹199/month Study Lab entitlement or an approved complimentary grant. Study Lab remains a price hypothesis until validated.
- Human grading is separate: one free Standard task per learner account; Standard 1 credit, Premium 2, Elite 3, Custom 4+; ₹399 per credit remains a price hypothesis.
- Determine each task's price from the approved task scope and predicted grader minutes, with word bands as guidance. Build a separate task-frequency/marks dataset for every grade/curriculum; do not transfer CBSE proportions into IB or Cambridge or treat the approximate CBSE 50-word example as universal.
- A single 24-hour elapsed-time target applies to all accepted human grading, including the free Standard task; it supersedes older 72/48-hour differentiated proposals. No urgent surcharge at initial launch.
- The payment/credit/entitlement system, learner email verification delivery and commercial Admin dashboard are approved specifications but not implemented. Do not block the free diagnostic/report on those features; complete them before any paid sales or course lock is enabled.


## 24. Historical Phase 1C-E audit-context checkpoint — superseded by Section 25

PR #22 remains open, draft and unmerged on `feature/phase-1b-local-auth-api`. Last verified code-bearing commit: `d6de31c467817ad83e864760d61d2e8ab5e112ed`. Exact-head GitHub Actions run [#41971855781](https://github.com/gradioprep/gradioprep-website/actions/runs/41971855781) passed local Supabase reset/seed, all PostgreSQL/RLS/pgTAP tests, TypeScript/Worker/Vite builds, 27/27 Playwright tests, cleanup and clean public-preview asset build. Cloudflare Workers Builds passed for the exact commit. No Founder-facing Preview was requested for this backend-only increment.

The full Phase 1C exit gate remains open. Next, complete the operation-by-operation audit and Worker/database authorization matrix, including denied/failed audit semantics, then complete the 1C-F adversarial acceptance matrix. The branded synthetic staging journey remains a later mandatory pre-acceptance gate after separate hosted-resource and DNS approval. Do not begin Phase 1D or Cycle 2.

## 25. Historical Phase 1C-E checkpoint and Cycle 1 implementation gates — superseded by Section 26

**Current code verification:** Code-bearing commit `f5097ba8bae0eee4c420e8e5081f90287f3149ee`; exact-head run [#41984620018](https://github.com/gradioprep/gradioprep-website/actions/runs/41984620018) passed 534 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds, 27/27 Playwright tests, local Supabase shutdown, local credential-file cleanup and clean public-preview asset build. The later documentation-only head `1f1195de965d40631879dc140dcca4b8a447cf54`, run [#41985668001](https://github.com/gradioprep/gradioprep-website/actions/runs/41985668001), also passed the same full workflow. Both runs were branch-push events; the workflow's public Preview upload is restricted to a qualifying pull-request event carrying the Founder-preview marker. No public/Founder Preview was deployed. The latest documentation reconciliation head `1f1195de965d40631879dc140dcca4b8a447cf54` passed the full workflow in [#41985668001](https://github.com/gradioprep/gradioprep-website/actions/runs/41985668001). PR #22 remains open, draft and unmerged. No public/Founder Preview was deployed.

**Implemented since the audit-context checkpoint:** The code adds protected-read/write outcome foundations, learner workflow write outcomes, staff-invitation collection/create/revoke error handling, Owner private-QA read error handling, and a token-hash-bound, database-derived invitation acceptance denial/state helper. The protected-table inventory remains 25 tables (18 public, seven private). No learner response, feedback, QA payload, invitation token or email is placed in the audit event.

**Remaining security blockers:** Phase 1B and Phase 1C-A/B/C/D are verified at their recorded local-synthetic checkpoints. Phase 1C-E now includes audit-context enrichment, protected-read and privileged-write outcome groundwork, learner write outcomes, staff-invitation list/create/revoke handling, Owner private-QA read error handling and database-derived invitation-acceptance denial/state events. **Phase 1C-E remains partial:** the generic `audit_privileged_write_outcome` and `audit_protected_read_outcome` RPCs still let an authorised caller create a misleading `failed` audit event by calling the RPC directly without executing the underlying protected operation. The next code slice must bind failures to real operations, add direct-RPC abuse and genuine-failure tests, and add Worker route/integration tests for staff-invitation and private-QA outcomes. Phase 1C-F adversarial acceptance remains incomplete; Phase 1D remains blocked until all Phase 1C exit criteria pass. A passing local test suite does not mean the entire Phase 1C matrix is closed. The immediate work is operation-bound generic failure auditing and Worker route/integration tests. Then complete the full endpoint-to-audit/authorization matrix and Phase 1C-F adversarial acceptance. Phase 1D remains blocked.

**Cycle 1 scope remains unchanged:** approved Grade 9 / IB MYP Year 4 research, taxonomy and item map are preserved. The Diagnostic/Evaluation Report and actual item authoring remain unbuilt and gated by flagship feature implementation and pilot validation. Branded synthetic staging on the Founder-confirmed domain remains mandatory before final Diagnostic/Report acceptance, subject to separate approvals. The whole-site learner-facing copy cleanup remains after Diagnostic/Report validation and before remedial authoring. Cambridge Grade 6 / Cycle 2 remains blocked until Cycle 1 is complete and the Founder directs transition.

No hosted resource, paid service, real learner data, external processor, merge, production deployment or DNS/custom-domain change is authorised by this checkpoint.


## 26. Verified Worker-only audit-outcome hardening and Cycle 1 gates — 5 November 2026

**Verified implementation update — 5 November 2026:** PR #22 remains open, draft and unmerged. Code head `3c4b4a71718b795855a9dd41346c80d1a1f85c39`; exact-head GitHub Actions run [#41992302366](https://github.com/gradioprep/gradioprep-website/actions/runs/41992302366) passed **494 pgTAP assertions across 14 SQL files**, TypeScript/Worker/Vite builds, **27/27 Playwright tests**, local Supabase shutdown, local credential cleanup and clean public-preview asset build. The workflow was a branch push, so no public/Founder Preview was uploaded. Migration `20261105000900_phase1c_worker_only_audit_ingestion.sql` introduces `record_worker_audit_outcome`, callable only by `service_role`; the old browser-callable generic audit outcome RPCs are revoked. The Worker uses its server-only service-role client solely for audit ingestion, with verified actor identity and allowlisted actions, outcomes and safe reason categories; business reads/writes remain on the caller-scoped client. Audit writes fail closed if the Worker audit key is absent or the database does not acknowledge the event. The local service-role key is kept in ignored `.dev.vars` and is not copied to browser `.env.local`/Vite variables. Browser direct-RPC forgery tests, trusted-writer tests and the existing Playwright invitation/private-QA/account API journey pass. Phase 1C-E remains partial pending the complete endpoint-to-audit/authorization matrix and targeted failure-injection/correlation acceptance; Phase 1C-F remains open and Phase 1D remains blocked. No hosted resources, real learner data, paid usage, merge, deployment or DNS changes occurred.

The audit-ingestion change does not alter the Cycle 1 sequence, the Founder-approved Grade 9 / IB MYP Year 4 scope, its research/taxonomy/item map, the flagship feature plan, or the mandatory post-report whole-site copy cleanup. The Diagnostic/Evaluation Report and actual item authoring remain unbuilt and gated by shared flagship implementation and pilot validation. Cambridge Grade 6 / Cycle 2 remains blocked until Cycle 1 is complete and the Founder directs transition.

Phase 1C-E remains partial pending full endpoint-to-audit/authorization reconciliation and targeted route audit-correlation/failure-injection coverage; Phase 1C-F remains open; Phase 1D remains blocked. Branded synthetic staging on the Founder-confirmed domain remains mandatory before final Diagnostic/Report acceptance, subject to separate approvals. No hosted resource, paid service, real learner data, external processor, merge, production deployment or DNS/custom-domain change is authorised.
