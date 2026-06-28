import Foundation

struct AssistantAttachmentDraft: Identifiable, Hashable {
    let id = UUID().uuidString
    let name: String
    let mimeType: String
    let data: Data

    var uploadAttachment: AssistantUploadAttachment {
        AssistantUploadAttachment(name: name, mimeType: mimeType, data: data)
    }

    var isImage: Bool {
        mimeType.lowercased().hasPrefix("image/")
    }

    var formattedSize: String {
        let bytes = Double(data.count)
        if bytes >= 1024 * 1024 {
            return String(format: "%.1f MB", bytes / 1024 / 1024)
        }
        return String(format: "%.1f KB", max(bytes / 1024, 0.1))
    }

    var iconName: String {
        if isImage {
            return "photo"
        }
        switch URL(fileURLWithPath: name).pathExtension.lowercased() {
        case "pdf":
            return "doc.richtext"
        case "txt":
            return "doc.text"
        case "doc", "docx":
            return "doc"
        default:
            return "paperclip"
        }
    }
}

struct AssistantRetryDraft: Equatable {
    let conversationID: AssistantConversation.ID
    let text: String
    let attachments: [AssistantUploadAttachment]
    let assistantMode: AssistantMode
    let modelSelection: AssistantModelSelection
}

struct AssistantStatusNotice: Equatable {
    enum Kind: Equatable {
        case backendUnavailable
        case modelUnavailable
        case sessionExpired
        case syncWarning
        case generic
    }

    let kind: Kind
    let title: String
    let message: String
    let actionTitle: String?
}

@MainActor
final class AssistantStore: ObservableObject {
    private static let maxAttachmentCount = 5
    private static let maxAttachmentBytes = 10 * 1024 * 1024
    private static let allowedAttachmentMimeTypes: Set<String> = [
        "image/png",
        "image/jpeg",
        "image/webp",
        "application/pdf",
        "text/plain",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ]
    private static let allowedAttachmentExtensions: Set<String> = [
        "pdf",
        "txt",
        "doc",
        "docx"
    ]

    @Published private(set) var projects: [AssistantProject] = []
    @Published private(set) var conversations: [AssistantConversation] = []
    @Published private(set) var archivedConversations: [AssistantConversation] = []
    @Published private(set) var lastFailedMessage: AssistantRetryDraft?
    @Published var selectedProjectID: Int?
    @Published var showingArchived = false
    @Published var conversationSearchQuery = ""
    @Published var assistantMode: AssistantMode = .default
    @Published var modelSelection: AssistantModelSelection = .openAI
    @Published private(set) var availableModels: [AssistantModelSelection] = AssistantModelSelection.allCases
    @Published var attachments: [AssistantAttachmentDraft] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published private(set) var statusNotice: AssistantStatusNotice?
    @Published var shareURL: URL?
    @Published var lastShareToken: String?

    private let service: AssistantService
    private let shareBaseURL: URL
    private var streamTask: Task<Void, Never>?
    private var activeLoadingMessageID: AssistantMessage.ID?

    init(service: AssistantService, shareBaseURL: URL) {
        self.service = service
        self.shareBaseURL = shareBaseURL
    }

