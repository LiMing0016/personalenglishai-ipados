# Auth And Session Design

This document designs Phase 1: auth and user session. The goal is to build a stable and secure login loop before connecting the learning assistant to real APIs.

## Goals

- Users can sign in with an existing Personal English AI account.
- On successful login, the access token is stored in Keychain.
- The app can restore session state on launch.
- When authenticated, the app fetches `/api/users/me/profile`.
- When tokens expire, the app clears session state and returns to the login view.
- The app never stores OpenAI API keys or server-side secrets.

## Chosen Auth Strategy

Use option B: a mobile-native auth contract for iPadOS.

The Web app can keep its current production flow: access token in JSON body, refresh token in an httpOnly cookie.

The iPadOS long-term strategy:

- Backend exposes mobile login/refresh/logout endpoints.
- Login returns both access token and refresh token.
- iPadOS stores both tokens in Keychain.
- Refresh sends the refresh token in JSON instead of relying on Web cookies.
- Detailed spec: `docs/superpowers/specs/2026-06-12-ipados-mobile-auth-design.md`.

## User Flow

```text
App launch
  -> AuthSession.restore()
    -> local token exists
      -> GET /api/users/me/profile
        -> success: enter AppRootView
        -> 401: try refresh
          -> refresh succeeds: retry profile
          -> refresh fails: clear token and show LoginView
    -> no local token
      -> show LoginView

User signs in
  -> POST /api/v1/auth/mobile/login
    -> success: save token, fetch profile, enter AppRootView
    -> failure: show error
```

## State Model

`AuthSession` should be the global source of truth for session state:

```swift
enum AuthState {
    case restoring
    case signedOut
    case signedIn(MeProfile)
    case failed(String)
}
```

The current skeleton has `AuthSession` and `TokenStore`. It can evolve from simple `accessToken/isAuthenticated` state into this full state model.

## File Boundaries

```text
Core/Auth/
  AuthSession.swift             # global session state
  TokenStore.swift              # access/refresh token storage protocol
  KeychainTokenStore.swift      # Keychain implementation

Core/Networking/
  APIClient.swift               # requests, Authorization header, error mapping
  APIError.swift
  APIEndpoint.swift
  APIEnvelope.swift

Features/Auth/
  Models/
    LoginRequest.swift
    LoginResponse.swift
    RefreshTokenRequest.swift
  Services/
    AuthService.swift           # login, refresh, logout
  Views/
    LoginView.swift             # login UI

Features/Profile/
  Services/
    UserService.swift           # getMyProfile()
```

## API Design

AuthService should provide:

```swift
protocol AuthService {
    func login(email: String, password: String) async throws -> LoginResponse
    func refresh() async throws -> LoginResponse
    func logout() async throws
}
```

UserService should provide:

```swift
protocol UserService {
    func getMyProfile() async throws -> MeProfile
}
```

## UI Design

The first version should stay simple:

- email field
- password field
- sign-in button
- loading state
- error message
- enter the workspace after successful login

Do not add registration, forgot password, captcha, or slider verification in Phase 1. Those belong to later enhancements.

## Error Handling

Cover:

- empty email or password
- network unavailable
- 401 login failure
- 403 unverified email or restricted account
- unexpected server response
- Keychain write failure

## Acceptance Criteria

- The app shows LoginView when launched with no token.
- The app can call the real login endpoint.
- On successful login, token is stored in Keychain.
- Relaunch restores access token or refresh token from Keychain.
- Valid session fetches profile and enters the app.
- 401 or refresh failure clears local token and returns to login.
- `xcodebuild` passes.

## Out Of Scope

- No WebView login.
- Do not store OpenAI API keys in the app.
- Do not log tokens.
- Do not use Web httpOnly cookie refresh as the long-term iPadOS strategy.
- Do not implement full registration, password reset, or captcha in Phase 1.
