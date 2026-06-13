//
//  FilterChip.swift
//  Pulse
//
//  A selectable pill used to filter the activity feed.
//

import SwiftUI

/// A pill-shaped, selectable filter chip with press feedback.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.background : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Theme.stroke, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}
