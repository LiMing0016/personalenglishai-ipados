import SwiftUI

struct AppRootView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @State private var selectedTab: AppTab = .dashboard
    @State private var selectedConversationID: AssistantConversation.ID?
    @State private var selectedWritingDraftID: String?

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } content: {
            ContextColumnView(
                selectedTab: selectedTab,
                selectedConversationID: $selectedConversationID,
                selectedWritingDraftID: $selectedWritingDraftID
            )
        } detail: {
            DetailColumnView(
                selectedTab: selectedTab,
                selectedConversationID: selectedConversationID,
                selectedWritingDraftID: selectedWritingDraftID
            )
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct SidebarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        List {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.title, systemImage: tab.systemImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedTab == tab ? Color.accentColor.opacity(0.14) : Color.clear)
                .accessibilityIdentifier("sidebar.\(tab.rawValue)")
            }
        }
        .navigationTitle("Personal English AI")
    }
}

private struct ContextColumnView: View {
    let selectedTab: AppTab
    @Binding var selectedConversationID: AssistantConversation.ID?
    @Binding var selectedWritingDraftID: String?

    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardContextView()
                case .assistant:
                    ConversationListView(selectedConversationID: $selectedConversationID)
                case .writing:
                    WritingHistoryView(selectedDraftID: $selectedWritingDraftID)
                case .profile:
                    ProfileContextView()
                }
            }
        }
    }
}

private struct DetailColumnView: View {
    let selectedTab: AppTab
    let selectedConversationID: AssistantConversation.ID?
    let selectedWritingDraftID: String?

    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .assistant:
                    AssistantRootView(conversationID: selectedConversationID)
                case .writing:
                    WritingRootView(draftID: selectedWritingDraftID)
                case .profile:
                    ProfileView()
                }
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
