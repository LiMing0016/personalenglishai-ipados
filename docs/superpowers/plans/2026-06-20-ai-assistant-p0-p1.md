# AI Assistant P0/P1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the first iPad-side AI assistant gaps that do not depend on new backend endpoints.

**Architecture:** Keep the existing SwiftUI feature structure. Extend `AssistantStore` as the state boundary, extend `AssistantService` only for backend endpoints that already exist, and keep view-only interactions in `ChatView`, `ConversationListView`, and `MessageBubbleView`.

**Tech Stack:** SwiftUI, async/await, XCTest, existing `APIClient`, existing assistant backend contract.

---

## Scope

This batch implements the iPad-side P0/P1 foundation:

- Conversation rename via existing `PATCH /api/assistant/conversations/{id}`.
- Failed-send retry for the last failed user prompt.
- Better stop-generation status without pretending backend cancel exists.
- Attachment preflight validation for count, size, and MIME/extension.
- Message action entry points for copy and retry/regenerate-ready UI.

Out of scope for this batch:

- Dynamic `/api/assistant/models`.
- Real backend run cancel.
- Backend regenerate endpoint.
- Attachment metadata/preview endpoint.
- Structured message `parts`.

## Files

- Modify: `PersonalEnglishAI/Features/Assistant/Services/AssistantService.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantStore.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantConversation.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Models/AssistantMessage.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ChatView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/ConversationListView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/MessageBubbleView.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/LiveAssistantServiceTests.swift`
- Test: new `PersonalEnglishAITests/Features/Assistant/AssistantStoreTests.swift`

## Tasks

### Task 1: Conversation Rename Service

- [ ] Add a failing service test proving `LiveAssistantService.renameConversation` sends `PATCH /assistant/conversations/{id}` with `title` and `summary`.
- [ ] Implement `renameConversation` in `AssistantService`, `MockAssistantService`, and `LiveAssistantService`.
- [ ] Run the assistant service tests.

### Task 2: Store State For Retry And Rename

- [ ] Add failing store tests for retry state, successful retry clearing state, attachment validation, and conversation rename.
- [ ] Add `lastFailedMessage` state and `retryLastFailedMessage()`.
- [ ] Add `renameConversation(id:title:)`.
- [ ] Add attachment validation before accepting drafts.

### Task 3: Chat And Conversation UI

- [ ] Add rename entry in conversation context menu.
- [ ] Add failed assistant message action to retry.
- [ ] Show stopped generation as a non-error cancelled state.
- [ ] Keep attachment cards visible and clear validation errors cleanly.

### Task 4: Verification

- [ ] Run `xcodebuild` tests for `PersonalEnglishAITests`.
- [ ] Run a build for the iPad simulator target.
- [ ] Summarize remaining backend-dependent P1 gaps.

## Self-Review

- No backend target-contract endpoints are called in this batch.
- No existing user edits are reverted.
- P0/P1 work is limited to user-visible stability and interaction closures.
