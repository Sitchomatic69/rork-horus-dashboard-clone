//
//  DashboardTab.swift
//  Pulse
//
//  The four primary panels reachable from the bottom tab bar.
//

import Foundation

/// Top-level destinations in the dashboard.
enum DashboardTab: Int, CaseIterable, Identifiable {
    case overview
    case analytics
    case activity
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .analytics: return "Analytics"
        case .activity: return "Activity"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .analytics: return "chart.bar.xaxis"
        case .activity: return "bolt.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
