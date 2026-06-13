import Foundation

struct MeProfile: Decodable, Hashable {
    let userId: Int?
    let email: String?
    let nickname: String?
    let studyStage: String?
    let emailVerified: Bool?
    let phone: String?
    let phoneVerified: Bool?
    let avatarUrl: String?
    let registerSource: String?
    let createdAt: String?

    static let preview = MeProfile(
        userId: 1,
        email: "student@example.com",
        nickname: "学习者",
        studyStage: "雅思备考",
        emailVerified: true,
        phone: nil,
        phoneVerified: false,
        avatarUrl: nil,
        registerSource: "email",
        createdAt: "2026-06-13 00:00:00"
    )
}
