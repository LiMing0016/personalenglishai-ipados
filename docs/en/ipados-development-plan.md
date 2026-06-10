# iPadOS Development Plan

This English page is a concise companion to the Chinese detailed plan at `/ipados-development-plan`.

## Summary

The existing `LiMing0016/personalenglishai` repository already contains the Web client, Spring Boot backend, database integration, and Python AI orchestrator. The iPadOS repository should implement only the native SwiftUI client and reuse the existing backend APIs.

## Recommended Direction

- Build a native SwiftUI iPadOS app.
- Reuse the existing Spring Boot API.
- Keep OpenAI API keys on the backend/orchestrator side.
- Use Keychain for access-token storage.
- Start with the smallest useful loop: login, profile fetch, assistant conversation list, and assistant messaging.

## Structure

```text
PersonalEnglishAI/
  App/
  Core/
  DesignSystem/
  Features/
  Resources/
```

## Current Status

Phase 0 is complete:

- Xcode project created.
- Three-column SwiftUI shell added.
- Mock Home, Assistant, Writing, and Profile surfaces added.
- Basic networking, auth session, Keychain token store, and SSE parser placeholders added.

## Next Step

Start Phase 1:

1. Confirm mobile refresh-token strategy.
2. Implement real `AuthService`.
3. Store access token in Keychain.
4. Restore session on launch.
5. Fetch `/api/users/me/profile`.
