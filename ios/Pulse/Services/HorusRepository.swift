//
//  HorusRepository.swift
//  Pulse
//
//  Data layer for the Horus partner v1 API.
//  Supports stealer log search with field filtering, date ranges,
//  cursor-based pagination, and multi-module access (telegram, forums, combo).
//

import Foundation

/// Abstraction over the Horus partner v1 API.
protocol HorusRepository {
    /// Search stealer logs with keyword, optional field filter, date range, and cursor pagination.
    func searchStealer(
        keyword: String,
        field: HorusField?,
        dateFrom: Date?,
        dateTo: Date?,
        limit: Int,
        cursor: String?
    ) async throws -> HorusSearchResponse

    /// Browse stealer logs without a keyword (recent feed).
    func browseStealerLogs(
        limit: Int,
        cursor: String?,
        field: HorusField?,
        dateFrom: Date?,
        dateTo: Date?
    ) async throws -> HorusSearchResponse

    /// Check API key health via the stealer search endpoint with a minimal query.
    func checkHealth() async throws -> Bool
}

/// Live HTTPS implementation hitting the Horus partner v1 API.
final class LiveHorusRepository: HorusRepository {
    private let apiKeyManager: ApiKeyManager
    private let baseURL = "https://horus.st/api"
    private let session: URLSession

    init(apiKeyManager: ApiKeyManager, session: URLSession = .shared) {
        self.apiKeyManager = apiKeyManager
        self.session = session
    }

    // MARK: - Search stealer

    func searchStealer(
        keyword: String,
        field: HorusField?,
        dateFrom: Date?,
        dateTo: Date?,
        limit: Int,
        cursor: String?
    ) async throws -> HorusSearchResponse {
        guard let key = apiKeyManager.horusKey else {
            throw RepositoryError.missingKey
        }
        let clampedLimit = min(max(limit, 1), 500)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "limit", value: "\(clampedLimit)"),
        ]
        if let fieldValue = field?.apiValue {
            queryItems.append(URLQueryItem(name: "field", value: fieldValue))
        }
        if let from = dateFrom {
            queryItems.append(URLQueryItem(name: "dateFrom", value: Self.isoFormatter.string(from: from)))
        }
        if let to = dateTo {
            queryItems.append(URLQueryItem(name: "dateTo", value: Self.isoFormatter.string(from: to)))
        }
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        return try await horusRequest(path: "/v1/search/stealer", queryItems: queryItems, key: key)
    }

    // MARK: - Browse stealer logs

    func browseStealerLogs(
        limit: Int,
        cursor: String?,
        field: HorusField?,
        dateFrom: Date?,
        dateTo: Date?
    ) async throws -> HorusSearchResponse {
        guard let key = apiKeyManager.horusKey else {
            throw RepositoryError.missingKey
        }
        let clampedLimit = min(max(limit, 1), 500)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(clampedLimit)"),
        ]
        if let fieldValue = field?.apiValue {
            queryItems.append(URLQueryItem(name: "field", value: fieldValue))
        }
        if let from = dateFrom {
            queryItems.append(URLQueryItem(name: "dateFrom", value: Self.isoFormatter.string(from: from)))
        }
        if let to = dateTo {
            queryItems.append(URLQueryItem(name: "dateTo", value: Self.isoFormatter.string(from: to)))
        }
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        return try await horusRequest(path: "/v1/search/stealer", queryItems: queryItems, key: key)
    }

    // MARK: - Health check

    /// Uses GET /v1/search/stealer with a minimal query as a lightweight
    /// health check — the same endpoint the app actually uses. Matches
    /// ApiKeyManager.validateHorus() exactly: same endpoint, same 30s
    /// timeout, same auth header, same response treatment.
    func checkHealth() async throws -> Bool {
        guard let key = apiKeyManager.horusKey else {
            throw RepositoryError.missingKey
        }
        var components = URLComponents(string: "\(baseURL)/v1/search/stealer")!
        components.queryItems = [
            URLQueryItem(name: "keyword", value: "health_check"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        var req = URLRequest(url: components.url!)
        req.setValue(key, forHTTPHeaderField: "X-Api-Key")
        req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 30

        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw RepositoryError.invalidResponse
        }
        switch http.statusCode {
        case 200...299:
            return true
        case 401, 403:
            throw RepositoryError.unauthorized
        case 429:
            throw RepositoryError.rateLimited
        default:
            throw RepositoryError.httpError(http.statusCode, "Health check failed (HTTP \(http.statusCode))")
        }
    }

    // MARK: - Shared request helpers

    private func horusRequest(path: String, queryItems: [URLQueryItem], key: String) async throws -> HorusSearchResponse {
        let (data, response) = try await makeHorusRequest(path: path, queryItems: queryItems, key: key)
        try validateHorusHTTP(response, data: data)
        return try parseStealerResponse(data)
    }

    private func makeHorusRequest(path: String, queryItems: [URLQueryItem], key: String) async throws -> (Data, URLResponse) {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        components.queryItems = queryItems

        var req = URLRequest(url: components.url!)
        req.setValue(key, forHTTPHeaderField: "X-Api-Key")
        req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 30
        return try await session.data(for: req)
    }

    private func validateHorusHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw RepositoryError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            let err = parseHorusError(data)
            throw err ?? RepositoryError.unauthorized
        }
        if http.statusCode == 429 {
            throw RepositoryError.rateLimited
        }
        if http.statusCode == 400 {
            let err = parseHorusError(data)
            throw err ?? RepositoryError.httpError(400, "Bad request — check parameters")
        }
        guard http.statusCode == 200 else {
            let err = parseHorusError(data)
            throw err ?? RepositoryError.httpError(http.statusCode, nil)
        }
    }

    private func parseHorusError(_ data: Data) -> RepositoryError? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, !success,
              let errorDict = json["error"] as? [String: Any],
              let message = errorDict["message"] as? String
        else { return nil }
        let code = errorDict["code"] as? String
        let detail = code.map { "\(message) (code: \($0))" } ?? message
        return .unauthorizedDetail(detail)
    }

    private func parseStealerResponse(_ data: Data) throws -> HorusSearchResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let dataDict = json["data"] as? [String: Any]
        else {
            let err = parseHorusError(data)
            throw err ?? RepositoryError.parseError("API returned unsuccessful response")
        }
        let items = dataDict["items"] as? [[String: Any]] ?? []
        let total = dataDict["total"] as? Int ?? items.count
        let cursor = dataDict["nextCursor"] as? String ?? dataDict["next_cursor"] as? String
        let hasMore = cursor != nil && !items.isEmpty

        let results: [StealerLogResult] = items.enumerated().compactMap { idx, dict in
            let id = dict["id"] as? String ?? "horus_\(idx)"
            let logId = dict["log_id"] as? String
            let domain = dict["domain"] as? String
            let url = dict["url"] as? String
            let username = dict["username"] as? String
            let password = dict["password"] as? String
            let os = dict["os"] as? String ?? dict["operating_system"] as? String
            let country = dict["country"] as? String ?? dict["country_code"] as? String
            let ip = dict["ip"] as? String ?? dict["ip_address"] as? String
            let malware = dict["malware_family"] as? String ?? dict["malware"] as? String
            let dateStr = dict["captured_at"] as? String
            let capturedAt = dateStr.flatMap { Self.dateFormatter.date(from: $0) }
            return StealerLogResult(id: id, logId: logId, domain: domain, url: url,
                                    username: username, password: password, os: os,
                                    country: country, ip: ip, malwareFamily: malware,
                                    capturedAt: capturedAt)
        }
        return HorusSearchResponse(results: results, total: total, cursor: cursor, hasMore: hasMore)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Mock

