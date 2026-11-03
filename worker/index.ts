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
  const { data: currentUser, error: currentUserError } = await supabase.auth.getUser();
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
