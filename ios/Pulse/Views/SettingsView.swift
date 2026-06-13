//
//  SettingsView.swift
//  Pulse
//
//  The settings panel: profile header, persisted preference toggles, and
//  informational rows.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        @Bindable var vm = viewModel

        DashboardScreen {
            DashboardHeader(title: "Settings")
        } content: {
            profileCard

            SettingsGroup(title: "Preferences") {
                SettingsToggleRow(
                    icon: "bell.fill", title: "Push Notifications", tint: .lime,
                    isOn: vm.binding(for: \.pushEnabled, key: SettingsViewModel.Keys.push)
                )
                RowDivider()
                SettingsToggleRow(
                    icon: "faceid", title: "Face ID Lock", tint: .cyan,
                    isOn: vm.binding(for: \.faceIDEnabled, key: SettingsViewModel.Keys.faceID)
                )
                RowDivider()
                SettingsToggleRow(
                    icon: "hand.tap.fill", title: "Haptic Feedback", tint: .violet,
                    isOn: vm.binding(for: \.hapticsEnabled, key: SettingsViewModel.Keys.haptics)
                )
            }

            SettingsGroup(title: "Reports") {
                SettingsToggleRow(
                    icon: "envelope.fill", title: "Weekly Digest", tint: .coral,
                    isOn: vm.binding(for: \.weeklyDigestEnabled, key: SettingsViewModel.Keys.digest)
                )
                RowDivider()
                SettingsToggleRow(
                    icon: "chart.bar.fill", title: "Compact Charts", tint: .cyan,
                    isOn: vm.binding(for: \.compactCharts, key: SettingsViewModel.Keys.compactCharts)
                )
            }

            SettingsGroup(title: "About") {
                SettingsLinkRow(icon: "info.circle.fill", title: "Version", tint: .lime, value: viewModel.appVersion)
                RowDivider()
                SettingsLinkRow(icon: "lock.shield.fill", title: "Privacy Policy", tint: .violet)
                RowDivider()
                SettingsLinkRow(icon: "questionmark.circle.fill", title: "Help & Support", tint: .cyan)
            }

            signOutButton
        }
        .task { await viewModel.load() }
    }

    // MARK: - Profile

    private var profileCard: some View {
        HStack(spacing: 16) {
            AvatarView(initials: viewModel.profile?.initials ?? "··", size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.profile?.name ?? "Loading…")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(viewModel.profile?.role ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text(viewModel.profile?.email ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Sign out

    private var signOutButton: some View {
        Button {
            Haptics.tap()
        } label: {
            Text("Sign Out")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.negative)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.negative.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.top, 4)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
