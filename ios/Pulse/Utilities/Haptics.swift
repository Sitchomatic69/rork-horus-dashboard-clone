//
//  Haptics.swift
//  Pulse
//
//  Thin wrapper around UIKit feedback generators for subtle tactile feedback.
//

import UIKit

/// Lightweight haptic feedback helpers used across interactive elements.
enum Haptics {
    /// A light impact, ideal for taps on cards and tab items.
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// A selection change tick, ideal for segmented controls and filters.
    static func select() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// A soft impact for toggles and confirmations.
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
