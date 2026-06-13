import Foundation
import UIKit

protocol AuthService {
    func fetchCaptcha() async throws -> CaptchaChallenge
    func verifyCaptcha(captchaId: String, x: Int) async throws -> CaptchaVerification
    func login(email: String, password: String, captchaToken: String) async throws -> LoginResponse
    func register(email: String, password: String, nickname: String) async throws -> RegisterResponse
    func logout() async throws
    func resendVerification(email: String) async throws
    func verifyEmail(token: String) async throws -> AuthStatusResponse
    func forgotPassword(email: String) async throws
    func validateResetToken(_ token: String) async throws -> AuthStatusResponse
    func resetPassword(token: String, password: String) async throws
    func refresh() async throws -> LoginResponse
}

struct LiveAuthService: AuthService {
    let apiClient: APIClient

    func fetchCaptcha() async throws -> CaptchaChallenge {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .get, path: "/v1/auth/captcha"),
            responseType: APIEnvelope<CaptchaChallenge>.self
        )

        guard let challenge = envelope.data else {
            throw APIError.decodingFailed
        }

        return challenge
    }

    func verifyCaptcha(captchaId: String, x: Int) async throws -> CaptchaVerification {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/captcha/verify"),
            body: CaptchaVerifyRequest(captchaId: captchaId, x: x),
            responseType: APIEnvelope<CaptchaVerification>.self
        )

        guard let verification = envelope.data else {
            throw APIError.decodingFailed
        }

        return verification
    }

    func login(email: String, password: String, captchaToken: String) async throws -> LoginResponse {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/login"),
            body: LoginRequest(email: email, password: password, captchaToken: captchaToken),
            responseType: APIEnvelope<LoginResponse>.self
        )

        guard let response = envelope.data, response.token?.isEmpty == false else {
            throw APIError.missingToken
        }

        return response
    }

    func register(email: String, password: String, nickname: String) async throws -> RegisterResponse {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/register"),
            body: RegisterRequest(email: email, password: password, nickname: nickname),
            responseType: APIEnvelope<RegisterResponse>.self
        )

        guard let response = envelope.data else {
            throw APIError.decodingFailed
        }

        return response
    }

    func logout() async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/logout"),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    func resendVerification(email: String) async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/resend-verification"),
            body: EmailOnlyRequest(email: email),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    func verifyEmail(token: String) async throws -> AuthStatusResponse {
        let envelope = try await apiClient.send(
            APIEndpoint(
                method: .get,
                path: "/v1/auth/verify-email",
                queryItems: [URLQueryItem(name: "token", value: token)]
            ),
            responseType: APIEnvelope<AuthStatusResponse>.self
        )

        guard let response = envelope.data else {
            throw APIError.decodingFailed
        }

        return response
    }

    func forgotPassword(email: String) async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/forgot-password"),
            body: EmailOnlyRequest(email: email),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    func validateResetToken(_ token: String) async throws -> AuthStatusResponse {
        let envelope = try await apiClient.send(
            APIEndpoint(
                method: .get,
                path: "/v1/auth/reset-password/validate",
                queryItems: [URLQueryItem(name: "token", value: token)]
            ),
            responseType: APIEnvelope<AuthStatusResponse>.self
        )

        guard let response = envelope.data else {
            throw APIError.decodingFailed
        }

        return response
    }

    func resetPassword(token: String, password: String) async throws {
        _ = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/reset-password"),
            body: ResetPasswordRequest(token: token, password: password),
            responseType: APIEnvelope<EmptyAPIResponse>.self
        )
    }

    func refresh() async throws -> LoginResponse {
        let envelope = try await apiClient.send(
            APIEndpoint(method: .post, path: "/v1/auth/refresh"),
            responseType: APIEnvelope<LoginResponse>.self,
            allowsTokenRefresh: false
        )

        guard let response = envelope.data, response.token?.isEmpty == false else {
            throw APIError.missingToken
        }

        return response
    }
}

