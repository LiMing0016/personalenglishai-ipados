import XCTest
@testable import PersonalEnglishAI

final class WritingDocumentStateTests: XCTestCase {
    func testMetricsCountsWordsSentencesAndParagraphs() {
        let metrics = WritingDocumentMetrics(
            text: """
            I like learning English. It helps me think clearly.

            Writing every day is useful!
            """
        )

        XCTAssertEqual(metrics.words, 14)
        XCTAssertEqual(metrics.sentences, 3)
        XCTAssertEqual(metrics.paragraphs, 2)
        XCTAssertEqual(metrics.displayText, "14 词 · 3 句 · 2 段")
    }

    func testGoalProgressCapsAtCompletion() {
        let short = WritingGoalProgress(metrics: WritingDocumentMetrics(text: "one two"), targetWordCount: 4)
        XCTAssertEqual(short.ratio, 0.5)
        XCTAssertEqual(short.displayText, "2 / 4 词")
        XCTAssertFalse(short.isComplete)

        let complete = WritingGoalProgress(metrics: WritingDocumentMetrics(text: "one two three four five"), targetWordCount: 4)
        XCTAssertEqual(complete.ratio, 1)
        XCTAssertEqual(complete.displayText, "5 / 4 词")
        XCTAssertTrue(complete.isComplete)
    }

    func testSaveStatusTextReflectsDirtyAndSavedStates() {
        XCTAssertEqual(WritingSaveStatus.dirty.displayText, "正在编辑")
        XCTAssertEqual(WritingSaveStatus.saved.displayText, "已保存")
    }

    func testStarterActionsExposeLearningAssetEntryPoints() {
        XCTAssertEqual(
            WritingStarterAction.primary.map(\.title),
            ["从模板开始", "使用素材库", "粘贴考试题目", "继续最近草稿"]
        )
        XCTAssertEqual(WritingStarterAction.primary.first?.toolRawValue, "template")
        XCTAssertEqual(WritingStarterAction.primary[1].toolRawValue, "material")
    }
}
