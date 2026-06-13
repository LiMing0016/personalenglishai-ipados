import SwiftUI
import UIKit

struct LoginView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @State private var authMode: AuthMode = .signIn
    @State private var nickname = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoadingCaptcha = false
    @State private var isVerifyingCaptcha = false
    @State private var isSubmitting = false
    @State private var isRegistering = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var pendingVerificationEmail: String?
    @State private var supportSheet: AuthSupportSheet?
    @State private var captchaErrorMessage: String?
    @State private var captchaChallenge: CaptchaChallenge?
    @State private var sliderX: CGFloat = 0
    @FocusState private var focusedField: Field?

    private enum Field {
        case nickname
        case email
        case password
        case confirmPassword
    }

    private enum AuthMode {
        case signIn
        case register

        var title: String {
            switch self {
            case .signIn:
                "登录"
            case .register:
                "注册"
            }
        }

        var subtitle: String {
            switch self {
            case .signIn:
                "继续你的英语写作训练与 AI 学习计划。"
            case .register:
                "创建账号后，请先完成邮箱验证，再回到这里登录。"
            }
        }
    }

    private var canSubmit: Bool {
        switch authMode {
        case .signIn:
            Validation.isNonEmpty(email) && Validation.isNonEmpty(password)
        case .register:
            Validation.isNonEmpty(nickname) &&
                Validation.isNonEmpty(email) &&
                Validation.isNonEmpty(password) &&
                Validation.isNonEmpty(confirmPassword)
        }
    }

    private var primaryButtonTitle: String {
        switch authMode {
        case .signIn:
            isSubmitting ? "正在登录" : "登录"
        case .register:
            isRegistering ? "正在注册" : "注册"
        }
    }

    private func primaryAction() {
        switch authMode {
        case .signIn:
            beginSignIn()
        case .register:
            beginRegister()
        }
    }

    var body: some View {
        ZStack {
            AuthBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack {
                    Spacer(minLength: 88)

                    signInPanel
                        .frame(maxWidth: 460)

                    Spacer(minLength: 88)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)

            if let captchaChallenge {
                CaptchaOverlayView(
                    challenge: captchaChallenge,
                    sliderX: $sliderX,
                    isVerifying: isVerifyingCaptcha,
                    errorMessage: captchaErrorMessage,
                    onClose: closeCaptcha,
                    onReload: { Task { await loadCaptcha() } },
                    onVerify: { x in Task { await verifyCaptcha(x: x) } }
                )
                .transition(.opacity)
            }

            if let supportSheet {
                AuthSupportSheetView(
                    sheet: supportSheet,
                    onClose: { self.supportSheet = nil }
                )
                .transition(.opacity)
            }
        }
    }

    private var signInPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            header

            VStack(spacing: Spacing.sm) {
                if authMode == .register {
                    fieldLabel("昵称")

                    TextField("昵称", text: $nickname)
                        .textContentType(.nickname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .nickname)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .email
                        }
                        .accessibilityIdentifier("auth.nickname")
                }

                fieldLabel(authMode == .signIn ? "用户名 / 邮箱" : "邮箱")

                TextField(authMode == .signIn ? "用户名 / 邮箱" : "邮箱", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
                    .accessibilityIdentifier("auth.email")

                fieldLabel("密码")

                SecureField("密码", text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        beginSignIn()
                    }
                    .accessibilityIdentifier("auth.password")
                    .padding(.bottom, Spacing.sm)

                if authMode == .register {
                    fieldLabel("确认密码")

                    SecureField("再次输入密码", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit {
                            beginRegister()
                        }
                        .accessibilityIdentifier("auth.confirmPassword")
                        .padding(.bottom, Spacing.sm)
                }

                if let successMessage {
                    Text(successMessage)
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.43, green: 0.86, blue: 1.0))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("auth.success")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.48, blue: 0.50))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("auth.error")
                }

                if let pendingVerificationEmail {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("这个邮箱还没有完成验证。")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.78))

                        HStack(spacing: Spacing.sm) {
                            Button("重发验证邮件") {
                                supportSheet = .verifyEmail(email: pendingVerificationEmail)
                            }

                            Button("我已有验证链接") {
                                supportSheet = .verifyEmail(email: pendingVerificationEmail)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color(red: 0.43, green: 0.86, blue: 1.0))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: primaryAction) {
                    HStack(spacing: Spacing.sm) {
                        if isLoadingCaptcha || isSubmitting || isRegistering {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                        }
                        Text(primaryButtonTitle)
                    }
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GradientButtonStyle())
                .controlSize(.large)
                .disabled(!canSubmit || isLoadingCaptcha || isSubmitting || isRegistering)
                .opacity(canSubmit && !isLoadingCaptcha && !isSubmitting && !isRegistering ? 1 : 0.48)
                .padding(.top, Spacing.sm)
                .accessibilityIdentifier(authMode == .signIn ? "auth.signIn" : "auth.register")
            }
            .textFieldStyle(BrandTextFieldStyle())

            HStack {
                if authMode == .signIn {
                    Button(action: {
                        supportSheet = .forgotPassword(email: email)
                    }) {
                        Text("忘记密码？")
                            .padding(.vertical, 8)
                            .padding(.trailing, 8)
                    }
                }
                Spacer()
                Button(action: toggleAuthMode) {
                    Text(authMode == .signIn ? "去注册" : "已有账号，去登录")
                        .padding(.vertical, 8)
                        .padding(.leading, 8)
                }
                .accessibilityIdentifier(authMode == .signIn ? "auth.showRegister" : "auth.showSignIn")
            }
            .buttonStyle(.borderless)
            .font(Typography.caption.weight(.semibold))
            .foregroundStyle(Color(red: 0.43, green: 0.86, blue: 1.0))
        }
        .padding(34)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.17, blue: 0.28).opacity(0.88),
                            Color(red: 0.10, green: 0.14, blue: 0.25).opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: Color(red: 0.02, green: 0.04, blue: 0.12).opacity(0.52), radius: 34, x: 0, y: 22)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .center, spacing: Spacing.md) {
                BrandLogoMark(size: 60)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Personal English AI")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("日拱一卒，功不唐捐")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.79, blue: 0.32))
                }
            }

            Text(authMode.subtitle)
                .font(Typography.body)
                .foregroundStyle(Color.white.opacity(0.66))
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(Typography.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.82))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func beginSignIn() {
        guard canSubmit, !isLoadingCaptcha, !isSubmitting else {
            return
        }

        focusedField = nil
        Task {
            await loadCaptcha()
        }
    }

    private func beginRegister() {
        guard canSubmit, !isRegistering else {
            return
        }

        focusedField = nil
        errorMessage = nil
        successMessage = nil

        if let validationMessage = validateRegistrationForm() {
            errorMessage = validationMessage
            return
        }

        Task {
            await submitRegister()
        }
    }

    @MainActor
    private func submitRegister() async {
        isRegistering = true
        defer { isRegistering = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await appEnvironment.authService.register(
                email: trimmedEmail,
                password: password,
                nickname: trimmedNickname
            )

            authMode = .signIn
            nickname = ""
            password = ""
            confirmPassword = ""
            successMessage = "注册成功，请先完成邮箱验证，然后使用该邮箱登录。"
            pendingVerificationEmail = trimmedEmail
            errorMessage = nil
            focusedField = .password
        } catch {
            errorMessage = friendlyMessage(for: error, fallback: "注册失败，请检查信息后重试。")
        }
    }

    @MainActor
    private func loadCaptcha() async {
        isLoadingCaptcha = true
        captchaErrorMessage = nil
        errorMessage = nil
        sliderX = 0

        do {
            captchaChallenge = try await appEnvironment.authService.fetchCaptcha()
        } catch {
            errorMessage = friendlyMessage(for: error, fallback: "验证码加载失败，请确认后端服务已启动。")
        }

        isLoadingCaptcha = false
    }

    @MainActor
    private func verifyCaptcha(x: Int) async {
        guard let captchaChallenge, !isVerifyingCaptcha else {
            return
        }

        isVerifyingCaptcha = true
        captchaErrorMessage = nil
        defer { isVerifyingCaptcha = false }

        do {
            let verification = try await appEnvironment.authService.verifyCaptcha(
                captchaId: captchaChallenge.captchaId,
                x: x
            )

            guard verification.verified, let captchaToken = verification.captchaToken else {
                await refreshCaptchaAfterVerificationFailure(message: "验证失败，已刷新验证码。")
                return
            }

            self.captchaChallenge = nil
            sliderX = 0
            try await submitLogin(captchaToken: captchaToken)
        } catch {
            await refreshCaptchaAfterVerificationFailure(
                message: friendlyMessage(for: error, fallback: "验证码校验失败，已刷新验证码。")
            )
        }
    }

    @MainActor
    private func refreshCaptchaAfterVerificationFailure(message: String) async {
        sliderX = 0

        do {
            captchaChallenge = try await appEnvironment.authService.fetchCaptcha()
            captchaErrorMessage = message
        } catch {
            captchaErrorMessage = friendlyMessage(for: error, fallback: "验证码刷新失败，请确认后端服务已启动。")
        }
    }

    @MainActor
    private func submitLogin(captchaToken: String) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response = try await appEnvironment.authService.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                captchaToken: captchaToken
            )

            guard let token = response.token, !token.isEmpty else {
                throw APIError.missingToken
            }

            try appEnvironment.authSession.updateAccessToken(token)
        } catch {
            if case let APIError.requestFailed(statusCode, _) = error, statusCode == 403 {
                pendingVerificationEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                pendingVerificationEmail = nil
            }
            errorMessage = friendlyMessage(for: error, fallback: "登录失败，请检查账号密码。")
            throw error
        }
    }

    private func closeCaptcha() {
        captchaChallenge = nil
        captchaErrorMessage = nil
        sliderX = 0
    }

    private func toggleAuthMode() {
        authMode = authMode == .signIn ? .register : .signIn
        errorMessage = nil
        successMessage = nil
        pendingVerificationEmail = nil
        captchaChallenge = nil
        captchaErrorMessage = nil
        sliderX = 0
        focusedField = authMode == .register ? .nickname : .email
    }

    private func validateRegistrationForm() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedNickname.count <= 50 else {
            return "昵称不能超过 50 个字符。"
        }

        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            return "请输入有效的邮箱地址。"
        }

        guard password.count >= 8 else {
            return "密码长度至少 8 位。"
        }

        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        guard hasLowercase, hasUppercase, hasNumber else {
            return "密码需包含大小写字母和数字。"
        }

        guard password == confirmPassword else {
            return "两次输入的密码不一致。"
        }

        return nil
    }

    private func friendlyMessage(for error: Error, fallback: String) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case let .requestFailed(statusCode, message):
                if let message, !message.isEmpty {
                    return message
                }

                switch statusCode {
                case 400:
                    return "请求信息不完整，请检查输入并完成验证码。"
                case 401:
                    return "账号或密码不正确。"
                case 403:
                    return "账号尚未完成邮箱验证，请先去网页端验证邮箱。"
                default:
                    return "服务器返回错误 \(statusCode)，请稍后重试。"
                }
            case .missingToken:
                return "登录成功但没有收到 token，请检查后端响应。"
            default:
                return fallback
            }
        }

        return fallback
    }
}

