import { createHash, randomUUID } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve, sep } from "node:path";
import { createClient } from "@supabase/supabase-js";

const projectId = "gradioprep-local";
const databaseContainerName = "supabase_db_" + projectId;
const bucketName = "private-submissions";
const restoreDatabaseName = "gradioprep_phase1e_restore";
const restoreRoleName = "supabase_admin";
const containerDumpPath = "/tmp/gradioprep-phase1e-backup.dump";
const containerCorruptPath = "/tmp/gradioprep-phase1e-corrupt.dump";
const appRoot = process.cwd();

function fail(message) {
  throw new Error(message);
}

function safeDiagnostic(stderr) {
  const lines = String(stderr ?? "").split(/\r?\n/);
  // Keep PostgreSQL's structured error headers, never the SQL statement or
  // nearby LINE/CONTEXT output that can contain stored application data.
  const diagnosticLines = lines.filter(line =>
    /^\s*(?:pg_restore:\s+(?:error|warning):|ERROR:|FATAL:|PANIC:|HINT:)/i.test(line)
  );
  return diagnosticLines
    .slice(0, 5)
    .join(" ")
    .replace(/eyJ[A-Za-z0-9_-]{20,}/g, "[redacted-token]")
    .replace(/\b(?:sb_secret|sb_publishable)_[A-Za-z0-9_-]{10,}\b/g, "[redacted-key]")
    .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, "[redacted-email]")
    .replace(/(?:postgres(?:ql)?:\/\/)[^\s"'<>]+/gi, "[redacted-database-url]")
    .replace(/\b(?:password|secret|token|api[_ -]?key)\s*[=:]\s*[^,\s;]+/gi, "[redacted-credential]")
    .slice(0, 700);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: appRoot,
    encoding: "utf8",
    maxBuffer: 32 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
    ...options,
  });
  if (result.error) fail(command + " could not be started.");
  if (result.status !== 0) {
    const safeArgs = args.slice(0, 5).map((arg, index) => {
      if (args[index - 1] === "-c") return "[SQL omitted]";
      return String(arg).replace(/eyJ[A-Za-z0-9_-]{20,}/g, "[redacted]");
    }).join(" ");
    const safeStderr = safeDiagnostic(result.stderr);
    fail(
      command + " " + safeArgs + " failed (exit " + String(result.status) + ")." +
      (safeStderr ? " Safe diagnostic: " + safeStderr : ""),
    );
  }
  return String(result.stdout ?? "").trim();
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function readLocalEnvironment() {
  const envPath = join(appRoot, ".dev.vars");
  if (!existsSync(envPath)) fail("Missing .dev.vars. Start local Supabase and run npm run supabase:env first.");

  const values = new Map();
  for (const line of readFileSync(envPath, "utf8").split(/\r?\n/)) {
    const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (match) values.set(match[1], match[2].trim());
  }

  const url = values.get("SUPABASE_URL");
  const serviceKey = values.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) fail("Local Supabase URL or server-only service key is missing.");

  let parsedUrl;
  try {
    parsedUrl = new URL(url);
  } catch {
    fail("SUPABASE_URL is invalid.");
  }
  if (
    parsedUrl.protocol !== "http:" ||
    !["127.0.0.1", "localhost", "::1"].includes(parsedUrl.hostname) ||
    parsedUrl.port !== "54321"
  ) {
    fail("Refusing backup/restore unless Supabase is the expected local-only service at 127.0.0.1:54321.");
  }

  return { url, serviceKey };
}

function findDatabaseContainer() {
  const names = run("docker", ["ps", "--format", "{{.Names}}"]).split(/\r?\n/).filter(Boolean);
  if (!names.includes(databaseContainerName)) {
    fail("The expected local Supabase database container is not running. Start it with npm run supabase:start.");
  }
  return databaseContainerName;
}

function dockerExec(container, args, options = {}) {
  return run("docker", ["exec", container, ...args], options);
}

