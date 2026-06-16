//
//  BrowseView.swift
//  Pulse
//
//  The Browse panel: stealer log explorer with source filters,
//  paginated log cards with metadata, and field-level copy support.
//

import SwiftUI

struct BrowseView: View {
    @State private var viewModel = BrowseViewModel()

    var body: some View {
        DashboardScreen {
            DashboardHeader(title: "Browse", subtitle: "Explore stealer log intelligence")
        } content: {
            filterBar

            if let error = viewModel.error, !viewModel.isLoading {
                errorBanner(error)
            }

            if viewModel.isLoading && viewModel.logs.isEmpty {
                loadingState
            } else if viewModel.filteredLogs.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                logsSection
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BrowseFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.filter == filter,
                        action: {
                            Haptics.select()
                            viewModel.selectFilter(filter)
                        }
                    )
                }
            }
        }
        .contentMargins(.horizontal, Theme.screenPadding, for: .scrollContent)
        .padding(.horizontal, -Theme.screenPadding)
    }

    // MARK: - Logs

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "\(viewModel.totalCount) logs found")

            VStack(spacing: 10) {
                ForEach(viewModel.filteredLogs) { log in
                    StealerResultCard(
                        log: log,
                        onCopy: { viewModel.copyToClipboard($0) },
                        copiedField: viewModel.copiedField
                    )
                }
            }

            if viewModel.hasMore {
                Button {
                    Task { await viewModel.loadMore() }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView().tint(Theme.accent)
                        }
                        Text("Load more")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - States

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
            Image(systemName: "rectangle.stack")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("No stealer logs to browse")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            Text("Configure your Horus API key in Settings\nto start browsing intelligence data.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonBlock(height: 180, cornerRadius: Theme.cornerMedium)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    BrowseView()
        .preferredColorScheme(.dark)
}
