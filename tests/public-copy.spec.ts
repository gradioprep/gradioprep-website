import { expect, test } from "@playwright/test";

const publicRoutes = [
  "/",
  "/dashboard",
  "/pathways",
  "/pathways/ib-myp/language-and-literature",
  "/pathways/ib-myp/language-and-literature/year-1",
  "/pathways/ib-myp/language-and-literature/year-1/units/unit-1",
  "/pathways/ib-myp/language-and-literature/year-1/units/unit-1/lesson",
  "/pathways/cambridge-lower-secondary/english",
  "/pathways/cambridge-igcse/first-language-english",
  "/questions",
  "/assessment",
  "/account",
];

const internalCopyPatterns = [
  /\bprototype\b/i,
  /academic content review passed/i,
  /assessment feedback prototype/i,
  /design prototype/i,
  /early build/i,
  /working name/i,
  /\bdemo\b/i,
  /fictional/i,
  /planning preview/i,
  /pilot preview/i,
  /\bpreview\b/i,
  /not released/i,
  /unverified/i,
  /placeholder/i,
  /local test/i,
  /synthetic data/i,
  /initial pa delivery slice/i,
  /partial, unscored/i,
  /release readiness/i,
  /not final rubric/i,
  /candidate objective/i,
  /do not infer syllabus coverage/i,
  /\bphase 1[abcde]\b/i,
  /internal review/i,
  /editor note/i,
  /development environment/i,
];

test.describe("public website copy rules", () => {
  for (const viewport of [
    { name: "desktop", width: 1440, height: 1000 },
    { name: "mobile", width: 390, height: 844 },
  ]) {
    test(`public routes contain no internal notes at ${viewport.name} width`, async ({ page }) => {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      for (const route of publicRoutes) {
        await page.goto(route);
        await expect(page.locator("body")).toBeVisible();
        const text = await page.locator("body").innerText();
        const title = await page.title();
        const accessibleText = await page.locator("body *").evaluateAll(nodes =>
          nodes.flatMap(node =>
            ["aria-label", "title", "placeholder"].map(name => node.getAttribute(name)).filter(Boolean)
          )
        );
        const renderedCopy = [title, text, ...accessibleText].join("\n");
        for (const pattern of internalCopyPatterns) {
          expect(renderedCopy, `${pattern} found on ${route} at ${viewport.name} width`).not.toMatch(pattern);
        }
      }
    });
  }

  test("dashboard shows empty states instead of fictional learner activity", async ({ page }) => {
    await page.goto("/dashboard");
    await expect(page.getByText("Your completed work will appear here.")).toBeVisible();
    await expect(page.getByText("Complete your first Preliminary Assessment or practice activity to start building your learning record.")).toBeVisible();
    await expect(page.getByText("Your recent activity will appear here.")).toBeVisible();
    await expect(page.getByText("12", { exact: true })).toHaveCount(0);
    await expect(page.getByText("28", { exact: true })).toHaveCount(0);
  });

  test("Evaluation Report screen does not show example marks or an illustrative rubric", async ({ page }) => {
    await page.goto("/assessment");
    await expect(page.getByRole("heading", { name: "Your Evaluation Report." })).toBeVisible();
    await expect(page.getByText("Your learning insights will appear here.")).toBeVisible();
    await expect(page.getByText(/not final rubric|placeholder criterion|illustrative excerpts/i)).toHaveCount(0);
  });

  test("learner JavaScript bundles exclude internal academic review and release notes", async ({ page }) => {
    await page.goto("/pathways/ib-myp/language-and-literature/year-1/units/unit-1/lesson");
    const scriptUrls = await page.locator("script[src]").evaluateAll(nodes =>
      nodes.map(node => (node as HTMLScriptElement).src).filter(Boolean)
    );
    expect(scriptUrls.length).toBeGreaterThan(0);
    const downloadedScripts: string[] = [];
    for (const url of scriptUrls) {
      const response = await page.request.get(url);
      expect(response.ok(), `public script asset should load: ${url}`).toBeTruthy();
      downloadedScripts.push(await response.text());
    }
    const bundleText = downloadedScripts.join("\\n");
    const internalPatterns = [
      /Academic content review passed/i,
      /Academic review passed for the content preview/i,
      /candidate-unverified/i,
      /Candidate Year 1 strands/i,
      /Pilot preview for early MYP learners/i,
      /Planning slot only/i,
      /verify programme documents and approve unit sequence before release/i,
      /Do not claim official curriculum mapping or release/i,
      /remainingReleaseChecks/i,
    ];
    for (const pattern of internalPatterns) {
      expect(bundleText, `internal metadata ${pattern} must not be shipped in learner assets`).not.toMatch(pattern);
    }
  });
});
