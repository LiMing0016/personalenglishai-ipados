import Foundation

struct CaptchaChallenge: Decodable, Equatable {
    let captchaId: String
    let bgImage: String
    let pieceImage: String
}

struct CaptchaVerifyRequest: Encodable {
    let captchaId: String
    let x: Int
}

struct CaptchaVerification: Decodable, Equatable {
    let verified: Bool
    let captchaToken: String?
}
