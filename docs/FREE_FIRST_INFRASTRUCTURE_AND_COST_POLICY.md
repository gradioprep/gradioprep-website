# Free-First Infrastructure, Subscription and Cost-Control Policy

> **Current execution checkpoint — 7 November 2026 (authoritative active status; older dated milestone records remain historical):** PR #22 is open, draft and unmerged on `feature/phase-1b-local-auth-api`; pre-reconciliation head `2cf7304b8d2ae6b3c8363dd68e97d608682bd0bb`. **Phase 1C is complete** at code/test head `fcd1f7c2f0b4a91d5f7900ee91b046dc6debc481`; exact-head Actions [#42072385858](https://github.com/gradioprep/gradioprep-website/actions/runs/42072385858) passed 494 pgTAP assertions across 14 SQL files, TypeScript/Worker/Vite builds and 31/31 Playwright tests. **Phase 1D is verified** at code/test head `251e9633e2b1be32fbb0abebb9b1bc0dc2bf07ef`; exact-head Actions [#42189786947](https://github.com/gradioprep/gradioprep-website/actions/runs/42189786947) passed 519 pgTAP assertions across 15 SQL files, builds, 31/31 Playwright tests and cleanup. **Phase 1E backup/recovery/deletion is partial and unverified:** migrations `20261106000200_phase1e_account_deletion_ledger.sql` and `20261106000300_phase1e_account_closure_retention_plan.sql` exist; paired tests `account_deletion_ledger.test.sql` (`plan(35)`) and `account_closure_retention.test.sql` (`plan(47)`) have not run. Exact-head Actions [#42208654326](https://github.com/gradioprep/gradioprep-website/actions/runs/42208654326), attempt 4, failed before runner assignment: job `127868964485` has runner ID 0, no runner name and no steps; **no SQL tests executed**. This is not a SQL pass or failure. Windows WSL2 Ubuntu is installed; Linux user is `gradioprep`. Docker Desktop/WSL integration, Linux-side checkout and repository-scoped self-hosted runner remain pending. The current workflow still targets `ubuntu-latest` until a separate reviewed change. **All five GitHub spending budgets remain blocked.** Statements below dated before this checkpoint are historical evidence; their former active/next-step status is superseded here.
**Version:** 1.0  
**Decision date:** 3 November 2026  
**Status:** Founder-approved operating and budget policy.  
**Authority:** This policy records the Founder's direction that free resources are the default and paid services are used only when demonstrably unavoidable. It is binding on the Master Project Brief, Phase 0 decision register, Phase 1 specification, Phase 1A execution plan, Data Model, flagship feature plan and Preview/release process.

## 1. Binding budget objective

1. **Free-first is the core operating model.** Use suitable free plans, free quotas, open-source software and local development tools by default. Do not choose a paid service merely because it is more convenient or has a larger quota.
2. **Twelve-month target:** from 3 November 2026 through 2 November 2027, target **US$0 in recurring infrastructure subscriptions and paid API usage**. This excludes the domain already purchased and the user's existing computer/internet arrangements. This is a budget target, not a promise that every free tier can satisfy every production reliability requirement.
3. **100-subscriber review point:** when GradiPrep reaches 100 or more active subscribers, review service capacity, reliability, support, recovery and actual usage. This is a review trigger, **not an automatic instruction to upgrade**. Continue using free services where they still meet requirements.
4. **Unavoidable exception before 100 subscribers:** a paid service may be proposed earlier only where documented tests show that no suitable free/open-source/local option can satisfy an essential security, privacy, data-residency, recovery, availability, capacity or product requirement. Explain the failed free alternatives and the consequences of not paying.
5. **Approval before charges:** before any paid subscription, paid API call, paid add-on, usage overage, billing-method activation for a service, spend-cap removal or automatic upgrade, provide the exact provider, reason, alternatives, current price, estimated monthly recurring cost, variable usage formula, taxes/currency caveats and any one-off charges. Obtain the Founder's explicit approval for that specific spend. No approval is implied by a provider being listed in the approved architecture.
6. Never enable automatic upgrades, uncontrolled paid overage, automatic spend-cap increases or paid fallback routing. Configure budgets/spend caps and service-level quota stops wherever the provider supports them. If the free quota is exhausted, fail safely and use the approved manual fallback; do not silently incur a charge.

