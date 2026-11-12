/** Read-only, version-bound PA evidence inspection. No marks or academic inferences. */
export interface PaObservation {
  observation_code?: string;
  group_code?: string;
  sitting_number?: number;
  sequence_number?: number;
}
export interface PaOutcome {
  outcome_reference?: string;
  outcome_title?: string;
  source_locator?: string;
  unit_code?: string;
}
export interface PaMapping {
  observation_code?: string;
  mapping_status?: string;
  direct_outcomes?: PaOutcome[];
}
export interface PaEvidence {
  observation_code?: string;
  response_sha256?: string | null;
}
export interface PaReportEvidenceSnapshot {
  content_snapshot?: { observations?: PaObservation[] };
  curriculum_mapping_snapshot?: PaMapping[];
  learner_evidence_snapshot?: PaEvidence[];
  curriculum_mapping_status: string;
  evidence_sufficiency_status: string;
}

export function paEvidenceRows(report: PaReportEvidenceSnapshot) {
  const observations = report.content_snapshot?.observations ?? [];
  const mappings = new Map((report.curriculum_mapping_snapshot ?? []).map(entry => [entry.observation_code, entry]));
  const evidence = new Map((report.learner_evidence_snapshot ?? []).map(entry => [entry.observation_code, entry]));
  return observations.map((observation, index) => {
    const code = observation.observation_code ?? "";
    const mapping = mappings.get(code);
    const outcomes = mapping?.mapping_status === "direct"
      ? (mapping.direct_outcomes ?? []).filter(outcome =>
        typeof outcome.outcome_reference === "string" && outcome.outcome_reference.trim().length > 0)
      : [];
    return {
      code: code || "Item " + (index + 1),
      group: observation.group_code || "Other",
      sitting: observation.sitting_number,
      saved: /^[a-f0-9]{64}$/i.test(evidence.get(code)?.response_sha256 ?? ""),
      mapped: outcomes.length > 0,
      outcomes,
    };
  });
}

export default function PaReportEvidenceReview({ report }: { report: PaReportEvidenceSnapshot }) {
  const rows = paEvidenceRows(report);
  const groups = Array.from(new Set(rows.map(item => item.group)));
  const saved = rows.filter(item => item.saved).length;
  const mapped = rows.filter(item => item.mapped).length;
  const ready = report.curriculum_mapping_status === "complete_direct"
    && report.evidence_sufficiency_status === "sufficient" && rows.length > 0
    && rows.every(item => item.saved && item.mapped);
  return <section aria-label="Report evidence review" className="proto-pa-report-evidence">
    <h4>Assessment evidence by segment</h4>
    <p>{rows.length} observations · {saved} responses recorded · {mapped} verified direct curriculum links</p>
    <p role="status">{ready
      ? "Saved evidence and curriculum connections meet the recorded report checks. Human academic review is still required."
      : "Review cannot be completed from these records yet. Missing responses or direct curriculum connections must be resolved."}</p>
    {groups.map(group => {
      const items = rows.filter(item => item.group === group);
      return <div key={group} className="proto-pa-evidence-group">
        <h5>{group} · {items.filter(item => item.saved).length}/{items.length} responses · {items.filter(item => item.mapped).length}/{items.length} curriculum links</h5>
        <ul>{items.map(item => <li key={item.code}>
          <strong>{item.code}</strong>
          {item.sitting ? <span> Sitting {item.sitting} </span> : null}
          <span>{item.saved ? "Response saved" : "Response missing"}</span>
          <span>{item.mapped ? "Direct mapping verified" : "Direct mapping unavailable"}</span>
          {item.outcomes.length > 0 && <ul aria-label={"Curriculum outcomes for " + item.code}>
            {item.outcomes.map((outcome, index) => <li key={item.code + "-" + index}>
              <strong>{outcome.outcome_reference}</strong>
              {outcome.outcome_title ? " — " + outcome.outcome_title : ""}
              {outcome.source_locator && <span> · Source: {outcome.source_locator}</span>}
            </li>)}
          </ul>}
        </li>)}</ul>
      </div>;
    })}
    {rows.length === 0 && <p>No observation evidence is recorded in this version.</p>}
    <p>This panel reflects the saved report snapshot. It does not calculate a grade, validate source editions, or replace teacher judgement.</p>
  </section>;
}
