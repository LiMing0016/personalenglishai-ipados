import Foundation

struct LoginResponse: Decodable {
    let token: String?
    let userId: Int?
    let email: String?
}
