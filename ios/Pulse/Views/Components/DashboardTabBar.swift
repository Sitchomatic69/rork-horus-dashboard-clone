//
//  DashboardTabBar.swift
//  Pulse
//
//  A custom floating glass tab bar with a sliding selection pill.
//

import SwiftUI

/// Floating bottom tab bar that drives panel selection.
struct DashboardTabBar: View {
    @Binding var selection: DashboardTab
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DashboardTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .dashboardGlass(cornerRadius: 28)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Theme.strokeStrong, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: selection)
    }

    private func tabButton(for tab: DashboardTab) -> some View {
        Button {
            selection = tab
            Haptics.tap()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    if selection == tab {
                        Capsule()
                            .fill(Theme.accent.opacity(0.16))
                            .matchedGeometryEffect(id: "selectionPill", in: namespace)
                            .frame(width: 52, height: 34)
                    }
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selection == tab ? Theme.accent : Theme.textTertiary)
                }
                .frame(height: 34)

                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selection == tab ? Theme.textPrimary : Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
