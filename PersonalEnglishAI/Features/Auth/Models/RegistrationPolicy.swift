import Foundation

enum RegistrationPolicy {
    static func canSubmit(
        nickname: String,
        email: String,
        password: String,
        confirmPassword: String,
        acceptedLegalTerms: Bool
    ) -> Bool {
        acceptedLegalTerms &&
            Validation.isNonEmpty(nickname) &&
            Validation.isNonEmpty(email) &&
            Validation.isNonEmpty(password) &&
            Validation.isNonEmpty(confirmPassword)
    }
}
