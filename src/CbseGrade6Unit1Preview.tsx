import { useRef, useState } from "react";
import { cbseGrade6Unit1LearnerLesson as lesson } from "./content/cbseGrade6Unit1LearnerLesson";

const directTask = lesson.tasks[0];
const inferenceTask = lesson.tasks[1];
const sequenceTask = lesson.tasks[2];
const locationTask = lesson.tasks[3];
const locationWords = ["at", "near", "down", "behind", "beside"] as const;

export default function CbseGrade6Unit1Preview() {
  const mainRef = useRef<HTMLElement | null>(null);
  const [selectedDetail, setSelectedDetail] = useState("");
  const [inferenceResponse, setInferenceResponse] = useState("");
  const [sequenceAnswers, setSequenceAnswers] = useState<Record<number, string>>({});
  const [locationAnswers, setLocationAnswers] = useState<Record<number, string>>({});
  const [exitResponse, setExitResponse] = useState("");

  const clearAll = () => {
    setSelectedDetail("");
    setInferenceResponse("");
    setSequenceAnswers({});
    setLocationAnswers({});
    setExitResponse("");
  };

  return (
    <div className="cbse-preview-root">
      <a
        className="cbse-preview-skip-link"
        href="#cbse-preview-main"
        onClick={() => mainRef.current?.focus()}
      >
        Skip to lesson content
      </a>

      <div className="proto-notice cbse-preview-notice" aria-label="Controlled preview status">
        <span aria-hidden="true" />
        <b>CONTROLLED PREVIEW</b>
        <i aria-hidden="true">/</i>
        <span className="cbse-preview-notice-text">Interface testing only · Not a release</span>
      </div>

      <header className="cbse-preview-header">
        <div className="cbse-preview-header-inner">
          <a className="cbse-preview-brand" href="/" aria-label="Criterion Lab homepage">criterion lab</a>
          <span className="cbse-preview-context">CBSE ENGLISH · GRADE 6 · UNIT 1</span>
        </div>
      </header>

      <main
        id="cbse-preview-main"
        className="cbse-preview-main"
        ref={mainRef}
        tabIndex={-1}
        aria-labelledby="cbse-preview-title"
      >
        <section className="cbse-preview-hero">
          <p className="proto-eyebrow"><span aria-hidden="true" />CBSE ENGLISH · GRADE 6 · UNIT 1</p>
          <h1 id="cbse-preview-title">{lesson.title}</h1>
          <p className="cbse-preview-description">
            Read a short story, look closely at the clues, and explain how the events fit together.
            Then practise describing where things happen.
          </p>
        </section>

        <section className="cbse-preview-status" aria-labelledby="cbse-preview-status-title">
          <div className="cbse-preview-status-mark" aria-hidden="true">i</div>
          <div className="cbse-preview-status-copy">
            <h2 id="cbse-preview-status-title">Controlled accessibility preview — not a release</h2>
            <p>
              The learner-facing content has been approved for the academic-content gate. This page
              is an ungraded interface test: responses stay in this page's temporary state and are
              not submitted, scored or saved.
            </p>
            <dl className="cbse-preview-status-grid">
              <div>
                <dt>Content review</dt>
                <dd>Approved for content</dd>
              </div>
              <div>
                <dt>Source alignment</dt>
                <dd>Partial; no official objective code</dd>
              </div>
              <div>
                <dt>Release status</dt>
                <dd>Not approved for release</dd>
              </div>
            </dl>
          </div>
        </section>

        <section className="cbse-preview-card" aria-labelledby="cbse-preview-reading-title">
          <div className="cbse-preview-card-heading">
            <span className="cbse-preview-step">01 · READ</span>
            <h2 id="cbse-preview-reading-title">{lesson.passage.label}</h2>
          </div>
          <p className="cbse-preview-passage">{lesson.passage.text}</p>
          <p className="cbse-preview-rights-note">{lesson.passage.rightsNote}</p>
          <div className="cbse-preview-goals">
            <h3>What you will practise</h3>
            <ul>{lesson.learningGoals.map(goal => <li key={goal}>{goal}</li>)}</ul>
          </div>
        </section>

        <div className="cbse-preview-interactive" aria-label="Practice activities">
          <section className="cbse-preview-card" aria-labelledby="cbse-task-1-heading">
            <div className="cbse-preview-card-heading">
              <span className="cbse-preview-step">02 · FIND A DETAIL</span>
              <h2 id="cbse-task-1-heading">{directTask.focus}</h2>
            </div>
            <fieldset className="cbse-preview-fieldset">
              <legend>{directTask.prompt}</legend>
              <div className="cbse-preview-radio-list">
                {directTask.options.map(option => (
                  <label className="cbse-preview-radio-option" htmlFor={`cbse-direct-${option.id}`} key={option.id}>
                    <input
                      id={`cbse-direct-${option.id}`}
                      type="radio"
                      name="cbse-direct-detail"
                      value={option.id}
                      checked={selectedDetail === option.id}
                      onChange={() => setSelectedDetail(option.id)}
                    />
                    <span className="cbse-preview-option-id">{option.id}</span>
                    <span className="cbse-preview-option-text">{option.text}</span>
                  </label>
                ))}
              </div>
            </fieldset>
          </section>

          <section className="cbse-preview-card" aria-labelledby="cbse-task-2-heading">
            <div className="cbse-preview-card-heading">
              <span className="cbse-preview-step">03 · EXPLAIN</span>
              <h2 id="cbse-task-2-heading">{inferenceTask.focus}</h2>
            </div>
            <label className="cbse-preview-field-label" htmlFor="cbse-inference-response">
              {inferenceTask.prompt}
            </label>
            <textarea
              id="cbse-inference-response"
              className="cbse-preview-textarea"
              rows={4}
              value={inferenceResponse}
              onChange={event => setInferenceResponse(event.target.value)}
              placeholder="Explain what the detail suggests..."
            />
            <p className="cbse-preview-field-hint">Use a detail from the passage and explain how it supports your idea.</p>
          </section>

          <section className="cbse-preview-card" aria-labelledby="cbse-task-3-heading">
            <div className="cbse-preview-card-heading">
              <span className="cbse-preview-step">04 · SEQUENCE</span>
              <h2 id="cbse-task-3-heading">{sequenceTask.focus}</h2>
            </div>
            <fieldset className="cbse-preview-fieldset">
              <legend>{sequenceTask.prompt}</legend>
              <p className="cbse-preview-field-hint">Choose a position for each event. Use each position once.</p>
              <div className="cbse-preview-sequence-list">
                {sequenceTask.items.map((eventText, index) => (
                  <label className="cbse-preview-sequence-row" htmlFor={`cbse-sequence-${index}`} key={eventText}>
                    <span className="cbse-preview-sequence-event">{eventText}</span>
                    <select
                      id={`cbse-sequence-${index}`}
                      aria-label={`Position for event ${index + 1}: ${eventText}`}
                      value={sequenceAnswers[index] ?? ""}
                      onChange={event => setSequenceAnswers(previous => ({ ...previous, [index]: event.target.value }))}
                    >
                      <option value="">Choose position</option>
                      {[1, 2, 3, 4].map(position => <option value={String(position)} key={position}>{position}</option>)}
                    </select>
                  </label>
                ))}
              </div>
            </fieldset>
          </section>

          <section className="cbse-preview-card" aria-labelledby="cbse-task-4-heading">
            <div className="cbse-preview-card-heading">
              <span className="cbse-preview-step">05 · LOCATION WORDS</span>
              <h2 id="cbse-task-4-heading">{locationTask.focus}</h2>
            </div>
            <fieldset className="cbse-preview-fieldset">
              <legend>{locationTask.prompt}</legend>
              <div className="cbse-preview-location-list">
                {locationTask.items.map((sentence, index) => {
                  const [before, after] = sentence.split("___");
                  const accessibleName = `Location word for sentence ${index + 1}: ${sentence.replace("___", "blank")}`;
                  return (
                    <label className="cbse-preview-location-row" htmlFor={`cbse-location-${index}`} key={sentence}>
                      <span>{before}</span>
                      <select
                        id={`cbse-location-${index}`}
                        aria-label={accessibleName}
                        value={locationAnswers[index] ?? ""}
                        onChange={event => setLocationAnswers(previous => ({ ...previous, [index]: event.target.value }))}
                      >
                        <option value="">Choose a word</option>
                        {locationWords.map(word => <option value={word} key={word}>{word}</option>)}
                      </select>
                      <span>{after}</span>
                    </label>
                  );
                })}
              </div>
            </fieldset>
          </section>

          <section className="cbse-preview-card" aria-labelledby="cbse-task-exit-heading">
            <div className="cbse-preview-card-heading">
              <span className="cbse-preview-step">06 · INDEPENDENT RETELLING</span>
              <h2 id="cbse-task-exit-heading">Retell the solution</h2>
            </div>
            <label className="cbse-preview-field-label" htmlFor="cbse-exit-response">
              {lesson.exitTask.prompt}
            </label>
            <textarea
              id="cbse-exit-response"
              className="cbse-preview-textarea"
              rows={5}
              value={exitResponse}
              onChange={event => setExitResponse(event.target.value)}
              placeholder="First, the animals noticed..."
            />
          </section>
        </div>

        <details className="cbse-preview-self-review">
          <summary>Open the self-review checklist</summary>
          <ul>
            <li>Have I used a relevant detail from the passage?</li>
            <li>Have I explained how the detail supports my interpretation?</li>
            <li>Have I kept the events in a clear order?</li>
            <li>Do my location words fit the relationships described?</li>
          </ul>
          <p>This is a checklist for reflection, not an answer key or a mark.</p>
        </details>

        <div className="cbse-preview-actions">
          <button className="proto-action secondary" type="button" onClick={clearAll}>Clear all responses</button>
          <a className="cbse-preview-home-link" href="/">Return to homepage</a>
        </div>
        <p className="cbse-preview-session-note">
          No response is sent to a server or saved to an account. Clear responses or leave this page
          to discard this temporary preview session.
        </p>
      </main>

      <footer className="cbse-preview-footer">
        <span>CRITERION LAB · CONTROLLED INTERFACE PREVIEW</span>
        <span>CBSE Grade 6 Unit 1 · v1.0 · Unreleased</span>
      </footer>
    </div>
  );
}
