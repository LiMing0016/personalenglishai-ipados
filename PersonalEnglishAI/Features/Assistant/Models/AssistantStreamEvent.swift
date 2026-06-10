import Foundation

struct AssistantStreamEvent: Decodable {
    let type: String
    let delta: String?
    let content: String?
}
