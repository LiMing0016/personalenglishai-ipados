import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let attachments: [AssistantAttachmentDraft]
    let isSending: Bool
    let send: () -> Void
    let attach: () -> Void
    let removeAttachment: (AssistantAttachmentDraft.ID) -> Void
    let stop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(attachments) { attachment in
                            HStack(spacing: 6) {
                                Image(systemName: "paperclip")
                                Text(attachment.name)
                                    .lineLimit(1)
                                Button {
                                    removeAttachment(attachment.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.peaiSurface, in: Capsule())
                        }
                    }
                }
            }

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                Button(action: attach) {
                    Image(systemName: "paperclip")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.bordered)
                .disabled(isSending)
                .accessibilityLabel("添加附件")

                TextField("输入你的英语学习问题", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .disabled(isSending)
                    .accessibilityIdentifier("assistant.input")

                if isSending {
                    Button(action: stop) {
                        Image(systemName: "stop.fill")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("停止生成")
                } else {
                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty)
                    .accessibilityLabel("发送消息")
                    .accessibilityIdentifier("assistant.send")
                }
            }
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
        ChatInputBar(
            text: $text,
            attachments: [],
            isSending: false,
            send: {},
            attach: {},
            removeAttachment: { _ in },
            stop: {}
        )
        .padding()
    }
}
