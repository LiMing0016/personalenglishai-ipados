# API 接入

iPadOS App 应该直接请求现有 Spring Boot API，不请求 Vue Web 前端。

## Base URL

开发默认地址：

```text
http://127.0.0.1:18080/api
```

生产环境地址后续应通过 `AppConfiguration` 配置。

## 鉴权边界

Web 客户端当前使用：

- access token 放在 `Authorization: Bearer <token>` 中
- refresh token 通过 httpOnly cookie 携带

iPadOS 客户端已选择 mobile-native auth contract：

- 后端提供 mobile login/refresh/logout 契约。
- login/refresh 通过 JSON body 返回 access token 和 refresh token。
- iPadOS 将 access token 和 refresh token 保存到 Keychain。
- refresh 时通过 JSON body 提交 refresh token，不依赖 Web httpOnly cookie。

登录与会话的详细设计见 [登录与会话设计](./auth-session-design)。

## 第一批接口

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

## 安全规则

- 不要把 OpenAI API Key 放进 iPad App。
- access token 和 refresh token 存入 Keychain。
- 不要记录 token 或 secret。
- 所有 AI 调用都走现有后端/orchestrator 服务。
