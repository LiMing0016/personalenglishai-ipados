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
            "Home"
        case .assistant:
            "Assistant"
        case .writing:
            "Writing"
        case .profile:
            "Profile"
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
