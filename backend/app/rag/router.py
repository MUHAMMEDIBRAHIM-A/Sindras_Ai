"""RAG query and chat history API endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth.dependencies import get_current_user
from ..database import get_db
from ..models import ChatMessage, ChatSession, User
from ..schemas import (
    ChatMessageResponse,
    ChatSessionResponse,
    RAGQueryRequest,
    RAGQueryResponse,
)
from .service import query_rag

router = APIRouter(prefix="/rag", tags=["RAG"])


@router.post("/query", response_model=RAGQueryResponse)
async def ask_question(
    body: RAGQueryRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Ask a question. Retrieves relevant chunks from your documents and
    generates a grounded answer with source citations."""
    if not body.question.strip():
        raise HTTPException(status_code=422, detail="Question cannot be empty")

    return await query_rag(
        db=db,
        user_id=current_user.id,
        question=body.question.strip(),
        session_id=body.session_id,
        top_k=body.top_k,
    )


@router.get("/sessions", response_model=list[ChatSessionResponse])
async def list_sessions(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all RAG chat sessions for the current user."""
    result = await db.execute(
        select(ChatSession)
        .where(ChatSession.user_id == current_user.id)
        .order_by(ChatSession.created_at.desc())
    )
    return result.scalars().all()


@router.get("/sessions/{session_id}/messages", response_model=list[ChatMessageResponse])
async def get_session_messages(
    session_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get all messages in a chat session. Owner-only access."""
    # Verify session ownership
    session_result = await db.execute(
        select(ChatSession).where(
            ChatSession.id == session_id,
            ChatSession.user_id == current_user.id,
        )
    )
    if session_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Session not found")

    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id)
        .order_by(ChatMessage.created_at.asc())
    )
    return result.scalars().all()
