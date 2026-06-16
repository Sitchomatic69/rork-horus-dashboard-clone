//
//  SearchView.swift
//  Pulse
//
//  The Search panel: universal search bar with type selection,
//  result tabs for breach data (OSINTDog) and stealer logs (Horus),
//  pagination, and detailed result cards.
//

import SwiftUI

struct SearchView: View {
    let apiKeyManager: ApiKeyManager
    @State private var viewModel: SearchViewModel

    init(apiKeyManager: ApiKeyManager) {
        self.apiKeyManager = apiKeyManager
        self._viewModel = State(wrappedValue: SearchViewModel(apiKeyManager: apiKeyManager))
    }

    var body: some View {
        DashboardScreen {
            header
        } content: {
            searchBar
            if viewModel.isLoading && viewModel.breachResults.isEmpty && viewModel.stealerResults.isEmpty {
                loadingState
            } else if let error = viewModel.error, viewModel.breachResults.isEmpty && viewModel.stealerResults.isEmpty {
                errorState(error)
            } else if !viewModel.breachResults.isEmpty || !viewModel.stealerResults.isEmpty {
                resultsSection
            } else {
                emptyState
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Search")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Breach data & stealer logs across 15+ sources")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 12)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        VStack(spacing: 10) {
            SearchBarView(
                text: $viewModel.searchTerm,
                selectedType: $viewModel.selectedType,
                isSearching: viewModel.isLoading,
                onSubmit: { Task { await viewModel.search() } }
            )

            HStack(spacing: 8) {
                Text("Horus field:")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(HorusField.allCases) { field in
                            FilterChip(
                                title: field.rawValue,
                                isSelected: viewModel.horusField == field,
                                action: { viewModel.horusField = field }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !viewModel.breachResults.isEmpty {
                resultsGroup(
                    title: "Breach Records — OSINTDog",
                    count: viewModel.totalDog,
                    tint: Theme.accent,
                    results: viewModel.breachResults.map { breach in
                        ResultCardData.breach(breach)
                    },
                    hasMore: viewModel.hasMoreDog,
                    onLoadMore: { Task { await viewModel.loadMoreDog() } }
                )
            }

            if !viewModel.stealerResults.isEmpty {
                resultsGroup(
                    title: "Stealer Logs — Horus",
                    count: viewModel.totalHorus,
                    tint: Theme.cyan,
                    results: viewModel.stealerResults.map { log in
                        ResultCardData.stealer(log)
                    },
                    hasMore: viewModel.hasMoreHorus,
                    onLoadMore: { Task { await viewModel.loadMoreHorus() } }
                )
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(Theme.accent)
                    Spacer()
                }
            }
        }
    }

    private func resultsGroup(
        title: String,
        count: Int,
        tint: Color,
        results: [ResultCardData],
        hasMore: Bool,
        onLoadMore: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
                Text("\(count) total")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }

            LazyVStack(spacing: 10) {
                ForEach(results) { data in
                    ResultCard(data: data)
                }

                if hasMore {
                    Button(action: onLoadMore) {
                        Text("Load more…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            ForEach(0..<4, id: \.self) { _ in
                SkeletonBlock(height: 80)
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.negative)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textTertiary)
            Text("Enter a search term above\nto query breach databases")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    SearchView(apiKeyManager: ApiKeyManager())
        .preferredColorScheme(.dark)
}
