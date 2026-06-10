import Foundation

protocol AuthService {
    func login(email: String, password: String) async throws -> LoginResponse
}

struct MockAuthService: AuthService {
    func login(email: String, password: String) async throws -> LoginResponse {
        LoginResponse(token: "preview-token", userId: 1, email: email)
    }
}
