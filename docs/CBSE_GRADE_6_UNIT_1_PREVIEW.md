# CBSE Grade 6 Unit 1 — Controlled Interface Preview

**Status:** Unlinked draft preview for interface/accessibility testing only. Not a normal pathway, student release or production integration.

**Source content:** Approved learner-facing v1.0 “The Turning Sign” in the content candidate [PR #16](https://github.com/gradioprep/gradioprep-website/pull/16). This PR copies only the learner-safe source data needed to render the preview. It does not import or reproduce the separate teacher/editor answer pack.

**Direct route:** `/preview/cbse-grade-6/english/unit-1`. The route resolves only when the exact path segments match. No homepage, Pathways, lesson list, catalogue card or in-app navigation links to this route.

## Preview controls

- Visible status notice records content approval, partial source alignment, no unit-specific official CBSE objective code, and unreleased status.
- The page uses semantic landmarks and heading order, a keyboard skip link, labelled radio/textarea/select controls, visible focus indicators and responsive layouts.
- Response fields are held only in component state. There is no API submission, scoring, account save or browser persistence. The clear-all action resets all temporary responses.
- The current task source is original to the platform and has no external image or third-party passage. The teacher/editor answer pack is outside the preview module and learner-facing bundle.

## Verification scope

Playwright tests cover direct-route behaviour, absence of normal-navigation links, status/mapping boundaries, keyboard skip-link focus, accessible names and unique control IDs, reset behaviour, horizontal overflow at 320/390/768/1024 CSS-pixel widths, sampled text contrast and no teacher-only answer-key text. These automated checks are not a full WCAG audit or a substitute for manual keyboard, screen-reader and hosted-preview review.

The preview is publicly reachable if hosted on a public Workers.dev preview URL. Use fictional test responses only. Do not merge, enable normal learner navigation, or promote to production from this PR.

## Hosted preview deployment

The preview branch carries the existing least-privilege Controlled Cloudflare Worker preview workflow. For this approved branch it runs on pushes to `preview/cbse-grade-6-unit-1-accessibility` and uses the distinct Worker Preview name `pr-17`. It executes `npx wrangler preview`, not `npx wrangler deploy`; production Worker deployment, production DNS and the Cambridge `pr-15` preview are not changed. The generated Workers.dev preview is public unless Cloudflare Access is separately enabled. Use fictional test responses only.
