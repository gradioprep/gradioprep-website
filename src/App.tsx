import { useEffect, useState, type ReactNode } from "react";
import { demoQuestionItems } from "./content/demoCatalog";
import { englishPathways } from "./content/pathways";
import { pilotReviewSummary } from "./content/pilotReviewSummary";
import { pilotLearnerLesson } from "./content/pilotLearnerLesson";
import { getUnitReadinessGates, getUnitReadinessSummary, unitContentPlans } from "./content/unitReadiness";

type Page = "home" | "dashboard" | "pathways" | "lesson" | "questions" | "assessment";
type Navigate = (page: Page) => void;

type PathwaysLocation =
  | { type: "pathways"; view: "catalogue" }
  | { type: "pathways"; view: "curriculum"; courseCode: string }
  | { type: "pathways"; view: "level"; courseCode: string; pathwayId: string }
  | { type: "pathways"; view: "unit"; courseCode: string; pathwayId: string; unitId: string };

type AppRoute =
  | { type: "home" }
  | { type: "page"; page: "dashboard" | "questions" | "assessment" }
  | PathwaysLocation
  | { type: "lesson"; pathwayId: string; unitId: string }
  | { type: "not-found" };

type NavigatePath = (path: string) => void;

const sections: { page: Page; label: string; icon: string }[] = [
  { page: "dashboard", label: "Overview", icon: "⌂" },
  { page: "pathways", label: "Pathways", icon: "⌁" },
  { page: "questions", label: "Question bank", icon: "▤" },
  { page: "lesson", label: "Lessons & practice", icon: "↗" },
  { page: "assessment", label: "Assessment feedback", icon: "◎" },
];


const courseChoices = [
  {
    code: "ib-myp-language-literature",
    path: "ib-myp/language-and-literature",
    programmeCode: "ib-myp",
    taxonomy: "IB MYP",
    title: "Language and Literature",
    levelSummary: "Years 1–5",
    description: "Explore reading, interpretation and purposeful writing through the IB Middle Years Programme.",
    caveat: "Grade equivalents are navigation aids only. Applicable guide edition and objective mapping remain unverified.",
    groupClass: "taxonomy-ib",
  },
  {
    code: "cambridge-lower-secondary-english",
    path: "cambridge-lower-secondary/english",
    programmeCode: "cambridge-lower-secondary",
    taxonomy: "Cambridge Lower Secondary",
    title: "English",
    levelSummary: "Stages 7–9",
    description: "Build core English skills through the Cambridge Lower Secondary route, kept distinct from IGCSE.",
    caveat: "Applicable curriculum framework and official learning-objective references remain to be verified.",
    groupClass: "taxonomy-lower-secondary",
  },
  {
    code: "cambridge-igcse-first-language-english",
    path: "cambridge-igcse/first-language-english",
    programmeCode: "cambridge-igcse",
    taxonomy: "Cambridge IGCSE",
    title: "First Language English",
    levelSummary: "Syllabus edition and level structure to be confirmed",
    description: "Explore the First Language English route without treating provisional grade bands as separate qualifications.",
    caveat: "The applicable syllabus edition and mapping are unverified; grade-equivalent bands are navigation aids only.",
    groupClass: "taxonomy-igcse",
  },
];

function coursePathForCode(courseCode: string): string {
  const course = courseChoices.find(item => item.code === courseCode);
  return course ? `/pathways/${course.path}` : "/pathways";
}

function pathwayPathForId(pathwayId: string): string {
  const pathway = englishPathways.find(item => item.id === pathwayId);
  return pathway ? `${coursePathForCode(pathway.courseCode)}/${pathway.levelCode}` : "/pathways";
}

function unitPathForId(pathwayId: string, unitId: string): string {
  const pathway = englishPathways.find(item => item.id === pathwayId);
  const unit = pathway?.unitSlots.find(item => item.id === unitId);
  return pathway && unit ? `${pathwayPathForId(pathway.id)}/units/unit-${unit.sequence}` : "/pathways";
}

function lessonPathForId(pathwayId: string, unitId: string): string {
  return `${unitPathForId(pathwayId, unitId)}/lesson`;
}

function pilotLessonRoute(): AppRoute {
  const pathway = englishPathways.find(item => item.unitSlots.some(unit => unit.id === pilotReviewSummary.unitId));
  const unit = pathway?.unitSlots.find(item => item.id === pilotReviewSummary.unitId);
  return pathway && unit ? { type: "lesson", pathwayId: pathway.id, unitId: unit.id } : { type: "not-found" };
}

function pathnameForPage(page: Page): string {
  if (page === "home") return "/";
  if (page === "pathways") return "/pathways";
  if (page === "lesson") {
    const pilot = pilotLessonRoute();
    return pilot.type === "lesson" ? lessonPathForId(pilot.pathwayId, pilot.unitId) : "/pathways";
  }
  return `/${page}`;
}

function resolvePathname(pathname: string): AppRoute {
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) return { type: "home" };

  if (segments.length === 1) {
    const segment = segments[0];
    if (segment === "pathways") return { type: "pathways", view: "catalogue" };
    if (segment === "lesson") return pilotLessonRoute();
    if (segment === "dashboard" || segment === "questions" || segment === "assessment") {
      return { type: "page", page: segment };
    }
    return { type: "not-found" };
  }

  if (segments[0] !== "pathways" || segments.length < 3) return { type: "not-found" };

  const course = courseChoices.find(item => item.path === segments.slice(1, 3).join("/"));
  if (!course) return { type: "not-found" };
  if (segments.length === 3) return { type: "pathways", view: "curriculum", courseCode: course.code };

  const pathway = englishPathways.find(item =>
    item.courseCode === course.code &&
    item.levelCode === segments[3] &&
    item.levelKind === "official-programme-level"
  );
  if (!pathway) return { type: "not-found" };
  if (segments.length === 4) {
    return { type: "pathways", view: "level", courseCode: course.code, pathwayId: pathway.id };
  }
  if (segments[4] !== "units") return { type: "not-found" };

  const unit = pathway.unitSlots.find(item => `unit-${item.sequence}` === segments[5]);
  if (!unit) return { type: "not-found" };
  if (segments.length === 6) {
    return { type: "pathways", view: "unit", courseCode: course.code, pathwayId: pathway.id, unitId: unit.id };
  }
  if (segments.length === 7 && segments[6] === "lesson" && unit.id === pilotReviewSummary.unitId) {
    return { type: "lesson", pathwayId: pathway.id, unitId: unit.id };
  }
  return { type: "not-found" };
}

function Notice({ compact = false }: { compact?: boolean }) {
  return <div className={"proto-notice" + (compact ? " compact" : "")}><span /> <b>PROTOTYPE</b><i>/</i> Sample content and fictional learner data</div>;
}
function Logo({ onClick }: { onClick: () => void }) {
  return <button className="proto-logo" type="button" onClick={onClick} aria-label="Criterion Lab home"><span className="proto-logo-mark"><i /><i /><i /><i /></span><span><b>criterion lab</b><small>IB & CAMBRIDGE LEARNING</small></span></button>;
}
function Action({ children, onClick, secondary = false }: { children: ReactNode; onClick: () => void; secondary?: boolean }) {
  return <button type="button" onClick={onClick} className={"proto-action" + (secondary ? " secondary" : "")}>{children}</button>;
}
function Label({ children }: { children: ReactNode }) { return <p className="proto-eyebrow"><span />{children}</p>; }

