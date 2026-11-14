import type { ChangeEvent } from "react";

const explanationPrompts = {
  RV04: {
    question: "Explain how one wording or layout choice in the poster helps its audience understand the poster's purpose. Refer to a specific detail.",
    range: "Response guidance: 20–30 words. Ideal target: 25 words; this is guidance, not a limit.",
    target: 25,
  },
  RV05: {
    question: "Explain how the poster's visual grouping and a specific outcome figure work together to communicate the event's results.",
    range: "Response guidance: 20–30 words. Ideal target: 25 words; this is guidance, not a limit.",
    target: 25,
  },
  LC01: {
    question: "Which words in the meeting description support the meaning you selected?",
    range: "Response guidance: 15–25 words. Ideal target: 20 words; this is guidance, not a limit.",
    target: 20,
  },
  LC02: {
    question: "Explain why moving the time phrase changes what the reader notices first without changing when the review happens. Compare both versions.",
    range: "Response guidance: 15–25 words. Ideal target: 20 words; this is guidance, not a limit.",
    target: 20,
  },
} as const;

export type ContextualChoiceCode = keyof typeof explanationPrompts;

export function requiresPaContextualExplanation(
  instrumentCode: string,
  instrumentVersion: number,
  observationCode: string,
): observationCode is ContextualChoiceCode {
  return instrumentCode === "ib-myp-g9-cycle1" && Number.isInteger(instrumentVersion)
    && instrumentVersion >= 2 && Object.prototype.hasOwnProperty.call(explanationPrompts, observationCode);
}

export function paChoiceResponse(
  instrumentCode: string,
  instrumentVersion: number,
  observationCode: string,
  choice?: string,
  explanation?: string,
): { choice: string; explanation?: string } | null {
  if (!choice || !["A", "B", "C", "D"].includes(choice)) return null;
  if (!requiresPaContextualExplanation(instrumentCode, instrumentVersion, observationCode)) {
    return { choice };
  }
  if (typeof explanation !== "string" || explanation.trim().length < 5 || explanation.length > 12000) return null;
  return { choice, explanation };
}

export default function PaContextualExplanationField({
  instrumentCode, instrumentVersion, code, value, onChange, disabled = false,
}: {
  instrumentCode: string;
  instrumentVersion: number;
  code: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}) {
  if (!requiresPaContextualExplanation(instrumentCode, instrumentVersion, code)) return null;
  const prompt = explanationPrompts[code];
  const count = value.trim() ? value.trim().split(/\s+/u).length : 0;
  const change = (event: ChangeEvent<HTMLTextAreaElement>) => onChange(event.target.value);
  return <label className="proto-diagnostic-text-field">
    <span>{prompt.question}</span>
    <small>{prompt.range}</small>
    <textarea rows={4} maxLength={12000} value={value} onChange={change} disabled={disabled} />
    <small className="proto-diagnostic-word-count" aria-live="polite" aria-atomic="true">
      {count} / {prompt.target} words
    </small>
  </label>;
}
