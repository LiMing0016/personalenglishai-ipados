import Foundation
import XCTest
@testable import PersonalEnglishAI

@MainActor
final class AssistantStoreTests: XCTestCase {
    func testFailedStreamingMessageStoresRetryDraftAndRetryClearsIt() async {
        let service = StoreTestAssistantService()
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        let conversationID = await store.createConversation()
        XCTAssertEqual(conversationID, "conv-store")

        _ = await store.send(text: "帮我练习定语从句", conversationID: conversationID)
        await waitUntil { !store.isSending }

        XCTAssertEqual(store.lastFailedMessage?.text, "帮我练习定语从句")
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.status, .failed)

        _ = await store.retryLastFailedMessage()
        await waitUntil { !store.isSending }

        XCTAssertNil(store.lastFailedMessage)
        XCTAssertEqual(service.streamRequests.count, 2)
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.content, "重试成功。")
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.status, .done)
    }

    func testAttachmentValidationRejectsUnsupportedOversizedAndExcessFiles() {
        let store = AssistantStore(service: StoreTestAssistantService(), shareBaseURL: URL(string: "https://example.com")!)

        store.addAttachments([
            AssistantAttachmentDraft(name: "script.sh", mimeType: "text/x-shellscript", data: Data("echo hi".utf8))
        ])
        XCTAssertEqual(store.attachments.count, 0)
        XCTAssertEqual(store.errorMessage, "仅支持 PNG、JPG、WebP、PDF、TXT、DOC、DOCX 附件。")

        store.clearError()
        store.addAttachments([
            AssistantAttachmentDraft(name: "large.pdf", mimeType: "application/pdf", data: Data(repeating: 0, count: 10 * 1024 * 1024 + 1))
        ])
        XCTAssertEqual(store.attachments.count, 0)
        XCTAssertEqual(store.errorMessage, "单个附件最大支持 10MB。")

        store.clearError()
        store.addAttachments((1...6).map { index in
            AssistantAttachmentDraft(name: "note-\(index).txt", mimeType: "text/plain", data: Data("hello".utf8))
        })
        XCTAssertEqual(store.attachments.count, 5)
        XCTAssertEqual(store.errorMessage, "一次最多上传 5 个附件。")
    }

    func testRenameConversationUpdatesLocalConversation() async {
        let service = StoreTestAssistantService()
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        _ = await store.createConversation()
        await store.renameConversation(id: "conv-store", title: "作文修改")

        XCTAssertEqual(service.renamedTitle, "作文修改")
        XCTAssertEqual(store.conversation(id: "conv-store")?.title, "作文修改")
    }

    func testRegenerateResponseResendsNearestPreviousUserMessage() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        service.conversations = [
            AssistantConversation(
                id: "conv-store",
                title: "翻译练习",
                updatedAt: .now,
                messages: [
                    AssistantMessage(id: "user-1", role: .user, content: "把这句话翻译成英文", createdAt: .now),
                    AssistantMessage(id: "assistant-1", role: .assistant, content: "Please translate this sentence into English.", createdAt: .now)
                ]
            )
        ]
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()
        _ = await store.regenerateResponse(messageID: "assistant-1", conversationID: "conv-store")
        await waitUntil { !store.isSending }

        XCTAssertEqual(service.streamRequests, ["把这句话翻译成英文"])
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.content, "重试成功。")
    }

    func testResendEditedUserMessageSendsEditedText() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        service.conversations = [
            AssistantConversation(
                id: "conv-store",
                title: "追问",
                updatedAt: .now,
                messages: [
                    AssistantMessage(id: "user-1", role: .user, content: "原始问题", createdAt: .now),
                    AssistantMessage(id: "assistant-1", role: .assistant, content: "原始回答", createdAt: .now)
                ]
            )
        ]
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()
        _ = await store.resendEditedUserMessage(
            messageID: "user-1",
            conversationID: "conv-store",
            text: "编辑后的问题"
        )
        await waitUntil { !store.isSending }

        XCTAssertEqual(service.streamRequests, ["编辑后的问题"])
        XCTAssertEqual(store.conversation(id: "conv-store")?.summary, "编辑后的问题")
    }

    func testSendWhileStreamingIgnoresDuplicateSubmission() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        service.streamDelayNanoseconds = 250_000_000
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        let conversationID = await store.createConversation()
        _ = await store.send(text: "第一条问题", conversationID: conversationID)
        await waitUntil { service.streamRequests == ["第一条问题"] }

        _ = await store.send(text: "第二条问题", conversationID: conversationID)

        XCTAssertEqual(service.streamRequests, ["第一条问题"])
        XCTAssertEqual(
            store.conversation(id: "conv-store")?.messages.filter { $0.role == .user }.map(\.content),
            ["第一条问题"]
        )

        await waitUntil { !store.isSending }

        XCTAssertEqual(service.streamRequests, ["第一条问题"])
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.content, "重试成功。")
    }

    func testStreamingCompletionKeepsAnswerWhenConversationRefreshFails() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        let conversationID = await store.createConversation()
        service.failingGetConversationIDs = ["conv-store"]

        _ = await store.send(text: "请讲解一般过去时", conversationID: conversationID)
        await waitUntil { !store.isSending }

        let lastMessage = store.conversation(id: "conv-store")?.messages.last
        XCTAssertEqual(lastMessage?.role, .assistant)
        XCTAssertEqual(lastMessage?.content, "重试成功。")
        XCTAssertEqual(lastMessage?.status, .done)
        XCTAssertNil(store.lastFailedMessage)
        XCTAssertEqual(store.errorMessage, "回答已生成，但同步最新对话失败，请稍后下拉刷新。")
    }

    func testStopStreamingCancelsLoadingMessageAndRestoresSendingState() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        service.streamDelayNanoseconds = 500_000_000
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        let conversationID = await store.createConversation()
        _ = await store.send(text: "请生成一篇短文", conversationID: conversationID)
        await waitUntil { store.isSending }

        store.stopStreaming()

        XCTAssertFalse(store.isSending)
        XCTAssertNil(store.lastFailedMessage)
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.content, "已停止生成。")
        XCTAssertEqual(store.conversation(id: "conv-store")?.messages.last?.status, .cancelled)
    }

    func testLoadBackendConnectionFailureShowsRecoveryNotice() async {
        let service = StoreTestAssistantService()
        service.listProjectsError = URLError(.cannotConnectToHost)
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()

        XCTAssertEqual(store.errorMessage, "无法连接 AI 后端，请确认后端服务已启动。")
        XCTAssertEqual(store.statusNotice?.kind, .backendUnavailable)
        XCTAssertEqual(store.statusNotice?.title, "AI 后端未连接")
        XCTAssertEqual(store.statusNotice?.actionTitle, "重试")

        store.clearError()

        XCTAssertNil(store.errorMessage)
        XCTAssertNil(store.statusNotice)
    }

    func testStreamingModelFailureShowsModelNoticeAndRetryDraft() async {
        let service = StoreTestAssistantService()
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        let conversationID = await store.createConversation()
        _ = await store.send(text: "讲解 government", conversationID: conversationID)
        await waitUntil { !store.isSending }

        XCTAssertEqual(store.errorMessage, "模型服务暂时不可用")
        XCTAssertEqual(store.statusNotice?.kind, .modelUnavailable)
        XCTAssertEqual(store.statusNotice?.title, "模型服务暂时不可用")
        XCTAssertEqual(store.statusNotice?.actionTitle, "重试")
        XCTAssertEqual(store.lastFailedMessage?.text, "讲解 government")
    }

    func testMessageBubbleLayoutCapsUserBubbleWidthForIPadLandscape() {
        XCTAssertEqual(MessageBubbleLayout.userBubbleMaxWidth(for: 1200), 620)
        XCTAssertEqual(MessageBubbleLayout.userBubbleMaxWidth(for: 744), 416.64, accuracy: 0.01)
        XCTAssertEqual(MessageBubbleLayout.userBubbleMaxWidth(for: 390), 240)
        XCTAssertEqual(MessageBubbleLayout.assistantContentMaxWidth(for: 1200), 860)
        XCTAssertEqual(MessageBubbleLayout.assistantContentMaxWidth(for: 390), 320)
    }

    func testLoadModelsUsesBackendDefaultSelection() async {
        let service = StoreTestAssistantService()
        service.models = [
            AssistantModelSelection(
                title: "GPT-5.4 Mini",
                subtitle: "gpt-5.4-mini",
                provider: "openai",
                model: "gpt-5.4-mini",
                isDefault: false,
                supportsStreaming: true,
                supportsAttachments: true,
                supportsVision: true,
                maxInputTokens: 128000,
                status: "available"
            ),
            AssistantModelSelection(
                title: "Qwen Plus",
                subtitle: "qwen-plus",
                provider: "qwen",
                model: "qwen-plus",
                isDefault: true,
                supportsStreaming: true,
                supportsAttachments: true,
                supportsVision: false,
                maxInputTokens: 32000,
                status: "available"
            )
        ]
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()

        XCTAssertEqual(store.availableModels.map(\.title), ["GPT-5.4 Mini", "Qwen Plus"])
        XCTAssertEqual(store.modelSelection, service.models[1])
    }

    func testLoadModelsFallsBackToLocalDefaultsWhenEndpointFails() async {
        let service = StoreTestAssistantService()
        service.listModelsError = APIError.requestFailed(statusCode: 503, message: "models unavailable")
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()

        XCTAssertEqual(store.availableModels, AssistantModelSelection.allCases)
        XCTAssertEqual(store.modelSelection, .openAI)
    }

    func testContinueGenerationSendsContinuationPrompt() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        service.conversations = [
            AssistantConversation(
                id: "conv-store",
                title: "作文练习",
                updatedAt: .now,
                messages: [
                    AssistantMessage(id: "assistant-1", role: .assistant, content: "第一段已经完成。", createdAt: .now)
                ]
            )
        ]
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()
        _ = await store.continueGeneration(conversationID: "conv-store")
        await waitUntil { !store.isSending }

        XCTAssertEqual(service.streamRequests, ["继续生成"])
    }

    func testFirstMessageGeneratesLocalConversationTitle() async {
        let service = StoreTestAssistantService()
        service.failingStreamRequestIndexes = []
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        let conversationID = await store.createConversation()
        _ = await store.send(text: "请帮我制定 30 天英语学习计划", conversationID: conversationID)
        await waitUntil { !store.isSending }

        XCTAssertEqual(store.conversation(id: "conv-store")?.title, "请帮我制定 30 天英语学习计划")
    }

    func testConversationSearchFiltersTitleSummaryAndMessages() async {
        let service = StoreTestAssistantService()
        service.conversations = [
            AssistantConversation(
                id: "writing",
                title: "作文修改",
                summary: "雅思 task 2",
                updatedAt: .now,
                messages: [AssistantMessage(id: "m1", role: .assistant, content: "coherence and cohesion")]
            ),
            AssistantConversation(
                id: "vocab",
                title: "词汇积累",
                summary: "government 相关词",
                updatedAt: .now,
                messages: [AssistantMessage(id: "m2", role: .assistant, content: "policy, citizen")]
            )
        ]
        let store = AssistantStore(service: service, shareBaseURL: URL(string: "https://example.com")!)

        await store.load()
        store.conversationSearchQuery = "government"

        XCTAssertEqual(store.visibleConversations.map(\.id), ["vocab"])

        store.conversationSearchQuery = "coherence"

        XCTAssertEqual(store.visibleConversations.map(\.id), ["writing"])
    }

    func testAttachmentDraftFormatsSizeAndDetectsImagePreview() {
        let imageDraft = AssistantAttachmentDraft(
            name: "photo.png",
            mimeType: "image/png",
            data: Data(repeating: 0, count: 1536)
        )
        let pdfDraft = AssistantAttachmentDraft(
            name: "essay.pdf",
            mimeType: "application/pdf",
            data: Data(repeating: 0, count: 2 * 1024 * 1024)
        )

        XCTAssertTrue(imageDraft.isImage)
        XCTAssertEqual(imageDraft.formattedSize, "1.5 KB")
        XCTAssertFalse(pdfDraft.isImage)
        XCTAssertEqual(pdfDraft.formattedSize, "2.0 MB")
    }

    private func waitUntil(
        timeout: TimeInterval = 1,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}

