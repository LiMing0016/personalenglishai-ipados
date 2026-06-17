import Foundation
import SwiftUI

enum MarkdownMessageRenderer {
    static func attributedString(from markdown: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            )
        } catch {
            return AttributedString(markdown)
        }
    }
}

struct MarkdownMessageText: View {
    let markdown: String

    var body: some View {
        Text(MarkdownMessageRenderer.attributedString(from: markdown))
            .font(.body)
            .lineSpacing(4)
            .textSelection(.enabled)
            .tint(Color.peaiAccent)
    }
}
