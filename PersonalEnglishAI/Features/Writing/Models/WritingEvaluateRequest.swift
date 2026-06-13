import Foundation

struct WritingEvaluateRequest: Encodable {
    let essay: String
    let mode: WritingMode
    let taskPrompt: String?
}

enum WritingMode: String, Codable, CaseIterable, Identifiable {
    case free
    case exam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free:
            "自由写作"
        case .exam:
            "考试写作"
        }
    }
}
