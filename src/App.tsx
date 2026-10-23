type Pathway = {
  number: string;
  programme: string;
  title: string;
  stage: string;
  description: string;
};

const pathways: Pathway[] = [
  {
    number: "01",
    programme: "IB MYP",
    title: "Language & Literature",
    stage: "Years 1–5",
    description:
      "Build confidence in reading, interpretation and purposeful writing through a clearly mapped learning route.",
  },
  {
    number: "02",
    programme: "CAMBRIDGE",
    title: "Lower Secondary English",
    stage: "Stages 7–9",
    description:
      "Strengthen core English skills with practice organised around the learning objectives that matter.",
  },
  {
    number: "03",
    programme: "CAMBRIDGE IGCSE",
    title: "First Language English",
    stage: "Grade 9–10 equivalent",
    description:
      "Work towards the relevant syllabus with carefully checked curriculum mapping and purposeful practice.",
  },
];

const principles = [
  {
    number: "01",
    title: "Find your bearings",
    detail: "Start with your programme, stage and the skill you want to build.",
    symbol: "⌖",
  },
  {
    number: "02",
    title: "Practise with purpose",
    detail: "Use focused questions, annotated examples and clear explanations.",
    symbol: "↗",
  },
  {
    number: "03",
    title: "Learn from evidence",
    detail: "Use saved attempts and meaningful feedback to decide what comes next.",
    symbol: "✳",
  },
];

function BrandMark() {
  return (
    <span className="brand-mark" aria-hidden="true">
      <span />
      <span />
      <span />
      <span />
    </span>
  );
}

