import Foundation

enum AssistantMode: String, CaseIterable, Identifiable, Hashable {
    case `default`
    case exam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default:
            "日常学习"
        case .exam:
            "考试强化"
        }
    }

    var learningMode: String {
        switch self {
        case .default:
            "daily_explain"
        case .exam:
            "exam_boost"
        }
    }
}

struct AssistantModelSelection: Identifiable, Hashable, Decodable {
    let id: String
    let title: String
    let subtitle: String
    let provider: String
    let model: String
    let isDefault: Bool
    let supportsStreaming: Bool
    let supportsAttachments: Bool
    let supportsVision: Bool
    let maxInputTokens: Int?
    let status: String?

    init(
        id: String? = nil,
        title: String,
        subtitle: String,
        provider: String,
        model: String,
        isDefault: Bool = false,
        supportsStreaming: Bool = true,
        supportsAttachments: Bool = true,
        supportsVision: Bool = false,
        maxInputTokens: Int? = nil,
        status: String? = "available"
    ) {
        self.id = id ?? "\(provider):\(model)"
        self.title = title
        self.subtitle = subtitle
        self.provider = provider
        self.model = model
        self.isDefault = isDefault
        self.supportsStreaming = supportsStreaming
        self.supportsAttachments = supportsAttachments
        self.supportsVision = supportsVision
        self.maxInputTokens = maxInputTokens
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case backendID = "id"
        case label
        case provider
        case isDefault = "default"
        case supportsStreaming
        case supportsAttachments
        case supportsVision
        case maxInputTokens
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let model = try container.decode(String.self, forKey: .backendID)
        let provider = try container.decode(String.self, forKey: .provider)
        let label = try container.decodeIfPresent(String.self, forKey: .label) ?? model

        self.init(
            title: label,
            subtitle: model,
            provider: provider,
            model: model,
            isDefault: try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false,
            supportsStreaming: try container.decodeIfPresent(Bool.self, forKey: .supportsStreaming) ?? true,
            supportsAttachments: try container.decodeIfPresent(Bool.self, forKey: .supportsAttachments) ?? false,
            supportsVision: try container.decodeIfPresent(Bool.self, forKey: .supportsVision) ?? false,
            maxInputTokens: try container.decodeIfPresent(Int.self, forKey: .maxInputTokens),
            status: try container.decodeIfPresent(String.self, forKey: .status)
        )
    }

    static let openAI = AssistantModelSelection(
        title: "OpenAI",
        subtitle: "gpt-5.4-mini",
        provider: "openai",
        model: "gpt-5.4-mini",
        isDefault: true,
        supportsStreaming: true,
        supportsAttachments: true,
        supportsVision: true,
        maxInputTokens: 128000
    )

    static let kimi = AssistantModelSelection(
        title: "Kimi",
        subtitle: "kimi-k2.5",
        provider: "kimi",
        model: "kimi-k2.5",
        supportsStreaming: true,
        supportsAttachments: false,
        supportsVision: false,
        maxInputTokens: 128000
    )

    static let qwen = AssistantModelSelection(
        title: "Qwen",
        subtitle: "qwen-plus",
        provider: "qwen",
        model: "qwen-plus",
        supportsStreaming: true,
        supportsAttachments: true,
        supportsVision: false,
        maxInputTokens: 32000
    )

    static let allCases: [AssistantModelSelection] = [.openAI, .kimi, .qwen]
}

struct AssistantRequest: Encodable {
    let appConversationId: String
    let clientMessageId: String
    let idempotencyKey: String
    let aiProvider: String
    let model: String
    let mode: String
    let intent: String
    let scope: String
    let message: Message
    let studyContext: StudyContext

    struct Message: Encodable {
        let text: String
    }

    struct StudyContext: Encodable {
        let studyStage: String?
        let targetExam: String?
        let locale: String
        let responseLanguage: String
    }

    init(
        appConversationId: String,
        text: String,
        studyStage: String?,
        assistantMode: AssistantMode,
        modelSelection: AssistantModelSelection
    ) {
        let clientMessageId = UUID().uuidString
        self.appConversationId = appConversationId
        self.clientMessageId = clientMessageId
        self.idempotencyKey = clientMessageId
        self.aiProvider = modelSelection.provider
        self.model = modelSelection.model
        self.mode = assistantMode.learningMode
        self.intent = "free_chat"
        self.scope = "message_only"
        self.message = Message(text: text)
        self.studyContext = StudyContext(
            studyStage: studyStage?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            targetExam: Self.targetExam(from: studyStage),
            locale: "zh-CN",
            responseLanguage: "zh-CN"
        )
    }

    private static func targetExam(from stage: String?) -> String? {
        let normalized = stage?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let known = ["ielts", "toefl", "cet4", "cet6", "gaokao", "postgrad"]
        guard let normalized, known.contains(normalized) else {
            return nil
        }
        return normalized
    }
}

struct CreateAssistantConversationRequest: Encodable {
    let title: String?
    let projectId: Int?
}

struct UpdateAssistantConversationRequest: Encodable {
    let title: String
    let summary: String?
}

struct AssistantProjectRequest: Encodable {
    let name: String
    let description: String
}

struct SendAssistantMessageRequest: Encodable {
    let message: String
    let studyStage: String?
    let assistantMode: String?
}

struct SetPinnedAssistantConversationRequest: Encodable {
    let pinned: Bool
}

struct MoveAssistantConversationRequest: Encodable {
    let projectId: Int?
}

struct AssistantUploadAttachment: Hashable {
    let name: String
    let mimeType: String
    let data: Data
}

struct AssistantShare: Identifiable, Hashable, Decodable {
    var id: String { shareToken }
    let shareToken: String
    let sharePath: String
    let createdAt: Date?
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
