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
  { path: ibUnitOne, heading: /How writers shape meaning.*pilot preview/i },
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

    await page.getByRole("button", { name: /Explore Year 1/ }).click();
    await expect(page).toHaveURL(new RegExp(`${ibYearOne}$`));
    await expect(page.getByRole("heading", { name: /Year 1 learning plan/i })).toBeVisible();

    await page.getByRole("button", { name: /View pilot unit/ }).click();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));
    await expect(page.getByRole("heading", { name: /How writers shape meaning.*pilot preview/i })).toBeVisible();

    await page.getByRole("button", { name: /Open learner lesson preview/ }).click();
    await expect(page).toHaveURL(new RegExp(`${pilotLesson}$`));
    await expect(page.getByRole("heading", { name: /Notice the choice\. Explain the effect\./i })).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));
    await expect(page.getByRole("heading", { name: /How writers shape meaning.*pilot preview/i })).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(new RegExp(`${ibYearOne}$`));
    await expect(page.getByRole("heading", { name: /Year 1 learning plan/i })).toBeVisible();

    await page.goForward();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));

    await page.getByRole("button", { name: "Year 1" }).click();
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
});
