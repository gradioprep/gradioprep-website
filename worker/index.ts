import { createContextClient, verifyAuth } from "@supabase/server/core";

type WorkerEnv = Env & {
  SUPABASE_URL?: string;
  SUPABASE_PUBLISHABLE_KEY?: string;
};

type ProtectedReadAuditAction =
  | "student_attempt_list_authorized"
  | "student_attempt_read_authorized"
  | "grader_attempt_queue_authorized"
  | "grader_attempt_read_authorized"
  | "student_submission_list_authorized"
  | "student_submission_read_authorized"
  | "grader_submission_queue_authorized"
  | "grader_submission_read_authorized"
  | "owner_submission_queue_authorized";

type AppRole = "student" | "guardian" | "grader" | "admin" | "owner";

const APP_ROLES: readonly AppRole[] = [
  "student",
  "guardian",
  "grader",
  "admin",
  "owner",
];

interface RoleRevocationRequest {
  target_user_id: string;
  role: AppRole;
  reason: string;
}

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function isValidDisplayName(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0 && value.trim().length <= 80;
}

function hasOnlyDisplayNameFields(value: unknown): value is { display_name: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 1 && isValidDisplayName(record.display_name);
}

function isUuid(value: unknown): value is string {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

function hasOnlyRoleRevocationFields(value: unknown): value is RoleRevocationRequest {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 3 &&
    Object.keys(record).every((key) => ["target_user_id", "role", "reason"].includes(key)) &&
    isUuid(record.target_user_id) &&
    typeof record.role === "string" &&
    APP_ROLES.includes(record.role as AppRole) &&
    typeof record.reason === "string" &&
    record.reason.trim().length >= 3 &&
    record.reason.trim().length <= 240;
}

async function createCallerContext(request: Request, env: WorkerEnv) {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    throw new Error("Local Supabase environment is not configured.");
  }

  // Verify the bearer token against this project's signing keys, then create
  // only the caller-scoped client. createSupabaseContext also constructs an
  // admin client, which requires a secret key even when this route never uses
  // it. This API deliberately has no service-role/admin client.
  const supabaseEnv = {
    url: env.SUPABASE_URL,
    publishableKeys: { default: env.SUPABASE_PUBLISHABLE_KEY },
    jwks: new URL("/auth/v1/.well-known/jwks.json", env.SUPABASE_URL),
  };
  const { data: auth, error } = await verifyAuth(request, {
    auth: "user",
    env: supabaseEnv,
  });

  if (error) return { data: null, error };
  if (!auth.token || !auth.userClaims?.id) {
    return { data: null, error: { status: 401, code: "missing_user_claims" } };
  }

  const supabase = createContextClient({
    auth: { token: auth.token },
    env: supabaseEnv,
  });

  // Signature/expiry verification alone cannot detect a globally revoked
  // session until its JWT expires. Introspect the live session with GoTrue
  // before authorising protected Worker operations.
  const { data: currentUser, error: currentUserError } = await supabase.auth.getUser(auth.token);
  if (currentUserError || !currentUser.user || currentUser.user.id !== auth.userClaims.id) {
    const authUnavailable = Boolean(
      currentUserError &&
      (typeof currentUserError.status !== "number" || currentUserError.status >= 500)
    );
    return {
      data: null,
      error: {
        status: authUnavailable ? 503 : 401,
        code: authUnavailable ? "auth_service_unavailable" : "session_revoked",
      },
    };
  }

  // verifyAuth validates the JWT signature, issuer, audience and expiry.
  // Its normalized userClaims type omits the AAL field in some package versions,
  // so read assurance from the payload of that already-verified token.
  let assuranceLevel: "aal1" | "aal2" = "aal1";
  try {
    const encodedPayload = auth.token.split(".")[1];
    if (encodedPayload) {
      const base64 = encodedPayload.replace(/-/g, "+").replace(/_/g, "/");
      const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
      const binary = atob(padded);
      const bytes = Uint8Array.from(binary, character => character.charCodeAt(0));
      const verifiedClaims = JSON.parse(new TextDecoder().decode(bytes)) as Record<string, unknown>;
      assuranceLevel = verifiedClaims.aal === "aal2" ? "aal2" : "aal1";
    }
  } catch {
    // Fail closed: malformed or absent assurance claims remain AAL1.
  }

  return {
    data: {
      supabase,
      userId: auth.userClaims.id,
      assuranceLevel,
    },
    error: null,
  };
}

async function authenticatedMe(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    return jsonResponse({
      error: "backend_not_configured",
      message: "Authentication is not connected to this public preview. Use the local development environment for synthetic account testing.",
    }, 503);
  }

  const { data: context, error } = await createCallerContext(request, env);

  if (error || !context) {
    return jsonResponse({
      error: "authentication_required",
      code: error?.code ?? "missing_user_claims",
      message: error?.code === "session_revoked"
        ? "This session has ended. Please sign in again."
        : "A valid signed-in account is required.",
    }, error?.status ?? 401);
  }

  const userId = context.userId;
  const [{ data: profile, error: profileError }, { data: roleRows, error: roleError }] = await Promise.all([
    context.supabase
      .from("profiles")
      .select("user_id, display_name, account_status, created_at")
      .eq("user_id", userId)
      .maybeSingle(),
    context.supabase
      .from("role_assignments")
      .select("role")
      .eq("user_id", userId)
      .is("revoked_at", null),
  ]);

  if (profileError || roleError) {
    return jsonResponse({
      error: "profile_unavailable",
      message: "The account profile could not be loaded. Please try again.",
    }, 500);
  }

  if (!profile || profile.account_status !== "active") {
    return jsonResponse({
      error: "account_unavailable",
      message: "This account is unavailable. Sign out or contact the project administrator.",
    }, 403);
  }

  return jsonResponse({
    user: { id: userId },
    profile,
    roles: (roleRows ?? []).map((row) => row.role),
  });
}

async function updateProfile(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    return jsonResponse({
      error: "backend_not_configured",
      message: "Profile changes are unavailable in this public preview.",
    }, 503);
  }

  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > 2_048) {
    return jsonResponse({ error: "request_too_large" }, 413);
  }

  let body: unknown;
  try {
    const raw = await request.text();
    if (raw.length > 2_048) return jsonResponse({ error: "request_too_large" }, 413);
    body = JSON.parse(raw);
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  if (!hasOnlyDisplayNameFields(body)) {
    return jsonResponse({
      error: "invalid_profile_update",
      message: "Only a non-empty display_name of up to 80 characters can be changed.",
    }, 400);
  }

  const { data: context, error } = await createCallerContext(request, env);

  if (error || !context) {
    return jsonResponse({
      error: "authentication_required",
      code: error?.code ?? "missing_user_claims",
    }, error?.status ?? 401);
  }

  const { data: profile, error: updateError } = await context.supabase
    .from("profiles")
    .update({ display_name: body.display_name.trim() })
    .eq("user_id", context.userId)
    .select("user_id, display_name, account_status, created_at")
    .maybeSingle();

  if (updateError || !profile) {
    return jsonResponse({
      error: "account_unavailable",
      message: "This account is unavailable for profile changes.",
    }, 403);
  }

  return jsonResponse({ profile });
}

