import Foundation

protocol TokenStore {
    func readAccessToken() throws -> String?
    func saveAccessToken(_ token: String) throws
    func deleteAccessToken() throws
}

final class InMemoryTokenStore: TokenStore {
    private var accessToken: String?

    func readAccessToken() throws -> String? {
        accessToken
    }

    func saveAccessToken(_ token: String) throws {
        accessToken = token
    }

    func deleteAccessToken() throws {
        accessToken = nil
    }
}
