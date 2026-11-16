import { useState } from "react";

/** The Founder already granted qualified academic approval. This workspace
 * records only the genuine, version-bound evidence underlying that decision. */
type ReadinessRow = {
  observation_code: string; group_code: string;
  learner_capture_enabled: boolean; reviewed_direct_mapping_present: boolean;
  approved_rubric_record_present: boolean; instrument_release_state: string;
};
const uuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
const digest = (s: string) => /^[a-f0-9]{64}$/.test(s);

export default function PaAcademicEvidencePanel({ accessToken }: { accessToken: string }) {
  const [version, setVersion] = useState("");
  const [rows, setRows] = useState<ReadinessRow[]>([]);
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
  async function perform(task: () => Promise<void>, success: string) {
    setBusy(true); setError(""); setStatus("");
    try { await task(); setStatus(success); }
    catch (e) { setError(e instanceof Error ? e.message : "Operation failed."); }
    finally { setBusy(false); }
  }
  const allMapped = loaded && rows.length === 30 && new Set(rows.map(r=>r.observation_code)).size === 30 &&
    rows.every(r=>r.reviewed_direct_mapping_present && r.learner_capture_enabled);
  const numericMaxima = rows.map(r=>({ code: r.observation_code, max_points: Number(maxima[r.observation_code]) }));
  const rubricReady = allMapped && digest(rubricHash) && academicRef.trim().length >= 12 &&
    calibrationRef.trim().length >= 12 && rubricNote.trim().length >= 20 &&
    numericMaxima.every(r=>maxima[r.code] !== undefined && maxima[r.code].trim() !== "" &&
      Number.isFinite(r.max_points) && r.max_points > 0 && r.max_points <= 100);
  const receiptReady = uuid(version) && uuid(rubricId) &&
    sourceRef.trim().length >= 20 && [bundleHash,mappingHash,packsHash,calibrationHash].every(digest) &&
    evidenceNote.trim().length >= 30;
  return <section aria-label="Owner-only academic evidence handoff" className="proto-pa-academic-evidence">
    <h4>Step 8 · Restricted academic evidence handoff</h4>
    <p>Existing Founder academic approvals remain valid. Enter only genuine exact-version source
      references, verified direct mappings, numerical scoring anchors and witnessed calibration records.
      Never use test values. Private teacher files stay outside public GitHub.</p>
    <label>PA instrument version ID
      <input value={version} onChange={e=>{setVersion(e.target.value.trim());setRows([]);
        setLoaded(false);setRubricId("");setReceiptId("");}} placeholder="Exact instrument version UUID" />
    </label>
    <button type="button" className="proto-action secondary" disabled={busy || !uuid(version)}
      onClick={()=>void perform(async()=>{
        const response=await call("/api/v1/admin/pa-academic/readiness/"+version);
        setRows((response.dimensions as ReadinessRow[]) ?? []);setLoaded(true);
      },"Exact-version mapping and capture state loaded.")}>Check 30 dimensions</button>
    {loaded && <>
      <p>{rows.filter(r=>r.reviewed_direct_mapping_present).length} / 30 reviewed direct mappings;
        {" "}{rows.filter(r=>r.learner_capture_enabled).length} / 30 capture-enabled observations.
        {allMapped ? " Structural prerequisite satisfied." : " Release and rubric recording remain blocked."}</p>
      <ul aria-label="Exact-version academic readiness">{rows.map(r=><li key={r.observation_code}>
        {r.observation_code}: {r.reviewed_direct_mapping_present ? "direct mapping recorded" : "mapping missing"}
        {" · "}{r.learner_capture_enabled ? "capture enabled" : "capture disabled"}
      </li>)}</ul>
    </>}
    <fieldset disabled={busy || !allMapped || Boolean(rubricId)}>
      <legend>Record real, reviewed numerical rubric</legend>
      <p>Numbers and rubric fingerprint must come from the existing approved restricted evidence,
        not from defaults or an invented scoring scale.</p>
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
    {error && <p role="alert">{error}</p>}
    {status && <p role="status">{status}</p>}
  </section>;
}