async function revokeRole(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    return jsonResponse({
      error: "backend_not_configured",
      message: "Role administration is unavailable in this public preview.",
    }, 503);
  }

  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > 2_048) {
    return jsonResponse({ error: "request_too_large" }, 413);
  }

  let body: unknown;
  try {
    const raw = await request.text();
    if (raw.length > 2_048) return jsonResponse({ error: "request_too_large" }, 413);
    body = JSON.parse(raw);
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  if (!hasOnlyRoleRevocationFields(body)) {
    return jsonResponse({
      error: "invalid_role_revocation",
      message: "Provide a valid target_user_id, role and reason. Additional fields are not accepted.",
    }, 400);
  }

  const { data: context, error } = await createCallerContext(request, env);
  if (error || !context) {
    return jsonResponse({
      error: "authentication_required",
      code: error?.code ?? "missing_user_claims",
    }, error?.status ?? 401);
  }

  const { error: revokeError } = await context.supabase.rpc("revoke_role_assignment", {
    target_user_id: body.target_user_id,
    target_role: body.role,
    reason_text: body.reason.trim(),
  });

  if (revokeError) {
    if (revokeError.message === "mfa_required") {
      return jsonResponse({
        error: "mfa_required",
        message: "Verify a second factor before managing account roles.",
      }, 403);
    }
    if (revokeError.code === "42501") {
      return jsonResponse({
        error: "role_management_forbidden",
        message: "Only an authorised account owner can manage roles.",
      }, 403);
    }
    if (revokeError.code === "P0002") {
      return jsonResponse({ error: "role_assignment_not_found" }, 404);
    }
    if (revokeError.code === "23514") {
      return jsonResponse({
        error: "last_owner_protected",
        message: "The final active owner role cannot be revoked.",
      }, 409);
    }
    if (revokeError.code === "22023") {
      return jsonResponse({ error: "invalid_revocation_reason" }, 400);
    }
    return jsonResponse({
      error: "role_revocation_failed",
      message: "The role could not be revoked. Please try again.",
    }, 500);
  }

  return jsonResponse({ revoked: true });
}


interface StaffInvitationError {
  code?: string;
  message?: string;
}

interface StaffInvitationCreateRequest {
  email: string;
  role: "grader" | "admin";
}

function asRows(value: unknown): Record<string, unknown>[] {
  if (Array.isArray(value)) {
    return value.filter((row): row is Record<string, unknown> =>
      typeof row === "object" && row !== null && !Array.isArray(row)
    );
  }
  if (typeof value === "object" && value !== null && !Array.isArray(value)) {
    return [value as Record<string, unknown>];
  }
  return [];
}

async function readBoundedJson(
  request: Request,
  maxBytes = 2_048,
): Promise<{ ok: true; body: unknown } | { ok: false; response: Response }> {
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > maxBytes) {
    return { ok: false, response: jsonResponse({ error: "request_too_large" }, 413) };
  }
  try {
    const raw = await request.text();
    if (new TextEncoder().encode(raw).byteLength > maxBytes) {
      return { ok: false, response: jsonResponse({ error: "request_too_large" }, 413) };
    }
    return { ok: true, body: JSON.parse(raw) as unknown };
  } catch {
    return { ok: false, response: jsonResponse({ error: "invalid_json" }, 400) };
  }
}

function hasOnlyInvitationCreateFields(value: unknown): value is StaffInvitationCreateRequest {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 2 &&
    Object.keys(record).every((key) => ["email", "role"].includes(key)) &&
    typeof record.email === "string" &&
    record.email.trim().length >= 6 &&
    record.email.trim().length <= 320 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(record.email.trim()) &&
    (record.role === "grader" || record.role === "admin");
}

function hasOnlyInvitationRevokeFields(value: unknown): value is { reason: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 1 &&
    Object.keys(record)[0] === "reason" &&
    typeof record.reason === "string" &&
    record.reason.trim().length >= 3 &&
    record.reason.trim().length <= 80;
}

function hasOnlyInvitationAcceptFields(value: unknown): value is { token: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 1 &&
    Object.keys(record)[0] === "token" &&
    typeof record.token === "string" &&
    /^[A-Za-z0-9_-]{43}$/.test(record.token);
}

function createInvitationToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const binary = Array.from(bytes, (byte) => String.fromCharCode(byte)).join("");
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function hashInvitationToken(token: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function staffInvitationRpcError(error: StaffInvitationError): Response {
  const message = error.message ?? "";
  if (message === "mfa_required") {
    return jsonResponse({ error: message, message: "Verify a second factor before managing or accepting staff invitations." }, 403);
  }
  if (message === "staff_invitation_forbidden") {
    return jsonResponse({ error: message, message: "This account is not authorised to manage or accept staff invitations." }, 403);
  }
  if (message === "invitation_email_mismatch" || message === "invitation_email_unverified") {
    return jsonResponse({
      error: message,
      message: message === "invitation_email_mismatch"
        ? "Sign in with the verified email address to which this invitation was issued."
        : "Verify this account's email address before accepting the invitation.",
    }, 403);
  }
  if (message === "invitation_not_found") {
    return jsonResponse({ error: message, message: "This invitation link is invalid or no longer available." }, 404);
  }
  if (["invitation_expired", "invitation_revoked", "invitation_already_used", "invitation_not_pending"].includes(message)) {
    return jsonResponse({ error: message, message: "This invitation is no longer active. Ask the account owner for a new invitation." }, 410);
  }
  if (message === "invitation_rate_limited") {
    return jsonResponse({ error: message, message: "Too many invitations were created recently. Try again later." }, 429);
  }
  if (["invitation_already_pending", "invitation_role_already_active"].includes(message)) {
    return jsonResponse({ error: message, message: "A pending invitation or active role already exists for this email and role." }, 409);
  }
  if (message.startsWith("invalid_invitation_")) {
    return jsonResponse({ error: message, message: "The invitation details are invalid. Check the email, role and reason." }, 400);
  }
  return jsonResponse({ error: "staff_invitation_failed", message: "The invitation could not be processed. Please try again." }, 500);
}

async function listStaffInvitations(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return jsonResponse({ error: "backend_not_configured" }, 503);
  const { data: context, error } = await createCallerContext(request, env);
  if (error || !context) {
    return jsonResponse({ error: "authentication_required", code: error?.code ?? "missing_user_claims" }, error?.status ?? 401);
  }
  const { data, error: listError } = await context.supabase.rpc("list_staff_invitations");
  if (listError) return staffInvitationRpcError(listError);
  return jsonResponse({ invitations: asRows(data) });
}

async function createStaffInvitation(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return jsonResponse({ error: "backend_not_configured" }, 503);
  const parsed = await readBoundedJson(request);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyInvitationCreateFields(parsed.body)) return jsonResponse({ error: "invalid_staff_invitation" }, 400);

  const { data: context, error } = await createCallerContext(request, env);
  if (error || !context) {
    return jsonResponse({ error: "authentication_required", code: error?.code ?? "missing_user_claims" }, error?.status ?? 401);
  }

  const token = createInvitationToken();
  const tokenHash = await hashInvitationToken(token);
  const { data, error: createError } = await context.supabase.rpc("create_staff_invitation", {
    p_email: parsed.body.email.trim().toLowerCase(),
    p_role: parsed.body.role,
    p_token_hash: tokenHash,
  });
  if (createError) return staffInvitationRpcError(createError);

  const invitation = asRows(data)[0];
  if (!invitation) return jsonResponse({ error: "staff_invitation_failed" }, 500);

  // Return the bearer token once in the URL fragment; fragments are not sent
  // in HTTP requests or Referer headers. The database stores only tokenHash.
  const invitationUrl = new URL("/account", new URL(request.url).origin);
  invitationUrl.hash = "staff-invite=" + token;
  return jsonResponse({ invitation, invite_url: invitationUrl.toString() }, 201);
}

