import Foundation
import SwiftUI

struct AppEnvironment: @unchecked Sendable {
    let configuration: AppConfiguration
    let authSession: AuthSession
    let apiClient: APIClient

    init(
        configuration: AppConfiguration,
        authSession: AuthSession,
        apiClient: APIClient
    ) {
        self.configuration = configuration
        self.authSession = authSession
        self.apiClient = apiClient
    }
}

extension AppEnvironment {
    static let live = AppEnvironment(
        configuration: .development,
        authSession: AuthSession(tokenStore: KeychainTokenStore(service: "PersonalEnglishAI")),
        apiClient: APIClient(configuration: .development)
    )

    static let preview = AppEnvironment(
        configuration: .preview,
        authSession: AuthSession(tokenStore: InMemoryTokenStore()),
        apiClient: APIClient(configuration: .preview)
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
