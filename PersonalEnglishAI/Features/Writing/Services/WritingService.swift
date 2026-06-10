import Foundation

protocol WritingService {
    func evaluate(_ request: WritingEvaluateRequest) async throws -> WritingEvaluateResponse
}

struct MockWritingService: WritingService {
    func evaluate(_ request: WritingEvaluateRequest) async throws -> WritingEvaluateResponse {
        WritingEvaluateResponse(
            requestId: UUID().uuidString,
            summary: "This is a strong draft placeholder. Real scoring will arrive after API integration.",
            score: WritingScore(overall: 7.0, task: 7.0, coherence: 6.5, lexical: 7.0, grammar: 6.5)
        )
    }
}
