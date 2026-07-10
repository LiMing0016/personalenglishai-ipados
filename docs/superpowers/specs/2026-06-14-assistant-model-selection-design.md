# Assistant Model Selection Design

## Goal

Allow iPad users to choose which configured AI provider/model powers each AI assistant message.

## Scope

The first version supports the configured local providers: OpenAI, Kimi, and Qwen. The iPad app sends both `aiProvider` and `model` on assistant run requests. Spring Boot accepts and forwards these fields to the Python orchestrator. Python uses the requested model for that run, falling back to `AI_ASSISTANT_MODEL` when no model is provided.

## UX

The chat toolbar shows two compact pickers:

- Mode: daily learning or exam boost.
- Model: OpenAI, Kimi, or Qwen options backed by local `.env` configuration.

The model picker is per-session app state for now. It does not persist to the server or device storage in this iteration.

## Data Contract

Assistant run JSON adds optional top-level fields:

```json
{
  "aiProvider": "openai",
  "model": "gpt-4o"
}
```

Existing clients remain compatible because both fields are optional.

## Verification

- iPad unit tests verify `aiProvider` and `model` are encoded.
- Backend DTO tests verify the fields deserialize and are forwarded.
- Python tests verify request-specific model selection overrides the default model.
- Manual verification uses `/health` and an iPad assistant message.
