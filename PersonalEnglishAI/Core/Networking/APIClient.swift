import Foundation

struct APIClient {
    let configuration: AppConfiguration
    var urlSession: URLSession = .shared
    var tokenProvider: (() -> String?)?

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        let request = try makeRequest(endpoint, body: body)
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder.api.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func makeRequest(
        _ endpoint: APIEndpoint,
        body: (any Encodable)?
    ) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.apiBaseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenProvider?(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder.api.encode(AnyEncodable(body))
        }

        return request
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
