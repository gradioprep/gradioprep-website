import { useEffect, useState } from "react";
import type { Navigate } from "../App";

interface ObservationSnapshot {
  observation_code?: string;
  group_code?: string;
  sitting_number?: number;
  sequence_number?: number;
}

interface MappingSnapshotEntry {
  observation_code?: string;
  mapping_status?: string;
  direct_outcomes?: unknown[];
}

interface LearnerEvidenceEntry {
  observation_code?: string;
  response_sha256?: string | null;
}

interface EvaluationReport {
  report_record_id: string;
  report_version_id: string;
  report_scope: string;
  version_number: number;
  curriculum_mapping_status: string;
  evidence_sufficiency_status: string;
  content_snapshot?: {
    total_minutes?: number;
    sitting_count?: number;
    observations?: ObservationSnapshot[];
  };
  curriculum_mapping_snapshot?: MappingSnapshotEntry[];
  learner_evidence_snapshot?: LearnerEvidenceEntry[];
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
  return {
    heading: "Not complete",
    description: "Some assessment tasks cannot yet be linked to a verified curriculum outcome.",
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
    heading: "Not yet sufficient",
    description: "The report does not yet meet the combined checks for response evidence and verified curriculum connections.",
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
    setReport(null);
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

  if (loading || (!report && !error)) {
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
  const observations = report.content_snapshot?.observations ?? [];
  const totalItems = observations.length;
  const responseRecords = (report.learner_evidence_snapshot ?? []).filter(
    entry => typeof entry.response_sha256 === "string" && /^[a-f0-9]{64}$/i.test(entry.response_sha256),
  ).length;
  const verifiedLinks = (report.curriculum_mapping_snapshot ?? []).filter(
    entry => entry.mapping_status === "direct" &&
      Array.isArray(entry.direct_outcomes) && entry.direct_outcomes.length > 0,
  ).length;
  const evidenceByCode = new Map((report.learner_evidence_snapshot ?? []).map(entry => [entry.observation_code, entry]));
  const mappingsByCode = new Map((report.curriculum_mapping_snapshot ?? []).map(entry => [entry.observation_code, entry]));
  const sittingCount = report.content_snapshot?.sitting_count;
  const totalMinutes = report.content_snapshot?.total_minutes;
  const createdAt = new Date(report.created_at);
  const createdLabel = Number.isNaN(createdAt.getTime())
    ? "Date unavailable"
    : createdAt.toLocaleDateString(undefined, { day: "numeric", month: "long", year: "numeric" });

  return <section className="proto-evaluation-report" aria-labelledby="proto-evaluation-report-heading">
    <div className="proto-panel proto-evaluation-hero">
      <div className="proto-evaluation-meta">
        <p className="proto-eyebrow"><span />PRELIMINARY ASSESSMENT</p>
        <span className="proto-evaluation-status">Submitted · Version {report.version_number}</span>
      </div>
      <h2 id="proto-evaluation-report-heading">Your starting point is recorded.</h2>
      <p>This report records the evidence saved with your submitted Preliminary Assessment. It is an initial record of your work, not a scored evaluation.</p>
      <small>Created {createdLabel}</small>
    </div>

    <section className="proto-panel proto-evaluation-coverage" aria-label="Assessment evidence summary">
      <div>
        <p className="proto-eyebrow">ASSESSMENT ITEMS</p>
        <strong>{totalItems || "—"}</strong>
        <span>Included in this report</span>
      </div>
      <div>
        <p className="proto-eyebrow">RESPONSES RECORDED</p>
        <strong>{responseRecords} <small>/ {totalItems || "—"}</small></strong>
        <span>Saved response records referenced</span>
      </div>
      <div>
        <p className="proto-eyebrow">CURRICULUM LINKS</p>
        <strong>{verifiedLinks} <small>/ {totalItems || "—"}</small></strong>
        <span>Items linked to verified outcomes</span>
      </div>
      <div>
        <p className="proto-eyebrow">ASSESSMENT PLAN</p>
        <strong>{sittingCount && totalMinutes ? sittingCount + " sittings" : "—"}</strong>
        <span>{totalMinutes ? totalMinutes + " planned minutes" : "Timing not recorded"}</span>
      </div>
    </section>

    <div className="proto-evaluation-grid">
      <article className="proto-panel proto-evaluation-card">
        <p className="proto-eyebrow">CURRICULUM CONNECTIONS</p>
        <h3>{mapping.heading}</h3>
        <p>{mapping.description}</p>
        <p className="proto-evaluation-detail">{verifiedLinks} of {totalItems || "the recorded"} items have a verified curriculum outcome link.</p>
      </article>
      <article className="proto-panel proto-evaluation-card">
        <p className="proto-eyebrow">RESPONSE EVIDENCE</p>
        <h3>{evidence.heading}</h3>
        <p>{evidence.description}</p>
        <p className="proto-evaluation-detail">{responseRecords} of {totalItems || "the recorded"} response records are referenced in this report. Your answer text is not copied into this summary.</p>
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

    <section className="proto-panel proto-evaluation-note" aria-labelledby="proto-evaluation-item-heading">
      <h3 id="proto-evaluation-item-heading">Your assessment evidence</h3>
      <p>Each entry shows whether a response was saved and whether its curriculum connection was verified. These are evidence checks, not marks or grades.</p>
      {observations.length === 0 ? <p>No item records are available in this report.</p> : (
        <ul className="proto-evaluation-observations">
          {observations.map((item, index) => {
            const code = item.observation_code ?? "";
            const response = evidenceByCode.get(code);
            const mappingEntry = mappingsByCode.get(code);
            const saved = typeof response?.response_sha256 === "string" && /^[a-f0-9]{64}$/i.test(response.response_sha256);
            const linked = mappingEntry?.mapping_status === "direct"
              && Array.isArray(mappingEntry.direct_outcomes) && mappingEntry.direct_outcomes.length > 0;
            return <li key={code || index}>
              <strong>{code || `Item ${index + 1}`}</strong>
              <span>{saved ? "Response saved" : "No saved response"}</span>
              <span>{linked ? "Curriculum connection verified" : "Curriculum connection unavailable"}</span>
            </li>;
          })}
        </ul>
      )}
    </section>

    <div className="proto-panel proto-evaluation-note">
      <h3>What this report contains</h3>
      <p>This report summarises the submitted assessment scope and the evidence records available to it. It does not contain a score, grade, percentile comparison, personalised feedback or recommended learning plan.</p>
    </div>
  </section>;
}
