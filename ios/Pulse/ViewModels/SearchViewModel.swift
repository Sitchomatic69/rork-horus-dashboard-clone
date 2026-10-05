//
//  SearchViewModel.swift
//  Pulse
//
//  Drives the Search panel: universal search bar, query execution,
//  result pagination, and error handling for both OSINTDog and Horus.
//

import SwiftUI
import Observation

@Observable
final class SearchViewModel {
    private(set) var breachResults: [BreachResult] = []
    private(set) var stealerResults: [StealerLogResult] = []
    private(set) var dehashedResults: [BreachResult] = []
    private(set) var recentQueries: [SearchQuery] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var hasMoreDog = false
    private(set) var hasMoreHorus = false
    private(set) var hasMoreDehashed = false
    private(set) var totalDog = 0
    private(set) var totalHorus = 0
    private(set) var totalDeHashed = 0
    private(set) var isExporting = false

    var searchTerm = ""
    var selectedType: SearchType = .email
    var horusField: HorusField = .all

    private let apiKeyManager: ApiKeyManager
    private let dogRepo: OSINTDogRepository
    private let horusRepo: HorusRepository
    private let dehashedRepo: DeHashedRepository
    private var currentDogPage = 0
    private var currentDeHashedPage = 1
    private var horusCursor: String?

    init(apiKeyManager: ApiKeyManager,
         dogRepo: OSINTDogRepository? = nil,
         horusRepo: HorusRepository? = nil,
         dehashedRepo: DeHashedRepository? = nil) {
        self.apiKeyManager = apiKeyManager
        self.dogRepo = dogRepo ?? LiveOSINTDogRepository(apiKeyManager: apiKeyManager)
        self.horusRepo = horusRepo ?? LiveHorusRepository(apiKeyManager: apiKeyManager)
        self.dehashedRepo = dehashedRepo ?? LiveDeHashedRepository(apiKeyManager: apiKeyManager)
    }

    /// Runs a full search across all three services for the current term and type.
    func search() async {
        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return }

        isLoading = true
        error = nil
        breachResults = []
        stealerResults = []
        dehashedResults = []
        currentDogPage = 0
        currentDeHashedPage = 1
        horusCursor = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchDog(term: term) }
            group.addTask { await self.fetchHorus(keyword: term) }
            group.addTask { await self.fetchDeHashed(term: term) }
        }

        isLoading = false

        if !breachResults.isEmpty || !stealerResults.isEmpty || !dehashedResults.isEmpty {
            let query = SearchQuery(term: term, type: selectedType)
            recentQueries.insert(query, at: 0)
            if recentQueries.count > 10 { recentQueries = Array(recentQueries.prefix(10)) }
        }
    }

    func loadMoreDeHashed() async {
        guard hasMoreDehashed, !isLoading else { return }
        isLoading = true
        currentDeHashedPage += 1
        await fetchDeHashed(term: searchTerm.trimmingCharacters(in: .whitespaces), append: true)
        isLoading = false
    }

    func loadMoreDog() async {
        guard hasMoreDog, !isLoading else { return }
        isLoading = true
        currentDogPage += 1
        await fetchDog(term: searchTerm.trimmingCharacters(in: .whitespaces), append: true)
        isLoading = false
    }

    func loadMoreHorus() async {
        guard hasMoreHorus, !isLoading else { return }
        isLoading = true
        await fetchHorus(keyword: searchTerm.trimmingCharacters(in: .whitespaces), append: true)
        isLoading = false
    }

    /// Fetches every remaining page from all three sources so an export
    /// contains the complete result set, not just the loaded pages.
    /// Calls with no more pages simply return quickly.
    func fetchAllPages() async {
        guard !isExporting, !isLoading else { return }
        isExporting = true
        defer { isExporting = false }

        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.drainDog(term: term) }
            group.addTask { await self.drainHorus(term: term) }
            group.addTask { await self.drainDeHashed(term: term) }
        }
    }

    // MARK: - Private

    /// Page cap per source as a safety net against APIs that never
    /// clear their `hasMore` flag.
    private static let maxDrainPages = 100

    @discardableResult
    private func fetchDog(term: String, append: Bool = false) async -> Bool {
        do {
            let response = try await dogRepo.search(term: term, type: selectedType, page: currentDogPage)
            if append {
                breachResults.append(contentsOf: response.results)
            } else {
                breachResults = response.results
            }
            hasMoreDog = response.hasMore
            totalDog = response.total
        } catch {
            self.error = error.localizedDescription
            return false
        }
        return true
    }

    @discardableResult
    private func fetchHorus(keyword: String, append: Bool = false) async -> Bool {
        do {
            let response = try await horusRepo.searchStealer(
                keyword: keyword,
                field: horusField,
                dateFrom: nil,
                dateTo: nil,
                limit: 20,
                cursor: horusCursor
            )
            if append {
                stealerResults.append(contentsOf: response.results)
            } else {
                stealerResults = response.results
            }
            hasMoreHorus = response.hasMore
            horusCursor = response.cursor
            totalHorus = response.total
        } catch {
            if self.error == nil { self.error = error.localizedDescription }
            return false
        }
        return true
    }

    @discardableResult
    private func fetchDeHashed(term: String, append: Bool = false) async -> Bool {
        do {
            let response = try await dehashedRepo.search(
                term: term,
                type: selectedType,
                page: currentDeHashedPage
            )
            if append {
                dehashedResults.append(contentsOf: response.results)
            } else {
                dehashedResults = response.results
            }
            hasMoreDehashed = response.hasMore
            totalDeHashed = response.total
        } catch RepositoryError.missingKey {
            // No key configured — skip silently; the Dashboard shows setup state.
            return false
        } catch {
            if self.error == nil { self.error = error.localizedDescription }
            return false
        }
        return true
    }

    private func drainDog(term: String) async {
        var page = 0
        while hasMoreDog && page < Self.maxDrainPages {
            page += 1
            currentDogPage += 1
            guard await fetchDog(term: term, append: true) else { break }
        }
    }

    private func drainHorus(term: String) async {
        var page = 0
        while hasMoreHorus && page < Self.maxDrainPages {
            page += 1
            guard await fetchHorus(keyword: term, append: true) else { break }
        }
    }

    private func drainDeHashed(term: String) async {
        var page = 0
        while hasMoreDehashed && page < Self.maxDrainPages {
            page += 1
            currentDeHashedPage += 1
            guard await fetchDeHashed(term: term, append: true) else { break }
        }
    }
}