async function revokeStaffInvitation(request: Request, env: WorkerEnv, invitationId: string): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return jsonResponse({ error: "backend_not_configured" }, 503);
  const parsed = await readBoundedJson(request);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyInvitationRevokeFields(parsed.body) || !isUuid(invitationId)) {
    return jsonResponse({ error: "invalid_staff_invitation_revocation" }, 400);
  }
  const { data: context, error } = await createCallerContext(request, env);
  if (error || !context) {
    return jsonResponse({ error: "authentication_required", code: error?.code ?? "missing_user_claims" }, error?.status ?? 401);
  }
  const { error: revokeError } = await context.supabase.rpc("revoke_staff_invitation", {
    p_invitation_id: invitationId,
    p_reason: parsed.body.reason.trim(),
  });
  if (revokeError) return staffInvitationRpcError(revokeError);
  return jsonResponse({ revoked: true });
}

async function acceptStaffInvitation(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) return jsonResponse({ error: "backend_not_configured" }, 503);
  const parsed = await readBoundedJson(request, 512);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyInvitationAcceptFields(parsed.body)) return jsonResponse({ error: "invalid_staff_invitation" }, 400);
  const { data: context, error } = await createCallerContext(request, env);
  if (error || !context) {
    return jsonResponse({ error: "authentication_required", code: error?.code ?? "missing_user_claims" }, error?.status ?? 401);
  }
  const tokenHash = await hashInvitationToken(parsed.body.token);
  const { data, error: acceptError } = await context.supabase.rpc("accept_staff_invitation", {
    p_token_hash: tokenHash,
  });
  if (acceptError) return staffInvitationRpcError(acceptError);
  const accepted = asRows(data)[0];
  if (!accepted || !["grader", "admin"].includes(String(accepted.accepted_role))) {
    return jsonResponse({ error: "staff_invitation_failed" }, 500);
  }
  return jsonResponse({ accepted: true, role: accepted.accepted_role });
}


type CallerContext = NonNullable<Awaited<ReturnType<typeof createCallerContext>>["data"]>;

function hasOnlyAttemptStartFields(value: unknown): value is { task_version_id: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 1 &&
    Object.keys(record)[0] === "task_version_id" &&
    isUuid(record.task_version_id);
}

function hasOnlyAttemptResponseFields(value: unknown): value is { response_text: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 1 &&
    Object.keys(record)[0] === "response_text" &&
    typeof record.response_text === "string" &&
    record.response_text.length <= 12_000;
}

function hasOnlyAttemptAssignmentFields(value: unknown): value is { grader_user_id: string; reason: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 2 &&
    Object.keys(record).every((key) => ["grader_user_id", "reason"].includes(key)) &&
    isUuid(record.grader_user_id) &&
    typeof record.reason === "string" &&
    record.reason.trim().length >= 3 &&
    record.reason.trim().length <= 240;
}

function hasOnlyAssessmentSubmissionFields(value: unknown): value is {
  task_version_id: string;
  idempotency_key: string;
  response_text: string;
} {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 3 &&
    Object.keys(record).every((key) =>
      ["task_version_id", "idempotency_key", "response_text"].includes(key)
    ) &&
    isUuid(record.task_version_id) &&
    isUuid(record.idempotency_key) &&
    typeof record.response_text === "string" &&
    record.response_text.trim().length > 0 &&
    record.response_text.length <= 12_000;
}

function hasOnlySubmissionAssignmentFields(value: unknown): value is { grader_user_id: string; reason: string } {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 2 &&
    Object.keys(record).every((key) => ["grader_user_id", "reason"].includes(key)) &&
    isUuid(record.grader_user_id) &&
    typeof record.reason === "string" &&
    record.reason.trim().length >= 3 &&
    record.reason.trim().length <= 240;
}

function hasOnlySubmissionTransitionFields(value: unknown): value is {
  target_status: "queued" | "withdrawn" | "closed";
  reason: string;
} {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  return Object.keys(record).length === 2 &&
    Object.keys(record).every(key => ["target_status", "reason"].includes(key)) &&
    ["queued", "withdrawn", "closed"].includes(String(record.target_status)) &&
    typeof record.reason === "string" &&
    record.reason.trim().length >= 3 &&
    record.reason.trim().length <= 240;
}

function hasOnlyPrivateQaRecordFields(value: unknown): value is {
  checks: Record<string, boolean | number | string>;
  status: "pending" | "passed" | "action_required";
  explanation: string;
  uncertainty?: string;
  reviewer_action: string;
} {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record);
  if (!keys.includes("checks") || !keys.includes("status") ||
      !keys.includes("explanation") || !keys.includes("reviewer_action") ||
      keys.some(key => ![
        "checks", "status", "explanation", "uncertainty", "reviewer_action",
      ].includes(key))) return false;

  if (typeof record.checks !== "object" || record.checks === null ||
      Array.isArray(record.checks)) return false;
  const checks = record.checks as Record<string, unknown>;
  const entries = Object.entries(checks);
  if (entries.length < 1 || entries.length > 30 || JSON.stringify(checks).length > 8_192) {
    return false;
  }
  if (!entries.every(([key, item]) =>
    /^[a-z][a-z0-9_]{1,39}$/.test(key) &&
    ((typeof item === "boolean") ||
      (typeof item === "string" && item.length <= 200) ||
      (typeof item === "number" && Number.isFinite(item)))
  )) return false;

  if (!["pending", "passed", "action_required"].includes(String(record.status)) ||
      typeof record.explanation !== "string" ||
      record.explanation.trim().length < 5 ||
      record.explanation.length > 2_000 ||
      typeof record.reviewer_action !== "string" ||
      record.reviewer_action.trim().length < 3 ||
      record.reviewer_action.length > 1_000) return false;

  return record.uncertainty === undefined ||
    (typeof record.uncertainty === "string" && record.uncertainty.length <= 1_000);
}

function hasOnlyAssessmentDraftFields(value: unknown): value is {
  overall_feedback: string;
  change_reason?: string;
  criterion_results: Array<{ criterion_id: string; points_awarded: number; feedback: string }>;
} {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record);
  if (!keys.includes("overall_feedback") || !keys.includes("criterion_results") ||
      keys.some((key) => !["overall_feedback", "change_reason", "criterion_results"].includes(key))) {
    return false;
  }
  if (typeof record.overall_feedback !== "string" ||
      record.overall_feedback.trim().length < 5 ||
      record.overall_feedback.length > 8000 ||
      !Array.isArray(record.criterion_results) ||
      record.criterion_results.length < 1 ||
      record.criterion_results.length > 30) return false;
  if (record.change_reason !== undefined &&
      (typeof record.change_reason !== "string" ||
       record.change_reason.trim().length < 3 ||
       record.change_reason.trim().length > 240)) return false;

  return record.criterion_results.every((item: unknown) => {
    if (typeof item !== "object" || item === null || Array.isArray(item)) return false;
    const result = item as Record<string, unknown>;
    return Object.keys(result).length === 3 &&
      ["criterion_id", "points_awarded", "feedback"].every((key) => key in result) &&
      isUuid(result.criterion_id) &&
      typeof result.points_awarded === "number" &&
      Number.isFinite(result.points_awarded) &&
      result.points_awarded >= 0 &&
      result.points_awarded <= 1000 &&
      Math.round(result.points_awarded * 100) === result.points_awarded * 100 &&
      typeof result.feedback === "string" &&
      result.feedback.trim().length >= 5 &&
      result.feedback.length <= 3000;
  });
}

