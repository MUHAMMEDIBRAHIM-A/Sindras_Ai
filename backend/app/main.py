"""SINRAS AI — FastAPI Backend Application.

Production-ready RAG system with JWT auth, document ingestion, and
vector-powered question answering using Gemini + pgvector.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from .auth.router import router as auth_router
from .database import engine, Base
from .documents.router import router as documents_router
from .rag.router import router as rag_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: create tables and enable pgvector extension.
    Shutdown: dispose of the database engine.
    """
    async with engine.begin() as conn:
        # Enable pgvector extension
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        # Create all tables
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title="SINRAS AI RAG API",
    description="Backend for document-grounded AI question answering",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow Flutter app (adjust origins for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router)
app.include_router(documents_router)
app.include_router(rag_router)


@app.get("/health")
async def health_check():
    """Simple health check endpoint."""
    return {"status": "ok", "service": "sinras-rag-api"}
