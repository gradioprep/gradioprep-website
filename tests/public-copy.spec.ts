import { expect, test } from "@playwright/test";

const ibCourse = "/pathways/ib-myp/language-and-literature";
const lowerSecondaryCourse = "/pathways/cambridge-lower-secondary/english";
const plannedUnits = [1, 2, 3];

const allConfiguredCurriculumRoutes = [
  ...["year-1", "year-2", "year-3", "year-4", "year-5"].flatMap(level => [
    `${ibCourse}/${level}`,
    ...plannedUnits.map(unit => `${ibCourse}/${level}/units/unit-${unit}`),
  ]),
  ...["stage-7", "stage-8", "stage-9"].flatMap(stage => [
    `${lowerSecondaryCourse}/${stage}`,
    ...plannedUnits.map(unit => `${lowerSecondaryCourse}/${stage}/units/unit-${unit}`),
  ]),
];

const publicRoutes = [...new Set([
  "/",
  "/dashboard",
  "/pathways",
  ibCourse,
  ...allConfiguredCurriculumRoutes,
  `${ibCourse}/year-1/units/unit-1/lesson`,
  "/lesson",
  lowerSecondaryCourse,
  "/pathways/cambridge-igcse/first-language-english",
  "/pathways/cambridge-igcse/first-language-english/grade-9-equivalent-band",
  "/pathways/cambridge-igcse/first-language-english/grade-10-equivalent-band",
  "/questions",
  "/assessment",
  "/account",
])];

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
  /approval confirmed by project owner/i,
  /academic (?:content )?review (?:passed|pending|complete)/i,
  /candidate(?:[- ]unverified)? (?:year|objective|mapping|strand)/i,
  /internal (?:comment|note|review|status|instruction)/i,
  /test (?:environment|account|data)/i,
  /synthetic (?:student|learner|test) (?:account|data)/i,
  /development (?:environment|status)/i,
  /release (?:status|gate|candidate)/i,
];

test.describe("public website copy rules", () => {
  for (const viewport of [
    { name: "desktop", width: 1440, height: 1000 },
    { name: "mobile", width: 390, height: 844 },
  ]) {
    test(`all configured public routes contain no internal notes at ${viewport.name} width`, async ({ page }) => {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      for (const route of publicRoutes) {
        await page.goto(route);
        await expect(page.locator("body")).toBeVisible();
        const text = await page.locator("body").innerText();
        const title = await page.title();
        const accessibleText = await page.locator("body *").evaluateAll(nodes =>
          nodes.flatMap(node =>
            ["aria-label", "aria-description", "title", "placeholder", "alt", "value"]
              .map(name => node.getAttribute(name))
              .filter((value): value is string => Boolean(value))
          )
        );
        const metadataText = await page.locator('meta[name="description"], meta[property^="og:"]')
          .evaluateAll(nodes => nodes.map(node => node.getAttribute("content")).filter(Boolean));
        const renderedCopy = [title, text, ...accessibleText, ...metadataText].join("\n");
        for (const pattern of internalCopyPatterns) {
          expect(renderedCopy, `${pattern} found on ${route} at ${viewport.name} width`).not.toMatch(pattern);
        }
      }
    });
  }

  test("dashboard shows useful empty states instead of fictional learner activity", async ({ page }) => {
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

  test("all shipped JavaScript and CSS assets exclude internal academic and development material", async ({ page }) => {
    await page.goto(`${ibCourse}/year-1/units/unit-1/lesson`);
    const assetUrls = await page.locator("script[src], link[rel~='stylesheet'][href]").evaluateAll(nodes =>
      nodes.map(node => node instanceof HTMLScriptElement ? node.src : (node as HTMLLinkElement).href).filter(Boolean)
    );
    const scriptUrls = assetUrls.filter(url => /\.m?js(?:$|\?)/i.test(new URL(url).pathname));
    const stylesheetUrls = assetUrls.filter(url => /\.css(?:$|\?)/i.test(new URL(url).pathname));
    expect(scriptUrls.length, "the public learner route should load its JavaScript bundle").toBeGreaterThan(0);
    expect(stylesheetUrls.length, "the public learner route should load its stylesheet").toBeGreaterThan(0);

    const downloadedAssets: string[] = [];
    for (const url of assetUrls) {
      const response = await page.request.get(url);
      expect(response.ok(), `public client asset should load: ${url}`).toBeTruthy();
      downloadedAssets.push(await response.text());
    }
    const bundleText = downloadedAssets.join("\\n");
    const internalAssetPatterns = [
      /\bprototype\b/i,
      /academic content review passed/i,
      /academic review passed for the content preview/i,
      /academic lead \(approval confirmed by project owner/i,
      /candidate-unverified/i,
      /candidate year 1 strands/i,
      /pilot preview for early myp learners/i,
      /planning slot only/i,
      /verify programme documents and approve unit sequence before release/i,
      /do not claim official curriculum mapping or release/i,
      /remainingReleaseChecks/i,
      /sourceScopeNote/i,
      /sourceBriefUrl/i,
      /officialObjectiveCodes/i,
      /candidateObjectiveMappings/i,
      /reviewerLabel/i,
      /academicReviewer/i,
      /academicReviewedAt/i,
      /releaseApprovedBy/i,
      /contentRightsNote/i,
      /unitContentPlans/i,
      /getUnitReadinessGates/i,
      /\bphase 1[abcde]\b/i,
      /development environment/i,
      /test environment/i,
      /synthetic data/i,
      /TODO:/i,
      /TEMP_COPY_/i,
    ];
    for (const pattern of internalAssetPatterns) {
      expect(bundleText, `internal content or metadata ${pattern} must not be shipped in client assets`).not.toMatch(pattern);
    }
  });
});
