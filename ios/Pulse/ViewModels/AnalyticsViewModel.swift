//
//  AnalyticsViewModel.swift
//  Pulse
//
//  State and loading logic for the Analytics panel.
//

import SwiftUI
import Observation

/// Drives the Analytics panel: range selection and chart data.
@Observable
final class AnalyticsViewModel {
    private(set) var data: AnalyticsData?
    private(set) var range: AnalyticsRange = .week
    private(set) var isLoading = true

    private let repository: DashboardRepository

    init(repository: DashboardRepository = MockDashboardRepository()) {
        self.repository = repository
    }

    /// Loads chart data for the current range.
    func load() async {
        isLoading = true
        data = await repository.loadAnalytics(range: range)
        isLoading = false
    }

    /// Switches the visible time range and reloads if it changed.
    func select(_ newRange: AnalyticsRange) async {
        guard newRange != range else { return }
        range = newRange
        await load()
    }
}
