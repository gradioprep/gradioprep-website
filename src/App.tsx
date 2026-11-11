import { useEffect, useState, type ReactNode } from "react";
import AccountPage from "./auth/AccountPage";
import EvaluationReportPanel from "./auth/EvaluationReportPanel";
import { useAuth } from "./auth/AuthProvider";
import { englishPathways } from "./content/pathways";
import { pilotReviewSummary } from "./content/pilotReviewSummary";
import { pilotLearnerLesson } from "./content/pilotLearnerLesson";

export type Page = "home" | "dashboard" | "pathways" | "lesson" | "questions" | "assessment" | "account";
export type Navigate = (page: Page) => void;

type PathwaysLocation =
  | { type: "pathways"; view: "catalogue" }
  | { type: "pathways"; view: "curriculum"; courseCode: string }
  | { type: "pathways"; view: "level"; courseCode: string; pathwayId: string }
  | { type: "pathways"; view: "unit"; courseCode: string; pathwayId: string; unitId: string };

type AppRoute =
  | { type: "home" }
  | { type: "page"; page: "dashboard" | "questions" | "assessment" | "account" }
  | PathwaysLocation
  | { type: "lesson"; pathwayId: string; unitId: string }
  | { type: "not-found" };

type NavigatePath = (path: string) => void;