function assertRestoreRoleAvailable(container) {
  const roleStatus = dockerExec(container, [
    "psql", "-U", "postgres", "-d", "postgres", "-At",
    "-c",
    "SELECT CASE WHEN rolsuper AND rolcanlogin THEN 'ready' ELSE 'unavailable' END " +
      "FROM pg_roles WHERE rolname = '" + restoreRoleName + "';",
  ]);
  if (roleStatus !== "ready") {
    fail("The local Supabase administrative restore role is unavailable or lacks superuser/login capability.");
  }

  const connectionStatus = dockerExec(container, [
    "psql", "-U", restoreRoleName, "-d", "postgres", "-At",
    "-c",
    "SELECT CASE WHEN rolsuper THEN 'superuser' ELSE 'not_superuser' END " +
      "FROM pg_roles WHERE rolname = current_user;",
  ]);
  if (connectionStatus !== "superuser") {
    fail("The local administrative restore role did not connect with the required privileges.");
  }
}

function assertSyntheticUsers(container) {
  const nonSyntheticCount = dockerExec(container, [
    "psql", "-U", "postgres", "-d", "postgres", "-At",
    "-c", "SELECT count(*) FROM auth.users WHERE email IS NULL OR email !~ '\\.invalid$';",
  ]);
  if (nonSyntheticCount !== "0") {
    fail("Backup refused: the local Auth database contains an email that is not in the reserved .invalid test domain.");
  }
  const userCount = dockerExec(container, [
    "psql", "-U", "postgres", "-d", "postgres", "-At",
    "-c", "SELECT count(*) FROM auth.users;",
  ]);
  if (!/^[1-9][0-9]*$/.test(userCount)) {
    fail("Backup refused: no seeded synthetic Auth users were found.");
  }
}

const snapshotSql =
  "SELECT jsonb_build_object(" +
  "'authUsers', (SELECT count(*) FROM auth.users), " +
  "'authIdentities', (SELECT count(*) FROM auth.identities), " +
  "'profiles', (SELECT count(*) FROM public.profiles), " +
  "'roleAssignments', (SELECT count(*) FROM public.role_assignments), " +
  "'assessmentSubmissions', (SELECT count(*) FROM public.assessment_submissions), " +
  "'submissionVersions', (SELECT count(*) FROM public.submission_versions), " +
  "'submissionFiles', (SELECT count(*) FROM private.submission_files), " +
  "'securityAuditEvents', (SELECT count(*) FROM private.security_audit_events), " +
  "'privateQaRecords', (SELECT count(*) FROM private.private_qa_records), " +
  "'storageObjectPaths', coalesce((SELECT jsonb_agg(name ORDER BY name) FROM storage.objects WHERE bucket_id = 'private-submissions'), '[]'::jsonb), " +
  "'schemaEvidence', jsonb_build_object(" +
    "'applicationTables', (SELECT count(*) FROM pg_tables WHERE schemaname IN ('public','private')), " +
    "'policies', (SELECT count(*) FROM pg_policies WHERE schemaname IN ('public','private','storage','auth')), " +
    "'constraints', (SELECT count(*) FROM pg_constraint WHERE connamespace IN ('public'::regnamespace,'private'::regnamespace)), " +
    "'applicationFunctions', (SELECT count(*) FROM pg_proc AS p JOIN pg_namespace AS n ON n.oid = p.pronamespace WHERE n.nspname IN ('public','private')), " +
    "'migrationEntries', (SELECT count(*) FROM supabase_migrations.schema_migrations)" +
  ")" +
  ")::text;";

function databaseSnapshot(container, databaseName = "postgres") {
  const output = dockerExec(container, [
    "psql", "-U", "postgres", "-d", databaseName, "-At", "-v", "ON_ERROR_STOP=1", "-c", snapshotSql,
  ]);
  try {
    return JSON.parse(output);
  } catch {
    fail("Could not read the database restore-verification snapshot.");
  }
}

