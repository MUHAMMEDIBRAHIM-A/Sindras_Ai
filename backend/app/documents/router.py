"""Document management API endpoints."""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth.dependencies import get_current_user
from ..database import get_db
from ..models import Document, User
from ..schemas import DocumentListResponse, DocumentResponse
from .service import ingest_document

router = APIRouter(prefix="/documents", tags=["Documents"])


@router.post("/upload", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Upload a PDF, DOCX, or TXT file for RAG indexing.

    The file is parsed, chunked, embedded, and stored in the vector database.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    file_bytes = await file.read()

    try:
        doc = await ingest_document(
            db=db,
            user_id=current_user.id,
            filename=file.filename,
            content_type=file.content_type or "application/octet-stream",
            file_bytes=file_bytes,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))

    return doc


@router.get("", response_model=DocumentListResponse)
async def list_documents(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all documents uploaded by the current user."""
    result = await db.execute(
        select(Document)
        .where(Document.user_id == current_user.id)
        .order_by(Document.uploaded_at.desc())
    )
    docs = result.scalars().all()
    return DocumentListResponse(documents=docs, total=len(docs))


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a document and all its chunks. Owner-only access."""
    result = await db.execute(
        select(Document).where(
            Document.id == document_id,
            Document.user_id == current_user.id,  # Enforce ownership
        )
    )
    doc = result.scalar_one_or_none()
    if doc is None:
        raise HTTPException(status_code=404, detail="Document not found")

    await db.delete(doc)
    await db.flush()
