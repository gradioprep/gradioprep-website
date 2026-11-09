import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react";

type ReviewRole = "grader" | "owner";

interface SubmissionRow {
  id: string;
  response_mode: string;
  status: string;
  accepted_at: string;
  grading_due_at: string;
  task_versions?: {
    task_code?: string;
    title?: string;
    version?: number;
  } | null;
}

interface TranscriptPage {
  page_number: number;
  text: string;
  status: "digital_text" | "no_text_layer" | "teacher_transcribed";
}

interface TranscriptVersion {
  version: number;
  method: string;
  state: string;
  verification_state: string;
  page_count: number;
  pages: TranscriptPage[];
  text: string;
  review_note?: string | null;
  created_at?: string;
}

interface PrivatePdfResponse {
  file?: {
    version: number;
    page_count: number;
    signed_url: string;
    expires_in_seconds: number;
  };
  transcript?: TranscriptVersion | null;
  error?: string;
}

function normalizeReviewVersion(value: Record<string, unknown>): TranscriptVersion | null {
  const rawPages = value.pages;
  if (!Array.isArray(rawPages)) return null;
  const pages = rawPages as TranscriptPage[];
  const version = typeof value.version === "number"
    ? value.version
    : typeof value.transcript_version === "number"
      ? value.transcript_version
      : null;
  if (version === null || !pages.length) return null;
  return {
    version,
    method: String(value.method ?? value.extraction_method ?? "teacher_review"),
    state: String(value.state ?? value.extraction_state ?? "partial"),
    verification_state: String(value.verification_state ?? "unverified"),
    page_count: typeof value.page_count === "number" ? value.page_count : pages.length,
    pages,
    text: String(value.text ?? value.content_text ?? ""),
    review_note: typeof value.review_note === "string" ? value.review_note : null,
    created_at: typeof value.created_at === "string" ? value.created_at : undefined,
  };
}

function pageStatusLabel(status: TranscriptPage["status"]): string {
  if (status === "no_text_layer") return "No digital text layer";
  if (status === "teacher_transcribed") return "Teacher-transcribed or corrected";
  return "Digital text";
}

