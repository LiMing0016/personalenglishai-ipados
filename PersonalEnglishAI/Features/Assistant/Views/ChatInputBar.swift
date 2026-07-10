import SwiftUI
import UIKit

struct ChatInputBar: View {
    @Binding var text: String
    let attachments: [AssistantAttachmentDraft]
    @Binding var assistantMode: AssistantMode
    @Binding var modelSelection: AssistantModelSelection
    let availableModels: [AssistantModelSelection]
    let isSending: Bool
    let send: () -> Void
    let attach: () -> Void
    let removeAttachment: (AssistantAttachmentDraft.ID) -> Void
    let stop: () -> Void
    @FocusState private var isInputFocused: Bool
    @StateObject private var voiceInput = VoiceInputController()
    @State private var voiceBaseText = ""

    private var canSend: Bool {
        ChatComposerLayout.canSend(
            text: text,
            attachmentCount: attachments.count,
            isVoiceActive: voiceInput.state.isActive
        )
    }

    private var isComposerActive: Bool {
        ChatComposerLayout.isActive(
            text: text,
            attachmentCount: attachments.count,
            isFocused: isInputFocused
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(attachments) { attachment in
                            AttachmentDraftCard(
                                attachment: attachment,
                                isUploading: isSending,
                                remove: { removeAttachment(attachment.id) }
                            )
                        }
                    }
                }
            }

            composer
        }
        .onChange(of: voiceInput.state.transcript) { _, transcript in
            applyVoiceTranscript(transcript)
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            editor
                .frame(maxWidth: .infinity)

            if voiceInput.state.isActive || voiceInput.state.status == .failed {
                VoiceInputStatusView(
                    state: voiceInput.state,
                    dismiss: voiceInput.resetError
                )
            }

            HStack(spacing: Spacing.sm) {
                attachmentMenu

                modeMenu

                modelMenu

                Spacer(minLength: Spacing.sm)

                voiceButton

                sendButton
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isInputFocused ? Color.peaiAccent.opacity(0.78) : Color(.separator).opacity(0.26), lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(isInputFocused ? 0.10 : 0.06), radius: isInputFocused ? 20 : 12, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.18), value: isComposerActive)
        .animation(.easeInOut(duration: 0.18), value: isInputFocused)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(isSending ? "等待 AI 回复完成" : "输入你的英语学习问题，或粘贴作文让 AI 修改")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 7)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.body)
                .lineSpacing(2)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(
                    maxWidth: .infinity,
                    minHeight: ChatComposerLayout.editorHeight(isActive: isComposerActive),
                    maxHeight: ChatComposerLayout.editorHeight(isActive: isComposerActive)
                )
                .padding(.horizontal, -5)
                .padding(.vertical, 0)
                .focused($isInputFocused)
                .disabled(isSending)
                .accessibilityIdentifier("assistant.input")
        }
        .frame(height: ChatComposerLayout.editorHeight(isActive: isComposerActive), alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isSending {
                isInputFocused = true
            }
        }
    }

    private var attachmentMenu: some View {
        Menu {
            Button("上传图片", systemImage: "photo") {
                attach()
            }
            Button("上传 PDF / 文档", systemImage: "doc.badge.plus") {
                attach()
            }
            Button("上传文本文件", systemImage: "text.document") {
                attach()
            }
        } label: {
            Image(systemName: "plus")
                .font(.headline.weight(.semibold))
                .frame(width: 38, height: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.peaiAccent)
        .background(Color.peaiAccent.opacity(0.10), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.peaiAccent.opacity(0.14), lineWidth: 1)
        }
        .disabled(isSending)
        .accessibilityLabel("添加内容")
    }

    private var modeMenu: some View {
        Menu {
            ForEach(AssistantMode.allCases) { mode in
                Button {
                    assistantMode = mode
                } label: {
                    Label(mode.title, systemImage: assistantMode == mode ? "checkmark" : "circle")
                }
            }
        } label: {
            ComposerControlChip(
                title: assistantMode.title,
                systemImage: "sparkles",
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
        .disabled(isSending)
        .accessibilityLabel("选择学习模式")
    }

    private var modelMenu: some View {
        Menu {
            ForEach(availableModels) { model in
                Button {
                    modelSelection = model
                } label: {
                    Label(modelChipTitle(for: model), systemImage: modelSelection == model ? "checkmark" : "circle")
                }
            }
        } label: {
            ComposerControlChip(
                title: modelChipTitle(for: modelSelection),
                systemImage: "cpu",
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
        .disabled(isSending || availableModels.isEmpty)
        .accessibilityLabel("选择模型")
    }

    private var voiceButton: some View {
        Button {
            handleVoiceButtonTap()
        } label: {
            Image(systemName: voiceInput.state.isRecording ? "stop.fill" : "mic")
                .font(.headline)
                .frame(width: 38, height: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(voiceInput.state.isRecording ? .white : .secondary)
        .background(voiceInput.state.isRecording ? Color.peaiAccent : Color(.systemBackground), in: Capsule())
        .overlay {
            Capsule()
                .stroke(voiceInput.state.isRecording ? Color.clear : Color(.separator).opacity(0.24), lineWidth: 1)
        }
        .disabled(isSending || voiceInput.state.isBusy)
        .accessibilityLabel(voiceInput.state.isRecording ? "停止语音输入" : "开始语音输入")
        .accessibilityHint("将语音识别为文字并填入输入框")
    }

    private var sendButton: some View {
        Group {
            if isSending {
                Button(action: stop) {
                    Image(systemName: "stop.fill")
                        .font(.headline)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.peaiAccent, in: Circle())
                .accessibilityLabel("停止生成")
            } else {
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.title3.weight(.bold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(canSend ? .white : .secondary.opacity(0.45))
                .background(canSend ? Color.peaiAccent : Color(.systemBackground), in: Circle())
                .overlay {
                    Circle()
                        .stroke(canSend ? Color.clear : Color(.separator).opacity(0.20), lineWidth: 1)
                }
                .disabled(!canSend)
                .accessibilityLabel("发送消息")
                .accessibilityIdentifier("assistant.send")
            }
        }
    }

    private func modelChipTitle(for model: AssistantModelSelection) -> String {
        "\(model.title) · \(model.subtitle)"
    }

    private func handleVoiceButtonTap() {
        if voiceInput.state.isRecording || voiceInput.state.isBusy {
            voiceInput.stop()
            return
        }

        voiceBaseText = text
        Task {
            await voiceInput.start()
        }
    }

    private func applyVoiceTranscript(_ transcript: String) {
        guard voiceInput.state.isActive || voiceInput.state.hasTranscript else {
            return
        }

        text = VoiceInputComposerText.merged(base: voiceBaseText, transcript: transcript)
    }
}

private struct ComposerControlChip: View {
    let title: String
    let systemImage: String
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color(.systemBackground), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.separator).opacity(0.24), lineWidth: 1)
        }
    }
}

private struct VoiceInputStatusView: View {
    let state: VoiceInputState
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption.weight(.bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: Spacing.xs)

            if state.status == .failed {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("关闭语音输入提示")
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.78), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch state.status {
        case .requestingPermission:
            "hourglass"
        case .listening:
            "waveform"
        case .stopping:
            "checkmark"
        case .failed:
            "exclamationmark.triangle"
        case .idle:
            "mic"
        }
    }

    private var iconColor: Color {
        state.status == .failed ? .orange : Color.peaiAccent
    }

    private var title: String {
        switch state.status {
        case .requestingPermission:
            "正在请求语音权限"
        case .listening:
            "正在听写"
        case .stopping:
            "正在整理语音文本"
        case .failed:
            "语音输入不可用"
        case .idle:
            "语音输入"
        }
    }

    private var detail: String? {
        if let errorMessage = state.errorMessage {
            return errorMessage
        }

        if state.hasTranscript {
            return state.transcript
        }

        return state.status == .listening ? "说话内容会实时填入输入框。" : nil
    }
}

private struct AttachmentDraftCard: View {
    let attachment: AssistantAttachmentDraft
    let isUploading: Bool
    let remove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            preview

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(attachment.formattedSize)
                    Text("·")
                    Text(isUploading ? "上传中" : "等待上传")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 180, alignment: .leading)

            Button(action: remove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
            .accessibilityLabel("移除附件")
        }
        .padding(6)
        .background(Color.peaiSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var preview: some View {
        if attachment.isImage, let image = UIImage(data: attachment.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: attachment.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.peaiAccent)
                .frame(width: 34, height: 34)
                .background(Color.peaiAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
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
            assistantMode: .constant(.default),
            modelSelection: .constant(.openAI),
            availableModels: AssistantModelSelection.allCases,
            isSending: false,
            send: {},
            attach: {},
            removeAttachment: { _ in },
            stop: {}
        )
        .padding()
    }
}
