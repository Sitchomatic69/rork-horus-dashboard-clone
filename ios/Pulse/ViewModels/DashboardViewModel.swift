//
//  DashboardViewModel.swift
//  Pulse
//
//  Drives the Dashboard panel: greeting, API health statuses,
//  recent search activity, and quick stats from both services.
//

import SwiftUI
import Observation

@Observable
final class DashboardViewModel {
    private(set) var recentQueries: [SearchQuery] = []
    private(set) var isLoading = true

    /// API health indicators — read from the shared ApiKeyManager.
    var dogStatus: ApiValidationState { apiKeyManager.osintdogState }
    var horusStatus: ApiValidationState { apiKeyManager.horusState }

    /// Detailed error messages from the last validation attempt.
    var lastDogError: String? { apiKeyManager.lastOSINTDogError }
    var lastHorusError: String? { apiKeyManager.lastHorusError }

    /// Session-level search counters.
    private(set) var searchesRun = 0
    private(set) var totalResultsFound = 0
    private(set) var lastSearchDate: Date?

    private let apiKeyManager: ApiKeyManager
    private let dogRepo: OSINTDogRepository
    private let horusRepo: HorusRepository

    init(apiKeyManager: ApiKeyManager,
         dogRepo: OSINTDogRepository? = nil,
         horusRepo: HorusRepository? = nil) {
        self.apiKeyManager = apiKeyManager
        self.dogRepo = dogRepo ?? LiveOSINTDogRepository(apiKeyManager: apiKeyManager)
        self.horusRepo = horusRepo ?? LiveHorusRepository(apiKeyManager: apiKeyManager)
    }

    var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    /// Re-validates all configured API keys via the shared manager.
    func load() async {
        isLoading = true
        await apiKeyManager.validateAll()
        isLoading = false
    }

    /// Called after a successful search to update dashboard stats.
    func recordSearch(query: String, dogCount: Int, horusCount: Int) {
        searchesRun += 1
        totalResultsFound += dogCount + horusCount
        lastSearchDate = Date()
        recentQueries.insert(SearchQuery(term: query, type: .email), at: 0)
        if recentQueries.count > 5 { recentQueries = Array(recentQueries.prefix(5)) }
    }

    /// Returns the last validation error for a given API, if the key is unhealthy.
    func errorFor(name: String) -> String? {
        switch name {
        case "OSINTDog":
            if case .invalid = dogStatus { return lastDogError }
            if case .error = dogStatus { return lastDogError }
            return nil
        case "Horus":
            if case .invalid = horusStatus { return lastHorusError }
            if case .error = horusStatus { return lastHorusError }
            return nil
        default:
            return nil
        }
    }

    /// Formatted string for API key status display.
    func statusLabel(for state: ApiValidationState) -> String {
        switch state {
        case .unknown: return "Not checked"
        case .validating: return "Checking..."
        case .valid(let plan): return plan.map { "Active — \($0)" } ?? "Active"
        case .invalid(let reason): return reason ?? "Invalid"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}
