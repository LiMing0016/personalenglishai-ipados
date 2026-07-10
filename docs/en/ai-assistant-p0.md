# AI Assistant P0 Stability Loop

This document defines the P0 stability work that must be completed before the AI assistant grows into more advanced learning visuals and cross-module features. P0 is not about adding more presentation capabilities. It is about making login, navigation, message sending, stop generation, recovery, and iPad layout behavior reliable.

## Why P0 Comes First

The assistant already has the foundation for conversations, streaming output, attachments, folders, pinning, archiving, sharing, Markdown, Mermaid, and D3 graph rendering. Before expanding learning paths, ability trees, essay structure diagrams, and other visual learning artifacts, the app needs a stronger stability baseline:

- Passing captcha must reliably enter the main app.
- Backend, model, and expired-session failures need clear user-facing states.
- Sending, stopping, retrying, and regenerating must not conflict.
- Landscape, portrait, and split-screen layouts must keep text, bubbles, and input usable.
- The user should know whether a failure comes from local input, session state, network, backend, or model service.

## P0 Acceptance Goals

P0 is complete when the following flow can be verified:

1. Sign in with a verified email account.
2. Complete the slider captcha and enter the main app without staying in the captcha overlay.
3. Open the AI assistant, create a conversation, and send a normal text message.
4. Stop generation while a response is streaming, and confirm the input becomes usable again.
5. When the backend is down or the model fails, the page shows a clear error and allows retry.
6. In landscape and portrait, messages, input, and the top toolbar are not stretched, clipped, or blocked.
7. Switching conversations, archiving, pinning, and sharing do not corrupt the current chat state.
8. `xcodebuild` tests pass.

## P0 Scope

### 1. Stable Login-To-App Flow

- Captcha verification failure refreshes the captcha without being confused with login failure.
- Login failure after captcha success does not reopen the captcha overlay.
- A successful login response without a token shows a clear error.
- A 401 or failed token refresh clears the local session and returns to login.

### 2. Visible AI Backend Status

- `load`, send, stream, and upload errors should become understandable Chinese messages.
- Distinguish backend unreachable, model failure, expired login, attachment failure, and generic request failure.
- The assistant screen should expose a lightweight status hint instead of only showing "AI assistant is temporarily unavailable."

### 3. Consistent Sending State

- Only one generation task is allowed at a time.
- Rapid repeated send taps must not create multiple `assistant-loading` placeholder messages.
- If streaming succeeds but the later conversation refresh fails, the already generated answer should not be marked failed.
- After stopping generation, the input must become usable and the current assistant response should be marked cancelled.
- Failed messages keep a retry affordance, and retry success clears the failure state.

### 4. iPad Local Interaction

- The whole input area is tappable and supports multiline input.
- User bubbles keep a reasonable maximum width in portrait and landscape.
- Code, long English, and long Chinese text do not break the chat layout.
- The input bar respects safe areas and keyboard behavior.

### 5. P0 Test Coverage

- Login captcha state-machine tests.
- Duplicate send while sending test.
- Stop-generation state test.
- Streaming success with conversation-refresh failure test.
- Backend error-message mapping test.
- Attachment validation tests.

## Out Of Scope For P0

These are important, but not part of the first P0 batch:

- A real backend run-cancel endpoint.
- Dynamic model-list endpoint.
- Product-level visual upgrades for graph rendering.
- Full template library for learning paths, ability trees, grammar trees, timelines, and essay structures.
- Cross-module persistence into writing, vocabulary, and learning review.

## First P0 Execution Order

The first batch starts from the state-consistency issues that repeatedly affect validation:

1. Docs: record P0 scope, acceptance checks, and non-goals.
2. Tests: add sending-state and streaming-boundary coverage first.
3. Store: tighten `AssistantStore` concurrent sending, stop, and failure states.
4. UI: improve input hit target, landscape bubble width, and error hints.
5. Verification: run `xcodebuild` tests and manually check once in Simulator.

The existing execution plan is `docs/superpowers/plans/2026-06-20-ai-assistant-p0-p1.md`. It covers the first P0/P1 batch that does not require new backend endpoints. Future work such as dynamic model lists or true run cancellation must stay synced with the backend integration documents.

## 2026-06-22 First Batch Delivered

This batch completes the P0 loop that does not require new backend endpoints:

- `AssistantStore` now exposes recoverable status notices for backend unreachable, model failure, expired session, sync warning, and generic request failure.
- When streaming succeeds but conversation refresh fails, the generated answer remains visible and the UI shows a sync-warning notice.
- Model failures keep a retry draft so the user can retry from the status notice or the message actions.
- Stop generation cancels the current stream, marks the placeholder assistant message as stopped, and restores the input state.
- The chat screen now has a lightweight top status banner instead of relying only on global alerts.
- The input hit target is wider, and landscape user bubbles have a stricter maximum width so text and code do not stretch across the whole screen.
- `AssistantStoreTests` now cover backend unreachable, model failure, stop generation, refresh-failure answer preservation, duplicate sends, and landscape bubble width.
