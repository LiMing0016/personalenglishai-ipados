import Foundation
import XCTest
@testable import PersonalEnglishAI

final class LiveAssistantServiceTests: XCTestCase {
    override func tearDown() {
        AssistantMockURLProtocol.handler = nil
        super.tearDown()
    }

    func testListConversationsUsesArchivedAndProjectFilters() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations")
            XCTAssertEqual(request.url?.query, "archived=false&projectId=7")
            XCTAssertEqual(request.httpMethod, "GET")

            return try Self.jsonResponse(
                request: request,
                body: """
                {"code":"0","message":"OK","data":[{"id":"conv-1","projectId":7,"title":"雅思口语","summary":"Part 2","pinned":true,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:05:00"}]}
                """
            )
        }

        let service = makeService()
        let conversations = try await service.listConversations(archived: false, projectId: 7)

        XCTAssertEqual(conversations.map(\.id), ["conv-1"])
        XCTAssertEqual(conversations[0].projectId, 7)
        XCTAssertEqual(conversations[0].title, "雅思口语")
        XCTAssertTrue(conversations[0].pinned)
    }

    func testCreateConversationPostsTitleAndProject() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations")
            XCTAssertEqual(request.httpMethod, "POST")

            let payload = try XCTUnwrap(request.peaiJSONBody)
            XCTAssertEqual(payload["title"] as? String, "新对话")
            XCTAssertEqual(payload["projectId"] as? Int, 3)

            return try Self.jsonResponse(
                request: request,
                body: """
                {"code":"0","message":"OK","data":{"id":"conv-new","projectId":3,"title":"新对话","summary":"","pinned":false,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:00:00","messages":[]}}
                """
            )
        }

        let conversation = try await makeService().createConversation(title: "新对话", projectId: 3)

        XCTAssertEqual(conversation.id, "conv-new")
        XCTAssertEqual(conversation.messages, [])
    }

    func testGetConversationReturnsMessages() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1")
            XCTAssertEqual(request.httpMethod, "GET")

            return try Self.jsonResponse(
                request: request,
                body: """
                {"code":"0","message":"OK","data":{"id":"conv-1","projectId":null,"title":"对话","summary":"一句话","pinned":false,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:03:00","messages":[{"id":"m1","role":"user","content":"你好","status":"done","createdAt":"2026-06-14T09:01:00"},{"id":"m2","role":"assistant","content":"你好，我可以帮你练英语。","status":"done","createdAt":"2026-06-14T09:02:00"}]}}
                """
            )
        }

        let conversation = try await makeService().getConversation(id: "conv-1")

        XCTAssertEqual(conversation.messages.count, 2)
        XCTAssertEqual(conversation.messages[1].role, .assistant)
    }

    func testSendAgentMessagePostsRunPayload() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1/messages/run")
            XCTAssertEqual(request.httpMethod, "POST")

            let payload = try XCTUnwrap(request.peaiJSONBody)
            XCTAssertEqual(payload["appConversationId"] as? String, "conv-1")
            XCTAssertEqual(payload["aiProvider"] as? String, "kimi")
            XCTAssertEqual(payload["model"] as? String, "kimi-k2.5")
            XCTAssertEqual(payload["mode"] as? String, "daily_explain")
            XCTAssertEqual(payload["intent"] as? String, "free_chat")
            XCTAssertEqual(payload["scope"] as? String, "message_only")

            let message = try XCTUnwrap(payload["message"] as? [String: Any])
            XCTAssertEqual(message["text"] as? String, "帮我练口语")

            let studyContext = try XCTUnwrap(payload["studyContext"] as? [String: Any])
            XCTAssertEqual(studyContext["locale"] as? String, "zh-CN")
            XCTAssertEqual(studyContext["responseLanguage"] as? String, "zh-CN")

            return try Self.jsonResponse(
                request: request,
                body: """
                {"code":"0","message":"OK","data":{"id":"conv-1","projectId":null,"title":"帮我练口语","summary":"帮我练口语","pinned":false,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:03:00","messages":[{"id":"m1","role":"user","content":"帮我练口语","status":"done","createdAt":"2026-06-14T09:01:00"},{"id":"m2","role":"assistant","content":"当然可以。我们先从自我介绍开始。","status":"done","createdAt":"2026-06-14T09:02:00"}]}}
                """
            )
        }

        let conversation = try await makeService().sendAgentMessage(
            conversationID: "conv-1",
            text: "帮我练口语",
            studyStage: nil,
            assistantMode: .default,
            modelSelection: .kimi
        )

        XCTAssertEqual(conversation.messages.last?.content, "当然可以。我们先从自我介绍开始。")
    }

    func testStreamAgentMessageRequestsEventStream() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1/messages/run/stream")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "text/event-stream")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let payload = try XCTUnwrap(request.peaiJSONBody)
            XCTAssertEqual(payload["aiProvider"] as? String, "openai")
            XCTAssertEqual(payload["model"] as? String, "gpt-5.4-mini")

            return try Self.eventStreamResponse(
                request: request,
                body: "data: {\"type\":\"message.delta\",\"delta\":\"你好\"}\n\n" +
                    "data: {\"type\":\"message.completed\",\"content\":\"你好，我可以帮你练英语。\"}\n\n"
            )
        }

        final class EventSink: @unchecked Sendable {
            var events: [AssistantStreamEvent] = []
        }

        let sink = EventSink()
        try await makeService().streamAgentMessage(
            conversationID: "conv-1",
            text: "你好",
            studyStage: nil,
            assistantMode: .default,
            modelSelection: .openAI
        ) { event in
            sink.events.append(event)
        }

        XCTAssertEqual(sink.events.map(\.type), ["message.delta", "message.completed"])
        XCTAssertEqual(sink.events.last?.content, "你好，我可以帮你练英语。")
    }

    func testStreamAgentMessageRefreshesTokenAfterUnauthorized() async throws {
        final class TokenBox: @unchecked Sendable {
            var token = "expired-token"
            var refreshCount = 0
            var unauthorizedCount = 0
            var authorizations: [String?] = []
        }

        let box = TokenBox()
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1/messages/run/stream")
            box.authorizations.append(request.value(forHTTPHeaderField: "Authorization"))

            if box.authorizations.count == 1 {
                return try Self.jsonResponse(
                    request: request,
                    statusCode: 401,
                    body: #"{"code":"401001","message":"登录已过期","data":null}"#
                )
            }

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token")
            return try Self.eventStreamResponse(
                request: request,
                body: "data: {\"type\":\"message.completed\",\"content\":\"刷新后成功。\"}\n\n"
            )
        }

        final class EventSink: @unchecked Sendable {
            var events: [AssistantStreamEvent] = []
        }

        let sink = EventSink()
        let service = makeService(
            tokenProvider: { box.token },
            tokenRefreshProvider: {
                box.refreshCount += 1
                box.token = "fresh-token"
                return box.token
            },
            unauthorizedHandler: {
                box.unauthorizedCount += 1
            }
        )

        try await service.streamAgentMessage(
            conversationID: "conv-1",
            text: "你好",
            studyStage: nil,
            assistantMode: .default,
            modelSelection: .openAI
        ) { event in
            sink.events.append(event)
        }

        XCTAssertEqual(box.authorizations, ["Bearer expired-token", "Bearer fresh-token"])
        XCTAssertEqual(box.refreshCount, 1)
        XCTAssertEqual(box.unauthorizedCount, 0)
        XCTAssertEqual(sink.events.last?.content, "刷新后成功。")
    }

    func testStreamAgentMessageDecodesBackendErrorMessage() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1/messages/run/stream")
            return try Self.jsonResponse(
                request: request,
                statusCode: 502,
                body: #"{"code":"AI_ERROR","message":"模型服务暂时不可用","data":null}"#
            )
        }

        do {
            try await makeService().streamAgentMessage(
                conversationID: "conv-1",
                text: "你好",
                studyStage: nil,
                assistantMode: .default,
                modelSelection: .openAI
            ) { _ in }
            XCTFail("Expected streamAgentMessage to throw")
        } catch APIError.requestFailed(let statusCode, let message) {
            XCTAssertEqual(statusCode, 502)
            XCTAssertEqual(message, "模型服务暂时不可用")
        }
    }

    func testStreamAgentMessageReportsExpiredLoginWhenTokenRefreshFails() async throws {
        final class TokenBox: @unchecked Sendable {
            var refreshCount = 0
            var unauthorizedCount = 0
        }

        let box = TokenBox()
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer expired-token")
            return try Self.jsonResponse(
                request: request,
                statusCode: 401,
                body: #"{"code":"401001","message":"Unauthorized","data":null}"#
            )
        }

        let service = makeService(
            tokenProvider: { "expired-token" },
            tokenRefreshProvider: {
                box.refreshCount += 1
                throw APIError.missingToken
            },
            unauthorizedHandler: {
                box.unauthorizedCount += 1
            }
        )

        do {
            try await service.streamAgentMessage(
                conversationID: "conv-1",
                text: "你好",
                studyStage: nil,
                assistantMode: .default,
                modelSelection: .openAI
            ) { _ in }
            XCTFail("Expected streamAgentMessage to throw")
        } catch APIError.requestFailed(let statusCode, let message) {
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(message, "登录已过期，请重新登录")
        }

        XCTAssertEqual(box.refreshCount, 1)
        XCTAssertEqual(box.unauthorizedCount, 1)
    }

    func testUploadMessageUsesMultipartFormData() async throws {
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1/messages")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data; boundary=") == true)

            let body = String(data: try XCTUnwrap(request.peaiBodyData), encoding: .utf8)
            XCTAssertTrue(body?.contains(#"name="message""#) == true)
            XCTAssertTrue(body?.contains("请看这个文件") == true)
            XCTAssertTrue(body?.contains(#"name="aiProvider""#) == true)
            XCTAssertTrue(body?.contains("qwen") == true)
            XCTAssertTrue(body?.contains(#"name="model""#) == true)
            XCTAssertTrue(body?.contains("qwen-plus") == true)
            XCTAssertTrue(body?.contains(#"name="files"; filename="note.txt""#) == true)
            XCTAssertTrue(body?.contains("hello file") == true)

            return try Self.jsonResponse(
                request: request,
                body: """
                {"code":"0","message":"OK","data":{"id":"conv-1","projectId":null,"title":"附件","summary":"请看这个文件","pinned":false,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:03:00","messages":[{"id":"m1","role":"assistant","content":"我看到了附件。","status":"done","createdAt":"2026-06-14T09:02:00"}]}}
                """
            )
        }

        let conversation = try await makeService().uploadMessage(
            conversationID: "conv-1",
            text: "请看这个文件",
            attachments: [
                AssistantUploadAttachment(name: "note.txt", mimeType: "text/plain", data: Data("hello file".utf8))
            ],
            studyStage: nil,
            assistantMode: .default,
            modelSelection: .qwen
        )

        XCTAssertEqual(conversation.messages.last?.content, "我看到了附件。")
    }

    func testUploadMessageRefreshesTokenAfterUnauthorized() async throws {
        final class TokenBox: @unchecked Sendable {
            var token = "expired-token"
            var refreshCount = 0
            var unauthorizedCount = 0
            var authorizations: [String?] = []
        }

        let box = TokenBox()
        AssistantMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/assistant/conversations/conv-1/messages")
            box.authorizations.append(request.value(forHTTPHeaderField: "Authorization"))

            if box.authorizations.count == 1 {
                return try Self.jsonResponse(
                    request: request,
                    statusCode: 401,
                    body: #"{"code":"401001","message":"登录已过期","data":null}"#
                )
            }

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token")
            let body = String(data: try XCTUnwrap(request.peaiBodyData), encoding: .utf8)
            XCTAssertTrue(body?.contains(#"name="message""#) == true)
            XCTAssertTrue(body?.contains("请看这个文件") == true)

            return try Self.jsonResponse(
                request: request,
                body: """
                {"code":"0","message":"OK","data":{"id":"conv-1","projectId":null,"title":"附件","summary":"请看这个文件","pinned":false,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:03:00","messages":[{"id":"m1","role":"assistant","content":"上传成功。","status":"done","createdAt":"2026-06-14T09:02:00"}]}}
                """
            )
        }

        let conversation = try await makeService(
            tokenProvider: { box.token },
            tokenRefreshProvider: {
                box.refreshCount += 1
                box.token = "fresh-token"
                return box.token
            },
            unauthorizedHandler: {
                box.unauthorizedCount += 1
            }
        ).uploadMessage(
            conversationID: "conv-1",
            text: "请看这个文件",
            attachments: [
                AssistantUploadAttachment(name: "note.txt", mimeType: "text/plain", data: Data("hello file".utf8))
            ],
            studyStage: nil,
            assistantMode: .default,
            modelSelection: .qwen
        )

        XCTAssertEqual(box.authorizations, ["Bearer expired-token", "Bearer fresh-token"])
        XCTAssertEqual(box.refreshCount, 1)
        XCTAssertEqual(box.unauthorizedCount, 0)
        XCTAssertEqual(conversation.messages.last?.content, "上传成功。")
    }

    func testProjectsAndConversationActionsUseBackendEndpoints() async throws {
        var paths: [String] = []
        AssistantMockURLProtocol.handler = { request in
            paths.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")

            if request.url?.path == "/api/assistant/projects" && request.httpMethod == "GET" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":[{"id":5,"name":"雅思","description":"备考","createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:00:00"}]}"#)
            }
            if request.url?.path == "/api/assistant/projects" && request.httpMethod == "POST" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":{"id":6,"name":"新文件夹","description":"","createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:00:00"}}"#)
            }
            if request.url?.path == "/api/assistant/conversations/conv-1/pin" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":{"id":"conv-1","projectId":null,"title":"对话","summary":"","pinned":true,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:00:00"}}"#)
            }
            if request.url?.path == "/api/assistant/conversations/conv-1/archive" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":{"id":"conv-1","projectId":null,"title":"对话","summary":"","pinned":false,"archived":true,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:00:00"}}"#)
            }
            if request.url?.path == "/api/assistant/conversations/conv-1/move" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":{"id":"conv-1","projectId":5,"title":"对话","summary":"","pinned":false,"archived":false,"createdAt":"2026-06-14T09:00:00","updatedAt":"2026-06-14T09:00:00"}}"#)
            }
            if request.url?.path == "/api/assistant/conversations/conv-1/share" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":{"shareToken":"share-1","sharePath":"/assistant/share/share-1","createdAt":"2026-06-14T09:00:00"}}"#)
            }
            if request.url?.path == "/api/assistant/shares/share-1" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":null}"#)
            }
            if request.url?.path == "/api/assistant/conversations/conv-1" && request.httpMethod == "DELETE" {
                return try Self.jsonResponse(request: request, body: #"{"code":"0","message":"OK","data":null}"#)
            }

            XCTFail("Unexpected request \(request.httpMethod ?? "") \(request.url?.path ?? "")")
            return try Self.jsonResponse(request: request, statusCode: 404, body: #"{"message":"not found"}"#)
        }

        let service = makeService()
        _ = try await service.listProjects()
        _ = try await service.createProject(name: "新文件夹", description: "")
        _ = try await service.setPinned(conversationID: "conv-1", pinned: true)
        _ = try await service.archiveConversation(id: "conv-1")
        _ = try await service.moveConversation(id: "conv-1", projectId: 5)
        _ = try await service.shareConversation(id: "conv-1")
        try await service.revokeShare(token: "share-1")
        try await service.deleteConversation(id: "conv-1")

        XCTAssertEqual(paths, [
            "GET /api/assistant/projects",
            "POST /api/assistant/projects",
            "POST /api/assistant/conversations/conv-1/pin",
            "POST /api/assistant/conversations/conv-1/archive",
            "POST /api/assistant/conversations/conv-1/move",
            "POST /api/assistant/conversations/conv-1/share",
            "DELETE /api/assistant/shares/share-1",
            "DELETE /api/assistant/conversations/conv-1"
        ])
    }

    func testSSEParserKeepsCompleteDataBlocks() throws {
        let parser = ServerSentEventsParser()
        let events = parser.parse("""
        event: message.delta
        data: {"type":"message.delta","delta":"你好"}

        data: {"type":"message.completed","content":"你好，欢迎练习英语。"}

        """)

        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events[0].contains("message.delta"))
        XCTAssertTrue(events[1].contains("message.completed"))
    }

    private func makeService(
        tokenProvider: (() -> String?)? = nil,
        tokenRefreshProvider: (() async throws -> String?)? = nil,
        unauthorizedHandler: (() async -> Void)? = nil
    ) -> LiveAssistantService {
        LiveAssistantService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .assistantMocked,
            tokenProvider: tokenProvider,
            tokenRefreshProvider: tokenRefreshProvider,
            unauthorizedHandler: unauthorizedHandler
        ))
    }

    private static func jsonResponse(
        request: URLRequest,
        statusCode: Int = 200,
        body: String
    ) throws -> (HTTPURLResponse, Data) {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: XCTUnwrap(request.url),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        ))
        return (response, Data(body.utf8))
    }

    private static func eventStreamResponse(
        request: URLRequest,
        statusCode: Int = 200,
        body: String
    ) throws -> (HTTPURLResponse, Data) {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: XCTUnwrap(request.url),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/event-stream"]
        ))
        return (response, Data(body.utf8))
    }
}

private final class AssistantMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            XCTFail("Missing mock URL handler")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    var peaiBodyData: Data? {
        if let httpBody {
            return httpBody
        }

        guard let httpBodyStream else {
            return nil
        }

        httpBodyStream.open()
        defer { httpBodyStream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while httpBodyStream.hasBytesAvailable {
            let read = httpBodyStream.read(buffer, maxLength: bufferSize)
            if read <= 0 {
                break
            }
            data.append(buffer, count: read)
        }

        return data
    }

    var peaiJSONBody: [String: Any]? {
        get throws {
            guard let data = peaiBodyData else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
    }
}

private extension URLSession {
    static var assistantMocked: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AssistantMockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
