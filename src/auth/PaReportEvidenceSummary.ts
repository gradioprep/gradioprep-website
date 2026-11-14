/** Counts distinct captured response sources, not rubric dimensions.
 * AW/CW/SP each have one learner submission assessed through five dimensions.
 * No response text or internal review metadata is used.
 */
export interface PaResponseEvidence {
  observation_code?: string;
  source_response_observation_code?: string;
  response_sha256?: string | null;
}
export interface PaInstrumentObservation {
  observation_code?: string;
}
const responseHash = /^[a-f0-9]{64}$/i;
const observationCode = /^(?:RV|LC|AW|CW|SP)[0-9]{2}[ab]?$/;

export function paResponseSourceSummary(
  observations: PaInstrumentObservation[],
  evidence: PaResponseEvidence[],
): { recorded: number; expected: number } {
  const recognizedCodes = new Set(observations.map(x => x.observation_code)
    .filter((code): code is string => typeof code === "string" && observationCode.test(code)));
  const expected = new Set<string>();
  for (const code of recognizedCodes) {
    const source = /^(AW|CW|SP)0[1-5]$/.test(code) ? code.slice(0, 2) + "01" : code;
    expected.add(source);
  }
  const evidenceByCode = new Map(evidence.map(x => [x.observation_code, x]));
  const recorded = new Set<string>();
  for (const code of recognizedCodes) {
    const entry = evidenceByCode.get(code);
    if (!entry || !responseHash.test(entry.response_sha256 ?? "")) continue;
    const source = entry.source_response_observation_code ?? code;
    if (!expected.has(source)) continue;
    if ((/^(AW|CW|SP)/.test(code) && source !== code.slice(0, 2) + "01")
      || (!/^(AW|CW|SP)/.test(code) && source !== code)) continue;
    recorded.add(source);
  }
  return { recorded: recorded.size, expected: expected.size };
}
