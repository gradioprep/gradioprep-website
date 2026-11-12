/** Outline card only. Live spoken performance and follow-up require human assessment. */
export const speakingObservationCodes = ["SP01", "SP02", "SP03", "SP04", "SP05"] as const;

export interface PaSpeakingOutline {
  title: string;
  opening: string;
  development: string;
  consideration: string;
  closing: string;
}
export const emptySpeakingOutline: PaSpeakingOutline = {
  title: "", opening: "", development: "", consideration: "", closing: "",
};
export function isPaSpeakingOutline(value: PaSpeakingOutline): boolean {
  return (["title", "opening", "development", "consideration", "closing"] as const)
    .every(field => typeof value[field] === "string" && value[field].trim().length >= 3 && value[field].length <= 1000);
}

export default function PaSpeakingOutlineTask({
  value, onChange, readOnly = false,
}: {
  value: PaSpeakingOutline;
  onChange: (next: PaSpeakingOutline) => void;
  readOnly?: boolean;
}) {
  const fields: Array<{ key: keyof PaSpeakingOutline; label: string }> = [
    { key: "title", label: "Title of your proposal" },
    { key: "opening", label: "Opening: the use you recommend" },
    { key: "development", label: "Development: reasons and an example" },
    { key: "consideration", label: "Consideration: a different preference and your response" },
    { key: "closing", label: "Closing: the decision you recommend" },
  ];
  return <section className="proto-diagnostic-stimulus" aria-labelledby="pa-speaking-heading">
    <h3 id="pa-speaking-heading">Speaking/Presenting · A better shared space</h3>
    <p>Your school has one unused corner in a shared indoor area. The student council is collecting suggestions for how to use it.</p>
    <p>Prepare a short presentation recommending one practical use. Explain how it could serve students with different needs, address a concern, and finish with a clear recommendation.</p>
    <p>Use the five-part outline below as speaking notes, not as a full written speech. You do not need slides.</p>
    {fields.map(field => <label className="proto-diagnostic-text-field" key={field.key}>
      <span>{field.label}</span>
      <textarea rows={2} maxLength={1000} disabled={readOnly}
        value={value[field.key]}
        onChange={event => onChange({ ...value, [field.key]: event.target.value })} />
    </label>)}
    <p>During the assessed presentation, speak for up to three minutes. The assessor will then ask: “A student might prefer the corner to be used differently. What concern might they raise, and what would you say in response?”</p>
    <p>The outline is only preparation evidence. A qualified assessor must separately observe your live presentation and follow-up; your notes are not graded as spoken delivery.</p>
  </section>;
}
