import type { ChangeEvent } from "react";

const RESPONSE_WORD_PATTERN =
  /[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+|[-\u2010\u2011][\p{L}\p{N}]+)*/gu;

/**
 * Counts lexical words consistently with the content-rights word-count rule:
 * letters/digits form words; punctuation-only tokens are ignored; contractions
 * and hyphenated compounds count as one word.
 */
export function countResponseWords(value: string): number {
  return value.match(RESPONSE_WORD_PATTERN)?.length ?? 0;
}

interface ResponseWordCountTextareaProps {
  id: string;
  value: string;
  idealWords: number;
  rows: number;
  placeholder?: string;
  onChange: (value: string) => void;
}

/** Reusable, non-restrictive counter field for every learner typed response. */
export function ResponseWordCountTextarea({
  id,
  value,
  idealWords,
  rows,
  placeholder,
  onChange,
}: ResponseWordCountTextareaProps) {
  const countId = id + "-word-count";

  return (
    <>
      <textarea
        id={id}
        rows={rows}
        value={value}
        placeholder={placeholder}
        aria-describedby={countId}
        onChange={(event: ChangeEvent<HTMLTextAreaElement>) => onChange(event.currentTarget.value)}
      />
      <small
        id={countId}
        className="proto-response-word-count"
        role="status"
        aria-live="polite"
        aria-atomic="true"
      >
        {countResponseWords(value)}/{idealWords} words
      </small>
    </>
  );
}
