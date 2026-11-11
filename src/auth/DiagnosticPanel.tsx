import { useState } from "react";

type ResponseValue = {
  a?: string;
  b?: string[];
  text?: string;
  choice?: string;
  order?: string[];
  explanation?: string;
};

type DiagnosticResponseMap = Record<string, ResponseValue>;

const listeningAudioUrl = "https://voa-audio.voanews.eu/vle/2016/03/17/f6b24592-2626-4dd4-9250-718b8fc96d8f.mp3?download=1";

interface StartedDiagnostic {
  diagnostic: { diagnostic_code: string; title: string; version: number; total_minutes: number; sitting_count: number };
  attempt: { id: string; status: "in_progress" | "submitted" | "withdrawn"; is_replay: boolean };
  responses: Record<string, { response: ResponseValue; revision_number: number }>;
  section_status: string;
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
  return <label className="proto-diagnostic-text-field">
    <span>{label}</span>
    {guidance && <small>{guidance}</small>}
    <textarea rows={4} maxLength={12000} value={value} onChange={event => onChange(event.target.value)} disabled={disabled} />
  </label>;
}

export default function DiagnosticPanel({ accessToken }: { accessToken: string }) {
  const [attemptId, setAttemptId] = useState("");
  const [attemptStatus, setAttemptStatus] = useState<"not_started" | "in_progress" | "submitted">("not_started");
  const [responses, setResponses] = useState<DiagnosticResponseMap>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

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
    const listening01 = current("L01");
    if (listening01.a && ["A", "B", "C", "D"].includes(listening01.a) &&
        Array.isArray(listening01.b) && listening01.b.length === 2 &&
        new Set(listening01.b).size === 2 && listening01.b.every(value => ["A", "B", "C", "D"].includes(value))) {
      output.push({ code: "L01", response: { a: listening01.a, b: listening01.b } });
    }
    for (const code of ["RV02", "RV03", "RV06", "RV07a", "RV07b", "L02", "L04", "L05"]) {
      if (nonEmpty(current(code).text)) output.push({ code, response: { text: current(code).text } });
    }
    for (const code of ["RV04", "RV05", "L03", "LC01", "LC02", "LC03", "LC04"]) {
      if (current(code).choice && ["A", "B", "C", "D"].includes(current(code).choice!)) {
        output.push({ code, response: { choice: current(code).choice } });
      }
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
    return output;
  }

  const savedCodes = payloads().map(item => item.code);
  const complete = ["RV01", "RV02", "RV03", "RV04", "RV05", "RV06", "RV07a", "RV07b", "RV08", "RV09", "L01", "L02", "L03", "L04", "L05", "LC01", "LC02", "LC03", "LC04", "LC05"]
    .every(code => savedCodes.includes(code));

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
      if (!response.ok || !result.attempt?.id) throw new Error(result.error ?? "The Diagnostic could not be opened.");
      setAttemptId(result.attempt.id);
      setAttemptStatus(result.attempt.status === "submitted" ? "submitted" : "in_progress");
      const restored: DiagnosticResponseMap = {};
      for (const [code, value] of Object.entries(result.responses ?? {})) {
        restored[code] = value.response ?? {};
      }
      setResponses(restored);
      setMessage(result.attempt.status === "submitted"
        ? "Your Read & View, Listening and Language in Context evidence was submitted. This section is now read-only."
        : result.attempt.is_replay ? "Your saved Diagnostic section has been restored." : "Your Diagnostic section has started.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The Diagnostic could not be opened.");
    } finally {
      setLoading(false);
    }
  }

  async function saveAll(): Promise<boolean> {
    if (!attemptId) return false;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      for (const item of payloads()) {
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
    if (!complete || !attemptId) return;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      for (const item of payloads()) {
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
        throw new Error(result.error ?? "The Diagnostic could not be submitted.");
      }
      setAttemptStatus("submitted");
      setMessage("Your Read & View, Listening and Language in Context evidence has been submitted. These responses are now read-only.");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "The Diagnostic could not be submitted.");
    } finally {
      setSaving(false);
    }
  }

  const readOnly = attemptStatus === "submitted";
  const buttonDisabled = loading || saving || readOnly;

  return <section className="proto-panel proto-diagnostic" aria-labelledby="proto-diagnostic-heading">
    <div className="proto-panel-heading proto-diagnostic-heading">
      <div>
        <p className="proto-eyebrow"><span />CYCLE 1 · IB MYP YEAR 4 / GRADE 9</p>
        <h2 id="proto-diagnostic-heading">Diagnostic assessment</h2>
        <p>Read & View + Listening + Language in Context · initial delivery slice</p>
      </div>
      <span className="proto-account-status">{attemptStatus === "submitted" ? "Submitted" : attemptStatus === "in_progress" ? "In progress" : "Not started"}</span>
    </div>

    {attemptStatus === "not_started" ? <div className="proto-diagnostic-intro">
      <p>This build contains the Read & View and Language in Context tasks from Sitting 1. Start or continue your saved attempt to answer the twenty enabled observations.</p>
      <p>Listening and the remaining task groups are not included in this implementation slice. No marks, score or Evaluation Report are generated here.</p>
      <button className="proto-action" type="button" onClick={() => void startOrResume()} disabled={loading}>
        {loading ? "Opening assessment…" : "Start / continue Diagnostic"}
      </button>
    </div> : <>
      <div className="proto-diagnostic-notice" role="note">
        <strong>{readOnly ? "Current section submitted" : "Read & View + Listening + Language in Context only"}</strong>
        <span>{readOnly
          ? "Your submitted responses are displayed without scores or marking feedback."
          : "This is a partial, unscored Diagnostic implementation. Analytical Writing, Creative / Purposeful Production and Speaking / Presenting are not included yet. Your work is saved when you choose Save progress or Submit."}</span>
      </div>

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
      </div>

      <div className="proto-diagnostic-question">
        <h3>RV06 · Critical perspective and representation</h3>
        <p>A volunteer says: “The team fixed almost every object on the day.” Is that a fair description of the poster’s results? Use at least one figure from the graphic and explain one limitation in the statement.</p>
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


      <div className="proto-diagnostic-stimulus proto-diagnostic-listening" aria-labelledby="diagnostic-listening-heading">
        <h3 id="diagnostic-listening-heading">Listening · Solar Powered Library Helps Remote Students</h3>
        <p>Listen to the complete VOA Learning English report (4 minutes 10 seconds). The report includes narration and interview excerpts from people involved in the SolarSPELL project.</p>
        <audio
          data-testid="diagnostic-listening-audio"
          aria-label="VOA Learning English: Solar Powered Library Helps Remote Students"
          src={listeningAudioUrl}
          controls
          preload="none"
        >
          Your browser does not support audio playback. <a href={listeningAudioUrl}>Open the audio recording</a>.
        </audio>
        <p className="proto-diagnostic-attribution">Audio: Voice of America Learning English, “Solar Powered Library Helps Remote Students” (23 March 2016). Public-domain VOA Learning English MP3; reused with credit to learningenglish.voanews.com. <a href="https://learningenglish.voanews.com/a/solar-powered-library-helps-remote-students/3240836.html" target="_blank" rel="noreferrer">Original source and transcript</a>.</p>
      </div>

      <div className="proto-diagnostic-question">
        <h3>L01 · Central message and explicit information</h3>
        <ChoiceField
          legend="L01a. Which statement best expresses the report’s central message?"
          name="l01a"
          disabled={readOnly}
          value={current("L01").a ?? ""}
          onChange={value => update("L01", "a", value as string)}
          options={textOptions([
            "SolarSPELL is a solar-powered offline digital library designed to widen access to educational content in remote communities.",
            "SolarSPELL connects remote communities to the full public internet through satellite service.",
            "SolarSPELL replaces classroom teachers with online courses.",
            "SolarSPELL supplies electricity to entire villages.",
          ])}
        />
        <ChoiceField
          legend="L01b. Select two details that the report gives about the SolarSPELL project."
          name="l01b"
          disabled={readOnly}
          multiple
          value={current("L01").b ?? []}
          onChange={value => update("L01", "b", value as string[])}
          options={textOptions([
            "The solar-powered unit creates a WiFi hotspot without needing an internet connection.",
            "The Peace Corps has used about 50 units, and one unit in Naviso had been used by about 200 students.",
            "Each unit depends on permanent power cables and a live internet connection.",
            "The units are available only to university students in the United States.",
          ])}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>L02 · Inference and speaker viewpoint</h3>
        <p>Why does Alexis Cullen worry that communities without internet access may fall further behind? What wider concern about education and participation is she expressing?</p>
        <TextField label="Your response" guidance="Response guidance: 25–35 words. Ideal target: 30 words; this is guidance, not a limit." value={current("L02").text ?? ""} onChange={value => update("L02", "text", value)} disabled={readOnly} />
      </div>

      <div className="proto-diagnostic-question">
        <h3>L03 · Audience, context and purpose</h3>
        <ChoiceField
          legend="Who is the report’s most likely audience, and what is its main purpose?"
          name="l03"
          disabled={readOnly}
          value={current("L03").choice ?? ""}
          onChange={value => update("L03", "choice", value as string)}
          options={textOptions([
            "General listeners interested in education and technology; to explain an offline-learning initiative while considering its benefits and limits.",
            "Engineers at the university; to provide a technical construction manual for the device.",
            "Residents of Naviso; to ask them to purchase a SolarSPELL unit.",
            "Peace Corps staff; to instruct them to stop using community learning programmes.",
          ])}
        />
      </div>

      <div className="proto-diagnostic-question">
        <h3>L04 · Spoken language choice and emphasis</h3>
        <p>Gabriel Krieshok describes a universal approach as a “one size-fits-all solution” and says that it “never works”. Explain how this wording communicates his concern about using the same technology in different communities.</p>
        <TextField label="Your response" guidance="Response guidance: 25–35 words. Ideal target: 30 words; this is guidance, not a limit." value={current("L04").text ?? ""} onChange={value => update("L04", "text", value)} disabled={readOnly} />
      </div>

      <div className="proto-diagnostic-question">
        <h3>L05 · Evaluate a conclusion</h3>
        <p>A listener concludes: “Because SolarSPELL has helped students in Vanuatu, the same technology will solve the lack of educational access in every remote community.” Is this conclusion fully supported, partly supported or exaggerated? Use evidence from the report and identify one limitation.</p>
        <TextField label="Your response" guidance="Response guidance: 35–45 words. Ideal target: 40 words; this is guidance, not a limit." value={current("L05").text ?? ""} onChange={value => update("L05", "text", value)} disabled={readOnly} />
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

      <div className="proto-diagnostic-footer">
        <p>{savedCodes.length} of 20 observations have response-ready answers. Response guidance is not a hard word limit.</p>
        {!readOnly && <>
          <button className="proto-action secondary" type="button" onClick={() => void saveAll()} disabled={buttonDisabled || savedCodes.length === 0}>
            {saving ? "Saving…" : "Save progress"}
          </button>
          <button className="proto-action" type="button" onClick={() => void submitDiagnostic()} disabled={buttonDisabled || !complete}>
            {saving ? "Please wait…" : "Submit Diagnostic section"}
          </button>
        </>}
      </div>
    </>}
    {error && <p className="proto-diagnostic-error" role="alert">{error}</p>}
    {message && <p className="proto-diagnostic-message" role="status">{message}</p>}
  </section>;
}
