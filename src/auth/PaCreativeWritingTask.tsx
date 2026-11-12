import { countPaWords } from "./PaAnalyticalWritingTask";

/** One creative performance; CW01–CW05 are evidence dimensions, not separate submissions. */
export const creativeWritingObservationCodes = ["CW01", "CW02", "CW03", "CW04", "CW05"] as const;
export interface PaCreativeWritingResponse {
  plan: string;
  initial_draft: string;
  final_text: string;
  revision_before: string;
  revision_after: string;
  revision_note: string;
}
export const emptyCreativeWritingResponse: PaCreativeWritingResponse = {
  plan: "", initial_draft: "", final_text: "",
  revision_before: "", revision_after: "", revision_note: "",
};
export function isPaCreativeWritingResponse(value: PaCreativeWritingResponse): boolean {
  return value.plan.trim().length >= 5 && value.plan.length <= 1000
    && value.initial_draft.trim().length >= 5 && value.initial_draft.length <= 5000
    && value.final_text.trim().length >= 5 && value.final_text.length <= 5000
    && value.revision_before.trim().length >= 1 && value.revision_before.length <= 500
    && value.revision_after.trim().length >= 1 && value.revision_after.length <= 500
    && value.revision_before.trim() !== value.revision_after.trim()
    && value.revision_note.trim().length >= 5 && value.revision_note.length <= 1000;
}

export default function PaCreativeWritingTask({
  value, onChange, readOnly = false,
}: {
  value: PaCreativeWritingResponse;
  onChange: (next: PaCreativeWritingResponse) => void;
  readOnly?: boolean;
}) {
  const update = (field: keyof PaCreativeWritingResponse, text: string) =>
    onChange({ ...value, [field]: text });
  return <section aria-labelledby="pa-creative-writing-heading" className="proto-diagnostic-stimulus">
    <h3 id="pa-creative-writing-heading">Creative/Purposeful Production · The Book Swap</h3>
    <p>During a school open afternoon, rain moves the outdoor book swap into a busy hall. One small corner beside the windows is left unused.</p>
    <p>Write a short realistic narrative scene for readers aged 10–13 of the school magazine. Engage your readers and show how an unexpected change can help people see a shared space differently.</p>
    <p>Make one character notice something others have overlooked and choose what to do. Keep one viewpoint consistent and create an ending that grows naturally from the scene. Use dialogue, description and action where they help your purpose.</p>
    <p>Suggested time: 15 minutes, including planning and revision. Aim for 100–150 words (ideal 125); these are guidelines, not a word limit.</p>
    <label className="proto-diagnostic-text-field">
      <span>Your three plan notes: viewpoint, unexpected change, and ending choice</span>
      <textarea value={value.plan} maxLength={1000} rows={3} disabled={readOnly}
        onChange={event => update("plan", event.target.value)} />
    </label>
    <label className="proto-diagnostic-text-field">
      <span>Your initial draft</span>
      <textarea value={value.initial_draft} maxLength={5000} rows={6} disabled={readOnly}
        onChange={event => update("initial_draft", event.target.value)} />
    </label>
    <label className="proto-diagnostic-text-field">
      <span>Your revised final narrative scene</span>
      <textarea value={value.final_text} maxLength={5000} rows={8} disabled={readOnly}
        onChange={event => update("final_text", event.target.value)} />
      <small className="proto-diagnostic-word-count" aria-live="polite" aria-atomic="true">
        {countPaWords(value.final_text)} / 125 words
      </small>
    </label>
    <p>Record at least one purposeful edit to your draft. Your revision trace is separate from your narrative word count.</p>
    <label className="proto-diagnostic-text-field">
      <span>Original wording</span>
      <textarea value={value.revision_before} maxLength={500} rows={2} disabled={readOnly}
        onChange={event => update("revision_before", event.target.value)} />
    </label>
    <label className="proto-diagnostic-text-field">
      <span>Revised wording</span>
      <textarea value={value.revision_after} maxLength={500} rows={2} disabled={readOnly}
        onChange={event => update("revision_after", event.target.value)} />
    </label>
    <label className="proto-diagnostic-text-field">
      <span>How did this edit improve the scene?</span>
      <textarea value={value.revision_note} maxLength={1000} rows={3} disabled={readOnly}
        onChange={event => update("revision_note", event.target.value)} />
    </label>
  </section>;
}
