import Foundation

struct AssistantMessage: Identifiable, Hashable {
    enum Role: String {
        case user
        case assistant
    }

    let id: String
    let role: Role
    let content: String

    static let samples = [
        AssistantMessage(
            id: "message-1",
            role: .user,
            content: "Help me improve this IELTS answer."
        ),
        AssistantMessage(
            id: "message-2",
            role: .assistant,
            content: "Sure. Start with a clearer topic sentence, then add one specific example."
        )
    ]
}
