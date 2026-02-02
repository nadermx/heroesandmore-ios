import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return message ?? "HTTP error \(statusCode)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Please log in again"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error. Please try again later."
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatters = [
                ISO8601DateFormatter(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    return f
                }()
            ]

            for formatter in formatters {
                if let isoFormatter = formatter as? ISO8601DateFormatter {
                    if let date = isoFormatter.date(from: dateString) {
                        return date
                    }
                } else if let dateFormatter = formatter as? DateFormatter {
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Request Building

    private func buildURL(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        var components = URLComponents(string: Config.apiBaseURL + path)
        components?.queryItems = queryItems?.isEmpty == false ? queryItems : nil

        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        return url
    }

    private func buildRequest(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil,
        contentType: String = "application/json"
    ) async -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body

        // Add auth token if available
        if let token = await KeychainService.shared.get(key: Config.accessTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Request Execution

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var bodyData: Data? = nil

        if let body = body {
            bodyData = try encoder.encode(body)
        }

        let request = await buildRequest(url: url, method: method, body: bodyData)
        return try await execute(request: request)
    }

    func requestVoid(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil
    ) async throws {
        let url = try buildURL(path: path, queryItems: queryItems)
        var bodyData: Data? = nil

        if let body = body {
            bodyData = try encoder.encode(body)
        }

        let request = await buildRequest(url: url, method: method, body: bodyData)
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try handleStatusCode(httpResponse.statusCode)
    }

    func upload<T: Decodable>(
        path: String,
        imageData: Data,
        filename: String,
        queryItems: [URLQueryItem]? = nil,
        additionalFields: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.get(key: Config.accessTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        return try await execute(request: request)
    }

    // MARK: - Raw Data Request (for file downloads)

    func requestRaw(
        path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        let url = try buildURL(path: path, queryItems: queryItems)
        let request = await buildRequest(url: url, method: .get)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try handleStatusCode(httpResponse.statusCode, data: data)
        return data
    }

    // MARK: - File Upload (for collection import)

    func uploadFile<T: Decodable>(
        path: String,
        fileData: Data,
        fileName: String,
        additionalFields: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(path: path)
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = await KeychainService.shared.get(key: Config.accessTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Add file
        let mimeType = fileName.hasSuffix(".json") ? "application/json" : "text/csv"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Add additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        return try await execute(request: request)
    }

    private func execute<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle 401 - try to refresh token
        if httpResponse.statusCode == 401 {
            if try await refreshTokenAndRetry() {
                // Retry with new token
                var newRequest = request
                if let token = await KeychainService.shared.get(key: Config.accessTokenKey) {
                    newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                let (retryData, retryResponse) = try await session.data(for: newRequest)
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                try handleStatusCode(retryHttpResponse.statusCode, data: retryData)
                return try decoder.decode(T.self, from: retryData)
            } else {
                throw APIError.unauthorized
            }
        }

        try handleStatusCode(httpResponse.statusCode, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func handleStatusCode(_ statusCode: Int, data: Data? = nil) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...499:
            var message: String? = nil
            if let data = data,
               let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                message = errorResponse["detail"] ?? errorResponse["error"]
            }
            throw APIError.httpError(statusCode: statusCode, message: message)
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.httpError(statusCode: statusCode, message: nil)
        }
    }

    private func refreshTokenAndRetry() async throws -> Bool {
        guard let refreshToken = await KeychainService.shared.get(key: Config.refreshTokenKey) else {
            return false
        }

        struct RefreshRequest: Codable {
            let refresh: String
        }

        struct RefreshResponse: Codable {
            let access: String
            let refresh: String?
        }

        let url = try buildURL(path: "/auth/token/refresh/")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(RefreshRequest(refresh: refreshToken))

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            // Refresh failed, clear tokens
            await KeychainService.shared.delete(key: Config.accessTokenKey)
            await KeychainService.shared.delete(key: Config.refreshTokenKey)
            return false
        }

        let tokens = try decoder.decode(RefreshResponse.self, from: data)
        await KeychainService.shared.set(key: Config.accessTokenKey, value: tokens.access)
        if let newRefresh = tokens.refresh {
            await KeychainService.shared.set(key: Config.refreshTokenKey, value: newRefresh)
        }

        return true
    }
}
