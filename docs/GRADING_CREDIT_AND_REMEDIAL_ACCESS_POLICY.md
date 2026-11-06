# Grading Credit, Curriculum-Frequency and Remedial Access Policy

**Version:** 1.0  
**Approved:** 4 November 2026  
**Status:** Founder-approved product and commercial specification. Documentation-only approval; no payment service, credit ledger, entitlement service, Admin dashboard, email provider or paid integration has been provisioned or implemented.  
**Authority:** This is the single detailed source of truth for grading-credit allocation, curriculum-frequency analysis, learner free/paid access, customer entitlements and commercial sequencing. The Master Brief records binding product decisions; DATA_MODEL records logical records; the flagship PDF/grading specification records task/PDF workflow; and the diagnostic standard governs the diagnostic/remedial cycle.

## 1. Governing product and pricing principles

1. The initial diagnostic and its complete evaluation report are free to the learner. The report must not be hidden behind a registration-to-payment conversion gate or a paywall.
2. Provide a meaningful free starter remedial lesson/activity after the report. Keep selected lessons, practice questions, explanations, syllabus discovery and other designated free resources available before 100 subscribers.
3. The full personalised remedial programme is a separate course entitlement. The proposed Study Lab subscription is ₹199/month and remains a price hypothesis, not validated willingness-to-pay evidence. A Founder/authorised Admin may grant a complimentary entitlement to a pilot cohort or an individual.
4. Human grading is a separate optional paid service. A learner may have Study Lab course access without grading credits, or grading credits without a Study Lab subscription where the task is otherwise available.
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
3. Learner receives the complete evaluation report, including skill evidence, confidence, priorities and next steps, without payment.
4. Learner receives a meaningful free starter remedial lesson/activity and can continue using designated free practice/resources.
5. The learner may purchase the proposed Study Lab subscription (₹199/month hypothesis) to unlock the full personalised remedial programme and the Study Lab resource set.
6. Human grading is separately optional: the account may use its one free Standard task entitlement, then purchase grading-credit packs for additional human-reviewed submissions.

The complete report and already-earned report/history remain visible even when Study Lab is inactive or grading credits are exhausted. A paywall may appear when the learner chooses a paid course or paid grading action; it must not block the free diagnostic, complete report, free starter activity, free resources or access already purchased.

### 3.1 Course entitlements and Admin grants

- Routine, valid paid purchases should activate their course entitlement automatically after trusted payment confirmation. An Admin should not manually approve every paying learner.
- The internal Admin dashboard is a future staff feature for approved operational work: view entitlement state, grant/revoke complimentary pilot access, resolve account/course access issues, review payment/credit exceptions, issue approved refunds/adjustments, review capacity and view attributable audit history.
- A manual grant must include learner, course/pathway, scope, grantor, reason, start/end or expiry where relevant, timestamp and audit event.
- Admin permissions remain narrowly delegated. Admin does not inherit owner, grader or private academic-QA rights. Privileged actions require the specified strong authentication (AAL2 where applicable) and server/database enforcement.
- Owner-only QA and role-management functions stay separate. The future dashboard is not the existing Owner staff-invitation UI and is not part of current Phase 1C security code.

## 4. Human-grading credit tiers

The launch proposal uses the existing ₹399 unit-credit hypothesis and the following transparent tier defaults:

| Tier | Indicative expected response length | Default predicted grader time | Credits | Indicative value at ₹399/credit |
|---|---:|---:|---:|---:|
| **Standard** | Up to 50 words | Up to 20 minutes | **1** | **₹399** |
| **Premium** | 51–150 words | 21–40 minutes | **2** | **₹798** |
| **Elite** | 151–350 words | 41–60 minutes | **3** | **₹1,197** |
| **Custom / multi-task** | More than 350 words, more than 60 minutes, or a genuinely multi-task/multi-part paper | Individually estimated | **4+** | **₹1,596+**, disclosed before acceptance |

The word bands are initial task-classification guidance, not a learner input cap or a guarantee that every task in the band has the same workload. A 50-word task requiring extensive evidence comparison or several independent rubric judgements may be Premium. An unusually straightforward task may be reclassified only where the rubric and validated time evidence support it. Academic authorship must not manipulate response targets merely to fit a cheaper tier.

### 4.1 Server-side credit calculation

The default effort unit is 20 predicted grader minutes:

**required credits = max(1, ceiling(predicted grader minutes / 20))**

The system assigns the visible tier from the resulting credit count: 1 = Standard, 2 = Premium, 3 = Elite, 4+ = Custom. The predicted minutes must come from approved task/rubric metadata calibrated against observed grader time. Task complexity inputs include number of independently graded parts, rubric criteria, evidence references, comparison requirements and document-handling effort. The server determines the final tier/credits; the browser cannot supply or alter them.

