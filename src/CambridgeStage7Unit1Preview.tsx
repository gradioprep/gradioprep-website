import { useState } from "react";

const unitPath = "/pathways/cambridge-lower-secondary/english/stage-7/units/unit-1";

const initialResponses: Record<string, string> = {};

const guidedTasks = [
  {
    id: "guided-a",
    label: "A. Find a fact",
    prompt: "What was Jamil expected to work on before he got up?",
  },
  {
    id: "guided-b",
    label: "B. Select evidence",
    prompt: "Find two details that suggest the weather is becoming more difficult to manage.",
  },
  {
    id: "guided-c",
    label: "C. Make an inference",
    prompt: "What is a reasonable explanation for Jamil moving the seed trays? Identify two clues that support your answer.",
  },
  {
    id: "guided-d",
    label: "D. Explain a choice",
    prompt: "The writer says that leaves “skittered” across the tiles. What does that verb help you imagine about the movement? Explain how the word fits the moment.",
  },
];

const independentTasks = [
  {
    id: "independent-1",
    label: "1. Explicit information",
    prompt: "What did Jamil carry to the open paved patch beside the greenhouse?",
  },
  {
    id: "independent-2",
    label: "2. Evidence selection",
    prompt: "Copy two short details that suggest the rain or wind is getting stronger.",
  },
  {
    id: "independent-3",
    label: "3. Supported inference",
    prompt: "Why might Jamil decide to move the seed trays after recording the time? Use two details from the passage.",
  },
  {
    id: "independent-4",
    label: "4. Language and meaning",
    prompt: "Explain how the word “crept” affects the way the reader imagines the first line of water on the path.",
  },
  {
    id: "independent-5",
    label: "5. Check an interpretation",
    prompt: "A reader says, “Jamil stops writing because he is bored.” Is that interpretation well supported by the passage? Explain using evidence. You may offer a different interpretation if you support it.",
  },
  {
    id: "independent-6",
    label: "6. Extended response (80–100 words)",
    prompt: "How does the writer show Jamil’s attention shifting from observing the weather to helping with the garden? Use at least two precise details and explain what each contributes.",
  },
];

