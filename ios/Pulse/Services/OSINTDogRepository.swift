//
//  OSINTDogRepository.swift
//  Pulse
//
//  Data layer for the OSINTDog intelligence API.
//  Supports universal search, async search with polling, status checks,
//  and breach data queries across 15+ integrated sources.
//

import Foundation

/// Abstraction over the OSINTDog breach-search data source.
protocol OSINTDogRepository {
    /// Synchronous universal search across all data sources.
    func search(term: String, type: SearchType, page: Int) async throws -> OSINTDogSearchResponse

    /// Initiates an asynchronous search and returns a search ID for polling.
    func searchAsync(term: String, type: SearchType) async throws -> String

    /// Polls the status and results of an async search by its ID.
    func pollAsyncSearch(id: String, page: Int) async throws -> OSINTDogSearchResponse

    /// Checks the operational health of all integrated services.
    func checkStatus() async throws -> OSINTDogStatus
}

/// Live HTTPS implementation hitting the OSINTDog API.
final class LiveOSINTDogRepository: OSINTDogRepository {
    private let apiKeyManager: ApiKeyManager
    private let baseURL = "https://osintdog.com"
    private let session: URLSession
    private let pageSize = 20

    init(apiKeyManager: ApiKeyManager, session: URLSession = .shared) {
        self.apiKeyManager = apiKeyManager
        self.session = session
    }

    // MARK: - Synchronous search

