import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @ObservedObject var store: AssistantStore
    let conversationID: AssistantConversation.ID
    @State private var draft = ""
    @State private var showingFileImporter = false

    private var conversation: AssistantConversation? {
        store.conversation(id: conversationID)
    }

    private var messages: [AssistantMessage] {
        conversation?.messages ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            content

            Divider()

            ChatInputBar(
                text: $draft,
                attachments: store.attachments,
                isSending: store.isSending,
                send: send,
                attach: { showingFileImporter = true },
                removeAttachment: { store.removeAttachment(id: $0) },
                stop: store.stopStreaming
            )
            .padding(Spacing.md)
            .background(.bar)
        }
        .navigationTitle(conversation?.title ?? "对话")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Picker("模式", selection: $store.assistantMode) {
                    ForEach(AssistantMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Picker("模型", selection: $store.modelSelection) {
                    ForEach(AssistantModelSelection.allCases) { model in
                        Text("\(model.title) · \(model.subtitle)").tag(model)
                    }
                }
                .frame(width: 210)

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
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil },
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
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(Spacing.lg)
                }
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
}

private struct ShareItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
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
