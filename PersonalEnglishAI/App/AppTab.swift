import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case assistant
    case writing
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "首页"
        case .assistant:
            "AI 助手"
        case .writing:
            "写作"
        case .profile:
            "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "house"
        case .assistant:
            "bubble.left.and.bubble.right"
        case .writing:
            "pencil.and.scribble"
        case .profile:
            "person.crop.circle"
        }
    }
}
