//
//  OverviewViewModel.swift
//  Pulse
//
//  State and loading logic for the Overview panel.
//

import SwiftUI
import Observation

/// Drives the Overview panel: headline metrics, summary strip, recent items.
@Observable
final class OverviewViewModel {
    private(set) var metrics: [StatMetric] = []
    private(set) var summary: [SummaryItem] = []
    private(set) var recentItems: [RecentItem] = []
    private(set) var isLoading = true

    private let repository: DashboardRepository

    init(repository: DashboardRepository = MockDashboardRepository()) {
        self.repository = repository
    }

    /// A friendly greeting based on the current time of day.
    var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    /// Loads all overview data concurrently.
    func load() async {
        isLoading = true
        async let metrics = repository.loadMetrics()
        async let summary = repository.loadSummary()
        async let recent = repository.loadRecentItems()
        self.metrics = await metrics
        self.summary = await summary
        self.recentItems = await recent
        isLoading = false
    }
}
