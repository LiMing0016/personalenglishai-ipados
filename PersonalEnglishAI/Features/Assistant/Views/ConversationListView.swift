import SwiftUI

struct ConversationListView: View {
    @Binding var selectedConversationID: AssistantConversation.ID?
    private let conversations = AssistantConversation.samples

    var body: some View {
        List {
            ForEach(conversations) { conversation in
                Button {
                    selectedConversationID = conversation.id
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(conversation.title)
                            .font(.headline)
                        Text(conversation.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedConversationID == conversation.id ? Color.accentColor.opacity(0.14) : Color.clear)
                .accessibilityIdentifier("assistant.conversation.\(conversation.id)")
            }
        }
        .navigationTitle("AI 助手")
        .toolbar {
            Button {
                selectedConversationID = conversations.first?.id
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityLabel("新建对话")
            .accessibilityIdentifier("assistant.newConversation")
        }
        .onAppear {
            selectedConversationID = selectedConversationID ?? conversations.first?.id
        }
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListPreview()
    }
}

private struct ConversationListPreview: View {
    @State private var selectedConversationID: AssistantConversation.ID?

    var body: some View {
        NavigationStack {
            ConversationListView(selectedConversationID: $selectedConversationID)
        }
    }
}
