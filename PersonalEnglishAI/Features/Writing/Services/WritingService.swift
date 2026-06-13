import Foundation

protocol WritingService {
    func evaluate(_ request: WritingEvaluateRequest) async throws -> WritingEvaluateResponse
}

struct MockWritingService: WritingService {
    func evaluate(_ request: WritingEvaluateRequest) async throws -> WritingEvaluateResponse {
        WritingEvaluateResponse(
            requestId: UUID().uuidString,
            summary: "这是一篇结构清晰的示例草稿。真实评分会在 API 接入后返回。",
            score: WritingScore(overall: 7.0, task: 7.0, coherence: 6.5, lexical: 7.0, grammar: 6.5)
        )
    }
}
