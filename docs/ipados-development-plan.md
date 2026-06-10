# Personal English AI iPadOS Development Plan

本文档用于指导 `personalenglishai-ipados` 从零实现 iPadOS 原生客户端。现有 Web 仓库 `LiMing0016/personalenglishai` 保留为全栈主项目，iPadOS 仓库只负责 Apple 平台客户端。

## 1. 总体判断

现有 Web 项目已经包含完整后端和 AI 服务：

- `web/`: Vue 3 + TypeScript + Vite 前端
- `backend/`: Spring Boot + MySQL + Redis + JWT 后端
- `python/ai_orchestrator/`: FastAPI + OpenAI Agents SDK 学习助手编排服务

iPadOS 端不需要重新实现后端、数据库和 AI 编排。正确做法是：

- iPadOS 使用 SwiftUI 新做原生客户端。
- 继续复用现有 Spring Boot API。
- 继续由后端/Python 服务调用 OpenAI，不把 API Key 放进 iPad App。
- Web 和 iPadOS 可以共用同一套用户、作文、对话、订阅、学习数据。

## 当前状态

- Phase 0 的基础 Xcode 项目骨架已创建。
- 当前已有 SwiftUI App 入口、三栏 `NavigationSplitView`、基础目录结构、mock 首页、学习助手、写作和个人中心页面。
- 当前已有基础 `APIClient`、SSE parser、TokenStore/KeychainTokenStore 和 AppConfiguration 占位。
- 当前验证命令见根目录 `AGENTS.md`。
- 下一步进入登录与用户会话接入。

## 2. 推荐仓库安排

当前推荐采用两个仓库：

```text
personalenglishai/
  web/                  # Vue Web 客户端
  backend/              # Spring Boot API
  python/               # AI orchestrator
  docs/                 # Web/后端/部署文档

personalenglishai-ipados/
  PersonalEnglishAI/    # iPadOS SwiftUI App 源码
  PersonalEnglishAITests/
  PersonalEnglishAIUITests/
  docs/                 # iPadOS 客户端设计与迁移文档
```

不建议把 iPadOS 代码塞进现有 Web 全栈仓库，原因是：

- Xcode 项目、签名、资源、测试方式和 Web/后端差异很大。
- iPadOS 发布节奏可能不同于 Web/后端。
- Swift 包、App Store 配置、真机调试资产放在独立仓库更清晰。

只有当团队强依赖 monorepo、统一 CI、统一版本号时，才考虑把 iPadOS 放进主仓库的 `ios/` 或 `apps/ipados/`。

## 3. iPadOS 端主流架构选择

第一版推荐使用 SwiftUI 原生架构：

- UI: SwiftUI
- 导航: `NavigationSplitView` + `NavigationStack`
- 状态: `@State`, `@Binding`, `@Environment`, iOS 17+ 可用 `@Observable`
- 异步: Swift Concurrency, `async/await`, `.task`
- 网络: `URLSession`
- 鉴权存储: Keychain 保存 access token，必要时处理 refresh cookie
- 本地草稿: SwiftData 或文件/JSON，第一版可以先用轻量本地存储

不建议第一版使用：

- UIKit 大量手写页面
- WebView 套壳作为主体验
- 过早引入复杂 MVVM
- 把所有页面共用一个巨大 ViewModel
- 把网络请求直接写在 SwiftUI `body` 中

推荐风格是 MV + Services：

- View 负责界面和少量页面状态。
- Model 负责接口数据结构和领域数据。
- Service 负责网络、鉴权、流式响应、持久化等业务操作。
- 只有当某个页面状态非常复杂时，才为该功能引入 feature-local model/view model。

## 4. 推荐目录结构

创建 Xcode 项目后，建议源码按功能和基础设施拆分：

