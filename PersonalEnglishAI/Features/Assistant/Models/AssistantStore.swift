import Foundation

struct AssistantAttachmentDraft: Identifiable, Hashable {
    let id = UUID().uuidString
    let name: String
    let mimeType: String
    let data: Data

    var uploadAttachment: AssistantUploadAttachment {
        AssistantUploadAttachment(name: name, mimeType: mimeType, data: data)
    }
}

@MainActor
final class AssistantStore: ObservableObject {
    @Published private(set) var projects: [AssistantProject] = []
    @Published private(set) var conversations: [AssistantConversation] = []
    @Published private(set) var archivedConversations: [AssistantConversation] = []
    @Published var selectedProjectID: Int?
    @Published var showingArchived = false
    @Published var assistantMode: AssistantMode = .default
    @Published var modelSelection: AssistantModelSelection = .openAI
    @Published var attachments: [AssistantAttachmentDraft] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var shareURL: URL?
    @Published var lastShareToken: String?

    private let service: AssistantService
    private let shareBaseURL: URL
    private var streamTask: Task<Void, Never>?

    init(service: AssistantService, shareBaseURL: URL) {
        self.service = service
        self.shareBaseURL = shareBaseURL
    }

    var visibleConversations: [AssistantConversation] {
        let source = showingArchived ? archivedConversations : conversations
        return source
            .filter { selectedProjectID == nil || $0.projectId == selectedProjectID }
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
        do {
            async let projects = service.listProjects()
            async let active = service.listConversations(archived: false, projectId: nil)
            async let archived = service.listConversations(archived: true, projectId: nil)

            self.projects = try await projects
            conversations = try await active
            archivedConversations = try await archived
        } catch {
            errorMessage = message(for: error, fallback: "AI 助手加载失败")
        }
        isLoading = false
    }

    func createConversation() async -> AssistantConversation.ID? {
        do {
            let conversation = try await service.createConversation(title: nil, projectId: selectedProjectID)
            upsert(conversation)
            showingArchived = false
            return conversation.id
        } catch {
            errorMessage = message(for: error, fallback: "新建对话失败")
            return nil
        }
    }

    func loadConversation(id: AssistantConversation.ID) async {
        do {
            let conversation = try await service.getConversation(id: id)
            upsert(conversation)
        } catch {
            errorMessage = message(for: error, fallback: "对话加载失败")
        }
    }

    func send(text: String, conversationID: AssistantConversation.ID?) async -> AssistantConversation.ID? {
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

        if uploadAttachments.isEmpty {
            startStreaming(text: trimmed, conversationID: id)
        } else {
            await sendMultipart(text: trimmed, conversationID: id, attachments: uploadAttachments)
        }

        return id
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isSending = false
        replaceLoadingAssistantMessage(content: "已停止生成。", status: .failed)
    }

