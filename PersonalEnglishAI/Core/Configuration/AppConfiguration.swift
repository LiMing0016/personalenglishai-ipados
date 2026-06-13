import Foundation

struct AppConfiguration: Equatable {
    let apiBaseURL: URL
    let appName: String

    static let development = AppConfiguration(
        apiBaseURL: URL(string: "http://127.0.0.1:18080/api")!,
        appName: "Personal English AI"
    )

    static let preview = AppConfiguration(
        apiBaseURL: URL(string: "https://api.example.com/api")!,
        appName: "Personal English AI"
    )
}