function hasOnlyEmptyObject(value: unknown): boolean {
  return typeof value === "object" && value !== null && !Array.isArray(value) &&
    Object.keys(value as Record<string, unknown>).length === 0;
}

async function authenticatedCaller(request: Request, env: WorkerEnv) {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    return {
      context: null,
      response: jsonResponse({ error: "backend_not_configured" }, 503),
    };
  }
  const { data: context, error } = await createCallerContext(request, env);
  if (error || !context) {
    return {
      context: null,
      response: jsonResponse({
        error: "authentication_required",
        code: error?.code ?? "missing_user_claims",
      }, error?.status ?? 401),
    };
  }
  return { context, response: null };
}

async function requireActiveRole(context: CallerContext, role: AppRole): Promise<Response | null> {
  const { data, error } = await context.supabase
    .from("role_assignments")
    .select("id")
    .eq("user_id", context.userId)
    .eq("role", role)
    .is("revoked_at", null)
    .maybeSingle();
  if (error) return jsonResponse({ error: "authorization_unavailable" }, 503);
  if (!data) return jsonResponse({ error: "role_required" }, 403);
  return null;
}

function requireAal2(context: CallerContext): Response | null {
  return context.assuranceLevel === "aal2"
    ? null
    : jsonResponse({
        error: "mfa_required",
        message: "Verify a second factor before accessing protected staff operations.",
      }, 403);
}

async function auditAuthorizedProtectedRead(
  context: CallerContext,
  action: ProtectedReadAuditAction,
  targetId?: string,
): Promise<Response | null> {
  const { data, error } = await context.supabase.rpc("audit_authorized_protected_read", {
    p_action: action,
    p_target_id: targetId ?? null,
  });
  if (error) {
    return jsonResponse({
      error: "protected_read_audit_unavailable",
      message: "The protected read could not be audited. Please retry.",
    }, 503);
  }
  if (data !== true) {
    return jsonResponse({ error: "record_not_found_or_forbidden" }, 404);
  }
  return null;
}

async function listLearnerAttempts(request: Request, env: WorkerEnv): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;
  const auditDenied = await auditAuthorizedProtectedRead(auth.context, "student_attempt_list_authorized");
  if (auditDenied) return auditDenied;

  const { data, error } = await auth.context.supabase
    .from("attempts")
    .select("id, learner_id, task_version_id, status, started_at, submitted_at, task_versions(task_code, title, version, expected_min_words, ideal_words)")
    .eq("learner_id", auth.context.userId)
    .order("created_at", { ascending: false })
    .order("id", { ascending: false });

  if (error) return jsonResponse({ error: "attempts_unavailable" }, 500);
  return jsonResponse({ attempts: data ?? [] });
}

async function createLearnerAttempt(request: Request, env: WorkerEnv): Promise<Response> {
  const parsed = await readBoundedJson(request, 512);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyAttemptStartFields(parsed.body)) {
    return jsonResponse({ error: "invalid_attempt_request" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;

  const { data: taskVersion, error: taskError } = await auth.context.supabase
    .from("task_versions")
    .select("id, pathway_id")
    .eq("id", parsed.body.task_version_id)
    .eq("release_state", "published")
    .eq("response_mode", "typed")
    .maybeSingle();
  if (taskError) return jsonResponse({ error: "task_unavailable" }, 500);
  if (!taskVersion) return jsonResponse({ error: "task_not_available" }, 404);

  const { data: enrolment, error: enrolmentError } = await auth.context.supabase
    .from("course_enrolments")
    .select("id")
    .eq("learner_id", auth.context.userId)
    .eq("pathway_id", taskVersion.pathway_id)
    .eq("status", "active")
    .maybeSingle();
  if (enrolmentError) return jsonResponse({ error: "enrolment_unavailable" }, 500);
  if (!enrolment) return jsonResponse({ error: "task_not_available" }, 404);

  const { data, error: createError } = await auth.context.supabase.rpc("create_attempt", {
    p_task_version_id: taskVersion.id,
  });

  if (createError) {
    if (createError.message === "attempt_creation_forbidden") {
      return jsonResponse({ error: "attempt_creation_forbidden" }, 403);
    }
    if (createError.message === "attempt_task_not_available") {
      return jsonResponse({ error: "task_not_available" }, 404);
    }
    return jsonResponse({ error: "attempt_creation_failed" }, 500);
  }

  const created = asRows(data)[0];
  if (!created) return jsonResponse({ error: "attempt_creation_failed" }, 500);
  return jsonResponse({
    attempt: {
      id: created.attempt_id,
      learner_id: created.learner_id,
      task_version_id: created.task_version_id,
      status: created.status,
      started_at: created.started_at,
      submitted_at: created.submitted_at,
    },
  }, 201);
}

async function readAttemptDetails(context: CallerContext, attemptId: string) {
  const { data: attempt, error: attemptError } = await context.supabase
    .from("attempts")
    .select("id, learner_id, task_version_id, status, started_at, submitted_at, task_versions(task_code, title, version, expected_min_words, ideal_words), attempt_responses(id, prompt_id, response_text, word_count, version, updated_at)")
    .eq("id", attemptId)
    .maybeSingle();

  if (attemptError || !attempt) {
    return { attempt: null, prompts: null, error: attemptError };
  }

  const { data: prompts, error: promptsError } = await context.supabase
    .from("task_version_prompts")
    .select("id, sequence, prompt_text")
    .eq("task_version_id", attempt.task_version_id)
    .order("sequence", { ascending: true });

  if (promptsError) {
    return { attempt: null, prompts: null, error: promptsError };
  }
  return { attempt, prompts: prompts ?? [], error: null };
}

async function getLearnerAttempt(request: Request, env: WorkerEnv, attemptId: string): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;
  const auditDenied = await auditAuthorizedProtectedRead(
    auth.context, "student_attempt_read_authorized", attemptId,
  );
  if (auditDenied) return auditDenied;

  const result = await readAttemptDetails(auth.context, attemptId);
  if (result.error) return jsonResponse({ error: "attempt_unavailable" }, 500);
  if (!result.attempt) return jsonResponse({ error: "attempt_not_found" }, 404);
  return jsonResponse({ attempt: result.attempt, prompts: result.prompts });
}

async function saveAttemptResponse(
  request: Request,
  env: WorkerEnv,
  attemptId: string,
  promptId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 24_576);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyAttemptResponseFields(parsed.body)) {
    return jsonResponse({ error: "invalid_attempt_response" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;

  const { data: attempt, error: attemptError } = await auth.context.supabase
    .from("attempts")
    .select("id, task_version_id, status")
    .eq("id", attemptId)
    .maybeSingle();
  if (attemptError) return jsonResponse({ error: "attempt_unavailable" }, 500);
  if (!attempt) return jsonResponse({ error: "attempt_not_found" }, 404);
  if (attempt.status !== "in_progress") return jsonResponse({ error: "attempt_not_editable" }, 409);

  const { data: prompt, error: promptError } = await auth.context.supabase
    .from("task_version_prompts")
    .select("id")
    .eq("id", promptId)
    .eq("task_version_id", attempt.task_version_id)
    .maybeSingle();
  if (promptError) return jsonResponse({ error: "prompt_unavailable" }, 500);
  if (!prompt) return jsonResponse({ error: "prompt_not_found" }, 400);

  const { data, error: saveError } = await auth.context.supabase.rpc("save_attempt_response", {
    p_attempt_id: attemptId,
    p_prompt_id: promptId,
    p_response_text: parsed.body.response_text,
  });

  if (saveError) {
    if (saveError.message === "attempt_not_found") return jsonResponse({ error: "attempt_not_found" }, 404);
    if (saveError.message === "attempt_not_editable") return jsonResponse({ error: "attempt_not_editable" }, 409);
    if (saveError.message === "attempt_response_forbidden") return jsonResponse({ error: "attempt_response_forbidden" }, 403);
    if (saveError.message === "invalid_attempt_response" || saveError.message === "invalid_attempt_prompt") {
      return jsonResponse({ error: "invalid_attempt_response" }, 400);
    }
    return jsonResponse({ error: "attempt_response_save_failed" }, 500);
  }

  const response = asRows(data)[0];
  if (!response) return jsonResponse({ error: "attempt_response_save_failed" }, 500);
  return jsonResponse({ response });
}

async function submitLearnerAttempt(request: Request, env: WorkerEnv, attemptId: string): Promise<Response> {
  const parsed = await readBoundedJson(request, 128);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyEmptyObject(parsed.body)) return jsonResponse({ error: "invalid_attempt_submission" }, 400);

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;

  const { data, error } = await auth.context.supabase.rpc("submit_attempt", {
    p_attempt_id: attemptId,
  });
  if (error) {
    if (error.message === "attempt_not_found") return jsonResponse({ error: "attempt_not_found" }, 404);
    if (error.message === "attempt_not_in_progress") return jsonResponse({ error: "attempt_not_editable" }, 409);
    if (error.message === "attempt_response_required") return jsonResponse({ error: "attempt_response_required" }, 409);
    if (error.message === "attempt_submission_forbidden") return jsonResponse({ error: "attempt_submission_forbidden" }, 403);
    return jsonResponse({ error: "attempt_submission_failed" }, 500);
  }
  const submitted = asRows(data)[0];
  if (!submitted) return jsonResponse({ error: "attempt_submission_failed" }, 500);
  return jsonResponse({ attempt: submitted });
}

async function listLearnerSubmissions(request: Request, env: WorkerEnv): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;
  const auditDenied = await auditAuthorizedProtectedRead(auth.context, "student_submission_list_authorized");
  if (auditDenied) return auditDenied;

  const { data, error } = await auth.context.supabase
    .from("assessment_submissions")
    .select("id, learner_id, task_version_id, rubric_version_id, status, accepted_at, grading_due_at, sla_target_seconds, capacity_limit_snapshot, open_submissions_before_acceptance, task_versions(task_code, title, version), submission_versions(id, version_number, word_count, created_at)")
    .eq("learner_id", auth.context.userId)
    .order("accepted_at", { ascending: false })
    .order("id", { ascending: false });

  if (error) return jsonResponse({ error: "assessment_submissions_unavailable" }, 500);
  return jsonResponse({ submissions: data ?? [] });
}

