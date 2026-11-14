import { readFileSync } from "node:fs";
import { expect, test } from "@playwright/test";
import { renderToStaticMarkup } from "react-dom/server";
import PaContextualExplanationField, {
  paChoiceResponse, requiresPaContextualExplanation,
} from "../src/auth/PaContextualChoiceTask";

const revised = ["RV04","RV05","LC01","LC02"];

test("the four revised prompts provide accessible contextual explanations only for the new MYP4 version", () => {
  for (const code of revised) {
    expect(requiresPaContextualExplanation("ib-myp-g9-cycle1", 2, code)).toBe(true);
    expect(requiresPaContextualExplanation("ib-myp-g9-cycle1", 1, code)).toBe(false);
    expect(requiresPaContextualExplanation("other-route", 2, code)).toBe(false);
    const html = renderToStaticMarkup(<PaContextualExplanationField
      instrumentCode="ib-myp-g9-cycle1" instrumentVersion={2} code={code}
      value="" onChange={() => {}} />);
    expect(html).toContain("<textarea");
    expect(html).toContain("aria-live=\"polite\"");
    expect(html).toContain("Ideal target:");
    expect(html).toContain("0 / ");
    expect(html).not.toMatch(/answer key|distractor|scoring anchor|official ib grade/i);
    const legacy = renderToStaticMarkup(<PaContextualExplanationField
      instrumentCode="ib-myp-g9-cycle1" instrumentVersion={1} code={code}
      value="not visible" onChange={() => {}} />);
    expect(legacy).toBe("");
  }
  expect(requiresPaContextualExplanation("ib-myp-g9-cycle1", 2, "LC03")).toBe(false);
  expect(requiresPaContextualExplanation("ib-myp-g9-cycle1", 2, "L01")).toBe(false);
  expect(requiresPaContextualExplanation("ib-myp-g9-cycle1", Number.NaN, "RV04")).toBe(false);
});

test("version-bound answer construction prevents missing explanations without changing v1", () => {
  for (const code of revised) {
    expect(paChoiceResponse("ib-myp-g9-cycle1", 1, code, "B", "")).toEqual({choice:"B"});
    expect(paChoiceResponse("ib-myp-g9-cycle1", 2, code, "B", "")).toBeNull();
    expect(paChoiceResponse("ib-myp-g9-cycle1", 2, code, "B", "   ")).toBeNull();
    expect(paChoiceResponse("ib-myp-g9-cycle1", 2, code, "B", "four")).toBeNull();
    expect(paChoiceResponse("ib-myp-g9-cycle1", 2, code, "B", "wording supports this meaning")).toEqual({
      choice:"B", explanation:"wording supports this meaning",
    });
    expect(paChoiceResponse("ib-myp-g9-cycle1", 2, code, "Q", "explanation is provided")).toBeNull();
  }
  expect(paChoiceResponse("ib-myp-g9-cycle1", 2, "LC03", "A", "")).toEqual({choice:"A"});
  expect(paChoiceResponse("other-course", 2, "RV04", "A", "")).toEqual({choice:"A"});
});

test("rendered target is guidance, supports read-only restoration and text beyond target", () => {
  const html=renderToStaticMarkup(<PaContextualExplanationField
    instrumentCode="ib-myp-g9-cycle1" instrumentVersion={2} code="RV04"
    value={Array(40).fill("analysis").join(" ")}
    onChange={() => {}} disabled />);
  expect(html).toContain("40 / 25 words");
  expect(html).toContain("disabled=\"\"");
  expect(html).toContain("textarea");
  expect(html).not.toContain("maxLength=\"25\"");
  const lc = renderToStaticMarkup(<PaContextualExplanationField
    instrumentCode="ib-myp-g9-cycle1" instrumentVersion={2} code="LC01"
    value="One narrow shelf supports a limited proposal." onChange={() => {}} />);
  expect(lc).toContain("7 / 20 words");
});

test("learner panel is version-bound and cannot bypass draft publication or expose private teacher packs", () => {
  const panel = readFileSync("src/auth/DiagnosticPanel.tsx", "utf8");
  const seed = readFileSync("supabase/seed.sql", "utf8");
  const gate = readFileSync("supabase/migrations/20261112000600_phase2_pa_direct_mapping_publication_gate.sql", "utf8");
  const worker = readFileSync("worker/index.ts", "utf8");
  expect(panel).toContain("setInstrument({ code: result.diagnostic?.diagnostic_code");
  expect(panel).toContain("paChoiceResponse(instrument.code, instrument.version, code");
  expect((panel.match(/<PaContextualExplanationField/g) ?? []).length).toBe(4);
  expect(panel).toContain('instrument.version >= 2');
  expect(seed).toContain("THEN 'choice_and_text' ELSE response_kind END, false");
  expect(seed).toMatch(/2, 'draft', 80, 2/);
  expect(gate).toContain("pa_publication_requires_reviewed_direct_mapping");
  expect(gate).toContain("directly_mapped_observations <> total_observations");
  expect(worker).toContain('.eq("release_state", "published")');
  expect(worker).toContain('.order("version", { ascending: false })');
  expect(worker).not.toContain('.eq("version", 1)');
  expect(worker).toContain('only(["choice", "explanation"]) && choice(value.choice) && text(value.explanation)');
  expect(worker).toContain('section_status: version.version >= 2 ? "full_preliminary_assessment"');
  expect(panel).not.toMatch(/GRADIOPREP_MYP4_.*TEACHER_EDITOR|rubric_sha256/);
});
