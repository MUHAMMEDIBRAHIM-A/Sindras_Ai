"""RAG query service: embed question → vector search → grounded LLM answer."""

import uuid

import google.generativeai as genai
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..models import ChatMessage, ChatSession, Chunk, Document
from ..schemas import RAGQueryResponse, SourceReference

# Configure Gemini SDK
genai.configure(api_key=settings.gemini_api_key)

SYSTEM_PROMPT = """You are SINRAS AI, an intelligent assistant that answers questions using ONLY the provided context from the user's uploaded documents.

Rules:
1. Answer the question based STRICTLY on the provided context snippets.
2. If the answer is not found in the context, clearly state: "I couldn't find information about this in your uploaded documents."
3. Always cite your sources using the format: [Source: filename, Page N]
4. Be concise, accurate, and well-structured.
5. If multiple sources support the answer, cite all of them.
6. Never make up information that isn't in the context."""


async def _embed_query(question: str) -> list[float]:
    """Generate embedding for the user's question."""
    result = genai.embed_content(
        model="models/text-embedding-004",
        content=question,
        task_type="RETRIEVAL_QUERY",
    )
    return result["embedding"]


async def _vector_search(
    db: AsyncSession,
    user_id: uuid.UUID,
    query_embedding: list[float],
    top_k: int = 5,
) -> list[dict]:
    """Search for the most relevant chunks across the user's documents.

    Uses pgvector cosine distance operator (<=>).
    Returns chunk text, page number, document filename, and similarity score.
    """
    embedding_str = "[" + ",".join(str(v) for v in query_embedding) + "]"

    query = text("""
        SELECT
            c.id,
            c.chunk_text,
            c.page_number,
            d.filename,
            1 - (c.embedding <=> :embedding::vector) AS similarity
        FROM chunks c
        JOIN documents d ON c.document_id = d.id
        WHERE d.user_id = :user_id
        ORDER BY c.embedding <=> :embedding::vector
        LIMIT :top_k
    """)

    result = await db.execute(
        query,
        {
            "embedding": embedding_str,
            "user_id": str(user_id),
            "top_k": top_k,
        },
    )

    rows = result.fetchall()
    return [
        {
            "chunk_id": str(row[0]),
            "chunk_text": row[1],
            "page_number": row[2],
            "filename": row[3],
            "similarity": float(row[4]),
        }
        for row in rows
    ]


def _build_grounded_prompt(question: str, context_chunks: list[dict]) -> str:
    """Build the augmented prompt with retrieved context and citations."""
    context_parts = []
    for i, chunk in enumerate(context_chunks, 1):
        context_parts.append(
            f"[{i}] {chunk['chunk_text']}\n"
            f"    — Source: {chunk['filename']}, Page {chunk['page_number']}"
        )

    context_text = "\n\n".join(context_parts)

    return f"""Context from user's documents:

{context_text}

---

User's Question: {question}"""


async def query_rag(
    db: AsyncSession,
    user_id: uuid.UUID,
    question: str,
    session_id: uuid.UUID | None = None,
    top_k: int = 5,
) -> RAGQueryResponse:
    """Execute the full RAG pipeline: embed → search → generate → save."""

    # 1. Embed the question
    query_embedding = await _embed_query(question)

    # 2. Vector search (user-scoped)
    context_chunks = await _vector_search(db, user_id, query_embedding, top_k)

    if not context_chunks:
        answer = "You haven't uploaded any documents yet, or no relevant content was found. Please upload documents first."
        sources = []
    else:
        # 3. Build grounded prompt
        grounded_prompt = _build_grounded_prompt(question, context_chunks)

        # 4. Call Gemini LLM
        model = genai.GenerativeModel(
            model_name="gemini-2.0-flash",
            system_instruction=SYSTEM_PROMPT,
        )
        response = model.generate_content(grounded_prompt)
        answer = response.text or "No response generated."

        # 5. Build source references
        sources = [
            SourceReference(
                document_name=c["filename"],
                page_number=c["page_number"],
                chunk_text=c["chunk_text"][:200] + "..." if len(c["chunk_text"]) > 200 else c["chunk_text"],
                relevance_score=round(c["similarity"], 4),
            )
            for c in context_chunks
        ]

    # 6. Save to chat history
    if session_id is None:
        # Create new session with auto-title from question
        title = question[:80] + "..." if len(question) > 80 else question
        session = ChatSession(user_id=user_id, title=title)
        db.add(session)
        await db.flush()
        session_id = session.id

    # Save user message
    user_msg = ChatMessage(
        session_id=session_id,
        role="user",
        content=question,
    )
    db.add(user_msg)

    # Save assistant message with source references
    source_data = {
        "chunks": [
            {"filename": c["filename"], "page": c["page_number"], "chunk_id": c["chunk_id"]}
            for c in context_chunks
        ]
    }
    assistant_msg = ChatMessage(
        session_id=session_id,
        role="assistant",
        content=answer,
        source_chunks=source_data,
    )
    db.add(assistant_msg)
    await db.flush()

    return RAGQueryResponse(
        answer=answer,
        sources=sources,
        session_id=session_id,
    )