async function listBucketObjects(storage) {
  const found = [];
  async function visit(prefix) {
    let offset = 0;
    while (true) {
      const { data, error } = await storage.from(bucketName).list(prefix, {
        limit: 100,
        offset,
        sortBy: { column: "name", order: "asc" },
      });
      if (error) fail("Could not list the local private PDF bucket.");
      for (const item of data ?? []) {
        const objectPath = prefix ? prefix + "/" + item.name : item.name;
        if (item.id == null && item.metadata == null) {
          await visit(objectPath);
        } else {
          found.push({
            path: objectPath,
            contentType: item.metadata?.mimetype ?? "application/pdf",
          });
        }
      }
      if (!data || data.length < 100) break;
      offset += data.length;
    }
  }
  await visit("");
  found.sort((a, b) => a.path.localeCompare(b.path));
  return found;
}

function objectFilePath(objectsDirectory, objectPath) {
  const segments = objectPath.split("/");
  if (segments.some(segment => !segment || segment === "." || segment === ".." || segment.includes("\\"))) {
    fail("Storage returned an unsafe object path.");
  }
  const base = resolve(objectsDirectory);
  const target = resolve(base, ...segments);
  if (!target.startsWith(base + sep)) fail("Storage object path escaped the backup directory.");
  return target;
}