## 2. Implementation approval versus provisioning and spending

The Founder has approved the phased implementation plan and the Phase 0 architecture/provider choices. Work that stays within that approved scope and sequence is authorised to proceed through implementation, draft PRs, automated checks and public synthetic-data Preview verification; do not repeatedly ask the Founder to re-approve an implementation step already included in the approved plan.

The Founder has also explicitly approved Phase 1B local Supabase coding and verification using fictional/synthetic data only. That does not authorise hosted resource provisioning, paid usage, real learner records, sending learner content to external processors, PR merge, production deployment, DNS changes or public launch. Those actions remain separate gates because they create billing, privacy, security or release consequences.

A review of a completed implementation checkpoint is evidence-based milestone acceptance, not a request to re-authorise the approved plan. Ask for a new decision only when the proposed work changes the approved scope/provider/region/data handling, requires a charge or new hosted resource, begins real-data processing, or reaches a separately gated merge/production/release action.

## 3. Approved providers: free-first assessment and known limits

All figures below are a dated reference snapshot checked on 3 November 2026. They are not a purchase authorisation, invoice quote or guarantee that the same quotas will remain available. Recheck official provider terms, exact region, taxes, account-level limits and current pricing immediately before activation.

| Service and approved role | Free-first option and important limits | Paid option / cost exposure | Operating rule |
|---|---|---|---|
| **Supabase** — single Auth, PostgreSQL and primary private Storage project in Mumbai (`ap-south-1`) | Free: US$0; 500 MB database, 1 GB file storage, 50,000 monthly active users, 5 GB egress plus 5 GB cached egress; projects may pause after 7 days of low activity; no automatic downloadable database backups. Manual logical database exports using Supabase CLI are available. | Pro starts at US$25/month for the first project; usage, compute, storage and egress may add charges. Daily database backups are retained for 7 days on Pro, but do not include Storage API objects. PITR is a separate paid add-on; the published 7-day option is approximately US$100/month and requires at least Small compute. | Free is the starting candidate, not an unconditional approval for live data. Pro is not mandatory solely because it is named in an older document. Real learner records remain blocked until availability, capacity, backup/restore and privacy gates pass on the selected plan. If Free cannot meet them, compare a tested free approach, a weaker explicitly accepted recovery commitment, and the exact paid option before deciding. |
| **Cloudflare Workers** — current website host and lightweight API | Free: 100,000 Worker requests/day and 10 ms CPU per HTTP invocation; static asset requests are free and unlimited. | Workers Paid minimum US$5/month/account; includes 10 million requests and 30 million CPU milliseconds/month; usage above those allowances is billed. | Keep the current application on Free while measured traffic and CPU stay within limits. Static assets remain the preferred delivery path. No upgrade merely for convenience. |
| **Cloudflare R2** — secondary encrypted file-object backup only | Standard storage: 10 GB-month, 1 million Class A and 10 million Class B operations/month; internet egress is free. | Standard storage above the allowance is US$0.015/GB-month; operation overages are separately charged. | Use only as the already-selected secondary backup candidate, not primary app storage or a second database. Its location hint is best-effort and does not guarantee India residency. No real learner objects until transfer, residency, key custody and privacy gates pass. |
| **Azure Document Intelligence Read** — scanned-page OCR | F0: up to 500 pages/month; 4 MB max document size, 2-page analysis limit and 1 request/second. The approved 10 MB/10-page upload cap is a product cap; if F0 is used, process eligible page images individually under the provider limit. | S0 is usage-priced per page; exact Central India price and tax must be quoted before activation. | Use digital text extraction through PDF.js first. Apply OCR only to pages that need it. Hard-stop at the free quota and fall back to teacher review of the original PDF. No automatic S0 upgrade. |
| **Cloudflare Workers AI** — ten teacher-only feedback suggestions | 10,000 Neurons/day free allocation. If the daily allowance is exhausted, do not assume further inference is free. | To exceed the free allocation, Workers Paid is required; the published AI rate is US$0.011 per 1,000 Neurons above the allowance, in addition to the Workers Paid plan minimum. | Use only after synthetic quality evaluation and external-processing approval. At quota exhaustion, use manual teacher feedback. Never auto-publish AI text. |
| **GitHub Actions** — CI builds and tests | Target: trusted repository-scoped self-hosted WSL2 Linux runner for local Supabase checks; self-hosted runner job minutes are not billed as GitHub-hosted Actions minutes. | Artifact/cache storage may still use quota or incur charges; local PC, electricity and internet remain costs. GitHub-hosted minutes remain subject to included allowances and overage rules. | Keep all five GitHub spending budgets blocked. Current workflow remains `runs-on: ubuntu-latest` until a separate security-reviewed change. |
| **Key management** — encryption key custody for backups | No vendor or paid key-management product has been selected. Evaluate platform-supported or suitable free options, operational recovery and key separation first. | AWS KMS was only a candidate: a customer-managed key is listed at US$1/key/month, plus applicable request charges. | AWS KMS is not approved or required by this policy. Do not provision it unless a specific security design demonstrates the need and the Founder approves the exact cost. |
| **Email delivery and other optional APIs** | No separate paid email provider or other paid API is selected. Assess included provider capability and suitable free options first. | Any provider may have recurring or metered charges. | No new provider or charge without a cost comparison and explicit approval. |

