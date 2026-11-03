import { createContextClient, verifyAuth } from "@supabase/server/core";

type WorkerEnv = Env & {
  SUPABASE_URL?: string;
  SUPABASE_PUBLISHABLE_KEY?: string;
};

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

  return {
    data: { supabase, userId: auth.userClaims.id },
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
