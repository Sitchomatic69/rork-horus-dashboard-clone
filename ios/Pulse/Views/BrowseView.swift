//
//  BrowseView.swift
//  Pulse
//
//  The Browse panel: stealer log browsing with source filters,
//  field filtering, date ranges, cursor pagination, and field-level copy.
//  Uses the full Horus partner v1 API capabilities.
//

import SwiftUI

struct BrowseView: View {
    let apiKeyManager: ApiKeyManager
    @State private var viewModel: BrowseViewModel

    init(apiKeyManager: ApiKeyManager) {
        self.apiKeyManager = apiKeyManager
        self._viewModel = State(wrappedValue: BrowseViewModel(apiKeyManager: apiKeyManager))
    }

    var body: some View {
        DashboardScreen {
            header
        } content: {
            filterBar
            if viewModel.isLoading && viewModel.filteredLogs.isEmpty {
                loadingState
            } else if let error = viewModel.error, viewModel.filteredLogs.isEmpty {
                errorState(error)
            } else if viewModel.filteredLogs.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Browse")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Recent stealer logs across monitored sources")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 12)
    }

    // MARK: - Filters

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(BrowseFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.filter == filter,
                        action: { viewModel.selectFilter(filter) }
                    )
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(HorusField.allCases) { field in
                        FilterChip(
                            title: field.rawValue,
                            isSelected: viewModel.fieldFilter == field,
                            action: { viewModel.selectField(field) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Results

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(viewModel.totalCount) logs")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
                if viewModel.isLoading {
                    ProgressView().scaleEffect(0.7).tint(Theme.cyan)
                }
            }

            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredLogs) { log in
                    ResultCard(data: .stealer(log))
                        .contextMenu {
                            if let username = log.username {
                                Button { viewModel.copyToClipboard(username) } label: {
                                    Label("Copy username", systemImage: "person")
                                }
                            }
                            if let password = log.password {
                                Button { viewModel.copyToClipboard(password) } label: {
                                    Label("Copy password", systemImage: "key")
                                }
                            }
                            if let ip = log.ip {
                                Button { viewModel.copyToClipboard(ip) } label: {
                                    Label("Copy IP", systemImage: "network")
                                }
                            }
                            if let domain = log.domain {
                                Button { viewModel.copyToClipboard(domain) } label: {
                                    Label("Copy domain", systemImage: "globe")
                                }
                            }
                        }
                }

                if viewModel.hasMore {
                    Button(action: { Task { await viewModel.loadMore() } }) {
                        Text("Load more…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.cyan)
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
            ForEach(0..<5, id: \.self) { _ in
                SkeletonBlock(height: 72)
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
            Button("Retry") { Task { await viewModel.load() } }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textTertiary)
            Text("No logs found with current filters")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    BrowseView(apiKeyManager: ApiKeyManager())
        .preferredColorScheme(.dark)
}
