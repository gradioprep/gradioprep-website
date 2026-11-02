import { createSupabaseContext } from "@supabase/server";

type WorkerEnv = Env & {
  SUPABASE_URL?: string;
  SUPABASE_PUBLISHABLE_KEY?: string;
};

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

async function authenticatedMe(request: Request, env: WorkerEnv): Promise<Response> {
  if (!env.SUPABASE_URL || !env.SUPABASE_PUBLISHABLE_KEY) {
    return jsonResponse({
      error: "backend_not_configured",
      message: "Authentication is not connected to this public preview. Use the local development environment for synthetic account testing.",
    }, 503);
  }

  const { data: context, error } = await createSupabaseContext(request, {
    auth: "user",
    env: {
      url: env.SUPABASE_URL,
      publishableKeys: { default: env.SUPABASE_PUBLISHABLE_KEY },
    },
  });

  if (error || !context?.userClaims?.id) {
    const status = error?.status ?? 401;
    return jsonResponse({
      error: "authentication_required",
      message: "A valid signed-in account is required.",
    }, status);
  }

  const userId = context.userClaims.id;
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

  const { data: context, error } = await createSupabaseContext(request, {
    auth: "user",
    env: {
      url: env.SUPABASE_URL,
      publishableKeys: { default: env.SUPABASE_PUBLISHABLE_KEY },
    },
  });

  if (error || !context?.userClaims?.id) {
    return jsonResponse({ error: "authentication_required" }, error?.status ?? 401);
  }

  const { data: profile, error: updateError } = await context.supabase
    .from("profiles")
    .update({ display_name: body.display_name.trim() })
    .eq("user_id", context.userClaims.id)
    .select("user_id, display_name, account_status, created_at")
    .maybeSingle();

  if (updateError || !profile) {
    return jsonResponse({ error: "profile_update_failed" }, 403);
  }

  return jsonResponse({ profile });
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
