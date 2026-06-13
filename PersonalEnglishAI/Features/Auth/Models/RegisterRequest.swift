import Foundation

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let nickname: String
}
