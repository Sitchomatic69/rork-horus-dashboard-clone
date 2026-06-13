//
//  StatCard.swift
//  Pulse
//
//  A headline metric card with an icon chip, animated counting value,
//  and a trend badge. Staggers its count-up animation by index.
//

import SwiftUI

/// Displays a single `StatMetric` as a card on the Overview grid.
struct StatCard: View {
    let metric: StatMetric
    var index: Int = 0

    @State private var displayValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: metric.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(metric.accent.color)
                    .frame(width: 38, height: 38)
                    .background(metric.accent.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
                TrendBadge(direction: metric.trend, text: metric.formattedDelta)
            }

            VStack(alignment: .leading, spacing: 4) {
                CountingNumber(value: displayValue, format: metric.format)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(metric.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(Double(index) * 0.07)) {
                displayValue = metric.value
            }
        }
    }
}
