import SwiftUI

struct ProfileView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @State private var profile: MeProfile?
    @State private var subscription: SubscriptionStatus?
    private let ability = AbilityProfile.preview
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && profile == nil {
                LoadingView(title: "正在加载我的资料")
            } else if let errorMessage, profile == nil {
                ErrorStateView(title: "资料加载失败", message: errorMessage, retry: {
                    Task { await loadProfile() }
                })
            } else {
                profileContent
            }
        }
        .navigationTitle("我的")
        .toolbar {
            Button(role: .destructive) {
                signOut()
            } label: {
                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .accessibilityIdentifier("profile.signOut")
        }
        .task {
            await loadProfile()
        }
        .accessibilityIdentifier("profile.root")
    }

    private var profileContent: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }
            }

            Section("账户") {
                LabeledContent("邮箱", value: profile?.email ?? "未登录")
                LabeledContent("邮箱验证", value: profile?.emailVerified == true ? "已验证" : "未验证")
                LabeledContent("昵称", value: profile?.nickname ?? "未设置")
                LabeledContent("学习阶段", value: profile?.studyStage ?? "未设置")
                LabeledContent("注册来源", value: registerSourceText(profile?.registerSource))
            }

            Section("能力画像") {
                LabeledContent("语法", value: scoreText(ability.grammarScore))
                LabeledContent("词汇", value: scoreText(ability.vocabularyScore))
                LabeledContent("连贯性", value: scoreText(ability.coherenceScore))
            }

            Section("订阅") {
                LabeledContent("套餐", value: subscription?.planName ?? "暂无数据")
                LabeledContent("已使用额度", value: tokenText(subscription?.tokenUsed))
                LabeledContent("剩余额度", value: tokenText(subscription?.tokenRemaining))
            }
        }
    }

    private func scoreText(_ score: Double?) -> String {
        guard let score else { return "数据不足" }
        return String(format: "%.1f", score)
    }

    @MainActor
    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let profile = appEnvironment.userService.getMyProfile()
            async let subscription = appEnvironment.subscriptionService.getMySubscription()
            self.profile = try await profile
            self.subscription = try await subscription
            errorMessage = nil
        } catch {
            if case let APIError.requestFailed(statusCode, _) = error, statusCode == 401 {
                appEnvironment.authSession.clear()
                return
            }
            errorMessage = friendlyMessage(for: error)
        }
    }

    private func signOut() {
        Task {
            try? await appEnvironment.authService.logout()
            await MainActor.run {
                appEnvironment.authSession.clear()
            }
        }
    }

    private func tokenText(_ value: Int?) -> String {
        guard let value else { return "暂无数据" }
        return "\(value)"
    }

    private func registerSourceText(_ source: String?) -> String {
        switch source {
        case "email":
            return "邮箱"
        case "phone":
            return "手机号"
        case let source? where !source.isEmpty:
            return source
        default:
            return "未知"
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if case let APIError.requestFailed(statusCode, message) = error {
            if let message, !message.isEmpty {
                return message
            }
            return "服务器返回错误 \(statusCode)，请稍后重试。"
        }
        return "请确认后端服务已启动，然后重试。"
    }
}

struct ProfileContextView: View {
    var body: some View {
        List {
            Section("我的") {
                Label("账户", systemImage: "person")
                Label("订阅", systemImage: "creditcard")
                Label("能力画像", systemImage: "chart.xyaxis.line")
            }
        }
        .navigationTitle("我的")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
