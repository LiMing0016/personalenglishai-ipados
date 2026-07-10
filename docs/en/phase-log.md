# Phase Log

This file records what has actually happened. The roadmap describes intent; this log describes completed work, open questions, and next steps.

## 2026-06-10

Completed:

- Created `AGENTS.md` as long-term project guidance.
- Created `docs/ipados-development-plan.md`.
- Created the Xcode project `PersonalEnglishAI.xcodeproj`.
- Added SwiftUI app entry and iPad three-column shell.
- Added mock Home, Assistant, Writing, and Profile surfaces.
- Added basic `APIClient`, `APIEndpoint`, `APIError`, and `APIEnvelope`.
- Added `AuthSession`, `TokenStore`, `KeychainTokenStore`, and `ServerSentEventsParser`.
- Added the VitePress docs scaffold and changed it to a Chinese/English locale structure.
- Added the Phase 1 auth and session design document.

Verified:

```bash
xcodebuild -quiet -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

Not Yet Verified:

- `npm install` has not completed because the current environment cannot reach `registry.npmjs.org`.
- The VitePress site has not yet been verified with `docs:build`.

Open Questions At The Time:

- How should mobile refresh token handling work: cookie-based or JSON token-based?
- Which backend URL should be used for local iPad simulator testing?

Next At The Time:

- Finish auth strategy evaluation, then implement the real `AuthService`.

## 2026-06-12

Completed:

- Cloned the Web/backend reference repository next to this iPadOS repository as `personalenglishai-web-reference`.
- Compared the Web login flow and Spring Boot auth implementation, confirming the current Web production flow depends on slider captcha and an httpOnly refresh cookie.
- Chose option B for iPadOS: a mobile-native auth contract.
- Added the formal design spec: `docs/superpowers/specs/2026-06-12-ipados-mobile-auth-design.md`.
- Updated the auth/session design so access and refresh tokens are both stored in Keychain on iPadOS.

Open Questions:

- Whether the final backend mobile auth paths should use `/api/v1/auth/mobile/*`.
- Which backend URL should be used for local iPad simulator testing.

Next:

- Write the Phase 1 implementation plan based on the mobile auth contract.

## 2026-06-21

Completed:

- Decided that the AI Assistant should stabilize the P0 loop before adding more visualization features.
- Added `docs/ai-assistant-p0.md` and `docs/en/ai-assistant-p0.md`.
- Added the AI Assistant P0 pages to the Chinese and English VitePress navigation.

P0 Focus:

- Login should reliably enter the main app after captcha verification.
- AI backend, model, and auth errors should be visible.
- Send, stop, retry, and regenerate states should stay consistent.
- Input and message layouts should remain stable in iPad landscape, portrait, and Split View.

Next:

- Add tests for P0 send states and streaming boundaries, then tighten `AssistantStore` concurrency, stop, and failure handling.

## 2026-06-22

Completed:

- Added `docs/ai-assistant-p1.md` and `docs/en/ai-assistant-p1.md` to define the AI Assistant P1 core chat scope, acceptance checks, and follow-up boundaries.
- Added the P1 pages to the Chinese and English VitePress navigation and linked them from the roadmap.
- Changed iPad model selection to prefer the backend `/api/assistant/models` endpoint, with a local fallback model list when the endpoint is unavailable.
- Added continue generation, local automatic conversation titles, conversation search, attachment previews, and attachment size display.
- Message actions now include copy, retry, regenerate, and continue generation. Attachments keep uploading, failed retry, and size-limit states.
- Added targeted P1 tests covering dynamic models, model fallback, continue generation, automatic titles, search, and attachment draft presentation.

Current Boundaries:

- New conversation titles are generated locally on iPad first; backend title generation can be added later.
- Conversation search currently covers locally loaded conversations and messages; large history search should move to backend pagination/search.
- Attachment upload still follows the current backend upload contract; real persistence, type allowlists, and server-side scanning remain follow-up work.

Next:

- Run full build and tests, then continue the remaining P1 loop: real cancel/stop, backend-persisted attachments, and server-consistent conversation management.
