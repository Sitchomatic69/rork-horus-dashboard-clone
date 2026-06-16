//
//  ApiKeyManager.swift
//  Pulse
//
//  Manages API keys for OSINTDog and Horus via the Keychain.
//  Validates keys using each service's health/status endpoint
//  per their respective API specs, and exposes validation state
//  to the rest of the app.
//

import Foundation
import Security

/// Reads, writes, and validates API keys for both intelligence services.
@Observable
final class ApiKeyManager {
    private(set) var osintdogState: ApiValidationState = .unknown
    private(set) var horusState: ApiValidationState = .unknown

    private let service = "com.pulse.osint"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Keychain access

    var osintdogKey: String? {
        get { readKey(account: "osintdog") }
        set { writeKey(account: "osintdog", value: newValue) }
    }

    var horusKey: String? {
        get { readKey(account: "horus") }
        set { writeKey(account: "horus", value: newValue) }
    }

    func hasKey(for source: DataSource) -> Bool {
        switch source {
        case .osintdog: return osintdogKey != nil
        case .horus: return horusKey != nil
        }
    }

    func key(for source: DataSource) -> String? {
        switch source {
        case .osintdog: return osintdogKey
        case .horus: return horusKey
        }
    }

    func clearKey(for source: DataSource) {
        switch source {
        case .osintdog:
            osintdogKey = nil
            osintdogState = .unknown
        case .horus:
            horusKey = nil
            horusState = .unknown
        }
    }

    // MARK: - Validation (per attached API specs)

    /// Validates the OSINTDog key by hitting GET /api/status.
    /// The API returns `{"status": "online", ...}` on success.
    func validateOSINTDog() async {
        guard let key = osintdogKey, !key.isEmpty else {
            osintdogState = .invalid(reason: "No key set")
            return
        }
        osintdogState = .validating
        do {
            var req = URLRequest(url: URL(string: "https://osintdog.com/api/status")!)
            req.setValue(key, forHTTPHeaderField: "X-API-Key")
            req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
            req.timeoutInterval = 15

            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                osintdogState = .error("No response")
                return
            }
            if http.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = json?["status"] as? String
                if status == "online" {
                    let version = json?["version"] as? String
                    osintdogState = .valid(plan: version)
                } else {
                    let msg = status ?? "Service unavailable"
                    osintdogState = .invalid(reason: msg)
                }
            } else if http.statusCode == 401 || http.statusCode == 403 {
                osintdogState = .invalid(reason: "Invalid API key")
            } else if http.statusCode == 429 {
                osintdogState = .error("Rate limited — wait and retry")
            } else {
                osintdogState = .error("Status \(http.statusCode)")
            }
        } catch {
            osintdogState = .error(error.localizedDescription)
        }
    }

    /// Validates the Horus key against GET /v1/search/stealer with a minimal query.
    /// A 200 with `{"success": true}` means the key is valid.
    func validateHorus() async {
        guard let key = horusKey, !key.isEmpty else {
            horusState = .invalid(reason: "No key set")
            return
        }
        horusState = .validating
        do {
            var components = URLComponents(string: "https://horus.st/api/v1/search/stealer")!
            components.queryItems = [
                URLQueryItem(name: "keyword", value: "health_check"),
                URLQueryItem(name: "limit", value: "1"),
            ]
            var req = URLRequest(url: components.url!)
            req.setValue(key, forHTTPHeaderField: "X-Api-Key")
            req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
            req.timeoutInterval = 15

            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                horusState = .error("No response")
                return
            }
            if http.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if json?["success"] as? Bool == true {
                    horusState = .valid(plan: nil)
                } else {
                    let errorDict = json?["error"] as? [String: Any]
                    let msg = errorDict?["message"] as? String ?? "API error"
                    horusState = .invalid(reason: msg)
                }
            } else if http.statusCode == 401 || http.statusCode == 403 {
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorDict = json?["error"] as? [String: Any]
                let msg = errorDict?["message"] as? String ?? "Invalid API key"
                horusState = .invalid(reason: msg)
            } else if http.statusCode == 429 {
                horusState = .error("Rate limited — wait and retry")
            } else {
                horusState = .error("Status \(http.statusCode)")
            }
        } catch {
            horusState = .error(error.localizedDescription)
        }
    }

    /// Re-validates any key that is currently stored.
    func validateAll() async {
        await withTaskGroup(of: Void.self) { group in
            if osintdogKey != nil {
                group.addTask { await self.validateOSINTDog() }
            }
            if horusKey != nil {
                group.addTask { await self.validateHorus() }
            }
        }
    }

    // MARK: - Private keychain helpers

    private func readKey(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    private func writeKey(account: String, value: String?) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard let value, !value.isEmpty else { return }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
