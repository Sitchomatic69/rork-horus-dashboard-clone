//
//  UserProfile.swift
//  Pulse
//
//  The signed-in user shown on the Settings panel.
//

import Foundation

/// The current user's profile information.
struct UserProfile: Identifiable, Hashable {
    let id: UUID
    let name: String
    let role: String
    let email: String

    init(id: UUID = UUID(), name: String, role: String, email: String) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
    }

    /// Up-to-two-letter initials derived from the name, for the avatar.
    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
