# 路线图

本文档描述 iPadOS 客户端的开发路线。具体完成情况记录在 `phase-log.md`，详细规划保留在 `ipados-development-plan.md`。

## 总体方向

- 构建原生 SwiftUI iPadOS 客户端。
- 复用现有 `LiMing0016/personalenglishai` 后端、数据库和 AI orchestrator。
- 不在 iPad App 中保存 OpenAI API Key。
- 优先跑通有价值的学习助手闭环，再扩展更多功能。

## Phase 0: App 骨架

状态：complete。

范围：

- Xcode 项目
- SwiftUI App 入口
- iPad 三栏根布局
- 功能目录结构
- mock Home、Assistant、Writing、Profile 页面
- 基础 API client 和鉴权存储占位

## Phase 1: 登录与会话

状态：next。

范围：

- 采用 mobile-native auth contract
- access token 和 refresh token 存入 Keychain
- 实现 `AuthService`
- 使用现有后端账号登录
- App 启动时恢复登录态
- 获取 `/api/users/me/profile`

## Phase 2: 学习助手 MVP

状态：planned。

范围：

- 对话列表
- 新建对话
- 加载消息
- 发送消息
- 先支持非流式回复
- 基础闭环稳定后再支持流式回复

## Phase 3: 写作 MVP

状态：planned。

范围：

- 写作编辑器
- 自由写作/考试写作模式
- 提交作文评分
- 展示分数和反馈
- 本地草稿持久化

## Phase 4: iPadOS 体验

状态：planned。

范围：

- 横屏和竖屏体验打磨
- 键盘快捷键
- Split View 和 Stage Manager 适配
- loading、empty、error 状态优化
- 无障碍检查

## Phase 5: 个人中心与订阅

状态：planned。

范围：

- 个人资料
- 学习统计
- 能力画像
- 订阅状态
- 额度使用情况

## Phase 6: 发布准备

状态：planned。

范围：

- App 图标和元数据
- 隐私说明
- TestFlight 准备
- 真机测试
- App Store 审核风险检查
