import { expect, test } from "@playwright/test";
import { renderToStaticMarkup } from "react-dom/server";
import PaCreativeWritingTask, {
  emptyCreativeWritingResponse, creativeWritingObservationCodes,
  isPaCreativeWritingResponse,
} from "../src/auth/PaCreativeWritingTask";

test("one creative response includes a plan, both drafts and a visible revision trace", () => {
  expect(creativeWritingObservationCodes).toEqual(["CW01","CW02","CW03","CW04","CW05"]);
  const html = renderToStaticMarkup(<PaCreativeWritingTask
    value={emptyCreativeWritingResponse} onChange={() => {}} />);
  expect(html).toContain("The Book Swap");
  expect(html).toContain("0 / 125 words");
  expect((html.match(/<textarea/g) ?? []).length).toBe(6);
  expect(html).not.toMatch(/model answer|rubric score|teacher note|official IB grade/i);
});

test("CW validation rejects omitted trace and accepts over-target narrative", () => {
  const response = {
    plan:"Viewpoint: Sam; change: rain; ending: use the sunny corner.",
    initial_draft:"The corner was empty at first, but Sam noticed it.",
    final_text:Array(200).fill("scene").join(" "),
    revision_before:"The corner was empty.",
    revision_after:"The quiet corner glowed in the afternoon.",
    revision_note:"The change makes the place more vivid.",
  };
  expect(isPaCreativeWritingResponse(response)).toBe(true);
  expect(isPaCreativeWritingResponse({ ...response, revision_note:"" })).toBe(false);
  expect(isPaCreativeWritingResponse({ ...response, revision_after:response.revision_before })).toBe(false);
  const html=renderToStaticMarkup(<PaCreativeWritingTask
    value={response} readOnly onChange={() => {}} />);
  expect(html).toContain("200 / 125 words");
  expect((html.match(/disabled=""/g) ?? []).length).toBe(6);
});

test("creative task is only shown when server exposes CW01 as capture-enabled", async () => {
  const fs=await import("node:fs/promises");
  const panel=await fs.readFile(new URL("../src/auth/DiagnosticPanel.tsx",import.meta.url),"utf8");
  const worker=await fs.readFile(new URL("../worker/index.ts",import.meta.url),"utf8");
  expect(panel).toContain('availableCodes.includes("CW01") && <PaCreativeWritingTask');
  expect(panel).toContain('output.push({ code: "CW01", response: { ...creativeDraft } })');
  expect(panel).toContain("setCreativeDraft(savedCreative");
  expect(worker).toContain('if (observationCode === "CW01")');
});