function Home({ go }: { go: Navigate }) {
  return <div className="proto-public">
    <Notice />
    <header className="proto-header"><div className="proto-container proto-header-inner"><Logo onClick={() => go("home")} /><nav><a href="#proto-pathways">Pathways</a><a href="#proto-approach">Our approach</a><a href="#proto-first">What's coming</a></nav><Action secondary onClick={() => go("dashboard")}>Student preview ↗</Action></div></header>
    <main>
      <section className="proto-hero"><div className="proto-container proto-hero-grid"><div><Label>LEARNING, WITH DIRECTION</Label><h1>Make your next step a <em>smarter one.</em></h1><p className="proto-lead">A more considered way to learn English across IB MYP and Cambridge pathways. Practise with purpose, understand your gaps and build on what you know.</p><div className="proto-actions"><Action onClick={() => go("questions")}>Explore the question bank <span>→</span></Action><button className="proto-inline" type="button" onClick={() => document.getElementById("proto-approach")?.scrollIntoView({ behavior: "smooth" })}>Our approach ↘</button></div><div className="proto-proof"><span>✳</span><div><b>Learning that moves you forward.</b><small>Clear objectives. Useful practice. Feedback with a purpose.</small></div></div></div>
        <div className="proto-hero-art"><div className="proto-orbit one" /><div className="proto-orbit two" /><section className="proto-journey"><div className="proto-overline"><span>YOUR LEARNING JOURNEY</span><span>01 — 03</span></div><div className="proto-journey-title"><span>↗</span><div><small>A ROUTE THAT MAKES SENSE</small><h2>Progress, in practice.</h2></div></div><div className="proto-journey-row"><span>01</span><div><b>Understand the skill</b><small>Know what you're learning and why.</small></div><i className="done">✓</i></div><div className="proto-journey-row"><span>02</span><div><b>Practise with purpose</b><small>Try questions connected to that skill.</small></div><i>02</i></div><div className="proto-journey-row"><span>03</span><div><b>Choose your next step</b><small>Use evidence and feedback to improve.</small></div><i>03</i></div><div className="proto-journey-footer">✳ &nbsp; Designed for progress, not guesswork.</div></section><div className="proto-floating-note"><span>↗</span><div><b>Small steps.</b><small>Meaningful progress.</small></div></div></div></div><div className="proto-ribbon"><span>LEARN WITH PURPOSE</span><i /><span>GROW WITH EVIDENCE</span><i /><span>KEEP MOVING FORWARD</span></div></section>
      <section className="proto-pathways proto-section" id="proto-pathways"><div className="proto-container"><div className="proto-section-heading"><div><Label>START WITH THE RIGHT PATH</Label><h2>The right route starts<br />with <em>your world.</em></h2></div><p>Different programmes have different expectations. Start with the pathway that matches your curriculum—not a one-size-fits-all course.</p></div><div className="proto-pathway-groups">
        <section className="proto-pathway-group ib-pathway-group">
          <div className="proto-pathway-band"><div className="proto-pathway-symbol" aria-hidden="true"><span>IB</span><i>✳</i></div><div><small>PATHWAY 01 · INTERNATIONAL BACCALAUREATE</small><h3>IB Middle Years Programme</h3><p>Explore Language & Literature through inquiry, interpretation and thoughtful communication.</p></div><span className="proto-pathway-band-arrow" aria-hidden="true">↗</span></div>
          <div className="proto-pathway-grid ib-grid"><article><div><span>01</span><b>IB MYP</b></div><h3>Language & Literature</h3><small>Years 1–5</small><p>Build confidence in reading, interpretation and purposeful writing through a clearly mapped learning route.</p><button type="button" onClick={() => go("pathways")}>Explore IB pathways <span>↗</span></button></article></div>
        </section>
        <section className="proto-pathway-group cambridge-pathway-group">
          <div className="proto-pathway-band"><div className="proto-pathway-symbol" aria-hidden="true"><span>C</span><i>✦</i></div><div><small>PATHWAY 02 · CAMBRIDGE INTERNATIONAL</small><h3>Cambridge English</h3><p>Choose the stage that fits your learning journey, from core skills to exam preparation.</p></div><span className="proto-pathway-band-arrow" aria-hidden="true">↗</span></div>
          <div className="proto-pathway-grid cambridge-grid"><article><div><span>02</span><b>CAMBRIDGE</b></div><h3>Lower Secondary English</h3><small>Stages 7–9</small><p>Strengthen core English skills with practice organised around the learning objectives that matter.</p><button type="button" onClick={() => go("pathways")}>Explore Cambridge <span>↗</span></button></article><article><div><span>03</span><b>CAMBRIDGE IGCSE</b></div><h3>First Language English</h3><small>Grade 9–10 equivalent pathways</small><p>Work towards the relevant syllabus through purposeful practice and carefully checked mapping.</p><button type="button" onClick={() => go("pathways")}>Explore Cambridge <span>↗</span></button></article></div>
        </section>
      </div><p className="proto-fineprint">Stage 1 is a starter pathway, not exhaustive syllabus coverage. Curriculum mapping must be verified before content is published.</p></div></section>
      <section className="proto-approach proto-section" id="proto-approach"><div className="proto-container proto-approach-grid"><div><Label>WHY THIS PLATFORM</Label><h2>More than a library.<br /><em>A clearer next step.</em></h2><p>Finding notes is only the beginning. The aim is to connect the syllabus, a specific skill, deliberate practice and useful feedback in one learning space.</p><Action secondary onClick={() => go("lesson")}>Preview a lesson →</Action></div><div className="proto-principles"><article><span>01</span><i>⌖</i><div><b>Find your bearings</b><p>Start with your programme, stage and the skill you want to build.</p></div></article><article><span>02</span><i>↗</i><div><b>Practise with purpose</b><p>Use focused questions, annotated examples and clear explanations.</p></div></article><article><span>03</span><i>✳</i><div><b>Learn from evidence</b><p>Use saved attempts and meaningful feedback to decide what comes next.</p></div></article></div></div></section>
      <section className="proto-release" id="proto-first"><div className="proto-container proto-release-panel"><div><Label>THE FIRST RELEASE</Label><h2>English first.<br /><em>Built thoughtfully.</em></h2></div><div><p>The initial build focuses on English pathways, verified curriculum mapping, purposeful practice and a clear foundation for learner progress. Mathematics is planned for a later phase.</p><small>This preview contains sample content only. Real accounts, learning tools and connected progress tracking are still in development.</small><Action onClick={() => go("dashboard")}>Explore student preview ↗</Action></div></div></section>
    </main>
    <footer className="proto-public-footer"><div className="proto-container"><Logo onClick={() => go("home")} /><p>Know what to practise next—and see whether you have improved.</p><small>EARLY BUILD · WORKING NAME</small></div></footer>
  </div>;
}

function Shell({ page, go, children, context }: { page: Page; go: Navigate; children: ReactNode; context?: string }) {
  return <div className="proto-app"><Notice compact /><div className="proto-app-layout"><aside className="proto-sidebar"><Logo onClick={() => go("home")} /><div className="proto-workspace">LEARNING SPACE <span>DEMO</span></div><nav aria-label="Student preview navigation">{sections.map(s => <button type="button" key={s.page} className={page === s.page ? "active" : ""} onClick={() => go(s.page)}><i>{s.icon}</i>{s.label}{page === s.page && <b />}</button>)}</nav><div className="proto-sidebar-bottom"><strong>✳ &nbsp; Keep moving forward.</strong><p>Every attempt can teach you something.</p><button type="button" onClick={() => go("home")}>↖ &nbsp; Public homepage</button></div></aside><div className="proto-app-main"><header className="proto-app-header"><div>Learning space <span>/</span> <b>{sections.find(s => s.page === page)?.label ?? "Preview"}</b></div><small>{context ?? "English · Stage 1 preview"}</small><i>D</i></header><main className="proto-app-content">{children}<footer className="proto-app-footer"><span>CRITERION LAB · DESIGN PROTOTYPE</span><span>Fictional data · No real learner records</span></footer></main></div></div></div>;
}
function PageIntro({ eyebrow, title, subtitle }: { eyebrow: string; title: ReactNode; subtitle: string }) {
  return <div className="proto-page-intro"><Label>{eyebrow}</Label><h1>{title}</h1><p>{subtitle}</p></div>;
}
function InfoNote({ children }: { children: ReactNode }) { return <div className="proto-info-note"><span>i</span><p>{children}</p></div>; }

