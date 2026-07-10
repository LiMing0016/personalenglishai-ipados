# AI Assistant MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first usable iPadOS AI assistant module with live conversations, streaming replies, attachments, folders, archive/pin/delete, and share support.

**Architecture:** Keep backend access in `AssistantService`, UI state in a main-actor `AssistantStore`, and SwiftUI views focused on layout and user actions. The first streaming implementation consumes server-sent events from the backend and refreshes the conversation detail after completion.

**Tech Stack:** SwiftUI, async/await, URLSession, XCTest, existing Spring Boot `/api/assistant/**` backend.

---

### Task 1: Assistant API Contract

**Files:**
- Modify: `PersonalEnglishAI/Features/Assistant/Services/AssistantService.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Models/*.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/LiveAssistantServiceTests.swift`

- [ ] Write failing tests for list/create/get/send/stream/projects/share/archive/pin/move/delete.
- [ ] Implement `LiveAssistantService` with JSON, multipart, and SSE requests.
- [ ] Run Assistant service tests and confirm they pass.

### Task 2: Assistant State Layer

**Files:**
- Create: `PersonalEnglishAI/Features/Assistant/Models/AssistantStore.swift`
- Modify: `PersonalEnglishAI/App/AppEnvironment.swift`
- Modify: `PersonalEnglishAI/App/AppRootView.swift`

- [ ] Add `AssistantStore` as the single source of truth for conversations, projects, selected filters, attachments, streaming status, errors, and share URLs.
- [ ] Wire `LiveAssistantService` into `AppEnvironment`.
- [ ] Own the store at `AppShellView` level so list and chat detail share state.

### Task 3: iPad Assistant UI

**Files:**
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ConversationListView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/AssistantRootView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ChatView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ChatInputBar.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/MessageBubbleView.swift`
- Create: small focused sheet/helper views under `PersonalEnglishAI/Features/Assistant/Views/`

- [ ] Replace static sample data with store-driven live state.
- [ ] Add project filter and folder management sheets.
- [ ] Add row actions for pin/archive/delete/move.
- [ ] Add streaming message UI, stop button, retry affordance, and attachment chips.
- [ ] Add share sheet for generated share links.

### Task 4: Verification

**Files:**
- Existing project and tests.

- [ ] Run targeted Assistant tests.
- [ ] Run full iPadOS test suite with `xcodebuild`.
- [ ] If the backend is running, launch the app in Simulator and manually verify login -> AI assistant -> send message.
