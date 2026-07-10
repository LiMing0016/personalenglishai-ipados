import CoreGraphics
import Foundation

enum AssistantSidebarScene: String, CaseIterable, Identifiable {
    case assistant
    case writing
    case archive
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assistant:
            "AI 助手"
        case .writing:
            "写作练习"
        case .archive:
            "学习档案"
        case .profile:
            "我的"
        }
    }

    var subtitle: String {
        switch self {
        case .assistant:
            "翻译、语法、口语、问答"
        case .writing:
            "作文草稿、评分、润色"
        case .archive:
            "能力变化、目标、复盘"
        case .profile:
            "账号、偏好、设置"
        }
    }

    var systemImage: String {
        switch self {
        case .assistant:
            "bubble.left.and.bubble.right"
        case .writing:
            "pencil.and.scribble"
        case .archive:
            "chart.bar.xaxis"
        case .profile:
            "person.crop.circle"
        }
    }

    var destinationTab: AppTab {
        switch self {
        case .assistant:
            .assistant
        case .writing:
            .writing
        case .archive:
            .dashboard
        case .profile:
            .profile
        }
    }
}

enum AssistantSidebarQuickTask: String, CaseIterable, Identifiable {
    case translation
    case grammar
    case writingReview
    case learningPlan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .translation:
            "翻译"
        case .grammar:
            "语法"
        case .writingReview:
            "批改作文"
        case .learningPlan:
            "学习计划"
        }
    }

    var prompt: String {
        switch self {
        case .translation:
            "请帮我把这段英文翻译成自然中文："
        case .grammar:
            "请帮我分析这段英文的语法问题："
        case .writingReview:
            "请帮我批改这篇英语作文，并给出修改建议："
        case .learningPlan:
            "请根据我的目标制定一个英语学习计划："
        }
    }
}

enum AssistantSidebarLayout {
    static let collapsedWidth: CGFloat = 0
    static let minimumExpandedWidth: CGFloat = 340
    static let maximumExpandedWidth: CGFloat = 430
    static let expandedWidthRatio: CGFloat = 0.31

    static func width(containerWidth: CGFloat, isCollapsed: Bool) -> CGFloat {
        guard !isCollapsed else { return collapsedWidth }

        return min(
            maximumExpandedWidth,
            max(minimumExpandedWidth, containerWidth * expandedWidthRatio)
        )
    }
}