async function acceptLearnerSubmission(request: Request, env: WorkerEnv): Promise<Response> {
  const parsed = await readBoundedJson(request, 24_576);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyAssessmentSubmissionFields(parsed.body)) {
    return jsonResponse({ error: "invalid_assessment_submission" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;

  const { data, error } = await auth.context.supabase.rpc("accept_assessment_submission", {
    p_task_version_id: parsed.body.task_version_id,
    p_idempotency_key: parsed.body.idempotency_key,
    p_response_text: parsed.body.response_text,
  });

  if (error) {
    if (error.message === "assessment_submission_forbidden") {
      return jsonResponse({ error: "assessment_submission_forbidden" }, 403);
    }
    if (error.message === "invalid_assessment_submission") {
      return jsonResponse({ error: "invalid_assessment_submission" }, 400);
    }
    if (error.message === "assessment_task_not_available") {
      return jsonResponse({ error: "assessment_task_not_available" }, 404);
    }
    if (error.message === "submission_capacity_unavailable") {
      return jsonResponse({ error: "submission_capacity_unavailable" }, 503);
    }
    if (error.message === "submission_capacity_full") {
      return jsonResponse({ error: "submission_capacity_full" }, 409);
    }
    if (error.message === "submission_idempotency_conflict") {
      return jsonResponse({ error: "submission_idempotency_conflict" }, 409);
    }
    return jsonResponse({ error: "assessment_submission_failed" }, 500);
  }

  const accepted = asRows(data)[0];
  if (!accepted) return jsonResponse({ error: "assessment_submission_failed" }, 500);
  return jsonResponse(
    { submission: accepted },
    accepted.is_replay === true ? 200 : 201,
  );
}

async function getLearnerSubmission(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "student");
  if (roleDenied) return roleDenied;
  const auditDenied = await auditAuthorizedProtectedRead(
    auth.context, "student_submission_read_authorized", submissionId,
  );
  if (auditDenied) return auditDenied;

  const { data, error } = await auth.context.supabase
    .from("assessment_submissions")
    .select("id, learner_id, task_version_id, rubric_version_id, status, accepted_at, grading_due_at, sla_target_seconds, capacity_limit_snapshot, open_submissions_before_acceptance, task_versions(task_code, title, version, expected_min_words, ideal_words), submission_versions(id, version_number, response_text, word_count, created_at), assessment_versions(id, version_number, total_points, max_points, overall_feedback, published_at, first_published_at, first_turnaround_seconds, seconds_to_due_at_first_publish, sla_met, criterion_results(id, criterion_code_snapshot, criterion_title_snapshot, descriptor_snapshot, points_awarded, max_points_snapshot, feedback))")
    .eq("id", submissionId)
    .eq("learner_id", auth.context.userId)
    .maybeSingle();

  if (error) return jsonResponse({ error: "assessment_submission_unavailable" }, 500);
  if (!data) return jsonResponse({ error: "assessment_submission_not_found" }, 404);
  return jsonResponse({ submission: data });
}

async function assignAssessmentSubmissionToGrader(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 2_048);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlySubmissionAssignmentFields(parsed.body)) {
    return jsonResponse({ error: "invalid_assessment_assignment" }, 400);
  }
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("assign_submission_to_grader", {
    p_submission_id: submissionId,
    p_grader_user_id: parsed.body.grader_user_id,
    p_reason: parsed.body.reason.trim(),
  });
  if (error) {
    if (error.message === "assessment_assignment_forbidden") return jsonResponse({ error: "assessment_assignment_forbidden" }, 403);
    if (error.message === "assessment_submission_not_found") return jsonResponse({ error: "assessment_submission_not_found" }, 404);
    if (error.message === "assessment_submission_not_assignable") return jsonResponse({ error: "assessment_submission_not_assignable" }, 409);
    if (error.message === "grader_not_available") return jsonResponse({ error: "grader_not_available" }, 400);
    if (error.message === "invalid_assessment_assignment") return jsonResponse({ error: "invalid_assessment_assignment" }, 400);
    return jsonResponse({ error: "assessment_assignment_failed" }, 500);
  }
  const assignment = asRows(data)[0];
  if (!assignment) return jsonResponse({ error: "assessment_assignment_failed" }, 500);
  return jsonResponse({ assignment }, 201);
}