A task's expected word band is one input to its predicted grading minutes. Actual submitted word count does not automatically trigger a post-submission debit. The expected/ideal counter remains guidance only. A separate paper or additional task requires a separate, explicit task/credit confirmation before acceptance.

### 4.2 Credit packs and existing price hypotheses

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
4. Record for each written task: expected response range/ideal words, marks, independently graded parts, rubric criteria, response mode, estimated grader minutes, assigned tier and credits.
5. Use a median of paper-level distributions where possible so one unusually long or short paper does not dominate the curriculum. When fewer than five comparable assessments are available, mark the estimate provisional; do not fabricate a representative frequency.

The user's example that CBSE may feature approximately 50-word responses frequently is a research hypothesis for the specific CBSE grade/subject/examination format, not a universal CBSE rule. Validate it against the selected official materials before using it to set a tier share.

### 5.2 Calculate frequency and marks independently

For tier i (Standard, Premium, Elite):

**Fᵢ = tasks in tier i / all independently gradable written-response tasks**

**Mᵢ = marks assigned to tier i / all marks assigned to written-response tasks**

Store both as percentages. Fᵢ measures how often a learner encounters that response type; Mᵢ is an academic-importance cross-check. Do not use marks alone as a proxy for grader effort and do not force the two percentages to match.

### 5.3 Translate task mix into expected credit allocation

Use tier credits Cᵢ (1, 2 or 3) to calculate a curriculum's expected credit demand:

**Expected credits for N tasks in tier i = N × Fᵢ × Cᵢ**

**Share of expected credit consumption for tier i = (Fᵢ × Cᵢ) / Σ(Fⱼ × Cⱼ)**

This produces two different outputs:
- **Task mix:** what proportion of written-response tasks are Standard, Premium and Elite.
- **Credit mix:** what proportion of the learner's expected grading-credit use comes from each tier.

Illustrative example only: if a verified curriculum sample has 60% Standard, 30% Premium and 10% Elite tasks, then 100 representative tasks would consume an estimated 60 + 60 + 30 = **150 credits**. The expected credit-consumption mix would be 40% Standard, 40% Premium and 20% Elite. This example is a calculation demonstration, not an assertion about CBSE, IB or Cambridge.

Use the credit mix to forecast typical learner pack requirements, likely pack depletion, sales messaging and fulfilment capacity. Show learners a simple example of how many credits a specific task costs; keep source frequencies, calibration data and internal commercial assumptions out of learner reports.

### 5.4 Recalibration

Recalculate when a syllabus/exam pattern changes, after the first meaningful sample of real task usage, and periodically when enough completed submissions exist. Compare predicted grader minutes with actual median and upper-quartile times by task family. Adjust task metadata and the next policy version where evidence warrants it. Do not retrospectively change the price/credits of an accepted submission.

## 6. Typed-response and PDF pricing safeguards

- Retain the existing live typed-response counter (current/ideal, such as 38/50 or 59/50). The ideal target and expected range guide the learner; they do not impose a hard limit. Never truncate, reject or block a response solely because it exceeds the target.
- The 10 MB and 10-page PDF restrictions are file-safety limits, not credit tiers or billable page counts. A ten-page file is not automatically ten credits.
- Use PDF.js for digital text extraction first. Scanned-page OCR is a later external-processing path subject to synthetic quality evaluation, regional/privacy/consent approval and free-quota limits. OCR failure or quota exhaustion must preserve the original accepted PDF and allow the approved manual-grading fallback.
- Do not charge more solely because a response is a PDF, because OCR was required, because a file has more pages within the allowed cap, or because its raw word count exceeds the ideal target.
- Set the task tier and credits from the approved task scope/rubric/predicted grader minutes before submission. Display that requirement, price, scope, rubric and SLA before acceptance.
- If a learner chooses an additional independent task or a broader paper, require an explicit revised task/price/credit confirmation before accepting it. No retrospective or surprise debit is permitted.

## 7. Turnaround, capacity and free grading

**One shared launch target applies:** 24 elapsed hours from server-accepted human-grading submission to first publication of final human feedback. This applies to complimentary Standard work and all paid tiers when accepted. The approved 24-hour flagship target supersedes the earlier 72-hour free / 48-hour paid Standard / separate urgent 24-hour pricing proposal. There is no separate ₹199 urgent-grading add-on at initial launch. Reconsider differentiated SLAs only after real fulfilment evidence and a new Founder decision.

Initial Founder-as-sole-grader controls remain:
- Up to 30 paid human-grading submissions per month.
- Target no more than two newly accepted paid submissions per day.
- Up to four complimentary Standard graded tasks per week.
- Do not accept work unless the 24-hour target can be met; preserve the learner's draft and unspent entitlement/credit when capacity is full.
- Do not sell credit packs or course promises beyond demonstrated fulfilment capacity. Show availability before acceptance.

