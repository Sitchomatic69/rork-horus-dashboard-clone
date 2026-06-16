//
//  SettingsView.swift
//  Pulse
//
//  The Settings panel: API key management for OSINTDog and Horus,
//  validation controls, clear/remove actions, and app info.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        DashboardScreen {
            DashboardHeader(title: "Settings", subtitle: "API keys and preferences")
        } content: {
            profileCard
            osintdogKeySection
            horusKeySection
            appInfoSection
        }
    }

    // MARK: - Profile

    private var profileCard: some View {
        HStack(spacing: 16) {
            AvatarView(initials: "PI", size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("OSINT Investigator")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("API Configuration")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text("Manage your intelligence source keys")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    // MARK: - OSINTDog key

    private var osintdogKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OSINTDOG API")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                apiKeyRow(
                    icon: "magnifyingglass.circle.fill",
                    title: "OSINTDog Key",
                    tint: Theme.accent,
                    text: $viewModel.osintdogKey,
                    placeholder: "Paste OSINTDog API key…",
                    state: viewModel.osintdogState,
                    onValidate: { Task { await viewModel.validateOSINTDog() } },
                    onClear: { viewModel.clearOSINTDog() }
                )
            }
            .padding(.horizontal, 16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Horus key

    private var horusKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HORUS API")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                apiKeyRow(
                    icon: "shield.checkered",
                    title: "Horus Key",
                    tint: Theme.cyan,
                    text: $viewModel.horusKey,
                    placeholder: "Paste Horus API key…",
                    state: viewModel.horusState,
                    onValidate: { Task { await viewModel.validateHorus() } },
                    onClear: { viewModel.clearHorus() }
                )
            }
            .padding(.horizontal, 16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
    }

    // MARK: - App info

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                SettingsLinkRow(
                    icon: "info.circle.fill",
                    title: "Version",
                    tint: .lime,
                    value: viewModel.appVersion
                )
                RowDivider()
                SettingsLinkRow(
                    icon: "doc.text.fill",
                    title: "OSINTDog API Docs",
                    tint: .cyan,
                    value: "osintdog.com",
                    action: {
                        if let url = URL(string: "https://osintdog.com/docs") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                RowDivider()
                SettingsLinkRow(
                    icon: "doc.text.fill",
                    title: "Horus API Docs",
                    tint: .violet,
                    value: "horus.st",
                    action: {
                        if let url = URL(string: "https://horus.st/docs") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
    }

    // MARK: - API key row builder

    private func apiKeyRow(
        icon: String,
        title: String,
        tint: Color,
        text: Binding<String>,
        placeholder: String,
        state: ApiValidationState,
        onValidate: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 6) {
                    TextField(placeholder, text: text)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack(spacing: 6) {
                        Image(systemName: viewModel.statusIcon(for: state))
                            .font(.system(size: 10, weight: .bold))
                        Text(viewModel.statusLabel(for: state))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(viewModel.statusColor(for: state))
                }
            }
            .padding(.vertical, 14)

            RowDivider()

            HStack(spacing: 0) {
                Button(action: onValidate) {
                    HStack(spacing: 5) {
                        if case .validating = state {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(tint)
                        }
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 12))
                        Text("Validate")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.stroke)
                    .frame(width: 1, height: 24)

                Button(action: onClear) {
                    HStack(spacing: 5) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Clear")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.negative)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
