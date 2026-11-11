import { useEffect, useState } from "react";
import type { Navigate } from "../App";

interface EvaluationReport {
  report_record_id: string;
  report_version_id: string;
  report_scope: string;
  version_number: number;
  curriculum_mapping_status: string;
  evidence_sufficiency_status: string;
  created_at: string;
}

interface EvaluationReportResponse {
  report?: EvaluationReport;
  error?: string;
}

function curriculumConnection(status: string): { heading: string; description: string } {
  if (status === "complete_direct") {
    return {
      heading: "Connected",
      description: "The assessment tasks are connected to verified curriculum outcomes.",
    };
  }
  if (status === "pending_review") {
    return {
      heading: "Being confirmed",
      description: "Some curriculum connections are still being confirmed.",
    };
  }
  return {
    heading: "Not complete",
    description: "Some assessment tasks do not yet have verified curriculum connections.",
  };
}

function responseEvidence(status: string): { heading: string; description: string } {
  if (status === "sufficient") {
    return {
      heading: "Evidence recorded",
      description: "The evidence recorded for this report meets its current coverage checks.",
    };
  }
  return {
    heading: "More evidence needed",
    description: "The current report does not yet contain enough mapped evidence for a complete evaluation.",
  };
}

export default function EvaluationReportPanel({
  accessToken,
  reportRecordId,
  go,
}: {
  accessToken: string;
  reportRecordId: string;
  go: Navigate;
}) {
  const [report, setReport] = useState<EvaluationReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [retryCount, setRetryCount] = useState(0);

  useEffect(() => {
    if (!accessToken || !reportRecordId) {
      setReport(null);
      setError("");
      setLoading(false);
      return;
    }
    let active = true;
    setLoading(true);
    setError("");
    fetch("/api/v1/learner/evaluation-reports/" + reportRecordId, {
      headers: { Authorization: "Bearer " + accessToken },
      cache: "no-store",
    })
      .then(async response => {
        const result = await response.json() as EvaluationReportResponse;
        if (!response.ok || !result.report || result.report.report_scope !== "pa_baseline") {
          throw new Error("The Evaluation Report could not be loaded.");
        }
        return result.report;
      })
      .then(nextReport => {
        if (active) setReport(nextReport);
      })
      .catch(() => {
        if (active) {
          setReport(null);
          setError("We couldn't load your Evaluation Report. Please try again.");
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [accessToken, reportRecordId, retryCount]);

  if (!accessToken) {
    return <section className="proto-panel proto-evaluation-empty" aria-labelledby="proto-evaluation-signin">
      <h2 id="proto-evaluation-signin">Sign in to view your Evaluation Report.</h2>
      <p>Your report is available only to the account that submitted the Preliminary Assessment.</p>
      <button className="proto-action" type="button" onClick={() => go("account")}>Sign in →</button>
    </section>;
  }

  if (!reportRecordId) {
    return <section className="proto-panel proto-evaluation-empty" aria-labelledby="proto-evaluation-empty">
      <h2 id="proto-evaluation-empty">Start with your Preliminary Assessment.</h2>
      <p>Your Evaluation Report will appear here after you submit the Preliminary Assessment.</p>
      <button className="proto-action secondary" type="button" onClick={() => go("account")}>Open your account →</button>
    </section>;
  }

  if (loading) {
    return <section className="proto-panel proto-evaluation-empty" role="status">Loading your Evaluation Report…</section>;
  }

  if (error || !report) {
    return <section className="proto-panel proto-evaluation-empty" aria-labelledby="proto-evaluation-error">
      <h2 id="proto-evaluation-error">Your Evaluation Report is unavailable.</h2>
      <p>{error || "We couldn't load your Evaluation Report. Please try again."}</p>
      <button className="proto-action secondary" type="button" onClick={() => setRetryCount(value => value + 1)}>Try again</button>
    </section>;
  }

  const mapping = curriculumConnection(report.curriculum_mapping_status);
  const evidence = responseEvidence(report.evidence_sufficiency_status);
  const createdAt = new Date(report.created_at);
  const createdLabel = Number.isNaN(createdAt.getTime())
    ? "Date unavailable"
    : createdAt.toLocaleDateString(undefined, { day: "numeric", month: "long", year: "numeric" });

  return <section className="proto-evaluation-report" aria-labelledby="proto-evaluation-report-heading">
    <div className="proto-panel proto-evaluation-hero">
      <div className="proto-evaluation-meta">
        <p className="proto-eyebrow"><span />PRELIMINARY ASSESSMENT</p>
        <span className="proto-evaluation-status">Submitted</span>
      </div>
      <h2 id="proto-evaluation-report-heading">Your starting point is recorded.</h2>
      <p>This report records the evidence saved with your submitted Preliminary Assessment. It is an initial record of your work, not a scored evaluation.</p>
      <small>Created {createdLabel}</small>
    </div>

    <div className="proto-evaluation-grid">
      <article className="proto-panel proto-evaluation-card">
        <p className="proto-eyebrow">CURRICULUM CONNECTIONS</p>
        <h3>{mapping.heading}</h3>
        <p>{mapping.description}</p>
      </article>
      <article className="proto-panel proto-evaluation-card">
        <p className="proto-eyebrow">RESPONSE EVIDENCE</p>
        <h3>{evidence.heading}</h3>
        <p>{evidence.description}</p>
      </article>
      <article className="proto-panel proto-evaluation-card">
        <p className="proto-eyebrow">PERSONALISED FEEDBACK</p>
        <h3>Not included</h3>
        <p>This starting report does not include personalised feedback.</p>
      </article>
      <article className="proto-panel proto-evaluation-card">
        <p className="proto-eyebrow">ASSESSMENT RESULTS</p>
        <h3>Not scored</h3>
        <p>This report does not contain a score, grade or percentile comparison.</p>
      </article>
    </div>

    <div className="proto-panel proto-evaluation-note">
      <h3>Using your report</h3>
      <p>Scores, grade comparisons and personalised next steps will appear only when the available evidence and curriculum connections can support them.</p>
    </div>
  </section>;
}
