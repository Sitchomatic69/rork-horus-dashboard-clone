//
//  OverviewView.swift
//  Pulse
//
//  The main dashboard panel: greeting header, summary strip, stat grid,
//  and a recent-items list.
//

import SwiftUI

struct OverviewView: View {
    @State private var viewModel = OverviewViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        DashboardScreen {
            header
        } content: {
            if viewModel.isLoading {
                loadingState
            } else {
                summaryStrip
                statGrid
                recentSection
            }
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
                Text("Alex Rivera")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            AvatarView(initials: "AR")
        }
        .padding(.top, 12)
    }

    // MARK: - Summary strip

    private var summaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.summary) { item in
                    SummaryChip(item: item)
                }
            }
        }
        .contentMargins(.horizontal, Theme.screenPadding, for: .scrollContent)
        .padding(.horizontal, -Theme.screenPadding) // full-bleed within padded parent
    }

    // MARK: - Stat grid

    private var statGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(viewModel.metrics.enumerated()), id: \.element.id) { index, metric in
                StatCard(metric: metric, index: index)
            }
        }
    }

    // MARK: - Recent section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent", action: {})
            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentItems.enumerated()), id: \.element.id) { index, item in
                    RecentItemRow(item: item)
                        .padding(.vertical, 12)
                    if index < viewModel.recentItems.count - 1 {
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

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { _ in
                    SkeletonBlock(height: 120, cornerRadius: Theme.cornerLarge)
                }
            }
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { _ in
                    SkeletonBlock(height: 120, cornerRadius: Theme.cornerLarge)
                }
            }
            SkeletonBlock(height: 220, cornerRadius: Theme.cornerLarge)
        }
        .padding(.top, 8)
    }
}

#Preview {
    OverviewView()
        .preferredColorScheme(.dark)
}
