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

iPadOS 客户端需要先确认移动端策略：

- 方案 A：使用 `URLSession` cookie storage 支持 cookie-based refresh
- 方案 B：新增或确认适合原生 App 的 JSON refresh-token 流程

在这个问题确认前，不要深入实现 Phase 1。

## 第一批接口

```text
POST /api/v1/auth/login
POST /api/v1/auth/refresh
GET  /api/users/me/profile

GET  /api/assistant/conversations
POST /api/assistant/conversations
GET  /api/assistant/conversations/{id}
POST /api/assistant/conversations/{id}/messages/run
POST /api/assistant/conversations/{id}/messages/run/stream
```

## 安全规则

- 不要把 OpenAI API Key 放进 iPad App。
- access token 存入 Keychain。
- 不要记录 token 或 secret。
- 所有 AI 调用都走现有后端/orchestrator 服务。
