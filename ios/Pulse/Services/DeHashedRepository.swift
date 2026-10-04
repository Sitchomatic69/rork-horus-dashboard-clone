//
//  DeHashedRepository.swift
//  Pulse
//
//  DeHashed v2 API client. Searches leak entries via POST /v2/search
//  with a JSON body and the `Dehashed-Api-Key` header. All entry fields
//  come back as arrays of strings except `id` and `database_name`.
//
//  Query rules (from DeHashed's search guide):
//   - field-prefixed queries ("email:foo@bar.com"), 4–255 chars
//   - wildcard and regex are mutually exclusive (neither is used here)
//   - pagination is page-based (1-indexed); size capped at 20/page here
//

import Foundation

// MARK: - Response model

/// Paginated response from the DeHashed v2 search endpoint.
struct DeHashedSearchResponse: Hashable {
    let results: [BreachResult]
    let total: Int
    let page: Int
    let balance: Int?
    let hasMore: Bool
}

// MARK: - Protocol

protocol DeHashedRepository {
    /// Searches DeHashed for the given term. `page` is 1-indexed.
    func search(term: String, type: SearchType, page: Int) async throws -> DeHashedSearchResponse
    /// Cheap probe used by key validation — returns true on HTTP 200.
    func checkHealth() async -> Bool
}

// MARK: - Live implementation

final class LiveDeHashedRepository: DeHashedRepository {
    private let apiKeyManager: ApiKeyManager
    private let session: URLSession

    static let baseURL = "https://api.dehashed.com/v2"
    static let pageSize = 20
    static let maxPages = 99

    init(apiKeyManager: ApiKeyManager, session: URLSession = .shared) {
        self.apiKeyManager = apiKeyManager
        self.session = session
    }

    func search(term: String, type: SearchType, page: Int) async throws -> DeHashedSearchResponse {
        guard let key = apiKeyManager.dehashedKey, !key.isEmpty else {
            throw RepositoryError.missingKey
        }

        let trimmed = term.trimmingCharacters(in: .whitespaces)
        // DeHashed rejects queries shorter than 4 characters.
        guard trimmed.count >= 4 else {
            throw RepositoryError.parseError("DeHashed queries must be at least 4 characters")
        }
        guard trimmed.count <= 255 else {
            throw RepositoryError.parseError("DeHashed queries must be at most 255 characters")
        }

        let query = "\(Self.fieldPrefix(for: type))\(trimmed)"
        return try await executeSearch(query: query, page: max(1, page), key: key, label: "search")
    }

    func checkHealth() async -> Bool {
        guard let key = apiKeyManager.dehashedKey, !key.isEmpty else { return false }
        do {
            // Minimal real query — the same endpoint real searches use,
            // so a healthy response means the key actually works.
            _ = try await executeSearch(query: "email:test@example.com", page: 1, key: key, label: "health")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Request

    private func executeSearch(query: String, page: Int, key: String, label: String) async throws -> DeHashedSearchResponse {
        var components = URLComponents(string: "\(Self.baseURL)/search")!

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "Dehashed-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "query": query,
            "page": page,
            "size": Self.pageSize,
            "wildcard": false,
            "regex": false,
            "de_dupe": false,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RepositoryError.invalidResponse
        }

        logResponse("/v2/search (\(label))", data: data, response: response)

        switch http.statusCode {
        case 200...299:
            return try Self.parseResponse(data: data, page: page)
        case 401, 403:
            if let detail = Self.errorMessage(from: data) {
                throw RepositoryError.unauthorizedDetail(detail)
            }
            throw RepositoryError.unauthorized
        case 429:
            throw RepositoryError.rateLimited
        default:
            throw RepositoryError.httpError(http.statusCode, Self.errorMessage(from: data))
        }
    }

    // MARK: - Parsing

    static func parseResponse(data: Data, page: Int) throws -> DeHashedSearchResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RepositoryError.invalidResponse
        }

        let total = (json["total"] as? NSNumber)?.intValue ?? 0
        let balance = (json["balance"] as? NSNumber)?.intValue

        guard let entries = json["entries"] as? [[String: Any]] else {
            // A successful response with no entries array means zero results.
            return DeHashedSearchResponse(results: [], total: total, page: page, balance: balance, hasMore: false)
        }

