//
//  SettingsViewModel.swift
//  Pulse
//
//  State for the Settings panel. Toggle preferences are persisted to
//  UserDefaults via bindings, so changes survive relaunches.
//

import SwiftUI
import Observation

/// Drives the Settings panel: profile plus persisted preference toggles.
@Observable
final class SettingsViewModel {
    private(set) var profile: UserProfile?

    // Persisted preferences (loaded from UserDefaults in `init`).
    var pushEnabled: Bool
    var faceIDEnabled: Bool
    var hapticsEnabled: Bool
    var weeklyDigestEnabled: Bool
    var compactCharts: Bool

    let appVersion = "1.0.0"

    @ObservationIgnored private let store: UserDefaults
    private let repository: DashboardRepository

    init(repository: DashboardRepository = MockDashboardRepository(), store: UserDefaults = .standard) {
        self.repository = repository
        self.store = store
        self.pushEnabled = store.object(forKey: Keys.push) as? Bool ?? true
        self.faceIDEnabled = store.object(forKey: Keys.faceID) as? Bool ?? false
        self.hapticsEnabled = store.object(forKey: Keys.haptics) as? Bool ?? true
        self.weeklyDigestEnabled = store.object(forKey: Keys.digest) as? Bool ?? true
        self.compactCharts = store.object(forKey: Keys.compactCharts) as? Bool ?? false
    }

    func load() async {
        profile = await repository.loadProfile()
    }

    /// Builds a Toggle binding that also persists the new value.
    func binding(for keyPath: ReferenceWritableKeyPath<SettingsViewModel, Bool>, key: String) -> Binding<Bool> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                self[keyPath: keyPath] = newValue
                self.store.set(newValue, forKey: key)
                if self.hapticsEnabled { Haptics.soft() }
            }
        )
    }

    /// UserDefaults keys for persisted preferences.
    enum Keys {
        static let push = "settings.push"
        static let faceID = "settings.faceID"
        static let haptics = "settings.haptics"
        static let digest = "settings.digest"
        static let compactCharts = "settings.compactCharts"
    }
}
