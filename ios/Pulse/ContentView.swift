//
//  ContentView.swift
//  Pulse
//
//  Created by Rork on June 13, 2026.
//

import SwiftUI

/// App entry view — hosts the dashboard's root container.
struct ContentView: View {
    let apiKeyManager: ApiKeyManager

    var body: some View {
        RootView(apiKeyManager: apiKeyManager)
    }
}

#Preview {
    ContentView(apiKeyManager: ApiKeyManager())
}
