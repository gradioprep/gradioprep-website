import { useState } from "react";

/** Private scored PA handoff. No inferred marks and no automatic release.
 * Only rendered in the MFA-verified Owner review workspace. */
type Observation = { observation_code?: string; group_code?: string };
type FeedbackReview = { review_id: string; decision: string };
type PaReport = {
  report_record_id: string; report_version_id: string;
  curriculum_mapping_status: string; evidence_sufficiency_status: string;
  content_snapshot?: { observations?: Observation[] };
};
type ScoredDimension = { observation_code: string; points_awarded: number; points_possible: number };
type ScoredManifest = {
  source_report_version_id: string; composition_approval_id: string;
  dimension_count: number; curriculum_mapping_status: string;
  evidence_sufficiency_status: string; learner_visible: boolean;
  dimensions: ScoredDimension[];
  private_attainment: { points_awarded: number; points_possible: number; attainment_percent: number };
  teacher_feedback: string; rubric_sha256: string;
};

const expectedCounts: Record<string, number> = { RV: 10, LC: 5, AW: 5, CW: 5, SP: 5 };
const isUuid = (value: string) =>
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);

export default function PaScoringWorkspacePanel({
  accessToken, report, feedbackReviews, onPublished,
}: {
  accessToken: string; report: PaReport; feedbackReviews: FeedbackReview[];
  onPublished: () => Promise<void>;
}) {
  const [rubricId, setRubricId] = useState("");
  const [marks, setMarks] = useState<Record<string, string>>({});
  const [scoreDraftId, setScoreDraftId] = useState("");
  const [scoreReviewId, setScoreReviewId] = useState("");
  const [feedbackReviewId, setFeedbackReviewId] = useState("");
  const [compositionId, setCompositionId] = useState("");
  const [reviewNote, setReviewNote] = useState("");
  const [jointNote, setJointNote] = useState("");
  const [manifest, setManifest] = useState<ScoredManifest | null>(null);
  const [confirmed, setConfirmed] = useState(false);
  const [idempotencyKey] = useState(() => crypto.randomUUID());
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const observations = report.content_snapshot?.observations ?? [];
  const codes = observations.map(item => item.observation_code ?? "");
  const validInstrument = codes.length === 30 && new Set(codes).size === 30 &&
    Object.entries(expectedCounts).every(([group, count]) =>
      codes.filter(code => code.startsWith(group)).length === count);
  const reportReady = validInstrument &&
    report.curriculum_mapping_status === "complete_direct" &&
    report.evidence_sufficiency_status === "sufficient";
  const hasMarks = reportReady && codes.every(code =>
    marks[code] !== undefined && marks[code].trim() !== "" &&
    Number.isFinite(Number(marks[code])) && Number(marks[code]) >= 0 && Number(marks[code]) <= 100);
  const approvedFeedback = feedbackReviews.filter(item => item.decision === "approved_for_publication");
  const manifestReady = manifest && manifest.source_report_version_id === report.report_version_id &&
    manifest.composition_approval_id === compositionId &&
    manifest.dimension_count === 30 && manifest.dimensions?.length === 30 &&
    manifest.curriculum_mapping_status === "complete_direct" &&
    manifest.evidence_sufficiency_status === "sufficient" &&
    manifest.learner_visible === false;

  async function request(path: string, body?: object) {
    const response = await fetch(path, {
      method: body ? "POST" : "GET",
      headers: { Authorization: "Bearer " + accessToken,
        ...(body ? { "Content-Type": "application/json" } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
      cache: "no-store",
    });
    const result = await response.json() as Record<string, unknown>;
    if (!response.ok) throw new Error(response.status === 409
      ? "The report, rubric or approval is not eligible; check the exact version and evidence."
      : "This private scoring operation is unavailable.");
    return result;
  }
  async function perform(callback: () => Promise<void>, success: string) {
    setBusy(true); setError(""); setMessage("");
    try { await callback(); setMessage(success); }
    catch (cause) { setError(cause instanceof Error ? cause.message : "This operation failed."); }
    finally { setBusy(false); }
  }

  return <section className="proto-pa-scoring-workspace" aria-label="Private PA human scoring">
    <h4>Human-scored Evaluation Report</h4>
    <p>Use only the exact-version, academically reviewed 30-dimension rubric.
      This section never calculates marks automatically or assigns an official IB grade.</p>
    {!reportReady && <p role="status">Scoring is blocked until all 30 observation links
      and response evidence pass the curriculum and sufficiency checks.</p>}
    <label>Approved private rubric record ID
      <input value={rubricId} onChange={e => setRubricId(e.target.value.trim())}
        placeholder="Approved rubric UUID" autoComplete="off" />
    </label>
    {validInstrument && <fieldset disabled={busy || !reportReady || Boolean(scoreDraftId)}>
      <legend>Rubric points awarded for each observation</legend>
      <p>Enter only assessed human marks. Each entry is checked against its approved
        numerical maximum by the database. Zero is permitted for evidenced work.</p>
      <div className="proto-pa-score-grid">
        {observations.map(observation => {
          const code = observation.observation_code ?? "";
          return <label key={code}>{code}
            <input type="number" min="0" max="100" step="0.5"
              inputMode="decimal" value={marks[code] ?? ""}
              onChange={e => setMarks(current => ({ ...current, [code]: e.target.value }))}
              aria-label={code + " awarded points"} />
          </label>;
        })}
      </div>
    </fieldset>}
    <button type="button" className="proto-action secondary"
      disabled={busy || !hasMarks || !isUuid(rubricId) || Boolean(scoreDraftId)}
      onClick={() => void perform(async () => {
        const result = await request("/api/v1/admin/pa-scoring/drafts", {
          report_version_id: report.report_version_id, rubric_approval_id: rubricId,
          dimension_marks: codes.map(code => ({ code, points: Number(marks[code]) })),
        });
        setScoreDraftId(String(result.scoring_draft_id));
      }, "Thirty human marks saved privately. No learner report has been published.")}>
      Save private 30-dimension score draft
    </button>
    {scoreDraftId && <p>Private score draft recorded: <code>{scoreDraftId}</code></p>}
    <label>Human scoring review note
      <textarea rows={3} maxLength={1000} value={reviewNote}
        onChange={e => setReviewNote(e.target.value)} />
    </label>
    <button type="button" className="proto-action secondary"
      disabled={busy || !isUuid(scoreDraftId) || reviewNote.trim().length < 12 || Boolean(scoreReviewId)}
      onClick={() => void perform(async () => {
        const result = await request("/api/v1/admin/pa-scoring/review", {
          scoring_draft_id: scoreDraftId, decision: "approved_private", review_note: reviewNote.trim(),
        });
        setScoreReviewId(String(result.scoring_review_id));
      }, "Human scoring review approved privately; nothing is learner-visible.")}>
      Approve private human scoring
    </button>
    {scoreReviewId && <p>Scoring review recorded: <code>{scoreReviewId}</code></p>}
    <label>Already approved teacher-feedback review
      <select value={feedbackReviewId} onChange={e => setFeedbackReviewId(e.target.value)}>
        <option value="">Choose the matching report feedback review</option>
        {approvedFeedback.map(item => <option key={item.review_id} value={item.review_id}>{item.review_id}</option>)}
      </select>
    </label>
    <label>Combined scoring and teacher-feedback approval note
      <textarea rows={3} maxLength={1000} value={jointNote}
        onChange={e => setJointNote(e.target.value)} />
    </label>
    <button type="button" className="proto-action secondary"
      disabled={busy || !isUuid(scoreReviewId) || !isUuid(feedbackReviewId) ||
        jointNote.trim().length < 20 || Boolean(compositionId)}
      onClick={() => void perform(async () => {
        const result = await request("/api/v1/admin/pa-scoring/joint", {
          scoring_review_id: scoreReviewId, feedback_review_id: feedbackReviewId,
          approval_note: jointNote.trim(),
        });
        setCompositionId(String(result.composition_approval_id));
      }, "Same-version score and teacher-feedback approval linked privately.")}>
      Approve combined report
    </button>
    <button type="button" className="proto-action secondary"
      disabled={busy || !isUuid(compositionId)}
      onClick={() => void perform(async () => {
        const result = await request("/api/v1/admin/pa-scoring/manifest/" + compositionId);
        setManifest(result.manifest as ScoredManifest);
        setConfirmed(false);
      }, "Private scored-report manifest loaded for review.")}>
      Review scored-report manifest
    </button>
    {manifest && <div aria-label="Private scored report manifest">
      <p><strong>{manifest.private_attainment?.points_awarded} / {manifest.private_attainment?.points_possible}
        </strong> assessed rubric points · {manifest.private_attainment?.attainment_percent}% attainment</p>
      <p>Source version: {manifest.source_report_version_id}</p>
      <p>Rubric fingerprint: {manifest.rubric_sha256}</p>
      <p>Dimension count: {manifest.dimension_count}</p>
      <p>Teacher feedback: {manifest.teacher_feedback}</p>
      <ul>{manifest.dimensions?.map(d => <li key={d.observation_code}>
        {d.observation_code}: {d.points_awarded} / {d.points_possible}</li>)}</ul>
    </div>}
    <label><input type="checkbox" checked={confirmed}
      disabled={!manifestReady || busy}
      onChange={e => setConfirmed(e.target.checked)} />
      I have checked all 30 human scores, the curriculum evidence, and the teacher feedback
      in this exact report version, and authorise publication.</label>
    <button type="button" className="proto-action"
      disabled={busy || !manifestReady || !confirmed}
      onClick={() => void perform(async () => {
        await request("/api/v1/admin/pa-scoring/publish", {
          composition_approval_id: compositionId, idempotency_key: idempotencyKey,
        });
        setConfirmed(false);
        await onPublished();
      }, "Human-approved scored Evaluation Report published as a new immutable version.")}>
      Publish approved scored Evaluation Report
    </button>
    {error && <p role="alert">{error}</p>}
    {message && <p role="status">{message}</p>}
  </section>;
}