private final class StoreTestAssistantService: AssistantService, @unchecked Sendable {
    var conversations: [AssistantConversation] = []
    var streamRequests: [String] = []
    var failingStreamRequestIndexes: Set<Int> = [1]
    var failingGetConversationIDs: Set<AssistantConversation.ID> = []
    var streamDelayNanoseconds: UInt64 = 0
    var listProjectsError: Error?
    var listConversationsError: Error?
    var listModelsError: Error?
    var models: [AssistantModelSelection] = AssistantModelSelection.allCases
    var renamedTitle: String?

    func listModels() async throws -> [AssistantModelSelection] {
        if let listModelsError {
            throw listModelsError
        }
        return models
    }

    func listProjects() async throws -> [AssistantProject] {
        if let listProjectsError {
            throw listProjectsError
        }
        return []
    }
    func createProject(name: String, description: String) async throws -> AssistantProject {
        AssistantProject(id: 1, name: name, description: description, createdAt: .now, updatedAt: .now)
    }
    func updateProject(id: Int, name: String, description: String) async throws -> AssistantProject {
        AssistantProject(id: id, name: name, description: description, createdAt: .now, updatedAt: .now)
    }
    func deleteProject(id: Int) async throws {}
    func listConversations(archived: Bool?, projectId: Int?) async throws -> [AssistantConversation] {
        if let listConversationsError {
            throw listConversationsError
        }
        return conversations
    }

