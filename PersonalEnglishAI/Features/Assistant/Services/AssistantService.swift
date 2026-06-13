import Foundation

protocol AssistantService {
    func listConversations() async throws -> [AssistantConversation]
}

struct MockAssistantService: AssistantService {
    func listConversations() async throws -> [AssistantConversation] {
        AssistantConversation.samples
    }
}
