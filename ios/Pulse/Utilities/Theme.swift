//
//  Theme.swift
//  Pulse
//
//  Central design tokens for the dashboard: colors, spacing and radii.
//  Keeping these in one place guarantees a cohesive, consistent aesthetic.
//

import SwiftUI

/// App-wide design tokens. Pure constants — no state, no logic.
enum Theme {
    // MARK: Backgrounds
    static let background = Color(red: 0.043, green: 0.047, blue: 0.063)        // #0B0C10
    static let surface = Color(red: 0.082, green: 0.090, blue: 0.118)          // #15171E
    static let surfaceElevated = Color(red: 0.122, green: 0.133, blue: 0.169)  // #1F222B

    // MARK: Strokes
    static let stroke = Color.white.opacity(0.06)
    static let strokeStrong = Color.white.opacity(0.12)

    // MARK: Text
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.58)
    static let textTertiary = Color.white.opacity(0.38)

    // MARK: Accents
    static let accent = Color(red: 0.776, green: 0.973, blue: 0.306)   // #C6F84E lime
    static let cyan = Color(red: 0.310, green: 0.890, blue: 0.839)     // #4FE3D6
    static let coral = Color(red: 1.000, green: 0.478, blue: 0.420)    // #FF7A6B
    static let violet = Color(red: 0.655, green: 0.545, blue: 0.980)   // #A78BFA

    // MARK: Semantic
    static let positive = Color(red: 0.290, green: 0.871, blue: 0.502) // #4ADE80
    static let negative = Color(red: 0.984, green: 0.443, blue: 0.522) // #FB7185

    // MARK: Layout
    static let cornerLarge: CGFloat = 24
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 12
    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 18
}
