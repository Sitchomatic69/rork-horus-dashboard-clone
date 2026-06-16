//
//  SettingsComponents.swift
//  Pulse
//
//  Building blocks for the Settings panel: grouped containers, rows, and dividers.
//

import SwiftUI

/// A titled group that wraps its rows in a single card with dividers.
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
    }
}

/// A thin separator used between settings rows.
struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(height: 1)
    }
}

/// A tappable row with an icon, title, optional trailing value, and chevron.
struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let tint: MetricAccent
    var value: String?
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint.color)
                    .frame(width: 34, height: 34)
                    .background(tint.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let value {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
