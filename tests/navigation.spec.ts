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
  { path: ibUnitOne, heading: /How writers and creators shape meaning.*review draft/i },
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
    await expect(page.getByRole("heading", { name: /How writers and creators shape meaning.*review draft/i })).toBeVisible();

    await page.getByRole("button", { name: /Continue to Unit 1 review draft/ }).click();
    await expect(page).toHaveURL(new RegExp(`${pilotLesson}$`));
    await expect(page.getByRole("heading", { name: /Notice the choice\. Explain the effect\./i })).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(new RegExp(`${ibUnitOne}$`));
    await expect(page.getByRole("heading", { name: /How writers and creators shape meaning.*review draft/i })).toBeVisible();

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

test.describe("MYP Year 1 Unit 1 version 2 review preview", () => {
  test("labels the revised unit as pending review and shows the original paired artefacts", async ({ page }) => {
    const pageErrors: string[] = [];
    page.on("pageerror", (error) => pageErrors.push(error.message));

    await page.goto(pilotLesson);
    await expect(page.getByText(/Unit 1 version 2 is awaiting founder review/i)).toBeVisible();
    await expect(page.getByText(/Version 1's preview approval does not automatically apply to this revision/i)).toBeVisible();

    await expect(page.getByRole("heading", { name: "Original practice passage" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "A LIGHT ON EVERY LAST JOURNEY" })).toBeVisible();
    const posterPhoto = page.getByRole("img", { name: /Photograph of several people waiting at an illuminated bus stop on a rainy night/i });
    await expect(posterPhoto).toBeVisible();
    await expect.poll(
      () => posterPhoto.evaluate((image) => {
        const photo = image as HTMLImageElement;
        return photo.complete && photo.naturalWidth > 0;
      }),
      { timeout: 15000 },
    ).toBe(true);
    await expect(page.getByText(/Photograph by Berk Aktas.*Pexels, 2023/i)).toBeVisible();
    await expect(page.getByText(/Notice how the illuminated shelter and waiting passengers contrast/i)).toBeVisible();
    await expect(page.getByText(/Choice — point to an exact word, phrase or visual feature/i)).toBeVisible();
    await expect(page.getByText(/At sunrise, the empty platform shone silver/i)).toBeVisible();

    expect(pageErrors, "the Unit 1 preview should not produce browser JavaScript errors").toEqual([]);
  });

  test("entry observation and fresh-text exit check can be reviewed without scoring", async ({ page }) => {
    await page.goto(pilotLesson);

    await page.getByLabel("Your first observation").fill("I notice the word 'sighed'. It literally describes the bus.");
    await page.getByRole("button", { name: /Review my observation/i }).click();
    await expect(page.getByText("Check your starting point")).toBeVisible();
    await expect(page.getByText(/I have identified a precise detail I can point to/i)).toBeVisible();

    await page.getByLabel("Your exit response").fill("The word 'silver' may make the platform seem still or cool at sunrise.");
    await page.getByRole("button", { name: /Review exit response/i }).click();
    await expect(page.getByText("Self-review checklist")).toBeVisible();
    await expect(page.getByText(/This is a checklist, not a mark or a saved assessment/i)).toBeVisible();
  });
});

test("Unit 1 detail and level views show the v2 review gate instead of inheriting v1 approval", async ({ page }) => {
  await page.goto(ibUnitOne);

  await expect(page.getByRole("heading", { name: /How writers and creators shape meaning.*review draft/i })).toBeVisible();
  await expect(page.getByText(/Awaiting review of version 2/i)).toBeVisible();
  await expect(page.getByText(/Version 1 approval does not transfer to this revision/i)).toBeVisible();
  await expect(page.getByRole("button", { name: /Continue to Unit 1 review draft/i })).toBeVisible();

  await page.goto(ibYearOne);
  await expect(page.getByText(/Unit 1 version 2 awaiting founder review/i)).toBeVisible();
  await expect(page.getByText(/Academic review passed for pilot preview v1/i)).toHaveCount(0);
});
