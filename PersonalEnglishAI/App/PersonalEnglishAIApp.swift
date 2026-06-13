import SwiftUI

@main
struct PersonalEnglishAIApp: App {
    private let appEnvironment = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appEnvironment, appEnvironment)
                .onOpenURL { url in
                    appEnvironment.authDeepLinkStore.handle(url)
                }
        }
    }
}
