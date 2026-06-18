//
//  DashboardView.swift
//  Pulse
//
//  The Dashboard panel: greeting header, API health indicator cards,
//  quick stats, and a recent search activity list.
//

import SwiftUI

struct DashboardView: View {
    let apiKeyManager: ApiKeyManager
    @State private var viewModel: DashboardViewModel

    init(apiKeyManager: ApiKeyManager) {
        self.apiKeyManager = apiKeyManager
        self._viewModel = State(wrappedValue: DashboardViewModel(apiKeyManager: apiKeyManager))
    }

    var body: some View {
        DashboardScreen {
            header
        } content: {
            apiStatusCards
            quickStats
            recentQueriesSection
        }
        .task { await viewModel.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("Investigator")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            AvatarView(initials: "PI")
        }
        .padding(.top, 12)
    }

    // MARK: - API Status

    private var apiStatusCards: some View {
        HStack(spacing: 12) {
            apiCard(
                name: "OSINTDog",
                state: viewModel.dogStatus,
                icon: "magnifyingglass.circle.fill",
                color: Theme.accent
            )
            apiCard(
                name: "Horus",
                state: viewModel.horusStatus,
                icon: "shield.checkered",
                color: Theme.cyan
            )
        }
    }

    private func apiCard(name: String, state: ApiValidationState, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
                ApiStatusIndicator(state: state, label: viewModel.statusLabel(for: state))
            }
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            // Surface the last validation error when unhealthy
            if let error = viewModel.errorFor(name: name) {
                Text(error)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.negative.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16, cornerRadius: Theme.cornerMedium)
    }

    // MARK: - Quick Stats

    private var quickStats: some View {
        HStack(spacing: 12) {
            statTile(
                icon: "number",
                value: "\(viewModel.searchesRun)",
                label: "Searches",
                color: Theme.accent
            )
            statTile(
                icon: "doc.text.magnifyingglass",
                value: "\(viewModel.totalResultsFound)",
                label: "Results",
                color: Theme.cyan
            )
            statTile(
                icon: "clock",
                value: lastSearchText,
                label: "Last Search",
                color: Theme.violet
            )
        }
    }

    private func statTile(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14, cornerRadius: Theme.cornerMedium)
    }

    private var lastSearchText: String {
        viewModel.lastSearchDate?.formatted(.relative(presentation: .named)) ?? "—"
    }

    // MARK: - Recent queries

    private var recentQueriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Searches", actionTitle: "", action: nil)

            if viewModel.recentQueries.isEmpty {
                Text("No searches yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentQueries.enumerated()), id: \.element.id) { index, query in
                        recentQueryRow(query)
                            .padding(.vertical, 10)
                        if index < viewModel.recentQueries.count - 1 {
                            RowDivider()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )
            }
        }
    }

    private func recentQueryRow(_ query: SearchQuery) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 32, height: 32)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(query.term)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(query.type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Text(query.date, format: .relative(presentation: .named))
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

#Preview {
    DashboardView(apiKeyManager: ApiKeyManager())
        .preferredColorScheme(.dark)
}
