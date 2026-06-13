# iPadOS Auth Module Trae 题目

## 背景

本题用于实现 Personal English AI iPadOS 端登录注册模块。iPadOS App 不使用 WebView 登录，直接请求现有 Spring Boot API。

当前后端已有 Web auth 接口：

- `GET /api/v1/auth/captcha`
- `POST /api/v1/auth/captcha/verify`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/resend-verification`
- `GET /api/v1/auth/verify-email?token=...`
- `POST /api/v1/auth/forgot-password`
- `GET /api/v1/auth/reset-password/validate?token=...`
- `POST /api/v1/auth/reset-password`
- `GET /api/users/me/profile`

本题只要求实现 iPadOS SwiftUI 端登录注册闭环，不要求修改后端。

---

## A1：实现 iPadOS 登录页基础 UI 与登录接口

标签：中等 / feature迭代 / 前端

### Prompt

请在 iPadOS SwiftUI 项目中实现 Personal English AI 登录页基础闭环。页面需要参考现有品牌风格，使用深色品牌背景、居中的登录卡片、Logo、标题、邮箱输入框、密码输入框、登录按钮、错误提示和 loading 状态。

登录流程需要调用后端：

```text
GET  /api/v1/auth/captcha
POST /api/v1/auth/captcha/verify
POST /api/v1/auth/login
GET  /api/users/me/profile
```

登录成功后将 access token 写入 Keychain，并进入主应用界面。

### 要求

- 不使用 WebView 登录。
- 新增或完善 `AuthService`、`LoginRequest`、`LoginResponse`、`CaptchaChallenge` 等模型。
- `APIClient` 请求时支持 `Authorization: Bearer <token>`。
- 登录前必须展示滑块验证码，验证码通过后再提交登录。
- 登录成功后 token 保存到 Keychain。
- App 启动时可以从 Keychain 恢复登录态。
- 登录页输入框、按钮、错误提示需要有清晰的 SwiftUI 状态。
- 后端返回错误时，优先展示后端 `message`。

### 验收标准

- 无 token 启动 App 时显示登录页。
- 输入邮箱、密码后可以加载验证码。
- 滑块验证码通过后调用 `/api/v1/auth/login`。
- 登录成功后进入主应用界面。
- token 被保存到 Keychain。
- 重启 App 后可以恢复登录态。
- 密码错误或验证码错误时页面显示错误信息。
- `xcodebuild test` 或等价构建验证通过。

---

## A2：实现注册流程与邮箱未验证提示

标签：中等 / feature迭代 / 前端

### Prompt

请在 iPadOS 登录页中增加注册模式。用户可以在登录和注册之间切换。注册需要填写昵称、邮箱、密码、确认密码，并调用现有后端注册接口。

注册接口：

```text
POST /api/v1/auth/register
```

注册成功后不要直接登录，而是提示用户先完成邮箱验证。

### 要求

- 登录页提供“去注册 / 已有账号，去登录”切换入口。
- 注册字段包括昵称、邮箱、密码、确认密码。
- 前端做基本校验：
  - 昵称不能为空且不超过 50 个字符。
  - 邮箱必须包含 `@` 和 `.`。
  - 密码至少 8 位。
  - 密码包含大小写字母和数字。
  - 两次密码必须一致。
- 注册成功后切回登录模式。
- 注册成功后显示“请先完成邮箱验证”的提示。
- 登录接口返回 403 时，提示该邮箱尚未完成验证。
- 不要在注册成功后自动写入 token。

### 验收标准

- 用户可以从登录页切换到注册页。
- 注册表单校验错误会阻止提交并展示中文提示。
- 注册成功后显示邮箱验证提示。
- 登录未验证邮箱时显示明确提示。
- 后端返回“邮箱已存在”等错误时，页面展示后端错误文案。
- 现有登录流程不被破坏。

---

## B1：补齐邮箱验证与找回密码闭环

标签：困难 / feature迭代 / 前端

### Prompt

请在 iPadOS 登录注册模块中补齐邮箱验证和找回密码流程。页面不使用系统默认 Form 样式，使用与登录页一致的深色品牌弹窗。

需要接入的后端接口：

```text
POST /api/v1/auth/resend-verification
GET  /api/v1/auth/verify-email?token=...
POST /api/v1/auth/forgot-password
GET  /api/v1/auth/reset-password/validate?token=...
POST /api/v1/auth/reset-password
```

### 要求

- 登录页提供“忘记密码？”入口。
- 邮箱未验证提示区域提供“重发验证邮件”和“我已有验证链接”入口。
- 邮箱验证弹窗支持：
  - 输入邮箱后重发验证邮件。
  - 粘贴验证链接或 token 完成验证。
- 找回密码弹窗支持：
  - 输入邮箱发送重置邮件。
  - 粘贴重置链接或 token。
  - 输入新密码和确认密码。
  - 先校验 reset token，再提交新密码。
- 支持从 URL 中提取 `token` query 参数。
- 弹窗 UI 需要与登录页视觉一致，避免浅色系统 sheet 与品牌背景割裂。
- 所有错误优先展示后端 `message`。

### 验收标准

- 点击“忘记密码？”可以打开找回密码弹窗。
- 输入邮箱后可以调用 `/api/v1/auth/forgot-password`。
- 粘贴 reset token 后可以校验 token 并提交新密码。
- 邮箱未验证时可以重发验证邮件。
- 粘贴 verify token 后可以完成邮箱验证。
- 弹窗关闭、loading、成功提示、错误提示都可正常工作。
- 无效 token 会显示明确错误。

---

## B2：补齐登录态刷新、深链和注册协议入口

标签：困难 / 工程化 / 前端

### Prompt

请完善 iPadOS Auth 模块的工程闭环：实现 401 自动刷新 token、邮箱验证/重置密码深链入口、注册协议与隐私政策确认，并补充单元测试。

需要支持的深链示例：

```text
personalenglishai://verify-email?token=verify-token
personalenglishai://reset-password?token=reset-token
https://personalenglish.ai/verify-email?token=verify-token
https://personalenglish.ai/reset-password?token=reset-token
```

### 要求

- `APIClient` 遇到 401 时尝试调用 `/api/v1/auth/refresh`。
- refresh 成功后更新 Keychain token，并重试原请求一次。
- refresh 失败或重试后仍然 401 时，清理本地 token 并回到登录页。
- refresh 接口本身不能触发递归 refresh。
- 增加 `AuthDeepLinkAction` 或等价路由对象，解析 verify-email 和 reset-password 链接。
- App 入口使用 `.onOpenURL` 接收深链。
- Info.plist 注册 `personalenglishai` URL scheme。
- 深链打开后自动展示对应的邮箱验证或找回密码弹窗，并预填 token。
- 注册前必须勾选“我已阅读并同意用户协议和隐私政策”。
- 用户协议和隐私政策可以先做应用内品牌弹窗，文案可为第一版占位说明。
- 增加测试覆盖：
  - refresh endpoint 调用。
  - 401 后刷新 token 并重试。
  - 深链 token 解析。
  - 未勾选协议时注册按钮不可提交。

### 验收标准

- access token 失效后，普通 API 请求会自动 refresh 并重试一次。
- refresh 失败后 App 清理登录态并回到登录页。
- `personalenglishai://verify-email?token=...` 可以打开邮箱验证弹窗。
- `personalenglishai://reset-password?token=...` 可以打开找回密码弹窗。
- 构建产物 Info.plist 中包含 `personalenglishai` URL scheme。
- 注册页未勾选协议时不能提交。
- 点击“用户协议”和“隐私政策”可以打开弹窗。
- 新增测试通过，现有 auth 测试不回退。

---

## B3：Auth 模块测试与文档回归

标签：中等 / 工程化 / 前端

### Prompt

请为 iPadOS Auth 模块补充测试与简短文档，确保登录注册闭环后续可维护。

### 要求

- 使用 mock URL protocol 或等价方式测试 `AuthService`。
- 覆盖登录、注册、验证码、logout、refresh、邮箱验证、找回密码、重置密码。
- 覆盖后端错误 message 保留逻辑。
- 在 docs 中补充 iPadOS 当前 Auth 实现说明：
  - 使用现有后端 Web auth 接口。
  - access token 存 Keychain。
  - refresh 当前沿用 `/api/v1/auth/refresh`。
  - 长期可演进为 mobile-native auth contract。
  - 不在 iPadOS App 中保存 OpenAI API Key。
- 不要把测试写成只检查 mock 是否被调用，必须检查请求路径、HTTP method、请求 body 或响应解析。

### 验收标准

- Auth service 测试覆盖主要接口路径。
- APIClient 401 refresh 重试测试通过。
- 深链解析测试通过。
- 注册协议策略测试通过。
- `xcodebuild test` 通过。
- 文档能说明当前实现和长期 mobile auth contract 的区别。
