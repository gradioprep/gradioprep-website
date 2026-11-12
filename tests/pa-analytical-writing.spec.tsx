import { expect, test } from "@playwright/test";
import { renderToStaticMarkup } from "react-dom/server";
import PaAnalyticalWritingTask, {
  analyticalWritingObservationCodes,
  analyticalWritingPassage,
  countPaWords,
  isPaAnalyticalWritingResponse,
} from "../src/auth/PaAnalyticalWritingTask";

test("unreleased analytical-writing learner draft is one response with five evidence dimensions", () => {
  expect(analyticalWritingObservationCodes).toEqual(["AW01", "AW02", "AW03", "AW04", "AW05"]);
  expect(analyticalWritingPassage).toHaveLength(7);
  const html = renderToStaticMarkup(<PaAnalyticalWritingTask value="" onChange={() => {}} />);
  expect(html).toContain("The Unfinished Label");
  expect(html).toContain("preserving a memory and presenting it as fact");
  expect(html).toContain("0 / 180 words");
  expect((html.match(/<textarea/g) ?? []).length).toBe(1);
  expect(html).not.toMatch(/answer key|rubric score|model answer|teacher note|official IB grade/i);
});

test("word guidance never rejects a valid over-target typed response", () => {
  expect(countPaWords("  One   two\nthree  ")).toBe(3);
  expect(countPaWords("")).toBe(0);
  const longAnswer = Array(220).fill("evidence").join(" ");
  expect(countPaWords(longAnswer)).toBe(220);
  expect(isPaAnalyticalWritingResponse(longAnswer)).toBe(true);
  expect(isPaAnalyticalWritingResponse("    ")).toBe(false);
  const html = renderToStaticMarkup(<PaAnalyticalWritingTask value={longAnswer} onChange={() => {}} />);
  expect(html).toContain("220 / 180 words");
  expect(html).not.toContain("disabled=\"\"");
  const readOnly = renderToStaticMarkup(<PaAnalyticalWritingTask value={longAnswer} readOnly onChange={() => {}} />);
  expect(readOnly).toContain("disabled=\"\"");
});
