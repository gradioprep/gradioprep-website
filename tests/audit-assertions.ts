import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { expect } from "@playwright/test";
export type AuditActorRole="student"|"guardian"|"grader"|"admin"|"owner";
export interface PersistedAuditExpectation{actorId:string;actorRole:AuditActorRole;action:string;targetType:string;targetId:string|null;outcome:"success"|"denied"|"failed";reason:string;}
function localSqlCsv(sql:string):string{
 const vars=readFileSync(join(process.cwd(),".dev.vars"),"utf8");
 const url=vars.split(/\r?\n/).find(line=>line.startsWith("SUPABASE_URL="))?.slice("SUPABASE_URL=".length).trim();
 if(!url)throw new Error("Local Supabase URL is required by persisted audit assertions.");
 if(!["127.0.0.1","localhost","::1"].includes(new URL(url).hostname))throw new Error("Persisted audit assertions refuse a non-local Supabase host.");
 try{return execFileSync("npx",["--no-install","supabase","db","query",sql,"--local","--output","csv"],{cwd:process.cwd(),encoding:"utf8",timeout:30_000,stdio:["ignore","pipe","pipe"]});}
 catch{throw new Error("The local Supabase persisted-audit verification query failed.");}
}
export function assertPersistedAuditCorrelation(requestId:string|undefined|null,e:PersistedAuditExpectation):void{
 const {actorId,actorRole,action,targetType,targetId,outcome,reason}=e;
 expect(requestId,"Worker response must expose its generated correlation ID").toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
 for(const [label,value] of [["actor",actorId],["target",targetId]] as const)if(value!==null&&!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value))throw new Error("Invalid synthetic UUID supplied for persisted audit "+label+".");
 if(!/^[a-z0-9_]+$/.test(actorRole)||! /^[a-z0-9_]+$/.test(action)||! /^[a-z0-9_]+$/.test(targetType)||reason.length===0||reason.length>80||/[\u0000-\u001f]/.test(reason))throw new Error("Persisted audit assertions accept only bounded, safe identifiers and reasons.");
 const target=targetId===null?"target_id IS NULL":`target_id='${targetId}'::uuid`,safeReason=reason.replace(/'/g,"''");
 const sql=`SELECT CASE WHEN count(*)=1 AND bool_and(actor_id='${actorId}'::uuid) AND bool_and(actor_roles IS NOT NULL) AND bool_and(actor_roles @> ARRAY['${actorRole}'::public.app_role]) AND bool_and(action='${action}') AND bool_and(target_type='${targetType}') AND bool_and(${target}) AND bool_and(outcome='${outcome}') AND bool_and(reason_category='${safeReason}') AND bool_and(request_id='${requestId}'::uuid) AND bool_and(transaction_id IS NOT NULL) THEN 'AUDIT_ROW_MATCHED' ELSE 'AUDIT_ROW_MISMATCH' END AS result FROM private.security_audit_events WHERE request_id='${requestId}'::uuid AND action='${action}';`;
 expect(localSqlCsv(sql)).toContain("AUDIT_ROW_MATCHED");
}
export function readPersistedAuditTargetId(requestId:string|undefined|null,action:string):string{
 expect(requestId,"Worker response must expose its generated correlation ID").toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
 if(!/^[a-z0-9_]+$/.test(action))throw new Error("Invalid audit action identifier.");
 const o=localSqlCsv(`SELECT target_id::text FROM private.security_audit_events WHERE request_id='${requestId}'::uuid AND action='${action}' LIMIT 1;`);
 const id=o.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i)?.[0];expect(id,`Persisted audit event ${action} must include its target ID`).toBeTruthy();return id!;
}
export function actorIdFromAuthorizationHeader(authorization:string):string{
 const t=authorization.replace(/^Bearer\s+/i,""),s=t.split(".")[1];if(!s)throw new Error("Expected a synthetic bearer JWT.");
 const p=JSON.parse(Buffer.from(s,"base64url").toString("utf8")) as {sub?:string};
 if(!p.sub||! /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(p.sub))throw new Error("Synthetic JWT subject is invalid.");return p.sub;
}
