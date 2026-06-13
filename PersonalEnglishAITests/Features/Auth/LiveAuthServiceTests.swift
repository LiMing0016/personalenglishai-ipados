import Foundation
import XCTest
@testable import PersonalEnglishAI

final class LiveAuthServiceTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testLoginPostsCaptchaTokenAndReturnsEnvelopeToken() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/login")
            XCTAssertEqual(request.httpMethod, "POST")

            let body = try XCTUnwrap(request.peaiBodyData)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(payload?["email"], "u1@example.com")
            XCTAssertEqual(payload?["password"], "Abcd1234")
            XCTAssertEqual(payload?["captchaToken"], "cap-ok")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = Data("""
            {"code":"0","message":"OK","data":{"token":"access-1","tokenType":"Bearer","expiresIn":3600}}
            """.utf8)
            return (response, data)
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        let response = try await service.login(email: "u1@example.com", password: "Abcd1234", captchaToken: "cap-ok")

        XCTAssertEqual(response.token, "access-1")
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 3600)
    }

    func testFetchCaptchaReturnsEnvelopeData() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/captcha")
            XCTAssertEqual(request.httpMethod, "GET")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = Data("""
            {"code":"0","message":"OK","data":{"captchaId":"cap-1","bgImage":"data:image/png;base64,bg","pieceImage":"data:image/png;base64,piece"}}
            """.utf8)
            return (response, data)
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        let captcha = try await service.fetchCaptcha()

        XCTAssertEqual(captcha.captchaId, "cap-1")
        XCTAssertEqual(captcha.bgImage, "data:image/png;base64,bg")
        XCTAssertEqual(captcha.pieceImage, "data:image/png;base64,piece")
    }

    func testRegisterPostsEmailPasswordAndNickname() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/register")
            XCTAssertEqual(request.httpMethod, "POST")

            let body = try XCTUnwrap(request.peaiBodyData)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(payload?["email"], "new@example.com")
            XCTAssertEqual(payload?["password"], "Abcd1234")
            XCTAssertEqual(payload?["nickname"], "新同学")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 201,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = Data("""
            {"code":"0","message":"OK","data":{"userId":42}}
            """.utf8)
            return (response, data)
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        let response = try await service.register(email: "new@example.com", password: "Abcd1234", nickname: "新同学")

        XCTAssertEqual(response.userId, 42)
    }

    func testLogoutPostsLogoutEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/logout")
            XCTAssertEqual(request.httpMethod, "POST")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = Data("""
            {"code":"0","message":"OK","data":null}
            """.utf8)
            return (response, data)
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        try await service.logout()
    }

    func testRegisterFailureKeepsBackendMessage() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/register")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 409,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            let data = Data("""
            {"code":"409001","message":"邮箱已存在","data":null}
            """.utf8)
            return (response, data)
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        do {
            _ = try await service.register(email: "new@example.com", password: "Abcd1234", nickname: "新同学")
            XCTFail("Expected request failure")
        } catch APIError.requestFailed(let statusCode, let message) {
            XCTAssertEqual(statusCode, 409)
            XCTAssertEqual(message, "邮箱已存在")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testResendVerificationPostsEmail() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/resend-verification")
            XCTAssertEqual(request.httpMethod, "POST")

            let body = try XCTUnwrap(request.peaiBodyData)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(payload?["email"], "new@example.com")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"code":"0","message":"OK","data":null}"#.utf8))
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        try await service.resendVerification(email: "new@example.com")
    }

    func testVerifyEmailPassesTokenAsQueryItem() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/verify-email")
            XCTAssertEqual(request.url?.query, "token=verify-token")
            XCTAssertEqual(request.httpMethod, "GET")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"code":"0","message":"OK","data":{"status":"verified"}}"#.utf8))
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        let response = try await service.verifyEmail(token: "verify-token")

        XCTAssertEqual(response.status, "verified")
    }

    func testForgotPasswordPostsEmail() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/forgot-password")
            XCTAssertEqual(request.httpMethod, "POST")

            let body = try XCTUnwrap(request.peaiBodyData)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(payload?["email"], "student@example.com")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"code":"0","message":"OK","data":null}"#.utf8))
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        try await service.forgotPassword(email: "student@example.com")
    }

    func testValidateResetTokenPassesTokenAsQueryItem() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/reset-password/validate")
            XCTAssertEqual(request.url?.query, "token=reset-token")
            XCTAssertEqual(request.httpMethod, "GET")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"code":"0","message":"OK","data":{"status":"valid"}}"#.utf8))
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        let response = try await service.validateResetToken("reset-token")

        XCTAssertEqual(response.status, "valid")
    }

    func testResetPasswordPostsTokenAndPassword() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/reset-password")
            XCTAssertEqual(request.httpMethod, "POST")

            let body = try XCTUnwrap(request.peaiBodyData)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]
            XCTAssertEqual(payload?["token"], "reset-token")
            XCTAssertEqual(payload?["password"], "Newpass123")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"code":"0","message":"OK","data":null}"#.utf8))
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        try await service.resetPassword(token: "reset-token", password: "Newpass123")
    }

    func testRefreshPostsRefreshEndpointAndReturnsEnvelopeToken() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/auth/refresh")
            XCTAssertEqual(request.httpMethod, "POST")

            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"code":"0","message":"OK","data":{"token":"refreshed-token","tokenType":"Bearer","expiresIn":3600}}"#.utf8))
        }

        let service = LiveAuthService(apiClient: APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        ))

        let response = try await service.refresh()

        XCTAssertEqual(response.token, "refreshed-token")
    }

    func testAPIClientRefreshesTokenAndRetriesUnauthorizedRequest() async throws {
        struct ProtectedResponse: Decodable {
            let value: String
        }

        var currentToken = "expired-token"
        var requests: [URLRequest] = []
        var didRefresh = false

        MockURLProtocol.handler = { request in
            requests.append(request)

            if requests.count == 1 {
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer expired-token")
                let response = try XCTUnwrap(HTTPURLResponse(
                    url: XCTUnwrap(request.url),
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                ))
                return (response, Data(#"{"code":"401","message":"token expired","data":null}"#.utf8))
            }

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }

        var apiClient = APIClient(
            configuration: AppConfiguration(apiBaseURL: URL(string: "https://example.com/api")!, appName: "Test"),
            urlSession: .mocked
        )
        apiClient.tokenProvider = { currentToken }
        apiClient.tokenRefreshProvider = {
            didRefresh = true
            currentToken = "refreshed-token"
            return currentToken
        }

        let response = try await apiClient.send(
            APIEndpoint(method: .get, path: "/v1/protected"),
            responseType: ProtectedResponse.self
        )

        XCTAssertTrue(didRefresh)
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(response.value, "ok")
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            XCTFail("Missing mock URL handler")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    var peaiBodyData: Data? {
        if let httpBody {
            return httpBody
        }

        guard let httpBodyStream else {
            return nil
        }

        httpBodyStream.open()
        defer { httpBodyStream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while httpBodyStream.hasBytesAvailable {
            let read = httpBodyStream.read(buffer, maxLength: bufferSize)
            if read <= 0 {
                break
            }
            data.append(buffer, count: read)
        }

        return data
    }
}

private extension URLSession {
    static var mocked: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
