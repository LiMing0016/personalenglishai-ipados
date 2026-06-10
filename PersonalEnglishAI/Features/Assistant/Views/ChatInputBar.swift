import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let send: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField("Ask about English learning", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .accessibilityIdentifier("assistant.input")

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
            .accessibilityIdentifier("assistant.send")
        }
    }
}

struct ChatInputBar_Previews: PreviewProvider {
    static var previews: some View {
        ChatInputBarPreview()
    }
}

private struct ChatInputBarPreview: View {
    @State private var text = "Can you explain this sentence?"

    var body: some View {
        ChatInputBar(text: $text, send: {})
            .padding()
    }
}
