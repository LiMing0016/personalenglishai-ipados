import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button("Retry", action: retry)
                    .accessibilityIdentifier("error.retry")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorStateView(title: "Something went wrong", message: "Please try again.", retry: {})
    }
}
