import Foundation
import UIKit

enum PlatterAPIError: LocalizedError {
    case invalidResponse
    case serverError(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid server response."
        case .serverError(let code): "Server error (\(code))."
        case .decodingFailed: "Could not read server response."
        }
    }
}

struct ParseMenuAPIResponse: Codable {
    var menu: Menu
    var confidence: Double
    var warnings: [String]
}

struct GenerateCombosAPIRequest: Codable {
    var menu: Menu
    var constraints: Constraints
}

struct GenerateCombosAPIResponse: Codable {
    var combos: [Combo]
    var aiSummary: String
    var constraintTags: [String]
}

enum PlatterAPIService {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static func parseMenu(
        imageData: Data,
        source: MenuSource,
        restaurantName: String?
    ) async throws -> ParseMenuAPIResponse {
        let boundary = UUID().uuidString
        var body = Data()

        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        appendField("source", source.rawValue)
        if let restaurantName {
            appendField("restaurant_name", restaurantName)
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"menu.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        var request = URLRequest(url: PlatterAPIConfig.baseURL.appendingPathComponent("/v1/menus/parse"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await Self.session.data(for: request)
        try validate(response)
        guard let parsed = try? decoder.decode(ParseMenuAPIResponse.self, from: data) else {
            throw PlatterAPIError.decodingFailed
        }
        return parsed
    }

    static func generateCombos(menu: Menu, constraints: Constraints) async throws -> GenerateCombosAPIResponse {
        var request = URLRequest(url: PlatterAPIConfig.baseURL.appendingPathComponent("/v1/combos/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(GenerateCombosAPIRequest(menu: menu, constraints: constraints))

        let (data, response) = try await Self.session.data(for: request)
        try validate(response)
        guard let parsed = try? decoder.decode(GenerateCombosAPIResponse.self, from: data) else {
            throw PlatterAPIError.decodingFailed
        }
        return parsed
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw PlatterAPIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw PlatterAPIError.serverError(http.statusCode)
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
