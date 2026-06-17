import Foundation

protocol AssistantService: Sendable {
    func listProjects() async throws -> [AssistantProject]
    func createProject(name: String, description: String) async throws -> AssistantProject
    func updateProject(id: Int, name: String, description: String) async throws -> AssistantProject
    func deleteProject(id: Int) async throws
    func listConversations(archived: Bool?, projectId: Int?) async throws -> [AssistantConversation]
    func createConversation(title: String?, projectId: Int?) async throws -> AssistantConversation
    func getConversation(id: AssistantConversation.ID) async throws -> AssistantConversation
    func sendAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation
    func streamAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection,
        onEvent: @escaping @Sendable (AssistantStreamEvent) async -> Void
    ) async throws
    func uploadMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        attachments: [AssistantUploadAttachment],
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation
    func setPinned(conversationID: AssistantConversation.ID, pinned: Bool) async throws -> AssistantConversation
    func archiveConversation(id: AssistantConversation.ID) async throws -> AssistantConversation
    func restoreConversation(id: AssistantConversation.ID) async throws -> AssistantConversation
    func moveConversation(id: AssistantConversation.ID, projectId: Int?) async throws -> AssistantConversation
    func deleteConversation(id: AssistantConversation.ID) async throws
    func shareConversation(id: AssistantConversation.ID) async throws -> AssistantShare
    func revokeShare(token: String) async throws
}

struct MockAssistantService: AssistantService {
    func listProjects() async throws -> [AssistantProject] {
        [
            AssistantProject(id: 1, name: "雅思备考", description: "口语和写作练习", createdAt: .now, updatedAt: .now)
        ]
    }

    func createProject(name: String, description: String) async throws -> AssistantProject {
        AssistantProject(id: Int.random(in: 2...999), name: name, description: description, createdAt: .now, updatedAt: .now)
    }

    func updateProject(id: Int, name: String, description: String) async throws -> AssistantProject {
        AssistantProject(id: id, name: name, description: description, createdAt: .now, updatedAt: .now)
    }

    func deleteProject(id: Int) async throws {}

    func listConversations(archived: Bool? = nil, projectId: Int? = nil) async throws -> [AssistantConversation] {
        AssistantConversation.samples
    }

    func createConversation(title: String?, projectId: Int?) async throws -> AssistantConversation {
        AssistantConversation(
            id: UUID().uuidString,
            projectId: projectId,
            title: title?.isEmpty == false ? title! : "新对话",
            summary: "",
            updatedAt: .now
        )
    }

    func getConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        AssistantConversation.samples.first { $0.id == id } ?? AssistantConversation.samples[0]
    }

    func sendAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation {
        var conversation = try await getConversation(id: conversationID)
        conversation.messages.append(AssistantMessage(id: UUID().uuidString, role: .user, content: text))
        conversation.messages.append(AssistantMessage(id: UUID().uuidString, role: .assistant, content: "可以，我们先把目标拆成三步来练。"))
        conversation.updatedAt = .now
        return conversation
    }

    func streamAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection,
        onEvent: @escaping @Sendable (AssistantStreamEvent) async -> Void
    ) async throws {
        await onEvent(AssistantStreamEvent(type: "message.delta", delta: "可以，", content: nil, error: nil))
        await onEvent(AssistantStreamEvent(type: "message.completed", delta: nil, content: "可以，我们开始练习。", error: nil))
    }

    func uploadMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        attachments: [AssistantUploadAttachment],
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation {
        var conversation = try await getConversation(id: conversationID)
        conversation.messages.append(AssistantMessage(id: UUID().uuidString, role: .assistant, content: "我已经收到 \(attachments.count) 个附件。"))
        return conversation
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
        AssistantShare(shareToken: "preview-share", sharePath: "/assistant/share/preview-share", createdAt: .now)
    }

    func revokeShare(token: String) async throws {}
}

struct LiveAssistantService: AssistantService {
    private static let expiredSessionMessage = "登录已过期，请重新登录"

    let apiClient: APIClient

