import { expect, test } from "@playwright/test";

const ibYearOne = "/pathways/ib-myp/language-and-literature/year-1";
const ibUnitOne = `${ibYearOne}/units/unit-1`;
const pilotLesson = `${ibUnitOne}/lesson`;

const directRouteChecks: Array<{ path: string; heading: RegExp }> = [
  { path: "/pathways", heading: /Start with the right pathway/i },
  {
    path: "/pathways/ib-myp/language-and-literature",
    heading: /Language and Literature pathway/i,
  },
  { path: ibYearOne, heading: /Year 1 learning plan/i },
  { path: ibUnitOne, heading: /How writers and creators shape meaning.*review candidate/i },
  { path: pilotLesson, heading: /Notice the choice\. Explain the effect\./i },
  {
    path: "/pathways/cambridge-igcse/first-language-english/grade-9-equivalent-band",
    heading: /This route isn't available/i,
  },
  {
    path: "/pathways/cambridge-igcse/first-language-english/grade-10-equivalent-band",
    heading: /This route isn't available/i,
  },
];

test.describe("curriculum pathway URLs", () => {
  for (const route of directRouteChecks) {
    test(`direct link opens the correct screen: ${route.path}`, async ({ page }) => {
      const pageErrors: string[] = [];
      page.on("pageerror", (error) => pageErrors.push(error.message));

      await page.goto(route.path);
      await expect(page.getByRole("heading", { name: route.heading })).toBeVisible();
      expect(pageErrors, "the screen should not produce browser JavaScript errors").toEqual([]);
    });
  }

  test("pathway navigation keeps browser Back and Forward in sync with the page", async ({ page }) => {
    await page.goto("/pathways");

    await page.getByRole("button", { name: /Explore this pathway/ }).first().click();
    await expect(page).toHaveURL(/\/pathways\/ib-myp\/language-and-literature$/);
    await expect(page.getByRole("heading", { name: /Language and Literature pathway/i })).toBeVisible();

    await page.getByRole("button", { name: /Continue to Year 1/ }).click();
    await expect(page).toHaveURL(new RegExp(`${ibYearOne}$`));
    await expect(page.getByRole("heading", { name: /Year 1 learning plan/i })).toBeVisible();

    await page.getByRole("button", { name: /Continue to Unit 1/ }).click();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));
    await expect(page.getByRole("heading", { name: /How writers and creators shape meaning.*review candidate/i })).toBeVisible();

    await page.getByRole("button", { name: /Continue to pilot lesson preview/ }).click();
    await expect(page).toHaveURL(new RegExp(`${pilotLesson}$`));
    await expect(page.getByRole("heading", { name: /Notice the choice\. Explain the effect\./i })).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));
    await expect(page.getByRole("heading", { name: /How writers and creators shape meaning.*review candidate/i })).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(new RegExp(`${ibYearOne}$`));
    await expect(page.getByRole("heading", { name: /Year 1 learning plan/i })).toBeVisible();

    await page.goForward();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));

    await page.getByRole("button", { name: "Year 1", exact: true }).click();
    await expect(page).toHaveURL(new RegExp(`${ibYearOne}$`));
    await expect(page.getByRole("heading", { name: /Year 1 learning plan/i })).toBeVisible();
  });

  test("unavailable destinations provide a working route back to the catalogue", async ({ page }) => {
    await page.goto("/pathways/cambridge-igcse/first-language-english/grade-9-equivalent-band");
    await expect(page.getByRole("heading", { name: /This route isn't available/i })).toBeVisible();

    await page.getByRole("button", { name: /Return to pathways catalogue/ }).click();
    await expect(page).toHaveURL(/\/pathways$/);
    await expect(page.getByRole("heading", { name: /Start with the right pathway/i })).toBeVisible();
  });

  test("in-page navigation works across all supported levels and planned units", async ({ page }) => {
    const lowerSecondary = "/pathways/cambridge-lower-secondary/english";
    const stageSeven = `${lowerSecondary}/stage-7`;
    const unitOne = `${stageSeven}/units/unit-1`;
    const unitTwo = `${stageSeven}/units/unit-2`;
    const unitThree = `${stageSeven}/units/unit-3`;

    await page.goto(lowerSecondary);
    await page.getByRole("button", { name: /Continue to Stage 7/ }).click();
    await expect(page).toHaveURL(new RegExp(`${stageSeven}$`));
    await expect(page.getByRole("button", { name: /Back to Cambridge Lower Secondary · English/ })).toBeVisible();

    await page.getByRole("button", { name: /Continue to Unit 1/ }).click();
    await expect(page).toHaveURL(new RegExp(`${unitOne}$`));
    await page.getByRole("button", { name: /Continue to Unit 2/ }).click();
    await expect(page).toHaveURL(new RegExp(`${unitTwo}$`));

    await page.getByRole("button", { name: /Back to Unit 1/ }).click();
    await expect(page).toHaveURL(new RegExp(`${unitOne}$`));
    await page.getByRole("button", { name: /Continue to Unit 2/ }).click();
    await page.getByRole("button", { name: /Continue to Unit 3/ }).click();
    await expect(page).toHaveURL(new RegExp(`${unitThree}$`));
    await expect(page.getByText("No further unit is planned")).toBeVisible();
    await expect(page.getByText(/There are no additional unit slots/)).toBeVisible();

    await page.getByRole("button", { name: /Back to Unit 2/ }).click();
    await expect(page).toHaveURL(new RegExp(`${unitTwo}$`));
  });

  test("IGCSE offers a clear back button but never links to an unverified level", async ({ page }) => {
    await page.goto("/pathways/cambridge-igcse/first-language-english");
    await expect(page.getByRole("button", { name: /Back to Pathways catalogue/ })).toBeVisible();
    await expect(page.getByText("Levels are not available yet")).toBeVisible();
    await expect(page.getByText(/applicable IGCSE syllabus edition and level structure must be confirmed/)).toBeVisible();
    await expect(page.getByRole("button", { name: /Continue to/ })).toHaveCount(0);
  });

});


test.describe("IB MYP Year 1 Unit 1 version 4 learner guidance", () => {
  test("shows both registered literary extracts and question-specific response ranges", async ({ page }) => {
    await page.goto(pilotLesson);
    await expect(page.getByText(/The city clocks had only just gone three/)).toBeVisible();
    await expect(page.getByText(/The rabbit-hole went straight on like a tunnel/)).toBeVisible();
    await expect(page.getByText(/orange-lit platform/i)).toBeVisible();
    await expect(page.getByText(/bright shelter/i)).toHaveCount(0);
    await expect(page.getByText(/Expected response: 15–25 words/)).toBeVisible();
    await expect(page.getByText(/Expected response: 40–55 words/)).toBeVisible();
    await expect(page.getByText(/Expected response: 65–85 words/)).toBeVisible();
    await expect(page.getByText(/Expected response: 45–65 words/)).toHaveCount(2);
    await expect(page.getByText(/Expected response: 45–60 words/)).toBeVisible();
    await expect(page.getByText(/At the edge of the field, the last bus sighed/)).toHaveCount(0);
    await expect(page.getByText(/Shone silver/)).toHaveCount(0);
    await expect(page.getByText(/REVISED CONTENT CANDIDATE/)).toBeVisible();
    await expect(page.getByText(/not graded/i).first()).toBeVisible();
  });

  test("keeps response guidance visible without horizontal overflow at desktop and mobile widths", async ({ page }) => {
    for (const width of [360, 390, 768, 1024, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(pilotLesson);
      await expect(page.getByText(/Expected response: 15–25 words/)).toBeVisible();
      await expect(page.getByText(/Expected response: 40–55 words/)).toBeVisible();
      const dimensions = await page.evaluate(() => ({
        viewport: document.documentElement.clientWidth,
        content: document.documentElement.scrollWidth,
      }));
      expect(dimensions.content, `horizontal overflow at ${width}px viewport`).toBeLessThanOrEqual(dimensions.viewport);
    }
  });
});
