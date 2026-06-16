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

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            TabView(selection: $selection) {
                SearchView().tag(DashboardTab.search)
                DashboardView().tag(DashboardTab.dashboard)
                BrowseView().tag(DashboardTab.browse)
                SettingsView().tag(DashboardTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.keyboard)

            DashboardTabBar(selection: $selection)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
