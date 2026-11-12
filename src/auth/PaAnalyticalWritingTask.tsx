/** Original learner-safe AW task draft. Not routed or released until Year 4 academic approval. */
export const analyticalWritingObservationCodes = ["AW01", "AW02", "AW03", "AW04", "AW05"] as const;
export const analyticalWritingPassage = [
  "By four o’clock, the gallery had grown quiet. Arun stood before a blue cup on a square of white cloth. A thin crack ran from its handle to the rim, stopping just short of the painted bird.",
  "The donor, Mrs Iqbal, had told him that her mother carried the cup to the first day of the neighbourhood clinic. “She said it made the room feel less like a waiting room,” she had added.",
  "Arun’s first label was neat and certain: “This cup was used at the clinic’s opening in 1986.” Ms Vale, the curator, read it twice. “What tells us the year?” she asked.",
  "He looked at the notebook. It contained Mrs Iqbal’s words, but no date, no photograph, no record. The sentence, once printed, would seem more certain than the memory behind it.",
  "Arun crossed out “was used” and wrote “is remembered as”. The new phrase seemed weaker, though it was more exact.",
  "On opening morning, Mrs Iqbal found the label and read it slowly. “Yes,” she said. “That is what I told you.”",
  "Arun waited for her to ask for the old wording. Instead, she bent towards the cup. The crack caught the gallery light; the little painted bird remained whole. Then she stepped aside to let the next visitor come closer.",
] as const;

export function countPaWords(value: string): number {
  const trimmed = value.trim();
  return trimmed ? trimmed.split(/\s+/u).length : 0;
}

export function isPaAnalyticalWritingResponse(value: string): boolean {
  return value.trim().length >= 5 && value.length <= 12000;
}

export default function PaAnalyticalWritingTask({
  value, onChange, readOnly = false,
}: {
  value: string;
  onChange: (value: string) => void;
  readOnly?: boolean;
}) {
  return <section aria-labelledby="pa-analytical-writing-heading" className="proto-diagnostic-stimulus">
    <h3 id="pa-analytical-writing-heading">Analytical Writing · The Unfinished Label</h3>
    <p>Read the passage, then write one response to the question below.</p>
    {analyticalWritingPassage.map((paragraph, index) => <p key={index}>{paragraph}</p>)}
    <p><strong>Question:</strong> Analyse how the writer uses Arun’s changing label and details of the cup to explore the difference between preserving a memory and presenting it as fact.</p>
    <p>Develop a clear interpretation and support it with precise evidence from the passage. Explain how the writer’s choices shape the reader’s understanding.</p>
    <p>You may analyse wording, imagery, contrast or the progression of events where relevant. Focus on explaining how the details contribute to meaning rather than retelling the plot.</p>
    <label className="proto-diagnostic-text-field">
      <span>Your analytical response</span>
      <small>Suggested length: 150–200 words. Ideal target: 180 words. This is guidance, not a limit.</small>
      <textarea rows={9} maxLength={12000} value={value} disabled={readOnly}
        onChange={event => onChange(event.target.value)} />
      <small className="proto-diagnostic-word-count" aria-live="polite" aria-atomic="true">
        {countPaWords(value)} / 180 words
      </small>
    </label>
  </section>;
}
