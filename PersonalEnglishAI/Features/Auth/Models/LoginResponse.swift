import Foundation

struct LoginResponse: Decodable {
    let token: String?
    let tokenType: String?
    let expiresIn: Int?
}
