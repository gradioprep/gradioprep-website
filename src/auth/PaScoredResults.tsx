/** Learner-only presentation of an already published, human-approved PA scoring snapshot.
 * Never infer approval from numerical marks alone or expose private review metadata.
 */
export interface PublishedPaDimension {
  observation_code?: string;
  points_awarded?: number;
  points_possible?: number;
}
export interface PublishedPaScoring {
  status?: string;
  dimension_count?: number;
  dimensions?: PublishedPaDimension[];
  points_awarded?: number;
  points_possible?: number;
  attainment_percent?: number;
}
export interface PublishedPaSnapshot {
  published_feedback_snapshot?: { status?: string; feedback_text?: string };
  eligible_analytics_snapshot?: { pa_human_scoring?: PublishedPaScoring };
}

const finite = (n: unknown): n is number => typeof n === "number" && Number.isFinite(n);
const close = (a: number, b: number) => Math.abs(a - b) < 0.002;

export function approvedPaScoring(report: PublishedPaSnapshot): PublishedPaScoring | null {
  const score = report.eligible_analytics_snapshot?.pa_human_scoring;
  if (report.published_feedback_snapshot?.status !== "human_approved_published"
    || !report.published_feedback_snapshot.feedback_text?.trim()
    || score?.status !== "human_approved" || score.dimension_count !== 30
    || !Array.isArray(score.dimensions) || score.dimensions.length !== 30
    || !finite(score.points_awarded) || !finite(score.points_possible)
    || !finite(score.attainment_percent) || score.points_possible <= 0
    || score.points_awarded < 0 || score.points_awarded > score.points_possible
    || score.attainment_percent < 0 || score.attainment_percent > 100) return null;

  const seen = new Set<string>();
  let awarded = 0;
  let possible = 0;
  for (const dim of score.dimensions) {
    if (!dim || typeof dim.observation_code !== "string"
      || !/^(RV|LC|AW|CW|SP)[0-9]{2}[ab]?$/.test(dim.observation_code)
      || seen.has(dim.observation_code)
      || !finite(dim.points_awarded) || !finite(dim.points_possible)
      || dim.points_possible <= 0 || dim.points_awarded < 0
      || dim.points_awarded > dim.points_possible) return null;
    seen.add(dim.observation_code);
    awarded += dim.points_awarded;
    possible += dim.points_possible;
  }
  if (!close(awarded, score.points_awarded)
    || !close(possible, score.points_possible)
    || !close(100 * awarded / possible, score.attainment_percent)) return null;
  const groupCounts = { RV: 10, LC: 5, AW: 5, CW: 5, SP: 5 };
  if (Object.entries(groupCounts).some(([group, expected]) =>
    [...seen].filter(code => code.startsWith(group)).length !== expected)) return null;
  return score;
}

export default function PaScoredResults({ score }: { score: PublishedPaScoring }) {
  const dimensions = score.dimensions ?? [];
  return <section className="proto-panel proto-evaluation-note" aria-labelledby="proto-pa-approved-scores">
    <h3 id="proto-pa-approved-scores">Human-reviewed assessment results</h3>
    <p><strong>{score.points_awarded} of {score.points_possible} rubric points</strong> · {score.attainment_percent}% attainment on this assessment</p>
    <p>These points reflect teacher-approved task rubrics, not an official IB grade, class rank or predicted result. Different criteria can have different point maxima.</p>
    <h4>Scored evidence by assessment segment</h4>
    <ul className="proto-evaluation-observations">
      {(["RV", "LC", "AW", "CW", "SP"] as const).map(group => {
        const entries = dimensions.filter(dim => dim.observation_code?.startsWith(group));
        const points = entries.reduce((sum, dim) => sum + (dim.points_awarded ?? 0), 0);
        const maximum = entries.reduce((sum, dim) => sum + (dim.points_possible ?? 0), 0);
        const names: Record<string, string> = {
          RV: "Read and View", LC: "Language in Context",
          AW: "Analytical Writing", CW: "Creative and Purposeful Production",
          SP: "Speaking and Presenting",
        };
        return <li key={group}>
          <strong>{names[group]}</strong>
          <span>{points} / {maximum} rubric points</span>
          <ul aria-label={names[group] + " assessment evidence"}>
            {entries.map(dim => <li key={dim.observation_code}>
              <strong>{dim.observation_code}</strong>
              <span>{dim.points_awarded} / {dim.points_possible}</span>
            </li>)}
          </ul>
        </li>;
      })}
    </ul>
  </section>;
}