    func addAttachments(_ drafts: [AssistantAttachmentDraft]) {
        let remainingSlots = max(0, 5 - attachments.count)
        attachments.append(contentsOf: drafts.prefix(remainingSlots))
        if drafts.count > remainingSlots {
            errorMessage = "一次最多上传 5 个附件。"
        }
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
            errorMessage = message(for: error, fallback: "新建文件夹失败")
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
            errorMessage = message(for: error, fallback: "重命名文件夹失败")
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
            errorMessage = message(for: error, fallback: "删除文件夹失败")
        }
    }

    func setPinned(conversationID: AssistantConversation.ID, pinned: Bool) async {
        do {
            upsert(try await service.setPinned(conversationID: conversationID, pinned: pinned))
        } catch {
            errorMessage = message(for: error, fallback: "置顶操作失败")
        }
    }

    func archive(conversationID: AssistantConversation.ID) async {
        do {
            upsert(try await service.archiveConversation(id: conversationID))
        } catch {
            errorMessage = message(for: error, fallback: "归档失败")
        }
    }

    func restore(conversationID: AssistantConversation.ID) async {
        do {
            upsert(try await service.restoreConversation(id: conversationID))
        } catch {
            errorMessage = message(for: error, fallback: "恢复失败")
        }
    }

    func move(conversationID: AssistantConversation.ID, projectId: Int?) async {
        do {
            upsert(try await service.moveConversation(id: conversationID, projectId: projectId))
        } catch {
            errorMessage = message(for: error, fallback: "移动对话失败")
        }
    }

    func delete(conversationID: AssistantConversation.ID) async {
        do {
            try await service.deleteConversation(id: conversationID)
            conversations.removeAll { $0.id == conversationID }
            archivedConversations.removeAll { $0.id == conversationID }
        } catch {
            errorMessage = message(for: error, fallback: "删除对话失败")
        }
    }

    func share(conversationID: AssistantConversation.ID) async {
        do {
            let share = try await service.shareConversation(id: conversationID)
            lastShareToken = share.shareToken
            shareURL = URL(string: share.sharePath, relativeTo: shareBaseURL)?.absoluteURL
        } catch {
            errorMessage = message(for: error, fallback: "创建分享失败")
        }
    }

    func revokeLastShare() async {
        guard let lastShareToken else {
            errorMessage = "当前没有可撤销的分享。"
            return
        }

        do {
            try await service.revokeShare(token: lastShareToken)
            self.lastShareToken = nil
            shareURL = nil
        } catch {
            errorMessage = message(for: error, fallback: "撤销分享失败")
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func startStreaming(text: String, conversationID: AssistantConversation.ID) {
        appendOptimisticMessages(text: text, conversationID: conversationID, attachmentCount: 0)
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
                            self.appendStreamingDelta(delta)
                        }
                        if let content = event.content {
                            self.replaceLoadingAssistantMessage(content: content, status: .done)
                        }
                    }
                }

                let conversation = try await service.getConversation(id: conversationID)
                await MainActor.run {
                    self.upsert(conversation)
                    self.isSending = false
                    self.streamTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isSending = false
                    self.streamTask = nil
                }
            } catch {
                await MainActor.run {
                    self.replaceLoadingAssistantMessage(content: self.message(for: error, fallback: "AI 助手暂时不可用"), status: .failed)
                    self.errorMessage = self.message(for: error, fallback: "AI 助手暂时不可用")
                    self.isSending = false
                    self.streamTask = nil
                }
            }
        }
    }

    private func sendMultipart(
        text: String,
        conversationID: AssistantConversation.ID,
        attachments: [AssistantUploadAttachment]
    ) async {
        appendOptimisticMessages(text: text, conversationID: conversationID, attachmentCount: attachments.count)
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
        } catch {
            replaceLoadingAssistantMessage(content: message(for: error, fallback: "附件发送失败"), status: .failed)
            errorMessage = message(for: error, fallback: "附件发送失败")
        }
        isSending = false
    }

    private func appendOptimisticMessages(
        text: String,
        conversationID: AssistantConversation.ID,
        attachmentCount: Int
    ) {
        var conversation = conversation(id: conversationID) ?? AssistantConversation(
            id: conversationID,
            title: "新对话",
            updatedAt: .now
        )

        let displayText = text.isEmpty ? "已上传 \(attachmentCount) 个附件" : text
        conversation.messages.append(AssistantMessage(id: UUID().uuidString, role: .user, content: displayText, createdAt: .now))
        conversation.messages.append(AssistantMessage(id: "assistant-loading", role: .assistant, content: "正在思考...", status: .loading, createdAt: .now))
        conversation.summary = displayText
        conversation.updatedAt = .now
        upsert(conversation)
    }

    private func appendStreamingDelta(_ delta: String) {
        guard let index = conversations.firstIndex(where: { $0.messages.contains(where: { $0.id == "assistant-loading" }) }) else {
            return
        }
        guard let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == "assistant-loading" }) else {
            return
        }
        if conversations[index].messages[messageIndex].content == "正在思考..." {
            conversations[index].messages[messageIndex].content = ""
        }
        conversations[index].messages[messageIndex].content += delta
    }

    private func replaceLoadingAssistantMessage(content: String, status: AssistantMessage.Status) {
        replaceLoadingMessage(in: &conversations, content: content, status: status)
        replaceLoadingMessage(in: &archivedConversations, content: content, status: status)
    }

    private func replaceLoadingMessage(
        in conversations: inout [AssistantConversation],
        content: String,
        status: AssistantMessage.Status
    ) {
        for index in conversations.indices {
            guard let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == "assistant-loading" }) else {
                continue
            }
            conversations[index].messages[messageIndex].content = content
            conversations[index].messages[messageIndex].status = status
            conversations[index].messages[messageIndex].createdAt = .now
        }
    }

    private func upsert(_ conversation: AssistantConversation) {
        conversations.removeAll { $0.id == conversation.id }
        archivedConversations.removeAll { $0.id == conversation.id }

        if conversation.archived {
            archivedConversations.replaceOrAppend(conversation)
        } else {
            conversations.replaceOrAppend(conversation)
        }
    }

    private func message(for error: Error, fallback: String) -> String {
        if case APIError.requestFailed(_, let message) = error, let message, !message.isEmpty {
            return message
        }
        return fallback
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
