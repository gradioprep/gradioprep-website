import { useCallback, useEffect, useMemo, useRef, useState, type FormEvent } from "react";

interface TaskContext {
  task_code: string;
  title: string;
  version: number;
  expected_min_words: number;
  ideal_words: number;
  pdf_response_enabled: boolean;
}

interface QueueSubmission {
  id: string;
  task_version_id: string;
  rubric_version_id: string;
  response_mode: string;
  status: string;
  accepted_at: string;
  grading_due_at: string;
  sla_target_seconds: number;
  task_versions: TaskContext | TaskContext[] | null;
}

interface ResponseVersion {
  id: string;
  version_number: number;
  response_text: string | null;
  word_count: number;
  created_at: string;
}

interface Prompt {
  id: string;
  sequence: number;
  prompt_text: string;
}

interface Rubric {
  id: string;
  version: number;
  title: string;
}

interface RubricCriterion {
  id: string;
  criterion_code: string;
  sequence: number;
  title: string;
  descriptor: string;
  max_points: number;
}

interface CriterionDraft {
  criterion_id: string;
  points_awarded: number;
  feedback: string;
}

interface AssessmentDraft {
  overall_feedback: string;
  change_reason: string | null;
  criterion_results: CriterionDraft[];
  draft_revision: number;
  updated_at: string;
}

interface PublishedCriterion {
  criterion_code_snapshot: string;
  criterion_title_snapshot: string;
  descriptor_snapshot: string;
  points_awarded: number;
  max_points_snapshot: number;
  feedback: string;
}

interface PublishedVersion {
  id: string;
  version_number: number;
  total_points: number;
  max_points: number;
  overall_feedback: string;
  published_at: string;
  sla_met: boolean;
  criterion_results: PublishedCriterion[];
}

interface SubmissionDetail {
  submission: QueueSubmission;
  response_versions: ResponseVersion[];
  prompts: Prompt[];
  rubric: Rubric | null;
  criteria: RubricCriterion[];
  assignment: { grader_user_id: string; assigned_at: string };
  published_versions: PublishedVersion[];
  draft: AssessmentDraft | null;
}

interface TranscriptPage {
  page_number: number;
  text: string;
  status: "digital_text" | "no_text_layer" | "teacher_transcribed";
}

interface PrivateDocument {
  file?: {
    version: number;
    page_count: number;
    signed_url: string;
    expires_in_seconds: number;
  };
  transcript?: {
    version: number;
    verification_state: string;
    page_count: number;
    pages: TranscriptPage[];
  } | null;
  error?: string;
}

interface CriterionInput {
  points_awarded: number;
  feedback: string;
}

function taskFor(row: QueueSubmission | null): TaskContext | null {
  if (!row) return null;
  const task = row.task_versions;
  return Array.isArray(task) ? task[0] ?? null : task;
}

function localDate(value: string): string {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
}

