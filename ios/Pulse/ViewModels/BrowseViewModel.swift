//
//  BrowseViewModel.swift
//  Pulse
//
//  Drives the Browse panel: stealer log browsing with source filters,
//  field filtering, date ranges, cursor pagination, and field-level copy.
//  Uses the full Horus partner v1 API capabilities.
//

import SwiftUI
import Observation

@Observable
final class BrowseViewModel {
    private(set) var logs: [StealerLogResult] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var filter: BrowseFilter = .all
    private(set) var fieldFilter: HorusField = .all
    private(set) var hasMore = false
    private(set) var totalCount = 0
    private(set) var copiedField: String?

    private let horusRepo: HorusRepository
    private var cursor: String?

    init(horusRepo: HorusRepository = MockHorusRepository()) {
        self.horusRepo = horusRepo
    }

    func load() async {
        isLoading = true
        error = nil
        cursor = nil
        do {
            let response = try await horusRepo.browseStealerLogs(
                limit: 20,
                cursor: nil,
                field: fieldFilter,
                dateFrom: nil,
                dateTo: nil
            )
            logs = response.results
            hasMore = response.hasMore
            cursor = response.cursor
            totalCount = response.total
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        do {
            let response = try await horusRepo.browseStealerLogs(
                limit: 20,
                cursor: cursor,
                field: fieldFilter,
                dateFrom: nil,
                dateTo: nil
            )
            logs.append(contentsOf: response.results)
            hasMore = response.hasMore
            cursor = response.cursor
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func selectFilter(_ newFilter: BrowseFilter) {
        filter = newFilter
    }

    func selectField(_ newField: HorusField) {
        fieldFilter = newField
    }

    /// Copies the given value to the clipboard and flashes a feedback indicator.
    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        copiedField = value
        Haptics.soft()
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedField == value { copiedField = nil }
        }
    }

    /// Filter logs by selected source (browse is Horus-only; mock for OSINTDog).
    var filteredLogs: [StealerLogResult] {
        switch filter {
        case .all: return logs
        case .osintdog: return []
        case .horus: return logs
        }
    }
}
