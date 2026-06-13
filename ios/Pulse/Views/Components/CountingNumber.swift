//
//  CountingNumber.swift
//  Pulse
//
//  A number that animates smoothly from one value to another by conforming
//  to `Animatable`, re-rendering its text on every interpolated frame.
//

import SwiftUI

/// Displays a `Double` that animates when its value changes.
struct CountingNumber: View, Animatable {
    var value: Double
    var format: MetricFormat

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(format.string(from: value))
            .monospacedDigit()
    }
}