struct MockAuthService: AuthService {
    func fetchCaptcha() async throws -> CaptchaChallenge {
        CaptchaChallenge(
            captchaId: "preview-captcha",
            bgImage: Self.previewBackgroundImage,
            pieceImage: Self.previewPieceImage
        )
    }

    func verifyCaptcha(captchaId: String, x: Int) async throws -> CaptchaVerification {
        CaptchaVerification(verified: true, captchaToken: "preview-captcha-token")
    }

    func login(email: String, password: String, captchaToken: String) async throws -> LoginResponse {
        LoginResponse(token: "preview-token", tokenType: "Bearer", expiresIn: 3600)
    }

    func register(email: String, password: String, nickname: String) async throws -> RegisterResponse {
        RegisterResponse(userId: 1)
    }

    func logout() async throws {}

    func resendVerification(email: String) async throws {}

    func verifyEmail(token: String) async throws -> AuthStatusResponse {
        AuthStatusResponse(status: "verified")
    }

    func forgotPassword(email: String) async throws {}

    func validateResetToken(_ token: String) async throws -> AuthStatusResponse {
        AuthStatusResponse(status: "valid")
    }

    func resetPassword(token: String, password: String) async throws {}

    func refresh() async throws -> LoginResponse {
        LoginResponse(token: "preview-token", tokenType: "Bearer", expiresIn: 3600)
    }

    private static var previewBackgroundImage: String {
        makePNGDataURL(size: CGSize(width: 300, height: 150), opaque: true) { context, rect in
            let colors = [
                UIColor(red: 0.08, green: 0.18, blue: 0.34, alpha: 1).cgColor,
                UIColor(red: 0.11, green: 0.42, blue: 0.64, alpha: 1).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
            context.drawLinearGradient(gradient!, start: rect.origin, end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])

            for index in 0..<14 {
                let x = CGFloat((index * 37) % 300)
                let y = CGFloat((index * 29) % 150)
                let size = CGFloat(24 + (index % 4) * 12)
                context.setFillColor(UIColor.white.withAlphaComponent(index.isMultiple(of: 2) ? 0.10 : 0.06).cgColor)
                context.fillEllipse(in: CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size))
            }

            context.setStrokeColor(UIColor.white.withAlphaComponent(0.24).cgColor)
            context.setLineWidth(2)
            for y in stride(from: CGFloat(24), through: 126, by: 34) {
                context.move(to: CGPoint(x: 18, y: y))
                context.addLine(to: CGPoint(x: 282, y: y + 18))
                context.strokePath()
            }

            let gap = UIBezierPath(roundedRect: CGRect(x: 82, y: 48, width: 50, height: 54), cornerRadius: 12)
            context.setFillColor(UIColor.black.withAlphaComponent(0.28).cgColor)
            context.addPath(gap.cgPath)
            context.fillPath()
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.42).cgColor)
            context.addPath(gap.cgPath)
            context.strokePath()
        }
    }

    private static var previewPieceImage: String {
        makePNGDataURL(size: CGSize(width: 50, height: 150), opaque: false) { context, _ in
            let pieceRect = CGRect(x: 0, y: 48, width: 50, height: 54)
            let path = UIBezierPath(roundedRect: pieceRect, cornerRadius: 12)
            context.addPath(path.cgPath)
            context.clip()

            let colors = [
                UIColor(red: 0.32, green: 0.70, blue: 1.0, alpha: 0.96).cgColor,
                UIColor(red: 0.18, green: 0.38, blue: 0.72, alpha: 0.96).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
            context.drawLinearGradient(gradient!, start: pieceRect.origin, end: CGPoint(x: pieceRect.maxX, y: pieceRect.maxY), options: [])

            context.resetClip()
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.60).cgColor)
            context.setLineWidth(2)
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }

    private static func makePNGDataURL(
        size: CGSize,
        opaque: Bool,
        draw: (CGContext, CGRect) -> Void
    ) -> String {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { rendererContext in
            draw(rendererContext.cgContext, CGRect(origin: .zero, size: size))
        }

        let base64 = image.pngData()?.base64EncodedString() ?? ""
        return "data:image/png;base64,\(base64)"
    }
}