## 8. Payments, ledger and provider boundaries

- Use an append-only, server-authoritative credit ledger. It records purchase, reservation, consumption, release, refund, expiry and manual adjustment; it does not store a mutable client-controlled balance.
- Maintain course/subscription entitlements separately from human-grading credits and their ledger.
- A payment transaction must be matched to a trusted provider confirmation/webhook or an explicitly approved, auditable manual reconciliation process before entitlements/credits are activated.
- Payment provider, email provider, merchant terms, refund policy, tax treatment and checkout architecture are not selected by this approval. Compare low/no-cost options first; no provider account, hosted resource, paid API, charge or live payment is authorised here.
- Normal public learner registration must require verified email before real learner-record access and paid entitlements are enabled. Staff invitation acceptance already has separate verified-email controls. Local synthetic CI may use preconfirmed fixtures without sending real email; no transactional email provider is selected or configured.
- The future Admin console may issue only approved complimentary grants, corrections and refunds with reason and audit trail. Routine valid paid purchases activate automatically after trusted confirmation; manual Admin approval is for exceptions, not every paying learner.

## 9. Integrated implementation order

Keep the current approved engineering sequence intact; the commercial layer must not delay the free diagnostic/report:

1. **Finish Phase 1C:** current verified D slice is complete; implement 1C-E audit/workflow integrity and 1C-F adversarial acceptance, close any remaining authorization gaps and reconcile the current security model.
2. **Phase 1D:** private PDF storage, signature/MIME/size/page checks, assignment-scoped access, original-file integrity, PDF.js extraction and transcript-version controls.
3. **Phase 1E:** tested database and file-object backups, restore, deletion and retention workflows.
4. **Phase 1F:** synthetic-data security acceptance, threat-model closure and required runbooks. No Phase 1C exit may be inferred from a single passing slice.
5. **Shared flagship user/staff experience:** learner typed/PDF submission, teacher queue/workspace, rubric-based human grading and publication, timer and elapsed-time analytics. Apply this policy's task metadata for predicted grading time, tier and credit requirement. Complete privacy, external-processing and capacity gates before real data.
6. **Cycle 1 free diagnostic/report:** after the shared feature is built and pilot-validated, author and validate the approved MYP Year 4 diagnostic and teacher pack, build the free diagnostic and complete evaluation report, and verify accessibility/calculations.
7. **Mandatory whole-website copy cleanup:** complete the existing route/state copy sweep immediately after diagnostic/report validation and before any remedial content authoring.
8. **Remedial course:** author the five-session default (extend to six/seven only where justified), free starter activity, personalised pathway, and fresh outcome check. Preserve the report and starter activity regardless of paid status.
9. **Commercial entitlement layer, before selling paid access:** implement ordinary learner email verification, course entitlements, credit ledger, payment confirmation/checkout, approved Admin dashboard and access/credit exception workflow. The learner-facing Admin dashboard and customer payment UI are not Phase 1C security work.
10. **Controlled launch:** retain the free resources; initially expose only 2- and 5-credit packs; enforce the one-free-Standard-task entitlement and capacity limits; measure real grading time, task frequency, pack usage, conversion, refunds and contribution. Cambridge Grade 6 remains blocked until Cycle 1 completes and the Founder directs the transition.

Where implementation order must be parallelised, shared data contracts and security design may be prepared earlier, but do not begin paid sales or lock the diagnostic/report behind checkout. Do not request unnecessary Preview reviews: only a new concrete, substantial learner/staff-visible feature warrants Founder inspection.

## 10. Recalibration and launch metrics

Measure by curriculum, grade, task family and tier:
- response-task frequency and marks share;
- expected versus actual grader minutes (median and upper quartile);
- expected versus actual credits consumed;
- Standard/Premium/Elite mix and average credits per learner;
- credit pack purchase/use/refund/expiry and unused balances;
- free diagnostic/report completion and report-to-starter activity conversion;
- starter-to-full-course conversion and Study Lab retention;
- one-free-task use, paid-grading conversion and repeat purchases;
- 24-hour target compliance, queue age, capacity-full events and regrades;
- contribution after payment fees, taxes, refunds and fulfilment costs.

Use real pilot data only after the applicable privacy, hosted-service and limited-pilot approvals. Until then, use official public assessment materials, synthetic tasks and time studies with fictional work.

## 11. Explicit implementation status

As at 4 November 2026, the following are **specified/approved but not yet implemented**: three-tier task pricing; curriculum-frequency calculation; physical credit ledger and credit reservation/consumption; payment/checkout; course entitlement and Study Lab paywall; Admin entitlement dashboard; normal learner email-confirmation delivery/configuration; full diagnostic/report learner experience; full remedial course and free/paid access enforcement.

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
