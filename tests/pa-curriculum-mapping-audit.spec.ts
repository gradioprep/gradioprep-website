import { readFileSync } from "node:fs";
import { expect, test } from "@playwright/test";

const mapText = readFileSync("docs/curriculum/IB_MYP_G9_DIAGNOSTIC_ITEM_MAP_AND_SCORING_SPEC.md", "utf8");
const mappingStandard = readFileSync("docs/ASSESSMENT_CURRICULUM_MAPPING_AND_MILESTONE_STANDARD.md", "utf8");
const seed = readFileSync("supabase/seed.sql", "utf8");
const migrationTest = readFileSync("supabase/tests/diagnostic_full_instrument_draft.test.sql", "utf8");
const section = mapText.split("## 5.1 Item-by-item public-strand audit")[1]?.split("\n## ")[0] ?? "";
const rows = section.split("\n").filter(line => /^\| (RV\d{2}[ab]?|LC\d{2}|AW\d{2}|CW\d{2}|SP\d{2}|L\d{2}) \|/.test(line))
  .map(line => {
    const cells = line.split("|").slice(1, -1).map(cell => cell.trim());
    return { code: cells[0], candidate: cells[1], treatment: cells[2] };
  });
const expected = [
  "RV01","RV02","RV03","RV04","RV05","RV06","RV07a","RV07b","RV08","RV09",
  "LC01","LC02","LC03","LC04","LC05",
  "AW01","AW02","AW03","AW04","AW05",
  "CW01","CW02","CW03","CW04","CW05",
  "SP01","SP02","SP03","SP04","SP05",
];
const byCode = new Map(rows.map(row => [row.code, row]));

test("candidate Year 4 audit covers the complete exact thirty-observation PA scope", () => {
  expect(rows.map(row => row.code)).toEqual(expected);
  expect(new Set(rows.map(row => row.code)).size).toBe(30);
  expect(rows.filter(row => row.code.startsWith("L0"))).toHaveLength(0);
  for (const row of rows) {
    expect(row.candidate).toMatch(/\b[A-D]\.(i|ii|iii|iv|v)\b/);
    expect(row.treatment.length).toBeGreaterThan(40);
  }
});

test("audit explicitly carries the required changes to challenged curriculum mappings", () => {
  const required = {
    RV06: /Revise before use/i,
    LC01: /Revise before use/i,
    CW01: /Rename the dimension/i,
    CW02: /replace C\.i with C\.ii/i,
    CW04: /Rename the dimension/i,
    CW05: /before\/after revision trace/i,
    SP05: /D\.ii covers spoken register\/style/i,
  };
  for (const [code, phrase] of Object.entries(required)) {
    expect(byCode.get(code)?.treatment).toMatch(phrase);
  }
  expect(byCode.get("SP05")?.candidate).toContain("D.iv");
  expect(byCode.get("RV07a")?.candidate).toContain("A.iii");
  expect(byCode.get("RV07b")?.candidate).toContain("A.i");
});

test("candidate strands never substitute for authorised Year 4 mapping approval", () => {
  expect(section).toContain("All 30 observations remain `PENDING_Y4_ACADEMIC_REVIEW`");
  expect(section).toContain("authorised school Year 4 progression");
  expect(section).toContain("human MYP academic sign-off");
  expect(section).toContain("UNMAPPED");
  expect(mappingStandard).toContain("Only `DIRECT` items may form the PA/SA evidence basis");
  expect(mappingStandard).toContain("do not treat a Year 3 or Year 5 descriptor as an exact Year 4 descriptor");
});

test("the complete authoring blueprint remains unreleased with no learner capture or fictional mappings", () => {
  expect(seed).toContain("'ed222222-2222-4222-8222-222222222222'");
  expect(seed).toMatch(/'IB MYP Year 4 Preliminary Assessment — full evidence blueprint \(synthetic draft\)'[\s\S]*?2, 'draft', 80, 2/);
  expect(seed).toContain("sequence_number, response_kind, false");
  expect(migrationTest).toContain("no unreviewed draft observation is learner-capturable");
  expect(migrationTest).toContain("draft blueprint cannot invent reviewed official-outcome mappings");
  expect(migrationTest).toContain("student cannot begin unreleased full instrument");
});
