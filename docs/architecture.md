# 架构

iPadOS 客户端使用 SwiftUI，按功能组织目录，并把共享能力放在 `Core/` 中。

## 仓库职责

本仓库只负责 iPadOS 客户端。Web、后端、数据库和 AI 编排服务仍保留在 `LiMing0016/personalenglishai`。

## App 结构

```text
PersonalEnglishAI/
  App/
  Core/
  DesignSystem/
  Features/
  Resources/
```

## 核心原则

- SwiftUI View 负责 UI 表达和局部交互状态。
- 共享依赖放在 `Core/`，并通过 app environment values 注入。
- 网络代码放在 services 和 `APIClient` 中。
- 功能代码按产品区域组织。
- 接真实后端前，先使用 mock data 和 previews 验证体验。

## 当前基础

- `AppRootView` 负责 iPad 三栏布局。
- `APIClient` 是基础 URLSession wrapper。
- `AuthSession` 和 `TokenStore` 定义登录/会话边界。
- `KeychainTokenStore` 通过 Security framework 保存 access token。
- `ServerSentEventsParser` 为学习助手流式回复做准备。

## 说明

初始骨架没有使用 Swift macro 版本的 `#Preview` 和 `@Observable`，因为当前命令行构建环境会出现 Swift plugin server 错误。项目目前使用传统 `PreviewProvider` 和 `ObservableObject`，这仍然是稳定、主流的 iOS 开发方式。