```text
PersonalEnglishAI/
  App/
    PersonalEnglishAIApp.swift
    AppRootView.swift
    AppEnvironment.swift
    AppRoute.swift
    AppTab.swift

  Core/
    Networking/
      APIClient.swift
      APIEndpoint.swift
      APIError.swift
      APIEnvelope.swift
      AuthInterceptor.swift
      ServerSentEventsParser.swift
    Auth/
      AuthSession.swift
      TokenStore.swift
      KeychainTokenStore.swift
    Persistence/
      DraftStore.swift
      AppStorageKeys.swift
    Configuration/
      AppConfiguration.swift
      EnvironmentValues+Services.swift
    Utilities/
      DateFormatting.swift
      Validation.swift

  DesignSystem/
    Colors.swift
    Typography.swift
    Spacing.swift
    Components/
      LoadingView.swift
      EmptyStateView.swift
      ErrorStateView.swift
      PrimaryButton.swift

  Features/
    Auth/
      Models/
        LoginRequest.swift
        LoginResponse.swift
      Services/
        AuthService.swift
      Views/
        LoginView.swift
        RegisterView.swift

    Dashboard/
      Views/
        DashboardView.swift

    Assistant/
      Models/
        AssistantConversation.swift
        AssistantMessage.swift
        AssistantProject.swift
        AssistantRequest.swift
        AssistantStreamEvent.swift
      Services/
        AssistantService.swift
      Views/
        AssistantRootView.swift
        ConversationListView.swift
        ChatView.swift
        MessageBubbleView.swift
        ChatInputBar.swift

    Writing/
      Models/
        WritingEvaluateRequest.swift
        WritingEvaluateResponse.swift
        WritingHistoryItem.swift
      Services/
        WritingService.swift
      Views/
        WritingRootView.swift
        WritingEditorView.swift
        WritingResultView.swift
        WritingHistoryView.swift

    Profile/
      Models/
        MeProfile.swift
        SubscriptionStatus.swift
        AbilityProfile.swift
      Services/
        UserService.swift
        SubscriptionService.swift
      Views/
        ProfileView.swift
        SubscriptionView.swift

  Resources/
    Assets.xcassets
    Localizable.xcstrings
```

这个结构的原则：

- `Core/` 放所有功能都会用到的底层能力。
- `Features/` 按业务功能拆，避免所有页面堆在一个目录。
- 每个 feature 内部再按 `Models/Services/Views` 分层。
- `DesignSystem/` 放可复用 UI 元素，不放业务逻辑。
- `App/` 只做应用入口、路由、依赖注入和根布局。

## 5. 导航与 iPad 布局

iPadOS 第一版建议使用三层体验：

```text
左侧栏: 功能入口
  - 首页
  - 学习助手
  - 写作评分
  - 个人中心

中间栏: 列表或上下文
  - 对话列表
  - 作文历史
  - 设置分组

右侧主区域: 当前工作区
  - 聊天窗口
  - 写作编辑器
  - 评分结果
```

SwiftUI 上对应：

- App 根视图使用 `NavigationSplitView`。
- 每个主功能内部使用自己的 `NavigationStack`。
- 路由用 enum 表达，例如 `AppRoute`、`AssistantRoute`。
- sheet/alert 用 enum 表达，不用很多个 boolean 控制。

## 6. 和现有后端的接口边界

iPadOS 端应该直接请求后端 API，不请求 Web 前端。

Web 端当前 API 模式：

- Web 通过 `/api` 代理到 Spring Boot。
- 请求携带 `Authorization: Bearer <token>`。
- refresh token 通过 httpOnly cookie 静默续签。

iPadOS 端需要适配：

- `APIClient` 配置真实 API base URL，例如 `https://api.your-domain.com/api`。
- access token 保存到 Keychain。
- 每个请求自动加 `Authorization`。
- 401 时调用 `/v1/auth/refresh`，如果后端 refresh 强依赖 cookie，则需要确认移动端 cookie 策略。
- 如果移动端不适合使用 cookie refresh，后端最好新增移动端 refresh token JSON 返回/刷新机制。

第一批需要接入的接口：

```text
Auth
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout

User
GET   /api/users/me/profile
PATCH /api/users/me/profile/stage

Assistant
GET    /api/assistant/conversations
POST   /api/assistant/conversations
GET    /api/assistant/conversations/{id}
POST   /api/assistant/conversations/{id}/messages/run
POST   /api/assistant/conversations/{id}/messages/run/stream

Writing
POST /api/writing/evaluate
POST /api/writing/evaluate/submit
GET  /api/writing/evaluate/tasks/{requestId}
GET  /api/writing/history

Profile / Subscription
GET /api/users/me/profile/ability
GET /api/users/me/profile/stats
GET /api/subscription/me
GET /api/subscription/plans
```

## 7. 实现阶段

### Phase 0: iPadOS 项目骨架

