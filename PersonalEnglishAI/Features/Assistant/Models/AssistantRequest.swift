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

enum AssistantModelSelection: String, CaseIterable, Identifiable, Hashable {
    case openAI
    case kimi
    case qwen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAI:
            "OpenAI"
        case .kimi:
            "Kimi"
        case .qwen:
            "Qwen"
        }
    }

    var subtitle: String {
        switch self {
        case .openAI:
            "gpt-5.4-mini"
        case .kimi:
            "kimi-k2.5"
        case .qwen:
            "qwen-plus"
        }
    }

    var provider: String {
        switch self {
        case .openAI:
            "openai"
        case .kimi:
            "kimi"
        case .qwen:
            "qwen"
        }
    }

    var model: String {
        subtitle
    }
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
