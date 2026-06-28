import XCTest
@testable import PersonalEnglishAI

final class AssistantSidebarItemTests: XCTestCase {
    func testLearningScenesUseProductOrder() {
        XCTAssertEqual(
            AssistantSidebarScene.allCases.map(\.title),
            ["AI 助手", "写作练习", "学习档案", "我的"]
        )
    }

    func testLearningScenesUseProductSubtitles() {
        XCTAssertEqual(
            AssistantSidebarScene.allCases.map(\.subtitle),
            ["翻译、语法、口语、问答", "作文草稿、评分、润色", "能力变化、目标、复盘", "账号、偏好、设置"]
        )
    }

    func testQuickTasksUseProductOrder() {
        XCTAssertEqual(
            AssistantSidebarQuickTask.allCases.map(\.title),
            ["翻译", "语法", "批改作文", "学习计划"]
        )
    }

    func testLearningScenesMapToAppTabs() {
        XCTAssertEqual(AssistantSidebarScene.assistant.destinationTab, .assistant)
        XCTAssertEqual(AssistantSidebarScene.writing.destinationTab, .writing)
        XCTAssertEqual(AssistantSidebarScene.archive.destinationTab, .dashboard)
        XCTAssertEqual(AssistantSidebarScene.profile.destinationTab, .profile)
    }

    func testSidebarLayoutDoesNotReserveWidthWhenCollapsed() {
        XCTAssertEqual(
            AssistantSidebarLayout.width(containerWidth: 1200, isCollapsed: true),
            0
        )
    }

    func testSidebarLayoutKeepsMinimumExpandedWidth() {
        XCTAssertEqual(
            AssistantSidebarLayout.width(containerWidth: 900, isCollapsed: false),
            340
        )
    }

    func testSidebarLayoutCapsExpandedWidth() {
        XCTAssertEqual(
            AssistantSidebarLayout.width(containerWidth: 1600, isCollapsed: false),
            430
        )
    }
}
