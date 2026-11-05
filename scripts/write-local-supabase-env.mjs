import { randomBytes } from "node:crypto";
import { execFileSync } from "node:child_process";
import { writeFileSync } from "node:fs";

function parseEnvOutput(output) {
  const values = new Map();

  for (const line of output.split(/\r?\n/)) {
    const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (!match) continue;

    let value = match[2].trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    values.set(match[1], value);
  }

  // Older CLI output uses human-readable labels instead of KEY=value pairs.
  const apiLine = output.match(/^\s*API URL:\s*(\S+)/im);
  const publishableLine = output.match(/^\s*(?:publishable key|anon key):\s*(\S+)/im);
  const serviceRoleLine = output.match(/^\s*(?:service_role key|service role key):\s*(\S+)/im);
  if (apiLine && !values.has("API_URL")) values.set("API_URL", apiLine[1]);
  if (publishableLine && !values.has("PUBLISHABLE_KEY")) values.set("PUBLISHABLE_KEY", publishableLine[1]);
  if (serviceRoleLine && !values.has("SERVICE_ROLE_KEY")) values.set("SERVICE_ROLE_KEY", serviceRoleLine[1]);

  return values;
}

function readLocalStatus() {
  const attempts = [
    ["status", "--env", "--output-format", "text"],
    ["status", "--output", "env"],
    ["status", "-o", "env"],
    ["status", "--output", "json"],
  ];

  for (const args of attempts) {
    try {
      const output = execFileSync(
        "npx",
        ["supabase", ...args],
        { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
      );

      try {
        const json = JSON.parse(output);
        if (json && typeof json === "object") {
          const env = json.env && typeof json.env === "object" ? json.env : json;
          const entries = Object.entries(env).filter(([, value]) => typeof value === "string");
          return new Map(entries);
        }
      } catch {
        // Environment text and human-readable status are parsed below.
      }

      const values = parseEnvOutput(output);
      if (values.size > 0) return values;
    } catch {
      // Try the next documented CLI output style without printing its stderr,
      // which can contain local keys.
    }
  }

  throw new Error("No supported local Supabase status format was available.");
}

let values;
try {
  values = readLocalStatus();
} catch {
  console.error("Could not read the local Supabase environment. Start it with npm run supabase:start.");
  process.exit(1);
}

const url =
  values.get("API_URL") ??
  values.get("SUPABASE_URL") ??
  values.get("SUPA_API_URL");
const publishableKey =
  values.get("PUBLISHABLE_KEY") ??
  values.get("SUPABASE_PUBLISHABLE_KEY") ??
  values.get("ANON_KEY") ??
  values.get("SUPA_ANON_KEY");
const serviceRoleKey = values.get("SERVICE_ROLE_KEY") ?? values.get("SUPABASE_SERVICE_ROLE_KEY");

if (!url || !publishableKey || !serviceRoleKey) {
  console.error("The local Supabase CLI did not report an API URL, publishable/anonymous key and service-role key.");
  process.exit(1);
}

let safeUrl;
try {
  safeUrl = new URL(url);
} catch {
  console.error("The local Supabase CLI returned an invalid API URL.");
  process.exit(1);
}

if (!["127.0.0.1", "localhost", "::1"].includes(safeUrl.hostname)) {
  console.error("Refusing to write environment files for a non-local Supabase URL.");
  process.exit(1);
}

const localRaceBarrierSecret = randomBytes(32).toString("hex");

writeFileSync(
  ".dev.vars",
  `SUPABASE_URL=${url}\nSUPABASE_PUBLISHABLE_KEY=${publishableKey}\nSUPABASE_SERVICE_ROLE_KEY=${serviceRoleKey}\nGRADIPREP_TEST_RACE_BARRIER_SECRET=${localRaceBarrierSecret}\n`,
  { mode: 0o600 },
);

writeFileSync(
  ".env.local",
  `VITE_SUPABASE_URL=${url}\nVITE_SUPABASE_PUBLISHABLE_KEY=${publishableKey}\n`,
  { mode: 0o600 },
);

console.log("Local Supabase URL and publishable key written to ignored development files; the service-role key is restricted to .dev.vars and excluded from .env.local/browser builds.");
