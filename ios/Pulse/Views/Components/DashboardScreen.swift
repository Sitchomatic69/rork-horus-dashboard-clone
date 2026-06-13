//
//  DashboardScreen.swift
//  Pulse
//
//  Shared scaffold for every panel: atmospheric background, scrolling content,
//  consistent padding, and room for the floating tab bar.
//

import SwiftUI

/// A reusable scrolling screen container with a custom header slot.
struct DashboardScreen<Header: View, Content: View>: View {
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                header()
                content()
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, 120) // clearance for the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(AtmosphereBackground())
    }
}

/// Default large-title header used by most panels.
struct DashboardHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}

/// Subtle layered radial glows that give the dark background depth.
struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Theme.accent.opacity(0.10), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 360
            )
            RadialGradient(
                colors: [Theme.violet.opacity(0.08), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }
}
