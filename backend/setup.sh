#!/bin/bash
echo "Setting up Synras AI Backend & Databases..."

# 1. Start Docker containers (PostgreSQL, Redis, Qdrant)
docker-compose up -d

# 2. Setup Python environment
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python -m venv .venv
fi

echo "Activating virtual environment and installing dependencies..."
source .venv/Scripts/activate 2>/dev/null || source .venv/bin/activate
pip install -r requirements.txt

echo "Setup complete! Fill in your .env file with your GEMINI_API_KEY."
echo "Run the backend with: ./run.sh"
