import XCTest
@testable import PersonalEnglishAI

final class AuthDeepLinkTests: XCTestCase {
    func testParsesVerifyEmailTokenFromCustomScheme() throws {
        let url = try XCTUnwrap(URL(string: "personalenglishai://verify-email?token=verify-123"))

        let action = AuthDeepLinkAction(url: url)

        XCTAssertEqual(action, .verifyEmail(token: "verify-123"))
    }

    func testParsesResetPasswordTokenFromWebLink() throws {
        let url = try XCTUnwrap(URL(string: "https://personalenglish.ai/reset-password?token=reset-123"))

        let action = AuthDeepLinkAction(url: url)

        XCTAssertEqual(action, .resetPassword(token: "reset-123"))
    }

    func testIgnoresUnsupportedAuthDeepLink() throws {
        let url = try XCTUnwrap(URL(string: "personalenglishai://dashboard"))

        let action = AuthDeepLinkAction(url: url)

        XCTAssertNil(action)
    }
}
