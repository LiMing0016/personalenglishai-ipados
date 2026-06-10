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

Verified:

```bash
xcodebuild -quiet -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

Not Yet Verified:

- `npm install` has not completed because the current environment cannot reach `registry.npmjs.org`.
- The VitePress site has not yet been verified with `docs:build`.

Open Questions:

- How should mobile refresh token handling work: cookie-based or JSON token-based?
- Which backend URL should be used for local iPad simulator testing?

Next:

- Start Phase 1 auth/session integration.
