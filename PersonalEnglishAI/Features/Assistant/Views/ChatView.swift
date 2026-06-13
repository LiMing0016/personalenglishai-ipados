import SwiftUI

struct ChatView: View {
    let conversationID: AssistantConversation.ID
    @State private var messages = AssistantMessage.samples
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
                .padding(Spacing.lg)
            }

            Divider()

            ChatInputBar(text: $draft, send: send)
                .padding(Spacing.md)
                .background(.bar)
        }
        .navigationTitle("对话")
        .accessibilityIdentifier("assistant.chat.\(conversationID)")
    }

    private func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(
            AssistantMessage(
                id: UUID().uuidString,
                role: .user,
                content: trimmed
            )
        )
        draft = ""
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView(conversationID: AssistantConversation.samples[0].id)
        }
    }
}
