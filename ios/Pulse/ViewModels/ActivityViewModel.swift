//
//  ActivityViewModel.swift
//  Pulse
//
//  State and loading logic for the Activity panel, including day grouping
//  and category filtering.
//

import SwiftUI
import Observation

/// Drives the Activity panel: loading, filtering, and grouping events by day.
@Observable
final class ActivityViewModel {
    private(set) var sections: [ActivitySection] = []
    private(set) var isLoading = true
    private(set) var filter: ActivityCategory?

    private var allEvents: [ActivityEvent] = []
    private let repository: DashboardRepository

    init(repository: DashboardRepository = MockDashboardRepository()) {
        self.repository = repository
    }

    /// Loads activity events and builds the grouped sections.
    func load() async {
        isLoading = true
        allEvents = await repository.loadActivity()
        rebuild()
        isLoading = false
    }

    /// Applies (or clears) a category filter and rebuilds sections.
    func setFilter(_ category: ActivityCategory?) {
        filter = category
        rebuild()
    }

    // MARK: - Private

    private func rebuild() {
        let filtered = filter.map { category in
            allEvents.filter { $0.category == category }
        } ?? allEvents
        sections = ActivityViewModel.group(filtered)
    }

    /// Groups events into day buckets sorted newest-first.
    private static func group(_ events: [ActivityEvent]) -> [ActivitySection] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.date)
        }
        return buckets.keys.sorted(by: >).map { day in
            let title = relativeTitle(for: day, calendar: calendar)
            let events = (buckets[day] ?? []).sorted { $0.date > $1.date }
            return ActivitySection(id: title, title: title, events: events)
        }
    }

    private static func relativeTitle(for day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}
