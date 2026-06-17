//
//  RootView.swift
//  Pulse
//
//  Hosts the four swipeable panels and the floating custom tab bar.
//  Panels: Search, Dashboard, Browse, Settings.
//

import SwiftUI

/// Top-level container: a paged TabView with an overlaid custom tab bar.
struct RootView: View {
    @State private var selection: DashboardTab = .search
    let apiKeyManager: ApiKeyManager

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            TabView(selection: $selection) {
                SearchView(apiKeyManager: apiKeyManager)
                    .tag(DashboardTab.search)
                DashboardView(apiKeyManager: apiKeyManager)
                    .tag(DashboardTab.dashboard)
                BrowseView(apiKeyManager: apiKeyManager)
                    .tag(DashboardTab.browse)
                SettingsView(apiKeyManager: apiKeyManager)
                    .tag(DashboardTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.keyboard)

            DashboardTabBar(selection: $selection)
        }
        .preferredColorScheme(.dark)
        .task {
            // Fire-and-forget: validate keys without blocking the UI.
            // The shared ApiKeyManager updates @Observable state that
            // all panels react to as results come in.
            Task { await apiKeyManager.validateAll() }
        }
    }
}

#Preview {
    RootView(apiKeyManager: ApiKeyManager())
}