    func createConversation(title: String?, projectId: Int?) async throws -> AssistantConversation {
        let conversation = AssistantConversation(
            id: "conv-store",
            projectId: projectId,
            title: title ?? "新对话",
            summary: "",
            updatedAt: .now
        )
        conversations = [conversation]
        return conversation
    }

    func getConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        if failingGetConversationIDs.contains(id) {
            throw APIError.requestFailed(statusCode: 502, message: "对话详情同步失败")
        }
        return conversations.first { $0.id == id } ?? AssistantConversation(id: id, title: "新对话", updatedAt: .now)
    }

    func renameConversation(id: AssistantConversation.ID, title: String, summary: String?) async throws -> AssistantConversation {
        renamedTitle = title
        var conversation = try await getConversation(id: id)
        conversation.title = title
        conversation.summary = summary ?? conversation.summary
        conversations = [conversation]
        return conversation
    }

    func sendAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation {
        try await getConversation(id: conversationID)
    }

    func streamAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection,
        onEvent: @escaping @Sendable (AssistantStreamEvent) async -> Void
    ) async throws {
        streamRequests.append(text)
        if streamDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: streamDelayNanoseconds)
        }
        if failingStreamRequestIndexes.contains(streamRequests.count) {
            throw APIError.requestFailed(statusCode: 503, message: "模型服务暂时不可用")
        }
        if let index = conversations.firstIndex(where: { $0.id == conversationID }) {
            conversations[index].messages.append(AssistantMessage(id: "retry-user", role: .user, content: text, createdAt: .now))
            conversations[index].messages.append(AssistantMessage(id: "retry-assistant", role: .assistant, content: "重试成功。", status: .done, createdAt: .now))
            conversations[index].summary = text
            conversations[index].updatedAt = .now
        }
        await onEvent(AssistantStreamEvent(type: "message.completed", delta: nil, content: "重试成功。", error: nil))
    }

    func uploadMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        attachments: [AssistantUploadAttachment],
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation {
        try await getConversation(id: conversationID)
    }

    func setPinned(conversationID: AssistantConversation.ID, pinned: Bool) async throws -> AssistantConversation {
        var conversation = try await getConversation(id: conversationID)
        conversation.pinned = pinned
        return conversation
    }
    func archiveConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        var conversation = try await getConversation(id: id)
        conversation.archived = true
        return conversation
    }
    func restoreConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        var conversation = try await getConversation(id: id)
        conversation.archived = false
        return conversation
    }
    func moveConversation(id: AssistantConversation.ID, projectId: Int?) async throws -> AssistantConversation {
        var conversation = try await getConversation(id: id)
        conversation.projectId = projectId
        return conversation
    }
    func deleteConversation(id: AssistantConversation.ID) async throws {}
    func shareConversation(id: AssistantConversation.ID) async throws -> AssistantShare {
        AssistantShare(shareToken: "share", sharePath: "/assistant/share/share", createdAt: .now)
    }
    func revokeShare(token: String) async throws {}
}
