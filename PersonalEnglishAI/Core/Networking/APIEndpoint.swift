import Foundation

struct APIEndpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    let method: Method
    let path: String
    let queryItems: [URLQueryItem]

    init(method: Method, path: String, queryItems: [URLQueryItem] = []) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
    }
}
