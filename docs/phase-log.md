# 阶段记录

本文档记录已经发生的事情。路线图描述计划，本文件记录完成事项、开放问题和下一步。

## 2026-06-10

完成事项：

- 创建 `AGENTS.md` 作为长期项目指引。
- 创建 `docs/ipados-development-plan.md`。
- 创建 Xcode 项目 `PersonalEnglishAI.xcodeproj`。
- 添加 SwiftUI App 入口和 iPad 三栏 shell。
- 添加 mock Home、Assistant、Writing、Profile 页面。
- 添加基础 `APIClient`、`APIEndpoint`、`APIError` 和 `APIEnvelope`。
- 添加 `AuthSession`、`TokenStore`、`KeychainTokenStore` 和 `ServerSentEventsParser`。
- 添加 VitePress 文档站骨架，并改为中英文语言切换结构。
- 添加 Phase 1 登录与会话设计文档。

已验证：

```bash
xcodebuild -quiet -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

未完成验证：

- `npm install` 因当前环境无法访问 `registry.npmjs.org` 未完成。
- VitePress 文档站尚未完成 `docs:build` 验证。

当时开放问题：

- 移动端 refresh token 应该使用 cookie-based 还是 JSON token-based？
- iPad Simulator 本地测试应该使用哪个后端 URL？

当时下一步：

- 完成认证策略评估，然后开始实现真实 `AuthService`。

## 2026-06-12

完成事项：

- 拉取 Web/后端参考仓库到同级目录 `personalenglishai-web-reference`。
- 对照 Web 登录和 Spring Boot auth 实现，确认当前 Web 生产流程依赖滑动验证码和 httpOnly refresh cookie。
- 选择 iPadOS 长期方案 B：mobile-native auth contract。
- 新增正式设计 spec：`docs/superpowers/specs/2026-06-12-ipados-mobile-auth-design.md`。
- 更新登录与会话设计，明确 access token 和 refresh token 都由 iPadOS 保存到 Keychain。

开放问题：

- 后端 mobile auth endpoint 的最终路径是否采用 `/api/v1/auth/mobile/*`。
- iPad Simulator 本地测试应该使用哪个后端 URL。

下一步：

- 基于 mobile auth contract 编写 Phase 1 实现计划。
