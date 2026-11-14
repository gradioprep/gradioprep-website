import { useEffect, useState } from "react";
import PaAnalyticalWritingTask, { isPaAnalyticalWritingResponse } from "./PaAnalyticalWritingTask";
import PaCreativeWritingTask, { emptyCreativeWritingResponse, isPaCreativeWritingResponse, type PaCreativeWritingResponse } from "./PaCreativeWritingTask";
import PaSpeakingOutlineTask, { emptySpeakingOutline, isPaSpeakingOutline, type PaSpeakingOutline } from "./PaSpeakingOutlineTask";
import PaContextualExplanationField, { paChoiceResponse } from "./PaContextualChoiceTask";

type ResponseValue = {
  a?: string;
  b?: string[];
  text?: string;
  choice?: string;
  order?: string[];
  explanation?: string;
  plan?: string;
  initial_draft?: string;
  final_text?: string;
  revision_before?: string;
  revision_after?: string;
  revision_note?: string;
  title?: string;
  opening?: string;
  development?: string;
  consideration?: string;
  closing?: string;
};

type DiagnosticResponseMap = Record<string, ResponseValue>;

interface StartedDiagnostic {
  diagnostic: { diagnostic_code: string; title: string; version: number; total_minutes: number; sitting_count: number };
  attempt: { id: string; status: "in_progress" | "submitted" | "withdrawn"; is_replay: boolean };
  responses: Record<string, { response: ResponseValue; revision_number: number }>;
  section_status: string;
  available_observation_codes: string[];
  available_sittings: Array<{ observation_code: string; sitting_number: number }>;
}

const stimulusA = [
  "When the hall doors opened, the folding table was already crowded with objects that had stopped working: a lamp with a stubborn switch, a clock that lost five minutes every hour, and a blue bicycle with a loose bell. Nia had come to help, but she kept looking at the pile of things waiting on the floor.",
  "“We can repair all of them,” she said.",
  "Mr Sen, who ran the weekly repair afternoon, did not answer at once. He checked the lamp’s label, then set it aside. “Not safely today,” he said. “We need the right part and someone qualified to fit it.”",
  "Nia frowned. The clock, however, was simple: its loose back had let the battery slide out of place. She held the torch while Mr Sen fitted the cover. The hands began moving again, first with a small jump, then steadily.",
  "At the far end of the table, a child rang the bicycle bell. Its bright note crossed the hall and made two waiting people laugh. Nia looked back at the lamp. It was still broken, but it no longer seemed like proof that the afternoon had failed.",
  "On a card, she wrote: “Fixed today: one clock, one bell. Next time: the lamp.” Then she placed the card beside the waiting pile, where everyone could see what had happened—and what had not.",
];

const stimulusB = [
  "Bring one small household object to the community hall. You do not need to know how to repair it: volunteers will explain what can be checked safely.",
  "The chart shows the outcome for every object checked. “Waiting for parts” means the team has not yet completed the repair. “Not safe to repair” means the object needs a different service or should not be handled at this event.",
  "You can watch, ask questions or help with a simple task chosen by a volunteer. The team will not promise that every object can be fixed.",
];

const sequenceEvents = [
  "Nia writes a card recording what was fixed and what remains for another time.",
  "Nia arrives and sees objects waiting on the floor.",
  "Mr Sen sets the lamp aside because it cannot safely be repaired at the event.",
  "The clock is repaired.",
  "The bicycle bell rings and makes people laugh.",
];

const textOptions = (values: string[]) => values.map((value, index) => ({ value: String.fromCharCode(65 + index), label: value }));

function ChoiceField({
  legend, value, onChange, options, name, multiple = false, disabled = false,
}: {
  legend: string;
  value: string | string[];
  onChange: (next: string | string[]) => void;
  options: Array<{ value: string; label: string }>;
  name: string;
  multiple?: boolean;
  disabled?: boolean;
}) {
  return <fieldset className="proto-diagnostic-fieldset">
    <legend>{legend}</legend>
    <div className="proto-diagnostic-options">
      {options.map(option => {
        const checked = multiple
          ? (value as string[]).includes(option.value)
          : value === option.value;
        return <label className="proto-diagnostic-option" key={option.value}>
          <input
            type={multiple ? "checkbox" : "radio"}
            name={name}
            disabled={disabled}
            value={option.value}
            checked={checked}
            onChange={event => {
              if (!multiple) onChange(option.value);
              else {
                const current = value as string[];
                onChange(event.target.checked
                  ? [...current, option.value]
                  : current.filter(item => item !== option.value));
              }
            }}
          />
          <span><strong>{option.value}.</strong> {option.label}</span>
        </label>;
      })}
    </div>
  </fieldset>;
}