export default function TranscriptReviewPanel({
  accessToken,
  role,
  assuranceLevel,
}: {
  accessToken: string;
  role: ReviewRole;
  assuranceLevel: string;
}) {
  const [submissions, setSubmissions] = useState<SubmissionRow[]>([]);
  const [selectedId, setSelectedId] = useState("");
  const [fileUrl, setFileUrl] = useState("");
  const [transcript, setTranscript] = useState<TranscriptVersion | null>(null);
  const [draftPages, setDraftPages] = useState<TranscriptPage[]>([]);
  const [reviewNote, setReviewNote] = useState("");
  const [loadingQueue, setLoadingQueue] = useState(false);
  const [loadingFile, setLoadingFile] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const queueUrl = role === "owner"
    ? "/api/v1/admin/submissions/queue"
    : "/api/v1/grader/submissions";

  const refreshQueue = useCallback(async () => {
    setLoadingQueue(true);
    setError("");
    try {
      const response = await fetch(queueUrl, {
        headers: { Authorization: "Bearer " + accessToken },
        cache: "no-store",
      });
      const result = await response.json() as { submissions?: SubmissionRow[]; message?: string };
      if (!response.ok) throw new Error(result.message ?? "The review queue could not be loaded.");
      const rows = Array.isArray(result.submissions) ? result.submissions : [];
      setSubmissions(rows);
      setSelectedId(current => rows.some(row => row.id === current) ? current : (rows[0]?.id ?? ""));
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The review queue could not be loaded.");
    } finally {
      setLoadingQueue(false);
    }
  }, [accessToken, queueUrl]);

  useEffect(() => {
    if (assuranceLevel !== "aal2") return;
    void refreshQueue();
  }, [assuranceLevel, refreshQueue]);

  const refreshSelectedFile = useCallback(async () => {
    if (!selectedId) {
      setFileUrl("");
      setTranscript(null);
      setDraftPages([]);
      return;
    }
    setLoadingFile(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/submissions/" + selectedId + "/file", {
        headers: { Authorization: "Bearer " + accessToken },
        cache: "no-store",
      });
      const result = await response.json() as PrivatePdfResponse;
      if (!response.ok || !result.file?.signed_url) {
        throw new Error(result.error ?? "The original private PDF could not be opened.");
      }
      if (!result.transcript) {
        throw new Error("This submission has no digital-text transcript to review.");
      }
      const normalized = normalizeReviewVersion(result.transcript as unknown as Record<string, unknown>);
      if (!normalized) throw new Error("The transcript version could not be read.");
      setFileUrl(result.file.signed_url);
      setTranscript(normalized);
      setDraftPages(normalized.pages.map(page => ({ ...page })));
      setReviewNote("");
    } catch (requestError) {
      setFileUrl("");
      setTranscript(null);
      setDraftPages([]);
      setError(requestError instanceof Error ? requestError.message : "The original private PDF could not be opened.");
    } finally {
      setLoadingFile(false);
    }
  }, [accessToken, selectedId]);

  useEffect(() => {
    void refreshSelectedFile();
  }, [refreshSelectedFile]);

  const changedPages = useMemo(() => {
    if (!transcript) return 0;
    return draftPages.filter((page, index) =>
      page.text !== transcript.pages[index]?.text
    ).length;
  }, [draftPages, transcript]);

  const pagesValid = useMemo(() => {
    if (!transcript || draftPages.length !== transcript.page_count) return false;
    return draftPages.every((page, index) => {
      const original = transcript.pages[index];
      if (!original || page.page_number !== index + 1 || page.text.length > 12_000) return false;
      if (original.status === "no_text_layer" && page.text.trim().length === 0) return true;
      return page.text.trim().length > 0;
    });
  }, [draftPages, transcript]);

  function changePage(index: number, text: string) {
    setDraftPages(current => current.map((page, pageIndex) =>
      pageIndex === index ? { ...page, text } : page
    ));
    setMessage("");
  }

  function buildReviewPages(): TranscriptPage[] {
    if (!transcript) return [];
    return draftPages.map((page, index) => {
      const original = transcript.pages[index];
      const changed = page.text.trim() !== original.text.trim();
      const nextStatus = page.text.trim().length === 0
        ? "no_text_layer"
        : changed
          ? "teacher_transcribed"
          : original.status;
      return {
        page_number: index + 1,
        text: page.text.trim(),
        status: nextStatus,
      };
    });
  }

  async function saveReview(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedId || !transcript || !pagesValid || reviewNote.trim().length < 3) return;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/submissions/" + selectedId + "/transcript", {
        method: "PUT",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          expected_version: transcript.version,
          pages: buildReviewPages(),
          review_note: reviewNote.trim(),
        }),
      });
      const result = await response.json() as {
        transcript?: Record<string, unknown>;
        error?: string;
        message?: string;
      };
      if (response.status === 409 && result.error === "submission_transcript_version_conflict") {
        throw new Error("A newer transcript version has already been saved. Reload the latest version before editing again.");
      }
      if (!response.ok || !result.transcript) {
        throw new Error(result.message ?? result.error ?? "The transcript review could not be saved.");
      }
      const normalized = normalizeReviewVersion(result.transcript);
      if (!normalized) throw new Error("The saved transcript version could not be read.");
      const confirmation = normalized.verification_state === "teacher_corrected"
        ? "A new corrected transcript version was saved. Earlier versions remain unchanged."
        : "A new verified transcript version was saved. Earlier versions remain unchanged.";
      setTranscript(normalized);
      setDraftPages(normalized.pages.map(page => ({ ...page })));
      setReviewNote("");
      await refreshSelectedFile();
      setMessage(confirmation);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The transcript review could not be saved.");
    } finally {
      setSaving(false);
    }
  }

  if (assuranceLevel !== "aal2") {
    return <section className="proto-panel proto-transcript-review" aria-labelledby="proto-transcript-review-heading">
      <div className="proto-account-security-heading">
        <div><p className="proto-eyebrow"><span />PRIVATE ACADEMIC REVIEW</p><h3 id="proto-transcript-review-heading">PDF and transcript review</h3></div>
        <span className="proto-account-status">Second factor required</span>
      </div>
      <p>Verify your authenticator app to open assigned submissions and review private learner PDFs.</p>
    </section>;
  }

  return <section className="proto-panel proto-transcript-review" aria-labelledby="proto-transcript-review-heading">
    <div className="proto-account-security-heading">
      <div>
        <p className="proto-eyebrow"><span />PRIVATE ACADEMIC REVIEW</p>
        <h3 id="proto-transcript-review-heading">PDF and transcript review</h3>
      </div>
      <span className="proto-account-status">AAL2 verified</span>
    </div>
    <p className="proto-transcript-review-intro">
      Compare the original private PDF with its page-aligned digital transcript. Corrected text is saved as a new immutable version; the original PDF is never changed.
    </p>

    <div className="proto-transcript-review-toolbar">
      <label htmlFor="proto-transcript-submission">Submission queue
        <select
          id="proto-transcript-submission"
          value={selectedId}
          onChange={event => setSelectedId(event.target.value)}
          disabled={loadingQueue || submissions.length === 0}
        >
          {submissions.length === 0 && <option value="">No assigned submissions</option>}
          {submissions.map(row => <option key={row.id} value={row.id}>
            {(row.task_versions?.task_code ?? "Submission") + " · " +
              (row.task_versions?.title ?? row.id.slice(0, 8)) + " · " + row.status}
          </option>)}
        </select>
      </label>
      <button type="button" className="proto-account-toggle" onClick={() => void refreshQueue()} disabled={loadingQueue}>
        {loadingQueue ? "Refreshing…" : "Refresh queue"}
      </button>
    </div>

    {loadingFile ? <p role="status">Opening the original PDF and latest transcript…</p> :
      !selectedId ? <p>No submissions are currently available in this queue.</p> :
      !transcript ? <p>Select a submission with an accepted PDF transcript to review.</p> :
      <>
        <div className="proto-transcript-review-meta">
          <span>Transcript v{transcript.version}</span>
          <span>{transcript.verification_state.replaceAll("_", " ")}</span>
          <span>{transcript.page_count} pages</span>
          <span>{changedPages} changed pages</span>
          <button type="button" className="proto-account-toggle" onClick={() => void refreshSelectedFile()}>
            Reload original PDF and latest version
          </button>
        </div>

        <div className="proto-transcript-review-split">
          <section className="proto-transcript-original" aria-label="Original PDF">
            <div className="proto-transcript-pane-heading">
              <strong>Original PDF</strong>
              <small>Authoritative source · private link</small>
            </div>
            {fileUrl
              ? <iframe title="Original learner submission PDF" src={fileUrl} referrerPolicy="no-referrer" />
              : <p>The signed PDF link is unavailable. Reload the submission.</p>}
          </section>

          <section className="proto-transcript-editor" aria-label="Digital text transcript">
            <div className="proto-transcript-pane-heading">
              <strong>Page-by-page transcript</strong>
              <small>Review against the PDF before saving</small>
            </div>
            {transcript.verification_state === "unverified" &&
              <p className="proto-transcript-warning">This transcript has not yet been checked by a teacher. It may contain extraction errors or omissions.</p>}
            {draftPages.map((page, index) => <article className="proto-transcript-page" key={page.page_number}>
              <div className="proto-transcript-page-heading">
                <strong>Page {page.page_number}</strong>
                <span>{pageStatusLabel(page.status)}</span>
              </div>
              {page.status === "no_text_layer" && !page.text.trim() &&
                <p className="proto-transcript-no-text">No digital text was detected on this page. Read the original PDF and enter a human transcription only when the page is legible.</p>}
              <label htmlFor={"proto-transcript-page-" + page.page_number}>
                {page.status === "no_text_layer" ? "Teacher transcription" : "Extracted text / correction"}
              </label>
              <textarea
                id={"proto-transcript-page-" + page.page_number}
                rows={7}
                maxLength={12_000}
                value={page.text}
                onChange={event => changePage(index, event.target.value)}
                aria-label={"Transcript text for page " + page.page_number}
              />
              <small>{page.text.length.toLocaleString()} / 12,000 characters</small>
            </article>)}
          </section>
        </div>

        <form className="proto-transcript-review-form" onSubmit={saveReview}>
          <label htmlFor="proto-transcript-review-note">Review note
            <textarea
              id="proto-transcript-review-note"
              rows={2}
              maxLength={240}
              value={reviewNote}
              onChange={event => setReviewNote(event.target.value)}
              placeholder="Record what was checked or corrected against the original PDF."
              required
            />
          </label>
          <small>Saving creates a new immutable transcript version and records the reviewer. It does not overwrite earlier versions.</small>
          <button className="proto-action" type="submit"
            disabled={saving || loadingFile || !pagesValid || reviewNote.trim().length < 3}>
            {saving ? "Saving review…" : changedPages ? "Save corrected transcript version" : "Save verified transcript version"}
          </button>
        </form>
      </>}

    {error && <p className="proto-account-submission-feedback error" role="alert">{error}</p>}
    {message && <p className="proto-account-submission-feedback" role="status">{message}</p>}
  </section>;
}
