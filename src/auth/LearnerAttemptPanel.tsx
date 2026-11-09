import { useCallback, useEffect, useRef, useState } from "react";

interface TaskVersion {
  id: string;
  task_code: string;
  title: string;
  version: number;
  pathway_id: string;
  time_allowance_seconds: number | null;
  timer_policy_version: number;
  expected_min_words: number;
  ideal_words: number;
}

interface AttemptSummary {
  id: string;
  learner_id: string;
  task_version_id: string;
  status: "in_progress" | "submitted" | "withdrawn";
  started_at: string;
  submitted_at: string | null;
  task_versions: TaskVersion | TaskVersion[] | null;
}

interface TimerState {
  attempt_id: string;
  allowance_seconds: number | null;
  timer_policy_version: number;
  started_at: string;
  deadline_at: string | null;
  server_now: string;
  elapsed_seconds: number;
  remaining_seconds: number | null;
  is_expired: boolean;
  attempt_status: string;
  submitted_at: string | null;
}

interface AttemptDetail {
  attempt: AttemptSummary & {
    attempt_responses: Array<{
      id: string;
      prompt_id: string;
      response_text: string;
      word_count: number;
      version: number;
    }>;
    timer: TimerState;
  };
  prompts: Array<{ id: string; sequence: number; prompt_text: string }>;
}

interface AttemptListResponse {
  attempts: AttemptSummary[];
  available_tasks: TaskVersion[];
  error?: string;
  message?: string;
}

function taskFor(attempt: AttemptSummary): TaskVersion | null {
  return Array.isArray(attempt.task_versions)
    ? attempt.task_versions[0] ?? null
    : attempt.task_versions;
}

function formatClock(seconds: number): string {
  const bounded = Math.max(0, Math.floor(seconds));
  const minutes = Math.floor(bounded / 60);
  const remainder = bounded % 60;
  if (minutes >= 60) {
    return `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`;
  }
  return `${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`;
}

function formatAllowance(seconds: number | null): string {
  if (seconds === null) return "Untimed practice";
  if (seconds % 3600 === 0) return `${seconds / 3600} hour${seconds === 3600 ? "" : "s"}`;
  if (seconds % 60 === 0) return `${seconds / 60} minutes`;
  return `${seconds} seconds`;
}