type StepNavigationDestination =
  | { label: string; path: string }
  | { label: string; unavailableReason: string };

function PathwayStepNavigation({
  previous,
  next,
  navigatePath,
}: {
  previous: { label: string; path: string };
  next: StepNavigationDestination;
  navigatePath: NavigatePath;
}) {
  return <nav className="proto-bottom-actions proto-pathway-navigation" aria-label="Pathway step navigation">
    <button type="button" className="proto-action secondary" onClick={() => navigatePath(previous.path)}>
      <small className="proto-step-kicker">PREVIOUS STEP</small>
      <b>← Back to {previous.label}</b>
    </button>
    {"path" in next
      ? <button type="button" className="proto-action" onClick={() => navigatePath(next.path)}>
          <small className="proto-step-kicker">NEXT STEP</small>
          <b>Continue to {next.label} →</b>
        </button>
      : <div className="proto-pathway-next-unavailable" aria-label={next.label}>
          <small className="proto-step-kicker">NEXT STEP</small>
          <b>{next.label}</b>
          <p>{next.unavailableReason}</p>
        </div>}
  </nav>;
}

function Dashboard({ go }: { go: Navigate }) {
  return <Shell page="dashboard" go={go}><InfoNote><b>Demonstration dashboard.</b> All learner activity and numbers below are fictional examples to show the intended experience.</InfoNote><PageIntro eyebrow="YOUR LEARNING AT A GLANCE" title={<>A clearer picture of <em>your progress.</em></>} subtitle="A considered overview of what you have practised, where you are building confidence and what may be useful next." /><section className="proto-welcome"><div><small>YOUR NEXT STEP</small><h2>Keep building your writer's voice.</h2><p>Pick up with a short lesson on how deliberate language choices create tone.</p><Action onClick={() => go("lesson")}>Continue learning →</Action></div><div className="proto-welcome-art"><span>Aa</span><small>WORDS WITH PURPOSE</small></div></section><div className="proto-section-title"><div><h2>Your learning snapshot</h2><p>Example measures from a fictional demo learner.</p></div><small>THIS MONTH · SAMPLE</small></div><div className="proto-metrics"><article><i>⌖</i><small>SKILLS EXPLORED</small><strong>12</strong><span>Across 3 example units</span></article><article><i>↗</i><small>PRACTICE ATTEMPTS</small><strong>28</strong><span>Across reading and writing</span></article><article><i>⟳</i><small>REVISED RESPONSES</small><strong>6</strong><span>Saved revisions in this example</span></article></div><div className="proto-dash-grid"><section className="proto-panel"><div className="proto-panel-heading"><div><h2>Skills in focus</h2><p>Example statuses, with their evidence.</p></div><button type="button" onClick={() => go("questions")}>Find practice ↗</button></div><div className="proto-skill-row"><i className="good">✓</i><div><b>Selecting textual evidence</b><small>Consistent results across recent demo attempts.</small></div><span className="green-status">Building confidence</span></div><div className="proto-skill-row"><i className="warm">↗</i><div><b>Explaining language choices</b><small>Some explanations need clearer links to effect.</small></div><span className="warm-status">In progress</span></div><div className="proto-skill-row"><i>○</i><div><b>Structuring an argument</b><small>Not enough evidence to assess this skill yet.</small></div><span>Not assessed</span></div><p className="proto-note-bottom">In a live product, every skill status must be backed by defined rules and recorded learner evidence.</p></section><section className="proto-panel"><div className="proto-panel-heading"><div><h2>Suggested next</h2><p>Reasoned from this demo profile.</p></div><span className="proto-spark">✳</span></div><div className="proto-recommend"><small>12 MIN · GUIDED ANALYSIS</small><h3>How language shapes tone</h3><p>Practise linking a writer's choice to the effect it creates, using precise evidence.</p><Action onClick={() => go("lesson")}>Try this activity →</Action></div><button type="button" className="proto-wide-link" onClick={() => go("assessment")}>View example assessment feedback ↗</button></section></div><section className="proto-panel proto-activity"><div className="proto-panel-heading"><div><h2>Recent activity</h2><p>A short history from this fictional account.</p></div><button type="button" onClick={() => go("questions")}>Browse questions ↗</button></div>{[{t:"Read between the lines",m:"Inference and evidence · Practice",s:"Completed"},{t:"How language shapes tone",m:"Writer's choices · Guided analysis",s:"In progress"},{t:"Build a purposeful opening",m:"Structure and audience · Writing",s:"Saved draft"}].map(item => <button type="button" className="proto-activity-row" key={item.t} onClick={() => go(item.s === "Completed" ? "questions" : "lesson")}><i>{item.s === "Completed" ? "✓" : item.s === "In progress" ? "↗" : "○"}</i><span><b>{item.t}</b><small>{item.m}</small></span><em>{item.s}</em><strong>↗</strong></button>)}</section></Shell>;
}

