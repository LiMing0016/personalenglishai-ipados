# iPadOS Mobile Auth Design

Date: 2026-06-12

## Decision

Use a mobile-native authentication contract for the iPadOS app.

The iPadOS app should not copy the Web client's cookie-first login flow as its long-term architecture. The Web app can keep using access token in JSON plus httpOnly refresh cookie. The iPadOS app should use JSON access and refresh tokens stored in Keychain.

## Context

The reference Web/backend repository is available at:

```text
/Users/carterlina/projects/myprojects/personalenglishai-web-reference
```

Relevant backend facts:

- `POST /api/v1/auth/login` requires `captchaToken`.
- Login returns access token in JSON body.
- Refresh token is set as an httpOnly `refresh_token` cookie.
- `LoginResponse.refreshToken` is marked `@JsonIgnore`, so mobile clients cannot read it from the current login response.
- `POST /api/v1/auth/refresh` reads refresh token from cookie.
- `GET /api/users/me/profile` returns the current user's profile.

This is reasonable for Web, but not ideal for a native iPad app. Native clients should make session ownership explicit and store tokens in Keychain.

## Goals

- Let iPadOS users sign in with the same Personal English AI account.
- Store access and refresh tokens in Keychain.
- Restore session on app launch.
- Refresh access token without relying on Web cookies.
- Fetch `GET /api/users/me/profile` after login or restore.
- Keep all OpenAI API keys and backend secrets out of the iPad app.
- Keep SwiftUI state simple and testable.

## Non-Goals

- Do not rewrite the existing Web login flow.
- Do not put a WebView login shell into the iPad app.
- Do not copy all Web login variants into Phase 1.
- Do not implement registration, password reset, SMS login, or full account recovery in Phase 1.
- Do not store tokens in `UserDefaults`.

## Proposed Backend Contract

Add mobile-specific auth endpoints or mobile-aware variants of the existing endpoints. Exact endpoint names can be adjusted with the backend codebase, but the contract should be:

```text
POST /api/v1/auth/mobile/login
POST /api/v1/auth/mobile/refresh
POST /api/v1/auth/mobile/logout
```

Login request:

```json
{
  "email": "user@example.com",
  "password": "password"
}
```

Login response data:

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "refreshExpiresIn": 2592000
}
```

Refresh request:

```json
{
  "refreshToken": "jwt-refresh-token"
}
```

Refresh response data should use the same shape as login response.

Logout request:

```json
{
  "refreshToken": "jwt-refresh-token"
}
```

Logout can be idempotent. The iPad app will always clear local Keychain tokens even if the server logout request fails.

## Security Notes

- The current Web login requires slider captcha. For iPadOS Phase 1, do not build a native slider captcha unless backend policy requires it.
- If abuse prevention is needed for native apps, prefer a mobile-specific policy such as rate limiting, device/app attestation later, or a server-controlled challenge flow.
- Access and refresh tokens must be stored in Keychain only.
- Tokens must never be printed in logs.
- OpenAI credentials must remain server-side.

## iPadOS Architecture

Keep the existing MV + Services direction:

```text
Core/Auth/
  AuthSession.swift
  TokenStore.swift
  KeychainTokenStore.swift

Core/Networking/
  APIClient.swift
  APIEndpoint.swift
  APIEnvelope.swift
  APIError.swift

Features/Auth/
  Models/
    LoginRequest.swift
    LoginResponse.swift
    RefreshTokenRequest.swift
  Services/
    AuthService.swift
  Views/
    LoginView.swift

Features/Profile/
  Models/
    MeProfile.swift
  Services/
    UserService.swift
```

`AuthSession` should become the single app-level source of session state:

```swift
enum AuthState {
    case restoring
    case signedOut
    case signedIn(MeProfile)
    case failed(String)
}
```

Token storage should support both access and refresh tokens:

```swift
protocol TokenStore {
    func readAccessToken() throws -> String?
    func saveAccessToken(_ token: String) throws
    func deleteAccessToken() throws

    func readRefreshToken() throws -> String?
    func saveRefreshToken(_ token: String) throws
    func deleteRefreshToken() throws
}
```

## User Flow

```text
App launch
  -> AuthSession.restore()
    -> no tokens
      -> show LoginView
    -> access token exists
      -> GET /api/users/me/profile
        -> success: show AppRootView
        -> 401: try mobile refresh
          -> success: save new tokens, retry profile
          -> failure: clear tokens, show LoginView
    -> only refresh token exists
      -> try mobile refresh
        -> success: save new tokens, fetch profile, show AppRootView
        -> failure: clear tokens, show LoginView

User signs in
  -> POST /api/v1/auth/mobile/login
  -> save access + refresh tokens in Keychain
  -> GET /api/users/me/profile
  -> show AppRootView
```

## UI Direction

Phase 1 login UI should be simple and native:

- Email field
- Password field
- Sign in button
- Loading state
- Inline validation
- Error message area
- Keyboard-friendly layout
- Accessibility identifiers for UI tests

The first screen should feel like an app entry, not a marketing landing page. After successful login, users should enter the iPad three-column workspace.

## Error Handling

Handle at least:

- Missing email or password.
- Invalid email format.
- Network unavailable.
- Invalid credentials.
- Email not verified or account restricted.
- Unexpected response format.
- Keychain read/write failure.
- Refresh failure.

On refresh failure, clear local tokens and return to signed-out state.

## Validation

Implementation should pass:

```bash
xcodebuild -quiet -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

When test targets exist, add focused tests for token storage, auth response decoding, and session restore transitions.

## Open Backend Work

The iPadOS repository can implement its client side against this contract with mock services first. Real production login requires the backend repository to expose the mobile auth contract above or an equivalent endpoint that returns refresh token in JSON.

