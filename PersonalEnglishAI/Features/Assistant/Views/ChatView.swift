import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @ObservedObject var store: AssistantStore
    let conversationID: AssistantConversation.ID
    @State private var draft = ""
    @State private var showingFileImporter = false
    @State private var editingUserMessage: EditableUserMessage?

    private var conversation: AssistantConversation? {
        store.conversation(id: conversationID)
    }

    private var messages: [AssistantMessage] {
        conversation?.messages ?? []
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Divider()

                ChatInputBar(
                    text: $draft,
                    attachments: store.attachments,
                    assistantMode: $store.assistantMode,
                    modelSelection: $store.modelSelection,
                    availableModels: store.availableModels,
                    isSending: store.isSending,
                    send: send,
                    attach: { showingFileImporter = true },
                    removeAttachment: { store.removeAttachment(id: $0) },
                    stop: store.stopStreaming
                )
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(.bar)
            }
            .overlay(alignment: .top) {
                if let notice = store.statusNotice {
                    AssistantStatusBanner(
                        notice: notice,
                        action: { handleStatusNoticeAction(notice) },
                        dismiss: store.clearError
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: store.statusNotice)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("创建分享链接", systemImage: "square.and.arrow.up") {
                        Task { await store.share(conversationID: conversationID) }
                    }
                    Button("撤销最近分享", systemImage: "link.badge.minus") {
                        Task { await store.revokeLastShare() }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task(id: conversationID) {
            await store.loadConversation(id: conversationID)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.image, .pdf, .plainText, .text, .data],
            allowsMultipleSelection: true
        ) { result in
            handleImportedFiles(result)
        }
        .sheet(item: Binding(
            get: { store.shareURL.map(ShareItem.init(url:)) },
            set: { if $0 == nil { store.shareURL = nil } }
        )) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(item: $editingUserMessage) { editableMessage in
            EditUserMessageSheet(editableMessage: editableMessage) { editedText in
                Task {
                    _ = await store.resendEditedUserMessage(
                        messageID: editableMessage.id,
                        conversationID: editableMessage.conversationID,
                        text: editedText
                    )
                }
            }
        }
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil && store.statusNotice == nil },
            set: { if !$0 { store.clearError() } }
        )) {
            Button("知道了", role: .cancel) { store.clearError() }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .accessibilityIdentifier("assistant.chat.\(conversationID)")
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && messages.isEmpty {
            LoadingView(title: "正在加载对话")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if messages.isEmpty {
            EmptyStateView(
                systemImage: "sparkles",
                title: "开始一次英语练习",
                message: "可以问语法、写作、口语、词汇，也可以上传文件。"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message) {
                                Task { _ = await store.retryLastFailedMessage() }
                            } onRegenerate: {
                                Task {
                                    _ = await store.regenerateResponse(
                                        messageID: message.id,
                                        conversationID: conversationID
                                    )
                                }
                            } onContinue: {
                                Task {
                                    _ = await store.continueGeneration(conversationID: conversationID)
                                }
                            } onAskFollowUp: {
                                draft = followUpDraft(for: message)
                            } onEditAndResend: {
                                editingUserMessage = EditableUserMessage(
                                    message: message,
                                    conversationID: conversationID
                                )
                            }
                            .id(message.id)
                        }
                    }
                    .padding(Spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: messages.last?.content) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    private func send() {
        let text = draft
        draft = ""
        Task {
            _ = await store.send(text: text, conversationID: conversationID)
        }
    }

    private func handleStatusNoticeAction(_ notice: AssistantStatusNotice) {
        switch notice.kind {
        case .modelUnavailable:
            Task {
                if store.lastFailedMessage != nil {
                    _ = await store.retryLastFailedMessage()
                } else {
                    await store.loadConversation(id: conversationID)
                }
            }
        case .backendUnavailable, .generic:
            Task {
                await store.loadConversation(id: conversationID)
            }
        case .syncWarning:
            store.clearError()
        case .sessionExpired:
            store.clearError()
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastID = messages.last?.id else {
            return
        }
        withAnimation(.easeOut(duration: 0.18)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    private func handleImportedFiles(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            let drafts = try urls.map { url in
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: url)
                return AssistantAttachmentDraft(
                    name: url.lastPathComponent,
                    mimeType: mimeType(for: url),
                    data: data
                )
            }
            store.addAttachments(drafts)
        } catch {
            store.errorMessage = "附件读取失败"
        }
    }

    private func mimeType(for url: URL) -> String {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return "application/octet-stream"
        }
        return type.preferredMIMEType ?? "application/octet-stream"
    }

    private func followUpDraft(for message: AssistantMessage) -> String {
        guard message.role == .assistant else {
            return draft
        }
        return "关于这条回答，我想继续问："
    }
}

private struct ShareItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct AssistantStatusBanner: View {
    let notice: AssistantStatusNotice
    let action: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(notice.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(notice.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.sm)

            if let actionTitle = notice.actionTitle {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("关闭提示")
        }
        .padding(Spacing.md)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.separator).opacity(0.24), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch notice.kind {
        case .backendUnavailable, .sessionExpired:
            return .orange
        case .modelUnavailable:
            return .purple
        case .syncWarning:
            return .blue
        case .generic:
            return .secondary
        }
    }

    private var iconName: String {
        switch notice.kind {
        case .backendUnavailable:
            return "server.rack"
        case .modelUnavailable:
            return "sparkles"
        case .sessionExpired:
            return "lock.rotation"
        case .syncWarning:
            return "arrow.triangle.2.circlepath"
        case .generic:
            return "exclamationmark.triangle"
        }
    }
}

private struct EditableUserMessage: Identifiable {
    let id: AssistantMessage.ID
    let conversationID: AssistantConversation.ID
    let content: String

    init(message: AssistantMessage, conversationID: AssistantConversation.ID) {
        id = message.id
        self.conversationID = conversationID
        content = message.content
    }
}

private struct EditUserMessageSheet: View {
    @Environment(\.dismiss) private var dismiss
    let editableMessage: EditableUserMessage
    let resend: (String) -> Void
    @State private var editedText: String

    private var canResend: Bool {
        !editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(editableMessage: EditableUserMessage, resend: @escaping (String) -> Void) {
        self.editableMessage = editableMessage
        self.resend = resend
        _editedText = State(initialValue: editableMessage.content)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TextEditor(text: $editedText)
                    .font(.body)
                    .lineSpacing(2)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.sm)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    }
                    .accessibilityIdentifier("assistant.editMessage.input")

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("编辑后重发")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("重发") {
                        resend(editedText)
                        dismiss()
                    }
                    .disabled(!canResend)
                }
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView(
                store: AssistantStore(service: MockAssistantService(), shareBaseURL: URL(string: "https://example.com")!),
                conversationID: AssistantConversation.samples[0].id
            )
        }
    }
}
