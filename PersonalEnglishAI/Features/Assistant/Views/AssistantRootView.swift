import SwiftUI

struct AssistantRootView: View {
    @ObservedObject var store: AssistantStore
    @Binding var selectedConversationID: AssistantConversation.ID?
    @State private var showingConversationDrawer = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                content

                if showingConversationDrawer {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showingConversationDrawer = false
                            }
                        }

                    conversationDrawer(width: drawerWidth(for: proxy.size.width))
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .background(Color.peaiBackground)
        .navigationTitle(currentTitle)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showingConversationDrawer.toggle()
                    }
                } label: {
                    Label("对话", systemImage: "sidebar.leading")
                }
                .accessibilityIdentifier("assistant.toggleConversations")

                Button {
                    Task {
                        if let id = await store.createConversation() {
                            selectedConversationID = id
                        }
                    }
                } label: {
                    Label("新对话", systemImage: "square.and.pencil")
                }
                .accessibilityIdentifier("assistant.newConversationFromChat")
            }
        }
        .task {
            selectedConversationID = await store.loadInitialSelection(currentSelection: selectedConversationID)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let selectedConversationID {
            ChatView(store: store, conversationID: selectedConversationID)
        } else {
            EmptyStateView(
                systemImage: "bubble.left.and.bubble.right",
                title: "开始一次 AI 对话",
                message: "打开对话列表选择历史记录，或新建一次英语练习。"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var currentTitle: String {
        store.conversation(id: selectedConversationID)?.title ?? "AI 助手"
    }

    private func drawerWidth(for containerWidth: CGFloat) -> CGFloat {
        min(380, max(300, containerWidth * 0.34))
    }

    private func conversationDrawer(width: CGFloat) -> some View {
        NavigationStack {
            ConversationListView(
                store: store,
                selectedConversationID: $selectedConversationID
            ) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showingConversationDrawer = false
                }
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(Color.peaiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.16), radius: 24, x: 10, y: 0)
        .padding(.leading, Spacing.md)
        .padding(.vertical, Spacing.md)
    }
}

private struct AssistantRootPreview: View {
    @State private var selectedConversationID: AssistantConversation.ID? = AssistantConversation.samples[0].id

    var body: some View {
        NavigationStack {
            AssistantRootView(
                store: AssistantStore(service: MockAssistantService(), shareBaseURL: URL(string: "https://example.com")!),
                selectedConversationID: $selectedConversationID
            )
        }
    }
}

struct AssistantRootView_Previews: PreviewProvider {
    static var previews: some View {
        AssistantRootPreview()
    }
}