async function reassignAssessmentSubmissionGrader(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 2_048);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlySubmissionAssignmentFields(parsed.body)) {
    return jsonResponse({ error: "invalid_assessment_assignment" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("reassign_submission_grader", {
    p_submission_id: submissionId,
    p_new_grader_user_id: parsed.body.grader_user_id,
    p_reason: parsed.body.reason.trim(),
  });
  if (error) {
    if (error.message === "assessment_assignment_forbidden") {
      return jsonResponse({ error: "assessment_assignment_forbidden" }, 403);
    }
    if (error.message === "assessment_submission_not_found") {
      return jsonResponse({ error: "assessment_submission_not_found" }, 404);
    }
    if ([
      "assessment_submission_not_reassignable",
      "assessment_assignment_not_found",
      "grader_already_assigned",
    ].includes(error.message)) {
      return jsonResponse({ error: error.message }, 409);
    }
    if ([
      "invalid_assessment_assignment",
      "grader_not_available",
      "invalid_assessment_draft_archive",
    ].includes(error.message)) {
      return jsonResponse({ error: error.message }, 400);
    }
    return jsonResponse({ error: "assessment_reassignment_failed" }, 500);
  }

  const reassignment = asRows(data)[0];
  if (!reassignment) return jsonResponse({ error: "assessment_reassignment_failed" }, 500);
  return jsonResponse({ reassignment });
}

async function transitionAssessmentSubmission(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 2_048);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlySubmissionTransitionFields(parsed.body)) {
    return jsonResponse({ error: "invalid_assessment_transition" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("transition_assessment_submission", {
    p_submission_id: submissionId,
    p_target_status: parsed.body.target_status,
    p_reason: parsed.body.reason.trim(),
  });
  if (error) {
    if (error.message === "assessment_transition_forbidden") {
      return jsonResponse({ error: "assessment_transition_forbidden" }, 403);
    }
    if (error.message === "assessment_submission_not_found") {
      return jsonResponse({ error: "assessment_submission_not_found" }, 404);
    }
    if (error.message === "invalid_assessment_transition") {
      return jsonResponse({ error: "invalid_assessment_transition" }, 409);
    }
    if (error.message === "invalid_assessment_draft_archive") {
      return jsonResponse({ error: "invalid_assessment_transition" }, 400);
    }
    return jsonResponse({ error: "assessment_transition_failed" }, 500);
  }

  const transition = asRows(data)[0];
  if (!transition) return jsonResponse({ error: "assessment_transition_failed" }, 500);
  return jsonResponse({ transition });
}

async function createOwnerPrivateQaRecord(
  request: Request,
  env: WorkerEnv,
  assessmentVersionId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 12_288);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyPrivateQaRecordFields(parsed.body)) {
    return jsonResponse({ error: "invalid_private_qa_record" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("create_private_qa_record", {
    p_assessment_version_id: assessmentVersionId,
    p_checks: parsed.body.checks,
    p_status: parsed.body.status,
    p_explanation: parsed.body.explanation.trim(),
    p_uncertainty: parsed.body.uncertainty?.trim() ?? "",
    p_reviewer_action: parsed.body.reviewer_action.trim(),
  });
  if (error) {
    if (error.message === "private_qa_forbidden") {
      return jsonResponse({ error: "private_qa_forbidden" }, 403);
    }
    if (error.message === "private_qa_assessment_version_not_found") {
      return jsonResponse({ error: "assessment_version_not_found" }, 404);
    }
    if (["invalid_private_qa_record", "invalid_private_qa_checks"].includes(error.message)) {
      return jsonResponse({ error: error.message }, 400);
    }
    return jsonResponse({ error: "private_qa_record_create_failed" }, 500);
  }

  const qaRecord = asRows(data)[0];
  if (!qaRecord) return jsonResponse({ error: "private_qa_record_create_failed" }, 500);
  return jsonResponse({ qa_record: qaRecord }, 201);
}

async function listOwnerPrivateQaRecords(
  request: Request,
  env: WorkerEnv,
  assessmentVersionId: string,
): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("get_private_qa_records", {
    p_assessment_version_id: assessmentVersionId,
  });
  if (error) {
    if (error.message === "private_qa_forbidden") {
      return jsonResponse({ error: "private_qa_forbidden" }, 403);
    }
    if (error.message === "private_qa_assessment_version_not_found") {
      return jsonResponse({ error: "assessment_version_not_found" }, 404);
    }
    return jsonResponse({ error: "private_qa_records_unavailable" }, 500);
  }

  return jsonResponse({ qa_records: asRows(data) });
}

async function listAssignedAssessmentSubmissions(request: Request, env: WorkerEnv): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "grader");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;
  const auditDenied = await auditAuthorizedProtectedRead(auth.context, "grader_submission_queue_authorized");
  if (auditDenied) return auditDenied;

  const { data, error } = await auth.context.supabase
    .from("assessment_submissions")
    .select("id, learner_id, task_version_id, rubric_version_id, status, accepted_at, grading_due_at, sla_target_seconds, task_versions(task_code, title, version)")
    .in("status", ["assigned", "grading", "feedback_published"])
    .order("accepted_at", { ascending: true })
    .order("id", { ascending: true })
    .limit(100);
  if (error) return jsonResponse({ error: "grader_assessment_queue_unavailable" }, 500);
  return jsonResponse({ submissions: data ?? [] });
}

async function getAssignedAssessmentSubmission(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "grader");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;
  const auditDenied = await auditAuthorizedProtectedRead(
    auth.context, "grader_submission_read_authorized", submissionId,
  );
  if (auditDenied) return auditDenied;

  const { data: submission, error: submissionError } = await auth.context.supabase
    .from("assessment_submissions")
    .select("id, learner_id, task_version_id, rubric_version_id, status, accepted_at, grading_due_at, sla_target_seconds, task_versions(task_code, title, version, expected_min_words, ideal_words)")
    .eq("id", submissionId)
    .maybeSingle();
  if (submissionError) return jsonResponse({ error: "assessment_submission_unavailable" }, 500);
  if (!submission) return jsonResponse({ error: "assessment_submission_not_found" }, 404);

  const [
    responseResult,
    promptResult,
    rubricResult,
    criteriaResult,
    assignmentResult,
    versionsResult,
    draftResult,
  ] = await Promise.all([
    auth.context.supabase
      .from("submission_versions")
      .select("id, version_number, response_text, word_count, created_at")
      .eq("submission_id", submissionId)
      .order("version_number", { ascending: true }),
    auth.context.supabase
      .from("task_version_prompts")
      .select("id, sequence, prompt_text")
      .eq("task_version_id", submission.task_version_id)
      .order("sequence", { ascending: true }),
    auth.context.supabase
      .from("rubric_versions")
      .select("id, rubric_id, version, title")
      .eq("id", submission.rubric_version_id)
      .maybeSingle(),
    auth.context.supabase
      .from("rubric_criteria")
      .select("id, criterion_code, sequence, title, descriptor, max_points")
      .eq("rubric_version_id", submission.rubric_version_id)
      .order("sequence", { ascending: true }),
    auth.context.supabase
      .from("submission_grader_assignments")
      .select("id, grader_user_id, assigned_at, reason")
      .eq("submission_id", submissionId)
      .eq("grader_user_id", auth.context.userId)
      .is("revoked_at", null)
      .maybeSingle(),
    auth.context.supabase
      .from("assessment_versions")
      .select("id, version_number, total_points, max_points, overall_feedback, published_at, first_published_at, first_turnaround_seconds, seconds_to_due_at_first_publish, sla_met, criterion_results(id, rubric_criterion_id, criterion_code_snapshot, criterion_title_snapshot, descriptor_snapshot, points_awarded, max_points_snapshot, feedback)")
      .eq("submission_id", submissionId)
      .order("version_number", { ascending: true }),
    auth.context.supabase.rpc("get_assessment_draft", { p_submission_id: submissionId }),
  ]);

  if (responseResult.error || promptResult.error || rubricResult.error ||
      criteriaResult.error || assignmentResult.error || versionsResult.error || draftResult.error) {
    return jsonResponse({ error: "grader_assessment_detail_unavailable" }, 500);
  }
  if (!assignmentResult.data) return jsonResponse({ error: "assessment_submission_not_found" }, 404);

  return jsonResponse({
    submission,
    response_versions: responseResult.data ?? [],
    prompts: promptResult.data ?? [],
    rubric: rubricResult.data,
    criteria: criteriaResult.data ?? [],
    assignment: assignmentResult.data,
    published_versions: versionsResult.data ?? [],
    draft: asRows(draftResult.data)[0] ?? null,
  });
}

