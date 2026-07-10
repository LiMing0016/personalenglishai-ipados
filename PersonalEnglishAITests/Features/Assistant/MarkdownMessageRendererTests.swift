import XCTest
@testable import PersonalEnglishAI

final class MarkdownMessageRendererTests: XCTestCase {
    func testAttributedStringRemovesMarkdownControlSyntax() throws {
        let markdown = """
        # 你好呀

        我可以帮你做这些英语学习任务：

        - **翻译**：中英互译
        - **语法**：分析句子结构
        """

        let rendered = MarkdownMessageRenderer.attributedString(from: markdown)
        let plainText = String(rendered.characters)

        XCTAssertTrue(plainText.contains("你好呀"))
        XCTAssertTrue(plainText.contains("翻译"))
        XCTAssertTrue(plainText.contains("语法"))
        XCTAssertFalse(plainText.contains("#"))
        XCTAssertFalse(plainText.contains("**"))
    }

    func testAttributedStringFallsBackToPlainTextForInvalidMarkdown() throws {
        let invalidMarkdown = "This [link](not a valid url"

        let rendered = MarkdownMessageRenderer.attributedString(from: invalidMarkdown)
        let plainText = String(rendered.characters)

        XCTAssertEqual(plainText, invalidMarkdown)
    }
}
