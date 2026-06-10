import Foundation

protocol DraftStore {
    func loadDraft(id: String) async throws -> String?
    func saveDraft(_ text: String, id: String) async throws
}

struct InMemoryDraftStore: DraftStore {
    func loadDraft(id: String) async throws -> String? {
        nil
    }

    func saveDraft(_ text: String, id: String) async throws {
    }
}