    func search(term: String, type: SearchType, page: Int) async throws -> OSINTDogSearchResponse {
        guard let key = apiKeyManager.osintdogKey else {
            throw RepositoryError.missingKey
        }
        // Per docs: body is {"field": [{"<param>": "<term>"}]} — a flat array
        // of single-key objects. No documented limit/page params.
        var req = makeAuthRequest(path: "/api/search", method: "POST", key: key)
        let body: [String: Any] = [
            "field": [type.apiParam: term],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        try validateHTTP(response, data: data)
        return try parseSearchResponse(data, page: page)
    }

    // MARK: - Async search + polling

    /// Dump.cat asynchronous search, per docs:
    /// 1. POST /api/dumpcat/search/init  {"term": "...", "sort": 2} → {"search_id": ...}
    /// 2. POST /api/dumpcat/search/results {"search_id": ..., "limit", "offset"}
    func searchAsync(term: String, type: SearchType) async throws -> String {
        guard let key = apiKeyManager.osintdogKey else {
            throw RepositoryError.missingKey
        }
        var req = makeAuthRequest(path: "/api/dumpcat/search/init", method: "POST", key: key)
        let body: [String: Any] = [
            "term": term,
            "sort": 2,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        try validateHTTP(response, data: data)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let searchId = json["search_id"] as? String ?? json["id"] as? String
        else {
            throw RepositoryError.parseError("Missing search_id in Dump.cat init response")
        }
        return searchId
    }

    func pollAsyncSearch(id: String, page: Int) async throws -> OSINTDogSearchResponse {
        guard let key = apiKeyManager.osintdogKey else {
            throw RepositoryError.missingKey
        }
        var req = makeAuthRequest(path: "/api/dumpcat/search/results", method: "POST", key: key)
        let body: [String: Any] = [
            "search_id": id,
            "limit": pageSize,
            "offset": page * pageSize,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        try validateHTTP(response, data: data)
        return try parseSearchResponse(data, page: page)
    }

    // MARK: - Health check

    func checkStatus() async throws -> OSINTDogStatus {
        guard let key = apiKeyManager.osintdogKey else {
            throw RepositoryError.missingKey
        }
        var req = makeAuthRequest(path: "/api/status", method: "GET", key: key)
        let (data, response) = try await session.data(for: req)
        try validateHTTP(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RepositoryError.parseError("Invalid status response")
        }
        let status = json["status"] as? String ?? "unknown"
        let version = json["version"] as? String
        let services = json["services"] as? [String: [String]] ?? [:]
        return OSINTDogStatus(status: status, version: version, services: services)
    }

    // MARK: - Helpers

    private func makeAuthRequest(path: String, method: String, key: String) -> URLRequest {
        var req = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        req.httpMethod = method
        req.setValue(key, forHTTPHeaderField: "X-API-Key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 30
        return req
    }

    /// Per docs, error bodies use {"detail": "..."} and status codes mean:
    /// 400 invalid format, 401 invalid/missing key, 403 blacklisted search term
    /// (NOT auth), 429 rate limit, 500 server error.
    private func validateHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw RepositoryError.invalidResponse
        }
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let detail = json?["detail"] as? String ?? json?["message"] as? String
        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw detail.map { RepositoryError.unauthorizedDetail($0) } ?? RepositoryError.unauthorized
        case 403:
            throw RepositoryError.httpError(403, detail ?? "Search term is blacklisted")
        case 429:
            throw RepositoryError.rateLimited
        default:
            throw RepositoryError.httpError(http.statusCode, detail)
        }
    }

    /// Parses the documented nested response shape:
    /// {"success": true, "total_entries": N, "results": [{"source": ..., "entries": [{...}]}]}
    /// Entries are flattened into BreachResults tagged with their source name.
    private func parseSearchResponse(_ data: Data, page: Int) throws -> OSINTDogSearchResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success
        else {
            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let detail = errorJson?["detail"] as? String ?? errorJson?["message"] as? String
            throw RepositoryError.parseError(detail ?? "API returned unsuccessful response")
        }
        let total = json["total_entries"] as? Int ?? 0
        let sourceArray = json["results"] as? [[String: Any]] ?? []

        var results: [BreachResult] = []
        for (srcIdx, sourceDict) in sourceArray.enumerated() {
            let source = sourceDict["source"] as? String ?? "Unknown"
            let entries = sourceDict["entries"] as? [[String: Any]] ?? []
            for (entryIdx, dict) in entries.enumerated() {
                let id = dict["id"] as? String ?? "dog_\(page)_\(srcIdx)_\(entryIdx)"
                let email = dict["email"] as? String
                let username = dict["username"] as? String
                let password = dict["password"] as? String
                let domain = dict["domain"] as? String
                let ip = dict["ip"] as? String
                let dateStr = dict["date"] as? String
                let date = dateStr.flatMap { Self.dateFormatter.date(from: $0) }
                var fields = dict.compactMapValues { $0 as? String }
                for key in ["id", "email", "username", "password", "domain", "ip", "date"] {
                    fields.removeValue(forKey: key)
                }
                results.append(BreachResult(id: id, source: source, email: email, username: username,
                                            password: password, domain: domain, ip: ip, date: date, fields: fields))
            }
        }
        // /api/search has no documented pagination — it returns all entries at once.
        let hasMore = false
        return OSINTDogSearchResponse(results: results, total: total, page: page, hasMore: hasMore)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: - Mock

final class MockOSINTDogRepository: OSINTDogRepository {
    func search(term: String, type: SearchType, page: Int) async throws -> OSINTDogSearchResponse {
        try await Task.sleep(for: .milliseconds(600))
        let all: [BreachResult] = [
            BreachResult(id: "1", source: "LeakCheck", email: term, username: "jdoe",
                         password: "P@ssword123", domain: "example.com", date: Date().addingTimeInterval(-86400 * 30)),
            BreachResult(id: "2", source: "HackCheck", email: term, username: "j.doe",
                         password: "Summer2024!", domain: "target.co", date: Date().addingTimeInterval(-86400 * 65)),
            BreachResult(id: "3", source: "Snusbase", email: term, domain: "old-site.io",
                         date: Date().addingTimeInterval(-86400 * 120)),
            BreachResult(id: "4", source: "BreachVIP", email: term, username: "johnd",
                         password: "md5hash", ip: "192.168.1.1", date: Date().addingTimeInterval(-86400 * 200)),
            BreachResult(id: "5", source: "IntelVault", email: term, domain: "corp.net",
                         date: Date().addingTimeInterval(-86400 * 310)),
            BreachResult(id: "6", source: "BreachBase", email: term, username: "doe_j",
                         date: Date().addingTimeInterval(-86400 * 450)),
        ]
        let start = page * 3
        let pageResults = Array(all.dropFirst(start).prefix(3))
        return OSINTDogSearchResponse(results: pageResults, total: all.count, page: page, hasMore: start + 3 < all.count)
    }

    func searchAsync(term: String, type: SearchType) async throws -> String {
        try await Task.sleep(for: .milliseconds(200))
        return "async_mock_\(UUID().uuidString.prefix(8))"
    }

    func pollAsyncSearch(id: String, page: Int) async throws -> OSINTDogSearchResponse {
        try await Task.sleep(for: .milliseconds(400))
        return try await search(term: "mock", type: .email, page: page)
    }

    func checkStatus() async throws -> OSINTDogStatus {
        try await Task.sleep(for: .milliseconds(300))
        return OSINTDogStatus(
            status: "online",
            version: "2.0.0",
            services: [
                "data_breach": ["LeakCheck v2", "HackCheck", "Snusbase", "BreachVIP", "IntelVault", "BreachBase"],
                "social_media": ["SEON Email", "SEON Phone"],
            ]
        )
    }
}

// MARK: - Errors

enum RepositoryError: LocalizedError {
    case missingKey
    case invalidResponse
    case unauthorized
    case unauthorizedDetail(String)
    case rateLimited
    case httpError(Int, String?)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "API key not configured"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "API key rejected — check your key in Settings"
        case .unauthorizedDetail(let msg): return "API key rejected: \(msg)"
        case .rateLimited: return "Rate limit exceeded — wait and try again"
        case .httpError(let code, let msg): return msg ?? "Server error (HTTP \(code))"
        case .parseError(let msg): return "Failed to parse response: \(msg)"
        }
    }
}
