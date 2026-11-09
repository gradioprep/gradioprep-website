import { useCallback, useEffect, useState, type FormEvent, type ChangeEvent } from "react";
import { extractDigitalTextFromPdf } from "./pdfTextExtraction";

interface LearnerAssessmentTask {
  id: string;
  task_code: string;
  title: string;
  version: number;
  expected_min_words: number;
  ideal_words: number;
  pdf_response_enabled: boolean;
}

interface LearnerSubmission {
  id: string;
  response_mode: "typed" | "typed_pdf" | "pdf_only";
  status: string;
  accepted_at: string;
  grading_due_at: string;
  task_versions: LearnerAssessmentTask | LearnerAssessmentTask[] | null;
}

interface LearnerSubmissionsResponse {
  submissions?: LearnerSubmission[];
  available_tasks?: LearnerAssessmentTask[];
  error?: string;
  message?: string;
}

const maximumPdfBytes = 10 * 1024 * 1024;

function taskForSubmission(submission: LearnerSubmission): LearnerAssessmentTask | null {
  const task = submission.task_versions;
  return Array.isArray(task) ? task[0] ?? null : task;
}

function pdfEligible(task: LearnerAssessmentTask | null | undefined): boolean {
  return Boolean(task?.pdf_response_enabled && task.ideal_words > 20);
}

function userFacingApiError(code?: string): string {
  const messages: Record<string, string> = {
    assessment_task_not_available: "That assessment is no longer available to your account. Refresh the task list and try again.",
    submission_capacity_full: "This assessment is temporarily full. Your response has not been submitted.",
    submission_capacity_unavailable: "The submission service is temporarily unavailable. Your response has not been submitted.",
    submission_idempotency_conflict: "The submission could not be confirmed. Refresh your submissions before trying again.",
    pdf_extension_required: "Choose a PDF file. Other file types are not accepted.",
    pdf_mime_type_required: "The selected file was not recognised as a PDF.",
    invalid_pdf_signature: "The selected file does not contain a valid PDF signature.",
    pdf_file_too_large: "The PDF must be no larger than 10 MB.",
    pdf_page_limit_exceeded: "The PDF must contain no more than 10 pages.",
    encrypted_pdf_not_supported: "Password-protected PDFs are not supported.",
    malformed_pdf: "The selected PDF could not be opened. Check the file and try again.",
    pdf_response_not_enabled: "PDF attachments are not enabled for this task.",
    invalid_pdf_transcript: "The PDF's digital text could not be prepared safely. Try another PDF.",
    pdf_submission_in_progress: "This PDF submission is already being processed. Refresh your submissions before retrying.",
    pdf_submission_reservation_failed: "A submission place could not be reserved. Your work has not been accepted.",
    submission_not_found: "This submission is no longer available for PDF attachment.",
    submission_file_upload_unavailable: "The PDF could not be attached to this submission.",
    private_file_storage_unavailable: "Private file storage could not accept the PDF. Check your recent submissions before retrying.",
    private_file_acceptance_unavailable: "The PDF could not be confirmed as accepted. Check your recent submissions before retrying.",
  };
  return (code && messages[code]) || "The request could not be completed. Your typed response has not been changed.";
}

function validatePdf(file: File): string | null {
  if (!/\.pdf$/i.test(file.name)) return "Choose a PDF file. JPG and PNG files are not accepted.";
  if (file.type !== "application/pdf") return "Choose a file recognised by your device as a PDF.";
  if (file.size < 1 || file.size > maximumPdfBytes) return "The PDF must be between 1 byte and 10 MB.";
  return null;
}

