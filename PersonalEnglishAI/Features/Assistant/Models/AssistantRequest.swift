import Foundation

struct AssistantRequest: Encodable {
    let appConversationId: String
    let clientMessageId: String
    let message: Message

    struct Message: Encodable {
        let text: String
    }
}