const sections: { page: Page; label: string; icon: string }[] = [
  { page: "dashboard", label: "Overview", icon: "⌂" },
  { page: "pathways", label: "Pathways", icon: "⌁" },
  { page: "questions", label: "Question bank", icon: "▤" },
  { page: "lesson", label: "Lessons & practice", icon: "↗" },
  { page: "assessment", label: "Evaluation Report", icon: "◎" },
  { page: "account", label: "Account", icon: "◉" },
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
    if (segment === "dashboard" || segment === "questions" || segment === "assessment" || segment === "account") {
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

function Logo({ onClick }: { onClick: () => void }) {
  return <button className="proto-logo" type="button" onClick={onClick} aria-label="GradioPrep home"><span className="proto-logo-mark"><i /><i /><i /><i /></span><span><b>GradioPrep</b><small>ENGLISH LEARNING</small></span></button>;
}
function Action({ children, onClick, secondary = false }: { children: ReactNode; onClick: () => void; secondary?: boolean }) {
  return <button type="button" onClick={onClick} className={"proto-action" + (secondary ? " secondary" : "")}>{children}</button>;
}
function Label({ children }: { children: ReactNode }) { return <p className="proto-eyebrow"><span />{children}</p>; }

function Home({ go }: { go: Navigate }) {
 return <div className="proto-public">
  <header className="proto-header"><div className="proto-container proto-header-inner"><Logo onClick={()=>go("home")}/><nav><a href="#proto-pathways">Pathways</a><a href="#proto-approach">Our approach</a><a href="#proto-learning">Learning</a></nav><Action secondary onClick={()=>go("account")}>Sign in <span aria-hidden="true">↗</span></Action></div></header>
  <main>
   <section className="proto-hero"><div className="proto-container proto-hero-grid"><div><Label>LEARNING, WITH DIRECTION</Label><h1>Make your next step a <em>smarter one.</em></h1><p className="proto-lead">A more considered way to learn English across IB MYP and Cambridge pathways. Practise with purpose, understand your gaps and build on what you know.</p><div className="proto-actions"><Action onClick={()=>go("questions")}>Explore practice <span>→</span></Action><button className="proto-inline" type="button" onClick={()=>document.getElementById("proto-approach")?.scrollIntoView({behavior:"smooth"})}>Our approach ↘</button></div><div className="proto-proof"><span>✳</span><div><b>Learning that moves you forward.</b><small>Clear objectives. Useful practice. Feedback with a purpose.</small></div></div></div>
    <div className="proto-hero-art"><div className="proto-orbit one"/><div className="proto-orbit two"/><section className="proto-journey"><div className="proto-overline"><span>YOUR LEARNING JOURNEY</span><span>01 — 03</span></div><div className="proto-journey-title"><span>↗</span><div><small>A ROUTE THAT MAKES SENSE</small><h2>Progress, in practice.</h2></div></div><div className="proto-journey-row"><span>01</span><div><b>Understand the skill</b><small>Know what you're learning and why.</small></div><i className="done">✓</i></div><div className="proto-journey-row"><span>02</span><div><b>Practise with purpose</b><small>Try questions connected to that skill.</small></div><i>02</i></div><div className="proto-journey-row"><span>03</span><div><b>Choose your next step</b><small>Use evidence and feedback to improve.</small></div><i>03</i></div><div className="proto-journey-footer">✳ &nbsp; Designed for progress, not guesswork.</div></section><div className="proto-floating-note"><span>↗</span><div><b>Small steps.</b><small>Meaningful progress.</small></div></div></div>
   </div><div className="proto-ribbon"><span>LEARN WITH PURPOSE</span><i/><span>GROW WITH EVIDENCE</span><i/><span>KEEP MOVING FORWARD</span></div></section>
   <section className="proto-pathways proto-section" id="proto-pathways"><div className="proto-container"><div className="proto-section-heading"><div><Label>START WITH THE RIGHT PATH</Label><h2>The right route starts<br/>with <em>your world.</em></h2></div><p>Different programmes have different expectations. Start with the pathway that matches your curriculum—not a one-size-fits-all course.</p></div><div className="proto-pathway-groups">
    <section className="proto-pathway-group ib-pathway-group"><div className="proto-pathway-band"><div className="proto-pathway-symbol" aria-hidden="true"><span>IB</span><i>✳</i></div><div><small>PATHWAY 01 · INTERNATIONAL BACCALAUREATE</small><h3>IB Middle Years Programme</h3><p>Explore Language & Literature through inquiry, interpretation and thoughtful communication.</p></div><span className="proto-pathway-band-arrow" aria-hidden="true">↗</span></div><div className="proto-pathway-grid ib-grid"><article><div><span>01</span><b>IB MYP</b></div><h3>Language & Literature</h3><small>Years 1–5</small><p>Build confidence in reading, interpretation and purposeful writing through a clearly organised learning route.</p><button type="button" onClick={()=>go("pathways")}>Explore IB pathways <span>↗</span></button></article></div></section>
    <section className="proto-pathway-group cambridge-pathway-group"><div className="proto-pathway-band"><div className="proto-pathway-symbol" aria-hidden="true"><span>C</span><i>✦</i></div><div><small>PATHWAY 02 · CAMBRIDGE INTERNATIONAL</small><h3>Cambridge English</h3><p>Choose the stage that fits your learning journey, from core skills to exam preparation.</p></div><span className="proto-pathway-band-arrow" aria-hidden="true">↗</span></div><div className="proto-pathway-grid cambridge-grid"><article><div><span>02</span><b>CAMBRIDGE</b></div><h3>Lower Secondary English</h3><small>Stages 7–9</small><p>Strengthen core English skills with practice organised around the learning objectives that matter.</p><button type="button" onClick={()=>go("pathways")}>Explore Cambridge <span>↗</span></button></article><article><div><span>03</span><b>CAMBRIDGE IGCSE</b></div><h3>First Language English</h3><small>English language learning</small><p>Develop confident reading and purposeful writing through focused practice.</p><button type="button" onClick={()=>go("pathways")}>Explore Cambridge <span>↗</span></button></article></div></section>
   </div></div></section>
   <section className="proto-approach proto-section" id="proto-approach"><div className="proto-container proto-approach-grid"><div><Label>WHY THIS PLATFORM</Label><h2>More than a library.<br/><em>A clearer next step.</em></h2><p>Finding notes is only the beginning. The aim is to connect the syllabus, a specific skill, deliberate practice and useful feedback in one learning space.</p><Action secondary onClick={()=>go("lesson")}>Open a lesson →</Action></div><div className="proto-principles"><article><span>01</span><i>⌖</i><div><b>Find your bearings</b><p>Start with your programme, stage and the skill you want to build.</p></div></article><article><span>02</span><i>↗</i><div><b>Practise with purpose</b><p>Use focused questions, annotated examples and clear explanations.</p></div></article><article><span>03</span><i>✳</i><div><b>Learn from evidence</b><p>Use saved attempts and meaningful feedback to decide what comes next.</p></div></article></div></div></section>
   <section className="proto-release" id="proto-learning"><div className="proto-container proto-release-panel"><div><Label>ENGLISH LEARNING</Label><h2>Build confidence.<br/><em>One step at a time.</em></h2></div><div><p>Explore English pathways, practise important skills and use clear feedback to choose your next step.</p><Action onClick={()=>go("dashboard")}>Explore your learning ↗</Action></div></div></section>
  </main><footer className="proto-public-footer"><div className="proto-container"><Logo onClick={()=>go("home")}/><p>Know what to practise next—and see whether you have improved.</p></div></footer>
 </div>;
}

function Shell({ page, go, children, context }: { page: Page; go: Navigate; children: ReactNode; context?: string }) {
 return <div className="proto-app"><div className="proto-app-layout"><aside className="proto-sidebar"><Logo onClick={()=>go("home")}/><div className="proto-workspace">LEARNING SPACE</div><nav aria-label="Student navigation">{sections.map(s=><button type="button" key={s.page} className={page===s.page?"active":""} onClick={()=>go(s.page)}><i>{s.icon}</i>{s.label}{page===s.page&&<b/>}</button>)}</nav><div className="proto-sidebar-bottom"><strong>✳ &nbsp; Keep moving forward.</strong><p>Every attempt can teach you something.</p><button type="button" onClick={()=>go("home")}>↖ &nbsp; Homepage</button></div></aside><div className="proto-app-main"><header className="proto-app-header"><div>Learning space <span>/</span> <b>{sections.find(s=>s.page===page)?.label??"Learning"}</b></div><small>{context??"English learning"}</small><i>G</i></header><main className="proto-app-content">{children}<footer className="proto-app-footer"><span>GradioPrep</span></footer></main></div></div></div>;
}

function PageIntro({ eyebrow, title, subtitle }: { eyebrow: string; title: ReactNode; subtitle: string }) {
  return <div className="proto-page-intro"><Label>{eyebrow}</Label><h1>{title}</h1><p>{subtitle}</p></div>;
}

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
          <small className="proto-step-kicker">{next.path === "/pathways" ? "PATHWAYS" : "NEXT STEP"}</small>
          <b>{next.path === "/pathways" ? "Choose another pathway →" : `Continue to ${next.label} →`}</b>
        </button>
      : <div className="proto-pathway-next-unavailable" aria-label={next.label}>
          <small className="proto-step-kicker">NEXT STEP</small>
          <b>{next.label}</b>
          <p>{next.unavailableReason}</p>
        </div>}
  </nav>;
}

