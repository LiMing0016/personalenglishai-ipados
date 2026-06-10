# API Integration

The iPadOS app should talk directly to the existing Spring Boot API, not to the Vue web frontend.

## Base URL

Development default:

```text
http://127.0.0.1:18080/api
```

The production base URL should be configured later through `AppConfiguration`.

## Auth Boundary

The Web client currently uses:

- access token in `Authorization: Bearer <token>`
- refresh token through httpOnly cookie

The iPadOS client needs a confirmed mobile strategy:

- Option A: support cookie-based refresh with `URLSession` cookie storage
- Option B: add/confirm a JSON refresh-token flow suitable for native apps

Do not continue deep Phase 1 implementation until this is decided.

## First Endpoints

```text
POST /api/v1/auth/login
POST /api/v1/auth/refresh
GET  /api/users/me/profile

GET  /api/assistant/conversations
POST /api/assistant/conversations
GET  /api/assistant/conversations/{id}
POST /api/assistant/conversations/{id}/messages/run
POST /api/assistant/conversations/{id}/messages/run/stream
```

## Security Rules

- Do not put OpenAI API keys in the iPad app.
- Store access tokens in Keychain.
- Avoid logging tokens or secrets.
- Route all AI calls through existing backend/orchestrator services.
