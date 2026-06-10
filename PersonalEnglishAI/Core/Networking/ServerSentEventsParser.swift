import Foundation

struct ServerSentEventsParser {
    func parse(_ chunk: String) -> [String] {
        chunk
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { block in
                block
                    .split(separator: "\n")
                    .filter { $0.hasPrefix("data:") }
                    .map { $0.dropFirst("data:".count).trimmingCharacters(in: .whitespaces) }
                    .joined(separator: "\n")
            }
            .filter { !$0.isEmpty }
    }
}