function Dashboard({ go }: { go: Navigate }) {
 return <Shell page="dashboard" go={go}>
  <PageIntro eyebrow="YOUR LEARNING AT A GLANCE" title={<>A clearer picture of <em>your progress.</em></>} subtitle="See your learning activity, the skills you are developing and the next steps that help you move forward."/>
  <section className="proto-welcome"><div><small>YOUR NEXT STEP</small><h2>Start with the right pathway.</h2><p>Choose your curriculum to find focused English learning and practice.</p><Action onClick={()=>go("pathways")}>Explore pathways →</Action></div><div className="proto-welcome-art"><span>Aa</span><small>WORDS WITH PURPOSE</small></div></section>
  <div className="proto-section-title"><div><h2>Your learning snapshot</h2><p>Your completed work will appear here.</p></div><small>LEARNING SUMMARY</small></div>
  <div className="proto-metrics"><article><i>⌖</i><small>SKILLS EXPLORED</small><strong>—</strong><span>Your skill summary will appear here.</span></article><article><i>↗</i><small>PRACTICE ATTEMPTS</small><strong>—</strong><span>Your completed activities will appear here.</span></article><article><i>⟳</i><small>SAVED RESPONSES</small><strong>—</strong><span>Your saved work will appear here.</span></article></div>
  <div className="proto-dash-grid"><section className="proto-panel"><div className="proto-panel-heading"><div><h2>Skills in focus</h2><p>Build your learning record through completed work.</p></div><button type="button" onClick={()=>go("pathways")}>Explore pathways ↗</button></div><div className="proto-empty"><span>⌖</span><h3>Your skill summary starts here.</h3><p>Complete your first Preliminary Assessment or practice activity to start building your learning record.</p></div></section><section className="proto-panel"><div className="proto-panel-heading"><div><h2>Suggested next</h2><p>Choose a useful place to begin.</p></div><span className="proto-spark">✳</span></div><div className="proto-recommend"><small>YOUR NEXT STEP</small><h3>Choose your learning pathway</h3><p>Start with the curriculum and course that match your studies.</p><Action onClick={()=>go("pathways")}>Find your pathway →</Action></div><button type="button" className="proto-wide-link" onClick={()=>go("assessment")}>View your Evaluation Report ↗</button></section></div>
  <section className="proto-panel proto-activity"><div className="proto-panel-heading"><div><h2>Recent activity</h2><p>Your learning history at a glance.</p></div><button type="button" onClick={()=>go("questions")}>Explore practice ↗</button></div><div className="proto-empty"><span>↗</span><h3>Your recent activity will appear here.</h3><p>Complete an activity to begin building your learning history.</p></div></section>
 </Shell>;
}

