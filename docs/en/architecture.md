# Architecture

The iPadOS client uses SwiftUI with feature-oriented folders and shared service infrastructure.

## Repository Role

This repository owns only the iPadOS client. The Web, backend, database, and AI orchestration services remain in `LiMing0016/personalenglishai`.

## App Structure

```text
PersonalEnglishAI/
  App/
  Core/
  DesignSystem/
  Features/
  Resources/
```

## Core Principles

- SwiftUI views express UI and local interaction state.
- Shared dependencies live in `Core/` and are injected through app environment values.
- Network code stays in services and `APIClient`.
- Feature code is grouped by product area.
- Mock data and previews are used before connecting real backend flows.

## Current Foundation

- `AppRootView` owns the three-column iPad layout.
- `APIClient` is the base URLSession wrapper.
- `AuthSession` and `TokenStore` prepare the login/session boundary.
- `KeychainTokenStore` stores access tokens through the Security framework.
- `ServerSentEventsParser` prepares for assistant streaming.

## Notes

Swift macro-based `#Preview` and `@Observable` were avoided in the initial skeleton because the local command-line build environment produced Swift plugin server errors. The project currently uses traditional `PreviewProvider` and `ObservableObject`, which remain mainstream and stable.
