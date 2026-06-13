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

The iPadOS client has chosen a mobile-native auth contract:

- Backend exposes mobile login/refresh/logout endpoints.
- Login/refresh returns access token and refresh token in JSON.
- iPadOS stores both tokens in Keychain.
- Refresh sends the refresh token in JSON instead of relying on Web httpOnly cookies.

See [Auth And Session Design](./auth-session-design) for the detailed Phase 1 design.

## First Endpoints

```text
POST /api/v1/auth/mobile/login
POST /api/v1/auth/mobile/refresh
POST /api/v1/auth/mobile/logout
GET  /api/users/me/profile

GET  /api/assistant/conversations
POST /api/assistant/conversations
GET  /api/assistant/conversations/{id}
POST /api/assistant/conversations/{id}/messages/run
POST /api/assistant/conversations/{id}/messages/run/stream
```

## Security Rules

- Do not put OpenAI API keys in the iPad app.
- Store access and refresh tokens in Keychain.
- Avoid logging tokens or secrets.
- Route all AI calls through existing backend/orchestrator services.