function Lesson({ go, navigatePath, pathwayId, unitId }: { go: Navigate; navigatePath: NavigatePath; pathwayId: string; unitId: string }) {
 const pathway=englishPathways.find(item=>item.id===pathwayId)??englishPathways[0], unit=pathway.unitSlots.find(item=>item.id===unitId)??pathway.unitSlots[0];
 const curriculumPath=coursePathForCode(pathway.courseCode), levelPath=pathwayPathForId(pathway.id), unitPath=unitPathForId(pathway.id,unit.id);
 const lesson=pilotLearnerLesson, curriculumContext=`${pathway.programmeName} · ${pathway.courseName} · ${pathway.levelLabel} · Unit ${unit.sequence}`;
 const [selectedOptions,setSelectedOptions]=useState<Record<string,string>>({}),[responses,setResponses]=useState<Record<string,string>>({}),[attempted,setAttempted]=useState<Record<string,boolean>>({});
 const [exitResponse,setExitResponse]=useState(""),[exitReviewed,setExitReviewed]=useState(false);
 const attemptedCount=Object.values(attempted).filter(Boolean).length+(exitReviewed?1:0);
 const updateResponse=(id:string,value:string)=>{setResponses(previous=>({...previous,[id]:value}));setAttempted(previous=>({...previous,[id]:false}));};
 const canReview=(item:typeof lesson.practiceItems[number])=>item.options?Boolean(selectedOptions[item.id]):Boolean(responses[item.id]?.trim());
 return <Shell page="lesson" go={go} context={curriculumContext}>
  <div className="proto-crumb"><button type="button" onClick={()=>navigatePath("/pathways")}>Pathways</button> / <button type="button" onClick={()=>navigatePath(curriculumPath)}>{pathway.programmeName} · {pathway.courseName}</button> / <button type="button" onClick={()=>navigatePath(levelPath)}>{pathway.levelLabel}</button> / <button type="button" onClick={()=>navigatePath(unitPath)}>Unit {unit.sequence}</button> / <b>Lesson</b></div>
  <div className="proto-lesson-head"><div><Label>ENGLISH · LANGUAGE AND LITERATURE</Label><h1>Notice the choice.<br/><em>Explain the effect.</em></h1><p>{lesson.proposedLearningObjective}</p></div><div className="proto-progress"><small>LESSON LENGTH</small><b>{lesson.estimatedMinutes} <span>minutes</span></b><div><i style={{width:"100%"}}/></div><small>Move through the lesson at your own pace</small></div></div>
  <section className="proto-panel proto-pilot-learner-summary"><div className="proto-panel-heading"><div><h2>What success looks like</h2><p>Use these ideas as you read, practise and review your responses.</p></div><span>LEARNING GOALS</span></div>{lesson.successCriteria.map((item,index)=><div className="proto-skill-row proto-readiness-row" key={item}><i>{String(index+1).padStart(2,"0")}</i><div><b>{item}</b></div></div>)}</section>
  <div className="proto-learning-route" aria-label="Lesson steps"><div className="route-read"><span>01</span><i aria-hidden="true">▤</i><b>Read the passage</b><small>Notice details</small></div><div className="route-connector" aria-hidden="true">→</div><div className="route-idea"><span>02</span><i aria-hidden="true">✦</i><b>The idea</b><small>Spot the pattern</small></div><div className="route-connector" aria-hidden="true">→</div><div className="route-move"><span>03</span><i aria-hidden="true">↗</i><b>Learn the move</b><small>Try it yourself</small></div></div>
  <div className="proto-lesson-grid proto-pilot-learner-grid"><div>
   <section className="proto-panel proto-explanation proto-learning-stage stage-read"><Label>01 · READ THE PASSAGE</Label><h2>{lesson.passage.label}</h2><blockquote className="proto-pilot-passage">{lesson.passage.text}</blockquote><p className="proto-unit-readiness-intro">Read closely and notice the words that shape the mood and meaning of this moment.</p></section>
   <section className="proto-panel proto-explanation proto-learning-stage stage-idea"><Label>02 · THE IDEA</Label><h2>{lesson.keyIdea.label}</h2><div className="proto-pilot-evidence-chain">{lesson.keyIdea.pattern.map((step,index)=><div key={step}><i>{index+1}</i><p>{step}</p></div>)}</div><p>{lesson.keyIdea.explanation}</p></section>
   <section className="proto-panel proto-pilot-learning-steps proto-learning-stage stage-move"><Label>03 · LEARN THE MOVE</Label><h2>Work through the sequence</h2><p className="proto-stage-helper">Three small moves. Take them one at a time.</p>{lesson.sections.map(section=><article className="proto-pilot-section" key={section.id}><h3>{section.heading}</h3><p className="proto-pilot-purpose">{section.purpose}</p><p>{section.explanation}</p>{section.example&&<div className="proto-pilot-example"><small>{section.example.label.toUpperCase()}</small><blockquote>{section.example.text}</blockquote><p>{section.example.explanation}</p></div>}<div className="proto-pilot-action"><b>Try this</b><p>{section.learnerAction}</p></div></article>)}</section>
   <section className="proto-panel proto-pilot-practice"><div className="proto-panel-heading"><div><Label>04 · FORMATIVE PRACTICE</Label><h2>Put the idea to work</h2><p>{attemptedCount} of {lesson.practiceItems.length+1} activities reviewed in this session</p></div><span>SELF-CHECK</span></div><p className="proto-unit-readiness-intro">Choose an option or write your response, then compare your thinking with the success indicators. Your responses on this page are not saved, so keep a copy of any work you wish to revisit.</p>{lesson.practiceItems.map((item,index)=><article className="proto-pilot-question" key={item.id}><div className="proto-pilot-question-head"><span>{String(index+1).padStart(2,"0")}</span><div><small>{item.focus}</small><h3>{item.prompt}</h3></div></div>{item.options&&<div className="proto-pilot-options">{item.options.map(option=><button type="button" key={option.id} aria-pressed={selectedOptions[item.id]===option.id} className={"proto-pilot-option-button"+(selectedOptions[item.id]===option.id?" is-selected":"")} onClick={()=>{setSelectedOptions(previous=>({...previous,[item.id]:option.id}));setAttempted(previous=>({...previous,[item.id]:false}));}}><b>{option.id}</b><span>{option.text}</span></button>)}</div>}{!item.options&&<label className="proto-pilot-response-label">Your response<textarea rows={4} value={responses[item.id]??""} onChange={event=>updateResponse(item.id,event.target.value)} placeholder="Write your explanation here..."/></label>}<div className="proto-pilot-question-footer"><small>{attempted[item.id]?"REVIEWED":"READY TO REVIEW"}</small><button type="button" className="proto-action secondary" disabled={!canReview(item)} onClick={()=>setAttempted(previous=>({...previous,[item.id]:true}))}>Review my thinking</button></div>{attempted[item.id]&&<div className="proto-answer-feedback right"><b>Use the success indicators</b><p>Compare your response with each point below and revise where it would make your reasoning clearer.</p><ul>{item.successIndicators.map(point=><li key={point}>{point}</li>)}</ul><p>Different interpretations can be valid when they are supported by evidence.</p></div>}</article>)}</section>
   <section className="proto-panel proto-pilot-exit"><Label>05 · EXIT TICKET</Label><h2>Try the thinking move independently</h2><p>{lesson.exitTicket.prompt}</p><label className="proto-pilot-response-label">Your exit response<textarea rows={5} value={exitResponse} onChange={event=>{setExitResponse(event.target.value);setExitReviewed(false);}} placeholder="Use precise evidence, explain what it may suggest, and connect it to the context..."/></label><div className="proto-pilot-question-footer"><small>{exitReviewed?"CHECKLIST OPENED":"SELF-REVIEW AVAILABLE"}</small><button type="button" className="proto-action" disabled={!exitResponse.trim()} onClick={()=>setExitReviewed(true)}>Review exit response</button></div>{exitReviewed&&<div className="proto-answer-feedback right"><b>Self-review checklist</b><ul>{lesson.exitTicket.successIndicators.map(point=><li key={point}>{point}</li>)}</ul><p>Use the checklist to decide what to strengthen in your response.</p></div>}</section>
   <PathwayStepNavigation previous={{label:`Unit ${unit.sequence}`,path:unitPath}} next={{label:"Next lesson",unavailableReason:"Your next learning activity will appear here."}} navigatePath={navigatePath}/><div className="proto-bottom-actions proto-pathway-extra-actions"><Action onClick={()=>go("questions")}>Explore practice →</Action></div>
  </div><aside className="proto-panel proto-lesson-aside"><Label>IN THIS LESSON</Label>{lesson.sections.map((section,index)=><div className="proto-outline-row" key={section.id}><i>{String(index+1).padStart(2,"0")}</i><span><b>{section.heading.replace(/^\d+\.\s*/,"")}</b><small>{section.purpose}</small></span></div>)}<div className="proto-aside-tip"><span>Aa</span><b>Keep the evidence chain visible</b><p>Choice → association → effect in context. A quotation is the start of your explanation, not the whole explanation.</p></div></aside></div>
 </Shell>;
}

