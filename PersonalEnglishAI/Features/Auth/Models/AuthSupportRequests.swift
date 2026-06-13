import Foundation

struct EmailOnlyRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let password: String
}
