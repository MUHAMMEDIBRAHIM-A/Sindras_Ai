@echo off
echo Starting Synras AI Backend...

REM Activate virtual environment
call .venv\Scripts\activate.bat

REM Run FastAPI with uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
