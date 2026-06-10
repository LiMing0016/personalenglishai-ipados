import SwiftUI

struct WritingResultView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Score")
                .font(Typography.sectionTitle)

            EmptyStateView(
                systemImage: "chart.bar.doc.horizontal",
                title: "No score yet",
                message: "Submit an essay after API integration to see feedback here."
            )

            PrimaryButton(title: "Evaluate", systemImage: "checkmark.seal", action: {})
                .accessibilityIdentifier("writing.evaluate")
        }
        .padding(Spacing.md)
        .background(Color.peaiSurface)
    }
}

struct WritingResultView_Previews: PreviewProvider {
    static var previews: some View {
        WritingResultView()
    }
}
