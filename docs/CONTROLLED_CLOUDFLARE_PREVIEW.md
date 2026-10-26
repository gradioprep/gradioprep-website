# Controlled Cloudflare Preview Setup

**Status (26 October 2026):** The preview workflow is committed to the draft code PR branch, and its application build succeeds. A hosted preview has **not** yet been deployed because the repository does not yet have the two required GitHub Actions secrets. The workflow intentionally skips the deployment when either secret is absent.

## What this preview does

- Uses Cloudflare Worker Previews with `npx wrangler preview`, not the production deployment command `npx wrangler deploy`.
- Runs for same-repository pull requests targeting `main`, but never for forked PRs. Manual dispatch is restricted to the approved `preview/cambridge-stage-7-unit-1-accessibility` branch.
- Creates or updates a separate `pr-<number>` Preview for each pull request and posts its URL to the PR when deployment succeeds. Manual runs use the stable name `cambridge-stage-7-unit-1-accessibility`.
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
