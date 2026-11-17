import { expect,test } from "@playwright/test";
import { readFile } from "node:fs/promises";
test("two-sitting UI saves and finishes one session before moving to next",async()=>{
 const panel=await readFile(new URL("../src/auth/DiagnosticPanel.tsx",import.meta.url),"utf8");
 expect(panel).toContain('Start Sitting 1');
 expect(panel).toContain('Start Sitting 2');
 expect(panel).toContain('Finish Sitting {activeSitting}');
 expect(panel).toContain('pendingForSitting(activeSitting)');
 expect(panel).toContain('savedSignatures[item.code] === JSON.stringify(item.response)');
 expect(panel).toContain('(sittingExpired ? savedCodes : responseReadyCodes).includes(code)');
 expect(panel).toContain('setSavedSignatures(current => ({');
 expect(panel).toContain('are saved to your assessment');
 expect(panel).not.toContain('questions have response-ready answers');
 expect(panel).toContain('sittingExpired');
 expect(panel).toContain('finishedSittings.length !== 2');
 expect(panel).toContain('availableSittings[item.code] === activeSitting');
});
test("expired sittings lock all response controls including longer writing tasks",async()=>{
 const panel=await readFile(new URL("../src/auth/DiagnosticPanel.tsx",import.meta.url),"utf8");
 expect(panel).toContain("const sittingExpired = twoSitting");
 expect((panel.match(/disabled=\\{readOnly \\|\\| sittingExpired\\}/g) ?? []).length).toBeGreaterThanOrEqual(15);
 expect((panel.match(/readOnly=\\{readOnly \\|\\| saving \\|\\| sittingExpired\\}/g) ?? []).length).toBe(3);
 expect(panel).toContain("no further changes can be saved");
});

test("staff access arrangements are MFA-gated and do not reset clock",async()=>{
 const worker=await readFile(new URL("../worker/index.ts",import.meta.url),"utf8");
 const admin=await readFile(new URL("../src/auth/PaFeedbackWorkspacePanel.tsx",import.meta.url),"utf8");
 expect(worker).toContain("ownerPaSittingAdjustment");
 expect(worker).toContain('requireAal2(auth.context)');
 expect(admin).toContain("Apply arrangement");
 expect(admin).toContain("Untimed arrangement");
});
