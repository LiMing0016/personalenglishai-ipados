import Foundation

enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, message: String?)
    case decodingFailed
    case missingToken
}
