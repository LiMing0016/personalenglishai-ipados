import Foundation

enum RichContentBlock: Hashable, Encodable {
    case markdown(String)
    case mermaid(String)
    case graphJSON(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case content
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .markdown(let content):
            try container.encode("markdown", forKey: .type)
            try container.encode(content, forKey: .content)
        case .mermaid(let content):
            try container.encode("mermaid", forKey: .type)
            try container.encode(content, forKey: .content)
        case .graphJSON(let content):
            try container.encode("graph-json", forKey: .type)
            try container.encode(content, forKey: .content)
        }
    }
}
