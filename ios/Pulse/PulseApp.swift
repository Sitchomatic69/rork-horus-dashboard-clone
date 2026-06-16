//
//  PulseApp.swift
//  Pulse
//
//  Created by Rork on June 13, 2026.
//

import SwiftUI

@main
struct PulseApp: App {
    /// Single shared instance — all tabs read/write the same Keychain entries
    /// and see the same validation state.
    @State private var apiKeyManager = ApiKeyManager()

    var body: some Scene {
        WindowGroup {
            RootView(apiKeyManager: apiKeyManager)
                .preferredColorScheme(.dark)
        }
    }
}
