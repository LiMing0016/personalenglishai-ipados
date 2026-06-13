# iPadOS Mobile Auth Contract Trae 题目

## 背景

iPadOS 端已经确定采用 mobile-native auth contract：

- iPadOS 不使用 WebView 登录。
- iPadOS 不把 Web 端 httpOnly cookie refresh 作为长期方案。
- iPadOS 使用 Keychain 保存 access token 和 refresh token。
- refresh 时通过 JSON body 提交 refresh token。

现有 Web 登录流程保留不变：

- `POST /api/v1/auth/login` 需要 `captchaToken`。
- access token 通过 JSON body 返回。
- refresh token 通过 httpOnly cookie 保存。
- `POST /api/v1/auth/refresh` 从 cookie 读取 refresh token。

本题只要求 Trae 在后端仓库中新增 iPadOS 可用的 mobile auth 接口，不做 iPadOS SwiftUI 代码。

---

## A1：新增 iPadOS mobile login 接口

标签：中等 / 01代码 / 后端

### Prompt

请在后端新增 iPadOS 使用的 mobile login 接口。不要破坏现有 Web 登录接口，不要修改现有 `/api/v1/auth/login` 的 captcha 和 cookie 行为。

新增接口：

```text
POST /api/v1/auth/mobile/login
```

请求 body：

```json
{
  "email": "user@example.com",
  "password": "password"
}
```

响应继续使用现有 `ApiResponse<T>` 包装，`data` 至少包含：

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "refreshExpiresIn": 2592000
}
```

### 要求

- 可以新增 `MobileAuthControllerV1`，路径建议放在 `backend/src/main/java/com/personalenglishai/backend/controller/auth/v1/`。
- 可以新增 mobile 专用 DTO，不要直接改坏 Web 端 `LoginResponse` 的 `@JsonIgnore` 行为。
- 复用现有 `AuthService.login(email, password)` 生成 token。
- mobile login 不设置 refresh cookie。
- mobile login response 的 JSON `data` 必须包含 access token 和 refresh token。
- 不要在日志中输出 access token 或 refresh token。
- 不要修改 Web 登录、注册、手机登录、验证码、refresh、logout 的现有行为。

### 验收标准

- `POST /api/v1/auth/mobile/login` 可以用邮箱密码登录。
- 响应 `data.accessToken` 非空。
- 响应 `data.refreshToken` 非空。
- 响应 `data.tokenType` 为 `Bearer` 或与现有 JWT 类型一致。
- 响应 `data.expiresIn` 和 `data.refreshExpiresIn` 为有效秒数。
- `POST /api/v1/auth/login` 仍保持原有 captcha 和 refresh cookie 行为。
- 代码中没有 token 明文日志。

---

## A2：新增 iPadOS mobile refresh 接口

标签：中等 / 01代码 / 后端

### Prompt

请在后端新增 iPadOS 使用的 mobile refresh 接口。该接口从 JSON body 读取 refresh token，不依赖 Web 端 httpOnly cookie。

新增接口：

```text
POST /api/v1/auth/mobile/refresh
```

请求 body：

```json
{
  "refreshToken": "jwt-refresh-token"
}
```

响应继续使用现有 `ApiResponse<T>` 包装，`data` 结构与 mobile login 保持一致：

```json
{
  "accessToken": "new-jwt-access-token",
  "refreshToken": "new-jwt-refresh-token",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "refreshExpiresIn": 2592000
}
```

### 要求

- 复用现有 `AuthService.refresh(refreshToken)`。
- 不从 cookie 读取 refresh token。
- 不设置 refresh cookie。
- refresh token 无效、过期或类型错误时，沿用现有鉴权错误格式。
- 不要在日志中输出 refresh token。
- 不要影响现有 `/api/v1/auth/refresh` 的 cookie refresh 行为。

### 验收标准

- 使用 mobile login 返回的 refresh token 调用 mobile refresh 可以成功换取新 token。
- 响应 `data.accessToken` 非空。
- 响应 `data.refreshToken` 非空。
- 使用空 refresh token 或无效 refresh token 会返回鉴权失败。
- 现有 `/api/v1/auth/refresh` 仍从 cookie 读取 refresh token。
- 代码中没有 token 明文日志。

---

## B1：补齐 mobile logout 与接口测试

标签：中等 / 工程化 / 后端

### Prompt

请为 iPadOS mobile auth 补齐 logout 接口，并为 mobile login / refresh / logout 增加后端测试或等价的本地验证。

新增接口：

```text
POST /api/v1/auth/mobile/logout
```

请求 body：

```json
{
  "refreshToken": "jwt-refresh-token"
}
```

### 要求

- mobile logout 不清 Web cookie。
- 第一版可以做成幂等接口：服务端即使没有 refresh token blacklist，也返回成功。
- iPadOS 客户端会在本地清理 Keychain token，所以服务端 logout 不能阻塞本地退出。
- 如果后端已有 refresh token 版本号、黑名单或失效机制，可以复用；没有则不要临时引入复杂表结构。
- 增加 mobile auth 相关测试，至少覆盖成功登录、成功 refresh、无效 refresh token、logout 幂等返回。
- 不要影响 Web logout 的清 cookie 行为。

### 验收标准

- `POST /api/v1/auth/mobile/logout` 可调用并返回成功。
- 调用 mobile logout 不会设置或清除 Web refresh cookie。
- mobile login 测试通过。
- mobile refresh 成功测试通过。
- mobile refresh 无效 token 测试通过。
- mobile logout 幂等测试通过。
- 现有 Web auth 测试或最小回归验证通过。

---

## B2：补充后端文档与安全边界说明

标签：简单 / 工程化 / 后端

### Prompt

请为新增的 iPadOS mobile auth contract 补充后端文档，说明它与 Web auth 的区别、接口请求响应、token 存储责任和安全边界。

### 要求

- 在后端文档中新增或更新 auth 文档，记录：
  - Web auth：refresh token 使用 httpOnly cookie。
  - iPadOS mobile auth：refresh token 通过 JSON 返回，由客户端存 Keychain。
  - mobile login / refresh / logout 的路径、请求 body、响应 `data` 字段。
  - mobile 接口不返回 OpenAI API Key 或任何服务端 secret。
  - mobile 接口不得记录 token 明文日志。
- 文档不要要求 iPadOS 端使用 WebView。
- 文档不要把 mobile auth 写成替代 Web auth；两套契约并存。

### 验收标准

- 文档能清楚说明 `/api/v1/auth/mobile/login`。
- 文档能清楚说明 `/api/v1/auth/mobile/refresh`。
- 文档能清楚说明 `/api/v1/auth/mobile/logout`。
- 文档明确 Web auth 继续使用 httpOnly cookie refresh。
- 文档明确 iPadOS access token 和 refresh token 存 Keychain。
- 文档没有要求把 OpenAI API Key 放到客户端。
