import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Sign in")
                    .font(Typography.pageTitle)
                Text("Use your existing Personal English AI account.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: Spacing.md) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("auth.email")

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .accessibilityIdentifier("auth.password")

                PrimaryButton(title: "Sign in", systemImage: "arrow.right", action: {})
                    .disabled(!Validation.isNonEmpty(email) || !Validation.isNonEmpty(password))
                    .accessibilityIdentifier("auth.signIn")
            }
            .textFieldStyle(.roundedBorder)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 440)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
