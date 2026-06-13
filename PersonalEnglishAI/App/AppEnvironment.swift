import Foundation
import SwiftUI

struct AppEnvironment: @unchecked Sendable {
    let configuration: AppConfiguration
    let authSession: AuthSession
    let apiClient: APIClient
    let authService: AuthService
    let userService: UserService
    let subscriptionService: SubscriptionService
    let authDeepLinkStore: AuthDeepLinkStore

    init(
        configuration: AppConfiguration,
        authSession: AuthSession,
        apiClient: APIClient,
        authService: AuthService,
        userService: UserService,
        subscriptionService: SubscriptionService,
        authDeepLinkStore: AuthDeepLinkStore
    ) {
        self.configuration = configuration
        self.authSession = authSession
        self.apiClient = apiClient
        self.authService = authService
        self.userService = userService
        self.subscriptionService = subscriptionService
        self.authDeepLinkStore = authDeepLinkStore
    }
}

extension AppEnvironment {
    static let live: AppEnvironment = {
        let authSession = AuthSession(tokenStore: KeychainTokenStore(service: "PersonalEnglishAI"))
        let authDeepLinkStore = AuthDeepLinkStore()
        var apiClient = APIClient(configuration: .development)
        apiClient.tokenProvider = { authSession.accessToken }
        apiClient.tokenRefreshProvider = {
            let refreshService = LiveAuthService(apiClient: APIClient(configuration: .development))
            let response = try await refreshService.refresh()

            guard let token = response.token, !token.isEmpty else {
                throw APIError.missingToken
            }

            try authSession.updateAccessToken(token)
            return token
        }
        apiClient.unauthorizedHandler = {
            authSession.clear()
        }

        return AppEnvironment(
            configuration: .development,
            authSession: authSession,
            apiClient: apiClient,
            authService: LiveAuthService(apiClient: apiClient),
            userService: LiveUserService(apiClient: apiClient),
            subscriptionService: LiveSubscriptionService(apiClient: apiClient),
            authDeepLinkStore: authDeepLinkStore
        )
    }()

    static let preview = AppEnvironment(
        configuration: .preview,
        authSession: AuthSession(tokenStore: InMemoryTokenStore()),
        apiClient: APIClient(configuration: .preview),
        authService: MockAuthService(),
        userService: MockUserService(),
        subscriptionService: MockSubscriptionService(),
        authDeepLinkStore: AuthDeepLinkStore()
    )
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.preview
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