function Pathways({ go, route, navigatePath }: { go: Navigate; route: PathwaysLocation; navigatePath: NavigatePath }) {
 const view=route.view, selectedCourseCode=view==="catalogue"?courseChoices[0].code:route.courseCode;
 const selectedPathwayId=view==="level"||view==="unit"?route.pathwayId:"ib-myp-lal-y1";
 const selectedUnitId=view==="unit"?route.unitId:(englishPathways.find(item=>item.id===selectedPathwayId)?.unitSlots[0]?.id??"ib-myp-lal-y1-u1");
 const selectedPathway=englishPathways.find(item=>item.id===selectedPathwayId)??englishPathways[0], selectedUnit=selectedPathway.unitSlots.find(item=>item.id===selectedUnitId)??selectedPathway.unitSlots[0];
 const selectedCourse=courseChoices.find(item=>item.code===selectedCourseCode)??courseChoices[0], coursePathways=englishPathways.filter(item=>item.courseCode===selectedCourseCode), supported=coursePathways.filter(item=>item.levelKind==="official-programme-level"), first=supported[0];
 const previousUnit=selectedPathway.unitSlots.find((item,index)=>item.id===selectedUnit?.id&&index>0)?selectedPathway.unitSlots[selectedPathway.unitSlots.findIndex(item=>item.id===selectedUnit?.id)-1]:undefined;
 const unitIndex=selectedPathway.unitSlots.findIndex(item=>item.id===selectedUnit?.id), nextUnit=unitIndex>=0?selectedPathway.unitSlots[unitIndex+1]:undefined, lessonAvailable=selectedUnit?.id===pilotReviewSummary.unitId;
 const openCurriculum=(code:string)=>navigatePath(coursePathForCode(code)),openLevel=(id:string)=>{const p=englishPathways.find(item=>item.id===id);if(p&&p.levelKind==="official-programme-level")navigatePath(pathwayPathForId(p.id));},openUnit=(id:string)=>{const p=englishPathways.find(item=>item.unitSlots.some(unit=>unit.id===id));if(p&&p.levelKind==="official-programme-level")navigatePath(unitPathForId(p.id,id));};
 const backCatalogue=()=>navigatePath("/pathways"),backCurriculum=()=>navigatePath(coursePathForCode(selectedPathway.courseCode)),backLevel=()=>navigatePath(pathwayPathForId(selectedPathway.id));
 const context=view==="catalogue"?"English pathways":view==="curriculum"?`${selectedCourse.taxonomy} · ${selectedCourse.title}`:`${selectedPathway.programmeName} · ${selectedPathway.courseName} · ${selectedPathway.levelLabel}`;
 return <Shell page="pathways" go={go} context={context}>
 {view==="catalogue"&&<><PageIntro eyebrow="CHOOSE YOUR CURRICULUM" title={<>Start with the right <em>pathway.</em></>} subtitle="Choose the programme and subject that match your studies."/><div className="proto-pathway-catalogue-groups">{courseChoices.map((course,index)=><section className={"proto-pathway-catalogue-group "+course.groupClass} key={course.code}><div className="proto-pathway-taxonomy" aria-label={course.taxonomy+" pathway group"}><span>{String(index+1).padStart(2,"0")}</span><small>CURRICULUM</small><strong>{course.taxonomy}</strong><i/></div><article className="proto-curriculum-card"><div className="proto-curriculum-card-top"><span>{course.taxonomy}</span><b>ENGLISH</b></div><h2>{course.title}</h2><p>{course.description}</p><div className="proto-curriculum-card-meta"><span>{course.levelSummary}</span><span>English learning</span></div><button type="button" className="proto-action" onClick={()=>openCurriculum(course.code)}>Explore this pathway <span>→</span></button></article></section>)}</div></>}
 {view==="curriculum"&&<><div className="proto-crumb"><button type="button" onClick={backCatalogue}>Pathways</button> / <b>{selectedCourse.taxonomy} · {selectedCourse.title}</b></div><PageIntro eyebrow={selectedCourse.taxonomy} title={<>{selectedCourse.title} <em>pathway.</em></>} subtitle={selectedCourse.description}/><section className="proto-curriculum-context-panel"><div><small>YOUR LEARNING PATHWAY</small><h2>{selectedCourse.taxonomy} · {selectedCourse.title}</h2></div><p>Follow your course level to find focused units, lessons and practice activities.</p></section>{supported.length?<div className="proto-level-grid">{supported.map((p,index)=><article className="proto-level-card" key={p.id}><div className="proto-level-card-top"><span>{String(index+1).padStart(2,"0")}</span><b>{selectedCourse.taxonomy}</b></div><h2>{p.levelLabel}</h2><p>Explore focused learning and practice for {p.levelLabel}.</p><button type="button" className="proto-action" onClick={()=>openLevel(p.id)}>Explore {p.levelLabel} <span>→</span></button></article>)}</div>:<section className="proto-no-levels"><p className="proto-eyebrow"><span/>YOUR COURSE</p><h2>Your level choices will appear here.</h2><p>Choose the course structure that matches your studies to see the available learning levels.</p></section>}<PathwayStepNavigation previous={{label:"Pathways catalogue",path:"/pathways"}} next={first?{label:first.levelLabel,path:pathwayPathForId(first.id)}:{label:"Choose another pathway",path:"/pathways"}} navigatePath={navigatePath}/></>}
 {view==="level"&&<><div className="proto-crumb"><button type="button" onClick={backCatalogue}>Pathways</button> / <button type="button" onClick={backCurriculum}>{selectedPathway.programmeName} · {selectedPathway.courseName}</button> / <b>{selectedPathway.levelLabel}</b></div><PageIntro eyebrow={selectedPathway.programmeName+" · "+selectedPathway.courseName} title={<>{selectedPathway.levelLabel} <em>learning plan.</em></>} subtitle="Follow a sequence of focused units and activities as you build your English skills."/><section className="proto-curriculum-context-panel"><div><small>YOUR LEARNING PATHWAY</small><h2>{selectedPathway.programmeName} · {selectedPathway.courseName} · {selectedPathway.levelLabel}</h2></div><p>Work through each unit to build knowledge, practise key skills and prepare for your next step.</p></section><div className="proto-unit-list-heading"><div><h2>Your unit sequence</h2><p>Move through the units in order, at a steady pace.</p></div><span>{selectedPathway.unitSlots.length} UNITS</span></div><div className="proto-level-unit-list">{selectedPathway.unitSlots.map(unit=>{const available=unit.id===pilotReviewSummary.unitId;return <article className="proto-level-unit-row" key={unit.id}><span className="proto-level-unit-number">{String(unit.sequence).padStart(2,"0")}</span><div><h3>{available?pilotReviewSummary.title:"Your next unit is being prepared"}</h3><p>{available?pilotReviewSummary.proposedFocus:"Your course plan will show the unit’s key skills and the activities that help you practise them."}</p></div><button type="button" className="proto-text-link" onClick={()=>openUnit(unit.id)}>Open unit <span>↗</span></button></article>})}</div><PathwayStepNavigation previous={{label:`${selectedPathway.programmeName} · ${selectedPathway.courseName}`,path:coursePathForCode(selectedPathway.courseCode)}} next={selectedPathway.unitSlots[0]?{label:`Unit ${selectedPathway.unitSlots[0].sequence}`,path:unitPathForId(selectedPathway.id,selectedPathway.unitSlots[0].id)}:{label:"Next learning step",unavailableReason:"Your next learning activity will appear here."}} navigatePath={navigatePath}/></>}
 {view==="unit"&&selectedUnit&&<><div className="proto-crumb"><button type="button" onClick={backCatalogue}>Pathways</button> / <button type="button" onClick={backCurriculum}>{selectedPathway.programmeName} · {selectedPathway.courseName}</button> / <button type="button" onClick={backLevel}>{selectedPathway.levelLabel}</button> / <b>Unit {selectedUnit.sequence}</b></div><PageIntro eyebrow={selectedPathway.programmeName+" · "+selectedPathway.courseName+" · "+selectedPathway.levelLabel} title={<>{lessonAvailable?pilotReviewSummary.title:"Your next learning focus"}</>} subtitle={lessonAvailable?pilotReviewSummary.proposedFocus:"Once your course plan is set, this space will show the selected unit, the skills you will practise and your next activities."}/>{lessonAvailable?<section className="proto-unit-detail-panel"><div className="proto-panel-heading"><div><h2>Your learning focus</h2><p>Build your understanding of how writers use language to shape meaning.</p></div><span>LESSON</span></div><div className="proto-feedback-columns"><div><small>WHAT YOU WILL PRACTISE</small><p>Notice a writer’s choices, connect them to associations and explain their effect in context.</p></div><div><small>YOUR NEXT STEP</small><p>Read the passage, work through the examples and apply the thinking in focused activities.</p></div></div><button type="button" className="proto-action" onClick={()=>navigatePath(lessonPathForId(selectedPathway.id,selectedUnit.id))}>Open lesson <span>→</span></button></section>:<section className="proto-unit-detail-panel"><div className="proto-panel-heading"><div><h2>Your next unit is being prepared</h2><p>Your course plan will show the unit’s key skills and the activities that help you practise them.</p></div><span>YOUR LEARNING</span></div></section>}<PathwayStepNavigation previous={previousUnit?{label:`Unit ${previousUnit.sequence}`,path:unitPathForId(selectedPathway.id,previousUnit.id)}:{label:selectedPathway.levelLabel,path:pathwayPathForId(selectedPathway.id)}} next={lessonAvailable?{label:"Lesson",path:lessonPathForId(selectedPathway.id,selectedUnit.id)}:nextUnit?{label:`Unit ${nextUnit.sequence}`,path:unitPathForId(selectedPathway.id,nextUnit.id)}:{label:"Next learning step",unavailableReason:"Your next learning activity will appear here."}} navigatePath={navigatePath}/></>}
 </Shell>;
}