        let results = entries.compactMap(parseEntry)
        let hasMore = page < maxPages && page * pageSize < total

        return DeHashedSearchResponse(results: results, total: total, page: page, balance: balance, hasMore: hasMore)
    }

    /// Maps one v2 entry to a BreachResult. Person fields are arrays of
    /// strings; we take the first value of each and stash the rest in `fields`.
    private static func parseEntry(_ entry: [String: Any]) -> BreachResult? {
        let id = (entry["id"] as? String) ?? UUID().uuidString

        var source = "DeHashed"
        if let db = stringValue(entry, "database_name") {
            source = db
        }

        let email = firstValue(entry, "email")
        let username = firstValue(entry, "username")
        let password = firstValue(entry, "password")
        let ip = firstValue(entry, "ip_address")

        // Derive a domain from the email or URL when present.
        var domain: String?
        if let email, let at = email.firstIndex(of: "@") {
            domain = String(email[email.index(after: at)...])
        } else if let url = firstValue(entry, "url") {
            domain = url
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .split(separator: "/").first.map(String.init)
        }

        var fields: [String: String] = [:]
        let extraKeys = ["name", "address", "phone", "dob", "company", "social",
                         "cryptocurrency_address", "hashed_password", "license_plate"]
        for key in extraKeys {
            if let value = firstValue(entry, key) {
                fields[key] = value
            }
        }

        return BreachResult(
            id: id,
            source: source,
            email: email,
            username: username,
            password: password,
            domain: domain,
            ip: ip,
            date: nil,
            fields: fields
        )
    }

    /// Reads a possibly-array-of-strings field and returns its first value.
    private static func firstValue(_ entry: [String: Any], _ key: String) -> String? {
        stringValue(entry, key) ?? (entry[key] as? [Any])?.compactMap { $0 as? String }.first
    }

    /// Reads a plain string field (e.g. id, database_name).
    private static func stringValue(_ entry: [String: Any], _ key: String) -> String? {
        entry[key] as? String
    }

    // MARK: - Helpers

    /// Maps the app's SearchType to the DeHashed v2 field prefix.
    static func fieldPrefix(for type: SearchType) -> String {
        switch type {
        case .email: return "email:"
        case .username: return "username:"
        case .domain: return "domain:"
        case .ip: return "ip:"
        case .phone: return "phone:"
        }
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8)
        }
        // v2 error bodies aren't publicly documented — probe common shapes.
        for key in ["message", "detail", "error"] {
            if let value = json[key] as? String { return value }
            if let dict = json[key] as? [String: Any], let msg = dict["message"] as? String {
                return msg
            }
        }
        return nil
    }

    private func logResponse(_ label: String, data: Data, response: URLResponse) {
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        let preview = String(data: data, encoding: .utf8)?.prefix(200) ?? "<non-utf8>"
        print("[Pulse] DeHashed \(label) → HTTP \(status): \(preview)")
    }
}

// MARK: - Mock implementation

final class MockDeHashedRepository: DeHashedRepository {
    func search(term: String, type: SearchType, page: Int) async throws -> DeHashedSearchResponse {
        try await Task.sleep(for: .milliseconds(400))
        let results = MockDeHashedRepository.sampleResults(term: term)
        return DeHashedSearchResponse(
            results: results,
            total: results.count,
            page: page,
            balance: 100,
            hasMore: false
        )
    }

    func checkHealth() async -> Bool { true }

    static func sampleResults(term: String) -> [BreachResult] {
        [
            BreachResult(
                id: "dh-1",
                source: "Collection #1",
                email: term.contains("@") ? term : "\(term)@example.com",
                username: "user_\(term.prefix(6))",
                password: "hunter2",
                domain: "example.com",
                ip: "203.0.113.7",
                date: nil,
                fields: ["name": "Jane Doe", "phone": "+15550100"]
            ),
            BreachResult(
                id: "dh-2",
                source: "LinkedIn Leak",
                email: "contact@example.org",
                username: term,
                password: nil,
                domain: "example.org",
                ip: "198.51.100.22",
                date: nil,
                fields: ["company": "Example LLC"]
            ),
        ]
    }
}
