import Combine
import Foundation

enum AuthDeepLinkAction: Equatable, Identifiable {
    case verifyEmail(token: String)
    case resetPassword(token: String)

    var id: String {
        switch self {
        case let .verifyEmail(token):
            "verify-email-\(token)"
        case let .resetPassword(token):
            "reset-password-\(token)"
        }
    }

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty else {
            return nil
        }

        let pathParts = components.path
            .split(separator: "/")
            .map(String.init)

        let routeParts = ([components.host].compactMap { $0 } + pathParts)
            .map { $0.lowercased() }

        if routeParts.contains("verify-email") {
            self = .verifyEmail(token: token)
        } else if routeParts.contains("reset-password") {
            self = .resetPassword(token: token)
        } else {
            return nil
        }
    }
}

final class AuthDeepLinkStore: ObservableObject {
    @Published private(set) var pendingAction: AuthDeepLinkAction?

    func handle(_ url: URL) {
        pendingAction = AuthDeepLinkAction(url: url)
    }

    func clearPendingAction() {
        pendingAction = nil
    }
}
