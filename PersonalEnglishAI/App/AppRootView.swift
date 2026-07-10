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
    @State private var selectedTab: AppTab = .assistant
    @State private var selectedConversationID: AssistantConversation.ID?
    @State private var selectedWritingDraftID: String?
    @State private var isSidebarCollapsed = false

    init(assistantService: AssistantService, configuration: AppConfiguration) {
        let shareBaseURL = configuration.apiBaseURL.deletingLastPathComponent()
        _assistantStore = StateObject(wrappedValue: AssistantStore(
            service: assistantService,
            shareBaseURL: shareBaseURL
        ))
    }

    var body: some View {
        GeometryReader { proxy in
            let sidebarWidth = AppShellLayout.sidebarWidth(
                containerWidth: proxy.size.width,
                isSidebarCollapsed: isSidebarCollapsed
            )

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    if !isSidebarCollapsed {
                        AssistantWorkspaceSidebarView(
                            store: assistantStore,
                            selectedConversationID: $selectedConversationID,
                            selectedScene: selectedScene,
                            selectScene: selectScene,
                            toggleCollapsed: toggleSidebar,
                            createConversation: createConversation,
                            runQuickTask: runQuickTask
                        )
                        .frame(width: sidebarWidth)

                        Divider()
                    }

                    NavigationStack {
                        AppContentView(
                            selectedConversationID: $selectedConversationID,
                            selectedWritingDraftID: $selectedWritingDraftID,
                            selectedTab: $selectedTab,
                            assistantStore: assistantStore
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if isSidebarCollapsed {
                    sidebarRevealButton
                        .padding(.leading, Spacing.md)
                        .padding(.top, Spacing.md)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: isSidebarCollapsed)
        }
        .background(Color.peaiBackground)
    }

    private var sidebarRevealButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: "sidebar.leading")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("展开侧栏")
        .accessibilityIdentifier("app.sidebar.toggle")
    }

    private var selectedScene: AssistantSidebarScene {
        switch selectedTab {
        case .assistant:
            .assistant
        case .writing:
            .writing
        case .dashboard:
            .archive
        case .profile:
            .profile
        }
    }

    private func selectScene(_ scene: AssistantSidebarScene) {
        selectedTab = scene.destinationTab
    }

    private func toggleSidebar() {
        isSidebarCollapsed.toggle()
    }

    private func createConversation() {
        selectedTab = .assistant
        Task {
            if let id = await assistantStore.createConversation() {
                selectedConversationID = id
            }
        }
    }

    private func runQuickTask(_ task: AssistantSidebarQuickTask) {
        selectedTab = .assistant
        Task {
            let conversationID: AssistantConversation.ID?
            if let selectedConversationID {
                conversationID = selectedConversationID
            } else {
                conversationID = await assistantStore.createConversation()
            }
            if let conversationID {
                selectedConversationID = conversationID
                _ = await assistantStore.send(text: task.prompt, conversationID: conversationID)
            }
        }
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

            ForEach(AppTab.primaryTabs) { tab in
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
                WritingHubView(selectedDraftID: $selectedWritingDraftID)
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