    func listProjects() async throws -> [AssistantProject] {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .get, path: "/assistant/projects"),
            responseType: APIEnvelope<[AssistantProject]>.self
        ))
    }

    func createProject(name: String, description: String) async throws -> AssistantProject {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/projects"),
            body: AssistantProjectRequest(name: name, description: description),
            responseType: APIEnvelope<AssistantProject>.self
        ))
    }

    func updateProject(id: Int, name: String, description: String) async throws -> AssistantProject {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .patch, path: "/assistant/projects/\(id)"),
            body: AssistantProjectRequest(name: name, description: description),
            responseType: APIEnvelope<AssistantProject>.self
        ))
    }

    func deleteProject(id: Int) async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .delete, path: "/assistant/projects/\(id)"),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    func listConversations(archived: Bool? = nil, projectId: Int? = nil) async throws -> [AssistantConversation] {
        var queryItems: [URLQueryItem] = []
        if let archived {
            queryItems.append(URLQueryItem(name: "archived", value: archived ? "true" : "false"))
        }
        if let projectId {
            queryItems.append(URLQueryItem(name: "projectId", value: String(projectId)))
        }

        return try await unwrap(apiClient.send(
            APIEndpoint(method: .get, path: "/assistant/conversations", queryItems: queryItems),
            responseType: APIEnvelope<[AssistantConversation]>.self
        ))
    }

    func createConversation(title: String?, projectId: Int?) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations"),
            body: CreateAssistantConversationRequest(title: title, projectId: projectId),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func getConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .get, path: "/assistant/conversations/\(id)"),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func sendAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(conversationID)/messages/run"),
            body: AssistantRequest(
                appConversationId: conversationID,
                text: text,
                studyStage: studyStage,
                assistantMode: assistantMode,
                modelSelection: modelSelection
            ),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func streamAgentMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection,
        onEvent: @escaping @Sendable (AssistantStreamEvent) async -> Void
    ) async throws {
        var request = try makeJSONRequest(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(conversationID)/messages/run/stream"),
            body: AssistantRequest(
                appConversationId: conversationID,
                text: text,
                studyStage: studyStage,
                assistantMode: assistantMode,
                modelSelection: modelSelection
            )
        )
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let (bytes, _) = try await performStreamingRequest(request)

        var dataLines: [String] = []
        for try await line in bytes.lines {
            try Task.checkCancellation()
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                try await emitEvent(from: dataLines, onEvent: onEvent)
                dataLines.removeAll()
            } else if trimmedLine.hasPrefix("data:") {
                if !dataLines.isEmpty {
                    try await emitEvent(from: dataLines, onEvent: onEvent)
                    dataLines.removeAll()
                }
                dataLines.append(String(trimmedLine.dropFirst("data:".count)).trimmingCharacters(in: .whitespaces))
            }
        }
        try await emitEvent(from: dataLines, onEvent: onEvent)
    }

    func uploadMessage(
        conversationID: AssistantConversation.ID,
        text: String,
        attachments: [AssistantUploadAttachment],
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) async throws -> AssistantConversation {
        let fields: [(String, String)] = [
            ("message", text),
            ("studyStage", studyStage ?? ""),
            ("assistantMode", assistantMode.rawValue),
            ("aiProvider", modelSelection.provider),
            ("model", modelSelection.model)
        ]
        let request = try makeMultipartRequest(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(conversationID)/messages"),
            fields: fields,
            attachments: attachments
        )

        let (data, _) = try await performDataRequest(request)

        let envelope = try JSONDecoder.api.decode(APIEnvelope<AssistantConversation>.self, from: data)
        return try unwrap(envelope)
    }

    func setPinned(conversationID: AssistantConversation.ID, pinned: Bool) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(conversationID)/pin"),
            body: SetPinnedAssistantConversationRequest(pinned: pinned),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func archiveConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(id)/archive"),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func restoreConversation(id: AssistantConversation.ID) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(id)/restore"),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func moveConversation(id: AssistantConversation.ID, projectId: Int?) async throws -> AssistantConversation {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(id)/move"),
            body: MoveAssistantConversationRequest(projectId: projectId),
            responseType: APIEnvelope<AssistantConversation>.self
        ))
    }

    func deleteConversation(id: AssistantConversation.ID) async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .delete, path: "/assistant/conversations/\(id)"),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    func shareConversation(id: AssistantConversation.ID) async throws -> AssistantShare {
        try await unwrap(apiClient.send(
            APIEndpoint(method: .post, path: "/assistant/conversations/\(id)/share"),
            responseType: APIEnvelope<AssistantShare>.self
        ))
    }

    func revokeShare(token: String) async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .delete, path: "/assistant/shares/\(token)"),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    private func unwrap<Value>(_ envelope: APIEnvelope<Value>) throws -> Value {
        guard let data = envelope.data else {
            throw APIError.decodingFailed
        }
        return data
    }

    private func performStreamingRequest(
        _ request: URLRequest,
        allowsTokenRefresh: Bool = true
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let (bytes, response) = try await apiClient.urlSession.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401, allowsTokenRefresh {
            if let retryRequest = await requestByRefreshingToken(request) {
                return try await performStreamingRequest(retryRequest, allowsTokenRefresh: false)
            }
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: Self.expiredSessionMessage)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                await apiClient.unauthorizedHandler?()
            }

            let message = await errorMessage(from: bytes, statusCode: httpResponse.statusCode)
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        return (bytes, httpResponse)
    }

    private func performDataRequest(
        _ request: URLRequest,
        allowsTokenRefresh: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await apiClient.urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401, allowsTokenRefresh {
            if let retryRequest = await requestByRefreshingToken(request) {
                return try await performDataRequest(retryRequest, allowsTokenRefresh: false)
            }
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: Self.expiredSessionMessage)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                await apiClient.unauthorizedHandler?()
            }

            let message = errorMessage(from: data, statusCode: httpResponse.statusCode)
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        return (data, httpResponse)
    }

    private func requestByRefreshingToken(_ request: URLRequest) async -> URLRequest? {
        guard let tokenRefreshProvider = apiClient.tokenRefreshProvider else {
            await apiClient.unauthorizedHandler?()
            return nil
        }

        do {
            guard let refreshedToken = try await tokenRefreshProvider(), !refreshedToken.isEmpty else {
                await apiClient.unauthorizedHandler?()
                return nil
            }

            var retryRequest = request
            retryRequest.setValue("Bearer \(refreshedToken)", forHTTPHeaderField: "Authorization")
            return retryRequest
        } catch {
            await apiClient.unauthorizedHandler?()
            return nil
        }
    }

    private func errorMessage(from bytes: URLSession.AsyncBytes, statusCode: Int) async -> String? {
        if statusCode == 401 {
            return Self.expiredSessionMessage
        }

        do {
            return errorMessage(from: try await data(from: bytes), statusCode: statusCode)
        } catch {
            return nil
        }
    }

    private func errorMessage(from data: Data, statusCode: Int) -> String? {
        if statusCode == 401 {
            return Self.expiredSessionMessage
        }

        guard let message = try? JSONDecoder.api.decode(APIEnvelope<EmptyAPIResponse>.self, from: data).message,
              !message.isEmpty else {
            return nil
        }

        return message
    }

    private func data(from bytes: URLSession.AsyncBytes) async throws -> Data {
        var data = Data()
        for try await byte in bytes {
            data.append(contentsOf: [byte])
        }
        return data
    }

    private func makeJSONRequest(_ endpoint: APIEndpoint, body: some Encodable) throws -> URLRequest {
        var request = try makeBaseRequest(endpoint)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.api.encode(body)
        return request
    }

    private func makeMultipartRequest(
        _ endpoint: APIEndpoint,
        fields: [(String, String)],
        attachments: [AssistantUploadAttachment]
    ) throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try makeBaseRequest(endpoint)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(boundary: boundary, fields: fields, attachments: attachments)
        return request
    }

    private func makeBaseRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: apiClient.configuration.apiBaseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = apiClient.tokenProvider?(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func makeMultipartBody(
        boundary: String,
        fields: [(String, String)],
        attachments: [AssistantUploadAttachment]
    ) -> Data {
        var data = Data()

        for (name, value) in fields where !value.isEmpty {
            data.appendString("--\(boundary)\r\n")
            data.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            data.appendString("\(value)\r\n")
        }

        for attachment in attachments {
            data.appendString("--\(boundary)\r\n")
            data.appendString("Content-Disposition: form-data; name=\"files\"; filename=\"\(attachment.name)\"\r\n")
            data.appendString("Content-Type: \(attachment.mimeType)\r\n\r\n")
            data.append(attachment.data)
            data.appendString("\r\n")
        }

        data.appendString("--\(boundary)--\r\n")
        return data
    }

    private func emitEvent(
        from dataLines: [String],
        onEvent: @escaping @Sendable (AssistantStreamEvent) async -> Void
    ) async throws {
        guard !dataLines.isEmpty else {
            return
        }

        let payload = dataLines.joined(separator: "\n")
        guard let data = payload.data(using: .utf8) else {
            return
        }

        let event = try JSONDecoder.api.decode(AssistantStreamEvent.self, from: data)
        if event.type == "run.failed" {
            throw APIError.requestFailed(statusCode: 502, message: event.error?.message)
        }
        await onEvent(event)
    }
}

private extension Data {
    mutating func appendString(_ value: String) {
        append(Data(value.utf8))
    }
}
