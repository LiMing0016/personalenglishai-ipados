import Foundation
import SwiftUI

struct AppEnvironment: @unchecked Sendable {
    let configuration: AppConfiguration
    let authSession: AuthSession
    let apiClient: APIClient
    let authService: AuthService
    let userService: UserService
    let subscriptionService: SubscriptionService

    init(
        configuration: AppConfiguration,
        authSession: AuthSession,
        apiClient: APIClient,
        authService: AuthService,
        userService: UserService,
        subscriptionService: SubscriptionService
    ) {
        self.configuration = configuration
        self.authSession = authSession
        self.apiClient = apiClient
        self.authService = authService
        self.userService = userService
        self.subscriptionService = subscriptionService
    }
}

extension AppEnvironment {
    static let live: AppEnvironment = {
        let authSession = AuthSession(tokenStore: KeychainTokenStore(service: "PersonalEnglishAI"))
        var apiClient = APIClient(configuration: .development)
        apiClient.tokenProvider = { authSession.accessToken }

        return AppEnvironment(
            configuration: .development,
            authSession: authSession,
            apiClient: apiClient,
            authService: LiveAuthService(apiClient: apiClient),
            userService: LiveUserService(apiClient: apiClient),
            subscriptionService: LiveSubscriptionService(apiClient: apiClient)
        )
    }()

    static let preview = AppEnvironment(
        configuration: .preview,
        authSession: AuthSession(tokenStore: InMemoryTokenStore()),
        apiClient: APIClient(configuration: .preview),
        authService: MockAuthService(),
        userService: MockUserService(),
        subscriptionService: MockSubscriptionService()
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
