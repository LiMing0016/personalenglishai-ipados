import Foundation

struct APIClient: @unchecked Sendable {
    let configuration: AppConfiguration
    var urlSession: URLSession = .shared
    var tokenProvider: (() -> String?)?
    var tokenRefreshProvider: (() async throws -> String?)?
    var unauthorizedHandler: (() async -> Void)?

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
        responseType: Response.Type = Response.self,
        allowsTokenRefresh: Bool = true
    ) async throws -> Response {
        let request = try makeRequest(endpoint, body: body)
        let (data, response) = try await perform(request)

        if response.statusCode == 401, allowsTokenRefresh, let tokenRefreshProvider {
            do {
                if let refreshedToken = try await tokenRefreshProvider(), !refreshedToken.isEmpty {
                    let retryRequest = try makeRequest(endpoint, body: body, accessTokenOverride: refreshedToken)
                    let (retryData, retryResponse) = try await perform(retryRequest)
                    return try await decode(retryData, response: retryResponse, responseType: responseType)
                }
            } catch {
                await unauthorizedHandler?()
            }
        }

        return try await decode(data, response: response, responseType: responseType)
    }

    private func makeRequest(
        _ endpoint: APIEndpoint,
        body: (any Encodable)?,
        accessTokenOverride: String? = nil
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

        let token = accessTokenOverride ?? tokenProvider?()
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder.api.encode(AnyEncodable(body))
        }

        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        return (data, httpResponse)
    }

    private func decode<Response: Decodable>(
        _ data: Data,
        response: HTTPURLResponse,
        responseType: Response.Type
    ) async throws -> Response {
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 {
                await unauthorizedHandler?()
            }

            let message = try? JSONDecoder.api.decode(APIErrorResponse.self, from: data).message
            throw APIError.requestFailed(statusCode: response.statusCode, message: message)
        }

        do {
            return try JSONDecoder.api.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}

private struct APIErrorResponse: Decodable {
    let message: String?
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
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = DateFormatters.iso8601WithFractionalSeconds.date(from: value) {
                return date
            }

            if let date = DateFormatters.iso8601.date(from: value) {
                return date
            }

            if let date = DateFormatters.localDateTime.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(value)"
            )
        }
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

private enum DateFormatters {
    nonisolated(unsafe) static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    nonisolated(unsafe) static let localDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}
