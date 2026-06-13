# 登录与会话设计

本文档设计 Phase 1：登录与用户会话模块。目标是先跑通稳定、安全、可扩展的登录闭环，再进入学习助手真实 API 接入。

## 模块目标

- 用户可以使用现有 Personal English AI 账号登录。
- 登录成功后 access token 写入 Keychain。
- App 启动时可以恢复登录态。
- 登录态有效时获取 `/api/users/me/profile`。
- token 失效时清理会话并回到登录页。
- 不在 App 中保存 OpenAI API Key 或其他服务端 secret。

## 已选择的认证方案

已经选择方案 B：为 iPadOS 使用移动端原生认证契约。

Web 端继续使用当前生产流程：access token 通过 JSON body 返回，refresh token 通过 httpOnly cookie 保存。

iPadOS 端长期方案：

- 后端提供 mobile login/refresh/logout 契约。
- login 返回 access token 和 refresh token。
- iPadOS 将 access token 和 refresh token 都存入 Keychain。
- refresh 时通过 JSON body 提交 refresh token，不依赖 Web cookie。
- 详细设计见 `docs/superpowers/specs/2026-06-12-ipados-mobile-auth-design.md`。

## 用户流程

```text
App 启动
  -> AuthSession.restore()
    -> 有本地 token
      -> GET /api/users/me/profile
        -> 成功：进入 AppRootView
        -> 401：尝试 refresh
          -> refresh 成功：重试 profile
          -> refresh 失败：清理 token，展示 LoginView
    -> 无本地 token
      -> 展示 LoginView

用户登录
  -> POST /api/v1/auth/mobile/login
    -> 成功：保存 token，获取 profile，进入 AppRootView
    -> 失败：展示错误
```

## 状态模型

建议让 `AuthSession` 作为全局会话状态源：

```swift
enum AuthState {
    case restoring
    case signedOut
    case signedIn(MeProfile)
    case failed(String)
}
```

当前已有 `AuthSession` 和 `TokenStore`，后续可以从简单的 `accessToken/isAuthenticated` 演进为完整 `AuthState`。

## 文件边界

```text
Core/Auth/
  AuthSession.swift             # 全局会话状态，负责恢复、登录后更新、登出
  TokenStore.swift              # access/refresh token 存储协议
  KeychainTokenStore.swift      # Keychain 实现

Core/Networking/
  APIClient.swift               # 统一请求、Authorization header、错误映射
  APIError.swift
  APIEndpoint.swift
  APIEnvelope.swift

Features/Auth/
  Models/
    LoginRequest.swift
    LoginResponse.swift
    RefreshTokenRequest.swift
  Services/
    AuthService.swift           # 登录、refresh、logout
  Views/
    LoginView.swift             # 登录 UI

Features/Profile/
  Services/
    UserService.swift           # getMyProfile()
```

## API 设计

第一阶段 AuthService 建议提供：

```swift
protocol AuthService {
    func login(email: String, password: String) async throws -> LoginResponse
    func refresh() async throws -> LoginResponse
    func logout() async throws
}
```

UserService 提供：

```swift
protocol UserService {
    func getMyProfile() async throws -> MeProfile
}
```

## UI 设计

第一版登录 UI 先保持简单：

- 邮箱输入框
- 密码输入框
- 登录按钮
- loading 状态
- 错误提示
- 登录成功后进入主工作台

不要在 Phase 1 同时做注册、忘记密码、验证码、滑块验证。那些属于后续增强。

## 错误处理

需要覆盖：

- 邮箱或密码为空
- 网络不可用
- 401 登录失败
- 403 邮箱未验证或账号受限
- 服务器返回非预期格式
- token 写入 Keychain 失败

## 验收标准

- App 无 token 启动时显示登录页。
- 输入账号密码后可以调用真实登录接口。
- 登录成功后 token 写入 Keychain。
- 重启 App 后可以从 Keychain 恢复 access token 或 refresh token。
- 登录态有效时可以获取 profile 并进入 App。
- 401/refresh 失败时清理本地 token 并回到登录页。
- `xcodebuild` 构建通过。

## 不做的事情

- 不做 WebView 登录。
- 不把 OpenAI API Key 写入 App。
- 不在日志里输出 token。
- 不把 Web 端 httpOnly cookie refresh 作为 iPadOS 长期方案。
- 不在 Phase 1 里实现完整注册/找回密码/验证码。