function TextField({
  label, guidance, value, onChange, disabled = false,
}: {
  label: string;
  guidance?: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}) {
  const count = value.trim() ? value.trim().split(/\s+/u).length : 0;
  const target = guidance?.match(/Ideal target:\s*(\d+)\s*words/i)?.[1];
  return <label className="proto-diagnostic-text-field">
    <span>{label}</span>
    {guidance && <small>{guidance}</small>}
    <textarea rows={4} maxLength={12000} value={value} onChange={event => onChange(event.target.value)} disabled={disabled} />
    <small className="proto-diagnostic-word-count" aria-live="polite" aria-atomic="true">
      {count} / {target ?? "—"} words
    </small>
  </label>;
}

export default function DiagnosticPanel({
  accessToken,
  onEvaluationReportReady,
  onOpenEvaluationReport,
}: {
  accessToken: string;
  onEvaluationReportReady: (reportRecordId: string) => void;
  onOpenEvaluationReport: () => void;
}) {
  const [attemptId, setAttemptId] = useState("");
  const [attemptStatus, setAttemptStatus] = useState<"not_started" | "in_progress" | "submitted">("not_started");
  const [responses, setResponses] = useState<DiagnosticResponseMap>({});
  const [instrument, setInstrument] = useState({ code: "", version: 0 });
  const [availableCodes, setAvailableCodes] = useState<string[]>([]);
  const [availableSittings, setAvailableSittings] = useState<Record<string, number>>({});
  const [sittingSessions, setSittingSessions] = useState<Array<{
    sitting_number: number; started_at: string; completed_at: string | null;
    duration_seconds: number; extra_seconds: number; untimed: boolean; remaining_seconds: number | null;
  }>>([]);
  const [activeSitting, setActiveSitting] = useState(0);
  const [clockTick, setClockTick] = useState(0);
  useEffect(() => {
    const interval = window.setInterval(() => setClockTick(value => value + 1), 1000);
    return () => window.clearInterval(interval);
  }, []);
  const [creativeDraft, setCreativeDraft] = useState<PaCreativeWritingResponse>(emptyCreativeWritingResponse);
  const [speakingOutline, setSpeakingOutline] = useState<PaSpeakingOutline>(emptySpeakingOutline);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [reportRecordId, setReportRecordId] = useState("");
  const [reportError, setReportError] = useState("");
  const [reportLoading, setReportLoading] = useState(false);
  const [reportIdempotencyKeys, setReportIdempotencyKeys] = useState<Record<string, string>>({});

  const update = (code: string, key: keyof ResponseValue, value: string | string[]) => {
    setResponses(current => ({
      ...current,
      [code]: { ...(current[code] ?? {}), [key]: value },
    }));
  };

  const current = (code: string): ResponseValue => responses[code] ?? {};
  const nonEmpty = (value?: string) => typeof value === "string" && value.trim().length >= 5;

  function payloads(): Array<{ code: string; response: ResponseValue }> {
    const output: Array<{ code: string; response: ResponseValue }> = [];
    const rv01 = current("RV01");
    if (rv01.a && ["A", "B", "C", "D"].includes(rv01.a) &&
        Array.isArray(rv01.b) && rv01.b.length === 2 && new Set(rv01.b).size === 2) {
      output.push({ code: "RV01", response: { a: rv01.a, b: rv01.b } });
    }
    for (const code of ["RV02", "RV03", "RV06", "RV07a", "RV07b"]) {
      if (nonEmpty(current(code).text)) output.push({ code, response: { text: current(code).text } });
    }
    for (const code of ["RV04", "RV05", "LC01", "LC02", "LC03", "LC04"]) {
      const response = paChoiceResponse(instrument.code, instrument.version, code,
        current(code).choice, current(code).explanation);
      if (response) output.push({ code, response });
    }
    const rv08 = current("RV08");
    if (Array.isArray(rv08.order) && rv08.order.length === 5 &&
        new Set(rv08.order).size === 5 && rv08.order.every(value => ["1", "2", "3", "4", "5"].includes(value)) &&
        nonEmpty(rv08.explanation)) {
      output.push({ code: "RV08", response: { order: rv08.order, explanation: rv08.explanation } });
    }
    const rv09 = current("RV09");
    if (rv09.choice && ["A", "B", "C", "D"].includes(rv09.choice) && nonEmpty(rv09.explanation)) {
      output.push({ code: "RV09", response: { choice: rv09.choice, explanation: rv09.explanation } });
    }
    const lc05 = current("LC05");
    if (nonEmpty(lc05.text)) output.push({ code: "LC05", response: { text: lc05.text } });
    // AW02–AW05 are evaluation dimensions of AW01, not extra learner responses.
    if (availableCodes.includes("AW01") && isPaAnalyticalWritingResponse(current("AW01").text ?? "")) {
      output.push({ code: "AW01", response: { text: current("AW01").text } });
    }
    // CW01–CW05 are dimensions of one completed plan/draft/revision performance.
    if (availableCodes.includes("CW01") && isPaCreativeWritingResponse(creativeDraft)) {
      output.push({ code: "CW01", response: { ...creativeDraft } });
    }
    // The card is SP01 preparation evidence only. SP02–SP05 require observed speech.
    if (availableCodes.includes("SP01") && isPaSpeakingOutline(speakingOutline)) {
      output.push({ code: "SP01", response: { ...speakingOutline } });
    }
    return output;
  }

  const twoSitting = Object.values(availableSittings).includes(2);
  const currentSittingCodes = (codes: string[], sitting: number) =>
    codes.filter(code => availableSittings[code] === sitting);
  const pendingForSitting = (sitting: number) =>
    currentSittingCodes(requiredCodes, sitting).every(code => savedCodes.includes(code));
  const session = sittingSessions.find(s => s.sitting_number === activeSitting);
  const secondsLeft = session && !session.untimed
    ? Math.max(0, Math.ceil((new Date(session.started_at).getTime()
      + (session.duration_seconds + session.extra_seconds) * 1000 - Date.now()) / 1000))
    : null;
  void clockTick;
  const sittingExpired = twoSitting && !!session && secondsLeft === 0;
  const finishedSittings = sittingSessions.filter(s => s.completed_at !== null).map(s => s.sitting_number);
  const savedCodes = payloads().map(item => item.code);
  const requiredCodes = ["RV01", "RV02", "RV03", "RV04", "RV05", "RV06", "RV07a", "RV07b", "RV08", "RV09", "LC01", "LC02", "LC03", "LC04", "LC05",
    ...(availableCodes.includes("AW01") ? ["AW01"] : []),
    ...(availableCodes.includes("CW01") ? ["CW01"] : []),
    ...(availableCodes.includes("SP01") ? ["SP01"] : [])];
  const complete = requiredCodes.every(code => savedCodes.includes(code));

  function reportIdempotencyKeyFor(targetAttemptId: string): string {
    const cached = reportIdempotencyKeys[targetAttemptId];
    if (cached) return cached;

    const storageKey = "gradioprep.evaluation-report.idempotency:" + targetAttemptId;
    let key = "";
    try {
      key = window.localStorage.getItem(storageKey) ?? "";
    } catch {
      // Continue with an in-memory key when browser storage is unavailable.
    }
    if (!key) {
      key = crypto.randomUUID();
      try {
        window.localStorage.setItem(storageKey, key);
      } catch {
        // The component state below keeps retries idempotent during this visit.
      }
    }
    setReportIdempotencyKeys(current => ({ ...current, [targetAttemptId]: key }));
    return key;
  }

  async function prepareEvaluationReport(targetAttemptId: string): Promise<void> {
    setReportLoading(true);
    setReportError("");
    try {
      const response = await fetch(
        "/api/v1/learner/diagnostic-attempts/" + targetAttemptId + "/evaluation-report",
        {
          method: "POST",
          headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
          body: JSON.stringify({ idempotency_key: reportIdempotencyKeyFor(targetAttemptId) }),
        },
      );
      const result = await response.json() as {
        report?: { report_record_id: string };
        error?: string;
      };
      if (!response.ok || !result.report?.report_record_id) {
        throw new Error("The Evaluation Report could not be prepared.");
      }
      setReportRecordId(result.report.report_record_id);
      onEvaluationReportReady(result.report.report_record_id);
      setMessage("Your Evaluation Report is ready to view.");
    } catch {
      setReportError(
        "Your Preliminary Assessment was submitted, but your Evaluation Report could not be prepared. You can try again here.",
      );
    } finally {
      setReportLoading(false);
    }
  }

  async function startOrResume() {
    setLoading(true);
    setError("");
    setMessage("");
    try {
      const response = await fetch("/api/v1/learner/diagnostics/ib-myp-g9-cycle1/start", {
        method: "POST",
        headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
        body: JSON.stringify({ idempotency_key: crypto.randomUUID() }),
      });
      const result = await response.json() as StartedDiagnostic & { error?: string };
      if (!response.ok || !result.attempt?.id) throw new Error(result.error ?? "The Preliminary Assessment could not be opened.");
      setAttemptId(result.attempt.id);
      setInstrument({ code: result.diagnostic?.diagnostic_code ?? "", version: result.diagnostic?.version ?? 0 });
      setAttemptStatus(result.attempt.status === "submitted" ? "submitted" : "in_progress");
      const restored: DiagnosticResponseMap = {};
      for (const [code, value] of Object.entries(result.responses ?? {})) {
        restored[code] = value.response ?? {};
      }
      setResponses(restored);
      const savedCreative = restored.CW01;
      setCreativeDraft(savedCreative
        ? {
            plan: savedCreative.plan ?? "",
            initial_draft: savedCreative.initial_draft ?? "",
            final_text: savedCreative.final_text ?? "",
            revision_before: savedCreative.revision_before ?? "",
            revision_after: savedCreative.revision_after ?? "",
            revision_note: savedCreative.revision_note ?? "",
          }
        : { ...emptyCreativeWritingResponse });
      const savedSpeaking = restored.SP01;
      setSpeakingOutline(savedSpeaking ? {
        title: savedSpeaking.title ?? "",
        opening: savedSpeaking.opening ?? "",
        development: savedSpeaking.development ?? "",
        consideration: savedSpeaking.consideration ?? "",
        closing: savedSpeaking.closing ?? "",
      } : { ...emptySpeakingOutline });
      setAvailableSittings(Object.fromEntries(
        (result.available_sittings ?? []).filter(item =>
          typeof item.observation_code === "string" && [1,2].includes(item.sitting_number))
          .map(item => [item.observation_code,item.sitting_number]),
      ));
      const statesResponse = await fetch(
        "/api/v1/learner/diagnostic-attempts/" + result.attempt.id + "/sittings",
        { headers: { Authorization: "Bearer " + accessToken } },
      );
      if (!statesResponse.ok) throw new Error("Your sitting schedule could not be loaded.");
      const states = await statesResponse.json() as { sittings: typeof sittingSessions };
      setSittingSessions(states.sittings ?? []);
      const current = (states.sittings ?? []).find(item => !item.completed_at);
      setActiveSitting(current?.sitting_number ?? 0);
      setAvailableCodes(Array.isArray(result.available_observation_codes)
        ? result.available_observation_codes.filter((code): code is string => typeof code === "string")
        : []);
      if (result.attempt.status === "submitted") {
        setMessage("Your submitted Preliminary Assessment responses are read-only.");
        await prepareEvaluationReport(result.attempt.id);
      } else {
        setMessage(result.attempt.is_replay
          ? "Your saved Preliminary Assessment section has been restored."
          : "Your Preliminary Assessment section has started.");
      }
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The Preliminary Assessment could not be opened.");
    } finally {
      setLoading(false);
    }
  }

  async function sittingAction(sitting: number, action: "start" | "complete") {
    if (!attemptId) return;
    setLoading(true); setError(""); setMessage("");
    try {
      if (action === "complete" && !sittingExpired) {
        if (!(await saveAll())) return;
      }
      const response = await fetch(
        "/api/v1/learner/diagnostic-attempts/" + attemptId + "/sittings/" + sitting + "/" + action,
        { method: "POST", headers: { Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json" }, body: "{}" },
      );
      const body = await response.json() as { error?: string; sittings?: typeof sittingSessions };
      if (!response.ok) throw new Error(body.error ?? "This sitting could not be updated.");
      const refreshed = await fetch("/api/v1/learner/diagnostic-attempts/" + attemptId + "/sittings",
        { headers: { Authorization: "Bearer " + accessToken } });
      if (!refreshed.ok) throw new Error("Your sitting schedule could not be refreshed.");
      const status = await refreshed.json() as { sittings: typeof sittingSessions };
      setSittingSessions(status.sittings ?? []);
      setActiveSitting(action === "start" ? sitting : 0);
      setMessage(action === "start" ? "Your assessment sitting is ready."
        : "This sitting is complete. Your saved responses cannot be changed.");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Your sitting could not be updated.");
    } finally { setLoading(false); }
  }

  async function saveAll(): Promise<boolean> {
    if (!attemptId) return false;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      for (const item of payloads().filter(item => !twoSitting ||
        availableSittings[item.code] === activeSitting)) {
        const response = await fetch(
          "/api/v1/learner/diagnostic-attempts/" + attemptId + "/responses/" + item.code,
          {
            method: "PUT",
            headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
            body: JSON.stringify({ response: item.response }),
          },
        );
        const result = await response.json() as { error?: string };
        if (!response.ok) throw new Error(result.error ?? "A response could not be saved.");
      }
      setMessage("Your completed answers have been saved.");
      return true;
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Your responses could not be saved.");
      return false;
    } finally {
      setSaving(false);
    }
  }

  async function submitDiagnostic() {
    if (!complete || !attemptId || (twoSitting && finishedSittings.length !== 2)) return;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      for (const item of payloads().filter(() => !twoSitting)) {
        const response = await fetch(
          "/api/v1/learner/diagnostic-attempts/" + attemptId + "/responses/" + item.code,
          {
            method: "PUT",
            headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
            body: JSON.stringify({ response: item.response }),
          },
        );
        if (!response.ok) {
          const result = await response.json() as { error?: string };
          throw new Error(result.error ?? "A response could not be saved.");
        }
      }
      const submitted = await fetch(
        "/api/v1/learner/diagnostic-attempts/" + attemptId + "/submit",
        {
          method: "POST",
          headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
          body: "{}",
        },
      );
      const result = await submitted.json() as { attempt?: { status: string }; error?: string };
      if (!submitted.ok || result.attempt?.status !== "submitted") {
        throw new Error(result.error ?? "The Preliminary Assessment could not be submitted.");
      }
      setAttemptStatus("submitted");
      setMessage("Your Preliminary Assessment responses have been submitted and are now read-only.");
      await prepareEvaluationReport(attemptId);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The Preliminary Assessment could not be submitted.");
    } finally {
      setSaving(false);
    }
  }

  const readOnly = attemptStatus === "submitted";
  const buttonDisabled = loading || saving || readOnly || sittingExpired;

  return <section className="proto-panel proto-diagnostic" aria-labelledby="proto-diagnostic-heading">
    <div className="proto-panel-heading proto-diagnostic-heading">
      <div>
        <p className="proto-eyebrow"><span />IB MYP YEAR 4 · GRADE 9</p>
        <h2 id="proto-diagnostic-heading">Preliminary Assessment</h2>
        <p>Reading comprehension and language use</p>
      </div>
      <span className="proto-account-status">{attemptStatus === "submitted" ? "Submitted" : attemptStatus === "in_progress" ? "In progress" : "Not started"}</span>
    </div>

    {attemptStatus === "not_started" ? <div className="proto-diagnostic-intro">
      <p>This section explores how you interpret texts, use evidence and make language choices. Start or continue your saved attempt.</p>
      <p>Your responses are saved with your assessment. Your Evaluation Report will be available after the assessment is complete.</p>
      <button className="proto-action" type="button" onClick={() => void startOrResume()} disabled={loading}>
        {loading ? "Opening assessment…" : "Start / continue Preliminary Assessment"}
      </button>
    </div> : <>
      <div className="proto-diagnostic-notice" role="note">
        <strong>{readOnly ? "Current section submitted" : "Reading and language tasks"}</strong>
        <span>{readOnly
          ? "Your submitted responses are displayed without scores or marking feedback."
          : "Your responses are saved when you choose Save progress. Submit when you have completed this section."}</span>
      </div>

      {twoSitting && <section className="proto-diagnostic-notice" aria-label="Assessment sitting schedule">
        <strong>Two assessment sittings</strong>
        <p>Sitting 1: 35 minutes · Sitting 2: 45 minutes. Complete Sitting 1 before starting Sitting 2.</p>
        {session && <p role="timer" aria-live="off">Sitting {activeSitting}: {
          session.untimed ? "Untimed arrangement" :
          Math.floor((secondsLeft ?? 0) / 60) + ":" + String((secondsLeft ?? 0) % 60).padStart(2,"0")
        } remaining</p>}
        {sittingExpired && <p role="alert">This sitting's time has ended. You can finish it after reviewing saved answers, but no further changes can be saved.</p>}
        {!readOnly && activeSitting === 0 && !finishedSittings.includes(1) &&
          <button className="proto-action" type="button" disabled={loading}
            onClick={() => void sittingAction(1,"start")}>Start Sitting 1</button>}
        {!readOnly && activeSitting === 0 && finishedSittings.includes(1) && !finishedSittings.includes(2) &&
          <button className="proto-action" type="button" disabled={loading}
            onClick={() => void sittingAction(2,"start")}>Start Sitting 2</button>}
      </section>}
      {(!twoSitting || readOnly || activeSitting === 1) && <>
      <div className="proto-diagnostic-stimulus">
        <h3>Stimulus A · The Repair Table</h3>
        {stimulusA.map((paragraph, index) => <p key={index}>{paragraph}</p>)}
      </div>

      <div className="proto-diagnostic-stimulus proto-diagnostic-poster">
        <p className="proto-diagnostic-poster-brand">NORTHBANK LIBRARY</p>
        <h3>Fix-It Afternoon</h3>
        <p className="proto-diagnostic-tagline">Small repairs. Shared skills.</p>
        {stimulusB.map((paragraph, index) => <p key={index}>{paragraph}</p>)}
        <figure className="proto-diagnostic-chart" aria-labelledby="proto-diagnostic-chart-caption">
          <div className="proto-diagnostic-chart-row">
            <span>Repaired on the day</span><strong>31</strong><div className="proto-diagnostic-bar"><span style={{ width: "64.6%" }} /></div>
          </div>
          <div className="proto-diagnostic-chart-row">
            <span>Waiting for parts</span><strong>9</strong><div className="proto-diagnostic-bar"><span style={{ width: "18.75%" }} /></div>
          </div>
          <div className="proto-diagnostic-chart-row">
            <span>Not safe to repair here</span><strong>8</strong><div className="proto-diagnostic-bar"><span style={{ width: "16.67%" }} /></div>
          </div>
          <figcaption id="proto-diagnostic-chart-caption">This month’s record · 48 objects checked. The three categories account for all 48 objects.</figcaption>
        </figure>
        <p>You can watch, ask questions or help with a simple task chosen by a volunteer. The team will not promise that every object can be fixed.</p>
        <p className="proto-diagnostic-accessible">Accessible chart text: 31 objects were repaired that day, 9 were waiting for parts and 8 were not safe to repair at this event.</p>
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV01 · Main idea and explicit detail</h3>
        <ChoiceField
          legend="RV01a. Which statement best expresses the central idea of Stimulus A?"
          name="rv01a"
          disabled={readOnly}
          value={current("RV01").a ?? ""}
          onChange={value => update("RV01", "a", value as string)}
          options={textOptions([
            "The group proves that careful planning makes every object repairable.",
            "Nia learns that a useful repair afternoon can include honest limits and small successes.",
            "Mr Sen discourages visitors from asking questions about repairs.",
            "The bicycle bell is the main reason visitors attend the event.",
          ])}
        />
        <ChoiceField
          legend="RV01b. Select two details from Stimulus A that show that some work could not be completed that afternoon."
          name="rv01b"
          disabled={readOnly}
          multiple
          value={current("RV01").b ?? []}
          onChange={value => update("RV01", "b", value as string[])}
          options={textOptions([
            "Mr Sen sets the lamp aside because the right part and a qualified person are needed.",
            "The clock begins moving after Mr Sen fits its cover.",
            "Nia writes “Next time: the lamp” on the card.",
            "A child rings the bicycle bell.",
          ])}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV02 · Inference and interpretation</h3>
        <p>Why does Nia place the card beside the waiting pile at the end of Stimulus A? Explain what this action suggests about how her view of the afternoon has changed.</p>
        <TextField label="Your response" guidance="Response guidance: 35–45 words. Ideal target: 40 words; this is guidance, not a limit." value={current("RV02").text ?? ""} onChange={value => update("RV02", "text", value)}  disabled={readOnly} />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV03 · Creator’s choice</h3>
        <p>Explain how the phrase “Its bright note crossed the hall” shapes the atmosphere at that moment and contributes to the reader’s understanding of Nia’s response.</p>
        <TextField label="Your response" guidance="Response guidance: 35–50 words. Ideal target: 45 words; this is guidance, not a limit." value={current("RV03").text ?? ""} onChange={value => update("RV03", "text", value)}  disabled={readOnly} />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV04 · Context, audience and purpose</h3>
        <ChoiceField
          legend="Who is the most likely audience for Stimulus B, and what is the poster mainly designed to do?"
          name="rv04"
          disabled={readOnly}
          value={current("RV04").choice ?? ""}
          onChange={value => update("RV04", "choice", value as string)}
          options={textOptions([
            "Local residents who may bring an object; invite participation while explaining the event’s results and safety limits.",
            "Professional technicians; provide a detailed training manual for replacing parts.",
            "Children attending a music performance; advertise a concert.",
            "Collectors; prove that every household object can be repaired.",
          ])}
        />
        <PaContextualExplanationField
          instrumentCode={instrument.code}
          instrumentVersion={instrument.version}
          code="RV04"
          value={current("RV04").explanation ?? ""}
          onChange={value => update("RV04", "explanation", value)}
          disabled={readOnly}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV05 · Visual and verbal interpretation</h3>
        <ChoiceField
          legend="Which statement accurately interprets the outcome graphic in Stimulus B?"
          name="rv05"
          disabled={readOnly}
          value={current("RV05").choice ?? ""}
          onChange={value => update("RV05", "choice", value as string)}
          options={textOptions([
            "31 objects were repaired that day; 17 were not completed that day because 9 were waiting for parts and 8 were not safe to repair at this event.",
            "31 objects were waiting for parts; 17 were repaired that day.",
            "All 48 objects were repaired that day.",
            "Only 8 objects were checked.",
          ])}
        />
        <PaContextualExplanationField
          instrumentCode={instrument.code}
          instrumentVersion={instrument.version}
          code="RV05"
          value={current("RV05").explanation ?? ""}
          onChange={value => update("RV05", "explanation", value)}
          disabled={readOnly}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>{instrument.code === "ib-myp-g9-cycle1" && instrument.version >= 2
          ? "RV06 · Analysing a represented claim" : "RV06 · Critical perspective and representation"}</h3>
        {instrument.code === "ib-myp-g9-cycle1" && instrument.version >= 2
          ? <p>The poster says “Small repairs. Shared skills.” Analyse how its wording and outcome figures together present the event's achievements and limits. Support your interpretation with a figure and explain how a wording choice shapes the reader's understanding.</p>
          : <p>A volunteer says: “The team fixed almost every object on the day.” Is that a fair description of the poster’s results? Use at least one figure from the graphic and explain one limitation in the statement.</p>}
        <TextField label="Your response" guidance="Response guidance: 35–45 words. Ideal target: 40 words; this is guidance, not a limit." value={current("RV06").text ?? ""} onChange={value => update("RV06", "text", value)} disabled={readOnly}  />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV07a · Compare perspectives</h3>
        <p>How do Nia in Stimulus A and the poster in Stimulus B present what counts as a successful repair afternoon? Use relevant evidence from both stimuli.</p>
        <TextField label="Your response" guidance="Response guidance: 45–60 words. Ideal target: 50 words; this is guidance, not a limit." value={current("RV07a").text ?? ""} onChange={value => update("RV07a", "text", value)}  disabled={readOnly} />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV07b · Compare form, structure and creator choices</h3>
        <p>How do the story’s sequence and the poster’s visual categories guide the reader in different ways? Refer to one specific choice in each stimulus.</p>
        <TextField label="Your response" guidance="Response guidance: 45–60 words. Ideal target: 50 words; this is guidance, not a limit." value={current("RV07b").text ?? ""} onChange={value => update("RV07b", "text", value)} disabled={readOnly}  />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV08 · Sequence and structural development</h3>
        <p>Number these events from 1 to 5 in the order they occur in Stimulus A.</p>
        <div className="proto-diagnostic-sequence">
          {[1, 2, 3, 4, 5].map((position, index) => <label key={position}>
            <span>Event in position {position}</span>
            <select
              value={current("RV08").order?.[index] ?? ""}
              onChange={e => {
                const next = [...(current("RV08").order ?? ["", "", "", "", ""])];
                next[index] = e.target.value;
                update("RV08", "order", next);
              }}
              disabled={readOnly}
              aria-label={"Event in position " + position}
            >
              <option value="">Choose an event</option>
              {sequenceEvents.map((event, eventIndex) => <option key={eventIndex} value={String(eventIndex + 1)}>{event}</option>)}
            </select>
          </label>)}
        </div>
        <TextField label="Then explain in one sentence how this sequence helps the reader understand the change in Nia’s view." guidance="Response guidance: 15–25 words. Ideal target: 20 words; this is guidance, not a limit." value={current("RV08").explanation ?? ""} onChange={value => update("RV08", "explanation", value)}  disabled={readOnly} />
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV09 · Evidence selection and reasoning</h3>
        <ChoiceField
          legend="Which part of Stimulus B is the strongest evidence for the claim that the poster reports both completed and unfinished outcomes?"
          name="rv09"
          disabled={readOnly}
          value={current("RV09").choice ?? ""}
          onChange={value => update("RV09", "choice", value as string)}
          options={textOptions([
            "“Small repairs. Shared skills.”",
            "“31 repaired on the day; 9 waiting for parts; 8 not safe to repair at this event.”",
            "“Bring one small household object to the community hall.”",
            "“You do not need to know how to repair it.”",
          ])}
        />
        <TextField label="Explain briefly why this information is stronger evidence than one of the other statements." guidance="Response guidance: 15–25 words. Ideal target: 20 words; this is guidance, not a limit." value={current("RV09").explanation ?? ""} onChange={value => update("RV09", "explanation", value)}  disabled={readOnly} />
      </div>


      <div className="proto-diagnostic-stimulus">
        <h3>Language in Context</h3>
        <p>Use the short original contexts below. Select or edit language in a way that preserves meaning and suits the stated situation.</p>
      </div>

      <div className="proto-diagnostic-question">
        <h3>LC01 · Vocabulary in context</h3>
        <p>During the planning meeting, the proposal was described as <strong>modest</strong>: it involved one narrow shelf, not a new room.</p>
        <ChoiceField
          legend="In this context, what does “modest” most nearly mean?"
          name="lc01"
          disabled={readOnly}
          value={current("LC01").choice ?? ""}
          onChange={value => update("LC01", "choice", value as string)}
          options={textOptions([
            "Limited in scale or ambition.",
            "Expensive to maintain.",
            "Uncertain to succeed.",
            "Disrespectful to the people involved.",
          ])}
        />
        <PaContextualExplanationField
          instrumentCode={instrument.code}
          instrumentVersion={instrument.version}
          code="LC01"
          value={current("LC01").explanation ?? ""}
          onChange={value => update("LC01", "explanation", value)}
          disabled={readOnly}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>LC02 · Sentence structure and emphasis</h3>
        <p>Compare the two versions:</p>
        <ol>
          <li>The group will review the space after four weeks.</li>
          <li>After four weeks, the group will review the space.</li>
        </ol>
        <ChoiceField
          legend="What is the main effect of placing “After four weeks” at the beginning of Version 2?"
          name="lc02"
          disabled={readOnly}
          value={current("LC02").choice ?? ""}
          onChange={value => update("LC02", "choice", value as string)}
          options={textOptions([
            "It brings the timing of the review to the foreground.",
            "It changes the review so that it happens before the trial.",
            "It suggests that the group will review only the physical space, not feedback.",
            "It removes the group as the people responsible for the review.",
          ])}
        />
        <PaContextualExplanationField
          instrumentCode={instrument.code}
          instrumentVersion={instrument.version}
          code="LC02"
          value={current("LC02").explanation ?? ""}
          onChange={value => update("LC02", "explanation", value)}
          disabled={readOnly}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>LC03 · Grammar and usage</h3>
        <p>A draft notice contains this sentence:</p>
        <blockquote>“The list of suggested books are on the shelf.”</blockquote>
        <p>The notice describes the current location of one list. Select the edited sentence that corrects subject–verb agreement while keeping the present-time meaning.</p>
        <ChoiceField
          legend="Which sentence is correct?"
          name="lc03"
          disabled={readOnly}
          value={current("LC03").choice ?? ""}
          onChange={value => update("LC03", "choice", value as string)}
          options={textOptions([
            "The list of suggested books are on the shelf.",
            "The list of suggested books is on the shelf.",
            "The lists of suggested books is on the shelf.",
            "The list of suggested books be on the shelf.",
          ])}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>LC04 · Punctuation and sentence boundaries</h3>
        <p>A writer wants to show that the volunteers checked the shelf’s position after it arrived:</p>
        <blockquote>“The shelf had arrived the volunteers checked its position.”</blockquote>
        <ChoiceField
          legend="Which edit makes the relationship between the two clauses clear?"
          name="lc04"
          disabled={readOnly}
          value={current("LC04").choice ?? ""}
          onChange={value => update("LC04", "choice", value as string)}
          options={textOptions([
            "The shelf had arrived, so the volunteers checked its position.",
            "The shelf had arrived, the volunteers checked its position.",
            "The shelf had arrived so, the volunteers checked its position.",
            "The shelf had arrived the volunteers, checked its position.",
          ])}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>LC05 · Audience, purpose and register</h3>
        <p>A hurried note says:</p>
        <blockquote>“Don’t leave bags by the stairs. People need to walk through. Move them somewhere else.”</blockquote>
        <p>Rewrite the note as a short, respectful notice for students and visitors. Keep the request clear and tell readers where to place their bags.</p>
        <TextField
          label="Your notice"
          guidance="Response guidance: 30–40 words. Ideal target: 35 words; this is guidance, not a limit."
          value={current("LC05").text ?? ""}
          onChange={value => update("LC05", "text", value)}
          disabled={readOnly}
        />
      </div>

      </>}
      {(!twoSitting || readOnly || activeSitting === 2) && <>
      {availableCodes.includes("AW01") && <PaAnalyticalWritingTask
        value={current("AW01").text ?? ""}
        onChange={value => update("AW01", "text", value)}
        readOnly={readOnly || saving}
      />}

      {availableCodes.includes("CW01") && <PaCreativeWritingTask
        value={creativeDraft}
        onChange={setCreativeDraft}
        readOnly={readOnly || saving}
      />}

      {availableCodes.includes("SP01") && <PaSpeakingOutlineTask
        value={speakingOutline}
        onChange={setSpeakingOutline}
        readOnly={readOnly || saving}
      />}

      </>}
      <div className="proto-diagnostic-footer">
        <p>{savedCodes.filter(code => requiredCodes.includes(code)).length} of {requiredCodes.length} questions have response-ready answers. Response guidance is not a hard word limit.</p>
        {!readOnly && <>
          {twoSitting && activeSitting > 0 && <button className="proto-action"
            type="button" disabled={loading || saving || readOnly || !pendingForSitting(activeSitting)}
            onClick={() => void sittingAction(activeSitting,"complete")}>
            Finish Sitting {activeSitting}
          </button>}
          <button className="proto-action secondary" type="button" onClick={() => void saveAll()} disabled={buttonDisabled || savedCodes.length === 0 || (twoSitting && activeSitting === 0)}>
            {saving ? "Saving…" : "Save progress"}
          </button>
          <button className="proto-action" type="button" onClick={() => void submitDiagnostic()} disabled={buttonDisabled || !complete || (twoSitting && finishedSittings.length !== 2)}>
            {saving ? "Please wait…" : "Submit Preliminary Assessment section"}
          </button>
        </>}
      </div>
    </>}
    {error && <p className="proto-diagnostic-error" role="alert">{error}</p>}
    {message && <p className="proto-diagnostic-message" role="status">{message}</p>}
    {reportLoading && readOnly && <p className="proto-diagnostic-message" role="status">Preparing your Evaluation Report…</p>}
    {reportError && readOnly && <>
      <p className="proto-diagnostic-error" role="alert">{reportError}</p>
      <button
        className="proto-action secondary"
        type="button"
        onClick={() => void prepareEvaluationReport(attemptId)}
        disabled={reportLoading}
      >
        {reportLoading ? "Please wait…" : "Try again"}
      </button>
    </>}
    {reportRecordId && readOnly && <button
      className="proto-action"
      type="button"
      onClick={onOpenEvaluationReport}
    >
      View your Evaluation Report →
    </button>}
  </section>;
}