async function saveAssignedAssessmentDraft(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 24_576);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyAssessmentDraftFields(parsed.body)) {
    return jsonResponse({ error: "invalid_assessment_draft" }, 400);
  }
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "grader");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("save_assessment_draft", {
    p_submission_id: submissionId,
    p_overall_feedback: parsed.body.overall_feedback.trim(),
    p_change_reason: parsed.body.change_reason?.trim() ?? null,
    p_criterion_results: parsed.body.criterion_results,
  });
  if (error) {
    if (error.message === "grader_assessment_forbidden") return jsonResponse({ error: "grader_assessment_forbidden" }, 403);
    if (error.message === "assessment_submission_not_found") return jsonResponse({ error: "assessment_submission_not_found" }, 404);
    if (error.message === "assessment_change_reason_required") return jsonResponse({ error: "assessment_change_reason_required" }, 400);
    if (error.message === "invalid_assessment_draft" || error.message === "invalid_assessment_criteria") {
      return jsonResponse({ error: "invalid_assessment_draft" }, 400);
    }
    return jsonResponse({ error: "assessment_draft_save_failed" }, 500);
  }
  const draft = asRows(data)[0];
  if (!draft) return jsonResponse({ error: "assessment_draft_save_failed" }, 500);
  return jsonResponse({ draft });
}

async function publishAssignedAssessmentFeedback(
  request: Request,
  env: WorkerEnv,
  submissionId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request, 128);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyEmptyObject(parsed.body)) return jsonResponse({ error: "invalid_assessment_publication" }, 400);

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "grader");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("publish_assessment_feedback", {
    p_submission_id: submissionId,
  });
  if (error) {
    if (error.message === "grader_assessment_forbidden") return jsonResponse({ error: "grader_assessment_forbidden" }, 403);
    if (error.message === "assessment_submission_not_found") return jsonResponse({ error: "assessment_submission_not_found" }, 404);
    if (error.message === "assessment_draft_required") return jsonResponse({ error: "assessment_draft_required" }, 409);
    return jsonResponse({ error: "assessment_publication_failed" }, 500);
  }
  const published = asRows(data)[0];
  if (!published) return jsonResponse({ error: "assessment_publication_failed" }, 500);
  return jsonResponse({ assessment: published }, 201);
}

async function listAssessmentSubmissionQueue(request: Request, env: WorkerEnv): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;
  const auditDenied = await auditAuthorizedProtectedRead(auth.context, "owner_submission_queue_authorized");
  if (auditDenied) return auditDenied;

  const { data, error } = await auth.context.supabase
    .from("assessment_submissions")
    .select("id, learner_id, task_version_id, rubric_version_id, status, accepted_at, grading_due_at, sla_target_seconds, capacity_limit_snapshot, open_submissions_before_acceptance, task_versions(task_code, title, version)")
    .in("status", ["queued", "assigned", "grading"])
    .order("accepted_at", { ascending: true })
    .order("id", { ascending: true })
    .limit(100);

  if (error) return jsonResponse({ error: "assessment_submission_queue_unavailable" }, 500);
  return jsonResponse({ submissions: data ?? [] });
}

async function listGraderQueue(request: Request, env: WorkerEnv): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "grader");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;
  const auditDenied = await auditAuthorizedProtectedRead(auth.context, "grader_attempt_queue_authorized");
  if (auditDenied) return auditDenied;

  const { data, error } = await auth.context.supabase
    .from("attempts")
    .select("id, learner_id, task_version_id, status, submitted_at, task_versions(task_code, title, version)")
    .eq("status", "submitted")
    .order("submitted_at", { ascending: true })
    .order("id", { ascending: true });

  if (error) return jsonResponse({ error: "grader_queue_unavailable" }, 500);
  return jsonResponse({ attempts: data ?? [] });
}

async function getGraderAttempt(request: Request, env: WorkerEnv, attemptId: string): Promise<Response> {
  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "grader");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;
  const auditDenied = await auditAuthorizedProtectedRead(
    auth.context, "grader_attempt_read_authorized", attemptId,
  );
  if (auditDenied) return auditDenied;

  const result = await readAttemptDetails(auth.context, attemptId);
  if (result.error) return jsonResponse({ error: "attempt_unavailable" }, 500);
  if (!result.attempt) return jsonResponse({ error: "attempt_not_found" }, 404);
  if (result.attempt.status !== "submitted") return jsonResponse({ error: "attempt_not_found" }, 404);
  return jsonResponse({ attempt: result.attempt, prompts: result.prompts });
}

async function assignAttemptToGrader(
  request: Request,
  env: WorkerEnv,
  attemptId: string,
): Promise<Response> {
  const parsed = await readBoundedJson(request);
  if (!parsed.ok) return parsed.response;
  if (!hasOnlyAttemptAssignmentFields(parsed.body)) {
    return jsonResponse({ error: "invalid_attempt_assignment" }, 400);
  }

  const auth = await authenticatedCaller(request, env);
  if (!auth.context) return auth.response!;
  const roleDenied = await requireActiveRole(auth.context, "owner");
  if (roleDenied) return roleDenied;
  const mfaDenied = requireAal2(auth.context);
  if (mfaDenied) return mfaDenied;

  const { data, error } = await auth.context.supabase.rpc("assign_attempt_to_grader", {
    p_attempt_id: attemptId,
    p_grader_user_id: parsed.body.grader_user_id,
    p_reason: parsed.body.reason.trim(),
  });
  if (error) {
    if (error.message === "mfa_required") return jsonResponse({ error: "mfa_required" }, 403);
    if (error.message === "attempt_assignment_forbidden") return jsonResponse({ error: "attempt_assignment_forbidden" }, 403);
    if (error.message === "attempt_not_found") return jsonResponse({ error: "attempt_not_found" }, 404);
    if (error.message === "attempt_already_assigned") return jsonResponse({ error: "attempt_already_assigned" }, 409);
    if (error.message === "attempt_not_submitted") return jsonResponse({ error: "attempt_not_submitted" }, 409);
    if (error.message === "grader_not_available") return jsonResponse({ error: "grader_not_available" }, 400);
    if (error.message === "invalid_assignment_reason") return jsonResponse({ error: "invalid_assignment_reason" }, 400);
    return jsonResponse({ error: "attempt_assignment_failed" }, 500);
  }
  const assignment = asRows(data)[0];
  if (!assignment) return jsonResponse({ error: "attempt_assignment_failed" }, 500);
  return jsonResponse({ assignment }, 201);
}

