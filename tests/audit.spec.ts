import { execFileSync, spawn, type ChildProcess } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { expect, test } from "@playwright/test";

const ROOT = process.cwd();
const STUDENT_ID = "11111111-1111-4111-8111-111111111111";
const STUDENT_B_ID = "22222222-2222-4222-8222-222222222222";
const GRADER_A_ID = "55555555-5555-4555-8555-555555555555";
const TASK_A_ID = "a1111111-1111-4111-8111-111111111111";
const TASK_B_ID = "a2222222-2222-4222-8222-222222222222";
const PROMPT_A_ID = "b1111111-1111-4111-8111-111111111111";
const PROMPT_B_ID = "b2222222-2222-4222-8222-222222222222";
const ATTEMPT_A_ID = "c1111111-1111-4111-8111-111111111111";
const ATTEMPT_B_ID = "c2222222-2222-4222-8222-222222222222";
const UNKNOWN_SUBMISSION_ID = "e3333333-3333-4333-8333-333333333333";
const ASSESSMENT_VERSION_ID = "f9999999-9999-4999-8999-999999999999";
const LOCAL_PASSWORD = ["Local-only", "GradiPrep", "2026!"].join("-");

function readLocalDevVars(): Record<string, string> {
  const source = readFileSync(join(ROOT, ".dev.vars"), "utf8");
  const values: Record<string, string> = {};
  for (const line of source.split(/\r?\n/)) {
    const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (match) values[match[1]] = match[2].trim();
  }
  if (!values.SUPABASE_URL || !values.SUPABASE_PUBLISHABLE_KEY) {
    throw new Error("Local Supabase URL and publishable key are required by the audit tests.");
  }
  const host = new URL(values.SUPABASE_URL).hostname;
  if (!["127.0.0.1", "localhost", "::1"].includes(host)) {
    throw new Error("Audit tests refuse a non-local Supabase host.");
  }
  return values;
}

