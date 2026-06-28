import Foundation

struct WritingDocumentMetrics: Equatable {
    let words: Int
    let sentences: Int
    let paragraphs: Int

    init(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        words = trimmed.isEmpty ? 0 : trimmed.split { character in
            character.isWhitespace || character.isPunctuation
        }.count
        sentences = trimmed.isEmpty ? 0 : trimmed.split { ".?!。！？".contains($0) }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
        paragraphs = trimmed.isEmpty ? 0 : trimmed.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
    }

    var displayText: String {
        "\(words) 词 · \(sentences) 句 · \(paragraphs) 段"
    }
}

struct WritingGoalProgress: Equatable {
    let metrics: WritingDocumentMetrics
    let targetWordCount: Int

    var ratio: Double {
        guard targetWordCount > 0 else {
            return 0
        }

        return min(1, Double(metrics.words) / Double(targetWordCount))
    }

    var isComplete: Bool {
        ratio >= 1
    }

    var displayText: String {
        "\(metrics.words) / \(targetWordCount) 词"
    }
}

enum WritingSaveStatus: Equatable {
    case dirty
    case saving
    case saved

    var displayText: String {
        switch self {
        case .dirty:
            "正在编辑"
        case .saving:
            "正在保存"
        case .saved:
            "已保存"
        }
    }
}

struct WritingStarterAction: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let toolRawValue: String?

    static let primary = [
        WritingStarterAction(
            id: "template",
            title: "从模板开始",
            subtitle: "作文结构、邮件、考试框架",
            systemImage: "square.grid.2x2",
            toolRawValue: "template"
        ),
        WritingStarterAction(
            id: "material",
            title: "使用素材库",
            subtitle: "主题词汇、观点和例句",
            systemImage: "lightbulb",
            toolRawValue: "material"
        ),
        WritingStarterAction(
            id: "prompt",
            title: "粘贴考试题目",
            subtitle: "按题目要求组织文章",
            systemImage: "doc.text.magnifyingglass",
            toolRawValue: "sample"
        ),
        WritingStarterAction(
            id: "recent",
            title: "继续最近草稿",
            subtitle: "回到上次未完成内容",
            systemImage: "clock.arrow.circlepath",
            toolRawValue: "archive"
        )
    ]
}
