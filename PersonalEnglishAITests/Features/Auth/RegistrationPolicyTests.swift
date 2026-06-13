import XCTest
@testable import PersonalEnglishAI

final class RegistrationPolicyTests: XCTestCase {
    func testRegistrationCannotSubmitUntilLegalTermsAreAccepted() {
        XCTAssertFalse(RegistrationPolicy.canSubmit(
            nickname: "新同学",
            email: "student@example.com",
            password: "Abcd1234",
            confirmPassword: "Abcd1234",
            acceptedLegalTerms: false
        ))

        XCTAssertTrue(RegistrationPolicy.canSubmit(
            nickname: "新同学",
            email: "student@example.com",
            password: "Abcd1234",
            confirmPassword: "Abcd1234",
            acceptedLegalTerms: true
        ))
    }
}
