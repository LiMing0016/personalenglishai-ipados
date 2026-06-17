import Foundation

struct AssistantProject: Identifiable, Hashable, Decodable {
    let id: Int
    var name: String
    var description: String?
    var createdAt: Date?
    var updatedAt: Date?
}
