"""FastAPI router for the 5-in-1 SINRAS PRO Agent System & Benchmark Evaluations."""

import sys
import os

# Add agent_system root to sys.path
agent_system_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "agent_system")
if agent_system_dir not in sys.path:
    sys.path.insert(0, agent_system_dir)

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

from agent.graph import ProductionAgentEngine
from evals.harness import run_evaluation_benchmark

router = APIRouter(prefix="/api/v1/agent", tags=["5-in-1 Agent System"])
agent_engine = ProductionAgentEngine()

class AgentQueryRequest(BaseModel):
    query: str
    user_role: Optional[str] = "finance"
    session_id: Optional[str] = "default_session"

class AgentQueryResponse(BaseModel):
    intent: str
    detected_language: str
    target_language: str
    status: str
    voice_summary: str
    display_markdown: str
    citations: List[Dict[str, Any]] = []
    sql_data: List[Dict[str, Any]] = []
    recommended_chart: Optional[str] = None
    requires_human_approval: bool = False

@router.post("/query", response_model=AgentQueryResponse)
async def query_agent(req: AgentQueryRequest):
    """Execute query through central LangGraph agent engine with Multilingual & Guardrails rules."""
    try:
        user_role = req.user_role or "finance"
        result = agent_engine.invoke({
            "query": req.query,
            "user_role": user_role,
        })
        return AgentQueryResponse(
            intent=result.get("intent", "quick_query"),
            detected_language=result.get("detected_language", "en"),
            target_language=result.get("target_language", "en"),
            status=result.get("status", "completed"),
            voice_summary=result.get("voice_summary", ""),
            display_markdown=result.get("display_markdown", ""),
            citations=result.get("citations", []),
            sql_data=result.get("sql_data", []),
            recommended_chart=result.get("recommended_chart"),
            requires_human_approval=result.get("requires_approval", False),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Agent Execution Error: {str(e)}",
        )

@router.get("/eval")
async def run_agent_evals():
    """Run automated quality & safety evaluation benchmark suite."""
    try:
        report = run_evaluation_benchmark(agent_engine)
        return {"status": "success", "benchmark_report": report}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Evaluation Error: {str(e)}",
        )
