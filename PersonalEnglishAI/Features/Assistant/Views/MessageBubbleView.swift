import SwiftUI

struct MessageBubbleView: View {
    let message: AssistantMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                    .frame(maxWidth: 820, alignment: .leading)
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            messageText

            if message.status == .loading {
                ProgressView()
                    .controlSize(.small)
            } else if message.status == .failed {
                Label("发送失败", systemImage: "exclamationmark.triangle")
                    .font(.caption)
            }
        }
        .padding(bubbleInsets)
        .foregroundStyle(foregroundColor)
        .background {
            if message.role == .user {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.peaiAccent)
            }
        }
    }

    @ViewBuilder
    private var messageText: some View {
        if message.role == .assistant {
            AssistantRichMessageView(content: message.content)
        } else {
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    private var foregroundColor: Color {
        message.role == .assistant ? Color.primary : Color.white
    }

    private var bubbleInsets: EdgeInsets {
        if message.role == .assistant {
            EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0)
        } else {
            EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md)
        }
    }
}

struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubbleView(message: AssistantMessage.samples[0])
            MessageBubbleView(message: AssistantMessage.samples[1])
        }
        .padding()
    }
}
