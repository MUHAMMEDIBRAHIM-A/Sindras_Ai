# 🏆 SINRAS AI — SINRAS PRO OS & Multi-Agent RAG Platform (A to Z Guide)

> **The Ultimate Next-Generation Cross-Platform Autonomous AI Mobile Operating System & Grounded Enterprise RAG System.**  
> Powered by **Flutter 3**, **FastAPI**, **PostgreSQL + pgvector**, and **Multi-Provider LLM Core (Groq, DeepSeek, Google Gemini)**.

---

## 📑 Table of Contents
1. [🌟 Executive Overview](#-executive-overview)
2. [🎙️ SINRAS PRO OS & Voice Architecture](#️-sinras-pro-os--voice-architecture)
3. [🤖 Complete 17 Autonomous Agents Matrix](#-complete-17-autonomous-agents-matrix)
4. [⚡ Multi-Provider LLM Engine Matrix](#-multi-provider-llm-engine-matrix)
5. [📚 Enterprise RAG Pipeline Architecture](#-enterprise-rag-pipeline-architecture)
6. [🗄️ Complete Data Storage Schema & Vector DB](#️-complete-data-storage-schema--vector-db)
7. [🛡️ Security Path Audit & Threat Matrix](#️-security-path-audit--threat-matrix)
8. [🖥️ All Application Screens & Navigation](#️-all-application-screens--navigation)
9. [🚀 A to Z Setup & Installation Guide](#-a-to-z-setup--installation-guide)
10. [📊 API Reference & Endpoint Specification](#-api-reference--endpoint-specification)
11. [🛠️ Standalone Python GitHub PR Reviewer Agent](#️-standalone-python-github-pr-reviewer-agent)
12. [📜 License & Credits](#-license--credits)

---

## 🌟 Executive Overview

**SINRAS AI** is an all-in-one AI ecosystem combining two core systems:
1. **SINRAS PRO OS**: A real-time mobile device assistant with a futuristic Arc Reactor voice HUD, local intent execution (Settings, Camera, Dialer, SMS, Alarm, App Launcher), auto-test diagnostic suites, and instant exit controls.
2. **Multi-Agent RAG Platform**: A 17-agent autonomous reasoning engine connected to a multi-cloud LLM provider layer (Groq, DeepSeek, Gemini) and a vector-grounded document search backend.

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

---

## 🤖 Complete 17 Autonomous Agents Matrix

| # | Agent Name | Category | Primary Function | Special Capabilities |
| :-: | :--- | :---: | :--- | :--- |
| **1** | **SINRAS PRO OS Controller** | `System` | Mobile OS Voice & Intent Assistant | Arc Reactor HUD, App Launcher, Device Diagnostics, System Action Tags |
| **2** | **General Assistant** | `General` | All-purpose reasoning & structured Q&A | Step-by-step logic, Markdown formatting, analytical answers |
| **3** | **Code Debugger** | `Code` | Bug identification & runtime error fix | Root-cause analysis, inline fix annotations, defensive coding suggestions |
| **4** | **Code Reviewer** | `Code` | Architecture & security code auditing | Correctness, performance O(n²), SRP violations, vulnerability scanning |
| **5** | **Code Generator** | `Code` | Production-ready code generation | Idiomatic Dart/Kotlin/Python, error handling, style guide compliance |
| **6** | **GitHub PR & Bug Triage** | `Code` | Pull request inspection & automated review comments | GitHub REST API, diff auditing, mandatory coding standards checklist |
| **7** | **Proofreader & Editor** | `Writing` | Text editing, grammar, & tone adjustment | Flow correction, top-5 improvement highlights, voice preservation |
| **8** | **Content Writer** | `Writing` | Creative marketing & blog content | CTA integration, active voice optimization, reader engagement |
| **9** | **Email Composer** | `Writing` | Professional business email drafting | Subject line generator, structured body, formal/conversational variations |
| **10** | **Data Analyst** | `Analysis` | Data interpretation & trend discovery | Summary statistics, anomaly detection, business action points |
| **11** | **Natural Language SQL Analyst** | `Analysis` | English to safe SQL translation & charts | Read-only SQL (`SELECT`), join explanations, visualization recommendations |
| **12** | **Research Agent** | `Analysis` | Deep topic synthesis & citations | Multi-angle analysis, concept breakdown, open question flags |
| **13** | **Autonomous Market Scout** | `Analysis` | Competitor profiles & industry trend digests | High-signal market intelligence, competitor shifts, risk detection |
| **14** | **Task Planner** | `Productivity` | Strategic goal breakdown | Phase milestones, task time estimates, dependency tracking, risk analysis |
| **15** | **Meeting Summarizer** | `Productivity` | Transcript & meeting note extraction | Executive summary, action items with owners, decision logs |
| **16** | **Story Writer** | `Creative` | World-building & narrative fiction | Sensory descriptions, character arcs, plot resolution, natural dialogue |
| **17** | **AI Tutor** | `Learning` | Educational instruction & concept teaching | Analogies, step-by-step build-up, ASCII diagrams, self-check quizzes |

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
| **Multi-Agent** | `lib/multi_agent/multi_agent_screen.dart` | Provider Switcher (Groq/Gemini/DeepSeek), 17 Agent Chips, Key Manager | `Icons.psychology_rounded` |
| **Classic Agent** | `lib/agent_screen.dart` | Single Gemini Agent, Camera & Gallery Image Attachment | `Icons.smart_toy_rounded` |
| **RAG Chat** | `lib/screens/rag_chat_screen.dart` | Grounded Document Q&A, Source Citations, Relevance Scores | `Icons.question_answer_rounded` |
| **Documents** | `lib/screens/documents_screen.dart` | File Picker Upload (PDF/TXT), Ingestion Status, Delete Document | `Icons.folder_rounded` |
| **Login** | `lib/screens/login_screen.dart` | JWT Sign In / Account Registration Form | `Icons.lock_outlined` |
| **Home Shell** | `lib/screens/home_screen.dart` | 5-Tab Material 3 Bottom Navigation Shell | `Icons.home_rounded` |

---

## 🛠️ Standalone Python GitHub PR Reviewer Agent

Located in `backend/agents/github_pr_reviewer/`:

```bash
cd backend/agents/github_pr_reviewer
pip install -r requirements.txt

# Run Autonomous GitHub PR Agent
python agent.py
```

### Features:
- Fetches PR metadata and unified code diffs using GitHub REST API.
- Audits changed lines against team coding standards (`rules/coding_standards.md`).
- Automatically posts review comments (`APPROVE`, `REQUEST_CHANGES`, `COMMENT`) directly to GitHub.

---

## 📜 License & Credits
Licensed under the **MIT License**. Created with ❤️ for advanced AI assistant workflows.
