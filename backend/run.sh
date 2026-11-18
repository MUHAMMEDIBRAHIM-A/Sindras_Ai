#!/bin/bash
echo "Starting Synras AI Backend..."

# Activate virtual environment
source .venv/Scripts/activate 2>/dev/null || source .venv/bin/activate

# Run FastAPI with uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