final class MockHorusRepository: HorusRepository {
    func searchStealer(
        keyword: String,
        field: HorusField?,
        dateFrom: Date?,
        dateTo: Date?,
        limit: Int,
        cursor: String?
    ) async throws -> HorusSearchResponse {
        try await Task.sleep(for: .milliseconds(600))
        let all: [StealerLogResult] = [
            StealerLogResult(id: "h1", logId: "log_8f2a", domain: "admin.acme-corp.com",
                             url: "https://admin.acme-corp.com", username: "jacob.32**",
                             password: "••••••••", os: "Windows 11", country: "US",
                             ip: "45.33.32.12", malwareFamily: "RedLine",
                             capturedAt: Date().addingTimeInterval(-86400 * 2)),
            StealerLogResult(id: "h2", logId: "log_8f2a", domain: "okta.acme.com",
                             url: "https://okta.acme.com", username: "jacob.32**",
                             password: "•••••••", os: "Windows 11", country: "US",
                             ip: "45.33.32.12", malwareFamily: "RedLine",
                             capturedAt: Date().addingTimeInterval(-86400 * 2)),
            StealerLogResult(id: "h3", logId: "log_9a1b", domain: "vpn.target.co",
                             url: "https://vpn.target.co", username: "jsmith",
                             os: "Windows 10", country: "DE", ip: "91.66.12.44",
                             malwareFamily: "Lumma", capturedAt: Date().addingTimeInterval(-86400 * 7)),
        ]
        let filtered = keyword.isEmpty ? all : all.filter {
            ($0.domain ?? "").localizedCaseInsensitiveContains(keyword) ||
            ($0.username ?? "").localizedCaseInsensitiveContains(keyword)
        }
        return HorusSearchResponse(results: filtered, total: filtered.count, cursor: nil, hasMore: false)
    }

    func browseStealerLogs(
        limit: Int,
        cursor: String?,
        field: HorusField?,
        dateFrom: Date?,
        dateTo: Date?
    ) async throws -> HorusSearchResponse {
        try await Task.sleep(for: .milliseconds(600))
        let domains = ["portal.corp.com", "mail.agency.io", "cloud.saas.app", "admin.panel.dev", "api.service.net"]
        let usernames = ["admin", "user1", "sa", "root", "deploy"]
        let osList = ["Windows 11", "Windows 10", "macOS 14", "Ubuntu 22.04", "Windows 11"]
        let countryList = ["US", "GB", "DE", "FR", "BR"]
        let malwareList = ["RedLine", "Lumma", "Vidar", "Raccoon", "RedLine"]
        let count = min(limit, 8)
        var results: [StealerLogResult] = []
        for i in 0..<count {
            let log = StealerLogResult(
                id: "hb\(i)",
                logId: "log_\(1000 + i)",
                domain: domains[i % 5],
                username: usernames[i % 5],
                os: osList[i % 5],
                country: countryList[i % 5],
                malwareFamily: malwareList[i % 5],
                capturedAt: Date().addingTimeInterval(-86400 * Double(i + 1))
            )
            results.append(log)
        }
        return HorusSearchResponse(results: results, total: results.count, cursor: nil, hasMore: false)
    }

    func checkHealth() async throws -> Bool {
        try await Task.sleep(for: .milliseconds(200))
        return true
    }
}
