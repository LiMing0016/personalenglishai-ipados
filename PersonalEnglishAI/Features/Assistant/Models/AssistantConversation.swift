import Foundation

struct AssistantConversation: Identifiable, Hashable, Decodable {
    let id: String
    var projectId: Int?
    var title: String
    var summary: String?
    var pinned: Bool
    var archived: Bool
    var createdAt: Date?
    var updatedAt: Date
    var messages: [AssistantMessage]

    init(
        id: String,
        projectId: Int? = nil,
        title: String,
        summary: String? = nil,
        pinned: Bool = false,
        archived: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date,
        messages: [AssistantMessage] = []
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.summary = summary
        self.pinned = pinned
        self.archived = archived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case title
        case summary
        case pinned
        case archived
        case createdAt
        case updatedAt
        case messages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        projectId = try container.decodeIfPresent(Int.self, forKey: .projectId)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt ?? .now
        messages = try container.decodeIfPresent([AssistantMessage].self, forKey: .messages) ?? []
    }

    static let samples = [
        AssistantConversation(
            id: "conversation-1",
            projectId: nil,
            title: "雅思口语练习",
            summary: "Part 2 回答结构与高频表达。",
            pinned: true,
            archived: false,
            createdAt: .now,
            updatedAt: .now,
            messages: AssistantMessage.samples
        ),
        AssistantConversation(
            id: "conversation-2",
            projectId: nil,
            title: "语法讲解",
            summary: "什么时候使用现在完成时。",
            pinned: false,
            archived: false,
            createdAt: .now.addingTimeInterval(-3600),
            updatedAt: .now.addingTimeInterval(-3600),
            messages: []
        )
    ]
}
