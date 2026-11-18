@echo off
echo Setting up Synras AI Backend ^& Databases (Local SQLite Mode)...

REM Setup Python environment
if not exist ".venv" (
    echo Creating virtual environment...
    python -m venv .venv
)

echo Activating virtual environment and installing dependencies...
call .venv\Scripts\activate.bat
pip install -r requirements.txt

echo Setup complete! Fill in your .env file with your GEMINI_API_KEY.
echo Run the backend with: run.bat
pause
