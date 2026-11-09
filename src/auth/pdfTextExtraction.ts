import { getDocument, GlobalWorkerOptions } from "pdfjs-dist";
import pdfWorkerUrl from "pdfjs-dist/build/pdf.worker.min.mjs?url";

GlobalWorkerOptions.workerSrc = pdfWorkerUrl;

export interface ExtractedPdfTranscriptPage {
  page_number: number;
  text: string;
  status: "digital_text" | "no_text_layer";
}

export interface ExtractedPdfTranscript {
  extraction_method: "pdfjs";
  page_count: number;
  pages: ExtractedPdfTranscriptPage[];
  no_text_layer_pages: number[];
}

const maximumPages = 10;
const maximumPageTextCharacters = 12_000;
const maximumTranscriptCharacters = 120_000;

/**
 * Extract text already present in a PDF's digital text layer.
 *
 * This deliberately does not perform OCR. A page with no extractable digital
 * text is preserved as an explicit "no_text_layer" page so a reviewer can
 * inspect the original PDF; the app never guesses or fabricates its contents.
 */
export async function extractDigitalTextFromPdf(file: File): Promise<ExtractedPdfTranscript> {
  const bytes = new Uint8Array(await file.arrayBuffer());
  const loadingTask = getDocument({
    data: bytes,
    useWorkerFetch: false,
  });

  try {
    const document = await loadingTask.promise;
    const pageCount = document.numPages;
    if (!Number.isInteger(pageCount) || pageCount < 1 || pageCount > maximumPages) {
      throw new Error("The PDF must contain between 1 and 10 pages.");
    }

    const pages: ExtractedPdfTranscriptPage[] = [];
    const noTextLayerPages: number[] = [];
    let transcriptLength = 0;

    for (let pageNumber = 1; pageNumber <= pageCount; pageNumber += 1) {
      const page = await document.getPage(pageNumber);
      const textContent = await page.getTextContent();
      const extracted = textContent.items
        .filter((item) => "str" in item && typeof item.str === "string")
        .map((item) => {
          if (!("str" in item) || typeof item.str !== "string") return "";
          const value = item.str.trim();
          return value ? value + (item.hasEOL ? "\n" : " ") : "";
        })
        .join("")
        .replace(/[ \t]+/g, " ")
        .replace(/ *\n */g, "\n")
        .trim();

      if (extracted.length > maximumPageTextCharacters) {
        throw new Error("A page contains more digital text than the supported transcript limit.");
      }
      transcriptLength += extracted.length;
      if (transcriptLength > maximumTranscriptCharacters) {
        throw new Error("The PDF's extracted text exceeds the supported transcript limit.");
      }

      if (extracted.length === 0) {
        noTextLayerPages.push(pageNumber);
        pages.push({ page_number: pageNumber, text: "", status: "no_text_layer" });
      } else {
        pages.push({ page_number: pageNumber, text: extracted, status: "digital_text" });
      }
      page.cleanup();
    }

    return {
      extraction_method: "pdfjs",
      page_count: pageCount,
      pages,
      no_text_layer_pages: noTextLayerPages,
    };
  } finally {
    await loadingTask.destroy();
  }
}
