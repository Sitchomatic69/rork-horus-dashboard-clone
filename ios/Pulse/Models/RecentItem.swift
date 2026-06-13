//
//  RecentItem.swift
//  Pulse
//
//  Models for the Overview panel's summary strip and recent-items list.
//

import Foundation

/// A recent transaction/item shown in the Overview list.
struct RecentItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let amount: Double
    let date: Date
    let systemImage: String
    let accent: MetricAccent

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        amount: Double,
        date: Date,
        systemImage: String,
        accent: MetricAccent
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.date = date
        self.systemImage = systemImage
        self.accent = accent
    }

    var formattedAmount: String {
        let value = amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return amount >= 0 ? "+\(value)" : value
    }
}

/// A compact at-a-glance figure shown in the Overview summary strip.
struct SummaryItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let value: String
    let systemImage: String
    let tint: MetricAccent

    init(
        id: UUID = UUID(),
        title: String,
        value: String,
        systemImage: String,
        tint: MetricAccent
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.tint = tint
    }
}
