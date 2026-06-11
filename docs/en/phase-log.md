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
