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

  return values;
}

let output;
try {
  output = execFileSync(
    "npx",
    ["supabase", "status", "--env", "--output-format", "text"],
    { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
  );
} catch {
  console.error("Could not read the local Supabase environment. Start it with npm run supabase:start.");
  process.exit(1);
}

const values = parseEnvOutput(output);
const url = values.get("API_URL");
const publishableKey =
  values.get("PUBLISHABLE_KEY") ??
  values.get("SUPABASE_PUBLISHABLE_KEY") ??
  values.get("ANON_KEY");

if (!url || !publishableKey) {
  console.error("The local Supabase CLI did not report an API URL and publishable/anonymous key.");
  process.exit(1);
}

const safeUrl = new URL(url);
if (!["127.0.0.1", "localhost", "::1"].includes(safeUrl.hostname)) {
  console.error("Refusing to write environment files for a non-local Supabase URL.");
  process.exit(1);
}

writeFileSync(
  ".dev.vars",
  `SUPABASE_URL=${url}\nSUPABASE_PUBLISHABLE_KEY=${publishableKey}\n`,
  { mode: 0o600 },
);

writeFileSync(
  ".env.local",
  `VITE_SUPABASE_URL=${url}\nVITE_SUPABASE_PUBLISHABLE_KEY=${publishableKey}\n`,
  { mode: 0o600 },
);

console.log("Local Supabase URL and publishable key written to ignored development-only files. No service-role key was copied.");