private enum AuthSupportSheet: Identifiable {
    case forgotPassword(email: String)
    case verifyEmail(email: String)

    var id: String {
        switch self {
        case .forgotPassword:
            "forgot-password"
        case .verifyEmail:
            "verify-email"
        }
    }
}

private struct AuthSupportSheetView: View {
    @Environment(\.appEnvironment) private var appEnvironment

    let sheet: AuthSupportSheet
    let onClose: () -> Void

    @State private var email: String
    @State private var tokenOrLink = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var message: String?
    @State private var errorMessage: String?
    @State private var didRequestReset = false

    init(sheet: AuthSupportSheet, onClose: @escaping () -> Void) {
        self.sheet = sheet
        self.onClose = onClose
        switch sheet {
        case let .forgotPassword(email), let .verifyEmail(email):
            _email = State(initialValue: email)
        }
    }

    private var title: String {
        switch sheet {
        case .forgotPassword:
            "找回密码"
        case .verifyEmail:
            "邮箱验证"
        }
    }

    private var subtitle: String {
        switch sheet {
        case .forgotPassword:
            "输入注册邮箱后，我们会发送密码重置邮件。收到邮件后，可以把链接或 token 粘贴到这里完成重置。"
        case .verifyEmail:
            "如果没有收到验证邮件，可以重新发送；如果已经有验证链接，也可以粘贴到这里完成验证。"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.56)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)

