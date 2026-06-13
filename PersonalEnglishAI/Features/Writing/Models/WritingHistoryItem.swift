import Foundation

struct WritingHistoryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let preview: String
    let updatedAt: Date

    static let samples = [
        WritingHistoryItem(
            id: "draft-1",
            title: "科技与教育",
            preview: "有些人认为科技正在提升学习效率...",
            updatedAt: .now
        ),
        WritingHistoryItem(
            id: "draft-2",
            title: "城市生活",
            preview: "生活在大城市能够带来更多机会...",
            updatedAt: .now.addingTimeInterval(-7200)
        )
    ]
}