async function handleApi(request: Request, env: WorkerEnv): Promise<Response> {
  const url = new URL(request.url);
  if (url.pathname === "/api/health" && request.method === "GET") {
    return jsonResponse({ status: "ok", service: "gradioprep-api" });
  }

  if (url.pathname === "/api/v1/me" && request.method === "GET") {
    return authenticatedMe(request, env);
  }

  if (url.pathname === "/api/v1/me" && request.method === "PATCH") {
    return updateProfile(request, env);
  }

  if (url.pathname === "/api/v1/admin/roles/revoke" && request.method === "POST") {
    return revokeRole(request, env);
  }

  if (url.pathname === "/api/v1/admin/staff-invitations" && request.method === "GET") {
    return listStaffInvitations(request, env);
  }

  if (url.pathname === "/api/v1/admin/staff-invitations" && request.method === "POST") {
    return createStaffInvitation(request, env);
  }

  const invitationRevokeMatch = url.pathname.match(/^\/api\/v1\/admin\/staff-invitations\/([0-9a-f-]{36})\/revoke$/i);
  if (invitationRevokeMatch && request.method === "POST") {
    return revokeStaffInvitation(request, env, invitationRevokeMatch[1]);
  }

  if (url.pathname === "/api/v1/staff-invitations/accept" && request.method === "POST") {
    return acceptStaffInvitation(request, env);
  }

  if (url.pathname === "/api/v1/learner/attempts" && request.method === "GET") {
    return listLearnerAttempts(request, env);
  }

  if (url.pathname === "/api/v1/learner/attempts" && request.method === "POST") {
    return createLearnerAttempt(request, env);
  }

  const attemptResponseMatch = url.pathname.match(/^\/api\/v1\/learner\/attempts\/([0-9a-f-]{36})\/responses\/([0-9a-f-]{36})$/i);
  if (attemptResponseMatch && request.method === "PUT") {
    return saveAttemptResponse(request, env, attemptResponseMatch[1], attemptResponseMatch[2]);
  }

  const attemptSubmitMatch = url.pathname.match(/^\/api\/v1\/learner\/attempts\/([0-9a-f-]{36})\/submit$/i);
  if (attemptSubmitMatch && request.method === "POST") {
    return submitLearnerAttempt(request, env, attemptSubmitMatch[1]);
  }

  const learnerAttemptMatch = url.pathname.match(/^\/api\/v1\/learner\/attempts\/([0-9a-f-]{36})$/i);
  if (learnerAttemptMatch && request.method === "GET") {
    return getLearnerAttempt(request, env, learnerAttemptMatch[1]);
  }

  if (url.pathname === "/api/v1/learner/submissions" && request.method === "GET") {
    return listLearnerSubmissions(request, env);
  }

  if (url.pathname === "/api/v1/learner/submissions" && request.method === "POST") {
    return acceptLearnerSubmission(request, env);
  }

  const learnerSubmissionMatch = url.pathname.match(/^\/api\/v1\/learner\/submissions\/([0-9a-f-]{36})$/i);
  if (learnerSubmissionMatch && request.method === "GET") {
    return getLearnerSubmission(request, env, learnerSubmissionMatch[1]);
  }

  const assignSubmissionMatch = url.pathname.match(/^\/api\/v1\/admin\/submissions\/([0-9a-f-]{36})\/assign$/i);
  if (assignSubmissionMatch && request.method === "POST") {
    return assignAssessmentSubmissionToGrader(request, env, assignSubmissionMatch[1]);
  }

  const ownerSubmissionReassignMatch = url.pathname.match(/^\/api\/v1\/owner\/submissions\/([0-9a-f-]{36})\/reassign$/i);
  if (ownerSubmissionReassignMatch && request.method === "POST") {
    return reassignAssessmentSubmissionGrader(request, env, ownerSubmissionReassignMatch[1]);
  }

  const ownerSubmissionTransitionMatch = url.pathname.match(/^\/api\/v1\/owner\/submissions\/([0-9a-f-]{36})\/transition$/i);
  if (ownerSubmissionTransitionMatch && request.method === "POST") {
    return transitionAssessmentSubmission(request, env, ownerSubmissionTransitionMatch[1]);
  }

  const ownerPrivateQaMatch = url.pathname.match(/^\/api\/v1\/owner\/assessment-versions\/([0-9a-f-]{36})\/private-qa$/i);
  if (ownerPrivateQaMatch && request.method === "GET") {
    return listOwnerPrivateQaRecords(request, env, ownerPrivateQaMatch[1]);
  }
  if (ownerPrivateQaMatch && request.method === "POST") {
    return createOwnerPrivateQaRecord(request, env, ownerPrivateQaMatch[1]);
  }

  if (url.pathname === "/api/v1/grader/submissions" && request.method === "GET") {
    return listAssignedAssessmentSubmissions(request, env);
  }

  const graderSubmissionMatch = url.pathname.match(/^\/api\/v1\/grader\/submissions\/([0-9a-f-]{36})$/i);
  if (graderSubmissionMatch && request.method === "GET") {
    return getAssignedAssessmentSubmission(request, env, graderSubmissionMatch[1]);
  }

  const graderDraftMatch = url.pathname.match(/^\/api\/v1\/grader\/submissions\/([0-9a-f-]{36})\/draft$/i);
  if (graderDraftMatch && request.method === "PUT") {
    return saveAssignedAssessmentDraft(request, env, graderDraftMatch[1]);
  }

  const graderPublishMatch = url.pathname.match(/^\/api\/v1\/grader\/submissions\/([0-9a-f-]{36})\/publish$/i);
  if (graderPublishMatch && request.method === "POST") {
    return publishAssignedAssessmentFeedback(request, env, graderPublishMatch[1]);
  }

  if (url.pathname === "/api/v1/admin/submissions/queue" && request.method === "GET") {
    return listAssessmentSubmissionQueue(request, env);
  }

  if (url.pathname === "/api/v1/grader/queue" && request.method === "GET") {
    return listGraderQueue(request, env);
  }

  const graderAttemptMatch = url.pathname.match(/^\/api\/v1\/grader\/attempts\/([0-9a-f-]{36})$/i);
  if (graderAttemptMatch && request.method === "GET") {
    return getGraderAttempt(request, env, graderAttemptMatch[1]);
  }

  const assignAttemptMatch = url.pathname.match(/^\/api\/v1\/admin\/attempts\/([0-9a-f-]{36})\/assign$/i);
  if (assignAttemptMatch && request.method === "POST") {
    return assignAttemptToGrader(request, env, assignAttemptMatch[1]);
  }

  if (url.pathname.startsWith("/api/")) {
    return jsonResponse({ error: "not_found" }, 404);
  }

  return jsonResponse({ error: "not_found" }, 404);
}

export default {
  async fetch(request: Request, env: WorkerEnv): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname.startsWith("/api/")) {
      try {
        return await handleApi(request, env);
      } catch {
        return jsonResponse({
          error: "internal_error",
          message: "The request could not be completed.",
        }, 500);
      }
    }

    return env.ASSETS.fetch(request);
  },
};
