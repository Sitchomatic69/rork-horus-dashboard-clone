//
//  ApiKeyManager.swift
//  Pulse
//
//  Manages API keys for OSINTDog and Horus via the Keychain.
//  Validates keys using the same endpoint, timeout, and response
//  handling as the live repositories — one source of truth for
//  what "healthy" means.
//

import Foundation
import Security

/// Reads, writes, and validates API keys for both intelligence services.
@Observable
final class ApiKeyManager {
    private(set) var osintdogState: ApiValidationState = .unknown
    private(set) var horusState: ApiValidationState = .unknown

    /// Holds the most recent validation error per source so the UI
    /// can surface exactly what went wrong.
    private(set) var lastOSINTDogError: String?
    private(set) var lastHorusError: String?

    private let service = "com.pulse.osint"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        logEnvProvisioning()
    }

    // MARK: - Environment diagnostics

    /// Logs whether env-provisioned keys are present at runtime.
    /// This surfaces build-pipeline issues: if Config values are
    /// empty strings, the env vars didn't get injected.
    private func logEnvProvisioning() {
        let dogRaw = Config.EXPO_PUBLIC_OSINTDOG_API_KEY
        let horusRaw = Config.EXPO_PUBLIC_HORUS_API_KEY

        let dogStatus = dogRaw.isEmpty ? "MISSING (empty string — check env injection)" : "present (\(dogRaw.prefix(8))...)"
        let horusStatus = horusRaw.isEmpty ? "MISSING (empty string — check env injection)" : "present (\(horusRaw.prefix(8))...)"

        print("[Pulse] OSINTDog env key: \(dogStatus)")
        print("[Pulse] Horus env key: \(horusStatus)")
    }

    /// Returns true when the environment key is empty — meaning the
    /// build pipeline didn't inject it, not that the user removed it.
    func isEnvKeyMissing(for source: DataSource) -> Bool {
        switch source {
        case .osintdog: return Config.EXPO_PUBLIC_OSINTDOG_API_KEY.isEmpty
        case .horus: return Config.EXPO_PUBLIC_HORUS_API_KEY.isEmpty
        }
    }

    // MARK: - Environment fallbacks

    /// Keys provisioned via public env variables (compiled into Config).
    /// Used when the user hasn't stored their own key in the Keychain.
    private var envOSINTDogKey: String? {
        let value = Config.EXPO_PUBLIC_OSINTDOG_API_KEY
        return value.isEmpty ? nil : value
    }

    private var envHorusKey: String? {
        let value = Config.EXPO_PUBLIC_HORUS_API_KEY
        return value.isEmpty ? nil : value
    }

    // MARK: - Keychain access

    /// Returns the user-stored key if present, otherwise the env-provisioned key.
    var osintdogKey: String? {
        get { readKey(account: "osintdog") ?? envOSINTDogKey }
        set { writeKey(account: "osintdog", value: newValue) }
    }

    var horusKey: String? {
        get { readKey(account: "horus") ?? envHorusKey }
        set { writeKey(account: "horus", value: newValue) }
    }

    /// Whether the active key comes from the environment rather than the Keychain.
    func isUsingEnvKey(for source: DataSource) -> Bool {
        switch source {
        case .osintdog: return readKey(account: "osintdog") == nil && envOSINTDogKey != nil
        case .horus: return readKey(account: "horus") == nil && envHorusKey != nil
        }
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
            lastOSINTDogError = nil
        case .horus:
            horusKey = nil
            horusState = .unknown
            lastHorusError = nil
        }
    }

    // MARK: - Validation (matches repository logic exactly)

    // Both validations use:
    //  - The same endpoint path as their respective repository's health method
    //  - 30-second timeout (matches repository)
    //  - Same header names and User-Agent
    //  - Same response shape parsing

    /// Validates the OSINTDog key by hitting GET /api/status.
    /// Matches LiveOSINTDogRepository.checkStatus() — same endpoint,
    /// same 30s timeout, same "status == online" check.
    func validateOSINTDog() async {
        guard let key = osintdogKey, !key.isEmpty else {
            if isEnvKeyMissing(for: .osintdog) {
                osintdogState = .invalid(reason: "Not provisioned — check build env")
                lastOSINTDogError = "OSINTDog API key env variable is empty"
            } else {
                osintdogState = .invalid(reason: "No key set")
                lastOSINTDogError = "No OSINTDog API key configured"
            }
            return
        }
        osintdogState = .validating
        lastOSINTDogError = nil

        do {
            var req = URLRequest(url: URL(string: "https://osintdog.com/api/status")!)
            req.setValue(key, forHTTPHeaderField: "X-API-Key")
            req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
            req.timeoutInterval = 30

            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                osintdogState = .error("No response from server")
                lastOSINTDogError = "No HTTP response received"
                return
            }

            // Log the raw response to help diagnose issues
            let bodyPreview = String(data: data, encoding: .utf8)?.prefix(200) ?? "<non-utf8>"
            print("[Pulse] OSINTDog /api/status → HTTP \(http.statusCode): \(bodyPreview)")

            switch http.statusCode {
            case 200:
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let status = json?["status"] as? String
                if status == "online" {
                    let version = json?["version"] as? String
                    osintdogState = .valid(plan: version)
                } else {
                    let msg = status ?? "Service unavailable"
                    osintdogState = .invalid(reason: msg)
                    lastOSINTDogError = "Status endpoint returned \"\(msg)\""
                }
            case 401, 403:
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let detail = json?["message"] as? String ?? "Invalid API key"
                osintdogState = .invalid(reason: "Key rejected (HTTP \(http.statusCode))")
                lastOSINTDogError = detail
            case 429:
                osintdogState = .error("Rate limited — wait and retry")
                lastOSINTDogError = "Rate limited by OSINTDog (HTTP 429)"
            case let code where code >= 500:
                osintdogState = .error("Server error \(code)")
                lastOSINTDogError = "OSINTDog server error (HTTP \(code))"
            default:
                osintdogState = .error("Unexpected HTTP \(http.statusCode)")
                lastOSINTDogError = "HTTP \(http.statusCode): \(bodyPreview)"
            }
        } catch let error as URLError where error.code == .timedOut {
            osintdogState = .error("Network timeout — try again")
            lastOSINTDogError = "Request timed out after 30s"
        } catch {
            osintdogState = .error(error.localizedDescription)
            lastOSINTDogError = error.localizedDescription
        }
    }

    /// Validates the Horus key against GET /v1/health — the dedicated
    /// Horus health endpoint. Matches LiveHorusRepository.checkHealth()
    /// exactly: same endpoint, same 30s timeout, same auth header.
    func validateHorus() async {
        guard let key = horusKey, !key.isEmpty else {
            if isEnvKeyMissing(for: .horus) {
                horusState = .invalid(reason: "Not provisioned — check build env")
                lastHorusError = "Horus API key env variable is empty"
            } else {
                horusState = .invalid(reason: "No key set")
                lastHorusError = "No Horus API key configured"
            }
            return
        }
        horusState = .validating
        lastHorusError = nil

        do {
            var req = URLRequest(url: URL(string: "https://horus.st/api/v1/health")!)
            req.setValue(key, forHTTPHeaderField: "X-Api-Key")
            req.setValue("Pulse/1.0", forHTTPHeaderField: "User-Agent")
            req.timeoutInterval = 30

            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                horusState = .error("No response from server")
                lastHorusError = "No HTTP response received"
                return
            }

            // Log the raw response to help diagnose issues
            let bodyPreview = String(data: data, encoding: .utf8)?.prefix(200) ?? "<non-utf8>"
            print("[Pulse] Horus /v1/health → HTTP \(http.statusCode): \(bodyPreview)")

            switch http.statusCode {
            case 200...299:
                horusState = .valid(plan: nil)
            case 401, 403:
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorDict = json?["error"] as? [String: Any]
                let msg = errorDict?["message"] as? String ?? "Invalid API key"
                horusState = .invalid(reason: "Key rejected (HTTP \(http.statusCode))")
                lastHorusError = msg
            case 429:
                horusState = .error("Rate limited — wait and retry")
                lastHorusError = "Rate limited by Horus (HTTP 429)"
            case let code where code >= 500:
                horusState = .error("Server error \(code)")
                lastHorusError = "Horus server error (HTTP \(code))"
            default:
                horusState = .error("Unexpected HTTP \(http.statusCode)")
                lastHorusError = "HTTP \(http.statusCode): \(bodyPreview)"
            }
        } catch let error as URLError where error.code == .timedOut {
            horusState = .error("Network timeout — try again")
            lastHorusError = "Request timed out after 30s"
        } catch {
            horusState = .error(error.localizedDescription)
            lastHorusError = error.localizedDescription
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
