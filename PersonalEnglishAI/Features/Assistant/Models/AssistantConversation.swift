import Foundation

struct AssistantConversation: Identifiable, Hashable {
    let id: String
    var title: String
    var summary: String
    var updatedAt: Date

    static let samples = [
        AssistantConversation(
            id: "conversation-1",
            title: "IELTS speaking practice",
            summary: "Part 2 answer structure and vocabulary.",
            updatedAt: .now
        ),
        AssistantConversation(
            id: "conversation-2",
            title: "Grammar explanation",
            summary: "When to use present perfect.",
            updatedAt: .now.addingTimeInterval(-3600)
        )
    ]
}
