"""Pydantic request/response schemas for the API."""

import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr


# ── Auth ─────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Documents ────────────────────────────────────────────────────────────

class DocumentResponse(BaseModel):
    id: uuid.UUID
    filename: str
    content_type: str
    total_pages: int
    uploaded_at: datetime

    model_config = {"from_attributes": True}


class DocumentListResponse(BaseModel):
    documents: list[DocumentResponse]
    total: int


# ── RAG ──────────────────────────────────────────────────────────────────

class RAGQueryRequest(BaseModel):
    question: str
    session_id: uuid.UUID | None = None  # None creates a new session
    top_k: int = 5


class SourceReference(BaseModel):
    document_name: str
    page_number: int
    chunk_text: str
    relevance_score: float


class RAGQueryResponse(BaseModel):
    answer: str
    sources: list[SourceReference]
    session_id: uuid.UUID


# ── Chat History ─────────────────────────────────────────────────────────

class ChatSessionResponse(BaseModel):
    id: uuid.UUID
    title: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatMessageResponse(BaseModel):
    id: uuid.UUID
    role: str
    content: str
    source_chunks: dict | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
