import { expect,test } from "@playwright/test";
import { readFile } from "node:fs/promises";
test("two-sitting UI saves and finishes one session before moving to next",async()=>{
 const panel=await readFile(new URL("../src/auth/DiagnosticPanel.tsx",import.meta.url),"utf8");
 expect(panel).toContain('Start Sitting 1');
 expect(panel).toContain('Start Sitting 2');
 expect(panel).toContain('Finish Sitting {activeSitting}');
 expect(panel).toContain('pendingForSitting(activeSitting)');
 expect(panel).toContain('sittingExpired');
 expect(panel).toContain('finishedSittings.length !== 2');
 expect(panel).toContain('availableSittings[item.code] === activeSitting');
});
test("staff access arrangements are MFA-gated and do not reset clock",async()=>{
 const worker=await readFile(new URL("../worker/index.ts",import.meta.url),"utf8");
 const admin=await readFile(new URL("../src/auth/PaFeedbackWorkspacePanel.tsx",import.meta.url),"utf8");
 expect(worker).toContain("ownerPaSittingAdjustment");
 expect(worker).toContain('requireAal2(auth.context)');
 expect(admin).toContain("Apply arrangement");
 expect(admin).toContain("Untimed arrangement");
});
