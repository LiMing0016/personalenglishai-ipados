# AI Assistant P1 Core Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the AI assistant feel like a usable product by closing the first P1 chat experience gaps: dynamic models, continue generation, automatic titles, search, and attachment feedback.

**Architecture:** Keep `AssistantStore` as the feature state boundary. Add backend model-list support through `AssistantService`, while keeping fallback models available so the chat still works if `/api/assistant/models` is unavailable. Keep conversation search local for this batch because the current list endpoint already loads enough data for iPad-side filtering.

**Tech Stack:** SwiftUI, async/await, XCTest, existing `APIClient`, `GET /api/assistant/models` target contract from the backend iOS integration docs.

---

## Scope

This P1 batch implements:

- Dynamic model list loading from `GET /api/assistant/models` with fallback to existing OpenAI/Kimi/Qwen defaults.
- Continue generation from an existing assistant response.
- Local automatic conversation title generation from the first user prompt.
- Local conversation search by title, summary, and visible message content.
- Attachment cards with preview, formatted size, upload state, and existing failed-send retry path.

Already implemented before this batch:

- Message copy.
- Failed message retry.
- Regenerate from the nearest previous user message.
- Conversation pin, archive, restore, move, delete, rename, share.
- Attachment count, size, MIME, and extension validation.

Out of scope for this batch:

- Real backend run cancellation endpoint.
- Server-side search.
- Persistent attachment history across app restarts.
- Backend-generated title endpoint.
- Account-level model preferences.

## Files

- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantRequest.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Services/AssistantService.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantStore.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ChatView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ChatInputBar.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/MessageBubbleView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ConversationListView.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/LiveAssistantServiceTests.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/AssistantStoreTests.swift`
- Docs: `docs/ai-assistant-p0.md`
- Docs: `docs/en/ai-assistant-p0.md`

## Tasks

### Task 1: Dynamic Model List

- [ ] Add a failing service test proving `LiveAssistantService.listModels()` calls `GET /api/assistant/models` and decodes `id`, `label`, `provider`, `default`, `supportsStreaming`, `supportsAttachments`, `supportsVision`, `maxInputTokens`, and `status`.
- [ ] Add failing store tests proving backend default model selection is applied and model-load failure falls back to local defaults.
- [ ] Replace the fixed model enum with a value type that keeps static defaults (`.openAI`, `.kimi`, `.qwen`, `allCases`) and can also decode backend rows.
- [ ] Add `listModels()` to `AssistantService`, `MockAssistantService`, and `LiveAssistantService`.
- [ ] Load models in `AssistantStore.load()` without blocking projects and conversations when the model endpoint fails.
- [ ] Update `ChatView` model picker to use `store.availableModels`.

### Task 2: Continue Generation

- [ ] Add a failing store test proving `continueGeneration(conversationID:)` sends `继续生成` to the current conversation.
- [ ] Add `AssistantStore.continueGeneration(conversationID:)`.
- [ ] Add a message action button labeled `继续生成` for assistant messages.
- [ ] Wire the button in `ChatView` to the store method.

### Task 3: Automatic Conversation Titles

- [ ] Add a failing store test proving a new conversation titled `新对话` becomes a short title derived from the first user prompt.
- [ ] Add local title generation in `AssistantStore.appendOptimisticMessages`.
- [ ] Preserve the local generated title when the backend refresh still returns placeholder titles such as `新对话`.

### Task 4: Conversation Search

- [ ] Add a failing store test proving `conversationSearchQuery` filters by title, summary, and message content.
- [ ] Add `conversationSearchQuery` and local filtering to `AssistantStore.visibleConversations`.
- [ ] Add `.searchable` to `ConversationListView`.

### Task 5: Attachment Preview And Upload State

- [ ] Add a failing test for attachment formatted size and image detection.
- [ ] Add attachment display helpers on `AssistantAttachmentDraft`.
- [ ] Update `ChatInputBar` attachment cards to show image preview, file icon, size, and `上传中` while sending.
- [ ] Keep failed upload retry through `lastFailedMessage` and existing message retry UI.

### Task 6: Verification

- [ ] Run targeted assistant tests.
- [ ] Run `npm run docs:build`.
- [ ] Run full `xcodebuild test -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -derivedDataPath DerivedData`.
- [ ] Run `git diff --check`.

## Self-Review

- P1 requirements map to tasks: dynamic models (Task 1), continue generation (Task 2), auto title (Task 3), search and conversation management (Task 4), attachment preview/status/retry (Task 5), existing copy/retry/regenerate/pin/archive/folder/share remain covered by previous work.
- No plan placeholders remain.
- The model selection type still exposes `.openAI`, `.kimi`, `.qwen`, and `allCases`, so existing tests and call sites have a migration path.
