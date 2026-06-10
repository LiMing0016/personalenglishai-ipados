import Foundation

protocol SubscriptionService {
    func getMySubscription() async throws -> SubscriptionStatus
}

struct MockSubscriptionService: SubscriptionService {
    func getMySubscription() async throws -> SubscriptionStatus {
        .preview
    }
}
