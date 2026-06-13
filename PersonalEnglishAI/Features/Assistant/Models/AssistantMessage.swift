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
            content: "帮我优化一下这段雅思口语回答。"
        ),
        AssistantMessage(
            id: "message-2",
            role: .assistant,
            content: "可以。建议先用更清晰的主题句开头，然后补充一个具体例子，让回答更完整。"
        )
    ]
}