function Questions({ go }: { go: Navigate }) {
 return <Shell page="questions" go={go}><PageIntro eyebrow="PRACTISE WITH PURPOSE" title={<>A better question can<br/>unlock <em>a new idea.</em></>} subtitle="Find focused activities that help you strengthen the skills you are learning."/><section className="proto-panel proto-results"><div className="proto-empty"><span>⌕</span><h2>Your practice activities will appear here.</h2><p>Choose your curriculum pathway to find activities connected to your learning goals.</p><Action secondary onClick={()=>go("pathways")}>Explore pathways →</Action></div></section></Shell>;
}

function Assessment({ go, accessToken, reportRecordId }: {
  go: Navigate;
  accessToken: string;
  reportRecordId: string;
}) {
  return <Shell page="assessment" go={go}>
    <PageIntro
      eyebrow="YOUR LEARNING REPORT"
      title={<>Your <em>Evaluation Report.</em></>}
      subtitle="Review the evidence recorded from your Preliminary Assessment and understand what it can support."
    />
    <EvaluationReportPanel accessToken={accessToken} reportRecordId={reportRecordId} go={go} />
    <div className="proto-bottom-actions">
      <Action secondary onClick={() => go("dashboard")}>← Back to overview</Action>
      <Action onClick={() => go("pathways")}>Explore pathways →</Action>
    </div>
  </Shell>;
}