async function createBackup(storage, container, outputDirectory) {
  mkdirSync(outputDirectory, { recursive: true, mode: 0o700 });
  const objectsDirectory = join(outputDirectory, "objects");
  mkdirSync(objectsDirectory, { recursive: true, mode: 0o700 });

  const listedObjects = await listBucketObjects(storage);
  const objectManifest = [];
  for (const item of listedObjects) {
    const { data, error } = await storage.from(bucketName).download(item.path);
    if (error || !data) fail("Could not download a private PDF for the local backup.");
    const bytes = Buffer.from(await data.arrayBuffer());
    const destination = objectFilePath(objectsDirectory, item.path);
    mkdirSync(dirname(destination), { recursive: true, mode: 0o700 });
    writeFileSync(destination, bytes, { mode: 0o600 });
    objectManifest.push({
      path: item.path,
      contentType: item.contentType,
      bytes: bytes.byteLength,
      sha256: sha256(bytes),
    });
  }

  dockerExec(container, [
    "pg_dump", "-U", "postgres", "-d", "postgres",
    "--format=custom", "--file=" + containerDumpPath,
  ]);
  const databaseDumpPath = join(outputDirectory, "database.dump");
  run("docker", ["cp", container + ":" + containerDumpPath, databaseDumpPath]);
  dockerExec(container, ["rm", "-f", containerDumpPath]);

  const databaseDump = readFileSync(databaseDumpPath);
  const databaseState = databaseSnapshot(container);
  const dbObjectPaths = databaseState.storageObjectPaths;
  const apiObjectPaths = objectManifest.map(item => item.path).sort((a, b) => a.localeCompare(b));
  if (JSON.stringify(dbObjectPaths) !== JSON.stringify(apiObjectPaths)) {
    fail("The private Storage API object inventory does not match the database object metadata.");
  }

  const manifest = {
    formatVersion: 1,
    backupId: randomUUID(),
    createdAt: new Date().toISOString(),
    scope: "local-synthetic-only",
    projectId,
    bucket: bucketName,
    database: {
      file: "database.dump",
      format: "PostgreSQL custom archive",
      bytes: databaseDump.byteLength,
      sha256: sha256(databaseDump),
      stateSnapshot: databaseState,
    },
    objects: objectManifest,
    security: {
      encrypted: false,
      note: "This local test artefact is unencrypted and must never contain real learner data or be copied to an external backup target.",
    },
    notIncluded: [
      "Cloudflare Worker secrets and deployment configuration",
      "provider control-plane settings and project-level access credentials",
      "a numeric RPO or RTO commitment",
      "any hosted Supabase or R2 backup",
    ],
  };
  writeFileSync(join(outputDirectory, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n", { mode: 0o600 });
  return manifest;
}

function verifyBackupFiles(outputDirectory, manifest) {
  const dumpPath = join(outputDirectory, manifest.database.file);
  const dump = readFileSync(dumpPath);
  if (sha256(dump) !== manifest.database.sha256 || dump.byteLength !== manifest.database.bytes) {
    fail("Database backup checksum or size validation failed.");
  }
  for (const item of manifest.objects) {
    const filePath = objectFilePath(join(outputDirectory, "objects"), item.path);
    const bytes = readFileSync(filePath);
    if (bytes.byteLength !== item.bytes || sha256(bytes) !== item.sha256) {
      fail("Private PDF backup checksum or size validation failed.");
    }
  }
  return dumpPath;
}

async function restoreStorageObjects(storage, outputDirectory, manifest) {
  const temporaryPaths = [];
  try {
    for (const item of manifest.objects) {
      const sourcePath = objectFilePath(join(outputDirectory, "objects"), item.path);
      const bytes = readFileSync(sourcePath);
      const targetPath = "phase1e-restore-verification/" + manifest.backupId + "/" + item.path;
      const { error: uploadError } = await storage.from(bucketName).upload(targetPath, bytes, {
        contentType: item.contentType,
        upsert: false,
      });
      if (uploadError) fail("Could not restore a backed-up PDF into the local verification prefix.");
      temporaryPaths.push(targetPath);

      const { data, error: downloadError } = await storage.from(bucketName).download(targetPath);
      if (downloadError || !data) fail("Could not read back a restored private PDF.");
      const restoredBytes = Buffer.from(await data.arrayBuffer());
      if (restoredBytes.byteLength !== item.bytes || sha256(restoredBytes) !== item.sha256) {
        fail("A restored private PDF failed its SHA-256 verification.");
      }
    }
    return temporaryPaths;
  } catch (error) {
    await removeTemporaryObjects(storage, temporaryPaths);
    throw error;
  }
}

async function removeTemporaryObjects(storage, objectPaths) {
  for (let offset = 0; offset < objectPaths.length; offset += 100) {
    const { error } = await storage.from(bucketName).remove(objectPaths.slice(offset, offset + 100));
    if (error) fail("Could not remove local restore-verification objects.");
  }
}

function restoreDatabase(container, dumpPath) {
  run("docker", ["cp", dumpPath, container + ":" + containerDumpPath]);
  dockerExec(container, [
    "psql", "-U", "postgres", "-d", "postgres", "-v", "ON_ERROR_STOP=1",
    "-c", "DROP DATABASE IF EXISTS " + restoreDatabaseName + " WITH (FORCE);",
  ]);
  dockerExec(container, ["createdb", "-U", "postgres", restoreDatabaseName]);
  assertRestoreRoleAvailable(container);
  dockerExec(container, [
    "pg_restore", "-U", restoreRoleName, "-d", restoreDatabaseName,
    "--exit-on-error", containerDumpPath,
  ]);
}

function verifyRestoredAuthorization(container) {
  // Verify the restored database as application roles, not only as the
  // restore superuser. Row/policy counts alone cannot prove that RLS still
  // hides another learner's rows or blocks browser access to private PDFs.
  const sql = [
    "BEGIN;",
    "DO $verify$ DECLARE bucket_private boolean; storage_rls boolean; owner_visible integer; BEGIN " +
      "SELECT NOT public INTO bucket_private FROM storage.buckets WHERE id = 'private-submissions'; " +
      "IF bucket_private IS DISTINCT FROM true THEN RAISE EXCEPTION 'restored private PDF bucket is not private'; END IF; " +
      "SELECT relrowsecurity INTO storage_rls FROM pg_class WHERE oid = 'storage.objects'::regclass; " +
      "IF storage_rls IS DISTINCT FROM true THEN RAISE EXCEPTION 'restored Storage object RLS is disabled'; END IF; " +
      "SELECT count(*)::integer INTO owner_visible FROM storage.objects WHERE bucket_id = 'private-submissions'; " +
      "IF owner_visible < 1 THEN RAISE EXCEPTION 'restored private PDF object metadata is missing'; END IF; " +
    "END $verify$;",
    "SET LOCAL ROLE authenticated;",
    "SELECT set_config('request.jwt.claims', '{\"sub\":\"11111111-1111-4111-8111-111111111111\",\"role\":\"authenticated\",\"aal\":\"aal1\"}', true);",
    "DO $verify$ DECLARE own_attempts integer; foreign_attempts integer; visible_storage integer := 0; file_access_denied boolean := false; BEGIN " +
      "SELECT count(*)::integer INTO own_attempts FROM public.attempts; " +
      "IF own_attempts < 2 THEN RAISE EXCEPTION 'restored RLS did not expose the learner\'s own synthetic attempts'; END IF; " +
      "SELECT count(*)::integer INTO foreign_attempts FROM public.attempts WHERE id = 'c2222222-2222-4222-8222-222222222222'; " +
      "IF foreign_attempts <> 0 THEN RAISE EXCEPTION 'restored RLS exposed another learner\'s synthetic attempt'; END IF; " +
      "BEGIN PERFORM 1 FROM private.submission_files LIMIT 1; EXCEPTION WHEN insufficient_privilege THEN file_access_denied := true; END; " +
      "IF NOT file_access_denied THEN RAISE EXCEPTION 'authenticated browser role can read private PDF metadata directly'; END IF; " +
      "BEGIN SELECT count(*)::integer INTO visible_storage FROM storage.objects WHERE bucket_id = 'private-submissions'; " +
      "EXCEPTION WHEN insufficient_privilege THEN visible_storage := 0; END; " +
      "IF visible_storage <> 0 THEN RAISE EXCEPTION 'authenticated browser role can list private PDF Storage objects'; END IF; " +
    "END $verify$;",
    "RESET ROLE;",
    "SET LOCAL ROLE anon;",
    "SELECT set_config('request.jwt.claims', '{\"role\":\"anon\"}', true);",
    "DO $verify$ DECLARE visible_storage integer := 0; BEGIN " +
      "BEGIN SELECT count(*)::integer INTO visible_storage FROM storage.objects WHERE bucket_id = 'private-submissions'; " +
      "EXCEPTION WHEN insufficient_privilege THEN visible_storage := 0; END; " +
      "IF visible_storage <> 0 THEN RAISE EXCEPTION 'anonymous role can list private PDF Storage objects'; END IF; " +
    "END $verify$;",
    "RESET ROLE;",
    "ROLLBACK;",
  ].join("\\n");
  dockerExec(container, [
    "psql", "-U", restoreRoleName, "-d", restoreDatabaseName,
    "-v", "ON_ERROR_STOP=1", "-c", sql,
  ]);
}
function verifyCorruptArchiveRejected(container, dumpPath, workingDirectory) {
  const bytes = readFileSync(dumpPath);
  const corruptPath = join(workingDirectory, "corrupt.dump");
  const corrupt = Buffer.from(bytes);
  corrupt[0] = corrupt[0] ^ 0xff;
  writeFileSync(corruptPath, corrupt, { mode: 0o600 });
  run("docker", ["cp", corruptPath, container + ":" + containerCorruptPath]);

  const result = spawnSync("docker", ["exec", container, "pg_restore", "--list", containerCorruptPath], {
    cwd: appRoot,
    stdio: "ignore",
  });
  dockerExec(container, ["rm", "-f", containerCorruptPath]);
  if (!result.error && result.status === 0) {
    fail("Corrupt database archives must be rejected before restore.");
  }
}

function cleanupRestoreDatabase(container) {
  try {
    dockerExec(container, [
      "psql", "-U", "postgres", "-d", "postgres", "-v", "ON_ERROR_STOP=1",
      "-c", "DROP DATABASE IF EXISTS " + restoreDatabaseName + " WITH (FORCE);",
    ]);
  } catch {
    // Preserve the primary verification failure; CI's local stack is stopped by its always() cleanup.
  }
  try {
    dockerExec(container, ["rm", "-f", containerDumpPath, containerCorruptPath]);
  } catch {
    // The temporary container files disappear with the disposable local Supabase stack.
  }
}

async function verifyRoundTrip(storage, container, outputDirectory) {
  const manifest = JSON.parse(readFileSync(join(outputDirectory, "manifest.json"), "utf8"));
  if (manifest.formatVersion !== 1 || manifest.scope !== "local-synthetic-only" || manifest.encrypted !== undefined) {
    fail("The backup manifest is missing its expected local-only format marker.");
  }
  if (manifest.objects.length === 0) {
    fail("The restore acceptance requires at least one synthetic private PDF object.");
  }

  const dumpPath = verifyBackupFiles(outputDirectory, manifest);
  run("docker", ["cp", dumpPath, container + ":" + containerDumpPath]);
  dockerExec(container, ["pg_restore", "--list", containerDumpPath]);
  verifyCorruptArchiveRejected(container, dumpPath, outputDirectory);

  const restoreObjects = [];
  try {
    restoreDatabase(container, dumpPath);
    const restoredState = databaseSnapshot(container, restoreDatabaseName);
    if (JSON.stringify(restoredState) !== JSON.stringify(manifest.database.stateSnapshot)) {
      fail("The restored database does not match its backed-up table, constraint, policy and Storage metadata snapshot.");
    }
    verifyRestoredAuthorization(container);
    restoreObjects.push(...await restoreStorageObjects(storage, outputDirectory, manifest));
  } finally {
    await removeTemporaryObjects(storage, restoreObjects);
    cleanupRestoreDatabase(container);
  }
  return {
    databaseDumpBytes: manifest.database.bytes,
    protectedPdfObjects: manifest.objects.length,
    restoredDatabaseSnapshots: 1,
    restoredPdfChecksums: manifest.objects.length,
    corruptArchiveRejected: true,
  };
}

async function main() {
  const mode = process.argv.includes("--backup") ? "backup" : "verify-roundtrip";
  const { url, serviceKey } = readLocalEnvironment();
  const container = findDatabaseContainer();
  assertSyntheticUsers(container);

  const supabase = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
  });
  const { data: bucket, error: bucketError } = await supabase.storage.getBucket(bucketName);
  if (bucketError || !bucket || bucket.public !== false) {
    fail("The private-submissions bucket is not available as a private local bucket.");
  }

  let outputDirectory;
  let isTemporary = false;
  if (mode === "backup") {
    const stamp = new Date().toISOString().replace(/[.:]/g, "-");
    outputDirectory = join(appRoot, ".local-backups", "phase1e-" + stamp);
  } else {
    outputDirectory = join(tmpdir(), "gradioprep-phase1e-" + randomUUID());
    isTemporary = true;
  }

  mkdirSync(outputDirectory, { recursive: true, mode: 0o700 });
  try {
    const manifest = await createBackup(supabase.storage, container, outputDirectory);
    if (mode === "backup") {
      verifyBackupFiles(outputDirectory, manifest);
      console.log(JSON.stringify({
        status: "backup_created",
        scope: manifest.scope,
        databaseDumpBytes: manifest.database.bytes,
        protectedPdfObjects: manifest.objects.length,
        manifestPath: ".local-backups/" + outputDirectory.split(sep).slice(-1)[0] + "/manifest.json",
      }, null, 2));
    } else {
      const result = await verifyRoundTrip(supabase.storage, container, outputDirectory);
      console.log(JSON.stringify({ status: "backup_restore_verified", ...result }, null, 2));
    }
  } finally {
    if (isTemporary) rmSync(outputDirectory, { recursive: true, force: true });
  }
}

main().catch(error => {
  console.error("Phase 1E local backup verification failed: " + (error instanceof Error ? error.message : "unknown error"));
  process.exitCode = 1;
});
