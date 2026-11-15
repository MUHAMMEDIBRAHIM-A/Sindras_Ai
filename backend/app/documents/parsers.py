"""Document text extraction for PDF, DOCX, and TXT files."""

from dataclasses import dataclass

import fitz  # PyMuPDF
from docx import Document as DocxDocument


@dataclass
class PageText:
    """Represents extracted text from a single page."""
    page_number: int
    text: str


def extract_pdf(file_bytes: bytes) -> list[PageText]:
    """Extract text from each page of a PDF."""
    pages: list[PageText] = []
    with fitz.open(stream=file_bytes, filetype="pdf") as doc:
        for i, page in enumerate(doc):
            text = page.get_text("text").strip()
            if text:
                pages.append(PageText(page_number=i + 1, text=text))
    return pages


def extract_docx(file_bytes: bytes) -> list[PageText]:
    """Extract text from a DOCX file.

    DOCX doesn't have native page boundaries, so we treat the entire
    document as a single page and split by paragraphs for chunking.
    """
    import io
    doc = DocxDocument(io.BytesIO(file_bytes))
    full_text = "\n".join(p.text for p in doc.paragraphs if p.text.strip())
    if not full_text.strip():
        return []
    return [PageText(page_number=1, text=full_text)]


def extract_txt(file_bytes: bytes) -> list[PageText]:
    """Extract text from a plain text file."""
    text = file_bytes.decode("utf-8", errors="replace").strip()
    if not text:
        return []
    return [PageText(page_number=1, text=text)]


def extract_text(file_bytes: bytes, content_type: str) -> list[PageText]:
    """Route to the correct parser based on MIME type."""
    parsers = {
        "application/pdf": extract_pdf,
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document": extract_docx,
        "text/plain": extract_txt,
    }
    parser = parsers.get(content_type)
    if parser is None:
        raise ValueError(f"Unsupported file type: {content_type}")
    return parser(file_bytes)
