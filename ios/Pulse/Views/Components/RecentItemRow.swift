//
//  RecentItemRow.swift
//  Pulse
//
//  A single row in the Overview "recent items" list.
//

import SwiftUI

/// One recent transaction/item with icon, title, relative time, and amount.
struct RecentItemRow: View {
    let item: RecentItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(item.accent.color)
                .frame(width: 42, height: 42)
                .background(item.accent.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(item.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.formattedAmount)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(item.amount >= 0 ? Theme.positive : Theme.textPrimary)
                Text(item.date, format: .relative(presentation: .named))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}
