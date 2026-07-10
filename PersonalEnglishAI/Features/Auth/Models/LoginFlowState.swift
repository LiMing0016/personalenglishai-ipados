import CoreGraphics
import Foundation

struct LoginFlowState: Equatable {
    var captchaChallenge: CaptchaChallenge?
    var sliderX: CGFloat
    var captchaErrorMessage: String?
    var captchaStatusMessage: String? = nil
    var errorMessage: String?
    var pendingVerificationEmail: String?

    mutating func markCaptchaVerifiedForLoginSubmission() {
        captchaChallenge = nil
        sliderX = 0
        captchaErrorMessage = nil
        captchaStatusMessage = nil
    }

    mutating func markCaptchaVerifiedAndLoginSubmitting(message: String) {
        captchaErrorMessage = nil
        captchaStatusMessage = message
        errorMessage = nil
    }

    mutating func markLoginSubmissionSucceeded() {
        captchaChallenge = nil
        sliderX = 0
        captchaErrorMessage = nil
        captchaStatusMessage = nil
        errorMessage = nil
        pendingVerificationEmail = nil
    }

    mutating func markCaptchaVerificationFailed(
        message: String,
        refreshedChallenge: CaptchaChallenge
    ) {
        captchaChallenge = refreshedChallenge
        sliderX = 0
        captchaErrorMessage = message
        captchaStatusMessage = nil
    }

    mutating func markLoginSubmissionFailed(
        message: String,
        pendingVerificationEmail: String?
    ) {
        captchaChallenge = nil
        sliderX = 0
        captchaErrorMessage = nil
        captchaStatusMessage = nil
        errorMessage = message
        self.pendingVerificationEmail = pendingVerificationEmail
    }
}
