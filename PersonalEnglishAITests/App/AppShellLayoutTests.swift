import XCTest
@testable import PersonalEnglishAI

final class AppShellLayoutTests: XCTestCase {
    func testCollapsedSidebarGivesContentFullWorkspaceWidth() {
        XCTAssertEqual(
            AppShellLayout.contentWidth(containerWidth: 1366, isSidebarCollapsed: true),
            1366
        )
    }

    func testExpandedSidebarOnlyReservesSharedWorkspaceSidebar() {
        let containerWidth: CGFloat = 1366
        let sidebarWidth = AssistantSidebarLayout.width(
            containerWidth: containerWidth,
            isCollapsed: false
        )

        XCTAssertEqual(
            AppShellLayout.contentWidth(containerWidth: containerWidth, isSidebarCollapsed: false),
            containerWidth - sidebarWidth - AppShellLayout.separatorWidth
        )
    }

    func testCollapsedWritingPageKeepsWideHubRules() {
        let contentWidth = AppShellLayout.contentWidth(containerWidth: 1366, isSidebarCollapsed: true)
        let writingLayout = WritingHubLayout(containerWidth: contentWidth)

        XCTAssertEqual(writingLayout.documentColumnCount, 2)
        XCTAssertTrue(writingLayout.showsDailyPromptAside)
        XCTAssertTrue(writingLayout.showsHeroIllustration)
    }
}
