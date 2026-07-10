import XCTest
@testable import PersonalEnglishAI

final class AppTabTests: XCTestCase {
    func testPrimaryTabsStartWithAssistant() {
        XCTAssertEqual(AppTab.primaryTabs.first, .assistant)
    }

    func testPrimaryTabsExcludeDashboard() {
        XCTAssertFalse(AppTab.primaryTabs.contains(.dashboard))
    }

    func testPrimaryTabsKeepMainProductAreas() {
        XCTAssertEqual(AppTab.primaryTabs, [.assistant, .writing, .profile])
    }
}