                            Text(eyebrow)
                                .font(Typography.caption.weight(.semibold))
                                .foregroundStyle(Color(red: 1.0, green: 0.79, blue: 0.32))
                        }

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.semibold))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }
                        .accessibilityLabel("关闭")
                    }

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.white.opacity(0.70))
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))

                    supportSection("邮箱") {
                        TextField("邮箱", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(AuthSupportTextFieldStyle())
                    }

                    switch sheet {
                    case .forgotPassword:
                        forgotPasswordSection
                    case .verifyEmail:
                        verifyEmailSection
                    }

                    if let message {
                        statusMessage(message, color: Color(red: 0.43, green: 0.86, blue: 1.0))
                    }

                    if let errorMessage {
                        statusMessage(errorMessage, color: Color(red: 1.0, green: 0.50, blue: 0.52))
                    }
                }
                .padding(30)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(width: 560, height: 650)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.14, blue: 0.24).opacity(0.98),
                                Color(red: 0.07, green: 0.10, blue: 0.18).opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.44), radius: 34, x: 0, y: 24)
        }
    }

    private var eyebrow: String {
        switch sheet {
        case .forgotPassword:
            "通过邮箱重置密码"
        case .verifyEmail:
            "完成邮箱验证"
        }
    }

    private func actionButton(
        _ title: String,
        isBusy: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isBusy {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right")
                }
                Text(title)
            }
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GradientButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.42 : 1)
    }

    private var forgotPasswordSection: some View {
        Group {
            supportSection("第一步") {
                actionButton(
                    "发送重置邮件",
                    isBusy: isSubmitting && !didRequestReset,
                    isDisabled: !Validation.isNonEmpty(email) || isSubmitting
                ) {
                    Task { await requestPasswordReset() }
                }
            }

            supportSection("第二步") {
                TextField("粘贴重置链接或 token", text: $tokenOrLink, axis: .vertical)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(AuthSupportTextFieldStyle())

                SecureField("新密码", text: $newPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(AuthSupportTextFieldStyle())

                SecureField("确认新密码", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(AuthSupportTextFieldStyle())

                actionButton(
                    "提交新密码",
                    isBusy: isSubmitting && didRequestReset,
                    isDisabled: !canResetPassword || isSubmitting
                ) {
                    Task { await resetPassword() }
                }
            }
        }
    }

    private var verifyEmailSection: some View {
        Group {
            supportSection("验证邮件") {
                actionButton(
                    "重新发送验证邮件",
                    isBusy: isSubmitting,
                    isDisabled: !Validation.isNonEmpty(email) || isSubmitting
                ) {
                    Task { await resendVerification() }
                }
            }

            supportSection("已有验证链接") {
                TextField("粘贴验证链接或 token", text: $tokenOrLink, axis: .vertical)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(AuthSupportTextFieldStyle())

                actionButton(
                    "完成邮箱验证",
                    isBusy: isSubmitting,
                    isDisabled: !Validation.isNonEmpty(tokenOrLink) || isSubmitting
                ) {
                    Task { await verifyEmail() }
                }
            }
        }
    }

    private func supportSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.78))

            VStack(spacing: Spacing.sm) {
                content()
            }
        }
    }

    private func statusMessage(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Typography.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var canResetPassword: Bool {
        Validation.isNonEmpty(tokenOrLink) &&
            Validation.isNonEmpty(newPassword) &&
            Validation.isNonEmpty(confirmPassword)
    }

    @MainActor
    private func requestPasswordReset() async {
        guard validateEmail() else { return }
        isSubmitting = true
        didRequestReset = false
        defer { isSubmitting = false }

        do {
            try await appEnvironment.authService.forgotPassword(email: trimmedEmail)
            message = "如果该邮箱已注册，重置邮件会发送到你的邮箱。"
            errorMessage = nil
            didRequestReset = true
        } catch {
            errorMessage = friendlyMessage(for: error, fallback: "发送重置邮件失败，请稍后重试。")
            message = nil
        }
    }

    @MainActor
    private func resetPassword() async {
        errorMessage = nil
        message = nil

        guard let token = extractedToken else {
            errorMessage = "请粘贴有效的重置链接或 token。"
            return
        }

        if let validationMessage = validatePasswordPair() {
            errorMessage = validationMessage
            return
        }

        isSubmitting = true
        didRequestReset = true
        defer { isSubmitting = false }

        do {
            let status = try await appEnvironment.authService.validateResetToken(token)
            guard status.status == nil || status.status == "valid" else {
                errorMessage = "重置链接已失效，请重新发送重置邮件。"
                return
            }
            try await appEnvironment.authService.resetPassword(token: token, password: newPassword)
            message = "密码已重置，请关闭此窗口后重新登录。"
            tokenOrLink = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            errorMessage = friendlyMessage(for: error, fallback: "密码重置失败，请检查链接是否过期。")
        }
    }

    @MainActor
    private func resendVerification() async {
        guard validateEmail() else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await appEnvironment.authService.resendVerification(email: trimmedEmail)
            message = "验证邮件已发送，请查看邮箱。"
            errorMessage = nil
        } catch {
            errorMessage = friendlyMessage(for: error, fallback: "发送验证邮件失败，请稍后重试。")
            message = nil
        }
    }

    @MainActor
    private func verifyEmail() async {
        guard let token = extractedToken else {
            errorMessage = "请粘贴有效的验证链接或 token。"
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await appEnvironment.authService.verifyEmail(token: token)
            message = "邮箱验证成功，现在可以返回登录。"
            errorMessage = nil
            tokenOrLink = ""
        } catch {
            errorMessage = friendlyMessage(for: error, fallback: "邮箱验证失败，请检查链接是否过期。")
            message = nil
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var extractedToken: String? {
        let raw = tokenOrLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        if let components = URLComponents(string: raw),
           let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
           !token.isEmpty {
            return token
        }

        return raw
    }

    private func validateEmail() -> Bool {
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = "请输入有效的邮箱地址。"
            message = nil
            return false
        }
        return true
    }

    private func validatePasswordPair() -> String? {
        guard newPassword.count >= 8 else {
            return "密码长度至少 8 位。"
        }

        let hasLowercase = newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasUppercase = newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasNumber = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        guard hasLowercase, hasUppercase, hasNumber else {
            return "密码需包含大小写字母和数字。"
        }

        guard newPassword == confirmPassword else {
            return "两次输入的密码不一致。"
        }

        return nil
    }

    private func friendlyMessage(for error: Error, fallback: String) -> String {
        if case let APIError.requestFailed(statusCode, message) = error {
            if let message, !message.isEmpty {
                return message
            }
            return "服务器返回错误 \(statusCode)，请稍后重试。"
        }

        return fallback
    }
}

