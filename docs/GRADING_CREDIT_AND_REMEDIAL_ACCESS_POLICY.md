# Grading Credit, Curriculum-Frequency and Remedial Access Policy

**Version:** 1.1  
**Approved:** 4 November 2026; commercial amendment approved 6 November 2026  
**Status:** Founder-approved product and commercial specification. Documentation-only approval; no payment service, credit ledger, entitlement service, Admin dashboard, email provider or paid integration has been provisioned or implemented.  
**Authority:** This is the single detailed source of truth for grading-credit allocation, curriculum-frequency analysis, learner free/paid access, customer entitlements and commercial sequencing. The Master Brief records binding product decisions; DATA_MODEL records logical records; the flagship PDF/grading specification records task/PDF workflow; and the diagnostic standard governs the diagnostic/remedial cycle.

## 1. Governing product and pricing principles

1. The initial diagnostic and its complete evaluation report are free to the learner. The report must not be hidden behind a registration-to-payment conversion gate or a paywall.
2. Provide a meaningful free starter remedial lesson/activity after the report. Keep selected lessons, practice questions, explanations, syllabus discovery and other designated free resources available before 100 subscribers.
3. The full Remedial Course is a separate course entitlement, priced at ₹1,999 standalone. The earlier ₹199/month Study Lab subscription proposal is superseded and is not an approved current product or price. An authorised Admin may grant a complimentary entitlement through the future audited entitlement controls.
4. Human grading is a separate optional paid service. A learner may hold the Remedial Course entitlement without grading credits, or grading credits without course access where the task is otherwise available.
5. One grading credit represents a defined unit of human-grading effort. It is not a universal word-count allowance, a page allowance or an AI-processing token.
6. Task credit requirements are calculated and shown before submission acceptance. A learner is never charged an unexpected extra credit after submission or because the typed response exceeds its ideal word target.
7. The task's expected response length informs the effort estimate. Predicted grader time and task complexity determine the final credit requirement. Curriculum frequency estimates typical consumption and pack mix; it does not override the task-level rule.
8. The approved free-first infrastructure budget is a separate constraint. It targets US$0 recurring infrastructure subscriptions and paid API usage through 2 November 2027, with a review at 100+ active subscribers; that review does not automatically authorise an upgrade. See docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md.

## 2. Market benchmark — five relevant products

Public pricing and feature pages were checked on 4 November 2026. These examples are directional benchmarks, not direct price equivalents: most are AI-assisted grading products or educator/institution software, whereas GradiPrep's proposed differentiator is human rubric-based assessment.

