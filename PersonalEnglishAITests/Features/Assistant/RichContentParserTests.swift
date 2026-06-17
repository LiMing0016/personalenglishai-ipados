import XCTest
@testable import PersonalEnglishAI

final class RichContentParserTests: XCTestCase {
    func testPlainMarkdownBecomesSingleMarkdownBlock() {
        let blocks = RichContentParser.parse("""
        # 语法分析

        - **主语**：I
        - **谓语**：learned
        """)

        XCTAssertEqual(blocks, [
            .markdown("# 语法分析\n\n- **主语**：I\n- **谓语**：learned")
        ])
    }

    func testMermaidFenceBecomesMermaidBlock() {
        let blocks = RichContentParser.parse("""
        下面是思维导图：

        ```mermaid
        mindmap
          root((英语学习))
            阅读
        ```

        以上是结构。
        """)

        XCTAssertEqual(blocks, [
            .markdown("下面是思维导图："),
            .mermaid("mindmap\n  root((英语学习))\n    阅读"),
            .markdown("以上是结构。")
        ])
    }

    func testGraphJSONFenceBecomesGraphJSONBlock() {
        let blocks = RichContentParser.parse("""
        ```graph-json
        {
          "type": "force-tree",
          "nodes": [{"id": "root", "label": "英语学习"}],
          "edges": []
        }
        ```
        """)

        XCTAssertEqual(blocks, [
            .graphJSON("""
            {
              "type": "force-tree",
              "nodes": [{"id": "root", "label": "英语学习"}],
              "edges": []
            }
            """)
        ])
    }

    func testUnknownFenceStaysInsideMarkdownBlock() {
        let blocks = RichContentParser.parse("""
        ```swift
        let topic = "English"
        ```
        """)

        XCTAssertEqual(blocks, [
            .markdown("```swift\nlet topic = \"English\"\n```")
        ])
    }
}
