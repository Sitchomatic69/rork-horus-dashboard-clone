//
//  ActivityRow.swift
//  Pulse
//
//  A single row in the Activity feed.
//

import SwiftUI

/// One activity event with a category icon, title, detail and time.
struct ActivityRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: event.category.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(event.category.color)
                .frame(width: 40, height: 40)
                .background(event.category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(event.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(event.date, format: .dateTime.hour().minute())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
