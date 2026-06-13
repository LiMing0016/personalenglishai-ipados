import SwiftUI

struct WritingResultView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("评分")
                .font(Typography.sectionTitle)

            EmptyStateView(
                systemImage: "chart.bar.doc.horizontal",
                title: "还没有评分",
                message: "后续接入 API 后，提交作文即可在这里查看反馈。"
            )

            PrimaryButton(title: "开始评分", systemImage: "checkmark.seal", action: {})
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
