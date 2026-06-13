//
//  ViewStyles.swift
//  Pulse
//
//  Reusable view modifiers and button styles that enforce the dashboard look.
//

import SwiftUI

/// Standard elevated card surface used throughout the app.
struct CardStyle: ViewModifier {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = Theme.cornerLarge

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    /// Wraps the view in the standard dashboard card surface.
    func cardStyle(padding: CGFloat = 18, cornerRadius: CGFloat = Theme.cornerLarge) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }

    /// Applies a translucent glass background, using Liquid Glass on iOS 26+
    /// and a material fallback on earlier systems.
    @ViewBuilder
    func dashboardGlass(cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .background(Theme.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

/// Button style that gives a gentle spring-y press-down feedback.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
