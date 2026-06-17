import SwiftUI

struct AppRootView: View {
    @Environment(\.appEnvironment) private var appEnvironment

    var body: some View {
        AuthGateView(
            authSession: appEnvironment.authSession,
            appEnvironment: appEnvironment
        )
    }
}

private struct AuthGateView: View {
    @ObservedObject var authSession: AuthSession
    let appEnvironment: AppEnvironment

    var body: some View {
        Group {
            if authSession.isAuthenticated {
                AppShellView(
                    assistantService: appEnvironment.assistantService,
                    configuration: appEnvironment.configuration
                )
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: authSession.isAuthenticated)
    }
}

private struct AppShellView: View {
    @StateObject private var assistantStore: AssistantStore
    @State private var selectedTab: AppTab = .dashboard
    @State private var selectedConversationID: AssistantConversation.ID?
    @State private var selectedWritingDraftID: String?

    init(assistantService: AssistantService, configuration: AppConfiguration) {
        let shareBaseURL = configuration.apiBaseURL.deletingLastPathComponent()
        _assistantStore = StateObject(wrappedValue: AssistantStore(
            service: assistantService,
            shareBaseURL: shareBaseURL
        ))
    }

    var body: some View {
        HStack(spacing: 0) {
            PrimaryRailView(selectedTab: $selectedTab)

            Divider()

            NavigationStack {
                AppContentView(
                    selectedConversationID: $selectedConversationID,
                    selectedWritingDraftID: $selectedWritingDraftID,
                    selectedTab: $selectedTab,
                    assistantStore: assistantStore
                )
            }
        }
        .background(Color.peaiBackground)
    }
}

private struct PrimaryRailView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "book.closed")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.peaiAccent)
                .frame(width: 44, height: 44)
                .background(Color.peaiAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Image(systemName: tab.systemImage)
                        .font(.title2)
                        .foregroundStyle(selectedTab == tab ? Color.peaiAccent : .primary)
                        .frame(width: 48, height: 48)
                        .background(
                            selectedTab == tab ? Color.peaiAccent.opacity(0.14) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityIdentifier("sidebar.\(tab.rawValue)")
            }

            Spacer()
        }
        .padding(.top, Spacing.md)
        .padding(.horizontal, Spacing.sm)
        .frame(width: 72)
        .background(Color.peaiSurface)
    }
}

private struct AppContentView: View {
    @Binding var selectedConversationID: AssistantConversation.ID?
    @Binding var selectedWritingDraftID: String?
    @Binding var selectedTab: AppTab
    @ObservedObject var assistantStore: AssistantStore

    var body: some View {
        Group {
            switch selectedTab {
            case .dashboard:
                DashboardView { tab in
                    selectedTab = tab
                }
            case .assistant:
                AssistantRootView(
                    store: assistantStore,
                    selectedConversationID: $selectedConversationID
                )
            case .writing:
                WritingRootView(draftID: selectedWritingDraftID)
            case .profile:
                ProfileView()
            }
        }
    }
}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
            .environment(\.appEnvironment, AppEnvironment.preview)
    }
}
