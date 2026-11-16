import { useEffect, useState } from "react";

/** The Founder already granted qualified academic approval. This workspace
 * records only the genuine, version-bound evidence underlying that decision. */
type PaVersionSummary = {
  diagnostic_version_id: string;
  instrument_version: number;
  instrument_title: string;
  instrument_release_state: string;
  route_version_id: string;
  route_key: string;
  route_review_state: string;
  route_source_title: string | null;
  route_source_url: string | null;
  total_observations: number;
  direct_mappings: number;
  capture_enabled: number;
};
type VerifiedOutcome = {
  outcome_mapping_id: string;
  unit_code: string;
  outcome_reference: string;
  outcome_title: string;
  source_locator: string;
};
type ReadinessRow = {
  observation_code: string; group_code: string;
  learner_capture_enabled: boolean; reviewed_direct_mapping_present: boolean;
  approved_rubric_record_present: boolean; instrument_release_state: string;
};
const uuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
const digest = (s: string) => /^[a-f0-9]{64}$/.test(s);

/** Owner-only, locally generated form: no outcome or rationale is pre-approved. */
export function blankPaCrosswalkTemplate(rows: ReadinessRow[]): string | null {
  if (rows.length !== 30 || new Set(rows.map(row => row.observation_code)).size !== 30
    || rows.some(row => row.group_code === "L"
      || !/^(RV|LC|AW|CW|SP)[0-9]{2}[ab]?$/.test(row.observation_code))) return null;
  return JSON.stringify(rows.map(row => ({
    code: row.observation_code, outcome_mapping_id: "", rationale: "",
  })), null, 2);
}

/** Fingerprint restricted evidence locally. File bytes never leave the browser. */
async function fingerprintLocalFile(file: File): Promise<string> {
  const bytes = await file.arrayBuffer();
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(hash), byte => byte.toString(16).padStart(2, "0")).join("");
}


