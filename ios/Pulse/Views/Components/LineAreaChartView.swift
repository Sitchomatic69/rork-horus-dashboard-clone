//
//  LineAreaChartView.swift
//  Pulse
//
//  A hand-built smoothed line + area chart that draws itself in from the
//  left using an animated mask. Works for any number of points.
//

import SwiftUI

/// Animated smoothed line chart with a soft gradient area fill.
struct LineAreaChartView: View {
    let points: [TrendPoint]
    let accent: Color

    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let coords = coordinates(in: geo.size)

            ZStack {
                gridLines(in: geo.size)

                areaPath(coords, height: geo.size.height)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.32), accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                linePath(coords)
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.85), accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                if let last = coords.last {
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                        .shadow(color: accent.opacity(0.7), radius: 6)
                        .position(last)
                }
            }
            .mask(alignment: .leading) {
                Rectangle()
                    .frame(width: geo.size.width * progress)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1)) {
                progress = 1
            }
        }
    }

    // MARK: - Geometry

    private func coordinates(in size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let values = points.map(\.value)
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 1)
        let topInset: CGFloat = 8
        let usableHeight = size.height - topInset * 2
        let stepX = points.count > 1 ? size.width / CGFloat(points.count - 1) : size.width

        return points.enumerated().map { index, point in
            let x = points.count > 1 ? CGFloat(index) * stepX : size.width / 2
            let normalized = CGFloat((point.value - minValue) / range)
            let y = topInset + (1 - normalized) * usableHeight
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        for index in 1..<pts.count {
            let previous = pts[index - 1]
            let current = pts[index]
            let controlX = (previous.x + current.x) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: controlX, y: previous.y),
                control2: CGPoint(x: controlX, y: current.y)
            )
        }
        return path
    }

    private func areaPath(_ pts: [CGPoint], height: CGFloat) -> Path {
        var path = linePath(pts)
        guard let first = pts.first, let last = pts.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: height))
        path.addLine(to: CGPoint(x: first.x, y: height))
        path.closeSubpath()
        return path
    }

    private func gridLines(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4) { _ in
                Rectangle()
                    .fill(Theme.strokeStrong)
                    .frame(height: 1)
                Spacer()
            }
        }
    }
}
