import XCTest
@testable import PersonalEnglishAI

final class WritingHubStateTests: XCTestCase {
    func testDefaultHubOpensPracticeSection() {
        let state = WritingHubState(documents: WritingDocumentSummary.samples)

        XCTAssertEqual(state.selectedSection, .practice)
        XCTAssertEqual(state.filteredDocuments.count, WritingDocumentSummary.samples.count)
    }

    func testSearchAndModeFilterDocuments() {
        var state = WritingHubState(documents: WritingDocumentSummary.samples)

        state.searchText = "城市"
        XCTAssertEqual(state.filteredDocuments.map(\.title), ["城市生活"])

        state.searchText = ""
        state.modeFilter = .exam
        XCTAssertTrue(state.filteredDocuments.allSatisfy { $0.mode == .exam })
        XCTAssertEqual(state.filteredDocuments.map(\.title), ["科技与教育"])
    }

    func testDocumentsAreSortedByRecentUpdate() {
        let state = WritingHubState(documents: WritingDocumentSummary.samples)

        XCTAssertEqual(state.filteredDocuments.map(\.title), ["科技与教育", "城市生活", "自由写作 2026-06-24"])
    }

    func testDashboardSummaryUsesLatestScores() {
        let state = WritingHubState(documents: WritingDocumentSummary.samples)

        XCTAssertEqual(state.dashboardSummary.documentCount, 3)
        XCTAssertEqual(state.dashboardSummary.pendingReviewCount, 1)
        XCTAssertEqual(state.dashboardSummary.averageScoreText, "82")
        XCTAssertEqual(state.dashboardSummary.bestScoreText, "88")
    }

    func testHubLayoutUsesCompactRulesWhenPrimaryRailReducesAvailableWidth() {
        let layout = WritingHubLayout(containerWidth: 860)

        XCTAssertEqual(layout.documentColumnCount, 1)
        XCTAssertFalse(layout.showsDailyPromptAside)
        XCTAssertFalse(layout.showsHeroIllustration)
        XCTAssertLessThanOrEqual(layout.searchFieldWidth, 280)
    }

    func testHubLayoutKeepsRichWideRulesForLandscapeWorkspace() {
        let layout = WritingHubLayout(containerWidth: 1280)

        XCTAssertEqual(layout.documentColumnCount, 2)
        XCTAssertTrue(layout.showsDailyPromptAside)
        XCTAssertTrue(layout.showsHeroIllustration)
        XCTAssertEqual(layout.dailyPromptWidth, 380)
    }
}
