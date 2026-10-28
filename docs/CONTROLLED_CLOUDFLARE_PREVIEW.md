# Controlled Cloudflare Preview Setup

**Status (27 October 2026):** The controlled preview is deployed and verified in Cloudflare. The previous failure was limited to the PR-comment step; the application build and preview creation had succeeded. After a narrowly scoped GitHub token-permission fix, controlled preview run [#13](https://github.com/gradioprep/gradioprep-website/actions/runs/40523592690) passed, and Build check [#244](https://github.com/gradioprep/gradioprep-website/actions/runs/40523592680) passed the TypeScript/Vite build and 17/17 Chromium tests on verification commit `064b1a2eea832a9b8ee495226c36cc8a52358c34`. The preview URL is [https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev](https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev). At the post-run-#13 Cloudflare API check, `deployed_on` was `2026-10-27T14:42:19Z` UTC. This records that verification checkpoint rather than promising the deployment timestamp will remain unchanged after later preview runs. This is an unreleased interface-testing preview, not production or student-ready content.

## What this preview does

- Uses Cloudflare Worker Previews with `npx wrangler preview`, not the production deployment command `npx wrangler deploy`.
- Runs for same-repository pull requests targeting `main`, but never for forked PRs. Manual dispatch is restricted to the approved `preview/cambridge-stage-7-unit-1-accessibility` branch.
- Creates or updates a separate `pr-<number>` Preview for each pull request and posts its URL to the PR when deployment succeeds. Manual runs on the approved branch use `pr-15`, so they update the same Preview as PR #15. The current workflow keeps the default token permission at `contents: read`, grants `pull-requests: write` only to the preview job, and keeps the cleanup job read-only.
- Builds the application before attempting to upload the preview.
- Deletes the pull-request Preview when that PR is closed, if credentials are configured.
- Does not merge a PR, change the production deployment, change the main-domain DNS, or require the custom domain to be connected to Cloudflare.

Cloudflare Worker Preview URLs are public unless Cloudflare Access is configured. Workers.dev Preview URLs include a no-index response header, but this is not access control. Do not use the preview for personal data, real student records, confidential material or public release of the candidate unit. The visible unit status must continue to say that it is not released or student-ready.

## One-time setup required from the repository owner

The workflow needs two **repository Actions secrets**. Do not put tokens in code, commit them to Git, or send them in chat.

### 1. Create a restricted Cloudflare API token

1. Sign in at the Cloudflare dashboard.
2. Open **Account API Tokens** for the account that owns the `gradioprep-website` Worker.
3. Select **Create Token**.
4. Choose the **Edit Cloudflare Workers** template/policy.
5. Restrict it to the account that owns this Worker. Do not grant DNS/zone permissions; this preview uses the existing Worker’s Preview URL and does not need `gradioprep.com`.
6. Create the token and copy the value once. Keep it private.

### 2. Add the two GitHub repository secrets

1. Open https://github.com/gradioprep/gradioprep-website.
2. Select **Settings**.
3. In the left menu, open **Secrets and variables**, then **Actions**.
4. Under **Repository secrets**, select **New repository secret**.
5. For the first secret, enter the name `CLOUDFLARE_API_TOKEN` and paste the Cloudflare token as its value. Select **Add secret**.
6. Select **New repository secret** again.
7. Enter the name `CLOUDFLARE_ACCOUNT_ID` and use this account ID: `5c4eae400d4e9a23eab0cb34840943b7`. Select **Add secret**.

Do not send the API token to anyone. GitHub hides secret values after saving them.

### 3. Run the preview workflow

1. In the GitHub repository, select **Actions**.
2. Select **Controlled Cloudflare Worker preview** from the workflow list.
3. Select **Run workflow**.
4. In the branch menu, choose `preview/cambridge-stage-7-unit-1-accessibility`.
5. Select the green **Run workflow** button.

Open the resulting run. If it succeeds, the workflow summary and the draft PR conversation will show the Preview URL. If it fails, use the run’s error message to identify the missing permission or configuration issue. Do not change production settings to work around a Preview failure.

## Future operation

Commits pushed to a same-repository pull request trigger another build and update that PR's Preview. The normal production Worker remains unchanged. When a PR is closed, the cleanup job deletes its Preview if the required credentials are available.

Cloudflare documentation:
- Worker Previews: https://developers.cloudflare.com/workers/previews/
- GitHub Actions authentication and API tokens: https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/
- Cloudflare Access for Workers: https://developers.cloudflare.com/workers/configuration/cloudflare-access/


## Verification record — 27 October 2026

- **Failure identified:** Controlled preview run #9 built the app and created the Cloudflare Preview, then failed while calling the GitHub Issues comments API to read the PR conversation. GitHub returned HTTP 403, `Resource not accessible by integration`, with the effective accepted permissions header showing `issues=read; pull_requests=read`.
- **Fix committed:** commit `6b7c4e961482785d3170cb5debbcd7f15a22cee7` scopes `pull-requests: write` to the preview job only. The workflow-level default is `contents: read`; the cleanup job remains `contents: read`.
- **Workflow verification:** [Controlled preview run #13 passed](https://github.com/gradioprep/gradioprep-website/actions/runs/40523592690), including the “Update the pull request with the preview URL” step. The current URL is posted in the [PR #15 conversation](https://github.com/gradioprep/gradioprep-website/pull/15).
- **Build/browser verification:** [Build check #244 passed](https://github.com/gradioprep/gradioprep-website/actions/runs/40523592680); the TypeScript/Vite build succeeded and all 17 Chromium tests passed, including six Stage 7 preview checks and 11 existing navigation tests. Browser tests use locally served Wrangler assets.
- **Hosted preview verification:** Cloudflare's API returned HTTP 200 and confirmed the `pr-15` preview URL `https://pr-15-gradioprep-website.wandering-scene-1822.workers.dev`, with `deployed_on` timestamp `2026-10-27T14:42:19Z` UTC at the post-run-#13 API check. The remote page could not be fetched directly from this execution environment for an independent visual smoke check; founder visual review is still outstanding.
- **Safety boundary:** No PR was merged, no production deploy was run, and no DNS changes were made. The preview is public unless Cloudflare Access is enabled. Do not use it for student/personal data or present this candidate as released/student-ready.

## Content and release gate update — 28 October 2026

The founder confirms that human review of the exact Cambridge Stage 7 Unit 1 v1.3 learner content is complete and approved. Under the risk-based content process, the short platform-original passage and tasks have passed the internal originality/provenance screen: the initial phrase screen and eight supplemental searches found no exact passage-level match in returned public results. This status is not a formal legal opinion or guarantee of exclusivity. The current text-only unit uses no third-party image or excerpt.

The preview warning banner is kept aligned with these facts. Still open are the current full Cambridge framework/version and additional objective mapping, manual accessibility and hosted-page visual review, and explicit release approval. The public Worker Preview remains interface-testing-only, unmerged and not student-ready. No personal/student information belongs on it.