export default function PaAcademicEvidencePanel({ accessToken }: { accessToken: string }) {
  const [version, setVersion] = useState("");
  const [availableVersions, setAvailableVersions] = useState<PaVersionSummary[]>([]);
  const [versionsError, setVersionsError] = useState("");
  const [rows, setRows] = useState<ReadinessRow[]>([]);
  const [crosswalkJson, setCrosswalkJson] = useState("");
  const [verifiedOutcomes, setVerifiedOutcomes] = useState<VerifiedOutcome[]>([]);
  const [selectedOutcomes, setSelectedOutcomes] = useState<Record<string,string>>({});
  const [mappingRationales, setMappingRationales] = useState<Record<string,string>>({});
  const [crosswalkRecorded, setCrosswalkRecorded] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [rubricHash, setRubricHash] = useState("");
  const [maxima, setMaxima] = useState<Record<string,string>>({});
  const [academicRef, setAcademicRef] = useState("");
  const [calibrationRef, setCalibrationRef] = useState("");
  const [rubricNote, setRubricNote] = useState("");
  const [rubricId, setRubricId] = useState("");
  const [sourceRef, setSourceRef] = useState("");
  const [bundleHash, setBundleHash] = useState("");
  const [mappingHash, setMappingHash] = useState("");
  const [packsHash, setPacksHash] = useState("");
  const [calibrationHash, setCalibrationHash] = useState("");
  const [evidenceNote, setEvidenceNote] = useState("");
  const [receiptId, setReceiptId] = useState("");
  const [fingerprintStatus, setFingerprintStatus] = useState("");
  const [fingerprinting, setFingerprinting] = useState(false);
  async function hashSelectedFile(file: File | undefined, setHash: (hash: string) => void) {
    if (!file || busy || fingerprinting) return;
    setFingerprinting(true); setError(""); setFingerprintStatus("");
    try {
      const hash = await fingerprintLocalFile(file);
      setHash(hash);
      setFingerprintStatus("SHA-256 calculated locally for " + file.name +
        ". Confirm that this is the correct approved exact-version evidence before recording.");
    } catch {
      setError("The file could not be fingerprinted on this device. No file was uploaded.");
    } finally { setFingerprinting(false); }
  }
  function localFingerprintField(label: string, setter: (hash: string) => void) {
    return <label key={label}>{label} — calculate from an existing private file
      <input type="file" disabled={busy || fingerprinting}
        onChange={event=>{ const file = event.currentTarget.files?.[0];
          void hashSelectedFile(file, setter); event.currentTarget.value = ""; }} />
    </label>;
  }
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState("");

  async function call(path: string, body?: object) {
    const response = await fetch(path, { method: body ? "POST" : "GET",
      headers: { Authorization: "Bearer " + accessToken,
        ...(body ? { "Content-Type": "application/json" } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}), cache: "no-store" });
    const result = await response.json() as Record<string,unknown>;
    if (!response.ok) throw new Error(response.status === 409
      ? "The verified mapping or supporting academic evidence is incomplete or conflicts with this version."
      : response.status === 403 ? "Owner MFA is required for this action."
      : "The academic evidence operation could not be completed.");
    return result;
  }
  useEffect(() => {
    let active=true;
    setAvailableVersions([]);
    setVersionsError("");
    void call("/api/v1/admin/pa-academic/versions").then(result=>{
      if (active) setAvailableVersions((result.versions as PaVersionSummary[]) ?? []);
    }).catch(()=>{
      if (active) setVersionsError("The private PA version inventory could not be loaded.");
    });
    return ()=>{ active=false; };
    // The caller's access token scopes this request; stale results are discarded on sign-out.
  }, [accessToken]);
  async function perform(task: () => Promise<void>, success: string) {
    setBusy(true); setError(""); setStatus("");
    try { await task(); setStatus(success); }
    catch (e) { setError(e instanceof Error ? e.message : "Operation failed."); }
    finally { setBusy(false); }
  }
  const expectedCodes = new Set(rows.map(row => row.observation_code));
  const emptyCrosswalkTemplate = loaded ? blankPaCrosswalkTemplate(rows) : null;
  function downloadCrosswalkTemplate() {
    if (!emptyCrosswalkTemplate || !uuid(version)) return;
    const blob = new Blob([emptyCrosswalkTemplate], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "pa-direct-crosswalk-" + version + ".json";
    link.click();
    URL.revokeObjectURL(url);
  }
  const parsedCrosswalk = (() => {
    try {
      const raw: unknown = JSON.parse(crosswalkJson);
      if (!Array.isArray(raw) || raw.length !== 30 || !loaded || rows.length !== 30)
        return null;
      const codes = new Set<string>();
      for (const item of raw) {
        if (!item || typeof item !== "object" || Array.isArray(item)) return null;
        const entry = item as Record<string, unknown>;
        if (Object.keys(entry).length !== 3 ||
          typeof entry.code !== "string" || !expectedCodes.has(entry.code) ||
          codes.has(entry.code) || typeof entry.outcome_mapping_id !== "string" ||
          !uuid(entry.outcome_mapping_id) || typeof entry.rationale !== "string" ||
          entry.rationale.trim().length < 20 || entry.rationale.length > 2000) return null;
        codes.add(entry.code);
      }
      return codes.size === 30 ? raw : null;
    } catch { return null; }
  })();
  const allMapped = loaded && rows.length === 30 && new Set(rows.map(r=>r.observation_code)).size === 30 &&
    rows.every(r=>r.reviewed_direct_mapping_present);
  const numericMaxima = rows.map(r=>({ code: r.observation_code, max_points: Number(maxima[r.observation_code]) }));
  const rubricReady = !fingerprinting && allMapped && digest(rubricHash) && academicRef.trim().length >= 12 &&
    calibrationRef.trim().length >= 12 && rubricNote.trim().length >= 20 &&
    numericMaxima.every(r=>maxima[r.code] !== undefined && maxima[r.code].trim() !== "" &&
      Number.isFinite(r.max_points) && r.max_points > 0 && r.max_points <= 100);
  const receiptReady = !fingerprinting && uuid(version) && uuid(rubricId) &&
    sourceRef.trim().length >= 20 && [bundleHash,mappingHash,packsHash,calibrationHash].every(digest) &&
    evidenceNote.trim().length >= 30;
  return <section aria-label="Owner-only academic evidence handoff" className="proto-pa-academic-evidence">
    <h4>Step 8 · Restricted academic evidence handoff</h4>
    <p>Existing Founder academic approvals remain valid. Enter only genuine exact-version source
      references, verified direct mappings, numerical scoring anchors and witnessed calibration records.
      Never use test values. Private teacher files stay outside public GitHub.</p>
    <label>Choose the exact PA instrument
      <select aria-label="Exact PA instrument version" value={version}
        onChange={e=>{setVersion(e.target.value);setRows([]);
        setLoaded(false);setRubricId("");setReceiptId("");setCrosswalkJson("");setCrosswalkRecorded(false);setVerifiedOutcomes([]);setSelectedOutcomes({});setMappingRationales({});
        setRubricHash("");setMaxima({});setAcademicRef("");setCalibrationRef("");
        setRubricNote("");setSourceRef("");setBundleHash("");setMappingHash("");
        setPacksHash("");setCalibrationHash("");setEvidenceNote("");}}>
        <option value="">Select an instrument version</option>
        {availableVersions.map(item=><option key={item.diagnostic_version_id}
          value={item.diagnostic_version_id}>Version {item.instrument_version} · {item.instrument_title}</option>)}
      </select>
    </label>
    {versionsError && <p role="alert">{versionsError}</p>}
    {availableVersions.find(item=>item.diagnostic_version_id===version) && <p>
      {(()=>{const current=availableVersions.find(item=>item.diagnostic_version_id===version)!;
        return "Curriculum route: "+current.route_key+" · "+current.route_review_state+
          " · "+current.direct_mappings+"/"+current.total_observations+" verified direct mappings"+
          " · "+current.capture_enabled+"/"+current.total_observations+" capture-enabled observations"+
          (current.route_source_title ? " · Source: "+current.route_source_title : " · Official source not recorded");
      })()}
    </p>}
    <button type="button" className="proto-action secondary" disabled={busy || !uuid(version)}
      onClick={()=>void perform(async()=>{
        const response=await call("/api/v1/admin/pa-academic/readiness/"+version);
        setRows((response.dimensions as ReadinessRow[]) ?? []);
        const verified=await call("/api/v1/admin/pa-academic/outcomes/"+version);
        setVerifiedOutcomes((verified.outcomes as VerifiedOutcome[]) ?? []);
        setLoaded(true);
      },"Exact-version mapping and capture state loaded.")}>Check 30 dimensions</button>
    {loaded && !allMapped && !crosswalkRecorded && <fieldset disabled={busy || fingerprinting}>
      <legend>Record verified 30-observation direct curriculum crosswalk</legend>
      <p>Use only a complete crosswalk from the qualified Founder's existing reviewed evidence.
        Each entry must name the exact observation code, an existing reviewed DIRECT outcome
        mapping UUID on this verified Year 4 route, and its evidence rationale. This does
        not create curriculum outcomes or substitute for source verification.</p>
      <p>{verifiedOutcomes.length} existing, reviewed curriculum outcomes available for this
        exact route. If none appear, the underlying verified curriculum records must be
        supplied first; this workspace cannot create them.</p>
      <p>Download the exact 30 observation codes to prepare the real crosswalk
        privately. Outcome identifiers and rationales are left blank, never invented.</p>
      <button type="button" className="proto-action secondary"
        disabled={!emptyCrosswalkTemplate || busy}
        onClick={downloadCrosswalkTemplate}>Download blank 30-row crosswalk template</button>
      {verifiedOutcomes.length > 0 && <>
        {rows.map(row=><div key={row.observation_code}>
          <label>{row.observation_code} — reviewed curriculum outcome
            <select value={selectedOutcomes[row.observation_code] ?? ""}
              onChange={event=>setSelectedOutcomes(previous=>({
                ...previous,[row.observation_code]:event.target.value
              }))}>
              <option value="">Choose an exact curriculum outcome</option>
              {verifiedOutcomes.map(outcome=><option key={outcome.outcome_mapping_id}
                value={outcome.outcome_mapping_id}>
                {outcome.unit_code} · {outcome.outcome_reference} · {outcome.outcome_title}
                {" — "}{outcome.source_locator}
              </option>)}
            </select>
          </label>
          <label>{row.observation_code} — direct link rationale
            <textarea rows={2} maxLength={2000}
              value={mappingRationales[row.observation_code] ?? ""}
              onChange={event=>setMappingRationales(previous=>({
                ...previous,[row.observation_code]:event.target.value
              }))} />
          </label>
        </div>)}
        <button type="button" className="proto-action secondary"
          disabled={busy || rows.length !== 30 || rows.some(row=>
            !selectedOutcomes[row.observation_code] ||
            (mappingRationales[row.observation_code] ?? "").trim().length < 20)}
          onClick={()=>{
            setCrosswalkJson(JSON.stringify(rows.map(row=>({
              code:row.observation_code,
              outcome_mapping_id:selectedOutcomes[row.observation_code],
              rationale:mappingRationales[row.observation_code].trim()
            })),null,2));
          }}>Prepare the 30 verified links for review</button>
      </>}
      <label>Verified mapping file (JSON containing 30 entries)
        <input type="file" accept=".json,application/json" onChange={event=>{
          const file=event.currentTarget.files?.[0];
          if (file && file.size <= 64000) {
            void file.text().then(text=>setCrosswalkJson(text)).catch(()=>
              setError("Could not read the private crosswalk file on this device."));
          } else if (file) setError("Crosswalk file is too large.");
          event.currentTarget.value="";
        }} />
      </label>
      <label>Review 30-link JSON before secure handoff
        <textarea rows={5} value={crosswalkJson} onChange={event=>setCrosswalkJson(event.target.value)}
          placeholder={'[{"code":"RV01","outcome_mapping_id":"existing-reviewed-outcome-uuid","rationale":"Exact source and task-specific direct outcome rationale"}, ...]'} />
      </label>
      <p>{parsedCrosswalk
        ? "All 30 unique observation codes and identifiers have the required format. Database verification is still required."
        : "A complete, correctly formatted 30-row crosswalk is required before recording."}</p>
      <button type="button" className="proto-action secondary"
        disabled={!parsedCrosswalk || busy || fingerprinting}
        onClick={()=>void perform(async()=>{
          const result=await call("/api/v1/admin/pa-academic/crosswalk",{
            diagnostic_version_id:version,mappings:parsedCrosswalk,
          });
          if (result.recorded_direct_mappings !== 30)
            throw new Error("The database did not confirm all 30 mappings.");
          setCrosswalkRecorded(true);
          const updated=await call("/api/v1/admin/pa-academic/readiness/"+version);
          setRows((updated.dimensions as ReadinessRow[]) ?? []);
        },"All 30 verified DIRECT links recorded atomically and checked against the exact Year 4 route.")}>
        Record 30 reviewed direct links</button>
    </fieldset>}
    {loaded && <>
      <p>{rows.filter(r=>r.reviewed_direct_mapping_present).length} / 30 reviewed direct mappings;
        {" "}{rows.filter(r=>r.learner_capture_enabled).length} / 30 capture-enabled observations.
        {allMapped
          ? " Direct mapping preparation is complete. Learner capture and publication remain separately protected."
          : " Rubric recording waits for all reviewed direct links; learner capture stays protected."}</p>
      <ul aria-label="Exact-version academic readiness">{rows.map(r=><li key={r.observation_code}>
        {r.observation_code}: {r.reviewed_direct_mapping_present ? "direct mapping recorded" : "mapping missing"}
        {" · "}{r.learner_capture_enabled ? "capture enabled" : "capture disabled"}
      </li>)}</ul>
    </>}
    <fieldset disabled={busy || !allMapped || Boolean(rubricId)}>
      <legend>Record real, reviewed numerical rubric</legend>
      <p>Numbers and rubric fingerprint must come from the existing approved restricted evidence,
        not from defaults or an invented scoring scale.</p>
      {localFingerprintField("Reviewed rubric",setRubricHash)}
      <label>Rubric SHA-256 <input value={rubricHash} maxLength={64}
        onChange={e=>setRubricHash(e.target.value.trim())}/></label>
      {rows.map(r=><label key={r.observation_code}>{r.observation_code} approved maximum points
        <input type="number" min="0.01" max="100" step="any" value={maxima[r.observation_code] ?? ""}
          onChange={e=>setMaxima(m=>({...m,[r.observation_code]:e.target.value}))}/>
      </label>)}
      <label>Existing academic review record reference
        <input maxLength={500} value={academicRef} onChange={e=>setAcademicRef(e.target.value)}/></label>
      <label>Existing witnessed calibration record reference
        <input maxLength={500} value={calibrationRef} onChange={e=>setCalibrationRef(e.target.value)}/></label>
      <label>Evidence and anchor notes
        <textarea rows={3} maxLength={1000} value={rubricNote} onChange={e=>setRubricNote(e.target.value)}/></label>
      <button type="button" className="proto-action secondary" disabled={!rubricReady}
        onClick={()=>void perform(async()=>{
          const result=await call("/api/v1/admin/pa-academic/rubric",{
            diagnostic_version_id:version,rubric_sha256:rubricHash,dimension_maxima:numericMaxima,
            academic_review_reference:academicRef.trim(),
            assessor_calibration_reference:calibrationRef.trim(),approval_note:rubricNote.trim(),
          });setRubricId(String(result.rubric_approval_id));
        },"Exact 30-dimension rubric recorded privately. No PA publication occurred.")}>
        Record approved numeric rubric</button>
    </fieldset>
    {rubricId && <p>Private rubric receipt ID: <code>{rubricId}</code></p>}
    <fieldset disabled={busy || !uuid(rubricId) || Boolean(receiptId)}>
      <legend>Bind genuine restricted academic evidence</legend>
      <label>Authorised Year 4 route/source reference
        <input maxLength={500} value={sourceRef} onChange={e=>setSourceRef(e.target.value)}/></label>
      {([
        ["Reviewed bundle SHA-256",bundleHash,setBundleHash],
        ["30-row direct crosswalk SHA-256",mappingHash,setMappingHash],
        ["Restricted teacher packs SHA-256",packsHash,setPacksHash],
        ["Witnessed calibration SHA-256",calibrationHash,setCalibrationHash],
      ] as const).map(([label,value,update])=><label key={label}>{label}
        <input maxLength={64} value={value} onChange={e=>update(e.target.value.trim())}/></label>)}
      <p>Calculate each fingerprint from its actual approved private document. Hashing is not
        academic verification and does not establish that a calibration occurred. The files
        remain on this device; only their SHA-256 values may be submitted.</p>
      {localFingerprintField("Approved review bundle",setBundleHash)}
      {localFingerprintField("Verified 30-row direct crosswalk",setMappingHash)}
      {localFingerprintField("Complete restricted teacher-pack bundle",setPacksHash)}
      {localFingerprintField("Witnessed calibration record",setCalibrationHash)}
      <label>Exact-version evidence reconciliation note
        <textarea rows={3} maxLength={1000} value={evidenceNote}
          onChange={e=>setEvidenceNote(e.target.value)}/></label>
      <button type="button" className="proto-action secondary" disabled={!receiptReady}
        onClick={()=>void perform(async()=>{
          const result=await call("/api/v1/admin/pa-academic/evidence",{
            diagnostic_version_id:version,rubric_approval_id:rubricId,
            route_source_reference:sourceRef.trim(),review_bundle_sha256:bundleHash,
            direct_mapping_sha256:mappingHash,restricted_teacher_packs_sha256:packsHash,
            calibration_evidence_sha256:calibrationHash,evidence_note:evidenceNote.trim(),
          });setReceiptId(String(result.evidence_receipt_id));
        },"Private evidence receipt recorded. Publication remains a separate protected action.")}>
        Bind restricted evidence to rubric</button>
    </fieldset>
    {receiptId && <p>Private evidence receipt ID: <code>{receiptId}</code></p>}
    {fingerprinting && <p role="status">Calculating file fingerprint locally…</p>}
    {fingerprintStatus && <p role="status">{fingerprintStatus}</p>}
    {error && <p role="alert">{error}</p>}
    {status && <p role="status">{status}</p>}
  </section>;
}
