//
//  ActivityEvent.swift
//  Pulse
//
//  A single event in the Activity feed plus its category styling.
//

import SwiftUI

/// One entry in the chronological activity feed.
struct ActivityEvent: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let date: Date
    let category: ActivityCategory

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        date: Date,
        category: ActivityCategory
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.category = category
    }
}

/// Category of an activity event — drives its icon and color.
enum ActivityCategory: String, CaseIterable, Identifiable {
    case payment
    case user
    case system
    case alert
    case message

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .payment: return "creditcard.fill"
        case .user: return "person.fill"
        case .system: return "gearshape.fill"
        case .alert: return "exclamationmark.triangle.fill"
        case .message: return "bubble.left.fill"
        }
    }

    var color: Color {
        switch self {
        case .payment: return Theme.accent
        case .user: return Theme.cyan
        case .system: return Theme.violet
        case .alert: return Theme.coral
        case .message: return Theme.cyan
        }
    }
}

/// A day-grouped bucket of activity events for sectioned display.
struct ActivitySection: Identifiable {
    let id: String
    let title: String
    let events: [ActivityEvent]
}
