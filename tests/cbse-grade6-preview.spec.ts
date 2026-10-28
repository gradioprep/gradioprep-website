import { expect, test } from "@playwright/test";

const previewPath = "/preview/cbse-grade-6/english/unit-1";

function luminance(rgb: string): number {
  const channels = rgb.match(/[0-9]+(?:\.[0-9]+)?/g)?.slice(0, 3).map(Number);
  if (!channels || channels.length !== 3) throw new Error(`Unexpected CSS rgb colour: ${rgb}`);
  const [r, g, b] = channels.map(value => {
    const channel = value / 255;
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(foreground: string, background: string): number {
  const a = luminance(foreground);
  const b = luminance(background);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

test.describe("CBSE Grade 6 controlled preview", () => {
  test("direct route renders the unreleased lesson and accurate review/mapping status", async ({ page }) => {
    await page.goto(previewPath);
    await expect(page.getByRole("heading", { level: 1, name: "The Turning Sign" })).toBeVisible();
    await expect(page.getByRole("heading", { name: /Controlled accessibility preview — not a release/i })).toBeVisible();
    await expect(page.getByText(/Not approved for release/i)).toBeVisible();
    await expect(page.getByText(/Partial; no official objective code/i)).toBeVisible();
    await expect(page.getByText(/not submitted, scored or saved/i)).toBeVisible();
    await expect(page.getByRole("heading", { name: /Find a direct clue/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /Retell the solution/i })).toBeVisible();
  });

  test("preview path is not linked from normal learner navigation", async ({ page }) => {
    await page.goto("/pathways");
    await expect(page.locator(`a[href="${previewPath}"]`)).toHaveCount(0);
    await expect(page.getByRole("link", { name: /The Turning Sign/i })).toHaveCount(0);
    await expect(page.getByText(/CBSE Grade 6/i)).toHaveCount(0);
  });

  test("skip link is the first keyboard stop and moves focus to lesson content", async ({ page }) => {
    await page.goto(previewPath);
    await page.keyboard.press("Tab");
    const skipLink = page.getByRole("link", { name: "Skip to lesson content" });
    await expect(skipLink).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(page.locator("#cbse-preview-main")).toBeFocused();
  });

  test("interactive controls have unique IDs and associated labels", async ({ page }) => {
    await page.goto(previewPath);
    await expect(page.getByRole("radio")).toHaveCount(4);
    await expect(page.getByRole("textbox")).toHaveCount(2);
    await expect(page.getByRole("combobox")).toHaveCount(9);
    const labelled = await page.locator(".cbse-preview-interactive input, .cbse-preview-interactive textarea, .cbse-preview-interactive select").evaluateAll(elements =>
      elements.map(element => {
        const id = element.getAttribute("id");
        const label = id ? document.querySelectorAll(`label[for="${CSS.escape(id)}"]`).length : 0;
        return { id, label };
      }),
    );
    const ids = labelled.map(item => item.id);
    expect(ids.every(Boolean)).toBeTruthy();
    expect(new Set(ids).size).toBe(ids.length);
    expect(labelled.every(item => item.label === 1)).toBeTruthy();
  });

  test("clear-all removes every response from the temporary session", async ({ page }) => {
    await page.goto(previewPath);
    await page.getByRole("radio", { name: /A The deer had walked near the post/i }).check();
    await page.locator("#cbse-inference-response").fill("A clue does not prove who moved the sign.");
    await page.getByRole("combobox", { name: /Position for event 1/i }).selectOption("2");
    await page.getByRole("combobox", { name: /Location word for sentence 1/i }).selectOption("at");
    await page.locator("#cbse-exit-response").fill("First the animals investigate, then they find the wedge.");
    await page.getByRole("button", { name: "Clear all responses" }).click();
    for (const radio of await page.getByRole("radio").all()) await expect(radio).not.toBeChecked();
    await expect(page.locator("#cbse-inference-response")).toHaveValue("");
    await expect(page.getByRole("combobox", { name: /Position for event 1/i })).toHaveValue("");
    await expect(page.getByRole("combobox", { name: /Location word for sentence 1/i })).toHaveValue("");
    await expect(page.locator("#cbse-exit-response")).toHaveValue("");
  });

  test("layout has no horizontal overflow at tested phone, tablet and desktop widths", async ({ page }) => {
    for (const width of [320, 390, 768, 1024]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(previewPath);
      const dimensions = await page.evaluate(() => ({
        documentWidth: document.documentElement.scrollWidth,
        bodyWidth: document.body.scrollWidth,
        viewportWidth: window.innerWidth,
      }));
      expect(dimensions.documentWidth, `document overflow at ${width}px`).toBeLessThanOrEqual(width + 1);
      expect(dimensions.bodyWidth, `body overflow at ${width}px`).toBeLessThanOrEqual(width + 1);
      expect(dimensions.viewportWidth).toBe(width);
    }
  });

  test("sampled foreground/background pairs meet 4.5:1 text contrast", async ({ page }) => {
    await page.goto(previewPath);
    const samples = await page.locator(
      ".cbse-preview-hero h1, .cbse-preview-status h2, .cbse-preview-status p, .cbse-preview-passage, .cbse-preview-fieldset legend, .cbse-preview-field-label",
    ).evaluateAll(elements => elements.map(element => {
      const foreground = getComputedStyle(element).color;
      let current: Element | null = element;
      let background = "rgb(247, 248, 252)";
      while (current) {
        const candidate = getComputedStyle(current).backgroundColor;
        if (candidate && candidate !== "transparent" && candidate !== "rgba(0, 0, 0, 0)") {
          background = candidate;
          break;
        }
        current = current.parentElement;
      }
      return { sample: element.tagName.toLowerCase(), foreground, background };
    }));
    for (const sample of samples) {
      expect(
        contrastRatio(sample.foreground, sample.background),
        `contrast too low for ${sample.sample}: ${sample.foreground} on ${sample.background}`,
      ).toBeGreaterThanOrEqual(4.5);
    }
  });

  test("teacher answer-key guidance is not displayed in the learner preview", async ({ page }) => {
    await page.goto(previewPath);
    await expect(page.getByText(/Expected choice:|Strong response characteristics|Suggested answers|marking guide/i)).toHaveCount(0);
    await expect(page.getByText(/Use the success indicators/i)).toHaveCount(0);
  });

  test("unknown preview-like routes remain unavailable", async ({ page }) => {
    await page.goto(`${previewPath}-extra`);
    await expect(page.getByRole("heading", { name: /This route isn't available/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: "The Turning Sign" })).toHaveCount(0);
  });
});
