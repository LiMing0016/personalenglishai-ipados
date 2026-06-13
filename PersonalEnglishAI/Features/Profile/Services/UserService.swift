import Foundation

protocol UserService {
    func getMyProfile() async throws -> MeProfile
}

struct LiveUserService: UserService {
    let apiClient: APIClient

    func getMyProfile() async throws -> MeProfile {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .get, path: "/users/me/profile"),
            responseType: APIEnvelope<MeProfile>.self
        )

        guard let profile = envelope.data else {
            throw APIError.decodingFailed
        }

        return profile
    }
}

struct MockUserService: UserService {
    func getMyProfile() async throws -> MeProfile {
        .preview
    }
}
