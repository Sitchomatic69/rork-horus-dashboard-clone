//
//  StatMetric.swift
//  Pulse
//
//  A headline statistic displayed on the Overview dashboard.
//

import SwiftUI

/// A single headline metric (revenue, users, …) with period-over-period change.
struct StatMetric: Identifiable, Hashable {
    let id: UUID
    let title: String
    let value: Double
    let previousValue: Double
    let format: MetricFormat
    let systemImage: String
    let accent: MetricAccent

    init(
        id: UUID = UUID(),
        title: String,
        value: Double,
        previousValue: Double,
        format: MetricFormat,
        systemImage: String,
        accent: MetricAccent
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.previousValue = previousValue
        self.format = format
        self.systemImage = systemImage
        self.accent = accent
    }

    /// Percentage change versus the previous period.
    var deltaPercent: Double {
        guard previousValue != 0 else { return 0 }
        return (value - previousValue) / previousValue * 100
    }

    /// Direction of the change, derived from `deltaPercent`.
    var trend: TrendDirection {
        if deltaPercent > 0.05 { return .up }
        if deltaPercent < -0.05 { return .down }
        return .flat
    }

    var formattedValue: String { format.string(from: value) }

    var formattedDelta: String {
        let symbol = deltaPercent >= 0 ? "+" : "−"
        return "\(symbol)\(String(format: "%.1f", abs(deltaPercent)))%"
    }
}

/// Direction of a period-over-period change.
enum TrendDirection {
    case up, down, flat

    var systemImage: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return Theme.positive
        case .down: return Theme.negative
        case .flat: return Theme.textSecondary
        }
    }
}

/// Named accent roles so views never hard-code chart colors.
enum MetricAccent: Hashable {
    case lime, cyan, coral, violet

    var color: Color {
        switch self {
        case .lime: return Theme.accent
        case .cyan: return Theme.cyan
        case .coral: return Theme.coral
        case .violet: return Theme.violet
        }
    }
}

/// How a numeric value should be rendered as text.
enum MetricFormat {
    case currency
    case decimal
    case integer
    case percent
    case compact

    func string(from value: Double) -> String {
        switch self {
        case .currency:
            return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        case .decimal:
            return value.formatted(.number.precision(.fractionLength(1)))
        case .integer:
            return value.formatted(.number.precision(.fractionLength(0)))
        case .percent:
            return value.formatted(.number.precision(.fractionLength(1))) + "%"
        case .compact:
            return MetricFormat.compactString(value)
        }
    }

    /// Renders large numbers compactly, e.g. 12_840 -> "12.8k".
    static func compactString(_ value: Double) -> String {
        let magnitude = abs(value)
        switch magnitude {
        case 1_000_000...:
            return (value / 1_000_000).formatted(.number.precision(.fractionLength(1))) + "M"
        case 1_000...:
            return (value / 1_000).formatted(.number.precision(.fractionLength(1))) + "k"
        default:
            return value.formatted(.number.precision(.fractionLength(0)))
        }
    }
}
