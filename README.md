# 🏆 SINRAS AI — SINRAS PRO OS & Multi-Agent RAG Platform (A to Z Guide)

> **The Ultimate Next-Generation Cross-Platform Autonomous AI Mobile Operating System & Grounded Enterprise RAG System.**  
> Powered by **Flutter 3**, **FastAPI**, **PostgreSQL + pgvector**, and **Multi-Provider LLM Core (Groq, DeepSeek, Google Gemini)**.

---

## 📑 Table of Contents
1. [🌟 Executive Overview](#-executive-overview)
2. [🎙️ SINRAS PRO OS & Voice Architecture](#️-sinras-pro-os--voice-architecture)
3. [🤖 Complete 15 Autonomous Agents Matrix](#-complete-15-autonomous-agents-matrix)
4. [⚡ Multi-Provider LLM Engine Matrix](#-multi-provider-llm-engine-matrix)
5. [📚 Enterprise RAG Pipeline Architecture](#-enterprise-rag-pipeline-architecture)
6. [🗄️ Complete Data Storage Schema & Vector DB](#️-complete-data-storage-schema--vector-db)
7. [🛡️ Security Path Audit & Threat Matrix](#️-security-path-audit--threat-matrix)
8. [🖥️ All Application Screens & Navigation](#️-all-application-screens--navigation)
9. [🚀 A to Z Setup & Installation Guide](#-a-to-z-setup--installation-guide)
10. [📊 API Reference & Endpoint Specification](#-api-reference--endpoint-specification)
11. [🛠️ Troubleshooting & FAQ](#️-troubleshooting--faq)
12. [📜 License & Credits](#-license--credits)

---

## 🌟 Executive Overview

**SINRAS AI** is an all-in-one AI ecosystem combining two core systems:
1. **SINRAS PRO OS**: A real-time mobile device assistant with a futuristic Arc Reactor voice HUD, local intent execution (Settings, Camera, Dialer, SMS, Alarm, App Launcher), auto-test diagnostic suites, and instant exit controls.
2. **Multi-Agent RAG Platform**: A 15-agent autonomous reasoning engine connected to a multi-cloud LLM provider layer (Groq, DeepSeek, Gemini) and a vector-grounded document search backend.

---

## 🎙️ SINRAS PRO OS & Voice Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SINRAS PRO OS ENGINE                            │
├──────────────────────────────────┬─────────────────────────────────────┤
│  Arc Reactor Voice Visualizer    │ Sci-Fi Animated Holographic HUD     │
│  Mobile Device Intent Handler    │ Settings, Camera, Maps, Dialer, SMS │
│  Universal App Launcher          │ Launch any installed package        │
│  Auto-Test Diagnostic Suite      │ Automated CPU, RAM & Threat Audit   │
│  Clean Exit System Handler       │ Safe app termination (SystemPop)    │
└──────────────────────────────────┴─────────────────────────────────────┘
```

### Mobile OS Tool Execution Specification
SINRAS PRO parses tool commands in real-time from AI responses:
- `[[TOOL: {"action": "open_settings"}]]` ➔ Launches Mobile Settings
- `[[TOOL: {"action": "open_camera"}]]` ➔ Launches Camera
- `[[TOOL: {"action": "open_app", "app_name": "Chrome"}]]` ➔ Launches custom app
- `[[TOOL: {"action": "open_maps", "query": "coffee"}]]` ➔ Opens Google Maps search
- `[[TOOL: {"action": "open_dialer", "phone": "123456"}]]` ➔ Opens Phone Dialer
- `[[TOOL: {"action": "send_sms", "phone": "123", "body": "hi"}]]` ➔ Opens SMS composer
- `[[TOOL: {"action": "run_auto_test"}]]` ➔ Executes automated diagnostics
- `[[TOOL: {"action": "exit_app"}]]` ➔ Terminates application safely

---

## 🤖 Complete 15 Autonomous Agents Matrix

| # | Agent Name | Category | Primary Function | Special Capabilities |
| :-: | :--- | :---: | :--- | :--- |
| **1** | **SINRAS PRO OS Controller** | `System` | Mobile OS Voice & Intent Assistant | Arc Reactor HUD, App Launcher, Device Diagnostics, System Action Tags |
| **2** | **General Assistant** | `General` | All-purpose reasoning & structured Q&A | Step-by-step logic, Markdown formatting, analytical answers |
| **3** | **Code Debugger** | `Code` | Bug identification & runtime error fix | Root-cause analysis, inline fix annotations, defensive coding suggestions |
| **4** | **Code Reviewer** | `Code` | Architecture & security code auditing | Correctness, performance O(n²), SRP violations, vulnerability scanning |
| **5** | **Code Generator** | `Code` | Production-ready code generation | Idiomatic Dart/Kotlin/Python, error handling, style guide compliance |
| **6** | **Proofreader & Editor** | `Writing` | Text editing, grammar, & tone adjustment | Flow correction, top-5 improvement highlights, voice preservation |
| **7** | **Content Writer** | `Writing` | Creative marketing & blog content | CTA integration, active voice optimization, reader engagement |
| **8** | **Email Composer** | `Writing` | Professional business email drafting | Subject line generator, structured body, formal/conversational variations |
| **9** | **Data Analyst** | `Analysis` | Data interpretation & trend discovery | Summary statistics, anomaly detection, business action points |
| **10** | **Research Agent** | `Analysis` | Deep topic synthesis & citations | Multi-angle analysis, concept breakdown, open question flags |
| **11** | **Task Planner** | `Productivity` | Strategic goal breakdown | Phase milestones, task time estimates, dependency tracking, risk analysis |
| **12** | **Meeting Summarizer** | `Productivity` | Transcript & meeting note extraction | Executive summary, action items with owners, decision logs |
| **13** | **Story Writer** | `Creative` | World-building & narrative fiction | Sensory descriptions, character arcs, plot resolution, natural dialogue |
| **14** | **Idea Generator** | `Creative` | Brainstorming & concept creation | 10 distinct angles, bold/unconventional concepts, feasibility analysis |
| **15** | **AI Tutor** | `Learning` | Educational instruction & concept teaching | Analogies, step-by-step build-up, ASCII diagrams, self-check quizzes |

---

## ⚡ Multi-Provider LLM Engine Matrix

| Provider | Model Name | Latency | Output Speed | Best Used For | Free Tier Limit |
| :--- | :--- | :-: | :-: | :--- | :--- |
| **Groq (JARVIS/FRIDAY)** | `llama-3.3-70b-versatile` | **< 0.5s** | **300–500 tok/s** | Real-time voice commands, ultra-fast coding | 30 RPM / 14,400 RPD |
| **Google Gemini** | `gemini-2.0-flash` | **< 1.0s** | **150–200 tok/s** | Multimodal vision/images, long-context tasks | 15 RPM / 1M TPM |
| **DeepSeek** | `deepseek-chat` | **< 1.5s** | **80–120 tok/s** | Deep mathematical reasoning, code analysis | Free initial credits |

---

## 📚 Enterprise RAG Pipeline Architecture

```
[ User Upload PDF / DOCX ] ➔ [ FastHTML / PyPDF Chunking ] 
                                      │
                                      ▼
[ Gemini Text-Embedding-004 ] ➔ [ 768-dim Vector Float Array ] 
                                      │
                                      ▼
[ PostgreSQL pgvector HNSW ] ➔ [ Cosine Distance Search (<=>) ] 
                                      │
                                      ▼
[ Context-Augmented Prompt ] ➔ [ Grounded LLM Response + Sources ]
```

---

## 🗄️ Complete Data Storage Schema & Vector DB

### 1. `users` Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) UNIQUE NOT NULL,
    password_hash VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

### 2. `documents` Table
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    filename VARCHAR(512) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    total_pages INT DEFAULT 0,
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

### 3. `chunks` Table (Vector Store)
```sql
CREATE TABLE chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    page_number INT DEFAULT 0,
    chunk_text TEXT NOT NULL,
    embedding VECTOR(768) NOT NULL
);

-- HNSW Vector Index for Sub-second Cosine Similarity Search
CREATE INDEX ix_chunks_embedding_cosine 
ON chunks USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);
```

---

## 🛡️ Security Path Audit & Threat Matrix

| Security Threat | Mitigation Strategy | Implemented Component | Status |
| :--- | :--- | :--- | :-: |
| **API Key Leakage** | Enforced OS hardware KeyStore (Android) & Keychain (iOS) encryption | `MultiAgentStorage` / `FlutterSecureStorage` | 🔒 SECURE |
| **Unauthorized API Access** | OAuth2 JWT Bearer Token validation on all protected endpoints | `ApiClient` & FastAPI `OAuth2PasswordBearer` | 🔒 SECURE |
| **Cross-Tenant Data Leak** | Strict SQL & Vector query scoping by `user_id` | `backend/app/rag/service.py` | 🔒 SECURE |
| **Intent Redirection Attack** | Validated URI parsing and explicit intent launching | `JarvisController` | 🔒 SECURE |
| **Data Loss on Reboot** | Multi-tier persistence (KeyStore + SharedPreferences + Memory Cache) | `MultiAgentStorage` | 🔒 SECURE |

---

## 🖥️ All Application Screens & Navigation

| Screen Name | File Path | Key Features | Icon Used |
| :--- | :--- | :--- | :--- |
| **SINRAS PRO OS** | `lib/jarvis/jarvis_screen.dart` | Arc Reactor Voice HUD, System Diagnostics, Exit App, Auto-Test | `Icons.graphic_eq_rounded` |
| **Multi-Agent** | `lib/multi_agent/multi_agent_screen.dart` | Provider Switcher (Groq/Gemini/DeepSeek), 14 Agent Chips, Key Manager | `Icons.psychology_rounded` |
| **Classic Agent** | `lib/agent_screen.dart` | Single Gemini Agent, Camera & Gallery Image Attachment | `Icons.smart_toy_rounded` |
| **RAG Chat** | `lib/screens/rag_chat_screen.dart` | Grounded Document Q&A, Source Citations, Relevance Scores | `Icons.question_answer_rounded` |
| **Documents** | `lib/screens/documents_screen.dart` | File Picker Upload (PDF/TXT), Ingestion Status, Delete Document | `Icons.folder_rounded` |
| **Login** | `lib/screens/login_screen.dart` | JWT Sign In / Account Registration Form | `Icons.lock_outlined` |
| **Home Shell** | `lib/screens/home_screen.dart` | 5-Tab Material 3 Bottom Navigation Shell | `Icons.home_rounded` |

---

## 🚀 A to Z Setup & Installation Guide

### Prerequisites
- **Flutter SDK**: `3.13.7` or higher
- **Python**: `3.10` or higher
- **PostgreSQL**: `15+` with `pgvector` extension

### Step 1: Clone Repository
```bash
git clone https://github.com/your-username/synrasAI.git
cd synrasAI
```

### Step 2: Configure & Run Flutter Mobile App
```bash
# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Step 3: Configure & Run FastAPI Backend
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/macOS:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install requirements
pip install -r requirements.txt

# Start backend server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📊 API Reference & Endpoint Specification

| Method | Endpoint | Description | Auth Required |
| :-: | :--- | :--- | :-: |
| `POST` | `/auth/register` | Register new user account | ❌ No |
| `POST` | `/auth/login` | Authenticate & return JWT access token | ❌ No |
| `POST` | `/documents/upload` | Upload PDF/TXT document for ingestion | ✅ Yes |
| `GET` | `/documents/` | List all user-uploaded documents | ✅ Yes |
| `DELETE` | `/documents/{id}` | Delete document and associated vector chunks | ✅ Yes |
| `POST` | `/chat/query` | Execute grounded RAG query with source citations | ✅ Yes |
| `GET` | `/health` | Health check endpoint | ❌ No |

---

## 🛠️ Troubleshooting & FAQ

### Q1: Why are my API keys not saving?
**A**: Ensure you grant local storage permissions if prompted. Keys are saved to OS secure hardware storage (`FlutterSecureStorage`) with `SharedPreferences` fallback.

### Q2: How do I switch to the fastest sub-second agent mode?
**A**: Tap the top-right settings icon in the **SINRAS PRO OS** tab and select **Groq Core** (`llama-3.3-70b-versatile`).

### Q3: Can I run this without a backend?
**A**: Yes! **SINRAS PRO OS** and the **Multi-Agent Engine** run directly from the mobile app by supplying your API keys. The backend is only required for the Document RAG Chat tab.

---

## 📜 License & Credits
Licensed under the **MIT License**. Created with ❤️ for advanced AI assistant workflows.
