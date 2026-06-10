import Foundation

struct MeProfile: Decodable, Hashable {
    let userId: Int?
    let email: String?
    let nickname: String?
    let studyStage: String?

    static let preview = MeProfile(
        userId: 1,
        email: "student@example.com",
        nickname: "Student",
        studyStage: "IELTS"
    )
}
