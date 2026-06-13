//
//  BarChartView.swift
//  Pulse
//
//  A hand-built animated bar chart. Bars grow up from the baseline on appear.
//

import SwiftUI

/// Animated vertical bar chart with axis labels beneath each bar.
struct BarChartView: View {
    let points: [TrendPoint]
    let accent: Color

    @State private var progress: CGFloat = 0

    var body: some View {
        let maxValue = max(points.map(\.value).max() ?? 1, 1)

        GeometryReader { geo in
            let labelHeight: CGFloat = 18
            let chartHeight = max(geo.size.height - labelHeight - 8, 1)

            HStack(alignment: .bottom, spacing: barSpacing(for: geo.size.width)) {
                ForEach(points) { point in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accent, accent.opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: barHeight(for: point.value, maxValue: maxValue, chartHeight: chartHeight))
                        Text(point.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(height: labelHeight)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 190)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                progress = 1
            }
        }
    }

    private func barHeight(for value: Double, maxValue: Double, chartHeight: CGFloat) -> CGFloat {
        let ratio = CGFloat(value / maxValue)
        return max(4, ratio * chartHeight * progress)
    }

    private func barSpacing(for width: CGFloat) -> CGFloat {
        points.count > 10 ? 4 : 10
    }
}
