import { expect, test } from "@playwright/test";

const previewPath = "/preview/cambridge-lower-secondary/english/stage-7/unit-1";

test.describe("Cambridge Stage 7 Unit 1 controlled preview", () => {
  test("loads the draft learner content with clear unreleased status", async ({ page }) => {
    await page.goto(previewPath);

    await expect(page.getByRole("heading", { level: 1, name: "Read closely, infer and explain" })).toBeVisible();
    await expect(page.getByText("NOT RELEASED — NOT STUDENT-READY")).toBeVisible();
    await expect(page.getByRole("heading", { level: 2, name: "The Rain Gauge" })).toBeVisible();
    await expect(page.getByText("The applicable current Cambridge", { exact: false })).toHaveCount(0);
    await expect(page.getByText("At first, the rain fell softly against the library windows", { exact: false })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Work independently" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Try the thinking move independently" })).toBeVisible();
  });

  test("exposes a working skip link and keyboard-operable worked example", async ({ page }) => {
    await page.goto(previewPath);

    await page.keyboard.press("Tab");
    await expect(page.getByRole("link", { name: "Skip to lesson content" })).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(page).toHaveURL(/#s7-preview-main$/);
    await expect(page.locator("#s7-preview-main")).toBeFocused();

    const workedExample = page.getByText("Open the worked example");
    await workedExample.focus();
    await page.keyboard.press("Enter");
    await expect(page.getByText("Clues → inference → reason")).toBeVisible();
  });

  test("provides programmatically associated labels for every response field", async ({ page }) => {
    await page.goto(previewPath);

    const textareas = page.locator(".s7-preview-main textarea");
    await expect(textareas).toHaveCount(14);

    const fieldAudit = await textareas.evaluateAll((nodes) => nodes.map((node) => {
      const textarea = node as HTMLTextAreaElement;
      return {
        id: textarea.id,
        labelCount: textarea.labels?.length ?? 0,
        labelName: textarea.labels?.[0]?.textContent?.trim() ?? "",
        describedBy: textarea.getAttribute("aria-describedby"),
        descriptionExists: textarea.getAttribute("aria-describedby")
          ? Boolean(document.getElementById(textarea.getAttribute("aria-describedby")!))
          : false,
      };
    }));

    expect(fieldAudit.filter((field) => field.labelCount === 0 || !field.labelName).map((field) => field.id)).toEqual([]);
    expect(new Set(fieldAudit.map((field) => field.labelName)).size).toBe(14);
    expect(fieldAudit.filter((field) => field.describedBy && !field.descriptionExists).map((field) => field.id)).toEqual([]);
    const describedByIds = fieldAudit
      .filter((field) => field.describedBy)
      .map((field) => field.describedBy)
      .sort();
    expect(describedByIds).toEqual([
      "guided-a-prompt",
      "guided-b-prompt",
      "guided-c-prompt",
      "guided-d-prompt",
      "independent-1-prompt",
      "independent-2-prompt",
      "independent-3-prompt",
      "independent-4-prompt",
      "independent-5-prompt",
      "independent-6-prompt",
      "s7-exit-response-prompt",
    ].sort());
    expect(fieldAudit.find((field) => field.id === "guided-a")?.describedBy).toBe("guided-a-prompt");
    await expect(page.getByLabel("Your response — A. Find a fact")).toBeVisible();
    await expect(page.getByLabel("Your exit response")).toBeVisible();
    await expect(page.getByLabel("The strongest evidence I used today was…")).toBeVisible();
  });

  test("keeps the layout within narrow mobile and tablet viewports", async ({ page }) => {
    await page.goto(previewPath);

    for (const width of [320, 390, 768, 1024]) {
      await page.setViewportSize({ width, height: 844 });
      const dimensions = await page.evaluate(() => ({
        documentWidth: document.documentElement.scrollWidth,
        viewportWidth: document.documentElement.clientWidth,
        mainWidth: document.querySelector("main")?.getBoundingClientRect().width ?? 0,
      }));

      expect(dimensions.documentWidth, `document width at ${width}px`).toBeLessThanOrEqual(dimensions.viewportWidth);
      expect(dimensions.mainWidth, `main width at ${width}px`).toBeGreaterThan(0);
      await expect(page.getByRole("heading", { level: 1, name: "Read closely, infer and explain" })).toBeVisible();
    }
  });

  test("clears all draft responses and warm-up choice without scoring or saving", async ({ page }) => {
    await page.goto(previewPath);

    const response = page.getByLabel("Your exit response");
    const warmupChoice = page.getByRole("radio", { name: "The room was cold." });
    await response.fill("Two details support this inference.");
    await warmupChoice.check();
    await expect(response).toHaveValue("Two details support this inference.");
    await expect(warmupChoice).toBeChecked();

    await page.getByRole("button", { name: "Clear all draft responses" }).click();
    await expect(response).toHaveValue("");
    await expect(warmupChoice).not.toBeChecked();
    await expect(page.getByText("Responses are held only in this open page session.", { exact: false })).toBeVisible();
    await expect(page.getByText(/not graded/i)).toBeVisible();
  });

  test("meets WCAG AA text contrast for sampled main, label, placeholder and button text", async ({ page }) => {
    await page.goto(previewPath);

    const samples = await page.evaluate(() => {
      const luminance = (rgb: number[]) => {
        const channels = rgb.map((value) => {
          const normalized = value / 255;
          return normalized <= 0.04045 ? normalized / 12.92 : ((normalized + 0.055) / 1.055) ** 2.4;
        });
        return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
      };
      const parse = (value: string) => {
        const parts = value.match(/[\d.]+/g);
        return parts ? parts.slice(0, 3).map(Number) : null;
      };
      const contrast = (foreground: number[], background: number[]) => {
        const l1 = luminance(foreground);
        const l2 = luminance(background);
        return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
      };
      const getSample = (selector: string, pseudo?: string) => {
        const element = document.querySelector(selector);
        if (!element) return { selector, ratio: 0 };
        const style = getComputedStyle(element, pseudo);
        const foreground = parse(style.color);
        let current: Element | null = element;
        let background: number[] | null = null;
        while (current) {
          const candidate = getComputedStyle(current).backgroundColor;
          const rgb = parse(candidate);
          const alpha = candidate.match(/rgba?\([^)]*,\s*([\d.]+)\s*\)$/i);
          const isTransparent = candidate === "transparent" || (candidate.startsWith("rgba") && alpha && Number(alpha[1]) === 0);
          if (rgb && !isTransparent) {
            background = rgb;
            break;
          }
          current = current.parentElement;
        }
        if (!foreground || !background || background.length !== 3) return { selector, ratio: 0 };
        return { selector, ratio: contrast(foreground, background) };
      };
      return [
        getSample(".s7-preview-panel p"),
        getSample(".s7-preview-label"),
        getSample(".s7-preview-response label"),
        getSample(".s7-preview-response textarea", "::placeholder"),
        getSample(".s7-preview-button"),
        getSample(".s7-preview-alert p"),
      ];
    });

    expect(samples).toHaveLength(6);
    for (const sample of samples) {
      expect(sample.ratio, `${sample.selector} contrast ratio`).toBeGreaterThanOrEqual(4.5);
    }
  });
});
