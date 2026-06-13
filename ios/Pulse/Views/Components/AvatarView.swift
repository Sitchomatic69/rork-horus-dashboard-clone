//
//  AvatarView.swift
//  Pulse
//
//  A circular monogram avatar built from a user's initials.
//

import SwiftUI

/// Circular avatar showing initials over an accent gradient.
struct AvatarView: View {
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Theme.accent, Theme.cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.background)
            )
            .overlay(
                Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}
