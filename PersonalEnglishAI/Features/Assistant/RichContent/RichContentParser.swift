import Foundation

enum RichContentParser {
    static func parse(_ content: String) -> [RichContentBlock] {
        var blocks: [RichContentBlock] = []
        var markdownBuffer: [String] = []
        var fenceBuffer: [String] = []
        var fenceLanguage: String?

        for line in content.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines) {
            if let language = openingFenceLanguage(from: line), fenceLanguage == nil {
                flushMarkdownBuffer(&markdownBuffer, into: &blocks)
                fenceLanguage = language
                fenceBuffer = []
                continue
            }

            if isClosingFence(line), let language = fenceLanguage {
                appendFenceBlock(
                    language: language,
                    body: normalized(fenceBuffer.joined(separator: "\n")),
                    rawLines: fenceBuffer,
                    into: &blocks
                )
                fenceLanguage = nil
                fenceBuffer = []
                continue
            }

            if fenceLanguage != nil {
                fenceBuffer.append(line)
            } else {
                markdownBuffer.append(line)
            }
        }

        if let language = fenceLanguage {
            markdownBuffer.append("```\(language)")
            markdownBuffer.append(contentsOf: fenceBuffer)
        }

        flushMarkdownBuffer(&markdownBuffer, into: &blocks)
        return blocks
    }

    private static func openingFenceLanguage(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```"), trimmed.count > 3 else {
            return nil
        }
        return String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func isClosingFence(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines) == "```"
    }

    private static func appendFenceBlock(
        language: String,
        body: String,
        rawLines: [String],
        into blocks: inout [RichContentBlock]
    ) {
        switch language {
        case "mermaid":
            blocks.append(.mermaid(body))
        case "graph-json":
            blocks.append(.graphJSON(body))
        default:
            let raw = normalized((["```\(language)"] + rawLines + ["```"]).joined(separator: "\n"))
            if !raw.isEmpty {
                blocks.append(.markdown(raw))
            }
        }
    }

    private static func flushMarkdownBuffer(_ buffer: inout [String], into blocks: inout [RichContentBlock]) {
        let markdown = normalized(buffer.joined(separator: "\n"))
        if !markdown.isEmpty {
            blocks.append(.markdown(markdown))
        }
        buffer.removeAll()
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
