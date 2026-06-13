//
//  TrendBadge.swift
//  Pulse
//
//  A small pill showing a directional arrow and a percentage delta.
//

import SwiftUI

/// A compact up/down/flat indicator with a colored background.
struct TrendBadge: View {
    let direction: TrendDirection
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: direction.systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(direction.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(direction.color.opacity(0.15), in: Capsule())
    }
}