export default function GraderWorkspacePanel({
  accessToken,
  assuranceLevel,
}: {
  accessToken: string;
  assuranceLevel: string;
}) {
  const [queue, setQueue] = useState<QueueSubmission[]>([]);
  const [selectedId, setSelectedId] = useState("");
  const [detail, setDetail] = useState<SubmissionDetail | null>(null);
  const [privateDocument, setPrivateDocument] = useState<PrivateDocument | null>(null);
  const [fileMessage, setFileMessage] = useState("");
  const [overallFeedback, setOverallFeedback] = useState("");
  const [changeReason, setChangeReason] = useState("");
  const [criterionInputs, setCriterionInputs] = useState<Record<string, CriterionInput>>({});
  const [draftDirty, setDraftDirty] = useState(false);
  const [loadingQueue, setLoadingQueue] = useState(false);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [savingDraft, setSavingDraft] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const detailRequest = useRef(0);

  const aal2Ready = assuranceLevel === "aal2";

  const refreshQueue = useCallback(async () => {
    if (!aal2Ready) return;
    setLoadingQueue(true);
    setError("");
    try {
      const response = await fetch("/api/v1/grader/submissions", {
        headers: { Authorization: "Bearer " + accessToken },
        cache: "no-store",
      });
      const result = await response.json() as { submissions?: QueueSubmission[]; error?: string };
      if (!response.ok) throw new Error(result.error ?? "The assigned submission queue could not be loaded.");
      const rows = Array.isArray(result.submissions) ? result.submissions : [];
      setQueue(rows);
      setSelectedId(current => rows.some(row => row.id === current) ? current : (rows[0]?.id ?? ""));
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The assigned submission queue could not be loaded.");
    } finally {
      setLoadingQueue(false);
    }
  }, [accessToken, aal2Ready]);

  const loadSubmission = useCallback(async (submissionId: string) => {
    const requestNumber = ++detailRequest.current;
    if (!submissionId || !aal2Ready) {
      setDetail(null);
      setPrivateDocument(null);
      setFileMessage("");
      setOverallFeedback("");
      setChangeReason("");
      setCriterionInputs({});
      setDraftDirty(false);
      return;
    }

    setLoadingDetail(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/grader/submissions/" + encodeURIComponent(submissionId), {
        headers: { Authorization: "Bearer " + accessToken },
        cache: "no-store",
      });
      const result = await response.json() as SubmissionDetail & { error?: string };
      if (!response.ok) throw new Error(result.error ?? "The assigned submission could not be opened.");
      if (detailRequest.current !== requestNumber) return;

      let document: PrivateDocument | null = null;
      let documentMessage = "This submission has no attached PDF. The typed response remains the authoritative submission.";
      if (result.submission.response_mode === "typed_pdf" || result.submission.response_mode === "pdf_only") {
        const fileResponse = await fetch("/api/v1/submissions/" + encodeURIComponent(submissionId) + "/file", {
          headers: { Authorization: "Bearer " + accessToken },
          cache: "no-store",
        });
        const fileResult = await fileResponse.json() as PrivateDocument;
        if (fileResponse.ok && fileResult.file?.signed_url) {
          document = fileResult;
          documentMessage = "";
        } else {
          documentMessage = fileResult.error ?? "The private PDF is unavailable. Reload the submission to request a fresh link.";
        }
      }
      if (detailRequest.current !== requestNumber) return;

      const savedResults = Array.isArray(result.draft?.criterion_results)
        ? result.draft.criterion_results
        : [];
      const inputs: Record<string, CriterionInput> = {};
      for (const criterion of result.criteria ?? []) {
        const saved = savedResults.find(item => item.criterion_id === criterion.id);
        inputs[criterion.id] = {
          points_awarded: Number(saved?.points_awarded ?? 0),
          feedback: saved?.feedback ?? "",
        };
      }

      setDetail(result);
      setPrivateDocument(document);
      setFileMessage(documentMessage);
      setOverallFeedback(result.draft?.overall_feedback ?? "");
      setChangeReason(result.draft?.change_reason ?? "");
      setCriterionInputs(inputs);
      setDraftDirty(false);
    } catch (requestError) {
      if (detailRequest.current === requestNumber) {
        setDetail(null);
        setPrivateDocument(null);
        setError(requestError instanceof Error ? requestError.message : "The assigned submission could not be opened.");
      }
    } finally {
      if (detailRequest.current === requestNumber) setLoadingDetail(false);
    }
  }, [accessToken, aal2Ready]);

  useEffect(() => {
    if (!aal2Ready) {
      setQueue([]);
      setSelectedId("");
      setDetail(null);
      setPrivateDocument(null);
      setLoadingQueue(false);
      setLoadingDetail(false);
      return;
    }
    void refreshQueue();
  }, [aal2Ready, refreshQueue]);

  useEffect(() => {
    void loadSubmission(selectedId);
  }, [selectedId, loadSubmission]);

  const selectedQueueItem = useMemo(
    () => queue.find(item => item.id === selectedId) ?? null,
    [queue, selectedId],
  );
  const selectedTask = taskFor(detail?.submission ?? selectedQueueItem);

  const validDraft = Boolean(
    detail &&
    detail.criteria.length > 0 &&
    overallFeedback.trim().length >= 5 &&
    (detail.published_versions.length === 0 || changeReason.trim().length >= 3) &&
    detail.criteria.every(criterion => {
      const input = criterionInputs[criterion.id];
      return input &&
        Number.isFinite(input.points_awarded) &&
        input.points_awarded >= 0 &&
        input.points_awarded <= Number(criterion.max_points) &&
        input.feedback.trim().length >= 5;
    }),
  );

  function updateCriterion(criterionId: string, patch: Partial<CriterionInput>) {
    setCriterionInputs(current => ({
      ...current,
      [criterionId]: { ...current[criterionId], ...patch },
    }));
    setDraftDirty(true);
    setMessage("");
  }

  async function saveDraft(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedId || !detail || !validDraft || !aal2Ready) return;
    setSavingDraft(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/grader/submissions/" + encodeURIComponent(selectedId) + "/draft", {
        method: "PUT",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          overall_feedback: overallFeedback.trim(),
          ...(changeReason.trim() ? { change_reason: changeReason.trim() } : {}),
          criterion_results: detail.criteria.map(criterion => ({
            criterion_id: criterion.id,
            points_awarded: criterionInputs[criterion.id].points_awarded,
            feedback: criterionInputs[criterion.id].feedback.trim(),
          })),
        }),
      });
      const result = await response.json() as { draft?: unknown; error?: string };
      if (!response.ok || !result.draft) {
        throw new Error(result.error === "assessment_change_reason_required"
          ? "Add a reason before revising already-published feedback."
          : result.error ?? "The private grading draft could not be saved.");
      }
      await loadSubmission(selectedId);
      setMessage("Private grading draft saved. It has not been published to the learner.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The private grading draft could not be saved.");
    } finally {
      setSavingDraft(false);
    }
  }

  async function publishFeedback() {
    if (!selectedId || !detail?.draft || draftDirty || publishing || !aal2Ready) return;
    const confirmed = window.confirm(
      "Publish this human-reviewed feedback to the learner now? Published versions are immutable.",
    );
    if (!confirmed) return;
    setPublishing(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/grader/submissions/" + encodeURIComponent(selectedId) + "/publish", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({}),
      });
      const result = await response.json() as { assessment?: unknown; error?: string };
      if (!response.ok || !result.assessment) {
        throw new Error(result.error ?? "Feedback could not be published.");
      }
      await Promise.all([refreshQueue(), loadSubmission(selectedId)]);
      setMessage("Feedback published. The learner can now view this immutable version.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Feedback could not be published.");
    } finally {
      setPublishing(false);
    }
  }

  if (!aal2Ready) {
    return <section className="proto-panel proto-grader-workspace" data-testid="grader-workspace">
      <div className="proto-account-security-heading">
        <div><p className="proto-eyebrow"><span />ASSIGNED ASSESSMENT WORK</p><h3>Grader workspace</h3></div>
        <span className="proto-account-status">Second factor required</span>
      </div>
      <p>Verify your authenticator app before opening assigned submissions, private learner documents or grading controls.</p>
    </section>;
  }

  return <section className="proto-panel proto-grader-workspace" data-testid="grader-workspace">
    <div className="proto-account-security-heading">
      <div><p className="proto-eyebrow"><span />ASSIGNED ASSESSMENT WORK</p><h3>Grader workspace</h3></div>
      <span className="proto-account-status">AAL2 verified</span>
    </div>
    <p className="proto-grader-workspace-intro">
      Assigned work is shown oldest first. Open the task, read the learner response against its saved rubric and private PDF evidence, then save a private draft. Only the explicit publication action sends feedback to the learner.
    </p>

    <div className="proto-grader-toolbar">
      <label htmlFor="proto-grader-submission">Assigned submissions · oldest first
        <select
          id="proto-grader-submission"
          value={selectedId}
          onChange={event => setSelectedId(event.target.value)}
          disabled={loadingQueue || queue.length === 0}
        >
          {queue.length === 0 && <option value="">No assigned submissions</option>}
          {queue.map(item => {
            const task = taskFor(item);
            return <option key={item.id} value={item.id}>
              {localDate(item.accepted_at)} · {task?.task_code ?? "Task"} · {item.id.slice(0, 8)} · {item.status.replaceAll("_", " ")}
            </option>;
          })}
        </select>
      </label>
      <button type="button" className="proto-account-toggle" onClick={() => void refreshQueue()} disabled={loadingQueue}>
        {loadingQueue ? "Refreshing…" : "Refresh queue"}
      </button>
    </div>

    {loadingQueue && <p role="status">Loading assigned submissions…</p>}
    {!loadingQueue && queue.length === 0 && <p className="proto-grader-empty">There are no submissions currently assigned to your account.</p>}
    {loadingDetail && <p role="status">Opening task context, rubric and private learner evidence…</p>}

    {detail && !loadingDetail && <>
      <div className="proto-grader-context">
        <div>
          <p className="proto-eyebrow">TASK CONTEXT</p>
          <h4>{selectedTask?.title ?? "Assessment task"}</h4>
          <p>{selectedTask?.task_code ?? "Task"} · Version {selectedTask?.version ?? "—"} · {detail.submission.response_mode.replaceAll("_", " ")}</p>
        </div>
        <div>
          <small>ACCEPTED</small><strong>{localDate(detail.submission.accepted_at)}</strong>
          <small>GRADING DUE</small><strong>{localDate(detail.submission.grading_due_at)}</strong>
          <small>WORKFLOW</small><strong>{detail.submission.status.replaceAll("_", " ")}</strong>
        </div>
      </div>

      <section className="proto-grader-block" aria-label="Question context">
        <h4>Question and task instructions</h4>
        {detail.prompts.length
          ? detail.prompts.map(prompt => <article key={prompt.id}>
              <small>QUESTION {prompt.sequence}</small>
              <p>{prompt.prompt_text}</p>
            </article>)
          : <p>No question prompt is attached to this task version.</p>}
      </section>

      <section className="proto-grader-block" aria-label="Learner response">
        <h4>Learner response</h4>
        {detail.response_versions.length
          ? detail.response_versions.map(version => <article key={version.id} className="proto-grader-response-version">
              <div><strong>Response version {version.version_number}</strong><small>{version.word_count} words · {localDate(version.created_at)}</small></div>
              <p>{version.response_text ?? "No typed response; review the original PDF and its page-aligned transcript below."}</p>
            </article>)
          : <p>This submission has no typed response. Review the original PDF and transcript below.</p>}
      </section>

      <section className="proto-grader-block">
        <h4>Original PDF and page-aligned transcript</h4>
        {privateDocument?.file?.signed_url
          ? <div className="proto-grader-document-split">
              <section className="proto-grader-pdf" aria-label="Original private PDF">
                <div><strong>Original private PDF</strong><small>Authoritative source · short-lived private link</small></div>
                <iframe title="Original grader submission PDF" src={privateDocument.file.signed_url} referrerPolicy="no-referrer" />
              </section>
              <section className="proto-grader-transcript" aria-label="Page-aligned transcript">
                <div><strong>Page-aligned transcript</strong>
                  <small>Transcript v{privateDocument.transcript?.version ?? "—"} · {privateDocument.transcript?.verification_state.replaceAll("_", " ") ?? "not available"}</small>
                </div>
                {privateDocument.transcript?.pages.map(page => <article key={page.page_number}>
                  <div><strong>Page {page.page_number}</strong><small>{page.status.replaceAll("_", " ")}</small></div>
                  <pre>{page.text || "No digital text was detected on this page. Use the original PDF as the source."}</pre>
                </article>)}
              </section>
            </div>
          : <p className="proto-grader-file-note">{fileMessage || "No private PDF is attached to this response."}</p>}
      </section>

      <section className="proto-grader-block proto-grader-rubric" aria-label="Exact assessment rubric">
        <div>
          <h4>Exact rubric for this submission</h4>
          <p>{detail.rubric?.title ?? "Rubric unavailable"} · Version {detail.rubric?.version ?? "—"}</p>
        </div>
        {detail.criteria.map(criterion => <article key={criterion.id}>
          <div><strong>{criterion.sequence}. {criterion.title}</strong><span>Maximum {criterion.max_points} points</span></div>
          <p>{criterion.descriptor}</p>
        </article>)}
      </section>

      <section className="proto-grader-block">
        <h4>Published feedback history</h4>
        {detail.published_versions.length
          ? detail.published_versions.map(version => <article className="proto-grader-published-version" key={version.id}>
              <div><strong>Published version {version.version_number}</strong><span>{version.total_points} / {version.max_points} points · {localDate(version.published_at)} · {version.sla_met ? "Within 24-hour target" : "Outside 24-hour target"}</span></div>
              <p>{version.overall_feedback}</p>
              {version.criterion_results.map((criterion, index) => <div key={criterion.criterion_code_snapshot + "-" + index}>
                <strong>{criterion.criterion_title_snapshot}: {criterion.points_awarded} / {criterion.max_points_snapshot}</strong>
                <p>{criterion.feedback}</p>
              </div>)}
            </article>)
          : <p>No feedback has been published for this submission yet.</p>}
      </section>

      <form className="proto-grader-draft-form" onSubmit={saveDraft}>
        <div>
          <p className="proto-eyebrow">PRIVATE HUMAN-GRADING DRAFT</p>
          <h4>Prepare criterion-based feedback</h4>
          <p>Draft marks and comments remain private until you explicitly publish. The rubric version attached at acceptance cannot be substituted.</p>
        </div>
        <label htmlFor="proto-grader-overall-feedback">Overall feedback
          <textarea id="proto-grader-overall-feedback" rows={4} maxLength={8000}
            value={overallFeedback} onChange={event => { setOverallFeedback(event.target.value); setDraftDirty(true); setMessage(""); }}
            placeholder="Summarise the response's strengths and the most useful next step." required />
        </label>
        {detail.criteria.map(criterion => <article className="proto-grader-criterion-input" key={criterion.id}>
          <div><strong>{criterion.sequence}. {criterion.title}</strong><span>Maximum {criterion.max_points} points</span></div>
          <label htmlFor={"proto-grader-score-" + criterion.id}>Points awarded
            <input id={"proto-grader-score-" + criterion.id} type="number" min="0" max={criterion.max_points} step="0.01"
              value={criterionInputs[criterion.id]?.points_awarded ?? 0}
              onChange={event => updateCriterion(criterion.id, { points_awarded: Number(event.target.value) })} required />
          </label>
          <label htmlFor={"proto-grader-criterion-feedback-" + criterion.id}>Criterion feedback
            <textarea id={"proto-grader-criterion-feedback-" + criterion.id} rows={3} maxLength={3000}
              value={criterionInputs[criterion.id]?.feedback ?? ""}
              onChange={event => updateCriterion(criterion.id, { feedback: event.target.value })}
              placeholder="Explain the mark with reference to the response and rubric descriptor." required />
          </label>
        </article>)}
        {detail.published_versions.length > 0 && <label htmlFor="proto-grader-change-reason">Reason for revising published feedback
          <textarea id="proto-grader-change-reason" rows={2} maxLength={240} value={changeReason}
            onChange={event => { setChangeReason(event.target.value); setDraftDirty(true); setMessage(""); }}
            placeholder="Explain why a new immutable feedback version is required." required />
        </label>}
        <div className="proto-grader-actions">
          <button className="proto-action" type="submit" disabled={!validDraft || savingDraft || publishing}>
            {savingDraft ? "Saving private draft…" : "Save private grading draft"}
          </button>
          <button className="proto-action secondary" type="button"
            onClick={() => void publishFeedback()}
            disabled={!detail.draft || draftDirty || publishing || savingDraft}>
            {publishing ? "Publishing…" : "Publish feedback to learner"}
          </button>
        </div>
        <small>Saving a draft does not notify the learner. Publication requires a separate human action and creates an immutable, versioned feedback record with an audit event.</small>
      </form>
    </>}

    {error && <p className="proto-account-submission-feedback error" role="alert">{error}</p>}
    {message && <p className="proto-account-submission-feedback" role="status">{message}</p>}
  </section>;
}
