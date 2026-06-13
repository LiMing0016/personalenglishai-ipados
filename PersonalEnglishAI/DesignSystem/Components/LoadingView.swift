import SwiftUI

struct LoadingView: View {
    let title: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text(title)
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(title: "加载中")
    }
}
