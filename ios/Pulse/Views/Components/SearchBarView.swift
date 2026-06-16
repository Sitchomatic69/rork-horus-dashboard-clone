//
//  SearchBarView.swift
//  Pulse
//
//  A styled search input with a text field, type selector, and search button.
//  Glass appearance with animated focus states.
//

import SwiftUI

/// Reusable search input with type picker and submit action.
struct SearchBarView: View {
    @Binding var text: String
    @Binding var selectedType: SearchType
    let isSearching: Bool
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Type selector
            HStack(spacing: 6) {
                ForEach(SearchType.allCases) { type in
                    let selected = selectedType == type
                    Button {
                        Haptics.select()
                        selectedType = type
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selected ? Theme.background : Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selected ? Theme.accent : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Theme.surfaceElevated, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))

            // Search input
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isFocused ? Theme.accent : Theme.textTertiary)

                TextField("Search emails, usernames, domains…", text: $text)
                    .focused($isFocused)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit {
                        isFocused = false
                        onSubmit()
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isFocused = false
                    Haptics.tap()
                    onSubmit()
                } label: {
                    if isSearching {
                        ProgressView()
                            .tint(Theme.accent)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.background)
                            .frame(width: 32, height: 32)
                            .background(Theme.accent, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isFocused ? Theme.accent.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}
