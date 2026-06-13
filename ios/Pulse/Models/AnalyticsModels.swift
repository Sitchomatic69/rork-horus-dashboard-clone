//
//  AnalyticsModels.swift
//  Pulse
//
//  Data structures backing the Analytics panel's charts and KPIs.
//

import Foundation

/// A single point in a time series (one day / one bucket).
struct TrendPoint: Identifiable, Hashable {
    let id: UUID
    let label: String
    let value: Double

    init(id: UUID = UUID(), label: String, value: Double) {
        self.id = id
        self.label = label
        self.value = value
    }
}

/// A named series of trend points with an accent color and derived stats.
struct AnalyticsSeries: Identifiable, Hashable {
    let id: UUID
    let name: String
    let points: [TrendPoint]
    let accent: MetricAccent

    init(id: UUID = UUID(), name: String, points: [TrendPoint], accent: MetricAccent) {
        self.id = id
        self.name = name
        self.points = points
        self.accent = accent
    }

    var total: Double { points.reduce(0) { $0 + $1.value } }
    var average: Double { points.isEmpty ? 0 : total / Double(points.count) }
    var peak: Double { points.map(\.value).max() ?? 0 }

    /// Percentage change between the first and last point of the series.
    var changePercent: Double {
        guard let first = points.first?.value, first != 0, let last = points.last?.value else { return 0 }
        return (last - first) / first * 100
    }
}

/// Time window selectable on the Analytics panel.
enum AnalyticsRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case quarter = "90D"

    var id: String { rawValue }
    var title: String { rawValue }

    var pointCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

/// A small KPI tile with a value and a directional delta.
struct KPItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let value: String
    let deltaPercent: Double

    init(id: UUID = UUID(), title: String, value: String, deltaPercent: Double) {
        self.id = id
        self.title = title
        self.value = value
        self.deltaPercent = deltaPercent
    }

    var isPositive: Bool { deltaPercent >= 0 }
    var formattedDelta: String {
        let symbol = deltaPercent >= 0 ? "+" : "−"
        return "\(symbol)\(String(format: "%.1f", abs(deltaPercent)))%"
    }
}

/// Everything the Analytics panel needs for a given range.
struct AnalyticsData: Hashable {
    let revenue: AnalyticsSeries   // rendered as an area + line chart
    let weeklyUsers: AnalyticsSeries // rendered as bars (always 7 days)
    let kpis: [KPItem]
}
