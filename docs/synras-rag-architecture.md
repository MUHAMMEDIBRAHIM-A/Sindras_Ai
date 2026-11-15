# Synras AI — RAG System Architecture & Implementation Plan

## 1. Existing Project Audit

### What exists today

| Layer | File | Purpose | Status |
|:------|:-----|:--------|:-------|
| Flutter entry | `lib/main.dart` | App bootstrap, MaterialApp, routes to AgentScreen | Keep as-is |
| Chat UI | `lib/agent_screen.dart` (315 lines) | Single-turn prompt to Gemini response, image attach, role selector | Keep — will add a new RAG screen alongside it |
| Agent engine | `lib/agent_service.dart` (41 lines) | Direct google_generative_ai SDK call with system instruction | Keep — existing roles keep working |
| Role enum | `lib/agent_role.dart` (66 lines) | 4 personas: General, Proofreader, Code Auditor, Vision | Keep |
| Android native | `app/` module with Compose + Firebase AI | Separate native Compose Android app in same project root | Untouched |
| Firebase config | `app/google-services.json` | Firebase project astra-32e88 | Untouched |
| Dependencies | `pubspec.yaml` | google_generative_ai, image_picker | Will add http, file_picker, flutter_secure_storage, shared_preferences |

### Key observations
- The app currently embeds the Gemini API key in client code. The RAG backend will hold all API keys server-side.
- No authentication exists. We will add JWT-based auth.
- No document management exists. We will create new screens and services.
- The `app/` module is a separate native Android app (Kotlin + Compose). It will not be modified.