private struct CaptchaOverlayView: View {
    let challenge: CaptchaChallenge
    @Binding var sliderX: CGFloat
    let isVerifying: Bool
    let errorMessage: String?
    let onClose: () -> Void
    let onReload: () -> Void
    let onVerify: (Int) -> Void

    @State private var dragStartX: CGFloat?

    private let imageWidth: CGFloat = 300
    private let imageHeight: CGFloat = 150
    private let thumbSize: CGFloat = 50
    private let minimumVerificationX: CGFloat = 40

    private var maxX: CGFloat {
        imageWidth - thumbSize
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text("请完成安全验证")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .accessibilityIdentifier("captcha.close")
                }

                ZStack(alignment: .leading) {
                    CaptchaImage(source: challenge.bgImage)
                        .frame(width: imageWidth, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    CaptchaImage(source: challenge.pieceImage)
                        .frame(width: thumbSize, height: imageHeight)
                        .offset(x: sliderX)
                }
                .frame(width: imageWidth, height: imageHeight)

                slider

                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.50, blue: 0.52))
                }

                Button(action: onReload) {
                    Label("换一张", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color(red: 0.43, green: 0.86, blue: 1.0))
                .disabled(isVerifying)
            }
            .padding(20)
            .frame(width: 342)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.11, green: 0.14, blue: 0.22).opacity(0.96))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.42), radius: 26, x: 0, y: 14)
        }
    }

    private var slider: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
                .frame(width: imageWidth, height: 48)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.20, green: 0.75, blue: 1.0).opacity(0.24))
                .frame(width: sliderX + thumbSize / 2, height: 48)

            Text(isVerifying ? "验证中..." : "向右拖动滑块完成验证")
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.68))
                .frame(width: imageWidth, height: 48)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.75, blue: 1.0),
                            Color(red: 0.43, green: 0.42, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: thumbSize, height: 48)
                .overlay {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(x: sliderX)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isVerifying else { return }
                            if dragStartX == nil {
                                dragStartX = sliderX
                            }
                            let nextX = (dragStartX ?? 0) + value.translation.width
                            sliderX = min(max(0, nextX), maxX)
                        }
                        .onEnded { _ in
                            guard !isVerifying else { return }
                            dragStartX = nil
                            guard sliderX >= minimumVerificationX else {
                                sliderX = 0
                                return
                            }
                            onVerify(Int(sliderX.rounded()))
                        }
                )
                .accessibilityIdentifier("captcha.slider")
        }
        .frame(width: imageWidth, height: 48)
    }
}

