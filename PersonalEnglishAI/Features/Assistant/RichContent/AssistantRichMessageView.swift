import SwiftUI
import UIKit

struct AssistantRichMessageView: View {
    let content: String
    @Environment(\.openURL) private var openURL
    @State private var contentHeight: CGFloat = 1
    @State private var renderError: String?

    private var blocks: [RichContentBlock] {
        RichContentParser.parse(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            MarkdownWebView(blocks: blocks, contentHeight: $contentHeight) { event in
                handle(event)
            }
            .frame(minHeight: 1)
            .frame(height: contentHeight)

            if let renderError {
                Label(renderError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func handle(_ event: RichContentWebEvent) {
        switch event {
        case .linkTapped(let url):
            openURL(url)
        case .renderError(let message):
            renderError = message
        case .heightChanged:
            break
        case .copyRequested(let text):
            UIPasteboard.general.string = text
        case .graphFullscreenRequested:
            break
        }
    }
}

struct AssistantRichMessageView_Previews: PreviewProvider {
    static var previews: some View {
        AssistantRichMessageView(content: """
        # 语法分析

        - **主语**：I
        - **谓语**：learned

        ```mermaid
        mindmap
          root((英语学习))
            阅读
              词汇
        ```
        """)
        .padding()
    }
}
