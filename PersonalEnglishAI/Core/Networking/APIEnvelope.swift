import Foundation

struct APIEnvelope<Value: Decodable>: Decodable {
    let code: String?
    let message: String?
    let data: Value?
}
