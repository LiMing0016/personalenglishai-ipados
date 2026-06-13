import Foundation

struct AssistantConversation: Identifiable, Hashable {
    let id: String
    var title: String
    var summary: String
    var updatedAt: Date

    static let samples = [
        AssistantConversation(
            id: "conversation-1",
            title: "雅思口语练习",
            summary: "Part 2 回答结构与高频表达。",
            updatedAt: .now
        ),
        AssistantConversation(
            id: "conversation-2",
            title: "语法讲解",
            summary: "什么时候使用现在完成时。",
            updatedAt: .now.addingTimeInterval(-3600)
        )
    ]
}
