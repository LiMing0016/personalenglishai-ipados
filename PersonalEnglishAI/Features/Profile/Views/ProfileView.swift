import SwiftUI

struct ProfileView: View {
    private let profile = MeProfile.preview
    private let subscription = SubscriptionStatus.preview
    private let ability = AbilityProfile.preview

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("Email", value: profile.email ?? "Not signed in")
                LabeledContent("Nickname", value: profile.nickname ?? "Not set")
                LabeledContent("Study stage", value: profile.studyStage ?? "Not set")
            }

            Section("Subscription") {
                LabeledContent("Plan", value: subscription.planName)
                LabeledContent("Token remaining", value: "\(subscription.tokenRemaining)")
            }

            Section("Ability") {
                LabeledContent("Grammar", value: scoreText(ability.grammarScore))
                LabeledContent("Vocabulary", value: scoreText(ability.vocabularyScore))
                LabeledContent("Coherence", value: scoreText(ability.coherenceScore))
            }
        }
        .navigationTitle("Profile")
        .accessibilityIdentifier("profile.root")
    }

    private func scoreText(_ score: Double?) -> String {
        guard let score else { return "Not enough data" }
        return String(format: "%.1f", score)
    }
}

struct ProfileContextView: View {
    var body: some View {
        List {
            Section("Profile") {
                Label("Account", systemImage: "person")
                Label("Subscription", systemImage: "creditcard")
                Label("Ability", systemImage: "chart.xyaxis.line")
            }
        }
        .navigationTitle("Profile")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
