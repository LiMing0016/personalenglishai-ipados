import SwiftUI

struct AssistantRootView: View {
    let conversationID: AssistantConversation.ID?

    var body: some View {
        if let conversationID {
            ChatView(conversationID: conversationID)
        } else {
            EmptyStateView(
                systemImage: "bubble.left.and.bubble.right",
                title: "选择一个对话",
                message: "从左侧列表选择一个对话，或新建一次练习。"
            )
            .navigationTitle("AI 助手")
        }
    }
}

struct AssistantRootView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AssistantRootView(conversationID: AssistantConversation.samples[0].id)
        }
    }
}
