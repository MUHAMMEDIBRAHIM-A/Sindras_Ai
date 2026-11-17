import sys
import os

# Ensure parent directory is on sys.path for direct imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from agent.graph import ProductionAgentEngine
from evals.harness import run_evaluation_benchmark

app = FastAPI(title="5-in-1 Production AI System API", version="1.0.0")
agent_engine = ProductionAgentEngine()

class QueryRequest(BaseModel):
    query: str
    user_role: str = "finance"
    session_id: str = "default_session"

@app.get("/")
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "system": "5-in-1 Production AI Engine",
        "modules": ["LLM Gateway", "Hybrid RAG", "Read-Only Text-to-SQL", "LangGraph Guardrails", "Eval Harness"],
    }

@app.post("/query")
def process_user_query(req: QueryRequest):
    try:
        result = agent_engine.invoke({"query": req.query, "user_role": req.user_role})
        return {
            "status": result.get("status"),
            "intent": result.get("intent"),
            "output": result.get("final_output"),
            "citations": result.get("citations", []),
            "sql_data": result.get("sql_data", []),
            "recommended_chart": result.get("recommended_chart"),
            "requires_human_approval": result.get("requires_approval", False),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/eval")
def run_eval_suite():
    try:
        report = run_evaluation_benchmark(agent_engine)
        return {"status": "success", "benchmark_report": report}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
