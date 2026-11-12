import { expect, test } from "@playwright/test";
import { renderToStaticMarkup } from "react-dom/server";
import PaSpeakingOutlineTask, {
  emptySpeakingOutline, speakingObservationCodes, isPaSpeakingOutline,
} from "../src/auth/PaSpeakingOutlineTask";

test("SP outline card is distinct from live presentation and follow-up", () => {
  expect(speakingObservationCodes).toEqual(["SP01","SP02","SP03","SP04","SP05"]);
  const html = renderToStaticMarkup(<PaSpeakingOutlineTask
    value={emptySpeakingOutline} onChange={() => {}} />);
  expect((html.match(/<textarea/g) ?? []).length).toBe(5);
  expect(html).toContain("A better shared space");
  expect(html).toContain("assessor must separately observe");
  expect(html).toContain("What concern might they raise");
  expect(html).not.toMatch(/<audio|<video|recording|model answer|official IB grade|rubric score/i);
});
test("SP outline validation refuses incomplete or injected content", () => {
  const response = {
    title:"A reading corner", opening:"I propose a shared reading corner.",
    development:"It is useful for quiet reading and group discussion.",
    consideration:"Other students prefer games, so we can alternate.",
    closing:"Please trial it for a month.",
  };
  expect(isPaSpeakingOutline(response)).toBe(true);
  expect(isPaSpeakingOutline({ ...response, consideration:"" })).toBe(false);
  expect(isPaSpeakingOutline({ ...response, title:"x" })).toBe(false);
  expect(isPaSpeakingOutline({ ...response, closing:"z".repeat(1001) })).toBe(false);
  const html = renderToStaticMarkup(<PaSpeakingOutlineTask value={response}
    readOnly onChange={() => {}} />);
  expect((html.match(/disabled=""/g) ?? []).length).toBe(5);
});
test("SP01 outline capture is gated by server enabled observations", async () => {
  const fs = await import("node:fs/promises");
  const panel = await fs.readFile(new URL("../src/auth/DiagnosticPanel.tsx",import.meta.url),"utf8");
  const worker = await fs.readFile(new URL("../worker/index.ts",import.meta.url),"utf8");
  expect(panel).toContain('availableCodes.includes("SP01") && <PaSpeakingOutlineTask');
  expect(panel).toContain('output.push({ code: "SP01", response: { ...speakingOutline } })');
  expect(panel).toContain('setSpeakingOutline(savedSpeaking ?');
  expect(worker).toContain('if (observationCode === "SP01")');
});