export default function LearnerSubmissionPanel({ accessToken }: { accessToken: string }) {
  const [tasks, setTasks] = useState<LearnerAssessmentTask[]>([]);
  const [submissions, setSubmissions] = useState<LearnerSubmission[]>([]);
  const [selectedTaskId, setSelectedTaskId] = useState("");
  const [responseText, setResponseText] = useState("");
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [submissionMode, setSubmissionMode] = useState<"typed" | "typed_pdf" | "pdf_only">("typed");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [uploadingSubmissionId, setUploadingSubmissionId] = useState("");
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const refresh = useCallback(async () => {
    const response = await fetch("/api/v1/learner/submissions", {
      headers: { Authorization: "Bearer " + accessToken },
      cache: "no-store",
    });
    const result = await response.json() as LearnerSubmissionsResponse;
    if (!response.ok) {
      throw new Error(result.message || userFacingApiError(result.error));
    }
    const nextTasks = Array.isArray(result.available_tasks) ? result.available_tasks : [];
    setTasks(nextTasks);
    setSubmissions(Array.isArray(result.submissions) ? result.submissions : []);
    setSelectedTaskId(current => nextTasks.some(task => task.id === current)
      ? current
      : nextTasks[0]?.id ?? "");
  }, [accessToken]);

  useEffect(() => {
    let active = true;
    setLoading(true);
    void refresh()
      .catch(requestError => {
        if (active) setError(requestError instanceof Error ? requestError.message : "Assessment tasks could not be loaded.");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [refresh]);

  const selectedTask = tasks.find(task => task.id === selectedTaskId) ?? null;

  async function uploadPdf(submissionId: string, file: File): Promise<void> {
    const form = new FormData();
    form.append("file", file, file.name);
    const response = await fetch("/api/v1/learner/submissions/" + encodeURIComponent(submissionId) + "/file", {
      method: "POST",
      headers: { Authorization: "Bearer " + accessToken },
      body: form,
    });
    const result = await response.json() as { error?: string; file?: { upload_state: string } };
    if (!response.ok || result.file?.upload_state !== "accepted") {
      throw new Error(userFacingApiError(result.error));
    }
  }

  async function submitWrittenResponse(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedTask) return;
    const needsText = submissionMode !== "pdf_only";
    const needsPdf = submissionMode !== "typed";
    if (needsText && !responseText.trim()) return;
    if (needsPdf && !pdfFile) return;

    setSubmitting(true);
    setError("");
    setMessage("");

    try {
      if (submissionMode === "typed_pdf" || submissionMode === "pdf_only") {
        const file = pdfFile;
        if (!file) throw new Error("Choose a PDF file before submitting.");

        const transcript = await extractDigitalTextFromPdf(file);
        const form = new FormData();
        form.append("task_version_id", selectedTask.id);
        form.append("idempotency_key", crypto.randomUUID());
        form.append("response_mode", submissionMode);
        if (submissionMode === "typed_pdf") form.append("response_text", responseText.trim());
        form.append("transcript_pages", JSON.stringify(transcript.pages));
        form.append("file", file, file.name);

        const response = await fetch("/api/v1/learner/pdf-submissions", {
          method: "POST",
          headers: { Authorization: "Bearer " + accessToken },
          body: form,
        });
        const result = await response.json() as {
          submission?: { submission_id?: string; id?: string };
          transcript?: { no_text_layer_pages?: number[] };
          error?: string;
          message?: string;
        };
        if (!response.ok || !result.submission) {
          throw new Error(result.message || userFacingApiError(result.error));
        }

        const noTextPages = result.transcript?.no_text_layer_pages ?? transcript.no_text_layer_pages;
        setResponseText("");
        setPdfFile(null);
        setSubmissionMode("typed");
        setMessage(noTextPages.length > 0
          ? "Your PDF submission was accepted. No digital text was detected on page(s) " +
            noTextPages.join(", ") +
            "; those pages are clearly flagged for teacher review. No OCR or guessed text was used."
          : "Your PDF submission was accepted and its available digital text was saved page by page for review.");
        await refresh().catch(() => undefined);
        return;
      }

      const response = await fetch("/api/v1/learner/submissions", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          task_version_id: selectedTask.id,
          idempotency_key: crypto.randomUUID(),
          response_text: responseText.trim(),
        }),
      });
      const result = await response.json() as {
        submission?: { submission_id?: string };
        error?: string;
        message?: string;
      };
      const submissionId = result.submission?.submission_id;
      if (!response.ok || !submissionId) {
        throw new Error(result.message || userFacingApiError(result.error));
      }

      let uploadError = "";
      if (pdfFile) {
        try {
          await uploadPdf(submissionId, pdfFile);
        } catch (uploadRequestError) {
          uploadError = uploadRequestError instanceof Error
            ? uploadRequestError.message
            : "The PDF could not be attached. Your typed response remains submitted.";
        }
      }

      setResponseText("");
      setPdfFile(null);
      if (uploadError) {
        setMessage("Your typed response was submitted, but the PDF was not attached. " + uploadError);
      } else {
        setMessage(pdfFile
          ? "Your written response and optional PDF were submitted successfully."
          : "Your typed response was submitted successfully.");
      }
      await refresh().catch(() => undefined);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Your response could not be submitted.");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleNewPdfChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0] ?? null;
    if (!file) {
      setPdfFile(null);
      return;
    }
    const validation = validatePdf(file);
    if (validation) {
      event.currentTarget.value = "";
      setPdfFile(null);
      setError(validation);
      return;
    }
    setError("");
    setPdfFile(file);
  }

  async function handleExistingPdfChange(
    submissionId: string,
    event: ChangeEvent<HTMLInputElement>,
  ) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = "";
    if (!file) return;
    const validation = validatePdf(file);
    if (validation) {
      setError(validation);
      return;
    }
    setUploadingSubmissionId(submissionId);
    setError("");
    setMessage("");
    try {
      await uploadPdf(submissionId, file);
      await refresh();
      setMessage("PDF attached to your written response.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The PDF could not be attached.");
    } finally {
      setUploadingSubmissionId("");
    }
  }

  const wordCount = responseText.trim() ? responseText.trim().split(/\s+/).length : 0;

  return <section className="proto-account-submissions" aria-labelledby="proto-account-submissions-heading" data-testid="learner-submissions-panel">
    <div className="proto-account-submissions-heading">
      <div>
        <p className="proto-eyebrow"><span />LEARNER SUBMISSIONS</p>
        <h3 id="proto-account-submissions-heading">Submit an assessment response</h3>
      </div>
      <span className="proto-account-status">Text or PDF</span>
    </div>
    <p className="proto-account-submissions-intro">Choose an available assessment. Depending on the task, you can type your response, add a PDF, or submit a PDF on its own for eligible longer-response tasks.</p>

    {loading ? <p role="status">Loading your available assessments…</p> : tasks.length === 0
      ? <p className="proto-account-submissions-empty">No published assessment tasks are currently available for your active enrolments.</p>
      : <form className="proto-account-submission-form" onSubmit={submitWrittenResponse}>
        <label htmlFor="proto-learner-task">Assessment task
          <select id="proto-learner-task" value={selectedTaskId} onChange={event => {
            setSelectedTaskId(event.target.value);
            setPdfFile(null);
            setSubmissionMode("typed");
            setError("");
          }}>
            {tasks.map(task => <option key={task.id} value={task.id}>
              {task.title} · {pdfEligible(task) ? "Optional PDF available" : "Typed response only"}
            </option>)}
          </select>
        </label>
        {selectedTask && <p className={pdfEligible(selectedTask) ? "proto-account-submission-eligibility eligible" : "proto-account-submission-eligibility"}>
          {pdfEligible(selectedTask)
            ? "This task accepts typed responses, typed responses with a PDF, or a PDF-only response. The PDF limit is 10 MB and 10 pages."
            : "This task accepts typed responses only. PDF attachments are not enabled."}
        </p>}
        {selectedTask && pdfEligible(selectedTask) && <label htmlFor="proto-learner-response-mode">Response format
          <select id="proto-learner-response-mode" value={submissionMode} onChange={event => {
            setSubmissionMode(event.target.value as "typed" | "typed_pdf" | "pdf_only");
            setError("");
            setMessage("");
          }}>
            <option value="typed">Typed response</option>
            <option value="typed_pdf">Typed response and PDF</option>
            <option value="pdf_only">PDF only (no typing required)</option>
          </select>
        </label>}
        {submissionMode !== "pdf_only" && <label htmlFor="proto-learner-response">Written response
          <textarea id="proto-learner-response" rows={6} maxLength={12000} value={responseText}
            onChange={event => setResponseText(event.target.value)}
            placeholder="Write your response here…" required />
          <small>{wordCount} words · {responseText.length.toLocaleString()} of 12,000 characters</small>
        </label>}
        {pdfEligible(selectedTask) && <label htmlFor="proto-learner-pdf">
          {submissionMode === "typed" ? "Optional PDF attachment" : "Required PDF response"}
          <input id="proto-learner-pdf" type="file" accept=".pdf,application/pdf"
            onChange={handleNewPdfChange} disabled={submitting} />
          <small>PDF only · Maximum 10 MB and 10 pages · JPG and PNG are not accepted. Available digital text is extracted page by page. Pages with no extractable digital text are flagged for teacher review; no OCR is used.</small>
          {pdfFile && <small>Selected: {pdfFile.name} ({(pdfFile.size / (1024 * 1024)).toFixed(2)} MB)</small>}
        </label>}
        <button className="proto-action" type="submit"
          disabled={submitting || !selectedTask ||
            (submissionMode !== "pdf_only" && !responseText.trim()) ||
            (submissionMode !== "typed" && !pdfFile)}>
          {submitting ? "Submitting…" : submissionMode === "pdf_only" ? "Submit PDF response" : "Submit written response"}
        </button>
      </form>}

    {error && <p className="proto-account-submission-feedback error" role="alert">{error}</p>}
    {message && <p className="proto-account-submission-feedback" role="status">{message}</p>}

    <div className="proto-account-submission-list" aria-label="Your recent submissions">
      <h4>Your submissions</h4>
      {!loading && submissions.length === 0
        ? <p>No submissions yet.</p>
        : submissions.map(submission => {
          const task = taskForSubmission(submission);
          const canAttachPdf = pdfEligible(task) && submission.status === "queued" && submission.response_mode === "typed";
          return <article className="proto-account-submission-row" key={submission.id}
            data-testid={"learner-submission-" + submission.id}>
            <div className="proto-account-submission-main">
              <strong>{task?.title ?? "Assessment task"}</strong>
              <small>{new Date(submission.accepted_at).toLocaleString()} · {submission.status.replaceAll("_", " ")}</small>
              <span>{submission.response_mode === "pdf_only"
                ? "PDF-only response"
                : submission.response_mode === "typed_pdf"
                  ? "Typed response + PDF"
                  : "Typed response only"}</span>
            </div>
            {canAttachPdf && <label className="proto-account-submission-attach">
              {uploadingSubmissionId === submission.id ? "Attaching PDF…" : "Attach optional PDF"}
              <input type="file" accept=".pdf,application/pdf" aria-label="Attach optional PDF"
                onChange={event => void handleExistingPdfChange(submission.id, event)}
                disabled={Boolean(uploadingSubmissionId) || submitting} />
            </label>}
          </article>;
        })}
    </div>
  </section>;
}
