import SwiftUI

struct AssistantRootView: View {
    let conversationID: AssistantConversation.ID?

    var body: some View {
        if let conversationID {
            ChatView(conversationID: conversationID)
        } else {
            EmptyStateView(
                systemImage: "bubble.left.and.bubble.right",
                title: "Select a conversation",
                message: "Choose a conversation from the list or create a new one."
            )
            .navigationTitle("Assistant")
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
