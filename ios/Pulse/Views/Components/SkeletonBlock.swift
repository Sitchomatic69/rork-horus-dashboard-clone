//
//  SkeletonBlock.swift
//  Pulse
//
//  A pulsing placeholder block used while data is loading.
//

import SwiftUI

/// A rounded rectangle that gently pulses to indicate loading.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8

    @State private var isPulsing = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.surfaceElevated)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .opacity(isPulsing ? 0.45 : 0.9)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}
