# Pulse

A native iOS dashboard app built with SwiftUI and a clean **MVVM + Repository** architecture. Pulse presents business metrics across four swipeable panels — Overview, Analytics, Activity, and Settings — wrapped in a focused, dark dashboard aesthetic.

## Features

- **Overview** — Headline stat cards (revenue, active users, conversion, avg. order), a quick-glance summary strip, and a recent-items list. Numbers count up on load.
- **Analytics** — An animated line/area chart and bar chart with selectable time ranges (week / month / quarter), plus KPI trend indicators that draw in.
- **Activity** — A chronological feed of recent events (payments, sign-ups, system, alerts, messages) with category icons and relative timestamps.
- **Settings** — Profile header and grouped preference toggles.

Navigation is a paged `TabView` with a floating custom tab bar and smooth transitions. Every panel loads its data through an async repository with visible skeleton loading states.

## Design

- Deep charcoal background (`#0B0C10`) with soft, elevated card surfaces.
- A single strong lime accent (`#C6F84E`), supported by cyan, coral, and violet metric tints.
- Animated touches throughout: count-up numbers, charts that draw in, gentle press feedback, and haptics.
- Centralized design tokens (color, spacing, radii) in `Theme.swift` for a cohesive look.

## Architecture

Pulse follows MVVM with a protocol-driven data layer, so views and view models depend on an abstraction (`DashboardRepository`) rather than a concrete data source — making it easy to swap mock data for a network or database backend.

- **Models** — Plain data + business logic (`StatMetric`, `AnalyticsModels`, `ActivityEvent`, `RecentItem`, `UserProfile`, `DashboardTab`).
- **ViewModels** — `@Observable` classes owning state and async loading (`OverviewViewModel`, `AnalyticsViewModel`, `ActivityViewModel`, `SettingsViewModel`).
- **Views** — SwiftUI screens and reusable components; UI only.
- **Services** — `DashboardRepository` protocol with a deterministic `MockDashboardRepository` implementation.
- **Utilities** — Design tokens (`Theme`), view styles, and haptics.

### Project structure

```text
ios/
└── Pulse/
    ├── PulseApp.swift          # @main entry point
    ├── ContentView.swift
    ├── Models/                 # Data models & enums
    ├── ViewModels/             # @Observable state + logic
    ├── Views/
    │   ├── Components/          # Reusable UI (cards, charts, rows, tab bar)
    │   ├── OverviewView.swift
    │   ├── AnalyticsView.swift
    │   ├── ActivityView.swift
    │   ├── SettingsView.swift
    │   └── RootView.swift       # Paged panels + custom tab bar
    ├── Services/               # DashboardRepository (data layer)
    ├── Utilities/              # Theme, ViewStyles, Haptics
    └── Assets.xcassets/
```

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **State:** `@Observable` (Observation framework)
- **Concurrency:** Swift async/await with structured concurrency (`async let`)
- **Minimum target:** iOS 18.0

## Getting Started

1. Open `ios/Pulse.xcodeproj` in Xcode.
2. Select an iOS 18+ simulator (or a connected device).
3. Build and run (`⌘R`).

The app ships with deterministic mock data, so it runs fully offline with no setup or API keys required.

## Data

All data is served by `MockDashboardRepository`, which returns believable, deterministic seed data after a short simulated latency (so loading states are visible). To connect a real backend, implement the `DashboardRepository` protocol and inject it into the view models in place of the mock.