function NotFound({ go }: { go: Navigate }) {
 return <Shell page="pathways" go={go} context="Learning"><PageIntro eyebrow="PATHWAY UNAVAILABLE" title={<>This route isn't <em>available.</em></>} subtitle="This learning route is not available. Return to the pathways catalogue to choose another course."/><Action onClick={()=>go("pathways")}>Return to pathways catalogue →</Action></Shell>;
}

export default function App() {
  const auth = useAuth();
  const [pathname, setPathname] = useState(() => window.location.pathname);
  const [evaluationReportId, setEvaluationReportId] = useState("");

  useEffect(() => {
    const handlePopState = () => {
      setPathname(window.location.pathname);
      window.scrollTo({ top: 0, behavior: "auto" });
    };
    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, []);

  useEffect(() => {
    const userId = auth.session?.user.id;
    if (!userId) {
      setEvaluationReportId("");
      return;
    }
    try {
      setEvaluationReportId(
        window.localStorage.getItem("gradioprep.evaluation-report.record:" + userId) ?? "",
      );
    } catch {
      setEvaluationReportId("");
    }
  }, [auth.session?.user.id]);

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
    if (route.page === "account") return <Shell page="account" go={go}>
      <AccountPage
        go={go}
        onEvaluationReportReady={reportRecordId => {
          setEvaluationReportId(reportRecordId);
          const userId = auth.session?.user.id;
          if (userId) {
            try {
              window.localStorage.setItem(
                "gradioprep.evaluation-report.record:" + userId,
                reportRecordId,
              );
            } catch {
              // The current page state still keeps the report available for this visit.
            }
          }
        }}
        onOpenEvaluationReport={() => navigatePath("/assessment")}
      />
    </Shell>;
    if (route.page === "questions") return <Questions go={go} />;
    return <Assessment
      go={go}
      accessToken={auth.session?.access_token ?? ""}
      reportRecordId={evaluationReportId}
    />;
  }
  if (route.type === "pathways") return <Pathways go={go} route={route} navigatePath={navigatePath} />;
  if (route.type === "lesson") return <Lesson go={go} navigatePath={navigatePath} pathwayId={route.pathwayId} unitId={route.unitId} />;
  return <NotFound go={go} />;
}
