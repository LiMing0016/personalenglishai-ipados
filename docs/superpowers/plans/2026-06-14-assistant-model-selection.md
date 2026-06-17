# Assistant Model Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users choose a configured AI model for each iPad AI assistant message.

**Architecture:** The selected model is represented in the iPad assistant feature, encoded into assistant run requests, passed through Spring Boot unchanged, and applied by the Python orchestrator for the current run. Missing values fall back to existing defaults.

**Tech Stack:** SwiftUI, XCTest, Java Spring Boot DTOs, Python FastAPI/Pydantic, Docker Compose.

---

### Task 1: iPad Request And UI

**Files:**
- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantRequest.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantStore.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Services/AssistantService.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ChatView.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/LiveAssistantServiceTests.swift`

- [ ] Add `AssistantModelSelection` with OpenAI, Kimi, and Qwen options.
- [ ] Add `aiProvider` and `model` to `AssistantRequest`.
- [ ] Pass the selected model through service calls.
- [ ] Add a compact model picker to `ChatView`.
- [ ] Update service tests to assert the outgoing JSON contains provider/model.

### Task 2: Spring Boot Pass-Through

**Files:**
- Modify: `backend/src/main/java/com/personalenglishai/backend/controller/dto/assistant/AssistantRequest.java`

- [ ] Add optional `aiProvider` and `model` fields with size limits.
- [ ] Ensure existing requests remain valid when fields are absent.

### Task 3: Python Orchestrator Model Override

**Files:**
- Modify: `python/ai_orchestrator/schemas/assistant_request.py`
- Modify: `python/ai_orchestrator/assistant_service.py`

- [ ] Add optional `aiProvider` and `model` to the Pydantic request.
- [ ] Resolve the per-request model from `request.model` or fallback `self.model`.
- [ ] Keep health output unchanged except it still reports the default model.

### Task 4: Verification

**Files:**
- Test project and backend/orchestrator commands.

- [ ] Run iPad assistant service tests.
- [ ] Run iPad full tests if build time is acceptable.
- [ ] Restart backend containers.
- [ ] Verify `/health` remains `configured:true`.