async function signInStudent(apiUrl: string, publishableKey: string): Promise<string> {
  const response = await fetch(
    `${apiUrl}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: {
        apikey: publishableKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "student.a@example.invalid",
        password: LOCAL_PASSWORD,
      }),
    },
  );
  if (!response.ok) throw new Error("Could not authenticate the synthetic local Student fixture.");
  const payload = await response.json() as { access_token?: string };
  if (!payload.access_token) throw new Error("The local Auth response did not contain an access token.");
  return payload.access_token;
}

function sqlCsv(sql: string): string {
  try {
    return execFileSync(
      "npx",
      ["--no-install", "supabase", "db", "query", sql, "--local", "--output", "csv"],
      {
        cwd: ROOT,
        encoding: "utf8",
        timeout: 30_000,
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
  } catch {
    throw new Error("The local Supabase audit-row verification query failed.");
  }
}

function assertPersistedAuditCorrelation(args: {
  requestId: string | null;
  action: string;
  actorId: string;
  targetId: string | null;
  outcome: string;
  reason: string;
}): void {
  const { requestId, action, actorId, targetId, outcome, reason } = args;
  expect(requestId, "Worker response must expose its generated correlation ID").toMatch(
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
  );
  const targetPredicate = targetId === null
    ? "target_id IS NULL"
    : `target_id = '${targetId}'::uuid`;
  const sql = `
    SELECT CASE
      WHEN count(*) = 1
       AND bool_and(actor_id = '${actorId}'::uuid)
       AND bool_and(action = '${action}')
       AND bool_and(${targetPredicate})
       AND bool_and(outcome = '${outcome}')
       AND bool_and(reason_category = '${reason}')
       AND bool_and(request_id = '${requestId}'::uuid)
       AND bool_and(transaction_id IS NOT NULL)
      THEN 'AUDIT_ROW_MATCHED'
      ELSE 'AUDIT_ROW_MISMATCH'
    END AS result
    FROM private.security_audit_events
    WHERE request_id = '${requestId}'::uuid
      AND action = '${action}';
  `;
  expect(sqlCsv(sql)).toContain("AUDIT_ROW_MATCHED");
}

async function waitForWorker(child: ChildProcess): Promise<void> {
  const deadline = Date.now() + 45_000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null || child.signalCode !== null) {
      throw new Error("The audit-failure Worker exited before it became ready.");
    }
    try {
      const response = await fetch("http://127.0.0.1:8788/api/health");
      if (response.status === 200) return;
    } catch {
      // The local Worker is still starting.
    }
    await new Promise(resolveDelay => setTimeout(resolveDelay, 250));
  }
  child.kill("SIGTERM");
  throw new Error("The audit-failure Worker did not become ready.");
}

test.describe("Phase 1C-E Worker audit correlation and failure injection", () => {
  test.describe.configure({ mode: "serial" });
  test.setTimeout(180_000);

  const local = readLocalDevVars();
  const supabaseUrl = local.SUPABASE_URL;
  const publishableKey = local.SUPABASE_PUBLISHABLE_KEY;
  let failureWorker: ChildProcess | undefined;
  let configDirectory: string | undefined;

  test.beforeAll(async () => {
    configDirectory = mkdtempSync(join(tmpdir(), "gradioprep-audit-failure-"));
    const noAuditConfig = {
      name: "gradioprep-audit-failure-test",
      main: resolve(ROOT, "worker/index.ts"),
      compatibility_date: "2026-10-19",
      compatibility_flags: ["nodejs_compat"],
      assets: {
        directory: resolve(ROOT, "dist"),
        binding: "ASSETS",
        run_worker_first: ["/api/*"],
        not_found_handling: "single-page-application",
      },
      // Deliberately omit SUPABASE_SERVICE_ROLE_KEY. No production test hook,
      // database permission change or shared .dev.vars mutation is required.
      vars: {
        SUPABASE_URL: supabaseUrl,
        SUPABASE_PUBLISHABLE_KEY: publishableKey,
      },
    };
    const configPath = join(configDirectory, "wrangler.audit-failure.jsonc");
    writeFileSync(configPath, JSON.stringify(noAuditConfig, null, 2), { mode: 0o600 });
    failureWorker = spawn(
      "npx",
      ["--no-install", "wrangler", "dev", "--config", configPath, "--ip", "127.0.0.1", "--port", "8788"],
      { cwd: ROOT, stdio: "ignore" },
    );
    await waitForWorker(failureWorker);
  });

  test.afterAll(async () => {
    if (failureWorker && failureWorker.exitCode === null && failureWorker.signalCode === null) {
      failureWorker.kill("SIGTERM");
    }
    if (configDirectory) rmSync(configDirectory, { recursive: true, force: true });
  });

  test("read and write success events persist the exact Worker response request ID", async () => {
    const token = await signInStudent(supabaseUrl, publishableKey);
    const headers = { Authorization: `Bearer ${token}` };

    const listResponse = await fetch("http://127.0.0.1:8787/api/v1/learner/attempts", { headers });
    expect(listResponse.status).toBe(200);
    assertPersistedAuditCorrelation({
      requestId: listResponse.headers.get("x-request-id"),
      action: "student_attempt_list_authorized",
      actorId: STUDENT_ID,
      targetId: null,
      outcome: "success",
      reason: "student_self",
    });

    const createResponse = await fetch("http://127.0.0.1:8787/api/v1/learner/attempts", {
      method: "POST",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify({ task_version_id: TASK_A_ID }),
    });
    expect(createResponse.status).toBe(201);
    const created = await createResponse.json() as { attempt?: { id?: string } };
    expect(created.attempt?.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    );
    assertPersistedAuditCorrelation({
      requestId: createResponse.headers.get("x-request-id"),
      action: "attempt_created",
      actorId: STUDENT_ID,
      targetId: created.attempt!.id!,
      outcome: "success",
      reason: "learner_action",
    });

    const crossLearnerRead = await fetch(
      `http://127.0.0.1:8787/api/v1/learner/attempts/${ATTEMPT_B_ID}`,
      { headers },
    );
    expect(crossLearnerRead.status).toBe(404);
    assertPersistedAuditCorrelation({
      requestId: crossLearnerRead.headers.get("x-request-id"),
      action: "student_attempt_read_authorized",
      actorId: STUDENT_ID,
      targetId: ATTEMPT_B_ID,
      outcome: "denied",
      reason: "resource_scope_denied",
    });

    const crossLearnerResponseSave = await fetch(
      `http://127.0.0.1:8787/api/v1/learner/attempts/${ATTEMPT_B_ID}/responses/${PROMPT_B_ID}`,
      {
        method: "PUT",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({ response_text: "A synthetic cross-learner write must be denied." }),
      },
    );
    expect([403, 404]).toContain(crossLearnerResponseSave.status);
    assertPersistedAuditCorrelation({
      requestId: crossLearnerResponseSave.headers.get("x-request-id"),
      action: "student_attempt_response_save",
      actorId: STUDENT_ID,
      targetId: ATTEMPT_B_ID,
      outcome: "denied",
      reason: "resource_scope_denied",
    });

    const crossLearnerSubmit = await fetch(
      `http://127.0.0.1:8787/api/v1/learner/attempts/${ATTEMPT_B_ID}/submit`,
      {
        method: "POST",
        headers: { ...headers, "Content-Type": "application/json" },
        body: JSON.stringify({}),
      },
    );
    expect([403, 404]).toContain(crossLearnerSubmit.status);
    assertPersistedAuditCorrelation({
      requestId: crossLearnerSubmit.headers.get("x-request-id"),
      action: "student_attempt_submit",
      actorId: STUDENT_ID,
      targetId: ATTEMPT_B_ID,
      outcome: "denied",
      reason: "resource_scope_denied",
    });
  });

  test("every Worker-audited route fails closed when its audit service is absent", async () => {
    const token = await signInStudent(supabaseUrl, publishableKey);
    const headers = { Authorization: `Bearer ${token}` };
    const contentHeaders = { ...headers, "Content-Type": "application/json" };

    const routes: Array<{
      method: "GET" | "POST" | "PUT";
      path: string;
      body?: Record<string, unknown>;
      expectedError: "protected_read_audit_unavailable" | "privileged_write_audit_unavailable";
    }> = [
      { method: "GET", path: "/api/v1/learner/attempts", expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: `/api/v1/learner/attempts/${ATTEMPT_A_ID}`, expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: "/api/v1/learner/submissions", expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: `/api/v1/learner/submissions/${UNKNOWN_SUBMISSION_ID}`, expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: "/api/v1/admin/staff-invitations", expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: `/api/v1/owner/assessment-versions/${ASSESSMENT_VERSION_ID}/private-qa`, expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: "/api/v1/grader/submissions", expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: `/api/v1/grader/submissions/${UNKNOWN_SUBMISSION_ID}`, expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: "/api/v1/admin/submissions/queue", expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: "/api/v1/grader/queue", expectedError: "protected_read_audit_unavailable" },
      { method: "GET", path: `/api/v1/grader/attempts/${ATTEMPT_A_ID}`, expectedError: "protected_read_audit_unavailable" },
      {
        method: "POST",
        path: "/api/v1/admin/roles/revoke",
        body: { target_user_id: STUDENT_B_ID, role: "grader", reason: "Synthetic audit outage test" },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: "/api/v1/admin/staff-invitations",
        body: { email: "audit-outage@example.invalid", role: "grader" },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: "/api/v1/admin/staff-invitations/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/revoke",
        body: { reason: "Synthetic audit outage test" },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: "/api/v1/learner/attempts",
        body: { task_version_id: TASK_B_ID },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "PUT",
        path: `/api/v1/learner/attempts/${ATTEMPT_B_ID}/responses/${PROMPT_B_ID}`,
        body: { response_text: "A cross-learner synthetic response must fail without audit acknowledgement." },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/learner/attempts/${ATTEMPT_B_ID}/submit`,
        body: {},
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: "/api/v1/learner/submissions",
        body: {
          task_version_id: TASK_B_ID,
          idempotency_key: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
          response_text: "A valid synthetic response for an unenrolled task.",
        },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/admin/submissions/${UNKNOWN_SUBMISSION_ID}/assign`,
        body: { grader_user_id: GRADER_A_ID, reason: "Synthetic audit outage test" },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/owner/submissions/${UNKNOWN_SUBMISSION_ID}/reassign`,
        body: { grader_user_id: GRADER_A_ID, reason: "Synthetic audit outage test" },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/owner/submissions/${UNKNOWN_SUBMISSION_ID}/transition`,
        body: { target_status: "closed", reason: "Synthetic audit outage test" },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/owner/assessment-versions/${ASSESSMENT_VERSION_ID}/private-qa`,
        body: {
          checks: { synthetic_check: true },
          status: "passed",
          explanation: "The synthetic audit failure check is complete.",
          reviewer_action: "No further synthetic action is required.",
        },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "PUT",
        path: `/api/v1/grader/submissions/${UNKNOWN_SUBMISSION_ID}/draft`,
        body: {
          overall_feedback: "Synthetic feedback used only to pass route validation.",
          criterion_results: [{
            criterion_id: "f3333333-3333-4333-8333-333333333333",
            points_awarded: 2,
            feedback: "A synthetic criterion feedback item.",
          }],
        },
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/grader/submissions/${UNKNOWN_SUBMISSION_ID}/publish`,
        body: {},
        expectedError: "privileged_write_audit_unavailable",
      },
      {
        method: "POST",
        path: `/api/v1/admin/attempts/${ATTEMPT_A_ID}/assign`,
        body: { grader_user_id: GRADER_A_ID, reason: "Synthetic audit outage test" },
        expectedError: "privileged_write_audit_unavailable",
      },
    ];

    for (const route of routes) {
      const response = await fetch(`http://127.0.0.1:8788${route.path}`, {
        method: route.method,
        headers: route.body === undefined ? headers : contentHeaders,
        ...(route.body === undefined ? {} : { body: JSON.stringify(route.body) }),
      });
      const responseBody = await response.json() as { error?: string };
      expect(
        response.status,
        `${route.method} ${route.path} should fail closed when audit ingestion is unavailable; got ${JSON.stringify(responseBody)}`,
      ).toBe(503);
      expect(responseBody.error).toBe(route.expectedError);
      expect(response.headers.get("x-request-id")).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
      );
    }
  });
});
