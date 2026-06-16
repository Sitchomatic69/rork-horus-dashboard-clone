//
//  ResultCard.swift
//  Pulse
//
//  A card displaying a breach or stealer log result with source badge,
//  key fields, and copy-to-clipboard support.
//

import SwiftUI

/// Displays a breach search result with key fields and a source badge.
struct BreachResultCard: View {
    let result: BreachResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SourceBadge(name: result.source)
                Spacer()
                if let date = result.date {
                    Text(date, format: .relative(presentation: .named))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            if let domain = result.domain {
                fieldRow(label: "Domain", value: domain, copyable: true)
            }
            if let email = result.email {
                fieldRow(label: "Email", value: email, copyable: true)
            }
            if let username = result.username {
                fieldRow(label: "User", value: username, copyable: true)
            }
            if let password = result.password {
                fieldRow(label: "Password", value: password, copyable: true, sensitive: true)
            }
            if let ip = result.ip {
                fieldRow(label: "IP", value: ip, copyable: true)
            }

            // Remaining fields
            let extra = result.fields.filter { key, _ in
                !["email", "username", "password", "domain", "ip", "date", "source", "id"].contains(key)
            }
            if !extra.isEmpty {
                ForEach(Array(extra.keys.sorted()), id: \.self) { key in
                    fieldRow(label: key.capitalized, value: extra[key] ?? "")
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }

    private func fieldRow(label: String, value: String, copyable: Bool = false, sensitive: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 60, alignment: .leading)

            Text(sensitive ? String(repeating: "•", count: 8) : value)
                .font(.system(size: 13, weight: .medium, design: sensitive ? .default : .monospaced))
                .foregroundStyle(sensitive ? Theme.textSecondary : Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if copyable {
                CopyButton(value: value)
            }
        }
    }
}

/// Displays a stealer log result with OS and country badges plus creds.
struct StealerResultCard: View {
    let log: StealerLogResult
    let onCopy: (String) -> Void
    let copiedField: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                SourceBadge(name: "Horus", color: Theme.cyan)
                if let malware = log.malwareFamily {
                    SourceBadge(name: malware, color: Theme.coral)
                }
                Spacer()
                if let date = log.capturedAt {
                    Text(date, format: .relative(presentation: .named))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            // OS + country + IP row
            HStack(spacing: 10) {
                if let os = log.os {
                    Label(os, systemImage: "desktopcomputer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let country = log.country {
                    Label(country, systemImage: "globe")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let ip = log.ip {
                    Label(ip, systemImage: "network")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Divider().overlay(Theme.stroke)

            if let domain = log.domain {
                copyRow(label: "Host", value: domain, onCopy: onCopy, copied: copiedField)
            }
            if let url = log.url {
                copyRow(label: "URL", value: url, onCopy: onCopy, copied: copiedField)
            }
            if let username = log.username {
                copyRow(label: "User", value: username, onCopy: onCopy, copied: copiedField)
            }
            if let password = log.password {
                copyRow(label: "Pass", value: password, onCopy: onCopy, copied: copiedField, sensitive: true)
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }

    private func copyRow(label: String, value: String, onCopy: @escaping (String) -> Void,
                         copied: String?, sensitive: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 40, alignment: .leading)

            Text(sensitive ? String(repeating: "•", count: 8) : value)
                .font(.system(size: 13, weight: .medium, design: sensitive ? .default : .monospaced))
                .foregroundStyle(sensitive ? Theme.textSecondary : Theme.textPrimary)
                .lineLimit(2)

            Spacer()

            Button {
                onCopy(value)
            } label: {
                Image(systemName: copied == value ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(copied == value ? Theme.positive : Theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Shared components

/// Small colored badge showing a source or category name.
struct SourceBadge: View {
    let name: String
    var color: Color = Theme.accent

    var body: some View {
        Text(name)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }
}

/// A tappable copy button with confirmation feedback.
struct CopyButton: View {
    let value: String
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = value
            copied = true
            Haptics.soft()
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(copied ? Theme.positive : Theme.textTertiary)
        }
        .buttonStyle(.plain)
    }
}
