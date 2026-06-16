//
//  SettingsViewModel.swift
//  Pulse
//
//  Drives the Settings panel: API key management for both services,
//  key validation, clear/remove actions, and app info.
//

import SwiftUI
import Observation

@Observable
final class SettingsViewModel {
    let apiKeyManager: ApiKeyManager

    var osintdogKey: String {
        get { apiKeyManager.osintdogKey ?? "" }
        set { apiKeyManager.osintdogKey = newValue.isEmpty ? nil : newValue }
    }

    var horusKey: String {
        get { apiKeyManager.horusKey ?? "" }
        set { apiKeyManager.horusKey = newValue.isEmpty ? nil : newValue }
    }

    var osintdogState: ApiValidationState { apiKeyManager.osintdogState }
    var horusState: ApiValidationState { apiKeyManager.horusState }

    let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()

    init(apiKeyManager: ApiKeyManager = ApiKeyManager()) {
        self.apiKeyManager = apiKeyManager
    }

    func validateOSINTDog() async {
        await apiKeyManager.validateOSINTDog()
    }

    func validateHorus() async {
        await apiKeyManager.validateHorus()
    }

    func clearOSINTDog() {
        apiKeyManager.clearKey(for: .osintdog)
    }

    func clearHorus() {
        apiKeyManager.clearKey(for: .horus)
    }

    // MARK: - Status helpers

    func statusLabel(for state: ApiValidationState) -> String {
        switch state {
        case .unknown: return "Not checked"
        case .validating: return "Validating..."
        case .valid(let plan): return plan.map { "Active — \($0)" } ?? "Active"
        case .invalid(let reason): return reason ?? "Invalid key"
        case .error(let msg): return msg
        }
    }

    func statusColor(for state: ApiValidationState) -> Color {
        switch state {
        case .valid: return Theme.positive
        case .invalid, .error: return Theme.negative
        case .validating: return Theme.accent
        case .unknown: return Theme.textTertiary
        }
    }

    func statusIcon(for state: ApiValidationState) -> String {
        switch state {
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .validating: return "arrow.triangle.2.circlepath"
        case .unknown: return "questionmark.circle"
        }
    }
}
