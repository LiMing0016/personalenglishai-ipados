import Foundation

struct WritingEvaluateResponse: Decodable {
    let requestId: String
    let summary: String
    let score: WritingScore
}

struct WritingScore: Decodable {
    let overall: Double
    let task: Double
    let coherence: Double
    let lexical: Double
    let grammar: Double
}
