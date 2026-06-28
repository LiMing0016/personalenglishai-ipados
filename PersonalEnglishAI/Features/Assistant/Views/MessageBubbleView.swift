import SwiftUI
import UIKit

enum MessageBubbleLayout {
    static func userBubbleMaxWidth(for containerWidth: CGFloat) -> CGFloat {
        min(620, max(240, containerWidth * 0.56))
    }

    static func assistantContentMaxWidth(for containerWidth: CGFloat) -> CGFloat {
        min(860, max(320, containerWidth * 0.72))
    }
}

struct MessageBubbleView: View {
    let message: AssistantMessage
    var onRetry: (() -> Void)?
    var onRegenerate: (() -> Void)?
    var onContinue: (() -> Void)?
    var onAskFollowUp: (() -> Void)?
    var onEditAndResend: (() -> Void)?
    @State private var showsCopiedState = false

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    bubble
                        .frame(
                            maxWidth: MessageBubbleLayout.assistantContentMaxWidth(for: 1200),
                            alignment: .leading
                        )
                    actionBar
                }
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    bubble
                        .frame(
                            maxWidth: MessageBubbleLayout.userBubbleMaxWidth(for: 1200),
                            alignment: .trailing
                        )
                    actionBar
                }
            }
        }
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button("复制", systemImage: "doc.on.doc") {
                copyMessage()
            }

            if message.status == .failed, let onRetry {
                Button("重试", systemImage: "arrow.clockwise") {
                    onRetry()
                }
            }
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if message.status != .loading {
            HStack(spacing: Spacing.xs) {
                MessageActionButton(
                    systemImage: showsCopiedState ? "checkmark" : "doc.on.doc",
                    title: showsCopiedState ? "已复制" : "复制",
                    action: copyMessage
                )

                if message.role == .assistant {
                    if let onRegenerate {
                        MessageActionButton(
                            systemImage: "arrow.clockwise",
                            title: "重新生成",
                            action: onRegenerate
                        )
                    }

                    if let onAskFollowUp {
                        MessageActionButton(
                            systemImage: "bubble.left.and.text.bubble.right",
                            title: "追问",
                            action: onAskFollowUp
                        )
                    }

                    if let onContinue {
                        MessageActionButton(
                            systemImage: "text.line.last.and.arrowtriangle.forward",
                            title: "继续生成",
                            action: onContinue
                        )
                    }
                } else if let onEditAndResend {
                    MessageActionButton(
                        systemImage: "pencil",
                        title: "编辑后重发",
                        action: onEditAndResend
                    )
                }

                if message.status == .failed, let onRetry {
                    MessageActionButton(
                        systemImage: "exclamationmark.arrow.triangle.2.circlepath",
                        title: "重试",
                        action: onRetry
                    )
                }
            }
            .padding(.horizontal, message.role == .assistant ? 0 : Spacing.xs)
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            messageText

            if message.status == .loading {
                ProgressView()
                    .controlSize(.small)
            } else if message.status == .failed {
                HStack(spacing: Spacing.sm) {
                    Label("发送失败", systemImage: "exclamationmark.triangle")
                        .font(.caption)

                    if let onRetry {
                        Button("重试") {
                            onRetry()
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
            } else if message.status == .cancelled {
                Label("已停止", systemImage: "stop.circle")
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
                .fixedSize(horizontal: false, vertical: true)
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

    private func copyMessage() {
        UIPasteboard.general.string = message.content
        showsCopiedState = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                showsCopiedState = false
            }
        }
    }
}

private struct MessageActionButton: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .contentShape(Rectangle())
        .help(title)
        .accessibilityLabel(title)
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
