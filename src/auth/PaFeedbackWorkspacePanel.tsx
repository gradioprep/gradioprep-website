import { useState } from "react";

type QueueEntry = {
  report_record_id: string; created_at: string; version_number: number;
  curriculum_mapping_status: string; evidence_sufficiency_status: string;
};
type Draft = { draft_id: string; report_version_id: string; draft_text: string; created_at: string };
type Review = { review_id: string; draft_id: string; decision: string; reviewer_note: string; decided_at: string };
type Report = {
  report_record_id: string; report_version_id: string; version_number: number;
  curriculum_mapping_status: string; evidence_sufficiency_status: string;
  content_snapshot?: { observations?: Array<{ observation_code?: string }> };
  published_feedback_snapshot?: { status?: string };
};

export default function PaFeedbackWorkspacePanel({
  accessToken, owner, assuranceLevel,
}: { accessToken: string; owner: boolean; assuranceLevel: string }) {
  const [recordId, setRecordId] = useState("");
  const [queue, setQueue] = useState<QueueEntry[]>([]);
  const [queueLoaded, setQueueLoaded] = useState(false);
  const [report, setReport] = useState<Report | null>(null);
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [draftText, setDraftText] = useState("");
  const [reviewNotes, setReviewNotes] = useState("");
  const [selectedDraft, setSelectedDraft] = useState("");
  const [selectedReview, setSelectedReview] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function request(path: string, body?: object) {
    const response = await fetch(path, {
      method: body ? "POST" : "GET",
      headers: { Authorization: "Bearer " + accessToken, ...(body ? { "Content-Type": "application/json" } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
      cache: "no-store",
    });
    const data = await response.json() as Record<string, unknown>;
    if (!response.ok) throw new Error(response.status === 409
      ? "This report has changed or is not eligible for this action."
      : response.status === 403 || response.status === 404
        ? "This report or action is unavailable for your account."
        : "The request could not be completed.");
    return data;
  }

  async function loadQueue() {
    const result = await request("/api/v1/staff/pa-feedback/queue");
    setQueue((result.reports as QueueEntry[]) ?? []);
    setQueueLoaded(true);
  }

  async function openReport(targetId: string) {
    setRecordId(targetId);
    setReport(null); setDrafts([]); setReviews([]);
    setSelectedDraft(""); setSelectedReview("");
    await refresh(targetId);
  }

  async function refresh(targetId = recordId) {
    const [reportResult, draftResult, reviewResult] = await Promise.all([
      request("/api/v1/learner/evaluation-reports/" + targetId),
      request("/api/v1/staff/pa-feedback/" + targetId + "/drafts"),
      request("/api/v1/staff/pa-feedback/" + targetId + "/reviews"),
    ]);
    setReport(reportResult.report as Report);
    setDrafts((draftResult.items as Draft[]) ?? []);
    setReviews((reviewResult.items as Review[]) ?? []);
  }

  async function perform(action: () => Promise<void>, success: string) {
    setBusy(true); setError(""); setMessage("");
    try { await action(); setMessage(success); }
    catch (err) { setError(err instanceof Error ? err.message : "The request could not be completed."); }
    finally { setBusy(false); }
  }

  const eligible = report?.curriculum_mapping_status === "complete_direct" &&
    report?.evidence_sufficiency_status === "sufficient";
  const selected = drafts.find(item => item.draft_id === selectedDraft);
  const reviewed = reviews.find(item => item.review_id === selectedReview);
  const canPublish = owner && eligible && reviewed?.decision === "approved_for_publication" &&
    reviewed.draft_id === selected?.draft_id && selected?.report_version_id === report?.report_version_id;

  return <section className="proto-panel" aria-labelledby="pa-feedback-workspace-title">
    <div className="proto-panel-heading">
      <div><p className="proto-eyebrow"><span />STAFF WORKSPACE</p>
        <h3 id="pa-feedback-workspace-title">Evaluation Report review</h3>
        <p>Prepare feedback and review its evidence before publication.</p></div>
    </div>
    {assuranceLevel !== "aal2" ? <p role="status">Verify your authenticator to access report review.</p> : <>
      <div className="proto-pa-review-queue">
        <button className="proto-action secondary" disabled={busy}
          onClick={() => void perform(loadQueue, "Review queue updated.")}>Load review queue</button>
        {queueLoaded && (queue.length === 0 ? <p>No Evaluation Reports are currently assigned to your account.</p> :
          <ul aria-label="Evaluation Reports available for review">
            {queue.map(entry => <li key={entry.report_record_id}>
              <div>
                <strong>Evaluation Report · Version {entry.version_number}</strong>
                <p>Received {new Date(entry.created_at).toLocaleString()}</p>
                <p>{entry.curriculum_mapping_status === "complete_direct" ? "Curriculum links verified" : "Curriculum review incomplete"} · {entry.evidence_sufficiency_status === "sufficient" ? "Evidence sufficient" : "Evidence incomplete"}</p>
              </div>
              <button className="proto-action secondary" type="button" disabled={busy}
                onClick={() => void perform(() => openReport(entry.report_record_id), "Report loaded for review.")}>
                Open report
              </button>
            </li>)}
          </ul>)}
      </div>
      <label>Evaluation Report record ID
        <input value={recordId} onChange={event => {
          setRecordId(event.target.value.trim()); setReport(null); setDrafts([]); setReviews([]);
          setSelectedDraft(""); setSelectedReview("");
        }} placeholder="Report UUID" aria-label="Evaluation Report record ID" />
      </label>
      <button className="proto-action secondary" disabled={busy || !/^[0-9a-f-]{36}$/i.test(recordId)}
        onClick={() => void perform(() => refresh(), "Report records loaded.")}>Open report</button>
      {report && <>
        <p><strong>Report version:</strong> {report.version_number}</p>
        <p><strong>Assessment items:</strong> {report.content_snapshot?.observations?.length ?? 0}</p>
        <p><strong>Curriculum connections:</strong> {report.curriculum_mapping_status === "complete_direct" ? "Verified" : "Not complete"}</p>
        <p><strong>Evidence:</strong> {report.evidence_sufficiency_status === "sufficient" ? "Sufficient" : "Not yet sufficient"}</p>
        <p><strong>Feedback:</strong> {report.published_feedback_snapshot?.status === "human_approved_published"
          ? "Published in this version" : "No approved feedback in this version"}</p>
        <p>Only reviewed feedback can be published when the curriculum links and response evidence meet the required checks.</p>
        <label>Teacher feedback
          <textarea rows={7} maxLength={5000} value={draftText} onChange={event => setDraftText(event.target.value)} />
        </label>
        <button className="proto-action secondary" disabled={busy || draftText.trim().length < 20}
          onClick={() => void perform(async () => {
            await request("/api/v1/staff/pa-feedback/drafts", { report_version_id: report.report_version_id, draft_text: draftText });
            setDraftText(""); await refresh();
          }, "Feedback draft saved for review.")}>Save feedback draft</button>
        <h4>Feedback draft history</h4>
        {drafts.length === 0 ? <p>No feedback drafts are recorded.</p> : <ul>
          {drafts.map(draft => <li key={draft.draft_id}>
            <label><input type="radio" name="pa-feedback-draft" checked={selectedDraft === draft.draft_id}
              onChange={() => { setSelectedDraft(draft.draft_id); setSelectedReview(""); }} />
              Draft saved {new Date(draft.created_at).toLocaleString()}</label>
            <p style={{ whiteSpace: "pre-wrap" }}>{draft.draft_text}</p>
          </li>)}
        </ul>}
        <h4>Review history</h4>
        {reviews.length === 0 ? <p>No review decisions are recorded.</p> : <ul>
          {reviews.map(review => <li key={review.review_id}>
            <label><input type="radio" name="pa-feedback-review" checked={selectedReview === review.review_id}
              onChange={() => { setSelectedReview(review.review_id); setSelectedDraft(review.draft_id); }} />
              {review.decision === "approved_for_publication" ? "Approved" : "Changes requested"} · {new Date(review.decided_at).toLocaleString()}</label>
            <p>{review.reviewer_note}</p>
          </li>)}
        </ul>}
        {owner && <>
          <label>Review decision notes
            <textarea rows={3} maxLength={1000} value={reviewNotes} onChange={event => setReviewNotes(event.target.value)} />
          </label>
          <div className="proto-account-actions">
            <button className="proto-action secondary" disabled={busy || !selected || reviewNotes.trim().length < 10}
              onClick={() => void perform(async () => {
                await request("/api/v1/admin/pa-feedback/review", {
                  draft_id: selected!.draft_id, decision: "changes_requested", reviewer_note: reviewNotes,
                });
                setReviewNotes(""); await refresh();
              }, "Changes requested and recorded.")}>Request changes</button>
            <button className="proto-action secondary" disabled={busy || !eligible || !selected ||
              selected.report_version_id !== report.report_version_id || reviewNotes.trim().length < 10}
              onClick={() => void perform(async () => {
                await request("/api/v1/admin/pa-feedback/review", {
                  draft_id: selected!.draft_id, decision: "approved_for_publication", reviewer_note: reviewNotes,
                });
                setReviewNotes(""); await refresh();
              }, "Human review decision recorded.")}>Approve feedback</button>
            <button className="proto-action" disabled={busy || !canPublish}
              onClick={() => void perform(async () => {
                await request("/api/v1/admin/pa-feedback/publish", {
                  review_id: reviewed!.review_id, idempotency_key: crypto.randomUUID(),
                });
                await refresh(); setSelectedReview(""); setSelectedDraft("");
              }, "Approved feedback published as a new report version.")}>Publish approved feedback</button>
          </div>
        </>}
      </>}
      {error && <p role="alert">{error}</p>}
      {message && <p role="status">{message}</p>}
    </>}
  </section>;
}
