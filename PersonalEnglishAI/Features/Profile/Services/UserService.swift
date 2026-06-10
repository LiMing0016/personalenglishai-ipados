import Foundation

protocol UserService {
    func getMyProfile() async throws -> MeProfile
}

struct MockUserService: UserService {
    func getMyProfile() async throws -> MeProfile {
        .preview
    }
}
