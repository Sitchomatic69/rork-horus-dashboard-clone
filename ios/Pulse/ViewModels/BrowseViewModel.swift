//
//  BrowseViewModel.swift
//  Pulse
//
//  Drives the Browse panel: a live stealer log feed built by querying the
//  Horus API across a curated set of popular domains in parallel, with
//  per-keyword cursor pagination, field filtering, and field-level copy.
//
//  The Horus /v1/search/stealer endpoint requires a real keyword (>= 2
//  chars) and offers no wildcard or recent-feed mode, so the feed is
//  assembled from multiple keyword queries merged into one timeline.
//

import SwiftUI
import Observation

@Observable
final class BrowseViewModel {
    /// Popular domains used to assemble the live feed.
    static let feedKeywords = [
        "gmail.com", "hotmail.com", "yahoo.com",
        "facebook.com", "instagram.com", "paypal.com",
    ]

    /// Results fetched per keyword per page.
    static let limitPerKeyword = 10

    private(set) var logs: [StealerLogResult] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var filter: BrowseFilter = .all
    private(set) var fieldFilter: HorusField = .all
    private(set) var hasMore = false
    private(set) var totalCount = 0
    private(set) var copiedField: String?

    private let apiKeyManager: ApiKeyManager
    private let horusRepo: HorusRepository

    /// Next-page cursor per feed keyword.
    private var cursors: [String: String] = [:]

    init(apiKeyManager: ApiKeyManager,
         horusRepo: HorusRepository? = nil) {
        self.apiKeyManager = apiKeyManager
        self.horusRepo = horusRepo ?? LiveHorusRepository(apiKeyManager: apiKeyManager)
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        error = nil
        cursors = [:]
        logs = []

        var collected: [StealerLogResult] = []
        var total = 0
        var firstError: Error?
        var newCursors: [String: String] = [:]

        await withTaskGroup(of: (String, Result<HorusSearchResponse, Error>).self) { group in
            for keyword in Self.feedKeywords {
                group.addTask {
                    do {
                        let response = try await self.horusRepo.searchStealer(
                            keyword: keyword,
                            field: self.fieldFilter,
                            dateFrom: nil,
                            dateTo: nil,
                            limit: Self.limitPerKeyword,
                            cursor: nil
                        )
                        return (keyword, .success(response))
                    } catch {
                        return (keyword, .failure(error))
                    }
                }
            }
            for await (keyword, result) in group {
                switch result {
                case .success(let response):
                    collected.append(contentsOf: response.results)
                    total += response.total
                    if let cursor = response.cursor {
                        newCursors[keyword] = cursor
                    }
                case .failure(let err):
                    if firstError == nil { firstError = err }
                }
            }
        }

        cursors = newCursors
        hasMore = !newCursors.isEmpty
        totalCount = total
        logs = Self.merged(collected)

        if collected.isEmpty, let err = firstError {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true

        var collected: [StealerLogResult] = []
        var firstError: Error?
        var newCursors: [String: String] = [:]

        await withTaskGroup(of: (String, Result<HorusSearchResponse, Error>).self) { group in
            for (keyword, cursor) in cursors {
                group.addTask {
                    do {
                        let response = try await self.horusRepo.searchStealer(
                            keyword: keyword,
                            field: self.fieldFilter,
                            dateFrom: nil,
                            dateTo: nil,
                            limit: Self.limitPerKeyword,
                            cursor: cursor
                        )
                        return (keyword, .success(response))
                    } catch {
                        return (keyword, .failure(error))
                    }
                }
            }
            for await (keyword, result) in group {
                switch result {
                case .success(let response):
                    collected.append(contentsOf: response.results)
                    if let cursor = response.cursor {
                        newCursors[keyword] = cursor
                    }
                case .failure(let err):
                    if firstError == nil { firstError = err }
                }
            }
        }

        cursors = newCursors
        hasMore = !newCursors.isEmpty && !collected.isEmpty
        logs = Self.merged(logs + collected)

        if collected.isEmpty, let err = firstError {
            error = err.localizedDescription
        }
        isLoading = false
    }

    func selectField(_ newField: HorusField) async {
        guard newField != fieldFilter else { return }
        fieldFilter = newField
        await load()
    }

    func selectFilter(_ newFilter: BrowseFilter) {
        filter = newFilter
    }

    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        copiedField = value
        Haptics.soft()
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedField == value { copiedField = nil }
        }
    }

    /// Filter logs by selected source.
    var filteredLogs: [StealerLogResult] {
        switch filter {
        case .all: return logs
        case .osintdog: return []
        case .horus: return logs
        }
    }

    // MARK: - Merging

    /// Deduplicates by id and sorts newest-first (undated entries last).
    private static func merged(_ logs: [StealerLogResult]) -> [StealerLogResult] {
        var seen = Set<String>()
        var unique: [StealerLogResult] = []
        unique.reserveCapacity(logs.count)
        for log in logs where seen.insert(log.id).inserted {
            unique.append(log)
        }
        return unique.sorted {
            ($0.capturedAt ?? .distantPast) > ($1.capturedAt ?? .distantPast)
        }
    }
}
