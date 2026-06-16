//
//  ApiStatusIndicator.swift
//  Pulse
//
//  A compact colored dot with label showing API key validation status.
//  Pulsing animation during validation, green/red for valid/invalid.
//

import SwiftUI

/// Compact status indicator for an API key's validation state.
struct ApiStatusIndicator: View {
    let state: ApiValidationState
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(statusColor)
        }
    }

    private var isPulsing: Bool {
        if case .validating = state { return true }
        return false
    }

    private var statusColor: Color {
        switch state {
        case .valid: return Theme.positive
        case .invalid, .error: return Theme.negative
        case .validating: return Theme.accent
        case .unknown: return Theme.textTertiary
        }
    }
}