private struct CaptchaImage: View {
    let source: String

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Color.white.opacity(0.42))
                    }
            }
        }
    }

    private var imageData: Data? {
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let base64Payload = trimmedSource
            .split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
            .last
            .map(String.init) ?? trimmedSource

        let normalizedPayload = base64Payload.filter { !$0.isWhitespace }
        return Data(base64Encoded: normalizedPayload, options: [.ignoreUnknownCharacters])
    }
}

private struct AuthBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.03, green: 0.06, blue: 0.18)

                Image("AuthBrandBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.82)
                    .saturation(1.12)

                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.05, blue: 0.16).opacity(0.22),
                        Color(red: 0.03, green: 0.07, blue: 0.21).opacity(0.42),
                        Color(red: 0.01, green: 0.02, blue: 0.08).opacity(0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.24, green: 0.55, blue: 1.0).opacity(0.22),
                        .clear
                    ],
                    center: .center,
                    startRadius: 60,
                    endRadius: 420
                )
                .blendMode(.screen)

                VStack {
                    Spacer()
                    Text("你的英语写作成长路径")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.34))
                        .padding(.bottom, Spacing.xl)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct BrandLogoMark: View {
    let size: CGFloat

    var body: some View {
        Image("PEAILogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: Color(red: 0.33, green: 0.70, blue: 1.0).opacity(0.22), radius: 14, x: 0, y: 8)
    }
}

private struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.75, blue: 1.0),
                                Color(red: 0.43, green: 0.42, blue: 1.0),
                                Color(red: 0.64, green: 0.49, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: Color(red: 0.23, green: 0.50, blue: 1.0).opacity(configuration.isPressed ? 0.12 : 0.32), radius: 18, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct BrandTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 14)
            .frame(height: 46)
            .foregroundStyle(.white)
            .tint(Color(red: 0.56, green: 0.85, blue: 1.0))
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
    }
}

private struct AuthSupportTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 14)
            .frame(minHeight: 46)
            .foregroundStyle(.white)
            .tint(Color(red: 0.56, green: 0.85, blue: 1.0))
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .previewDevice("iPad Air 11-inch (M4)")
                .previewDisplayName("iPad")

            LoginView()
                .previewDevice("iPad mini (A17 Pro)")
                .previewDisplayName("iPad Mini")
        }
    }
}
