//
//  ActivityView.swift
//  Pulse
//
//  The activity panel: category filters and a day-grouped event feed.
//

import SwiftUI

struct ActivityView: View {
    @State private var viewModel = ActivityViewModel()

    var body: some View {
        DashboardScreen {
            DashboardHeader(title: "Activity", subtitle: "Recent events across your account")
        } content: {
            filterBar

            if viewModel.isLoading {
                loadingState
            } else if viewModel.sections.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.sections) { section in
                    sectionView(section)
                }
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: viewModel.filter == nil) {
                    Haptics.select()
                    viewModel.setFilter(nil)
                }
                ForEach(ActivityCategory.allCases) { category in
                    FilterChip(title: category.title, isSelected: viewModel.filter == category) {
                        Haptics.select()
                        viewModel.setFilter(category)
                    }
                }
            }
        }
        .contentMargins(.horizontal, Theme.screenPadding, for: .scrollContent)
        .padding(.horizontal, -Theme.screenPadding)
    }

    // MARK: - Section

    private func sectionView(_ section: ActivitySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(section.events.enumerated()), id: \.element.id) { index, event in
                    ActivityRow(event: event)
                        .padding(.vertical, 12)
                    if index < section.events.count - 1 {
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

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("No activity here")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonBlock(height: 72, cornerRadius: Theme.cornerLarge)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    ActivityView()
        .preferredColorScheme(.dark)
}