function Lesson({ go, navigatePath, pathwayId, unitId }: { go: Navigate; navigatePath: NavigatePath; pathwayId: string; unitId: string }) {
  const pathway = englishPathways.find(item => item.id === pathwayId) ?? englishPathways[0];
  const unit = pathway.unitSlots.find(item => item.id === unitId) ?? pathway.unitSlots[0];
  const curriculumPath = coursePathForCode(pathway.courseCode);
  const levelPath = pathwayPathForId(pathway.id);
  const unitPath = unitPathForId(pathway.id, unit.id);
  const curriculumContext = `${pathway.programmeName} · ${pathway.courseName} · ${pathway.levelLabel} · Unit ${unit.sequence}`;
  const lesson = pilotLearnerLesson;
  const [entryResponse, setEntryResponse] = useState("");
  const [entryReviewed, setEntryReviewed] = useState(false);
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>({});
  const [responses, setResponses] = useState<Record<string, string>>({});
  const [attempted, setAttempted] = useState<Record<string, boolean>>({});
  const [exitResponse, setExitResponse] = useState("");
  const [exitReviewed, setExitReviewed] = useState(false);
  const attemptedCount = Object.values(attempted).filter(Boolean).length + (entryReviewed ? 1 : 0) + (exitReviewed ? 1 : 0);

  const updateResponse = (id: string, value: string) => {
    setResponses(previous => ({ ...previous, [id]: value }));
    setAttempted(previous => ({ ...previous, [id]: false }));
  };

  const canReview = (item: typeof lesson.practiceItems[number]) =>
    item.options ? Boolean(selectedOptions[item.id]) : Boolean(responses[item.id]?.trim());

  return <Shell page="lesson" go={go} context={curriculumContext}>
    <InfoNote>
      {lesson.reviewRecord.outcome === "passed"
        ? <><b>Academic content review passed.</b> This version is approved for pilot preview only. Official Year 1 mapping and release approval remain open.</>
        : <><b>Unit 1 version {lesson.version} is awaiting founder review.</b> Version 1's preview approval does not automatically apply to this revision. Official Year 1 mapping and release approval remain open.</>}
      {" "}Practice responses are temporary to this open preview; nothing is saved or graded.
    </InfoNote>
    <div className="proto-crumb"><button type="button" onClick={() => navigatePath("/pathways")}>Pathways</button> / <button type="button" onClick={() => navigatePath(curriculumPath)}>{pathway.programmeName} · {pathway.courseName}</button> / <button type="button" onClick={() => navigatePath(levelPath)}>{pathway.levelLabel}</button> / <button type="button" onClick={() => navigatePath(unitPath)}>Unit {unit.sequence}</button> / <b>Lesson</b></div>
    <div className="proto-lesson-head">
      <div>
        <Label>IB MYP LANGUAGE & LITERATURE · UNIT 1 REVIEW PREVIEW</Label>
        <h1>Notice the choice.<br /><em>Explain the effect.</em></h1>
        <p>{lesson.proposedLearningObjective}</p>
      </div>
      <div className="proto-progress">
        <small>LESSON VERSION</small>
        <b>{String(lesson.version).padStart(2, "0")} <span>· {lesson.estimatedMinutes} min</span></b>
        <div><i style={{ width: "100%" }} /></div>
        <small>{lesson.reviewRecord.outcome === "passed" && lesson.reviewRecord.reviewedAt ? `Reviewed ${lesson.reviewRecord.reviewedAt}` : "Founder review pending"} · Not saved</small>
      </div>
    </div>

    <section className="proto-panel proto-pilot-learner-summary">
      <div className="proto-panel-heading">
        <div><h2>What success looks like</h2><p>Use these as you read, practise and review your own responses.</p></div>
        <span>{lesson.reviewRecord.outcome === "passed" ? `PREVIEW V${lesson.version}` : `DRAFT V${lesson.version} · REVIEW PENDING`}</span>
      </div>
      {lesson.successCriteria.map((item,index) => <div className="proto-skill-row proto-readiness-row" key={item}><i>{String(index+1).padStart(2,"0")}</i><div><b>{item}</b></div></div>)}
    </section>

    <div className="proto-learning-route" aria-label="Lesson steps">
      <div className="route-read"><span>01</span><i aria-hidden="true">▤</i><b>Read + view</b><small>Notice choices</small></div>
      <div className="route-connector" aria-hidden="true">→</div>
      <div className="route-idea"><span>02</span><i aria-hidden="true">✦</i><b>The idea</b><small>Spot the pattern</small></div>
      <div className="route-connector" aria-hidden="true">→</div>
      <div className="route-move"><span>03</span><i aria-hidden="true">↗</i><b>Learn the move</b><small>Try it yourself</small></div>
    </div>
    <div className="proto-lesson-grid proto-pilot-learner-grid">
      <div>
        <section className="proto-panel proto-explanation proto-learning-stage stage-read">
          <Label>01 · READ THE PASSAGE</Label>
          <h2>{lesson.passage.label}</h2>
          <blockquote className="proto-pilot-passage">{lesson.passage.text}</blockquote>
          <p className="proto-unit-readiness-intro">{lesson.passage.rightsNote}</p>
          <figure className="proto-pilot-poster">
            <div className="proto-pilot-poster-card">
              <p className="proto-pilot-poster-kicker">{lesson.companionArtifact.kicker}</p>
              <h3>{lesson.companionArtifact.headline}</h3>
              <div className="proto-pilot-poster-photo-wrap">
                <img
                  className="proto-pilot-poster-photo"
                  src="https://images.pexels.com/photos/19092243/pexels-photo-19092243/free-photo-of-people-on-a-bus-stop-at-night.jpeg?auto=compress&dpr=1&h=750&w=1260"
                  alt={lesson.companionArtifact.altText}
                  loading="lazy"
                  decoding="async"
                />
              </div>
              <p className="proto-pilot-poster-supporting">{lesson.companionArtifact.supportingText}</p>
              <p className="proto-pilot-poster-footer">{lesson.companionArtifact.footerText}</p>
            </div>
            <figcaption>Notice how the illuminated shelter and waiting passengers contrast with the dark street and reflections on wet pavement.</figcaption>
            <p className="proto-unit-readiness-intro">{lesson.companionArtifact.rightsNote}</p>
          </figure>
        </section>
        <section className="proto-panel proto-pilot-entry-check">
          <Label>STARTING POINT · NOT GRADED</Label>
          <h2>What do you notice first?</h2>
          <p>{lesson.entryCheck.prompt}</p>
          <label className="proto-pilot-response-label">Your first observation
            <textarea rows={3} value={entryResponse} onChange={event => { setEntryResponse(event.target.value); setEntryReviewed(false); }} placeholder={lesson.entryCheck.placeholder} />
          </label>
          <div className="proto-pilot-question-footer">
            <small>{entryReviewed ? "STARTING THOUGHT REVIEWED" : "NOT YET REVIEWED"}</small>
            <button type="button" className="proto-action secondary" disabled={!entryResponse.trim()} onClick={() => setEntryReviewed(true)}>Review my observation</button>
          </div>
          {entryReviewed && <div className="proto-answer-feedback right"><b>Check your starting point</b><ul>{lesson.entryCheck.successIndicators.map(point => <li key={point}>{point}</li>)}</ul><p>Keep this first thought. You can revisit it after the model and practice.</p></div>}
        </section>
        <section className="proto-panel proto-explanation proto-learning-stage stage-idea">
          <Label>02 · THE IDEA</Label>
          <h2>{lesson.keyIdea.label}</h2>
          <div className="proto-pilot-evidence-chain">
            {lesson.keyIdea.pattern.map((step,index)=><div key={step}><i>{index+1}</i><p>{step}</p></div>)}
          </div>
          <p>{lesson.keyIdea.explanation}</p>
        </section>

        <section className="proto-panel proto-pilot-learning-steps proto-learning-stage stage-move">
          <Label>03 · LEARN THE MOVE</Label>
          <h2>Work through the sequence</h2><p className="proto-stage-helper">Three small moves. Take them one at a time.</p>
          {lesson.sections.map(section => <article className="proto-pilot-section" key={section.id}>
            <h3>{section.heading}</h3>
            <p className="proto-pilot-purpose">{section.purpose}</p>
            <p>{section.explanation}</p>
            {section.example && <div className="proto-pilot-example"><small>{section.example.label.toUpperCase()}</small><blockquote>{section.example.text}</blockquote><p>{section.example.explanation}</p></div>}
            <div className="proto-pilot-action"><b>Try this</b><p>{section.learnerAction}</p></div>
          </article>)}
        </section>

        <section className="proto-panel proto-pilot-practice">
          <div className="proto-panel-heading">
            <div><Label>04 · FORMATIVE PRACTICE</Label><h2>Put the idea to work</h2><p>{attemptedCount} of {lesson.practiceItems.length+2} activities reviewed in this open preview</p></div>
            <span>NOT GRADED</span>
          </div>
          <p className="proto-unit-readiness-intro">Choose an option or write your response, then check the success indicators. This preview does not mark correctness, retain your work or send it anywhere.</p>
          {lesson.practiceItems.map((item,index)=><article className="proto-pilot-question" key={item.id}>
            <div className="proto-pilot-question-head"><span>{String(index+1).padStart(2,"0")}</span><div><small>{item.focus}</small><h3>{item.prompt}</h3></div></div>
            {item.options && <div className="proto-pilot-options">
              {item.options.map(option=><button type="button" key={option.id} aria-pressed={selectedOptions[item.id]===option.id} className={"proto-pilot-option-button"+(selectedOptions[item.id]===option.id?" is-selected":"")} onClick={()=>{setSelectedOptions(previous=>({...previous,[item.id]:option.id}));setAttempted(previous=>({...previous,[item.id]:false}));}}>
                <b>{option.id}</b><span>{option.text}</span>
              </button>)}
            </div>}
            {!item.options && <label className="proto-pilot-response-label">Your response
              <textarea rows={4} value={responses[item.id]??""} onChange={event=>updateResponse(item.id,event.target.value)} placeholder="Write your explanation here..." />
            </label>}
            <div className="proto-pilot-question-footer">
              <small>{attempted[item.id]?"REVIEWED IN THIS SESSION":"NOT YET REVIEWED"}</small>
              <button type="button" className="proto-action secondary" disabled={!canReview(item)} onClick={()=>setAttempted(previous=>({...previous,[item.id]:true}))}>Review my thinking</button>
            </div>
            {attempted[item.id] && <div className="proto-answer-feedback right"><b>Use the success indicators</b><p>Your response has not been scored. Check each point below and revise your answer if it would make your reasoning clearer.</p><ul>{item.successIndicators.map(point=><li key={point}>{point}</li>)}</ul><p>Different interpretations can be valid when they are supported by evidence.</p></div>}
          </article>)}
        </section>

        <section className="proto-panel proto-pilot-exit">
          <Label>05 · EXIT TICKET</Label>
          <h2>Try the thinking move independently</h2>
          <div className="proto-pilot-transfer-stimulus">
            <small>{lesson.exitTicket.stimulus.label}</small>
            <blockquote>{lesson.exitTicket.stimulus.text}</blockquote>
            <p>{lesson.exitTicket.stimulus.rightsNote}</p>
          </div>
          <p>{lesson.exitTicket.prompt}</p>
          <label className="proto-pilot-response-label">Your exit response
            <textarea rows={5} value={exitResponse} onChange={event=>{setExitResponse(event.target.value);setExitReviewed(false);}} placeholder="Use precise evidence, explain what it may suggest, and connect it to the context..." />
          </label>
          <div className="proto-pilot-question-footer">
            <small>{exitReviewed?"CHECKLIST OPENED":"SELF-REVIEW AVAILABLE"}</small>
            <button type="button" className="proto-action" disabled={!exitResponse.trim()} onClick={()=>setExitReviewed(true)}>Review exit response</button>
          </div>
          {exitReviewed && <div className="proto-answer-feedback right"><b>Self-review checklist</b><ul>{lesson.exitTicket.successIndicators.map(point=><li key={point}>{point}</li>)}</ul><p>This is a checklist, not a mark or a saved assessment.</p></div>}
        </section>
        <PathwayStepNavigation
          previous={{ label: `Unit ${unit.sequence}`, path: unitPath }}
          next={{
            label: "More lessons are not available yet",
            unavailableReason: "Only the reviewed pilot lesson is available in this preview. Additional lessons must be prepared and reviewed before they can be added.",
          }}
          navigatePath={navigatePath}
        />
        <div className="proto-bottom-actions proto-pathway-extra-actions"><Action onClick={() => go("questions")}>Explore more practice →</Action></div>
      </div>
      <aside className="proto-panel proto-lesson-aside">
        <Label>IN THIS LESSON</Label>
        {lesson.sections.map((section,index)=><div className="proto-outline-row" key={section.id}><i>{String(index+1).padStart(2,"0")}</i><span><b>{section.heading.replace(/^\d+\.\s*/,"")}</b><small>{section.purpose}</small></span></div>)}
        <div className="proto-aside-tip"><span>Aa</span><b>Keep the evidence chain visible</b><p>Choice → association → effect in context. A quotation is the start of your explanation, not the whole explanation.</p></div>
        <div className="proto-aside-tip"><span>i</span><b>About this version</b><p>{lesson.reviewRecord.outcome === "passed" ? `Academic content review passed on ${lesson.reviewRecord.reviewedAt}; the content is preview-only.` : `Version ${lesson.version} is awaiting founder review. Version 1's approval does not transfer to this revision.`} Official curriculum mapping is unverified.</p></div>
        <p className="proto-note-bottom">{lesson.learnerNote}</p>
      </aside>
    </div>
  </Shell>;
}

function Pathways({ go, route, navigatePath }: { go: Navigate; route: PathwaysLocation; navigatePath: NavigatePath }) {
  const view = route.view;
  const selectedCourseCode = route.view === "catalogue" ? courseChoices[0].code : route.courseCode;
  const selectedPathwayId = route.view === "level" || route.view === "unit" ? route.pathwayId : "ib-myp-lal-y1";
  const selectedUnitId = route.view === "unit"
    ? route.unitId
    : englishPathways.find(item => item.id === selectedPathwayId)?.unitSlots[0]?.id ?? "ib-myp-lal-y1-u1";

  const selectedPathway = englishPathways.find(item => item.id === selectedPathwayId) ?? englishPathways[0];
  const selectedUnit = selectedPathway.unitSlots.find(item => item.id === selectedUnitId) ?? selectedPathway.unitSlots[0];
  const selectedCourse = courseChoices.find(item => item.code === selectedCourseCode) ?? courseChoices[0];
  const selectedPlan = unitContentPlans.find(plan => plan.unitId === selectedUnit?.id);
  const readinessGates = selectedPlan ? getUnitReadinessGates(selectedPlan) : [];
  const readiness = selectedPlan ? getUnitReadinessSummary(selectedPlan) : { complete: 0, total: 0, releasable: false };
  const coursePathways = englishPathways.filter(item => item.courseCode === selectedCourseCode);
  const supportedCoursePathways = coursePathways.filter(item => item.levelKind === "official-programme-level");
  const firstSupportedPathway = supportedCoursePathways[0];
  const previousUnit = selectedPathway.unitSlots.find((item, index) => item.id === selectedUnit?.id && index > 0)
    ? selectedPathway.unitSlots[selectedPathway.unitSlots.findIndex(item => item.id === selectedUnit?.id) - 1]
    : undefined;
  const selectedUnitIndex = selectedPathway.unitSlots.findIndex(item => item.id === selectedUnit?.id);
  const nextUnit = selectedUnitIndex >= 0 ? selectedPathway.unitSlots[selectedUnitIndex + 1] : undefined;
  const isPilotUnit = selectedUnit?.id === pilotReviewSummary.unitId;



  const openCurriculum = (courseCode: string) => navigatePath(coursePathForCode(courseCode));

  const openLevel = (pathwayId: string) => {
    const pathway = englishPathways.find(item => item.id === pathwayId);
    if (!pathway || pathway.levelKind !== "official-programme-level") return;
    navigatePath(pathwayPathForId(pathway.id));
  };

  const openUnit = (unitId: string) => {
    const pathway = englishPathways.find(item => item.unitSlots.some(unit => unit.id === unitId));
    if (!pathway || pathway.levelKind !== "official-programme-level") return;
    navigatePath(unitPathForId(pathway.id, unitId));
  };

  const backToCatalogue = () => navigatePath("/pathways");
  const backToCurriculum = () => navigatePath(coursePathForCode(selectedPathway.courseCode));
  const backToLevel = () => navigatePath(pathwayPathForId(selectedPathway.id));

  const shellContext = view === "catalogue"
    ? "English pathways · Planning preview"
    : view === "curriculum"
      ? `${selectedCourse.taxonomy} · ${selectedCourse.title}`
      : `${selectedPathway.programmeName} · ${selectedPathway.courseName} · ${selectedPathway.levelLabel}`;

  return <Shell page="pathways" go={go} context={shellContext}>
    {view === "catalogue" && <>
      <InfoNote><b>Pathway catalogue — planning preview.</b> These are planned English routes, not released courses. Official syllabus editions and mappings remain unverified. Stage 1 is a starter pathway, not exhaustive syllabus coverage.</InfoNote>
      <PageIntro
        eyebrow="CHOOSE YOUR CURRICULUM"
        title={<>Start with the right <em>pathway.</em></>}
        subtitle="Compare the available curriculum routes. Choose a programme and subject to see the levels planned for that route."
      />
      <div className="proto-pathway-catalogue-groups">
        {courseChoices.map((course, index) => (
          <section className={"proto-pathway-catalogue-group " + course.groupClass} key={course.code}>
            <div className="proto-pathway-taxonomy" aria-label={course.taxonomy + " pathway group"}>
              <span aria-hidden="true">{String(index + 1).padStart(2, "0")}</span>
              <small>CURRICULUM TAXONOMY</small>
              <strong>{course.taxonomy}</strong>
              <i aria-hidden="true" />
            </div>
            <article className="proto-curriculum-card">
              <div className="proto-curriculum-card-top"><span>{course.taxonomy}</span><b>PLANNED ROUTE</b></div>
              <h2>{course.title}</h2>
              <p>{course.description}</p>
              <div className="proto-curriculum-card-meta"><span>{course.levelSummary}</span><span>{course.code === "cambridge-igcse-first-language-english" ? "Syllabus structure to be confirmed" : englishPathways.filter(item => item.courseCode === course.code).length + " planned levels"}</span></div>
              <p className="proto-curriculum-caveat">{course.caveat}</p>
              <button type="button" className="proto-action" onClick={() => openCurriculum(course.code)}>Explore this pathway <span>→</span></button>
            </article>
          </section>
        ))}
      </div>
    </>}

    {view === "curriculum" && <>
      <div className="proto-crumb"><button type="button" onClick={backToCatalogue}>Pathways</button> / <b>{selectedCourse.taxonomy} · {selectedCourse.title}</b></div>
      <InfoNote><b>Curriculum destination — planning preview.</b> These level choices describe planned navigation, not published or syllabus-mapped courses.</InfoNote>
      <PageIntro
        eyebrow={courseChoices.find(item => item.code === selectedCourseCode)?.taxonomy ?? "CURRICULUM"}
        title={<>{courseChoices.find(item => item.code === selectedCourseCode)?.title} <em>pathway.</em></>}
        subtitle={courseChoices.find(item => item.code === selectedCourseCode)?.description ?? "Explore the planned levels for this route."}
      />
      <section className="proto-curriculum-context-panel">
        <div><small>CURRICULUM ROUTE</small><h2>{courseChoices.find(item => item.code === selectedCourseCode)?.taxonomy} · {courseChoices.find(item => item.code === selectedCourseCode)?.title}</h2></div>
        <p>{courseChoices.find(item => item.code === selectedCourseCode)?.caveat}</p>
      </section>
      {coursePathways.some(pathway => pathway.levelKind === "official-programme-level") ? <div className="proto-level-grid">
        {coursePathways.filter(pathway => pathway.levelKind === "official-programme-level").map((pathway, index) => (
          <article className="proto-level-card" key={pathway.id}>
            <div className="proto-level-card-top"><span>{String(index + 1).padStart(2, "0")}</span><b>PLANNED</b></div>
            <h2>{pathway.levelLabel}</h2>
            {pathway.gradeEquivalentLabel && pathway.levelKind !== "navigation-only-grade-equivalent" && <p className="proto-level-equivalent">{pathway.gradeEquivalentLabel} · Navigation aid</p>}
            <p>{pathway.reviewNote}</p>
            <div className="proto-level-status"><span>Mapping</span><b>Unverified</b><span>Release</span><b>Planned</b></div>
            <button type="button" className="proto-action" onClick={() => openLevel(pathway.id)}>Explore {pathway.levelLabel} <span>→</span></button>
          </article>
        ))}
      </div> : <section className="proto-no-levels">
        <p className="proto-eyebrow"><span />LEVEL STRUCTURE NOT YET VERIFIED</p>
        <h2>Confirm the syllabus route before choosing a level.</h2>
        <p>The current planning data contains provisional grade-equivalent labels only. They are not separate qualifications or confirmed syllabus routes, so this prototype does not present them as independent levels.</p>
        <p>The applicable Cambridge IGCSE First Language English syllabus edition and any useful learner-navigation structure must be confirmed before level-specific plans are shown here.</p>
      </section>}
      <PathwayStepNavigation
        previous={{ label: "Pathways catalogue", path: "/pathways" }}
        next={firstSupportedPathway
          ? { label: firstSupportedPathway.levelLabel, path: pathwayPathForId(firstSupportedPathway.id) }
          : {
              label: "Levels are not available yet",
              unavailableReason: "The applicable IGCSE syllabus edition and level structure must be confirmed before level navigation is offered.",
            }}
        navigatePath={navigatePath}
      />
    </>}

    {view === "level" && <>
      <div className="proto-crumb"><button type="button" onClick={backToCatalogue}>Pathways</button> / <button type="button" onClick={backToCurriculum}>{selectedPathway.programmeName} · {selectedPathway.courseName}</button> / <b>{selectedPathway.levelLabel}</b></div>
      <InfoNote><b>Level plan — planning preview.</b> The unit sequence below is a planning structure, not an exhaustive syllabus map. No unit is presented as released unless its release requirements have been recorded.</InfoNote>
      <PageIntro
        eyebrow={selectedPathway.programmeName + " · " + selectedPathway.courseName}
        title={<>{selectedPathway.levelLabel} <em>learning plan.</em></>}
        subtitle="Review the planned sequence and its current content status. Curriculum mapping, content review and release approval are separate checks."
      />
      <section className="proto-curriculum-context-panel">
        <div><small>LEVEL CONTEXT</small><h2>{selectedPathway.programmeName} · {selectedPathway.courseName} · {selectedPathway.levelLabel}</h2></div>
        <div className="proto-level-status"><span>Official syllabus edition</span><b>Not assigned</b><span>Objective mapping</span><b>Unverified</b><span>Release</span><b>Planned</b></div>
        {selectedPathway.levelKind === "navigation-only-grade-equivalent" && <p>This grade-equivalent learning band is a provisional navigation aid only. It does not represent a separate qualification or syllabus route.</p>}
      </section>
      <div className="proto-unit-list-heading"><div><h2>Planned unit sequence</h2><p>Three planning slots are shown; this is not a claim of complete syllabus coverage.</p></div><span>3 PLANNING SLOTS</span></div>
      <div className="proto-level-unit-list">
        {selectedPathway.unitSlots.map(unit => (
          <article className="proto-level-unit-row" key={unit.id}>
            <span className="proto-level-unit-number">{String(unit.sequence).padStart(2, "0")}</span>
            <div><h3>{unit.title}</h3><p>{unit.reviewNote}</p><div className="proto-level-status compact"><span>Mapping</span><b>Unverified</b><span>Release</span><b>Planned</b>{unit.id === pilotReviewSummary.unitId && <b className="proto-review-status">{pilotReviewSummary.reviewRecord.outcome === "passed" ? "Academic review passed for pilot preview v" + pilotReviewSummary.version : "Unit 1 version 2 awaiting founder review"}</b>}</div></div>
            <button type="button" className="proto-text-link" onClick={() => openUnit(unit.id)}>{unit.id === pilotReviewSummary.unitId ? "View pilot unit" : "View unit details"} <span>↗</span></button>
          </article>
        ))}
      </div>
      <PathwayStepNavigation
        previous={{ label: `${selectedPathway.programmeName} · ${selectedPathway.courseName}`, path: coursePathForCode(selectedPathway.courseCode) }}
        next={selectedPathway.unitSlots[0]
          ? { label: `Unit ${selectedPathway.unitSlots[0].sequence}`, path: unitPathForId(selectedPathway.id, selectedPathway.unitSlots[0].id) }
          : {
              label: "Unit planning is not available yet",
              unavailableReason: "A unit sequence must be recorded before the next step can be opened.",
            }}
        navigatePath={navigatePath}
      />
    </>}

    {view === "unit" && selectedUnit && <>
      <div className="proto-crumb"><button type="button" onClick={backToCatalogue}>Pathways</button> / <button type="button" onClick={backToCurriculum}>{selectedPathway.programmeName} · {selectedPathway.courseName}</button> / <button type="button" onClick={backToLevel}>{selectedPathway.levelLabel}</button> / <b>Unit {selectedUnit.sequence}</b></div>
      <InfoNote><b>Unit detail — planning preview.</b> This view separates academic review, curriculum mapping, and release status. {isPilotUnit && pilotReviewSummary.status === "draft-for-founder-review" ? "Unit 1 version 2 is awaiting founder review; version 1's preview approval does not transfer to this revision." : "This lesson is available only as a pilot preview and is not an officially mapped or released course."}</InfoNote>
      <PageIntro
        eyebrow={selectedPathway.programmeName + " · " + selectedPathway.courseName + " · " + selectedPathway.levelLabel}
        title={<>{isPilotUnit ? pilotReviewSummary.title : "Unit " + selectedUnit.sequence} <em>{isPilotUnit ? (pilotReviewSummary.status === "draft-for-founder-review" ? "review draft." : "pilot preview.") : "planning record."}</em></>}
        subtitle={isPilotUnit ? pilotReviewSummary.proposedFocus : "This planning slot has no confirmed unit focus yet. Do not infer syllabus coverage from the placeholder."}
      />
      <section className="proto-unit-detail-panel">
        <div className="proto-panel-heading">
          <div><h2>{isPilotUnit ? `Unit ${selectedUnit.sequence} — ${pilotReviewSummary.title}` : selectedUnit.title}</h2><p>{selectedPathway.programmeName} · {selectedPathway.courseName} · {selectedPathway.levelLabel} · Unit {selectedUnit.sequence}</p></div>
          <span>NOT RELEASED</span>
        </div>
        {isPilotUnit ? <>
          <div className="proto-unit-status-grid">
            <div><small>ACADEMIC CONTENT REVIEW</small><b>{pilotReviewSummary.reviewRecord.outcome === "passed" ? `Passed for pilot preview v${pilotReviewSummary.version}` : `Awaiting review of version ${pilotReviewSummary.version}`}</b><p>{pilotReviewSummary.reviewRecord.outcome === "passed" ? `Reviewed ${pilotReviewSummary.reviewRecord.reviewedAt}` : "Version 1 approval does not transfer to this revision."}</p></div>
            <div><small>OFFICIAL CURRICULUM MAPPING</small><b>Unverified</b><p>No edition-specific official objective codes are assigned.</p></div>
            <div><small>RELEASE APPROVAL</small><b>Outstanding</b><p>This content is not a released syllabus-mapped course.</p></div>
          </div>
          <div className="proto-extract">
            <small>OFFICIAL STARTING POINT · CHECKED {pilotReviewSummary.source.checkedAt}</small>
            <p><a href={pilotReviewSummary.source.url} target="_blank" rel="noreferrer">{pilotReviewSummary.source.title} ↗</a></p>
            <p>{pilotReviewSummary.source.scopeNote}</p>
          </div>
          <div className="proto-feedback-columns">
            <div><small>UNIT LEARNING OBJECTIVE</small><p>{pilotReviewSummary.proposedLearningObjective}</p></div>
            <div><small>PUBLIC FRAMEWORK ALIGNMENT</small><p>This unit is designed against the broad skill areas described in public IB MYP information. Exact official Year 1 objective/strand mapping is not claimed.</p></div>
          </div>
          <div className="proto-extract">
            <small>PUBLIC MYP FRAMEWORK ALIGNMENT · NOT AN OFFICIAL OBJECTIVE MAP</small>
            <p>The public overview describes broad skill areas but does not include exact current Year 1 objective/strand descriptors. No official codes are assigned to this unit.</p>
            
            <p><a href={pilotReviewSummary.source.url} target="_blank" rel="noreferrer">Open public IB MYP overview ↗</a> · <a href={pilotReviewSummary.source.subjectBriefUrl} target="_blank" rel="noreferrer">Open public subject brief (historical overview) ↗</a></p>
          </div>
          <div className="proto-section-title"><div><h2>Remaining review and release checks</h2><p>{pilotReviewSummary.reviewRecord.outcome === "passed" ? "Content review passed for this version; other requirements remain separate." : "Version 2 awaits founder review; other requirements remain separate."}</p></div></div>
          {pilotReviewSummary.remainingReleaseChecks.map((item, index) => <div className="proto-skill-row proto-readiness-row" key={item}><i className="warm">{String(index + 1).padStart(2, "0")}</i><div><b>{item}</b></div></div>)}
          <p className="proto-note-bottom">{pilotReviewSummary.releaseNote}</p>
        </> : <>
          <p className="proto-unit-readiness-intro">This is a planning slot only. Its skill focus, learning objective, applicable syllabus source and objective mapping have not been confirmed.</p>
          <p className="proto-note-bottom">{selectedUnit.reviewNote}</p>
        </>}
        <div className="proto-unit-readiness-summary"><div><small>RELEASE READINESS</small><b>{readiness.complete} of {readiness.total} requirements complete</b></div><span>{readiness.releasable ? "Ready for release" : "Planning only"}</span></div>
        {readinessGates.map((gate, index) => <div className="proto-skill-row proto-readiness-row" key={gate.id}><i className={gate.status === "complete" ? "good" : gate.status === "blocked" ? "warm" : ""}>{gate.status === "complete" ? "✓" : String(index + 1).padStart(2, "0")}</i><div><b>{gate.title}</b><small>{gate.detail}</small><small className="proto-readiness-owner">{gate.owner}</small></div><span>{gate.status === "complete" ? "Complete" : gate.status === "blocked" ? "Blocked" : "Not started"}</span></div>)}
      </section>
      <PathwayStepNavigation
        previous={previousUnit
          ? { label: `Unit ${previousUnit.sequence}`, path: unitPathForId(selectedPathway.id, previousUnit.id) }
          : { label: selectedPathway.levelLabel, path: pathwayPathForId(selectedPathway.id) }}
        next={isPilotUnit
          ? {
              label: pilotReviewSummary.status === "draft-for-founder-review" ? "Unit 1 review draft" : "pilot lesson preview",
              path: lessonPathForId(selectedPathway.id, selectedUnit.id),
            }
          : nextUnit
            ? { label: `Unit ${nextUnit.sequence}`, path: unitPathForId(selectedPathway.id, nextUnit.id) }
            : {
                label: "No further unit is planned",
                unavailableReason: "There are no additional unit slots in this level's current planning sequence.",
              }}
        navigatePath={navigatePath}
      />
    </>}
  </Shell>;
}


function Questions({ go }: { go: Navigate }) {
  const [search, setSearch] = useState("");
  const [area, setArea] = useState("All skills");
  const [type, setType] = useState("All task types");
  const filtered = demoQuestionItems.filter(q => (q.title + " " + q.skill + " " + q.area + " " + q.type).toLowerCase().includes(search.toLowerCase()) && (area === "All skills" || q.area === area) && (type === "All task types" || q.type === type));
  return <Shell page="questions" go={go}><InfoNote><b>Question bank prototype.</b> Titles and items are examples for demonstrating search and filters, not a published syllabus-mapped bank.</InfoNote><PageIntro eyebrow="PRACTISE WITH PURPOSE" title={<>A better question can<br />unlock <em>a new idea.</em></>} subtitle="Explore short practice and extended-response examples. Filter by the kind of skill you want to work on." /><div className="proto-bank-count"><b>{filtered.length}</b> example {filtered.length === 1 ? "task" : "tasks"} shown <small>FICTIONAL CONTENT</small></div><section className="proto-panel proto-filters"><div className="proto-search"><span>⌕</span><input aria-label="Search questions" placeholder="Search a skill, topic or task..." value={search} onChange={e => setSearch(e.target.value)} /><small>SEARCH</small></div><div className="proto-filter-row"><label>SKILL AREA<select value={area} onChange={e => setArea(e.target.value)}><option>All skills</option><option>Reading</option><option>Writing</option><option>Analysis</option></select></label><label>TASK TYPE<select value={type} onChange={e => setType(e.target.value)}><option>All task types</option><option>Short response</option><option>Guided analysis</option><option>Writing task</option><option>Revision task</option></select></label><button type="button" onClick={() => { setSearch(""); setArea("All skills"); setType("All task types"); }}>Clear filters ↺</button></div></section><div className="proto-results">{filtered.map((q, i) => <article className="proto-result" key={q.id}><div className={"proto-result-art art-" + (i % 3)}><b>{q.area === "Reading" ? "“ ”" : q.area === "Writing" ? "Aa" : "↗"}</b><small>{q.id}</small></div><div className="proto-result-main"><div><span>{q.area}</span><small>{q.type}</small></div><h2>{q.title}</h2><p>{q.skill}</p><small>◷ {q.time} &nbsp; · &nbsp; Demo item</small></div><Action secondary onClick={() => go("lesson")}>Open activity ↗</Action></article>)}{filtered.length === 0 && <div className="proto-empty"><span>⌕</span><h2>No matching examples</h2><p>Try a different search term or clear the filters to see all demo items.</p><Action secondary onClick={() => { setSearch(""); setArea("All skills"); setType("All task types"); }}>Clear filters</Action></div>}</div></Shell>;
}

function Assessment({ go }: { go: Navigate }) {
  const [evidence, setEvidence] = useState(false);
  const evidenceExcerpts = [
    {
      criterion: "Purpose and audience",
      quote: "You might have noticed that things are changing around us...",
      explanation: "This excerpt gives an example of how feedback can point to the opening and discuss how it addresses its intended audience.",
    },
    {
      criterion: "Organisation and development",
      quote: "Another point to think about is...",
      explanation: "This excerpt gives an example of how feedback can connect a comment to the way a supporting point is introduced.",
    },
  ];
  return <Shell page="assessment" go={go}><InfoNote><b>Assessment feedback prototype.</b> This is fictional feedback and an illustrative placeholder rubric—not a founder-approved rubric or a real student assessment.</InfoNote><div className="proto-assess-head"><div><div className="proto-crumb"><button type="button" onClick={() => go("dashboard")}>Overview</button> / <b>Assessment feedback</b></div><Label>HUMAN FEEDBACK · CONCEPT SCREEN</Label><h1>See the thinking<br />behind <em>the feedback.</em></h1><p>Useful assessment connects a criterion to evidence in the response, then points towards a practical next step.</p></div><div className="proto-assess-status"><span>✓</span><div><small>EXAMPLE STATUS</small><b>Feedback published</b><small>Fictional assessment · sample date</small></div></div></div><section className="proto-panel proto-assess-summary"><div><small>SAMPLE TASK</small><h2>Write for a specific audience</h2><p>Extended response · Curriculum mapping to be verified</p></div><div><small>ASSESSMENT TYPE</small><b>Human-graded concept</b><small>RESPONSE HISTORY</small><button type="button" aria-expanded={evidence} aria-controls="proto-evidence-excerpts" onClick={() => { const next = !evidence; setEvidence(next); if (next) window.setTimeout(() => document.getElementById("proto-evidence-excerpts")?.scrollIntoView({ behavior: "smooth", block: "nearest" }), 50); }}>{evidence ? "Hide evidence excerpts ↑" : "Show evidence excerpts ↓"}</button></div></section><section id="proto-evidence-excerpts" hidden={!evidence} className="proto-panel proto-evidence-excerpts" aria-label="Evidence excerpts"><div className="proto-evidence-heading"><span>↗</span><div><Label>ILLUSTRATIVE EXCERPTS</Label><h2>Evidence connected to feedback</h2><p>These examples show how a feedback comment can refer to specific words from a response.</p></div></div><div className="proto-evidence-grid">{evidenceExcerpts.map(item => <article className="proto-evidence-card" key={item.criterion}><small>{item.criterion}</small><blockquote>“{item.quote}”</blockquote><p>{item.explanation}</p></article>)}</div><p className="proto-evidence-note">Fictional demonstration text only—not a real learner's response. Final rubrics and assessment rules are not yet approved.</p></section><div className="proto-assess-grid"><div><section className="proto-panel"><div className="proto-feedback-title"><div><Label>THE BIG PICTURE</Label><h2>A thoughtful start, with room to be more precise.</h2></div><span>✳</span></div><p className="proto-feedback-body">The response maintains a consistent voice and recognises its intended audience. To strengthen the piece, make the central point clearer earlier and ensure each detail helps develop that purpose.</p><div className="proto-feedback-columns"><div><small>WHAT IS WORKING</small><p>Voice and tone feel considered. The response stays focused on its intended reader.</p></div><div><small>WHAT TO DEVELOP</small><p>Make the main message more explicit and connect supporting details more directly to it.</p></div></div></section><section className="proto-panel proto-rubric"><div className="proto-panel-heading"><div><h2>Criterion-by-criterion feedback</h2><p>Illustrative placeholder criteria for the interface only.</p></div><span>NOT FINAL RUBRIC</span></div>{[{n:"01",title:"Purpose and audience",score:"4",body:"The tone is broadly appropriate to the intended reader. A clearer opening would establish the purpose more confidently."},{n:"02",title:"Organisation and development",score:"3",body:"The sequence is understandable. Stronger links between the central point and supporting details would improve the flow."},{n:"03",title:"Language and precision",score:"4",body:"Language is generally clear. A few more specific verbs and details could make the message sharper."}].map(c => <article className="proto-criterion" key={c.n}><div><span>{c.n}</span><div><b>{c.title}</b><small>Placeholder criterion</small></div><strong>{c.score}<small> / 5</small></strong></div><p>{c.body}</p></article>)}<p className="proto-rubric-note">Scores are illustrative UI data. Final task-specific rubrics and multi-credit rules remain decisions for the academic lead.</p></section></div><aside><section className="proto-panel proto-next-steps"><span>↗</span><Label>YOUR NEXT STEPS</Label><h2>Turn feedback into practice.</h2><ol><li><i>1</i>Rewrite the opening so the central point is clear.</li><li><i>2</i>Connect each supporting detail to your purpose.</li><li><i>3</i>Review transitions and clarify links between ideas.</li></ol><Action onClick={() => go("questions")}>Find related practice →</Action></section><section className="proto-panel proto-help"><span>i</span><b>What makes feedback useful?</b><p>It should be specific, linked to evidence and clear about what to try next—not only a score.</p></section></aside></div><div className="proto-bottom-actions"><Action secondary onClick={() => go("dashboard")}>← Back to overview</Action><Action onClick={() => go("lesson")}>Practise a skill →</Action></div></Shell>;
}

function NotFound({ go }: { go: Navigate }) {
  return <Shell page="pathways" go={go} context="Destination unavailable">
    <PageIntro
      eyebrow="DESTINATION NOT FOUND"
      title={<>This route isn't <em>available.</em></>}
      subtitle="We couldn't match this address to a planned pathway. Unverified syllabus routes are not created automatically."
    />
    <Action onClick={() => go("pathways")}>Return to pathways catalogue →</Action>
  </Shell>;
}

export default function App() {
  const [pathname, setPathname] = useState(() => window.location.pathname);

  useEffect(() => {
    const handlePopState = () => {
      setPathname(window.location.pathname);
      window.scrollTo({ top: 0, behavior: "auto" });
    };
    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, []);

  const navigatePath: NavigatePath = path => {
    const normalizedPath = `/${path.split("/").filter(Boolean).join("/")}`;
    if (window.location.pathname !== normalizedPath) {
      window.history.pushState({}, "", normalizedPath);
    }
    setPathname(normalizedPath);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const go: Navigate = next => navigatePath(pathnameForPage(next));
  const route = resolvePathname(pathname);

  if (route.type === "home") return <Home go={go} />;
  if (route.type === "page") {
    if (route.page === "dashboard") return <Dashboard go={go} />;
    if (route.page === "questions") return <Questions go={go} />;
    return <Assessment go={go} />;
  }
  if (route.type === "pathways") return <Pathways go={go} route={route} navigatePath={navigatePath} />;
  if (route.type === "lesson") return <Lesson go={go} navigatePath={navigatePath} pathwayId={route.pathwayId} unitId={route.unitId} />;
  return <NotFound go={go} />;
}
