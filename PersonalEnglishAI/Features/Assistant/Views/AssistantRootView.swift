import SwiftUI

struct AssistantRootView: View {
    @ObservedObject var store: AssistantStore
    @Binding var selectedConversationID: AssistantConversation.ID?

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.peaiBackground)
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
