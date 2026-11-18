"""SINRAS AI — Unified 5-in-1 FastAPI Backend Application.

Combines JWT Auth, Document Ingestion, Gemini + pgvector RAG, and the 5-in-1 Agent System
(LLM Gateway, Hybrid RAG, Read-Only Text-to-SQL, LangGraph Guardrails, Multilingual Engine, and Eval Harness).
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from .auth.router import router as auth_router
from .database import engine, Base
from .documents.router import router as documents_router
from .rag.router import router as rag_router
from .agent.router import router as agent_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: create tables and enable pgvector extension (if available).
    Shutdown: dispose of the database engine.
    """
    try:
        async with engine.begin() as conn:
            if engine.dialect.name == "postgresql":
                await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            await conn.run_sync(Base.metadata.create_all)
    except Exception as e:
        print(f"Warning: Database initialization skipped or deferred: {e}")
    yield
    try:
        await engine.dispose()
    except Exception:
        pass


app = FastAPI(
    title="SINRAS PRO AI — Unified 5-in-1 Backend API",
    description="Unified backend providing RAG, Multi-Agent Engine, Gateway, SQL Analyst, and Voice Assistant endpoints",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow Flutter app & web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router)
app.include_router(documents_router)
app.include_router(rag_router)
app.include_router(agent_router)


@app.get("/")
@app.get("/health")
async def health_check():
    """Simple health check endpoint."""
    return {
        "status": "ok",
        "service": "sinras-unified-api",
        "endpoints": [
            "/api/v1/agent/query",
            "/api/v1/agent/eval",
            "/api/v1/auth/login",
            "/api/v1/documents",
            "/api/v1/rag/query",
        ]
    }
