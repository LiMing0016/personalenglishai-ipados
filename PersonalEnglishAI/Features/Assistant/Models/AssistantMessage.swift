import Foundation

struct AssistantMessage: Identifiable, Hashable, Decodable {
    enum Role: String, Decodable {
        case user
        case assistant
    }

    enum Status: String, Decodable {
        case done
        case failed
        case loading
    }

    let id: String
    let role: Role
    var content: String
    var status: Status
    var createdAt: Date?

    init(
        id: String,
        role: Role,
        content: String,
        status: Status = .done,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.status = status
        self.createdAt = createdAt
    }

    static let samples = [
        AssistantMessage(
            id: "message-1",
            role: .user,
            content: "帮我优化一下这段雅思口语回答。",
            status: .done,
            createdAt: .now.addingTimeInterval(-120)
        ),
        AssistantMessage(
            id: "message-2",
            role: .assistant,
            content: """
            # 优化建议

            可以。建议你先调整这三点：

            - **主题句**：用更清晰的开头表达观点。
            - **例子**：补充一个具体生活场景。
            - **收尾**：用一句总结让回答更完整。
            """,
            status: .done,
            createdAt: .now.addingTimeInterval(-60)
        )
    ]
}
