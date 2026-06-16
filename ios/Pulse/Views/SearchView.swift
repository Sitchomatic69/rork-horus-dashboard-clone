//
//  SearchView.swift
//  Pulse
//
//  The Search panel: universal search bar, type selector, and a
//  two-section results feed (OSINTDog breaches + Horus stealer logs)
//  with pagination.
//

import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        DashboardScreen {
            DashboardHeader(title: "Search", subtitle: "Query intelligence sources")
        } content: {
            searchArea

            if let error = viewModel.error, !viewModel.isLoading {
                errorBanner(error)
            }

            if viewModel.isLoading && viewModel.breachResults.isEmpty && viewModel.stealerResults.isEmpty {
                loadingState
            } else {
                if !viewModel.breachResults.isEmpty {
                    osintdogSection
                }
                if !viewModel.stealerResults.isEmpty {
                    horusSection
                }
                if viewModel.breachResults.isEmpty && viewModel.stealerResults.isEmpty && !viewModel.isLoading {
                    emptyState
                }
            }
        }
    }

    // MARK: - Search

    private var searchArea: some View {
        SearchBarView(
            text: $viewModel.searchTerm,
            selectedType: $viewModel.selectedType,
            isSearching: viewModel.isLoading,
            onSubmit: { Task { await viewModel.search() } }
        )
    }

    // MARK: - OSINTDog results

    private var osintdogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "OSINTDog · \(viewModel.totalDog) results")
                Spacer()
                SourceBadge(name: "OSINTDog", color: Theme.accent)
            }
            VStack(spacing: 10) {
                ForEach(viewModel.breachResults) { result in
                    BreachResultCard(result: result)
                }
            }
            if viewModel.hasMoreDog {
                loadMoreButton("Load more OSINTDog…") {
                    Task { await viewModel.loadMoreDog() }
                }
            }
        }
    }

    // MARK: - Horus results

    private var horusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Horus · \(viewModel.totalHorus) stealer logs")
                Spacer()
                SourceBadge(name: "Horus", color: Theme.cyan)
            }
            VStack(spacing: 10) {
                ForEach(viewModel.stealerResults) { log in
                    StealerResultCard(log: log, onCopy: { _ in }, copiedField: nil)
                }
            }
            if viewModel.hasMoreHorus {
                loadMoreButton("Load more Horus…") {
                    Task { await viewModel.loadMoreHorus() }
                }
            }
        }
    }

    // MARK: - States

    private func loadMoreButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if viewModel.isLoading {
                    ProgressView().tint(Theme.accent)
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.coral)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.coral)
            Spacer()
        }
        .padding(12)
        .background(Theme.coral.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("Search for emails, usernames,\ndomains, or IPs")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonBlock(height: 140, cornerRadius: Theme.cornerMedium)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
