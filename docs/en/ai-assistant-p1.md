# AI Assistant P1 Core Chat Experience

P1 turns the assistant from a basic message sender into a more complete learning-product chat experience.

## Delivered

The first P1 batch now includes:

- Message actions: copy, failed-message retry, regenerate, and continue generation.
- Dynamic models: load model choices from `GET /api/assistant/models`; if that endpoint fails, the app falls back to local default models without blocking chat.
- Automatic titles: a new conversation gets a local short title from the first user prompt; backend placeholder titles such as "新对话" do not overwrite that local title.
- Conversation search: filter by title, summary, and currently loaded message content.
- Conversation management: keep the existing pin, archive, restore, move-to-folder, rename, delete, and share flows.
- Attachment experience: attachment cards show image previews or file icons, file size, and waiting/uploading state; failed uploads still use the existing retry path.

## Acceptance Checks

1. Open the AI assistant and confirm the model picker uses the available model list.
2. If the backend model-list endpoint is unavailable, sending still works with default models.
3. Create a new conversation and send "请帮我制定 30 天英语学习计划"; the conversation title should become a short local title from that message.
4. Tap "continue generation" on an assistant response and confirm it sends in the current conversation.
5. Search conversations by title, summary, or message content and confirm the list narrows correctly.
6. Add an image or PDF attachment and confirm the input area shows preview, size, and upload state.
7. `xcodebuild` tests pass.

## Still Later

These are not part of the first P1 batch:

- Real backend run cancellation.
- Server-side search and pagination.
- Persistent attachment history and cross-device recovery.
- Backend-generated titles or summaries.
- Full product display for model capability tags.
- Message selection, quoting, and scoped follow-up.
