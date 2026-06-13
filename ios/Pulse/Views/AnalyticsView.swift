//
//  AnalyticsView.swift
//  Pulse
//
//  The analytics panel: range selector, revenue area chart, weekly-users bar
//  chart, and KPI tiles.
//

import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        DashboardScreen {
            DashboardHeader(title: "Analytics", subtitle: "Performance over time")
        } content: {
            rangeSelector

            if viewModel.isLoading || viewModel.data == nil {
                loadingState
            } else if let data = viewModel.data {
                revenueCard(data.revenue)
                usersCard(data.weeklyUsers)
                kpiGrid(data.kpis)
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Range selector

    private var rangeSelector: some View {
        HStack(spacing: 6) {
            ForEach(AnalyticsRange.allCases) { range in
                let isSelected = viewModel.range == range
                Button {
                    Haptics.select()
                    Task { await viewModel.select(range) }
                } label: {
                    Text(range.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.background : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? Theme.accent : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.range)
    }

    // MARK: - Revenue card

    private func revenueCard(_ series: AnalyticsSeries) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(
                title: "Revenue",
                value: series.total.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                delta: series.changePercent
            )
            LineAreaChartView(points: series.points, accent: series.accent.color)
                .id(viewModel.range) // recreate so the draw-in animation replays
        }
        .cardStyle()
    }

    // MARK: - Users card

    private func usersCard(_ series: AnalyticsSeries) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            chartHeader(
                title: "New Users · This Week",
                value: series.total.formatted(.number.precision(.fractionLength(0))),
                delta: series.changePercent
            )
            BarChartView(points: series.points, accent: series.accent.color)
        }
        .cardStyle()
    }

    private func chartHeader(title: String, value: String, delta: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            TrendBadge(
                direction: delta >= 0 ? .up : .down,
                text: "\(delta >= 0 ? "+" : "−")\(String(format: "%.1f", abs(delta)))%"
            )
        }
    }

    // MARK: - KPI grid

    private func kpiGrid(_ items: [KPItem]) -> some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Text(item.value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 3) {
                        Image(systemName: item.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(item.formattedDelta)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(item.isPositive ? Theme.positive : Theme.negative)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(padding: 14, cornerRadius: Theme.cornerMedium)
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 14) {
            SkeletonBlock(height: 240, cornerRadius: Theme.cornerLarge)
            SkeletonBlock(height: 240, cornerRadius: Theme.cornerLarge)
        }
        .padding(.top, 8)
    }
}

#Preview {
    AnalyticsView()
        .preferredColorScheme(.dark)
}
