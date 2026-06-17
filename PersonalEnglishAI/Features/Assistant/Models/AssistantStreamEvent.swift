import Foundation

struct AssistantStreamEvent: Decodable, Hashable {
    struct Failure: Decodable, Hashable {
        let code: String?
        let message: String?
    }

    let type: String
    let delta: String?
    let content: String?
    let error: Failure?
}