function App() {
  return (
    <div className="site-shell" id="top">
      <div className="preview-banner">
        <span className="status-dot" />
        EARLY BUILD PREVIEW
        <span className="banner-divider">/</span>
        LEARNING TOOLS ARE IN DEVELOPMENT
      </div>

      <header className="site-header">
        <div className="container header-inner">
          <a className="brand" href="#top" aria-label="Criterion Lab home">
            <BrandMark />
            <span className="brand-words">
              <strong>criterion lab</strong>
              <small>IB &amp; CAMBRIDGE LEARNING</small>
            </span>
          </a>
          <nav className="main-nav" aria-label="Main navigation">
            <a href="#pathways">Pathways</a>
            <a href="#approach">Our approach</a>
            <a className="nav-link-strong" href="#first-release">
              What’s coming <span aria-hidden="true">↗</span>
            </a>
          </nav>
        </div>
      </header>

      <main>
        <section className="hero">
          <div className="container hero-layout">
            <div className="hero-copy">
              <p className="eyebrow"><span /> LEARNING, WITH DIRECTION</p>
              <h1>Make your next step a <em>smarter one.</em></h1>
              <p className="hero-description">
                A structured learning space for IB MYP and Cambridge English
                learners. Know what to practise next—and see whether you have
                improved.
              </p>
              <div className="hero-actions">
                <a className="button button-dark" href="#pathways">
                  Explore pathways <span aria-hidden="true">→</span>
                </a>
                <a className="simple-link" href="#approach">
                  How it works <span aria-hidden="true">↘</span>
                </a>
              </div>
              <div className="hero-signature">
                <span className="signature-star" aria-hidden="true">✳</span>
                <p>
                  <strong>Learning that moves you forward.</strong>
                  <br />
                  Clear objectives. Useful practice. Feedback with a purpose.
                </p>
              </div>
            </div>

            <div className="learning-card" aria-label="Illustration of the planned learning journey">
              <div className="card-heading">
                <span>THE LEARNING JOURNEY</span>
                <span className="card-index">01 — 03</span>
              </div>
              <div className="journey-title">
                <span className="journey-icon" aria-hidden="true">↗</span>
                <div>
                  <p>A ROUTE THAT MAKES SENSE</p>
                  <h2>Progress, in practice.</h2>
                </div>
              </div>
              <div className="journey-steps">
                <div className="journey-step">
                  <span className="step-number">01</span>
                  <div>
                    <strong>Understand the skill</strong>
                    <p>Know what you’re learning and why.</p>
                  </div>
                  <span className="step-ring" />
                </div>
                <div className="journey-step">
                  <span className="step-number">02</span>
                  <div>
                    <strong>Practise with purpose</strong>
                    <p>Try questions connected to that skill.</p>
                  </div>
                  <span className="step-ring" />
                </div>
                <div className="journey-step">
                  <span className="step-number">03</span>
                  <div>
                    <strong>Choose your next step</strong>
                    <p>Use evidence and feedback to improve.</p>
                  </div>
                  <span className="step-ring" />
                </div>
              </div>
              <div className="journey-footer">
                <span aria-hidden="true">✳</span>
                Designed for progress, not guesswork.
              </div>
              <span className="hero-orbit orbit-a" aria-hidden="true" />
              <span className="hero-orbit orbit-b" aria-hidden="true" />
            </div>
          </div>
          <div className="hero-ribbon" aria-hidden="true">
            <span>LEARN WITH PURPOSE</span><span className="ribbon-line" /><span>GROW WITH EVIDENCE</span>
          </div>
        </section>

        <section className="pathways section-space" id="pathways">
          <div className="container">
            <div className="section-head">
              <div>
                <p className="eyebrow"><span /> START WITH THE RIGHT PATH</p>
                <h2>The right learning route<br />starts with <em>your world.</em></h2>
              </div>
              <p className="section-intro">
                Different programmes have different expectations. Begin with
                the pathway that matches your curriculum—not a one-size-fits-all
                course.
              </p>
            </div>
            <div className="pathway-grid">
              {pathways.map((pathway) => (
                <article className="pathway-card" key={pathway.number}>
                  <div className="pathway-card-top">
                    <span className="pathway-number">{pathway.number}</span>
                    <span className="programme-tag">{pathway.programme}</span>
                  </div>
                  <h3>{pathway.title}</h3>
                  <p className="pathway-stage">{pathway.stage}</p>
                  <p className="pathway-description">{pathway.description}</p>
                  <div className="pathway-card-bottom">
                    <span>PATHWAY PREVIEW</span>
                    <span className="planned-tag">Planned</span>
                  </div>
                </article>
              ))}
            </div>
            <p className="section-note">
              Stage 1 is a starter pathway, not exhaustive syllabus coverage.
              Curriculum mapping will be verified against official specifications
              before any learning content is published.
            </p>
          </div>
        </section>

        <section className="approach section-space" id="approach">
          <div className="container approach-layout">
            <div className="approach-copy">
              <p className="eyebrow"><span /> WHY THIS PLATFORM</p>
              <h2>More than a library.<br /><em>A clearer next step.</em></h2>
              <p>
                Finding notes is only the beginning. The aim is to connect the
                syllabus, a specific skill, deliberate practice and useful
                feedback in one learning space.
              </p>
              <a className="simple-link" href="#first-release">
                What we’re building <span aria-hidden="true">→</span>
              </a>
            </div>
            <div className="principle-list">
              {principles.map((principle) => (
                <article className="principle-row" key={principle.number}>
                  <span className="principle-number">{principle.number}</span>
                  <div>
                    <h3>{principle.title}</h3>
                    <p>{principle.detail}</p>
                  </div>
                  <span className="principle-symbol" aria-hidden="true">{principle.symbol}</span>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="first-release section-space" id="first-release">
          <div className="container release-panel">
            <div className="release-top">
              <span className="release-symbol" aria-hidden="true">✳</span>
              <span>THE FIRST RELEASE</span>
            </div>
            <div className="release-layout">
              <h2>English first.<br /><em>Built thoughtfully.</em></h2>
              <div>
                <p>
                  The initial build will focus on English learning pathways,
                  verified curriculum mapping, purposeful practice and a clear
                  foundation for learner progress. Mathematics is planned for a
                  later phase.
                </p>
                <p className="release-caveat">
                  This is an early preview, not a complete course or a live
                  student account system. Interactive learning tools and content
                  are still being built.
                </p>
                <a className="button button-light" href="#top">
                  Back to the beginning <span aria-hidden="true">↑</span>
                </a>
              </div>
            </div>
            <div className="release-motif" aria-hidden="true">
              {Array.from({ length: 25 }, (_, index) => <span key={index} />)}
            </div>
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <div className="container footer-inner">
          <a className="brand footer-brand" href="#top" aria-label="Criterion Lab home">
            <BrandMark />
            <span className="brand-words">
              <strong>criterion lab</strong>
              <small>WORKING NAME — NOT FINAL</small>
            </span>
          </a>
          <p>Know what to practise next—and see whether you have improved.</p>
          <span className="footer-meta">EARLY BUILD · 2026</span>
        </div>
      </footer>
    </div>
  );
}

export default App;
