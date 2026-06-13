//
//  RootView.swift
//  Pulse
//
//  Hosts the four swipeable panels and the floating custom tab bar.
//

import SwiftUI

/// Top-level container: a paged TabView with an overlaid custom tab bar.
struct RootView: View {
    @State private var selection: DashboardTab = .overview

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            TabView(selection: $selection) {
                OverviewView().tag(DashboardTab.overview)
                AnalyticsView().tag(DashboardTab.analytics)
                ActivityView().tag(DashboardTab.activity)
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
