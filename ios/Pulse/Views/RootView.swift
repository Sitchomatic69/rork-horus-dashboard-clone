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
            // Validate any stored or env-provisioned keys on launch so every
            // panel reflects accurate API health from the start.
            await apiKeyManager.validateAll()
        }
    }
}

#Preview {
    RootView(apiKeyManager: ApiKeyManager())
}