| Product | Publicly described model at research date | Relevant product signal |
|---|---|---|
| [CoGrader](https://cograder.com/pricing/) | Starter is free with 100 student submissions/month. Standard is listed at US$15/month when billed annually and includes 350 submissions/month. Schools/districts receive a size-based quote. | Free submission allowance plus clear paid volume step; institutional administration, reporting and role controls sit in higher tiers. |
| [EssayGrader.ai](https://www.essaygrader.ai/pricing) | Basic is free with 100 essays/month and a 1,000-word limit. Lite is listed at US$6.99/month for 100 essays with a 2,000-word limit; Pro at US$14.99/month for 350 essays/3,500 words; Premium at US$34.99/month for 800 essays/8,000 words. | Submission count and word allowance are made visible together. |
| [AI Grader App](https://www.aigraderapp.com/purchase/) | Free lists 10 grading credits/month and a 1,000-word essay limit. Its annual-billing display lists Pro at US$16/month with 200 grading credits and Premium Plus at US$39.99/month with 500 grading credits and a 10,000-word limit. | Explicit grading credits and word limits make consumption easier to understand. The provider also lists separate AI-tool credits. |
| [Class Companion](https://classcompanion.com/plans) | Free teacher plan; school/district partnership pricing is quote-based. The higher institutional layer lists LMS integration, standards alignment, premium insights, custom learning plans, administrative features and usage analytics. | Free educator entry point; organisational administration, analytics and integrations form a distinct institutional offer. |
| [Turnitin Feedback Studio](https://guides.turnitin.com/hc/en-us/articles/37985974637453-How-to-purchase-a-turnitin-subscription) | Feedback Studio/Similarity subscriptions are institution-oriented; individuals are directed to institution access, while institutions request a size/needs-based quote. | Mature assessment operations use controlled institutional access, rubric/feedback workflows and managed administration rather than a simple universal consumer price. |

**Interpretation:** retain a useful free entry point; disclose submission/word boundaries before use; separate course access from grading usage; and reserve delegated administration/analytics for an appropriately protected staff layer. Do not copy AI-only competitor prices as the benchmark for human grading. Recheck all vendor pages before any future commercial comparison because public plans can change.

## 3. Learner access and free-first journey

The approved intended journey is:

1. Learner creates an account and verifies the email address before accessing real learner records or paid entitlements.
2. Learner completes the initial diagnostic without payment.
3. Learner receives the complete Evaluation Report without payment; it remains free permanently (₹999 is stated reference value only).
4. Learner receives a meaningful free starter remedial lesson/activity and can continue using designated free practice/resources.
5. The learner may purchase the standalone ₹1,999 Remedial Course entitlement or receive an approved complimentary course grant.
6. Human grading is separately optional: the account may use its one complimentary task entitlement when its server-calculated requirement is exactly one credit, then purchase a 2-, 5-, 10- or 20-credit package for additional human-reviewed submissions.

The complete report and already-earned report/history remain visible even when the Remedial Course entitlement is inactive or grading credits are exhausted. A paywall may appear when the learner chooses a paid course or paid grading action; it must not block the free diagnostic, complete report, free starter activity, free resources or access already purchased.

### 3.1 Course entitlements and Admin grants

- Routine, valid paid purchases should activate their course entitlement automatically after trusted payment confirmation. An Admin should not manually approve every paying learner.
- The internal Admin dashboard is a future staff feature for approved operational work: view entitlement state, grant/revoke complimentary pilot access, resolve account/course access issues, review payment/credit exceptions, issue approved refunds/adjustments, review capacity and view attributable audit history.
- A manual grant must include learner, course/pathway, scope, grantor, reason, start/end or expiry where relevant, timestamp and audit event.
- Admin permissions remain narrowly delegated. Admin does not inherit owner, grader or private academic-QA rights. Privileged actions require the specified strong authentication (AAL2 where applicable) and server/database enforcement.
- Owner-only QA and role-management functions stay separate. The future dashboard is not the existing Owner staff-invitation UI and is not part of current Phase 1C security code.

## 4. Historical Standard/Premium/Elite effort-tier proposal — superseded 6 November 2026

The launch proposal uses the existing ₹399 unit-credit hypothesis and the following transparent tier defaults:

| Tier | Indicative expected response length | Default predicted grader time | Credits | Indicative value at ₹399/credit |
|---|---:|---:|---:|---:|
| **Standard** | Up to 50 words | Up to 20 minutes | **1** | **₹399** |
| **Premium** | 51–150 words | 21–40 minutes | **2** | **₹798** |
| **Elite** | 151–350 words | 41–60 minutes | **3** | **₹1,197** |
| **Custom / multi-task** | More than 350 words, more than 60 minutes, or a genuinely multi-task/multi-part paper | Individually estimated | **4+** | **₹1,596+**, disclosed before acceptance |

The word bands are initial task-classification guidance, not a learner input cap or a guarantee that every task in the band has the same workload. A 50-word task requiring extensive evidence comparison or several independent rubric judgements may be Premium. An unusually straightforward task may be reclassified only where the rubric and validated time evidence support it. Academic authorship must not manipulate response targets merely to fit a cheaper tier.

### 4.1 Historical time-only credit calculation — superseded 6 November 2026

The default effort unit is 20 predicted grader minutes:

**required credits = max(1, ceiling(predicted grader minutes / 20))**

The system assigns the visible tier from the resulting credit count: 1 = Standard, 2 = Premium, 3 = Elite, 4+ = Custom. The predicted minutes must come from approved task/rubric metadata calibrated against observed grader time. Task complexity inputs include number of independently graded parts, rubric criteria, evidence references, comparison requirements and document-handling effort. The server determines the final tier/credits; the browser cannot supply or alter them.

A task's expected word band is one input to its predicted grading minutes. Actual submitted word count does not automatically trigger a post-submission debit. The expected/ideal counter remains guidance only. A separate paper or additional task requires a separate, explicit task/credit confirmation before acceptance.

### 4.2 Historical ₹399-per-credit package hypotheses — superseded 6 November 2026

Retain the Master Brief's current pack hypothesis pending pilot calibration:

| Pack | Price | Unit rate | Initial availability |
|---|---:|---:|---|
| 2 credits | ₹798 | ₹399/credit | May be purchasable at launch |
| 5 credits | ₹1,995 | ₹399/credit | May be purchasable at launch |
| 10 credits | ₹3,990 | ₹399/credit | Display as planned only; unavailable until fulfilment capacity justifies it |
| 20 credits | ₹7,980 | ₹399/credit | Display as planned only; unavailable until fulfilment capacity justifies it |

No launch bulk discount. Credits expire after six months under the proposed commercial terms. A human regrade of a revised response consumes another credit only when the learner explicitly requests that additional grading. Study Lab and human-grading credits are separate. The one-time free grading entitlement is a **single Standard (one-credit-equivalent) task per learner account**, not one per topic, course, grade or pathway.

₹199/month Study Lab and ₹399/credit remain price hypotheses. Recalibrate before public sale using observed grader time, actual task mix, payment fees, applicable taxes, fulfilment cost, refunds and willingness-to-pay evidence. A public price change requires a new versioned commercial decision; do not retrospectively change the price/credits of an accepted task.

## 5. Curriculum-frequency algorithm and internal credit allocation

### 5.1 Build a separate dataset for every curriculum/grade/course

Do not combine CBSE, IB and Cambridge response distributions. Do not transfer one grade's distribution to another. For each selected curriculum, grade/year/stage, subject, syllabus/examination series and task family:

1. Collect at least five recent official past/sample assessments or validated school assessments where available and rights permit. Record source, date/series, curriculum mapping and the actual written-response task inventory.
2. Count one independently gradable written-response prompt as one task. Do not count each rubric criterion, evidence observation, subskill or marking bullet as a separate response.
3. Exclude selected-response items that do not require human grading. Keep objective task volume separately for product planning.
4. Record for each written task: expected response range/ideal words, accepted/expected word basis, marks, independently graded parts, rubric criteria, response mode, predicted grader minutes, word-based credits, time-based credits and final maximum credits.
5. Use a median of paper-level distributions where possible so one unusually long or short paper does not dominate the curriculum. When fewer than five comparable assessments are available, mark the estimate provisional; do not fabricate a representative frequency.

The user's example that CBSE may feature approximately 50-word responses frequently is a research hypothesis for the specific CBSE grade/subject/examination format, not a universal CBSE rule. Validate it against the selected official materials before using it to forecast usage. Board-specific frequency must never modify the universal price tariff.

### 5.2 Calculate frequency and marks independently

For every independently gradable response task, calculate its approved word-based credit requirement using the current universal tariff and its predicted-time credit requirement using the calibrated task/rubric metadata. Record marks share separately as an academic cross-check. Task frequency and marks share are separate observations; do not use marks alone as a proxy for grader effort.

### 5.3 Translate observed task mix into expected credit demand

For each sampled task, apply the approved credit calculation separately:

- Word credits: 1–50 words=1; 51–150=2; 151–350=3; above 350 add one credit per complete or partial 100-word band.
- Time credits: max(1, ceiling(predicted grader minutes/20)).
- Required credits per task: max(word credits,time credits), never their sum.

Sum the resulting task-level credits over the representative assessment sample to forecast total demand, average credits per independently gradable task, and the expected split of tasks across credit bands. Keep the sample source, curriculum/grade/series, task count and assumptions. A board's observed response mix is for demand and capacity forecasting only; it never changes the tariff or makes comparable work cost differently across boards. Do not use the old Standard/Premium/Elite consumption-share calculation as the current tariff.

### 5.4 Recalibration

Recalculate when a syllabus/exam pattern changes, after the first meaningful sample of real task usage, and periodically when enough completed submissions exist. Compare predicted grader minutes with actual median and upper-quartile times by task family. Adjust task metadata and the next policy version where evidence warrants it. Do not retrospectively change the price/credits of an accepted submission.

## 6. Typed-response and PDF pricing safeguards

- Retain the existing live typed-response counter (current/ideal, such as 38/50 or 59/50). The ideal target and expected range guide the learner; they do not impose a hard limit. Never truncate, reject or block a response solely because it exceeds the target.
- The 10 MB and 10-page PDF restrictions are file-safety limits, not credit tiers or billable page counts. A ten-page file is not automatically ten credits.
- Use PDF.js for digital text extraction first. Scanned-page OCR is a later external-processing path subject to synthetic quality evaluation, regional/privacy/consent approval and free-quota limits. OCR failure or quota exhaustion must preserve the original accepted PDF and allow the approved manual-grading fallback.
- Do not charge more solely because a response is a PDF, because OCR was required, because a file has more pages within the allowed cap, or because its raw word count exceeds the ideal target.
- Calculate required credits from the approved task scope/rubric, server-derived accepted word count and predicted grader minutes before submission. Display the word/time calculations, final credits, price, scope, rubric and SLA before acceptance.
- If a learner chooses an additional independent task or a broader paper, require an explicit revised task/price/credit confirmation before accepting it. No retrospective or surprise debit is permitted.

## 7. Turnaround, capacity and free grading

**One shared launch target applies:** 24 elapsed hours from server-accepted human-grading submission to first publication of final human feedback. This applies to the one-time complimentary one-credit task entitlement and all other accepted human-grading work. The approved 24-hour flagship target supersedes the earlier 72-hour free / 48-hour paid Standard / separate urgent 24-hour pricing proposal. There is no separate ₹199 urgent-grading add-on at initial launch. Reconsider differentiated SLAs only after real fulfilment evidence and a new Founder decision.

Initial Founder-as-sole-grader controls remain:
- Up to 30 paid human-grading submissions per month.
- Target no more than two newly accepted paid submissions per day.
- Up to four complimentary one-credit graded tasks per week, subject to the one-time per-account entitlement and capacity safeguards.
- Do not accept work unless the 24-hour target can be met; preserve the learner's draft and unspent entitlement/credit when capacity is full.
- Do not sell credit packs or course promises beyond demonstrated fulfilment capacity. Show availability before acceptance.

## 8. Payments, ledger and provider boundaries

- Use an append-only, server-authoritative credit ledger. It records purchase, reservation, consumption, release, refund, expiry and manual adjustment; it does not store a mutable client-controlled balance.
- Maintain standalone Remedial Course entitlements separately from human-grading credits and their append-only ledger.
- A payment transaction must be matched to a trusted provider confirmation/webhook or an explicitly approved, auditable manual reconciliation process before entitlements/credits are activated.
- Payment provider, email provider, merchant terms, refund policy, tax treatment and checkout architecture are not selected by this approval. Compare low/no-cost options first; no provider account, hosted resource, paid API, charge or live payment is authorised here.
- Normal public learner registration must require verified email before real learner-record access and paid entitlements are enabled. Staff invitation acceptance already has separate verified-email controls. Local synthetic CI may use preconfirmed fixtures without sending real email; no transactional email provider is selected or configured.
- The future Admin console may issue only approved complimentary grants, corrections and refunds with reason and audit trail. Routine valid paid purchases activate automatically after trusted confirmation; manual Admin approval is for exceptions, not every paying learner.

## 9. Integrated implementation order

Keep the approved sequence intact; commercial implementation must not delay the permanently free Diagnostic/Report:

1. **Close Phase 1C:** both synchronized Phase 1C-F races pass exact-head synthetic CI. Complete the final Phase 1C exit-criteria and documentation review; Phase 1D remains blocked until that closeout is accepted.
2. **Phase 1D:** implement private PDF storage/file controls, signature/MIME/size/page checks, assignment-scoped access, original-file integrity, PDF.js extraction and transcript-version controls.
3. **Phase 1E:** implement and test database/file-object backups, restore, deletion and retention workflows.
4. **Phase 1F:** complete synthetic-data security acceptance, threat-model closure and required runbooks.
5. **Shared flagship submission/grading workflow:** implement typed/PDF submission, the existing grader queue with approved search/filter management, rubric-based human grading and human-only publication, the 24-hour SLA, then timer/analytics and synthetic/pilot validation.
6. **Cycle 1 Diagnostic/Report:** after the shared flagship feature is built and pilot-validated, author and validate the approved Grade 9 / IB MYP Year 4 Diagnostic and teacher pack, build the complete permanently free Evaluation Report, and verify accessibility/calculations.
7. **Mandatory whole-website copy cleanup:** complete the existing route/state copy sweep immediately after Diagnostic/Report validation and before remedial-content authoring.
8. **Remedial Course:** implement the standalone ₹1,999 full course, five 60-minute sessions by default; extend to six/seven only where evaluation analytics justify it. Preserve a meaningful free starter activity.
9. **Commercial systems:** implement versioned catalogue/campaigns, append-only credit ledger, separate course entitlements, trusted payment confirmation, idempotent fulfilment, refund/reversal and audited Admin exceptions. Only the two approved Diwali offers may be configured.
10. **Branded staging and final acceptance:** verify the complete synthetic journey on the dedicated staging host on `gradioprep.com`, backed by an isolated hosted synthetic backend, before final Diagnostic/Report acceptance. Hosted resources, DNS/custom-domain mapping and paid usage each require separate approval.

## 10. Recalibration and launch metrics

Measure by curriculum, grade, task family and tier:
- response-task frequency and marks share;
- expected versus actual grader minutes (median and upper quartile);
- expected versus actual credits consumed;
- Standard/Premium/Elite mix and average credits per learner;
- credit pack purchase/use/refund/expiry and unused balances;
- free diagnostic/report completion and report-to-starter activity conversion;
- free-starter-to-Remedial-Course conversion and course completion;
- one-free-task use, paid-grading conversion and repeat purchases;
- 24-hour target compliance, queue age, capacity-full events and regrades;
- contribution after payment fees, taxes, refunds and fulfilment costs.

Use real pilot data only after the applicable privacy, hosted-service and limited-pilot approvals. Until then, use official public assessment materials, synthetic tasks and time studies with fictional work.

## 11. Explicit implementation status

As at 6 November 2026, the following are **specified/approved but not yet implemented**: server-side word/time credit calculation and reservation; versioned catalogue/campaign; append-only credit ledger; purchase/checkout/payment confirmation and idempotent fulfilment; separate course entitlements; future commercial Admin exception/grant/refund console; normal learner email-confirmation delivery/configuration; queue search/filter UI; full learner PDF/typed submission and grader workflow; timer/analytics; Diagnostic/Report experience; full Remedial Course and paid/free access enforcement.

Existing building blocks include local synthetic Auth and staff-invitation verified-email acceptance; typed-response counters and server-generated word-count metadata; conceptual required_credits in the logical data model; accepted submission and human-feedback backend records; the approved 24-hour target; and the 10 MB/10-page PDF design. Those are not proof that the commercial/credit system or PDF storage/OCR is live.

No document in this policy authorises hosted provisioning, paid spend, external processing, real learner data, a payment transaction, PR merge, production deployment, DNS change or public launch. Apply the separate approval gates in docs/FREE_FIRST_INFRASTRUCTURE_AND_COST_POLICY.md.

## 11. Founder-approved commercial and credit-policy amendment — 6 November 2026

This section supersedes all conflicting earlier price, package, promotional and credit-band hypotheses in this document.

### Approved catalogue

| Product | Price / stated value | Entitlement |
|---|---:|---|
| Diagnostic + complete Evaluation Report | ₹999 stated value; free | Diagnostic and full report; no paywall |
| Standalone Remedial Course | ₹1,999 | Full course |
| 2-credit pack | ₹1,500 | 2 human-grading credits |
| 5-credit pack | ₹3,750 | 5 human-grading credits |
| Gold Plan | ₹7,500 | 10 human-grading credits |
| Platinum Plan | ₹14,999 | 20 human-grading credits |

Smaller packs are proportionate to the Platinum reference rate (₹14,999 / 20 = ₹749.95 per credit), rounded to whole rupees. No other pack or discount is approved.

### Only two Diwali offers

1. Free Diagnostic + complete Evaluation Report (stated value ₹999).
2. Platinum Diwali bundle: 20 grading credits plus the full Remedial Course (standalone reference price ₹1,999) for ₹7,999. Combined stated component value: ₹16,998.

No discounted Gold, bonus credits, coupon, additional bundle or other Diwali offer. Record exact campaign start/end timestamps and India-time display before activation. The report remains free after the campaign; ₹999 is not a future paywall.

### Universal board-neutral credit schedule

Identical for IB, Cambridge and CBSE. Board, curriculum, grade or school identity cannot change the price of comparable work.

| Accepted response length | Word-based credits |
|---|---:|
| 1–50 words | 1 |
| 51–150 words | 2 |
| 151–350 words | 3 |
| 351–450 words | 4 |
| 451–550 words | 5 |
| 551–650 words | 6 |
| 651–750 words | 7 |
| 751–850 words | 8 |
| 851–950 words | 9 |
| 951–1,050 words | 10 |
| Each further complete or partial 100-word band above 350 | +1 credit |

For positive word counts above 350: word-based credits = 3 + ceiling((word_count − 350) / 100). For 1–350 words use the fixed bands. Zero-word submissions are not accepted as graded responses. Use a server-defined tokenizer/version; never trust client word counts.

### Grading-time safeguard

Time-based credits = max(1, ceiling(predicted grader minutes / 20)). Final required credits = max(word-based credits, time-based credits). Do not add the estimates; they approximate the same work and summing them double-charges. Display both calculations and the final requirement before acceptance; reserve only after learner confirmation. Snapshot word count, tokenizer version, predicted minutes, both calculations, final credits and policy version. No retrospective debit.

Example: 1,000 words = 3 + ceiling(650/100) = 10 word credits. 180 predicted minutes = ceiling(180/20) = 9 time credits. Final = 10 credits, not 19, identically across all three boards. Board-specific frequency research is for demand forecasting only and cannot alter the tariff.

Credits pay for human grading; course access is separate. Platinum Diwali fulfilment grants both 20 credits and Remedial Course access. Standalone course grants course access only. These are approved policies, not implemented checkout or ledger functionality. Before paid sales implement versioned server-side catalogue/campaign rules, append-only credit ledger, separate course entitlements, trusted payment confirmation, idempotent bundle fulfilment, refunds/reversals and audited Admin exceptions. Store INR in integer paise. This docs amendment authorises no provider, live charge, paid subscription or hosted resource.
