# AGENTS.md

本文件是 `personalenglishai-ipados` 仓库的长期开发记忆。所有 agent 在本仓库工作前，必须先阅读本文件，再参考 `docs/ipados-development-plan.md`。

## Scope and Precedence

本文件适用于整个仓库。

如果后续在子目录中新增更具体的 `AGENTS.md`，则子目录文件只覆盖该子目录内的细节规则；本文件仍作为全局方向。

优先级：

1. 用户当前明确要求
2. 更近目录中的 `AGENTS.md`
3. 本文件
4. `docs/ipados-development-plan.md`
5. 代码库已有实现模式

## Project Identity

这是 Personal English AI 的 iPadOS 原生客户端仓库。

现有 Web/后端主仓库是 `LiMing0016/personalenglishai`：

- `web/`: Vue 3 + TypeScript + Vite
- `backend/`: Spring Boot + MySQL + Redis + JWT
- `python/ai_orchestrator/`: FastAPI + OpenAI Agents SDK

本仓库不重做后端、数据库或 AI 编排。本仓库只实现 iPadOS SwiftUI App，并复用现有后端 API。

## Product Direction

目标是从 0 到 1 做一个主流、可维护、原生体验好的 iPadOS 学习应用。

具体阶段、MVP 范围和任务拆解不在本文件维护，以规划文档为准：

- `docs/ipados-development-plan.md`

## Architecture Rules

优先使用主流 SwiftUI 原生架构：

- UI: SwiftUI
- Navigation: `NavigationSplitView` + `NavigationStack`
- State: `@State`, `@Binding`, `@Environment`, iOS 17+ 可用 `@Observable`
- Async: Swift Concurrency, `async/await`, `.task`
- Networking: `URLSession`
- Auth storage: Security framework based Keychain wrapper
- Local draft/cache: 从简单方案开始，必要时再引入 SwiftData
- Dependencies: 优先使用系统框架；确需第三方库时优先 Swift Package Manager

默认采用 MV + Services，而不是一开始套复杂 MVVM：

- View 负责界面表达和少量页面状态。
- Model 负责接口数据结构和领域数据。
- Service 负责网络、鉴权、流式响应、持久化等业务操作。
- 只有当某个功能状态明显复杂时，才引入 feature-local model/view model。

禁止把网络请求、token 处理、复杂业务逻辑直接写在 SwiftUI `body` 中。

SwiftUI 实现规则：

- 共享 app service 通过 `@Environment` 注入。
- feature-local 依赖优先用显式 initializer 传入。
- navigation、sheet、alert 优先用 enum 表达，不堆多个 boolean 状态。
- 异步加载使用 `.task` / `.task(id:)`，并提供 loading、empty、error 状态。
- 会更新 UI 的 observable/session 类型应保持在 MainActor 上。
- 复杂 View 拆成独立 subview，不用大量 computed `some View` 拼完整页面。
- 重要页面提供 SwiftUI Preview，并使用 mock service / fixture data。
- 交互控件应补充可访问性 label 或 identifier，方便 UI 测试。

## Repository Structure

创建 Xcode 项目后，按以下结构组织源码：

```text
PersonalEnglishAI/
  App/
  Core/
    Networking/
    Auth/
    Persistence/
    Configuration/
    Utilities/
  DesignSystem/
    Components/
  Features/
    Auth/
    Dashboard/
    Assistant/
    Writing/
    Profile/
  Resources/

PersonalEnglishAITests/
PersonalEnglishAIUITests/
docs/
```

目录职责：

- `App/`: App 入口、根布局、路由、依赖注入。
- `Core/`: 跨功能基础设施。
- `DesignSystem/`: 可复用 UI 组件、颜色、字体、间距。
- `Features/`: 按业务功能拆分，每个功能内部可有 `Models/Services/Views`。
- `docs/`: iPadOS 客户端设计、迁移计划、阶段记录。

## Backend Integration Rules

iPadOS 端直接请求 Spring Boot API，不请求 Web 前端。

重要原则：

- 不把 `OPENAI_API_KEY` 放进 iPad App。
- 所有 AI 能力都走现有后端或 Python orchestrator。
- access token 存 Keychain。
- 请求自动携带 `Authorization: Bearer <token>`。
- 401 时走 refresh 流程；如果现有 refresh 强依赖 httpOnly cookie，需要评估移动端兼容方案。

第一批接口：

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

## Development Workflow

每次开发前：

1. 阅读本文件。
2. 阅读 `docs/ipados-development-plan.md`。
3. 检查当前仓库结构和 git 状态。
4. 明确当前阶段和本次改动范围。

每次实现时：

1. 先保持功能闭环，再做视觉打磨。
2. 优先 mock service + preview，降低对后端运行状态的依赖。
3. 再接真实 API。
4. 每个页面必须考虑 loading、empty、error 状态。
5. 保持 SwiftUI View 小而清晰，复杂 UI 拆成独立 subview。
6. 修改接口、目录结构或阶段计划时，同步更新文档。

每次完成后：

1. 尽量运行 build/test。
2. 说明改动了哪些文件。
3. 说明有没有未验证项。
4. 如果进入新阶段，更新相关文档。

## Definition of Done

一次开发任务完成时，至少满足：

- 改动范围符合当前阶段目标。
- 新增 Swift 文件位于正确功能目录。
- View、Service、Model 边界清楚。
- 重要交互页面有 mock/preview 或可测试入口。
- 交互控件具备基本 accessibility 支持。
- 没有把 secret、token、API key 写入仓库。
- 能运行的情况下已执行 build/test。
- 未能验证的内容在最终说明中明确写出。
- 如果改变架构、接口、阶段计划或目录结构，已同步更新 `docs/`。

## Validation Commands

当前基础构建验证命令：

```bash
xcodebuild -quiet -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

当前还没有 test target。新增测试 target 后，应在这里补充 `test` 命令。

## UI/UX Principles

iPadOS App 不能只是 Web 版搬运。

优先体现 iPad 体验：

- 左侧功能栏
- 中间列表/上下文栏
- 右侧主工作区
- 横屏优先，同时兼容竖屏
- 支持长文本输入
- 为键盘快捷键、分屏、Stage Manager、Apple Pencil 预留空间

第一版不要做营销 landing page。打开 App 后应直接进入登录、首页或学习工作台。

## Do Not

- 不要把本项目做成 WebView 套壳，除非用户明确要求临时验证。
- 不要在 iPad App 中保存 OpenAI API Key。
- 不要把后端、数据库、AI orchestrator 重写到本仓库。
- 不要把所有 SwiftUI 页面、网络层和状态管理堆进一个文件。
- 不要为了简单页面过早引入全局 ViewModel。
- 不要在没有必要时引入第三方依赖；优先使用 SwiftUI、Foundation、URLSession、Security/Keychain。
- 不要修改 Web 主仓库的假设或接口约定，除非用户明确要求跨仓库变更。

## Documentation Memory Rules

为了防止以后遗忘：

- 长期方向写在 `AGENTS.md`。
- 阶段规划、MVP 范围、任务拆解写在 `docs/roadmap.md` 和 `docs/ipados-development-plan.md`。
- 已完成事项、开放问题和下一步写在 `docs/phase-log.md`。
- 文档站使用 VitePress，配置位于 `docs/.vitepress/config.mts`。
- 新增重要架构决策时，优先补充到 `docs/`。
- 如果实际实现偏离本文档，必须更新文档，而不是让代码和规划分叉。

## Current Next Step

当前已创建 Xcode 项目骨架。下一步以 `docs/ipados-development-plan.md` 中的最早未完成阶段为准。