    var visibleConversations: [AssistantConversation] {
        let source = showingArchived ? archivedConversations : conversations
        let normalizedQuery = conversationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return source
            .filter { selectedProjectID == nil || $0.projectId == selectedProjectID }
            .filter { conversation in
                guard !normalizedQuery.isEmpty else {
                    return true
                }
                return conversation.matchesSearchQuery(normalizedQuery)
            }
            .sorted { lhs, rhs in
                if lhs.pinned != rhs.pinned {
                    return lhs.pinned && !rhs.pinned
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    func conversation(id: AssistantConversation.ID?) -> AssistantConversation? {
        guard let id else {
            return nil
        }
        return conversations.first { $0.id == id } ?? archivedConversations.first { $0.id == id }
    }

    func loadInitialSelection(currentSelection: AssistantConversation.ID?) async -> AssistantConversation.ID? {
        await load()
        if let currentSelection, conversation(id: currentSelection) != nil {
            return currentSelection
        }
        return visibleConversations.first?.id
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        statusNotice = nil
        do {
            async let projects = service.listProjects()
            async let active = service.listConversations(archived: false, projectId: nil)
            async let archived = service.listConversations(archived: true, projectId: nil)

            self.projects = try await projects
            conversations = try await active
            archivedConversations = try await archived
        } catch {
            presentError(error, fallback: "AI 助手加载失败")
        }
        await loadModels()
        isLoading = false
    }

    func loadModels() async {
        do {
            let models = try await service.listModels()
                .filter { $0.status?.lowercased() != "unavailable" }
            availableModels = models.isEmpty ? AssistantModelSelection.allCases : models
        } catch {
            availableModels = AssistantModelSelection.allCases
        }

        if let defaultModel = availableModels.first(where: \.isDefault),
           !availableModels.contains(modelSelection) {
            modelSelection = defaultModel
        } else if !availableModels.contains(modelSelection),
                  let firstModel = availableModels.first {
            modelSelection = firstModel
        }
    }

    func createConversation() async -> AssistantConversation.ID? {
        do {
            let conversation = try await service.createConversation(title: nil, projectId: selectedProjectID)
            upsert(conversation)
            showingArchived = false
            return conversation.id
        } catch {
            presentError(error, fallback: "新建对话失败")
            return nil
        }
    }

    func loadConversation(id: AssistantConversation.ID) async {
        do {
            let conversation = try await service.getConversation(id: id)
            upsert(conversation)
        } catch {
            presentError(error, fallback: "对话加载失败")
        }
    }

    func send(text: String, conversationID: AssistantConversation.ID?) async -> AssistantConversation.ID? {
        guard !isSending else {
            return conversationID
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !attachments.isEmpty else {
            return conversationID
        }

        let id: AssistantConversation.ID
        if let conversationID {
            id = conversationID
        } else if let created = await createConversation() {
            id = created
        } else {
            return conversationID
        }

        let uploadAttachments = attachments.map(\.uploadAttachment)
        attachments.removeAll()
        isSending = true
        errorMessage = nil
        statusNotice = nil
        let retryDraft = AssistantRetryDraft(
            conversationID: id,
            text: trimmed,
            attachments: uploadAttachments,
            assistantMode: assistantMode,
            modelSelection: modelSelection
        )

        if uploadAttachments.isEmpty {
            startStreaming(
                text: trimmed,
                conversationID: id,
                assistantMode: assistantMode,
                modelSelection: modelSelection,
                retryDraft: retryDraft
            )
        } else {
            await sendMultipart(
                text: trimmed,
                conversationID: id,
                attachments: uploadAttachments,
                assistantMode: assistantMode,
                modelSelection: modelSelection,
                retryDraft: retryDraft
            )
        }

        return id
    }

    func retryLastFailedMessage() async -> AssistantConversation.ID? {
        guard !isSending else {
            return nil
        }

        guard let retryDraft = lastFailedMessage else {
            return nil
        }

        lastFailedMessage = nil
        isSending = true
        errorMessage = nil
        statusNotice = nil

        if retryDraft.attachments.isEmpty {
            startStreaming(
                text: retryDraft.text,
                conversationID: retryDraft.conversationID,
                assistantMode: retryDraft.assistantMode,
                modelSelection: retryDraft.modelSelection,
                retryDraft: retryDraft
            )
        } else {
            await sendMultipart(
                text: retryDraft.text,
                conversationID: retryDraft.conversationID,
                attachments: retryDraft.attachments,
                assistantMode: retryDraft.assistantMode,
                modelSelection: retryDraft.modelSelection,
                retryDraft: retryDraft
            )
        }

        return retryDraft.conversationID
    }

    func regenerateResponse(
        messageID: AssistantMessage.ID,
        conversationID: AssistantConversation.ID
    ) async -> AssistantConversation.ID? {
        guard !isSending,
              let conversation = conversation(id: conversationID),
              let messageIndex = conversation.messages.firstIndex(where: { $0.id == messageID }),
              conversation.messages[messageIndex].role == .assistant,
              let sourceMessage = conversation.messages[..<messageIndex].last(where: { $0.role == .user })
        else {
            return nil
        }

        return await send(text: sourceMessage.content, conversationID: conversationID)
    }

    func resendEditedUserMessage(
        messageID: AssistantMessage.ID,
        conversationID: AssistantConversation.ID,
        text: String
    ) async -> AssistantConversation.ID? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSending,
              !trimmed.isEmpty,
              let conversation = conversation(id: conversationID),
              conversation.messages.contains(where: { $0.id == messageID && $0.role == .user })
        else {
            return nil
        }

        return await send(text: trimmed, conversationID: conversationID)
    }

    func continueGeneration(conversationID: AssistantConversation.ID) async -> AssistantConversation.ID? {
        guard let conversation = conversation(id: conversationID),
              conversation.messages.contains(where: { $0.role == .assistant })
        else {
            return nil
        }

        return await send(text: "继续生成", conversationID: conversationID)
    }

    func stopStreaming() {
        guard isSending else {
            return
        }

        let loadingMessageID = activeLoadingMessageID
        streamTask?.cancel()
        streamTask = nil
        isSending = false
        activeLoadingMessageID = nil
        if let loadingMessageID {
            replaceLoadingAssistantMessage(id: loadingMessageID, content: "已停止生成。", status: .cancelled)
        }
    }

    func addAttachments(_ drafts: [AssistantAttachmentDraft]) {
        var accepted: [AssistantAttachmentDraft] = []
        for draft in drafts {
            if attachments.count + accepted.count >= Self.maxAttachmentCount {
                errorMessage = "一次最多上传 5 个附件。"
                break
            }
            if let validationError = validationError(for: draft) {
                errorMessage = validationError
                continue
            }
            accepted.append(draft)
        }
        attachments.append(contentsOf: accepted)
    }

    func removeAttachment(id: AssistantAttachmentDraft.ID) {
        attachments.removeAll { $0.id == id }
    }

    func createProject(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        do {
            let project = try await service.createProject(name: trimmed, description: "")
            projects.append(project)
            selectedProjectID = project.id
        } catch {
            presentError(error, fallback: "新建文件夹失败")
        }
    }

    func renameProject(id: Int, name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        do {
            let project = try await service.updateProject(id: id, name: trimmed, description: "")
            projects.replaceOrAppend(project)
        } catch {
            presentError(error, fallback: "重命名文件夹失败")
        }
    }

    func deleteProject(id: Int) async {
        do {
            try await service.deleteProject(id: id)
            projects.removeAll { $0.id == id }
            if selectedProjectID == id {
                selectedProjectID = nil
            }
            await load()
        } catch {
            presentError(error, fallback: "删除文件夹失败")
        }
    }

    func renameConversation(id: AssistantConversation.ID, title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        do {
            let currentSummary = conversation(id: id)?.summary
            upsert(try await service.renameConversation(id: id, title: trimmed, summary: currentSummary))
        } catch {
            presentError(error, fallback: "重命名对话失败")
        }
    }

    func setPinned(conversationID: AssistantConversation.ID, pinned: Bool) async {
        do {
            upsert(try await service.setPinned(conversationID: conversationID, pinned: pinned))
        } catch {
            presentError(error, fallback: "置顶操作失败")
        }
    }

    func archive(conversationID: AssistantConversation.ID) async {
        do {
            upsert(try await service.archiveConversation(id: conversationID))
        } catch {
            presentError(error, fallback: "归档失败")
        }
    }

    func restore(conversationID: AssistantConversation.ID) async {
        do {
            upsert(try await service.restoreConversation(id: conversationID))
        } catch {
            presentError(error, fallback: "恢复失败")
        }
    }

    func move(conversationID: AssistantConversation.ID, projectId: Int?) async {
        do {
            upsert(try await service.moveConversation(id: conversationID, projectId: projectId))
        } catch {
            presentError(error, fallback: "移动对话失败")
        }
    }

    func delete(conversationID: AssistantConversation.ID) async {
        do {
            try await service.deleteConversation(id: conversationID)
            conversations.removeAll { $0.id == conversationID }
            archivedConversations.removeAll { $0.id == conversationID }
        } catch {
            presentError(error, fallback: "删除对话失败")
        }
    }

    func share(conversationID: AssistantConversation.ID) async {
        do {
            let share = try await service.shareConversation(id: conversationID)
            lastShareToken = share.shareToken
            shareURL = URL(string: share.sharePath, relativeTo: shareBaseURL)?.absoluteURL
        } catch {
            presentError(error, fallback: "创建分享失败")
        }
    }

    func revokeLastShare() async {
        guard let lastShareToken else {
            errorMessage = "当前没有可撤销的分享。"
            statusNotice = AssistantStatusNotice(
                kind: .generic,
                title: "没有可撤销的分享",
                message: "当前对话还没有创建过分享链接。",
                actionTitle: nil
            )
            return
        }

        do {
            try await service.revokeShare(token: lastShareToken)
            self.lastShareToken = nil
            shareURL = nil
        } catch {
            presentError(error, fallback: "撤销分享失败")
        }
    }

    func clearError() {
        errorMessage = nil
        statusNotice = nil
    }

    private func startStreaming(
        text: String,
        conversationID: AssistantConversation.ID,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection,
        retryDraft: AssistantRetryDraft
    ) {
        let loadingMessageID = appendOptimisticMessages(text: text, conversationID: conversationID, attachmentCount: 0)
        activeLoadingMessageID = loadingMessageID
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await service.streamAgentMessage(
                    conversationID: conversationID,
                    text: text,
                    studyStage: nil,
                    assistantMode: assistantMode,
                    modelSelection: modelSelection
                ) { event in
                    await MainActor.run {
                        if let delta = event.delta {
                            self.appendStreamingDelta(delta, loadingMessageID: loadingMessageID)
                        }
                        if let content = event.content {
                            self.replaceLoadingAssistantMessage(id: loadingMessageID, content: content, status: .done)
                        }
                    }
                }

                do {
                    let conversation = try await service.getConversation(id: conversationID)
                    await MainActor.run {
                        self.upsert(conversation)
                        self.lastFailedMessage = nil
                        self.isSending = false
                        self.streamTask = nil
                        self.clearActiveLoadingMessage(id: loadingMessageID)
                    }
                } catch {
                    await MainActor.run {
                        if self.isCompletedAssistantMessage(id: loadingMessageID) {
                            self.lastFailedMessage = nil
                            self.errorMessage = "回答已生成，但同步最新对话失败，请稍后下拉刷新。"
                            self.statusNotice = AssistantStatusNotice(
                                kind: .syncWarning,
                                title: "对话同步失败",
                                message: "AI 回答已经显示，本地刷新最新对话详情失败。你可以稍后下拉刷新。",
                                actionTitle: "知道了"
                            )
                        } else {
                            let presentation = self.errorPresentation(for: error, fallback: "AI 助手暂时不可用")
                            self.replaceLoadingAssistantMessage(
                                id: loadingMessageID,
                                content: presentation.message,
                                status: .failed
                            )
                            self.lastFailedMessage = retryDraft
                            self.errorMessage = presentation.message
                            self.statusNotice = presentation.notice
                        }
                        self.isSending = false
                        self.streamTask = nil
                        self.clearActiveLoadingMessage(id: loadingMessageID)
                    }
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isSending = false
                    self.streamTask = nil
                    self.clearActiveLoadingMessage(id: loadingMessageID)
                }
            } catch {
                await MainActor.run {
                    let presentation = self.errorPresentation(for: error, fallback: "AI 助手暂时不可用")
                    self.replaceLoadingAssistantMessage(
                        id: loadingMessageID,
                        content: presentation.message,
                        status: .failed
                    )
                    self.lastFailedMessage = retryDraft
                    self.errorMessage = presentation.message
                    self.statusNotice = presentation.notice
                    self.isSending = false
                    self.streamTask = nil
                    self.clearActiveLoadingMessage(id: loadingMessageID)
                }
            }
        }
    }

    private func sendMultipart(
        text: String,
        conversationID: AssistantConversation.ID,
        attachments: [AssistantUploadAttachment],
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection,
        retryDraft: AssistantRetryDraft
    ) async {
        let loadingMessageID = appendOptimisticMessages(
            text: text,
            conversationID: conversationID,
            attachmentCount: attachments.count
        )
        activeLoadingMessageID = loadingMessageID
        do {
            let conversation = try await service.uploadMessage(
                conversationID: conversationID,
                text: text,
                attachments: attachments,
                studyStage: nil,
                assistantMode: assistantMode,
                modelSelection: modelSelection
            )
            upsert(conversation)
            lastFailedMessage = nil
        } catch {
            let presentation = errorPresentation(for: error, fallback: "附件发送失败")
            replaceLoadingAssistantMessage(id: loadingMessageID, content: presentation.message, status: .failed)
            lastFailedMessage = retryDraft
            errorMessage = presentation.message
            statusNotice = presentation.notice
        }
        isSending = false
        clearActiveLoadingMessage(id: loadingMessageID)
    }

    private func appendOptimisticMessages(
        text: String,
        conversationID: AssistantConversation.ID,
        attachmentCount: Int
    ) -> AssistantMessage.ID {
        var conversation = conversation(id: conversationID) ?? AssistantConversation(
            id: conversationID,
            title: "新对话",
            updatedAt: .now
        )

        let loadingMessageID = "assistant-loading-\(UUID().uuidString)"
        let displayText = text.isEmpty ? "已上传 \(attachmentCount) 个附件" : text
        conversation.messages.append(AssistantMessage(id: UUID().uuidString, role: .user, content: displayText, createdAt: .now))
        conversation.messages.append(AssistantMessage(id: loadingMessageID, role: .assistant, content: "正在思考...", status: .loading, createdAt: .now))
        if conversation.title.isAssistantPlaceholderTitle {
            conversation.title = Self.generatedConversationTitle(from: displayText)
        }
        conversation.summary = displayText
        conversation.updatedAt = .now
        upsert(conversation)
        return loadingMessageID
    }

    private func appendStreamingDelta(_ delta: String, loadingMessageID: AssistantMessage.ID) {
        appendStreamingDelta(delta, loadingMessageID: loadingMessageID, in: &conversations)
        appendStreamingDelta(delta, loadingMessageID: loadingMessageID, in: &archivedConversations)
    }

    private func appendStreamingDelta(
        _ delta: String,
        loadingMessageID: AssistantMessage.ID,
        in conversations: inout [AssistantConversation]
    ) {
        guard let index = conversations.firstIndex(where: { $0.messages.contains(where: { $0.id == loadingMessageID }) }) else {
            return
        }
        guard let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == loadingMessageID }) else {
            return
        }
        if conversations[index].messages[messageIndex].content == "正在思考..." {
            conversations[index].messages[messageIndex].content = ""
        }
        conversations[index].messages[messageIndex].content += delta
    }

    private func replaceLoadingAssistantMessage(
        id loadingMessageID: AssistantMessage.ID,
        content: String,
        status: AssistantMessage.Status
    ) {
        replaceLoadingMessage(in: &conversations, id: loadingMessageID, content: content, status: status)
        replaceLoadingMessage(in: &archivedConversations, id: loadingMessageID, content: content, status: status)
    }

    private func replaceLoadingMessage(
        in conversations: inout [AssistantConversation],
        id loadingMessageID: AssistantMessage.ID,
        content: String,
        status: AssistantMessage.Status
    ) {
        for index in conversations.indices {
            guard let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == loadingMessageID }) else {
                continue
            }
            conversations[index].messages[messageIndex].content = content
            conversations[index].messages[messageIndex].status = status
            conversations[index].messages[messageIndex].createdAt = .now
        }
    }

    private func isCompletedAssistantMessage(id loadingMessageID: AssistantMessage.ID) -> Bool {
        conversations.containsCompletedMessage(id: loadingMessageID) ||
            archivedConversations.containsCompletedMessage(id: loadingMessageID)
    }

    private func clearActiveLoadingMessage(id loadingMessageID: AssistantMessage.ID) {
        if activeLoadingMessageID == loadingMessageID {
            activeLoadingMessageID = nil
        }
    }

    private func upsert(_ conversation: AssistantConversation) {
        var conversation = conversation
        if conversation.title.isAssistantPlaceholderTitle,
           let existingTitle = self.conversation(id: conversation.id)?.title,
           !existingTitle.isAssistantPlaceholderTitle {
            conversation.title = existingTitle
        }

        conversations.removeAll { $0.id == conversation.id }
        archivedConversations.removeAll { $0.id == conversation.id }

        if conversation.archived {
            archivedConversations.replaceOrAppend(conversation)
        } else {
            conversations.replaceOrAppend(conversation)
        }
    }

    private static func generatedConversationTitle(from text: String) -> String {
        let compact = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard !compact.isEmpty else {
            return "新对话"
        }
        return String(compact.prefix(24))
    }

    private func message(for error: Error, fallback: String) -> String {
        errorPresentation(for: error, fallback: fallback).message
    }

    private func presentError(_ error: Error, fallback: String) {
        let presentation = errorPresentation(for: error, fallback: fallback)
        errorMessage = presentation.message
        statusNotice = presentation.notice
    }

    private func errorPresentation(
        for error: Error,
        fallback: String
    ) -> (message: String, notice: AssistantStatusNotice) {
        if error is URLError {
            let message = "无法连接 AI 后端，请确认后端服务已启动。"
            return (
                message,
                AssistantStatusNotice(
                    kind: .backendUnavailable,
                    title: "AI 后端未连接",
                    message: "请确认 Docker 或本地后端服务正在运行，然后重试当前操作。",
                    actionTitle: "重试"
                )
            )
        }

        if case APIError.invalidResponse = error {
            let message = "AI 后端响应异常，请确认后端服务状态。"
            return (
                message,
                AssistantStatusNotice(
                    kind: .backendUnavailable,
                    title: "AI 后端响应异常",
                    message: "后端返回了无法识别的响应。请确认服务已启动并使用正确的接口地址。",
                    actionTitle: "重试"
                )
            )
        }

        if case APIError.requestFailed(let statusCode, let backendMessage) = error {
            let trimmedMessage = backendMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = trimmedMessage?.isEmpty == false ? trimmedMessage! : fallback

            if statusCode == 401 {
                return (
                    message,
                    AssistantStatusNotice(
                        kind: .sessionExpired,
                        title: "登录状态已过期",
                        message: "请重新登录后继续使用 AI 助手。",
                        actionTitle: "重新登录"
                    )
                )
            }

            let looksLikeModelIssue = statusCode == 503 ||
                message.contains("模型") ||
                message.localizedCaseInsensitiveContains("model")

            if looksLikeModelIssue {
                return (
                    message,
                    AssistantStatusNotice(
                        kind: .modelUnavailable,
                        title: message,
                        message: "模型侧暂时没有返回可用结果。你可以稍后重试，或切换其他模型再发送。",
                        actionTitle: "重试"
                    )
                )
            }

            if statusCode >= 500 {
                return (
                    message,
                    AssistantStatusNotice(
                        kind: .backendUnavailable,
                        title: "AI 后端暂时不可用",
                        message: "后端服务返回了异常状态。请稍后重试，或检查本地 Docker 服务日志。",
                        actionTitle: "重试"
                    )
                )
            }

            return (
                message,
                AssistantStatusNotice(
                    kind: .generic,
                    title: "请求失败",
                    message: message,
                    actionTitle: "重试"
                )
            )
        }

        return (
            fallback,
            AssistantStatusNotice(
                kind: .generic,
                title: "AI 助手暂时不可用",
                message: fallback,
                actionTitle: "重试"
            )
        )
    }

    private func validationError(for draft: AssistantAttachmentDraft) -> String? {
        if draft.data.count > Self.maxAttachmentBytes {
            return "单个附件最大支持 10MB。"
        }

        let normalizedMimeType = draft.mimeType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fileExtension = URL(fileURLWithPath: draft.name).pathExtension.lowercased()
        if Self.allowedAttachmentMimeTypes.contains(normalizedMimeType) ||
            Self.allowedAttachmentExtensions.contains(fileExtension) {
            return nil
        }

        return "仅支持 PNG、JPG、WebP、PDF、TXT、DOC、DOCX 附件。"
    }
}

private extension Array where Element == AssistantConversation {
    mutating func replaceOrAppend(_ conversation: AssistantConversation) {
        if let index = firstIndex(where: { $0.id == conversation.id }) {
            self[index] = conversation
        } else {
            append(conversation)
        }
    }

    func containsCompletedMessage(id messageID: AssistantMessage.ID) -> Bool {
        contains { conversation in
            conversation.messages.contains { message in
                message.id == messageID && message.status == .done
            }
        }
    }
}

private extension Array where Element == AssistantProject {
    mutating func replaceOrAppend(_ project: AssistantProject) {
        if let index = firstIndex(where: { $0.id == project.id }) {
            self[index] = project
        } else {
            append(project)
        }
    }
}

private extension AssistantConversation {
    func matchesSearchQuery(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query) ||
            (summary?.localizedCaseInsensitiveContains(query) == true) ||
            messages.contains { $0.content.localizedCaseInsensitiveContains(query) }
    }
}

private extension String {
    var isAssistantPlaceholderTitle: Bool {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty || normalized == "新对话" || normalized.localizedCaseInsensitiveContains("new conversation")
    }
}
