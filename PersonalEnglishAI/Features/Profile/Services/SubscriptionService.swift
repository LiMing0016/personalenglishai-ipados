import Foundation

protocol SubscriptionService {
    func getMySubscription() async throws -> SubscriptionStatus
}

struct LiveSubscriptionService: SubscriptionService {
    let apiClient: APIClient

    func getMySubscription() async throws -> SubscriptionStatus {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .get, path: "/subscription/me"),
            responseType: APIEnvelope<SubscriptionStatus>.self
        )

        guard let subscription = envelope.data else {
            throw APIError.decodingFailed
        }

        return subscription
    }
}

struct MockSubscriptionService: SubscriptionService {
    func getMySubscription() async throws -> SubscriptionStatus {
        .preview
    }
}
