import Foundation

struct SubscriptionStatus: Decodable, Hashable {
    let planCode: String?
    let planName: String?
    let tokenUsed: Int?
    let tokenRemaining: Int?

    static let preview = SubscriptionStatus(
        planCode: "free",
        planName: "免费版",
        tokenUsed: 0,
        tokenRemaining: 1000
    )
}
