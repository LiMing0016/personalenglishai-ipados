import Foundation

enum AppRoute: Hashable {
    case dashboard
    case assistantConversation(id: AssistantConversation.ID)
    case writingDraft(id: String)
    case profile
}