The indicative monthly base prices above are not additive requirements. In particular, Supabase Pro, Workers Paid, PITR, AWS KMS, Azure S0 and paid email are not a bundle and must not be activated by default.

## 4. Reliability, capacity and safe degradation

Free-tier limits do not constitute an uptime SLA, production backup guarantee or unlimited service. “Free-first” must not be used to waive security or data-protection requirements.

Before accepting real learner records or PDF submissions:

- Measure expected database growth, file size, monthly submission volume, egress, OCR pages, AI usage, concurrency and CI minutes against the actual current free limits.
- Implement capacity warnings before quotas are reached and enforce hard limits before any charge can occur.
- Test database export/restore and original-file backup/restore as separate recovery paths. Supabase database backups do not include Storage API file objects.
- On Supabase Free, design and test scheduled/manual CLI database exports and a separate reviewed backup for file objects; define operator, encryption, access, retention, restore and deletion. A successful database dump alone is not a full restore.
- Treat Supabase Free inactivity pausing as an availability risk. Do not attempt to bypass provider policy with artificial traffic. Verify whether expected legitimate activity reliably avoids pausing; otherwise do not claim continuous availability.
- Keep accepted original PDFs safe when extraction/OCR/AI is unavailable or quota is reached. Teacher review of the original is the fallback. Do not destroy an accepted submission or silently charge for processing.
- If these safeguards cannot meet the Founder-approved service and recovery requirements at zero cost, keep real-data acceptance blocked until the Founder chooses between a revised tested service commitment and the exact unavoidable paid option.

The numeric RTO/RPO values in the Phase 1A document are proposals only. They are not Founder-approved service promises and must not be used as a hidden reason to buy PITR, KMS or another paid product.

## 5. Approval gates that remain separate

The approved implementation plan does not waive the following:
- Hosted Supabase or other hosted infrastructure provisioning, including a free-tier resource, where the project records require a provisioning decision.
- Paid services, subscriptions, paid usage, billing changes or overages.
- Real learner data, live authentication accounts, learner PDFs or production records.
- External processing by OCR, AI or backup providers; exact regional, privacy, contract, guardian-consent and deletion reviews remain mandatory.
- Cross-region or cross-border transfer of learner data or backup objects.
- PR merge, production deployment, DNS/custom-domain changes and public launch.

