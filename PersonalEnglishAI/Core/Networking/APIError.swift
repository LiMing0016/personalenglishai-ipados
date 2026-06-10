import Foundation

enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed
    case missingToken
}
