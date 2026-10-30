import type { PilotLessonPack } from "./model";

/**
 * Teacher/editor-only source for Unit 1 candidate version 3.
 * Contains answers, rationales and model responses. Never import this module
 * into the learner-facing application or its public client bundle.
 * AI-assisted drafting is not a human academic review.
 */
export const pilotLessonPack: PilotLessonPack = {
  id: "draft-lesson-how-writers-shape-meaning-v3",
  version: 3,
  unitId: "ib-myp-lal-y1-u1",
  status: "draft-for-founder-review",
  reviewRecord: {
    outcome: "pending",
    reviewedAt: null,
    reviewerLabel: "Academic review pending",
    scopeNote:
      "Version 3 is a new candidate prepared under the standards approved on 30 October 2026. Version 2 founder approval and version 1 academic-preview approval are historical and do not transfer. Human academic review of every question, rationale, model response and feedback item remains pending.",
  },
  title: "How writers and creators shape meaning",
  audienceNote:
    "Proposed for beginning MYP Language and Literature learners. Victorian prose demand, vocabulary load and sequence require a human age/level and accessibility review.",
  estimatedMinutes: 35,
  proposedLearningObjective:
    "Explain how a writer's language choices and a visual creator's design choices may shape atmosphere and meaning, using precise evidence and the surrounding context.",
  mappingStatus: "unverified",
  successCriteria: [
    "Select a precise word, phrase or visible design detail.",
    "Explain a plausible association or effect instead of only naming a technique.",
    "Connect the interpretation to the moment and audience using evidence.",
    "Recognise that more than one interpretation can be reasonable when it is supported by the text or image.",
  ],
  passage: {
    excerptId: "EXC-IB-MYP-Y1-U1-MAIN",
    sourceId: "SRC-IB-MYP-Y1-U1-001",
    label: "Literary extract — A Christmas Carol by Charles Dickens",
    text: "The city clocks had only just gone three, but it was quite dark already: it had not been light all day: and candles were flaring in the windows of the neighbouring offices, like ruddy smears upon the palpable brown air. The fog came pouring in at every chink and keyhole, and was so dense without, that although the court was of the narrowest, the houses opposite were mere phantoms.\n\nTo see the dingy cloud come drooping down, obscuring everything, one might have thought that Nature lived hard by, and was brewing on a large scale.",
    rightsNote:
      "From Stave I, “Marley's Ghost”, in A Christmas Carol (London: Chapman & Hall, 1843). Original English text transcribed from the 1843 edition. Underlying text public-domain term checks are recorded for India and the United Kingdom only; the United States and other territories are not cleared. Final unit-level rights sign-off remains pending.",
  },
  companionArtifact: {
    label: "Fictional night-bus campaign poster",
    kicker: "NORTHBANK NIGHT BUS",
    headline: "A LIGHT ON EVERY LAST JOURNEY",
    supportingText: "The late bus is still a way home.",
    footerText: "PLAN AHEAD · TRAVEL WITH CARE",
    visualDescription:
      "A photograph shows an empty bus-stop platform at night. A bus-stop sign stands beside a dark road; orange streetlights illuminate the pavement and distant headlights approach. The platform-created poster headline and supporting line are placed around the photograph.",
    altText:
      "An empty bus-stop platform at night beside a dark road. Orange streetlights light the pavement and distant headlights approach; no people are visible.",
    rightsNote:
      "Photograph “Bus stop with platform during night.jpg” by Mateusz Konieczny; Wikimedia Commons file page records CC0 1.0 Universal Public Domain Dedication. File/licence rechecked 30 October 2026. Platform-authored headline, supporting line and layout are original content. Reconfirm asset, attribution and accessibility at final rights review.",
  },
  vocabularySupport: [
    { term: "ruddy", meaning: "reddish in colour" },
    { term: "palpable", meaning: "so noticeable or thick that it almost seems touchable" },
    { term: "chink", meaning: "a small crack or opening" },
    { term: "phantoms", meaning: "ghost-like shapes that are difficult to see clearly" },
    { term: "dingy", meaning: "dull, dark or dirty-looking" },
    { term: "obscuring", meaning: "making something difficult to see" },
    { term: "brewing", meaning: "making or producing something; here, used figuratively" },
  ],
  entryCheck: {
    prompt:
      "Choose one word or phrase from the Dickens extract, or one visible detail from the poster. Describe exactly what you notice before explaining its effect.",
    placeholder: "I notice the phrase/detail … It literally shows …",
    expectedResponseLength: { minWords: 15, maxWords: 25 },
    successIndicators: [
      "Identifies a precise word, phrase or visible detail.",
      "Describes what is literally present before adding an interpretation.",
    ],
    modelAnswer:
      "I notice “mere phantoms”. The words describe the houses as faint shapes, not as clearly visible buildings.",
    responseGuidance: {
      evidenceTargets: [
        "A precise phrase from the extract, such as “ruddy smears”, “palpable brown air” or “mere phantoms”, or a specific poster detail.",
        "A literal observation before an inferred effect.",
      ],
      acceptedInterpretations: [
        "Accept any accurate literal observation from the passage or poster, including colour, light, fog, shape, placement or wording.",
        "Do not require an interpretation at this stage; the purpose is to separate observation from inference.",
      ],
      qualityBands: {
        strong: "Names one exact word, phrase or visible detail and describes it literally in the requested range.",
        developing: "Names a broad feature, such as fog or dark colours, but does not point to a precise detail.",
        weak: "Gives an unsupported opinion or an interpretation without identifying what can actually be seen or read.",
        feedbackStrong: "You have selected a detail that can be checked directly in the source.",
        feedbackDeveloping: "Choose one exact word, phrase or visible feature rather than naming the whole scene.",
        feedbackWeak: "Start with what is actually written or shown. Leave your opinion about its effect for the next step.",
        nextStep: "Underline the exact evidence first; then decide what it may suggest.",
      },
    },
  },
  keyIdea: {
    label: "The evidence chain",
    pattern: [
      "Choice — identify the creator's language or design decision.",
      "Evidence — quote the exact wording or describe the specific visible detail.",
      "Effect in context — explain a plausible association and connect it to the moment or audience.",
    ],
    explanation:
      "Keep the choice, evidence and interpretation distinct. “Personification” names a choice; “Nature lived hard by” is evidence; the idea that the fog seems almost deliberately produced is an interpretation. A possible effect is not a guaranteed reaction for every reader or viewer.",
  },
  sections: [
    {
      id: "observe",
      heading: "1. Notice before you interpret",
      purpose: "Separate what can be observed from what can be inferred.",
      explanation:
        "The extract describes candles as “ruddy smears” and nearby houses as “mere phantoms”. The poster shows an empty platform, orange lighting and approaching headlights. Record these details first; do not assume that every reader will interpret them in the same way.",
      learnerAction:
        "Write one literal observation from the Dickens extract and one from the poster. Keep each close to the exact words or visible details.",
    },
    {
      id: "evidence-chain",
      heading: "2. Build an evidence chain",
      purpose: "Link a precise choice to an explanation supported by context.",
      explanation:
        "The phrase “mere phantoms” compares the houses to ghost-like shapes. This may suggest that the fog hides their familiar shapes. The nearby description of fog entering through “every chink and keyhole” supports that reading.",
      learnerAction:
        "Use all three parts: “The writer chooses to … . The evidence is ‘…’. This may suggest … because … .”",
      example: {
        label: "Worked example",
        text: "“the houses opposite were mere phantoms”",
        explanation:
          "The writer uses a comparison that makes the houses seem ghost-like (choice and evidence). This may suggest that the fog hides their familiar shapes, creating an uncertain or eerie atmosphere (possible effect in this setting).",
      },
    },
    {
      id: "compare",
      heading: "3. Compare two creators' choices",
      purpose: "Explain how a written description and a visual campaign may frame night-time streets differently.",
      explanation:
        "Dickens describes thick fog and buildings that are difficult to see. The poster places a bright shelter and the words “A light on every last journey” against a dark street. The poster may appear reassuring, although the dark setting could also remind some viewers to take care when travelling.",
      learnerAction:
        "Choose one exact phrase from Dickens and one written or visual feature from the poster. Explain how each could shape an audience's impression of being out at night.",
    },
    {
      id: "context",
      heading: "4. Explain a choice in context",
      purpose: "Use the wider sentence and moment to develop an interpretation.",
      explanation:
        "Dickens imagines that “Nature lived hard by” and was “brewing” the fog. This makes the weather seem almost like something a neighbour is deliberately making. The exaggeration may feel playful, ominous or both; the surrounding darkness helps explain why.",
      learnerAction:
        "Explain what the image of Nature “brewing” may suggest. Use the wording and the surrounding description of the dark, foggy street.",
    },
    {
      id: "transfer",
      heading: "5. Transfer the thinking move",
      purpose: "Apply the same evidence chain to a new writer and a different kind of scene.",
      explanation:
        "The exit extract comes from Lewis Carroll's fantasy story, not Dickens's urban Christmas setting. Focus on the sudden change in the rabbit-hole and Alice's unusual fall. A copied explanation about fog will not fit this new context.",
      learnerAction:
        "Choose a word or phrase from the Alice extract. Explain how it shapes the moment of the fall and connect your interpretation to what Alice experiences.",
    },
  ],
  practiceItems: [
    {
      id: "pilot-v3-q1",
      type: "best-explanation",
      focus: "Interpreting imagery and atmosphere",
      prompt:
        "Which explanation is best supported by comparing the candles to “ruddy smears upon the palpable brown air”?",
      options: [
        { id: "A", text: "The candles appear as neat, sharply outlined points against clear air.", feedback: "This conflicts with “smears” and the description of the thick brown air; the image does not suggest crisp points or clear conditions." },
        { id: "B", text: "The light seems blurred and spread through thick air, helping the reader imagine the foggy, obscured street.", feedback: "This is the best-supported explanation: “smears” suggests blurred shapes, and the surrounding wording describes thick fog and poor visibility." },
        { id: "C", text: "The phrase proves that the neighbouring offices are on fire.", feedback: "The text says candles are flaring; it does not report a fire. Do not turn an image of light into an event that is not stated." },
        { id: "D", text: "The image suggests that bright morning sunlight has cleared the fog.", feedback: "The extract says it is already dark at about three o'clock and describes candles and dense fog, not morning sunlight or clear weather." },
      ],
      bestOptionId: "B",
      answerReasoning: {
        correctOptionId: "B",
        explanation:
          "“Ruddy smears” compares the candlelight to reddish marks rather than distinct points. “Palpable brown air” makes the air seem thick and almost touchable. The next sentence confirms that the fog is dense and hides the houses. Option B is therefore the only explanation supported by the image and its immediate context.",
        optionRationales: [
          { optionId: "A", rationale: "Incorrect. “Smears” suggests blurred or spread marks, and the air is described as brown and thick rather than clear." },
          { optionId: "B", rationale: "Correct. It combines the blurred comparison with the surrounding description of dense fog and obscured buildings." },
          { optionId: "C", rationale: "Incorrect. Candles are present, but no office fire is described. The answer invents an event." },
          { optionId: "D", rationale: "Incorrect. It contradicts the stated darkness and candles. The extract does not describe sunlight clearing the fog." },
        ],
        acceptedAlternatives: [
          "No other option letter is correct. Accept a paraphrase of option B if the learner explains that the candlelight seems blurred, spread or difficult to distinguish in the thick fog.",
          "Do not accept “the passage proves a fire” or an explanation that ignores the words “smears” and “palpable brown air”.",
        ],
      },
      modelAnswer:
        "B — “smears” makes the candlelight seem blurred, while “palpable brown air” suggests thick fog. The surrounding sentence says the houses are difficult to see.",
      successIndicators: [
        "Chooses the explanation that fits the comparison and the surrounding description.",
        "Checks that the interpretation does not add an event that the text never states.",
      ],
      feedbackForLearner: {
        ifStrong: "You used both the comparison and the surrounding description to choose the best-supported interpretation.",
        nextStep: "When you choose an explanation, check every part of it against the exact wording and the sentences around it.",
      },
    },
    {
      id: "pilot-v3-q2",
      type: "short-response",
      focus: "Explaining a writer's description of fog",
      prompt:
        "Explain how the words “pouring in at every chink and keyhole” and “mere phantoms” shape the atmosphere of the street.",
      expectedResponseLength: { minWords: 40, maxWords: 55 },
      modelAnswer:
        "Dickens makes the fog seem active by saying it was “pouring in” through “every chink and keyhole”. The list of small openings suggests it enters everywhere, while “mere phantoms” makes the nearby houses seem faint and difficult to see. Together, these details create a dense, unsettling atmosphere.",
      successIndicators: [
        "Uses at least one of the quoted phrases accurately.",
        "Explains a plausible association, such as the fog seeming to enter everywhere or the houses becoming hard to see.",
        "Connects the wording to the atmosphere of the street.",
      ],
      responseGuidance: {
        evidenceTargets: [
          "“pouring in at every chink and keyhole”: the verb and the list of openings.",
          "“mere phantoms”: the comparison describing the houses.",
          "The wider context of darkness, candles and dense fog.",
        ],
        acceptedInterpretations: [
          "Accept readings of the fog as intrusive, enveloping, persistent, overwhelming or difficult to keep out.",
          "Accept readings of the houses as faint, ghost-like, uncertain or obscured.",
          "Accept eerie, unsettling, claustrophobic or disorienting atmosphere where the learner ties it to exact evidence.",
        ],
        qualityBands: {
          strong: "Uses accurate textual evidence, explains both an image or association and its effect on the street's atmosphere, and stays within the requested range.",
          developing: "Identifies relevant wording but mostly paraphrases it, or names a mood without explaining how the wording creates it.",
          weak: "Makes a general claim about fog or darkness with no precise evidence, or treats “phantoms” literally as actual ghosts.",
          feedbackStrong: "You explained how the image works rather than simply naming the fog or mood.",
          feedbackDeveloping: "You have selected a useful phrase. Add what the phrase makes the fog or houses seem like, then connect that idea to the atmosphere.",
          feedbackWeak: "Choose one exact phrase from the extract first. Explain what it makes you imagine; do not add events that are not in the passage.",
          nextStep: "Use the chain: exact words → plausible association → effect on this street.",
        },
      },
      feedbackForLearner: {
        ifStrong: "You linked the wording to a plausible atmosphere and supported your explanation.",
        nextStep: "Check that you explain the effect of the phrase, not only what the fog does.",
      },
    },
    {
      id: "pilot-v3-q3",
      type: "short-response",
      focus: "Comparing written and visual choices",
      prompt:
        "Compare how Dickens's description and the night-bus poster could shape an audience's impression of being out at night. Use one precise detail from each.",
      expectedResponseLength: { minWords: 65, maxWords: 85 },
      modelAnswer:
        "The Dickens extract makes the street difficult to see: the fog is “pouring in” and nearby houses become “mere phantoms”, so the setting feels closed-in and uncertain. The poster frames night travel more reassuringly. Its bright shelter and headline “A light on every last journey” draw attention to a visible place to wait and suggest that a journey home is available. The dark background may also remind some viewers to take care.",
      successIndicators: [
        "Uses an exact phrase from the Dickens extract.",
        "Uses a specific written or visual feature from the poster.",
        "Explains a similarity or difference in the impressions the choices may create.",
        "Recognises that the dark poster background may be read in more than one defensible way.",
      ],
      responseGuidance: {
        evidenceTargets: [
          "Dickens: “pouring in”, “mere phantoms”, candles or the brown air.",
          "Poster: headline “A light on every last journey”, bright amber shelter, dark street or approaching headlights.",
          "An explicit comparison of the impression each choice may create.",
        ],
        acceptedInterpretations: [
          "The Dickens scene may feel obscured, enclosed, eerie, confusing or oppressive.",
          "The poster may feel reassuring, hopeful or practical because the shelter is brightly lit and a way home is promised.",
          "The poster's dark backdrop may also suggest risk, caution or uncertainty. Accept this if supported by the image and copy.",
          "Accept another interpretation when the learner supports it with a precise feature from each artefact.",
        ],
        qualityBands: {
          strong: "Uses precise evidence from both artefacts, explains the difference or relationship between the choices, and qualifies audience effect appropriately.",
          developing: "Mentions a detail from each artefact but mainly lists them or explains only one side of the comparison.",
          weak: "Gives a general opinion about night travel, uses no checkable details, or claims that every audience will react in one fixed way.",
          feedbackStrong: "You compared the creators' choices and explained how the evidence supports the contrast.",
          feedbackDeveloping: "You have two relevant details. Explain what each one may suggest, then state how the impressions differ or connect.",
          feedbackWeak: "Start again with one exact phrase from Dickens and one visible or written detail from the poster. Keep your opinion tied to those details.",
          nextStep: "Use a paired structure: Dickens chooses …, which may suggest …; the poster chooses …, which may suggest … .",
        },
      },
      feedbackForLearner: {
        ifStrong: "You compared the two artefacts through evidence rather than listing unrelated observations.",
        nextStep: "Make the link between each feature and the impression it may create explicit.",
      },
    },
    {
      id: "pilot-v3-q4",
      type: "short-response",
      focus: "Interpreting personification and exaggeration",
      prompt:
        "What might Dickens suggest by imagining that Nature “lived hard by” and was “brewing” the fog? Explain how the image fits the scene.",
      expectedResponseLength: { minWords: 45, maxWords: 65 },
      modelAnswer:
        "By imagining Nature as a neighbour “brewing” something, Dickens makes the fog seem deliberately produced rather than ordinary weather. “On a large scale” exaggerates its size and force. The playful image makes the cloud seem almost alive while showing how completely it hides the street.",
      successIndicators: [
        "Uses the words “lived hard by” or “brewing” as evidence.",
        "Explains the personification or exaggeration rather than treating the image literally.",
        "Connects the interpretation to the thick fog and darkness.",
      ],
      responseGuidance: {
        evidenceTargets: [
          "“Nature lived hard by”: Nature is imagined as a neighbour.",
          "“brewing on a large scale”: the fog is imagined as something made in an exaggerated amount.",
          "The surrounding fog and darkness that obscure the street.",
        ],
        acceptedInterpretations: [
          "Accept a playful, humorous, ominous, threatening or exaggerated reading if tied to the phrasing and setting.",
          "Accept the idea that the fog seems alive, deliberate, or produced in an enormous quantity.",
          "Do not require the learner to use the technical term “personification” if the explanation correctly describes the human-like idea.",
        ],
        qualityBands: {
          strong: "Explains how the neighbour/brewing image works, uses precise evidence and connects its exaggeration to the obscured street.",
          developing: "Recognises that the image is unusual or exaggerated but does not explain what it suggests about the fog.",
          weak: "Treats Nature as a literal person making a real drink, or gives a mood word without textual evidence.",
          feedbackStrong: "You explained the comparison and linked it to the scale of the fog.",
          feedbackDeveloping: "Explain what changes when Nature is imagined as a neighbour who is brewing something.",
          feedbackWeak: "Read the image figuratively: what does the writer make Nature seem to be doing, and how does that change the fog?",
          nextStep: "Explain the human action first, then connect the exaggeration to the setting.",
        },
      },
      feedbackForLearner: {
        ifStrong: "You interpreted the figurative image and linked it to the scale of the fog.",
        nextStep: "Explain what the human action suggests before naming the technique.",
      },
    },
    {
      id: "pilot-v3-q5",
      type: "response-revision",
      focus: "Improving a vague explanation",
      prompt:
        "Improve this weak response in two or three sentences: “The fog is described. It makes the writing interesting.” Use one precise phrase from Dickens and explain its effect.",
      expectedResponseLength: { minWords: 45, maxWords: 65 },
      modelAnswer:
        "Dickens compares the houses to “mere phantoms”, suggesting that the fog makes familiar buildings appear faint and ghostlike. This creates an eerie, enclosed atmosphere because the reader cannot see the street clearly. The image is supported by the fog entering through “every chink and keyhole”.",
      successIndicators: [
        "Replaces the vague comment with a specific phrase from the extract.",
        "Explains what the phrase may suggest or help the reader imagine.",
        "Links the interpretation to the street's atmosphere.",
      ],
      responseGuidance: {
        evidenceTargets: [
          "One exact image, such as “mere phantoms”, “ruddy smears” or “pouring in at every chink and keyhole”.",
          "An explanation of the picture or association created by that wording.",
          "A connection to the dark, foggy street.",
        ],
        acceptedInterpretations: [
          "Accept alternatives using different accurate phrases from the passage.",
          "Accept eerie, faint, blurred, enclosed, uncertain, intrusive or overwhelming readings when supported by evidence.",
          "A response may focus on the candlelight rather than the houses if it still explains a precise image and the setting.",
        ],
        qualityBands: {
          strong: "Replaces the vague statement with precise evidence, explains a plausible effect and connects it to the setting in two or three coherent sentences.",
          developing: "Adds a quotation or technique name but still gives only a general comment about being interesting or effective.",
          weak: "Repeats the original response, gives an unsupported opinion or quotes a phrase without explaining it.",
          feedbackStrong: "You have turned a general statement into an evidence-based explanation.",
          feedbackDeveloping: "The quotation is a useful start. Explain what the image helps the reader picture and why that matters in this street.",
          feedbackWeak: "Do not repeat “it is interesting”. Choose one exact phrase and explain what it makes the street look or feel like.",
          nextStep: "Replace a judgement word with an explanation: phrase → image or association → effect in context.",
        },
      },
      feedbackForLearner: {
        ifStrong: "You replaced a general opinion with a precise image and explained its contribution.",
        nextStep: "Remove vague words such as “nice” or “interesting”; explain exactly what the phrase makes the reader imagine.",
      },
    },
  ],
  exitTicket: {
    stimulus: {
      excerptId: "EXC-IB-MYP-Y1-U1-TRANSFER",
      sourceId: "SRC-IB-MYP-Y1-U1-002",
      label: "Independent transfer extract — Alice's Adventures in Wonderland by Lewis Carroll",
      text: "The rabbit-hole went straight on like a tunnel for some way, and then dipped suddenly down, so suddenly that Alice had not a moment to think about stopping herself before she found herself falling down what seemed to be a very deep well.\n\nEither the well was very deep, or she fell very slowly, for she had plenty of time as she went down to look about her, and to wonder what was going to happen next. First, she tried to look down and make out what she was coming to, but it was too dark to see anything: then she looked at the sides of the well, and noticed that they were filled with cupboards and book-shelves: here and there she saw maps and pictures hung upon pegs.",
      rightsNote:
        "From Chapter I, “Down the rabbit-hole”, in Alice's Adventures in Wonderland (London: Macmillan and Co., 1866). Original English text from the 1866 edition; no modern translation or illustration is reproduced. Underlying text public-domain term checks are recorded for India and the United Kingdom only; the United States and other territories are not cleared. Final unit-level rights sign-off remains pending.",
    },
    prompt:
      "Choose a word or phrase from this extract. Explain how Carroll makes the fall seem unusual or surprising, and connect your interpretation to what Alice experiences.",
    expectedResponseLength: { minWords: 45, maxWords: 60 },
    vocabularySupport: [
      { term: "dipped", meaning: "sloped or moved downward" },
      { term: "make out", meaning: "see or recognise clearly" },
      { term: "cupboards", meaning: "storage cabinets" },
      { term: "pegs", meaning: "small hooks or pins used for hanging things" },
    ],
    successIndicators: [
      "Quotes a precise word or phrase from the Alice extract.",
      "Explains a plausible effect, such as surprise, uncertainty, curiosity or comic strangeness.",
      "Connects the explanation to the sudden fall or Alice's unusual surroundings.",
    ],
    modelAnswer:
      "Carroll says the rabbit-hole “dipped suddenly down”, so Alice's journey changes direction without warning. The simile “like a tunnel” first suggests a familiar passage, but the unexpected well makes the setting strange. This contrast makes the fall feel surprising while keeping Alice curious about what will happen next.",
    responseGuidance: {
      evidenceTargets: [
        "“dipped suddenly down”: the unexpected change in direction.",
        "“like a tunnel”: the comparison with a familiar passage.",
        "“what seemed to be a very deep well” or “plenty of time”: the strange experience of the fall.",
      ],
      acceptedInterpretations: [
        "Accept surprise, disorientation, curiosity, wonder or comic strangeness if tied to the wording.",
        "Accept the interpretation that the fall seems oddly calm or dreamlike if the learner uses the slow-fall wording and explains why.",
        "Do not require a single mood; reward a clear explanation grounded in the extract.",
      ],
      qualityBands: {
        strong: "Uses a precise quotation, explains how the language shapes the fall and links the interpretation to Alice's experience within the range.",
        developing: "Selects relevant wording but mostly retells what happens or names a mood without explaining how the wording creates it.",
        weak: "Uses no exact evidence, copies an explanation about Dickens's fog or makes a claim unsupported by the Alice extract.",
        feedbackStrong: "You transferred the evidence chain to a different writer and a different scene.",
        feedbackDeveloping: "You have identified the event. Add what the exact words make the fall seem like and why.",
        feedbackWeak: "Choose a phrase from the Alice extract, not the Dickens passage. Explain what is unusual about the rabbit-hole or the fall.",
        nextStep: "Use new evidence from this extract and connect its effect to Alice's experience.",
      },
    },
  },
  feedbackGuide: [
    { area: "Evidence choice", developing: "Uses a general feature or a loose reference.", secure: "Selects an exact phrase or identifiable visual detail." },
    { area: "Explanation", developing: "Names a technique or mood without explaining its contribution.", secure: "Explains a plausible association and links the detail to it." },
    { area: "Context and audience", developing: "Could apply the same comment to almost any text or poster.", secure: "Connects the interpretation to this moment, wider scene or intended audience." },
    { area: "Comparison", developing: "Lists one feature from each artefact without explaining a relationship.", secure: "Explains how the choices create a similarity or difference in likely impression." },
    { area: "Communication", developing: "Idea is difficult to follow or relies on an unsupported assertion.", secure: "Presents a reasoned point, uses evidence and qualifies an interpretation where useful." },
  ],
  accessibilitySupports: [
    "The passage and poster copy remain selectable text. The poster has descriptive alt text and does not rely on colour alone.",
    "The main excerpt includes vocabulary support and should be chunked into two short reading sections.",
    "The transfer extract includes vocabulary help for less familiar terms.",
    "Each typed response has its own expected word range shown before the learner types.",
    "Accept alternative interpretations when they are supported by accurate evidence and context.",
    "Review keyboard navigation, focus visibility, screen-reader order, zoom/reflow, visual contrast and mobile layout before release.",
  ],
  remainingReleaseChecks: [
    "Complete fresh human academic review for version 3, including the item-level answer rationale, every option rationale, model response, response-quality bands and feedback. AI-assisted drafting is not academic validation.",
    "Keep official IB objective/strand mapping unverified and codes blank until the exact applicable current official guide supports them.",
    "Complete final unit-level rights review of both text excerpts, the photo, poster copy/layout and the exact text incorporated in the public build.",
    "Complete age/level and contextual suitability review, including vocabulary and syntax scaffolding.",
    "Complete accessibility review, including screen-reader labels/order, keyboard access, zoom/reflow and mobile layout.",
    "Keep answer keys and model responses out of the client build and verify the separation in production output.",
    "Record explicit founder release approval only after all independent gates are complete.",
  ],
  releaseNote:
    "Version 3 is an unreleased candidate awaiting fresh founder and human academic review. Version 2 founder approval and version 1 pilot-preview academic approval do not transfer. Official Year 1 mapping remains unverified. Source-level public-domain checks are documented; the separate unit-level rights, accessibility, age/level suitability and release gates remain open.",
};