export default function CambridgeStage7Unit1Preview() {
  const [responses, setResponses] = useState<Record<string, string>>(initialResponses);
  const updateResponse = (id: string, value: string) => {
    setResponses((current) => ({ ...current, [id]: value }));
  };
  const clearResponses = () => setResponses({});

  const responseField = (
    id: string,
    label: string,
    prompt?: string,
    rows = 4,
  ) => (
    <div className="s7-preview-response" key={id}>
      {prompt && <p>{prompt}</p>}
      <label htmlFor={id}>{label}</label>
      <textarea
        id={id}
        name={id}
        rows={rows}
        value={responses[id] ?? ""}
        onChange={(event) => updateResponse(id, event.target.value)}
        placeholder="Write your thinking here…"
        autoCapitalize="sentences"
        spellCheck
      />
    </div>
  );

  return (
    <div className="s7-preview-shell">
      <a className="s7-preview-skip-link" href="#s7-preview-main">Skip to lesson content</a>
      <header className="s7-preview-header">
        <div className="s7-preview-container">
          <p className="s7-preview-kicker">CONTROLLED PREVIEW · INTERFACE TESTING</p>
          <h1>Read closely, infer and explain</h1>
          <p className="s7-preview-subtitle">
            Cambridge Lower Secondary English 0861 · Stage 7 · Unit 1 · Draft v1.3
          </p>
          <div className="s7-preview-alert" role="note" aria-label="Preview status">
            <strong>NOT RELEASED — NOT STUDENT-READY</strong>
            <p>
              This page exists only for interface accessibility testing. The complete current Cambridge
              framework, full objective mapping, formal rights/originality clearance, human academic and
              suitability judgement, and release approval remain outstanding. Nothing is graded or saved.
            </p>
          </div>
          <nav aria-label="Breadcrumb" className="s7-preview-breadcrumb">
            <ol>
              <li><a href="/pathways">Pathways</a></li>
              <li><a href="/pathways/cambridge-lower-secondary/english">Cambridge Lower Secondary English</a></li>
              <li><a href="/pathways/cambridge-lower-secondary/english/stage-7">Stage 7 plan</a></li>
              <li aria-current="page">Unit 1 preview</li>
            </ol>
          </nav>
        </div>
      </header>

      <main id="s7-preview-main" className="s7-preview-container s7-preview-main">
        <section aria-labelledby="s7-objectives-heading" className="s7-preview-panel">
          <p className="s7-preview-label">LEARNING GOALS</p>
          <h2 id="s7-objectives-heading">What you will learn</h2>
          <p>You will practise how to:</p>
          <ul>
            <li>find information that a text states clearly;</li>
            <li>make an inference that is supported by clues;</li>
            <li>choose precise evidence;</li>
            <li>explain how a word or detail helps create meaning.</li>
          </ul>
          <h3>Success criteria</h3>
          <ol>
            <li>I can distinguish a fact stated in the text from an inference I make.</li>
            <li>I can select a precise detail that supports my idea.</li>
            <li>I can explain how the detail supports the idea, not just copy it.</li>
          </ol>
        </section>

        <section aria-labelledby="s7-warmup-heading" className="s7-preview-panel">
          <p className="s7-preview-label">01 · WARM-UP · ABOUT 3 MINUTES</p>
          <h2 id="s7-warmup-heading">Facts and inferences</h2>
          <p>Read this original mini-example:</p>
          <blockquote className="s7-preview-quote">
            The map’s corners fluttered against Dev’s wrist. A loose sheet of paper skated across the floor.
          </blockquote>
          <fieldset className="s7-preview-choice">
            <legend>Which statement is directly stated?</legend>
            <label><input type="radio" name="s7-warmup-fact" value="cold" /> The room was cold.</label>
            <label><input type="radio" name="s7-warmup-fact" value="stated" /> The map’s corners moved and a sheet of paper skated across the floor.</label>
            <label><input type="radio" name="s7-warmup-fact" value="frightened" /> Dev was frightened.</label>
          </fieldset>
          <details className="s7-preview-worked-model">
            <summary>Open the worked example</summary>
            <p>The directly stated answer is the second option: it repeats what the sentences tell us.</p>
            <h3>Clues → inference → reason</h3>
            <ul>
              <li><strong>Clues the text states:</strong> the map’s corners fluttered, and a loose sheet of paper moved across the floor.</li>
              <li><strong>Inference:</strong> air was probably moving through the room.</li>
              <li><strong>Why it fits:</strong> both details describe light objects moving, which is consistent with air moving them.</li>
              <li><strong>What I should not claim:</strong> the text does not say that the room was cold or explain exactly why the air was moving.</li>
            </ul>
            <p>
              Use the same pattern in the passage: identify what the words actually state, make a reasonable
              inference, then explain how the clue supports it. An inference should fit the evidence; it is
              not a fact just because it seems possible.
            </p>
          </details>
        </section>

        <section aria-labelledby="s7-passage-heading" className="s7-preview-panel">
          <p className="s7-preview-label">02 · READ THE PASSAGE</p>
          <h2 id="s7-passage-heading">The Rain Gauge</h2>
          <div className="s7-preview-passage">
            <p>
              At first, the rain fell softly against the library windows, making each pane look as though
              it had been brushed with grey paint. Jamil placed his notebook on the table and watched the
              school garden beyond the glass. A thin line of water crept along the path; it stopped at the
              cracked stone beside the gate, then gathered until it slipped around the edge.
            </p>
            <p>
              Near the greenhouse, Ms Chen was trying to close a loose wooden door. She pushed once,
              listened to the hinge squeal, and looked toward the clouds. Jamil knew he was meant to finish
              his notes on plant growth, but he stood up and carried the small rain gauge to an open paved
              patch beside the greenhouse. The plastic cylinder trembled in his hands as a gust sent leaves
              skittering across the tiles.
            </p>
            <p>
              “Take care,” Ms Chen called. Her voice was calm, but she had already moved the seed trays
              away from the floor.
            </p>
            <p>
              Jamil set the gauge on a level brick and waited. The rain was stronger now. A new stream
              crossed the path, carrying one yellow leaf in a slow circle. He wrote down the time, then
              looked back at the seed trays. There was still room on the bench, just enough for the
              smallest ones.
            </p>
            <p>He put the notebook away and began to move them.</p>
          </div>
          <p className="s7-preview-source-note">Original practice passage written for this unit. No image or third-party excerpt is used on this page.</p>
          <details className="s7-preview-worked-model">
            <summary>Optional word help</summary>
            <dl className="s7-preview-word-list">
              <div><dt>Pane</dt><dd>One section of glass in a window.</dd></div>
              <div><dt>Hinge</dt><dd>The joint that lets a door open and close.</dd></div>
              <div><dt>Rain gauge</dt><dd>A container used to collect and measure rainfall.</dd></div>
              <div><dt>Paved patch</dt><dd>A small area covered with paving stones or another hard surface.</dd></div>
              <div><dt>Seed trays</dt><dd>Shallow containers used to grow seeds or seedlings.</dd></div>
            </dl>
          </details>
          <p>
            You can try to work out other unfamiliar words from the surrounding sentence first. The
            questions about “skittered” and “crept” ask you to explain the effect of those word choices,
            so use the context rather than looking for a definition first.
          </p>
        </section>

        <section aria-labelledby="s7-reading-purpose-heading" className="s7-preview-panel">
          <p className="s7-preview-label">03 · READ WITH A PURPOSE · ABOUT 5 MINUTES</p>
          <h2 id="s7-reading-purpose-heading">Read with a purpose</h2>
          <p>First, read the question before searching the passage. Then:</p>
          <ul>
            <li>identify details the text states directly;</li>
            <li>notice a word or phrase that helps you picture what is happening;</li>
            <li>mark a detail that could support an inference.</li>
          </ul>
          <p>
            You may underline on paper, jot down a short phrase, or label notes <strong>S</strong> (stated)
            and <strong>I</strong> (inference). You do not need to print or annotate the passage to complete
            the activity.
          </p>
          <p>Do not decide what a character feels or intends from one word alone. Check whether the rest of the text supports your interpretation.</p>
        </section>

        <section aria-labelledby="s7-guided-heading" className="s7-preview-panel">
          <p className="s7-preview-label">04 · GUIDED PRACTICE · ABOUT 6 MINUTES</p>
          <h2 id="s7-guided-heading">Try these in order</h2>
          <p>Use this frame if helpful: <strong>I infer that… One clue is… A second clue is… These details support my idea because…</strong></p>
          {guidedTasks.map((task) => responseField(task.id, "Your response", task.label + " — " + task.prompt, 3))}
        </section>

        <section aria-labelledby="s7-independent-heading" className="s7-preview-panel">
          <p className="s7-preview-label">05 · INDEPENDENT PRACTICE · ABOUT 8–10 MINUTES</p>
          <h2 id="s7-independent-heading">Work independently</h2>
          <p>Answer without using the sentence frame if you can.</p>
          {independentTasks.map((task) => responseField(task.id, "Your response", task.label + " — " + task.prompt, task.id === "independent-6" ? 6 : 3))}
        </section>

        <section aria-labelledby="s7-exit-heading" className="s7-preview-panel">
          <p className="s7-preview-label">06 · EXIT CHECK · ABOUT 3 MINUTES</p>
          <h2 id="s7-exit-heading">Try the thinking move independently</h2>
          <blockquote className="s7-preview-quote">
            The paper cup rolled along the platform. Lina glanced at the darkening sky and folded the picnic
            blanket into a square before tucking it into her bag.
          </blockquote>
          <p>
            Make one reasonable inference about why Lina is packing up. Identify two details that support
            your inference, and explain how they fit together.
          </p>
          {responseField("s7-exit-response", "Your exit response", undefined, 5)}
        </section>

        <section aria-labelledby="s7-reflection-heading" className="s7-preview-panel">
          <p className="s7-preview-label">REFLECTION</p>
          <h2 id="s7-reflection-heading">Look back at your thinking</h2>
          {responseField("s7-reflection-fact", "The difference between a fact and an inference is…")}
          {responseField("s7-reflection-evidence", "The strongest evidence I used today was…")}
          {responseField("s7-reflection-next", "Next time, I will improve my explanation by…")}
          <div className="s7-preview-actions">
            <button type="button" className="s7-preview-button secondary" onClick={clearResponses}>Clear all draft responses</button>
            <p>Responses are held only in this open page session. They are not graded, sent, or saved to an account.</p>
          </div>
        </section>

        <section aria-labelledby="s7-next-step-heading" className="s7-preview-panel s7-preview-next-step">
          <p className="s7-preview-label">NEXT-STEP GUIDANCE</p>
          <h2 id="s7-next-step-heading">Choose a practice move</h2>
          <p>If finding details was difficult, practise locating explicit information first.</p>
          <p>If your inference sounded possible but lacked support, practise choosing the strongest two clues.</p>
          <p>If you selected good evidence but did not explain it, practise linking each detail to your idea.</p>
          <a className="s7-preview-button" href={unitPath}>Return to the Stage 7 unit planning record</a>
        </section>
      </main>

      <footer className="s7-preview-footer">
        <div className="s7-preview-container">
          <p><strong>Controlled preview only.</strong> This candidate remains unreleased and is not an officially mapped Cambridge course.</p>
          <a href="/pathways/cambridge-lower-secondary/english/stage-7">Back to Stage 7 plan</a>
        </div>
      </footer>
    </div>
  );
}
