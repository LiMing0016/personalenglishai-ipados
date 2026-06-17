import Combine
import Foundation

final class AuthSession: ObservableObject, @unchecked Sendable {
    private let tokenStore: TokenStore
    @Published private(set) var accessToken: String?
    @Published private(set) var isRestoring = false

    var isAuthenticated: Bool {
        accessToken?.isEmpty == false
    }

    init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
        self.accessToken = try? tokenStore.readAccessToken()
    }

    func updateAccessToken(_ token: String) throws {
        try tokenStore.saveAccessToken(token)
        accessToken = token
    }

    func clear() {
        try? tokenStore.deleteAccessToken()
        accessToken = nil
    }
}
