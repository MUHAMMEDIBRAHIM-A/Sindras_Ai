"""Document ingestion service: parse → chunk → embed → store."""

import uuid

import google.generativeai as genai
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..models import Chunk, Document
from .parsers import PageText, extract_text

# Configure Gemini SDK once
genai.configure(api_key=settings.gemini_api_key)

ALLOWED_TYPES = {
    "application/pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain",
}


def _chunk_pages(
    pages: list[PageText],
    chunk_size: int = settings.chunk_size,
    overlap: int = settings.chunk_overlap,
) -> list[dict]:
    """Split page texts into overlapping word-level chunks.

    Returns a list of dicts with keys: chunk_text, page_number, chunk_index.
    """
    chunks: list[dict] = []
    idx = 0

    for page in pages:
        words = page.text.split()
        start = 0
        while start < len(words):
            end = start + chunk_size
            chunk_text = " ".join(words[start:end])
            if chunk_text.strip():
                chunks.append({
                    "chunk_text": chunk_text,
                    "page_number": page.page_number,
                    "chunk_index": idx,
                })
                idx += 1
            start += chunk_size - overlap
            if start >= len(words):
                break

    return chunks


async def _embed_texts(texts: list[str]) -> list[list[float]]:
    """Generate embeddings for a batch of texts using Gemini embedding API.

    Processes in batches of 100 (API limit).
    """
    all_embeddings: list[list[float]] = []
    batch_size = 100

    for i in range(0, len(texts), batch_size):
        batch = texts[i : i + batch_size]
        result = genai.embed_content(
            model="models/text-embedding-004",
            content=batch,
            task_type="RETRIEVAL_DOCUMENT",
        )
        all_embeddings.extend(result["embedding"])

    return all_embeddings


async def ingest_document(
    db: AsyncSession,
    user_id: uuid.UUID,
    filename: str,
    content_type: str,
    file_bytes: bytes,
) -> Document:
    """Full ingestion pipeline: validate → extract → chunk → embed → save."""

    if content_type not in ALLOWED_TYPES:
        raise ValueError(f"Unsupported file type: {content_type}. Allowed: PDF, DOCX, TXT.")

    max_bytes = settings.max_upload_size_mb * 1024 * 1024
    if len(file_bytes) > max_bytes:
        raise ValueError(f"File exceeds {settings.max_upload_size_mb} MB limit.")

    # 1. Extract text
    pages = extract_text(file_bytes, content_type)
    if not pages:
        raise ValueError("No text could be extracted from the uploaded file.")

    # 2. Chunk
    chunk_dicts = _chunk_pages(pages)
    if not chunk_dicts:
        raise ValueError("File produced no usable text chunks.")

    # 3. Embed
    texts = [c["chunk_text"] for c in chunk_dicts]
    embeddings = await _embed_texts(texts)

    # 4. Save document record
    doc = Document(
        user_id=user_id,
        filename=filename,
        content_type=content_type,
        total_pages=max(p.page_number for p in pages),
    )
    db.add(doc)
    await db.flush()

    # 5. Save chunks with embeddings
    for chunk_dict, embedding in zip(chunk_dicts, embeddings):
        chunk = Chunk(
            document_id=doc.id,
            chunk_index=chunk_dict["chunk_index"],
            page_number=chunk_dict["page_number"],
            chunk_text=chunk_dict["chunk_text"],
            embedding=embedding,
        )
        db.add(chunk)

    await db.flush()
    return doc