export default function LearnerAttemptPanel({ accessToken }: { accessToken: string }) {
  const [attempts, setAttempts] = useState<AttemptSummary[]>([]);
  const [availableTasks, setAvailableTasks] = useState<TaskVersion[]>([]);
  const [detail, setDetail] = useState<AttemptDetail | null>(null);
  const [responseText, setResponseText] = useState("");
  const [liveRemainingSeconds, setLiveRemainingSeconds] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const timerSample = useRef<{ remaining: number | null; sampledAt: number }>({
    remaining: null,
    sampledAt: 0,
  });

  const refreshList = useCallback(async () => {
    const response = await fetch("/api/v1/learner/attempts", {
      headers: { Authorization: "Bearer " + accessToken },
      cache: "no-store",
    });
    const result = await response.json() as AttemptListResponse;
    if (!response.ok) throw new Error(result.message ?? result.error ?? "Practice tasks could not be loaded.");
    setAttempts(Array.isArray(result.attempts) ? result.attempts : []);
    setAvailableTasks(Array.isArray(result.available_tasks) ? result.available_tasks : []);
  }, [accessToken]);

  const loadAttempt = useCallback(async (attemptId: string) => {
    const response = await fetch("/api/v1/learner/attempts/" + encodeURIComponent(attemptId), {
      headers: { Authorization: "Bearer " + accessToken },
      cache: "no-store",
    });
    const result = await response.json() as AttemptDetail & { error?: string; message?: string };
    if (!response.ok || !result.attempt?.timer) {
      throw new Error(result.message ?? result.error ?? "The practice attempt could not be opened.");
    }
    setDetail(result);
    const saved = result.attempt.attempt_responses.find(item => item.prompt_id === result.prompts[0]?.id);
    setResponseText(saved?.response_text ?? "");
    const remaining = result.attempt.timer.remaining_seconds;
    timerSample.current = { remaining, sampledAt: performance.now() };
    setLiveRemainingSeconds(remaining);
    setMessage("");
  }, [accessToken]);

  useEffect(() => {
    let active = true;
    setLoading(true);
    void refreshList().catch(reason => {
      if (active) setError(reason instanceof Error ? reason.message : "Practice tasks could not be loaded.");
    }).finally(() => {
      if (active) setLoading(false);
    });
    return () => { active = false; };
  }, [refreshList]);

  useEffect(() => {
    const timer = detail?.attempt.timer;
    const attemptId = detail?.attempt.id;
    if (!timer || !attemptId || timer.remaining_seconds === null) return;

    const updateDisplay = () => {
      const sample = timerSample.current;
      if (sample.remaining === null) return;
      const passed = Math.floor((performance.now() - sample.sampledAt) / 1000);
      setLiveRemainingSeconds(Math.max(0, sample.remaining - passed));
    };
    const refreshFromServer = () => {
      if (document.visibilityState === "visible") {
        void loadAttempt(attemptId).catch(reason => {
          setError(reason instanceof Error ? reason.message : "The timer could not be refreshed.");
        });
      }
    };

    const interval = window.setInterval(updateDisplay, 250);
    document.addEventListener("visibilitychange", refreshFromServer);
    window.addEventListener("focus", refreshFromServer);
    return () => {
      window.clearInterval(interval);
      document.removeEventListener("visibilitychange", refreshFromServer);
      window.removeEventListener("focus", refreshFromServer);
    };
  }, [detail?.attempt.id, detail?.attempt.timer.started_at, detail?.attempt.timer.remaining_seconds, loadAttempt]);

  const startPractice = async (taskVersionId: string) => {
    setBusy(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/learner/attempts", {
        method: "POST",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ task_version_id: taskVersionId }),
      });
      const result = await response.json() as { attempt?: { id: string }; error?: string; message?: string };
      if (!response.ok || !result.attempt?.id) {
        throw new Error(result.message ?? result.error ?? "The practice attempt could not be started.");
      }
      await loadAttempt(result.attempt.id);
      await refreshList();
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "The practice attempt could not be started.");
    } finally {
      setBusy(false);
    }
  };

  const saveResponse = async () => {
    if (!detail || !responseText.trim()) return;
    const prompt = detail.prompts[0];
    if (!prompt) {
      setError("This task has no available prompt.");
      return;
    }
    setBusy(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch(
        "/api/v1/learner/attempts/" + encodeURIComponent(detail.attempt.id) +
        "/responses/" + encodeURIComponent(prompt.id),
        {
          method: "PUT",
          headers: {
            Authorization: "Bearer " + accessToken,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ response_text: responseText }),
        },
      );
      const result = await response.json() as { error?: string; message?: string };
      if (!response.ok) throw new Error(result.message ?? result.error ?? "The response could not be saved.");
      await loadAttempt(detail.attempt.id);
      setMessage("Response saved. The advisory countdown does not block saving.");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "The response could not be saved.");
    } finally {
      setBusy(false);
    }
  };

  const submitAttempt = async () => {
    if (!detail) return;
    setBusy(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch(
        "/api/v1/learner/attempts/" + encodeURIComponent(detail.attempt.id) + "/submit",
        {
          method: "POST",
          headers: {
            Authorization: "Bearer " + accessToken,
            "Content-Type": "application/json",
          },
          body: "{}",
        },
      );
      const result = await response.json() as { error?: string; message?: string };
      if (!response.ok) throw new Error(result.message ?? result.error ?? "The practice attempt could not be submitted.");
      await loadAttempt(detail.attempt.id);
      await refreshList();
      setMessage("Practice attempt submitted.");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "The practice attempt could not be submitted.");
    } finally {
      setBusy(false);
    }
  };

  const selectedTask = detail ? taskFor(detail.attempt) : null;
  const timer = detail?.attempt.timer ?? null;
  const timeReachedZero = timer?.is_expired === true || liveRemainingSeconds === 0;
  const editable = detail?.attempt.status === "in_progress";

  return (
    <section className="proto-account-attempts" data-testid="learner-attempt-panel">
      <div className="proto-account-attempts-heading">
        <div>
          <p className="proto-eyebrow"><span />PRACTICE</p>
          <h3>Timed and untimed practice</h3>
        </div>
        <span className="proto-account-status">Server timed</span>
      </div>
      <p className="proto-account-attempts-intro">
        The countdown is advisory. It continues through refreshes and background tabs, but reaching zero never submits your work or prevents saving and submitting.
      </p>

      {loading ? <p role="status">Loading practice tasks…</p> : availableTasks.length ? (
        <div className="proto-account-attempt-task-list" aria-label="Available practice tasks">
          {availableTasks.map(task => (
            <article className="proto-account-attempt-task" key={task.id} data-testid={"practice-task-" + task.id}>
              <div>
                <small>Task version {task.version}</small>
                <h4>{task.title}</h4>
                <span>{formatAllowance(task.time_allowance_seconds)}</span>
              </div>
              <button className="proto-action" type="button" onClick={() => void startPractice(task.id)} disabled={busy}>
                Start practice
              </button>
            </article>
          ))}
        </div>
      ) : <p className="proto-account-attempts-empty">No released practice tasks are available in your active learning pathways yet.</p>}

      {attempts.some(item => item.status === "in_progress") && (
        <div className="proto-account-attempt-resume">
          <h4>Your in-progress practice</h4>
          {attempts.filter(item => item.status === "in_progress").map(item => (
            <div className="proto-account-attempt-resume-row" key={item.id}>
              <span>{taskFor(item)?.title ?? "Practice task"}</span>
              <button className="proto-account-toggle" type="button" disabled={busy} onClick={() => {
                setError("");
                void loadAttempt(item.id).catch(reason => setError(reason instanceof Error ? reason.message : "The attempt could not be reopened."));
              }}>Resume</button>
            </div>
          ))}
        </div>
      )}

      {detail && (
        <div className="proto-account-attempt-workspace">
          <div className="proto-account-attempt-workspace-heading">
            <div>
              <small>ACTIVE PRACTICE</small>
              <h4>{selectedTask?.title ?? "Practice task"}</h4>
            </div>
            {timer?.allowance_seconds === null
              ? <span className="proto-account-status">Untimed</span>
              : <div className="proto-attempt-clock" aria-label="Advisory countdown">
                  <small>TIME REMAINING · ADVISORY</small>
                  <strong data-testid="attempt-countdown">{formatClock(liveRemainingSeconds ?? timer?.remaining_seconds ?? 0)}</strong>
                </div>}
          </div>
          {timer?.allowance_seconds !== null && timeReachedZero && editable && (
            <p className="proto-attempt-expiry-note" role="status">
              The suggested time has ended. Your response is still available to save and submit.
            </p>
          )}
          {detail.prompts.map(prompt => (
            <div className="proto-account-attempt-prompt" key={prompt.id}>
              <small>QUESTION {prompt.sequence}</small>
              <p>{prompt.prompt_text}</p>
            </div>
          ))}
          <label className="proto-account-attempt-response">
            Your response
            <textarea
              value={responseText}
              onChange={event => setResponseText(event.target.value)}
              disabled={!editable || busy}
              maxLength={12000}
              rows={7}
            />
          </label>
          <div className="proto-account-attempt-actions">
            <button className="proto-action" type="button" onClick={() => void saveResponse()}
              disabled={!editable || busy || !responseText.trim()}>
              Save response
            </button>
            <button className="proto-action secondary" type="button" onClick={() => void submitAttempt()}
              disabled={!editable || busy || !responseText.trim()}>
              Submit practice
            </button>
          </div>
          {!editable && <p className="proto-account-attempts-intro">This attempt has been submitted. Its saved response is read-only.</p>}
        </div>
      )}

      {error && <p className="proto-account-feedback error" role="alert">{error}</p>}
      {message && <p className="proto-account-feedback success" role="status">{message}</p>}
    </section>
  );
}