目标：App 能启动，并有稳定的工程结构。

内容：

- 创建 SwiftUI iPadOS 项目。
- 建立 `App/Core/DesignSystem/Features` 目录。
- 实现基础 `NavigationSplitView`。
- 实现 `APIClient`、`APIError`、`AppConfiguration`。
- 加入 mock service，先不依赖真实后端也能预览界面。

验收标准：

- Xcode 能编译运行到 iPad Simulator。
- App 有左侧栏和空白工作区。
- SwiftUI Preview 可打开核心页面。

### Phase 1: 登录与用户会话

目标：用户能登录并进入应用。

内容：

- 登录页。
- `AuthService` 调用 `/v1/auth/login`。
- Keychain 保存 token。
- 启动时恢复登录态。
- 获取 `/users/me/profile`。
- 处理 401、403、登录过期。

验收标准：

- 正确账号可以登录。
- 关闭 App 再打开仍能保持登录。
- token 失效时回到登录页。

### Phase 2: 学习助手 MVP

目标：跑通最核心的 AI 对话。

内容：

- 对话列表。
- 新建对话。
- 消息列表。
- 发送消息。
- 第一版可先接非流式 `/messages/run`。
- 第二步接流式 `/messages/run/stream`。

验收标准：

- 能创建会话。
- 能发送英文学习问题。
- 能显示 AI 回复。
- 网络错误、生成中、空会话都有明确状态。

### Phase 3: 写作评分 MVP

目标：用户能在 iPad 上写作文并提交评分。

内容：

- 写作编辑器。
- 自由写作/考试写作模式。
- 调用 `/writing/evaluate` 或 `/writing/evaluate/submit`。
- 展示总分、维度分、语法错误和修改建议。
- 本地自动保存草稿。

验收标准：

- 输入作文后能拿到评分。
- 评分结果能清楚展示。
- App 退出或切换页面不丢草稿。

### Phase 4: iPadOS 体验打磨

目标：从“能用”变成“像 iPad App”。

内容：

- 横屏/竖屏布局优化。
- 键盘快捷键。
- 分屏与 Stage Manager 适配。
- 侧边栏折叠状态。
- 文本输入体验优化。
- 加载态、空状态、错误态统一。

验收标准：

- iPad 横屏主体验舒适。
- 长文本输入不卡顿。
- 切换对话/写作历史时布局稳定。

### Phase 5: 个人中心与订阅

目标：补齐用户闭环。

内容：

- 个人信息。
- 学习统计。
- 能力画像。
- 订阅状态和 token 额度。
- 兑换码或邀请功能视情况加入。

验收标准：

- 用户能看到自己的权益和学习数据。
- 额度不足时 App 能正确提示。

### Phase 6: 发布准备

目标：准备 TestFlight 或 App Store。

内容：

- App Icon。
- 隐私说明。
- 崩溃/错误日志策略。
- 真机测试。
- 网络异常测试。
- App Store Connect 配置。
- 如涉及数字内容付费，评估 Apple In-App Purchase。

验收标准：

- 能发 TestFlight。
- 隐私、登录、AI 内容、订阅策略没有明显上架风险。

## 8. 第一版 MVP 范围

建议第一版只做：

```text
Phase 0 + Phase 1 + Phase 2
```

也就是：

- App 骨架
- 登录
- 用户资料
- 学习助手对话列表
- 新建对话
- 发送消息
- 显示 AI 回复

写作评分是第二个核心闭环，但建议等学习助手跑通后再做。

## 9. 开发注意事项

- iPad App 不保存 OpenAI API Key。
- 所有 AI 调用走现有后端或 Python orchestrator。
- SwiftUI View 不直接拼接复杂业务逻辑。
- 网络请求集中在 service 中。
- access token 放 Keychain，不放明文文件。
- 不要把 Web 的页面结构逐字搬到 iPadOS。
- 优先做原生 iPad 体验，而不是 WebView 套壳。
- 复杂页面先保证功能闭环，再优化视觉和交互。

## 10. 下一步

下一步进入登录与用户会话接入：

1. 确认后端移动端登录/refresh token 策略。
2. 实现真实 `AuthService`。
3. 登录成功后写入 Keychain。
4. 启动时恢复登录态。
5. 获取 `/api/users/me/profile` 并进入应用工作台。
