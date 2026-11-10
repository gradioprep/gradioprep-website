import { expect, test } from "@playwright/test";

const pilotLesson = "/pathways/ib-myp/language-and-literature/year-1/units/unit-1/lesson";

const responseFields = [
  { id: "myp-y1-u1-entry-response", target: 20, prompt: "myp-y1-u1-entry-prompt", range: "myp-y1-u1-entry-range", label: "Your first observation" },
  { id: "pilot-v3-q2-response", target: 50, prompt: "pilot-v3-q2-prompt", range: "pilot-v3-q2-range", label: "Your response" },
  { id: "pilot-v3-q3-response", target: 75, prompt: "pilot-v3-q3-prompt", range: "pilot-v3-q3-range", label: "Your response" },
  { id: "pilot-v3-q4-response", target: 55, prompt: "pilot-v3-q4-prompt", range: "pilot-v3-q4-range", label: "Your response" },
  { id: "pilot-v3-q5-response", target: 55, prompt: "pilot-v3-q5-prompt", range: "pilot-v3-q5-range", label: "Your response" },
  { id: "myp-y1-u1-exit-response", target: 50, prompt: "myp-y1-u1-exit-prompt", range: "myp-y1-u1-exit-range", label: "Your exit response" },
];

test.describe("MYP Year 1 Unit 1 live response word counters", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(pilotLesson);
  });

  test("shows the approved ideal target on each of the six typed-response fields", async ({ page }) => {
    for (const field of responseFields) {
      await expect(page.locator(`#${field.id}`)).toBeVisible();
      await expect(page.locator(`#${field.id}-word-count`)).toHaveText(`0/${field.target} words`);
      const describedBy = (await page.locator(`#${field.id}`).getAttribute("aria-describedby") ?? "").split(/\s+/);
      expect(describedBy).toContain(field.prompt);
      expect(describedBy).toContain(field.range);
      expect(describedBy).toContain(`${field.id}-word-count`);
      await expect(page.locator(`#${field.id}`)).toHaveAccessibleName(field.label);
      await expect(page.locator(`#${field.prompt}`)).toBeVisible();
      await expect(page.locator(`#${field.range}`)).toBeVisible();
      await expect(page.locator(`#${field.id}`)).not.toHaveAttribute("maxlength", /.+/);
    }
  });

  test("counts typing, paste, edits, deletion and clear without counting punctuation as words", async ({ page }) => {
    const field = page.locator("#myp-y1-u1-entry-response");
    const counter = page.locator("#myp-y1-u1-entry-response-word-count");

    await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.evaluate(async () => {
      await navigator.clipboard.writeText("Don't use well-known examples: 42.");
    });
    await field.focus();
    await page.keyboard.press("Control+V");
    await expect(counter).toHaveText("5/20 words");

    await field.pressSequentially(" now");
    await expect(counter).toHaveText("6/20 words");

    await field.fill("A revised response.");
    await expect(counter).toHaveText("3/20 words");

    await field.fill("");
    await expect(counter).toHaveText("0/20 words");
  });

  test("continues counting above the ideal target without limiting or blocking the response", async ({ page }) => {
    const response = Array.from({ length: 59 }, (_, index) => `word${index + 1}`).join(" ");
    const field = page.locator("#pilot-v3-q2-response");

    await field.fill(response);
    await expect(page.locator("#pilot-v3-q2-response-word-count")).toHaveText("59/50 words");
    await expect(field).toBeEnabled();
    await expect(field).not.toHaveAttribute("maxlength", /.+/);
    await expect(field).toHaveValue(response);
    await expect(page.getByRole("button", { name: "Review my thinking" }).nth(1)).toBeEnabled();
  });
});
