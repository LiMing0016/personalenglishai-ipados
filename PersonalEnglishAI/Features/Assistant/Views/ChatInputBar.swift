import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let send: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField("输入你的英语学习问题", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .accessibilityIdentifier("assistant.input")

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("发送消息")
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
    @State private var text = "可以帮我解释这个句子吗？"

    var body: some View {
        ChatInputBar(text: $text, send: {})
            .padding()
    }
}
