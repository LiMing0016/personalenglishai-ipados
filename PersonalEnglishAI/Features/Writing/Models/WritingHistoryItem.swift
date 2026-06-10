import Foundation

struct WritingHistoryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let preview: String
    let updatedAt: Date

    static let samples = [
        WritingHistoryItem(
            id: "draft-1",
            title: "Technology and education",
            preview: "Some people believe technology improves learning...",
            updatedAt: .now
        ),
        WritingHistoryItem(
            id: "draft-2",
            title: "City life",
            preview: "Living in a large city offers more opportunities...",
            updatedAt: .now.addingTimeInterval(-7200)
        )
    ]
}
