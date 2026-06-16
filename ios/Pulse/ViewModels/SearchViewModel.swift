//
//  SearchViewModel.swift
//  Pulse
//
//  Drives the Search panel: universal search bar, query execution,
//  result pagination, and error handling for both OSINTDog and Horus.
//  Uses the full API capabilities per the attached service specs.
//

import SwiftUI
import Observation

@Observable
final class SearchViewModel {
    private(set) var breachResults: [BreachResult] = []
    private(set) var stealerResults: [StealerLogResult] = []
    private(set) var recentQueries: [SearchQuery] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var hasMoreDog = false
    private(set) var hasMoreHorus = false
    private(set) var totalDog = 0
    private(set) var totalHorus = 0

    var searchTerm = ""
    var selectedType: SearchType = .email
    var horusField: HorusField = .all

    private let dogRepo: OSINTDogRepository
    private let horusRepo: HorusRepository
    private var currentDogPage = 0
    private var horusCursor: String?

    init(dogRepo: OSINTDogRepository = MockOSINTDogRepository(),
         horusRepo: HorusRepository = MockHorusRepository()) {
        self.dogRepo = dogRepo
        self.horusRepo = horusRepo
    }

    /// Runs a full search across both services for the current term and type.
    func search() async {
        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return }

        isLoading = true
        error = nil
        breachResults = []
        stealerResults = []
        currentDogPage = 0
        horusCursor = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchDog(term: term) }
            group.addTask { await self.fetchHorus(keyword: term) }
        }

        isLoading = false

        // Save to recent queries
        if !breachResults.isEmpty || !stealerResults.isEmpty {
            let query = SearchQuery(term: term, type: selectedType)
            recentQueries.insert(query, at: 0)
            if recentQueries.count > 10 { recentQueries = Array(recentQueries.prefix(10)) }
        }
    }

    /// Loads the next page of OSINTDog results.
    func loadMoreDog() async {
        guard hasMoreDog, !isLoading else { return }
        isLoading = true
        currentDogPage += 1
        await fetchDog(term: searchTerm.trimmingCharacters(in: .whitespaces), append: true)
        isLoading = false
    }

    /// Loads the next page of Horus results.
    func loadMoreHorus() async {
        guard hasMoreHorus, !isLoading else { return }
        isLoading = true
        await fetchHorus(keyword: searchTerm.trimmingCharacters(in: .whitespaces), append: true)
        isLoading = false
    }

    // MARK: - Private

    private func fetchDog(term: String, append: Bool = false) async {
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
        }
    }

    private func fetchHorus(keyword: String, append: Bool = false) async {
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
        }
    }
}