These are not repeated approvals of the plan. They are approvals for materially different actions with separate security, privacy, billing or release effects.

## 6. Review and change control

Review provider terms and usage at least quarterly, before each new hosted integration, before the first real-data pilot and when subscriber count reaches 100. Also review earlier if any free quota approaches its hard limit or reliability/recovery testing fails. Update this policy and every dependent source-of-truth record together when a provider, price, quota or decision changes.

No assistant, developer or automation may infer spending authority from this plan, a listed vendor, an estimate, a quota warning or the 100-subscriber review point.

## 7. Official references checked 3 November 2026

- Supabase pricing: https://supabase.com/pricing
- Supabase billing and free-plan pausing: https://supabase.com/docs/guides/platform/billing-on-supabase and https://supabase.com/kb/faqs/platform/free-project-pausing
- Supabase Free-plan manual backups: https://supabase.com/kb/faqs/platform/free-plan-backups
- Supabase database backups and Storage API exclusion: https://supabase.com/docs/guides/platform/backups
- Supabase PITR pricing and compute requirement: https://supabase.com/docs/guides/platform/manage-your-usage/point-in-time-recovery
- Cloudflare Workers limits and pricing: https://developers.cloudflare.com/workers/platform/limits/ and https://developers.cloudflare.com/workers/platform/pricing/
- Cloudflare R2 pricing: https://developers.cloudflare.com/r2/pricing/
- Cloudflare Workers AI pricing: https://developers.cloudflare.com/workers-ai/platform/pricing/
- Azure Document Intelligence limits: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/service-limits?view=doc-intel-4.0.0
- Azure Document Intelligence pricing: https://azure.microsoft.com/en-us/pricing/details/document-intelligence/
- GitHub Actions included usage and billing: https://docs.github.com/en/billing/reference/product-usage-included and https://docs.github.com/en/billing/concepts/product-billing/github-actions
- AWS KMS pricing (candidate reference only): https://aws.amazon.com/kms/pricing/

**No provisioning or spending action is authorised by this policy itself.**

## Approved cost and feature additions — 6 November 2026

Build submission search/filter using existing PostgreSQL, measured indexes and existing Worker APIs. No paid search service, second database or separate application. Use bounded query parameters, permission-scoped server filtering and stable pagination; add indexes only when synthetic query plans/load tests justify them.

Develop catalogue, credit formula, ledger and course entitlements locally with synthetic data. Store INR prices in integer paise; keep prices/campaigns versioned and server-authoritative. No payment provider, paid subscription, live payment or hosted resource is activated by this documentation amendment. A no-monthly-fee payment provider may still charge transaction fees.

Approved catalogue: free Diagnostic + complete report (₹999 stated value); standalone Remedial Course ₹1,999; 2 credits ₹1,500; 5 credits ₹3,750; Gold 10 credits ₹7,500; Platinum 20 credits ₹14,999. Only Diwali offers: free Diagnostic/report and Platinum 20 credits plus Remedial Course for ₹7,999. No other campaign discount or bundle. Full tariff is in the Grading Credit and Remedial Access Policy.


## 7. Project-specific Actions minute control — 7 November 2026

Exact-head run [#42208654326](https://github.com/gradioprep/gradioprep-website/actions/runs/42208654326), attempt 4, failed before runner assignment and executed no steps. The selected no-additional-GitHub-hosted-minutes route is a repository-scoped self-hosted WSL2 Linux runner, not enabling spending budgets. GitHub documents that self-hosted runner job minutes are not billed as GitHub-hosted Actions minutes; artifact/cache storage may still be subject to usage/billing. The current workflow still targets `ubuntu-latest`; a separate reviewed workflow change is required before the runner receives jobs. All five spending budgets remain blocked. See [GitHub Actions billing concepts](https://docs.github.com/en/actions/concepts/billing-and-usage) and [secure use of self-hosted runners](https://docs.github.com/en/actions/reference/security/secure-use).