//
//  SummaryChip.swift
//  Pulse
//
//  A compact figure used in the Overview summary strip.
//

import SwiftUI

/// A small icon + value + title chip for the horizontal summary strip.
struct SummaryChip: View {
    let item: SummaryItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(item.tint.color)
                .frame(width: 34, height: 34)
                .background(item.tint.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }
}
