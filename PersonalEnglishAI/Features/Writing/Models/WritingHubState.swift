import CoreGraphics
import Foundation

enum WritingHubSection: String, CaseIterable, Identifiable {
    case practice
    case dashboard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .practice:
            "写作练习"
        case .dashboard:
            "Dashboard"
        }
    }
}

enum WritingDocumentModeFilter: String, CaseIterable, Identifiable {
    case all
    case free
    case exam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "全部"
        case .free:
            "自由"
        case .exam:
            "考试"
        }
    }

    func includes(_ mode: WritingMode) -> Bool {
        switch self {
        case .all:
            true
        case .free:
            mode == .free
        case .exam:
            mode == .exam
        }
    }
}

enum WritingDocumentStatus: String, Hashable {
    case draft
    case pendingReview
    case reviewed

    var title: String {
        switch self {
        case .draft:
            "草稿"
        case .pendingReview:
            "待评分"
        case .reviewed:
            "已评分"
        }
    }
}

struct WritingDocumentSummary: Identifiable, Hashable {
    let id: String
    let title: String
    let preview: String
    let mode: WritingMode
    let status: WritingDocumentStatus
    let updatedAt: Date
    let latestScore: Int?
    let evaluationCount: Int
    let revisionCount: Int

    static let samples = [
        WritingDocumentSummary(
            id: "essay-tech-education",
            title: "科技与教育",
            preview: "Technology is changing the way students learn and teachers teach.",
            mode: .exam,
            status: .reviewed,
            updatedAt: date(year: 2026, month: 6, day: 24, hour: 21, minute: 27),
            latestScore: 88,
            evaluationCount: 3,
            revisionCount: 2
        ),
        WritingDocumentSummary(
            id: "essay-city-life",
            title: "城市生活",
            preview: "Living in a city brings more chances, but it also creates pressure.",
            mode: .free,
            status: .reviewed,
            updatedAt: date(year: 2026, month: 6, day: 24, hour: 18, minute: 30),
            latestScore: 76,
            evaluationCount: 1,
            revisionCount: 1
        ),
        WritingDocumentSummary(
            id: "essay-free-20260624",
            title: "自由写作 2026-06-24",
            preview: "A short practice draft waiting for AI feedback.",
            mode: .free,
            status: .pendingReview,
            updatedAt: date(year: 2026, month: 6, day: 24, hour: 15, minute: 12),
            latestScore: nil,
            evaluationCount: 0,
            revisionCount: 0
        )
    ]

    private static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}

struct WritingHubDashboardSummary: Equatable {
    let documentCount: Int
    let pendingReviewCount: Int
    let averageScoreText: String
    let bestScoreText: String
}

struct WritingHubLayout: Equatable {
    let containerWidth: CGFloat

    var isCompact: Bool {
        containerWidth < 1_080
    }

    var horizontalPadding: CGFloat {
        containerWidth < 900 ? 20 : 28
    }

    var sectionSpacing: CGFloat {
        isCompact ? 26 : 34
    }

    var documentColumnCount: Int {
        containerWidth < 1_040 ? 1 : 2
    }

    var showsDailyPromptAside: Bool {
        containerWidth >= 1_120
    }

    var showsHeroIllustration: Bool {
        containerWidth >= 1_160
    }

    var searchFieldWidth: CGFloat {
        min(isCompact ? 280 : 330, max(220, containerWidth * 0.32))
    }

    var dailyPromptWidth: CGFloat {
        min(380, max(330, containerWidth * 0.30))
    }
}

struct WritingHubState {
    var selectedSection: WritingHubSection
    var searchText: String
    var modeFilter: WritingDocumentModeFilter
    var documents: [WritingDocumentSummary]

    init(
        selectedSection: WritingHubSection = .practice,
        searchText: String = "",
        modeFilter: WritingDocumentModeFilter = .all,
        documents: [WritingDocumentSummary] = WritingDocumentSummary.samples
    ) {
        self.selectedSection = selectedSection
        self.searchText = searchText
        self.modeFilter = modeFilter
        self.documents = documents
    }

    var filteredDocuments: [WritingDocumentSummary] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return documents
            .filter { document in
                modeFilter.includes(document.mode)
            }
            .filter { document in
                guard !keyword.isEmpty else {
                    return true
                }

                return document.title.localizedCaseInsensitiveContains(keyword)
                    || document.preview.localizedCaseInsensitiveContains(keyword)
            }
            .sorted { lhs, rhs in
                lhs.updatedAt > rhs.updatedAt
            }
    }

    var dashboardSummary: WritingHubDashboardSummary {
        let scores = documents.compactMap(\.latestScore)
        let averageText: String
        if scores.isEmpty {
            averageText = "--"
        } else {
            let average = Double(scores.reduce(0, +)) / Double(scores.count)
            averageText = "\(Int(average.rounded()))"
        }

        return WritingHubDashboardSummary(
            documentCount: documents.count,
            pendingReviewCount: documents.filter { $0.status == .pendingReview }.count,
            averageScoreText: averageText,
            bestScoreText: scores.max().map(String.init) ?? "--"
        )
    }
}
