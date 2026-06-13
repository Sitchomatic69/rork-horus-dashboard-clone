//
//  SectionHeader.swift
//  Pulse
//
//  A titled section header with an optional trailing action button.
//

import SwiftUI

/// Header row for a content section, e.g. "Recent" + a "See all" action.
struct SectionHeader: View {
    let title: String
    var actionTitle: String = "See all"
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
