//
//  DashboardTab.swift
//  Pulse
//
//  The four primary panels reachable from the bottom tab bar.
//  Repurposed for the OSINT investigation workflow.
//

import Foundation

/// Top-level destinations in the OSINT dashboard.
enum DashboardTab: Int, CaseIterable, Identifiable {
    case search
    case dashboard
    case browse
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .search: return "Search"
        case .dashboard: return "Dashboard"
        case .browse: return "Browse"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .search: return "magnifyingglass"
        case .dashboard: return "square.grid.2x2.fill"
        case .browse: return "rectangle.stack.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
