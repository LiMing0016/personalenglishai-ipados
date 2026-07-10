import XCTest
@testable import PersonalEnglishAI

final class LoginFlowStateTests: XCTestCase {
    func testLoginSubmissionFailureDoesNotReopenCaptchaAfterCaptchaVerified() {
        let challenge = CaptchaChallenge(captchaId: "captcha-1", bgImage: "bg", pieceImage: "piece")
        var state = LoginFlowState(
            captchaChallenge: challenge,
            sliderX: 120,
            captchaErrorMessage: nil,
            errorMessage: nil,
            pendingVerificationEmail: nil
        )

        state.markCaptchaVerifiedForLoginSubmission()
        state.markLoginSubmissionFailed(message: "账号或密码不正确。", pendingVerificationEmail: nil)

        XCTAssertNil(state.captchaChallenge)
        XCTAssertNil(state.captchaErrorMessage)
        XCTAssertEqual(state.sliderX, 0)
        XCTAssertEqual(state.errorMessage, "账号或密码不正确。")
        XCTAssertNil(state.pendingVerificationEmail)
    }

    func testCaptchaVerifiedKeepsOverlayVisibleWhileLoginIsSubmitting() {
        let challenge = CaptchaChallenge(captchaId: "captcha-1", bgImage: "bg", pieceImage: "piece")
        var state = LoginFlowState(
            captchaChallenge: challenge,
            sliderX: 120,
            captchaErrorMessage: "旧错误",
            errorMessage: "旧登录错误",
            pendingVerificationEmail: nil
        )

        state.markCaptchaVerifiedAndLoginSubmitting(message: "验证通过，正在登录...")

        XCTAssertEqual(state.captchaChallenge, challenge)
        XCTAssertEqual(state.sliderX, 120)
        XCTAssertNil(state.captchaErrorMessage)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.captchaStatusMessage, "验证通过，正在登录...")
    }

    func testLoginSubmissionSuccessClearsCaptchaSubmittingState() {
        var state = LoginFlowState(
            captchaChallenge: CaptchaChallenge(captchaId: "captcha-1", bgImage: "bg", pieceImage: "piece"),
            sliderX: 120,
            captchaErrorMessage: nil,
            captchaStatusMessage: "验证通过，正在登录...",
            errorMessage: nil,
            pendingVerificationEmail: "user@example.com"
        )

        state.markLoginSubmissionSucceeded()

        XCTAssertNil(state.captchaChallenge)
        XCTAssertEqual(state.sliderX, 0)
        XCTAssertNil(state.captchaErrorMessage)
        XCTAssertNil(state.captchaStatusMessage)
        XCTAssertNil(state.errorMessage)
        XCTAssertNil(state.pendingVerificationEmail)
    }

    func testCaptchaVerificationFailureRefreshesCaptchaAndKeepsErrorInCaptchaOverlay() {
        var state = LoginFlowState(
            captchaChallenge: CaptchaChallenge(captchaId: "captcha-1", bgImage: "bg", pieceImage: "piece"),
            sliderX: 120,
            captchaErrorMessage: nil,
            errorMessage: nil,
            pendingVerificationEmail: nil
        )
        let refreshedChallenge = CaptchaChallenge(captchaId: "captcha-2", bgImage: "new-bg", pieceImage: "new-piece")

        state.markCaptchaVerificationFailed(message: "验证失败，已刷新验证码。", refreshedChallenge: refreshedChallenge)

        XCTAssertEqual(state.captchaChallenge, refreshedChallenge)
        XCTAssertEqual(state.captchaErrorMessage, "验证失败，已刷新验证码。")
        XCTAssertEqual(state.sliderX, 0)
        XCTAssertNil(state.captchaStatusMessage)
        XCTAssertNil(state.errorMessage)
    }

    func testLoginSubmissionFailureClearsCaptchaSubmittingState() {
        var state = LoginFlowState(
            captchaChallenge: CaptchaChallenge(captchaId: "captcha-1", bgImage: "bg", pieceImage: "piece"),
            sliderX: 120,
            captchaErrorMessage: nil,
            errorMessage: nil,
            pendingVerificationEmail: nil
        )
        state.markCaptchaVerifiedAndLoginSubmitting(message: "验证通过，正在登录...")

        state.markLoginSubmissionFailed(message: "账号或密码不正确。", pendingVerificationEmail: nil)

        XCTAssertNil(state.captchaChallenge)
        XCTAssertNil(state.captchaStatusMessage)
        XCTAssertNil(state.captchaErrorMessage)
        XCTAssertEqual(state.sliderX, 0)
        XCTAssertEqual(state.errorMessage, "账号或密码不正确。")
    }
}
