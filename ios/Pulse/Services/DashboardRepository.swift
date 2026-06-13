//
//  DashboardRepository.swift
//  Pulse
//
//  Data layer for the dashboard. Views and view models depend on the
//  `DashboardRepository` protocol, never on a concrete implementation,
//  so the data source can be swapped (mock, network, database) freely.
//

import Foundation

/// Abstraction over the dashboard's data source.
protocol DashboardRepository {
    func loadMetrics() async -> [StatMetric]
    func loadSummary() async -> [SummaryItem]
    func loadRecentItems() async -> [RecentItem]
    func loadAnalytics(range: AnalyticsRange) async -> AnalyticsData
    func loadActivity() async -> [ActivityEvent]
    func loadProfile() async -> UserProfile
}

/// In-memory implementation that returns deterministic, believable seed data
/// after a short simulated latency. Deterministic so the UI is stable.
final class MockDashboardRepository: DashboardRepository {

    // MARK: Overview

    func loadMetrics() async -> [StatMetric] {
        await Self.simulateLatency()
        return [
            StatMetric(title: "Revenue", value: 48_230, previousValue: 43_180,
                       format: .currency, systemImage: "dollarsign.circle.fill", accent: .lime),
            StatMetric(title: "Active Users", value: 12_840, previousValue: 11_120,
                       format: .compact, systemImage: "person.2.fill", accent: .cyan),
            StatMetric(title: "Conversion", value: 3.8, previousValue: 4.1,
                       format: .percent, systemImage: "chart.line.uptrend.xyaxis", accent: .coral),
            StatMetric(title: "Avg. Order", value: 86, previousValue: 81,
                       format: .currency, systemImage: "cart.fill", accent: .violet),
        ]
    }

    func loadSummary() async -> [SummaryItem] {
        await Self.simulateLatency()
        return [
            SummaryItem(title: "Today", value: "$3,420", systemImage: "sun.max.fill", tint: .lime),
            SummaryItem(title: "Orders", value: "248", systemImage: "shippingbox.fill", tint: .cyan),
            SummaryItem(title: "Refunds", value: "$190", systemImage: "arrow.uturn.backward", tint: .coral),
            SummaryItem(title: "New", value: "32", systemImage: "sparkles", tint: .violet),
        ]
    }

    func loadRecentItems() async -> [RecentItem] {
        await Self.simulateLatency()
        let now = Date()
        return [
            RecentItem(title: "Stripe Payout", subtitle: "Bank transfer", amount: 2_480,
                       date: now.addingTimeInterval(-60 * 24), systemImage: "building.columns.fill", accent: .lime),
            RecentItem(title: "Pro Subscription", subtitle: "Jordan Blake", amount: 49,
                       date: now.addingTimeInterval(-60 * 95), systemImage: "crown.fill", accent: .violet),
            RecentItem(title: "Refund Issued", subtitle: "Order #4821", amount: -68,
                       date: now.addingTimeInterval(-60 * 210), systemImage: "arrow.uturn.backward", accent: .coral),
            RecentItem(title: "New Order", subtitle: "Casey Morgan", amount: 132,
                       date: now.addingTimeInterval(-60 * 320), systemImage: "bag.fill", accent: .cyan),
            RecentItem(title: "Pro Subscription", subtitle: "Riley Chen", amount: 49,
                       date: now.addingTimeInterval(-60 * 540), systemImage: "crown.fill", accent: .violet),
        ]
    }

    // MARK: Analytics

    func loadAnalytics(range: AnalyticsRange) async -> AnalyticsData {
        await Self.simulateLatency()
        let count = range.pointCount

        let revenuePoints: [TrendPoint] = (0..<count).map { index in
            let base = 1_200.0 + Double(index) * (range == .week ? 70 : 9)
            let wave = sin(Double(index) / 3.4) * 260
            let noise = (Self.hash(index, salt: 11) - 0.5) * 520
            let label = Self.axisLabel(for: range, index: index, total: count)
            return TrendPoint(label: label, value: max(220, base + wave + noise))
        }

        let weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let userPoints: [TrendPoint] = (0..<7).map { index in
            let base = 320.0 + sin(Double(index) / 1.6) * 120
            let noise = (Self.hash(index, salt: 29) - 0.5) * 140
            return TrendPoint(label: weekday[index], value: max(60, base + noise))
        }

        let kpis = [
            KPItem(title: "Conversion", value: "3.8%", deltaPercent: 0.6),
            KPItem(title: "Avg. Session", value: "4m 12s", deltaPercent: 2.4),
            KPItem(title: "Bounce Rate", value: "38%", deltaPercent: -1.8),
        ]

        return AnalyticsData(
            revenue: AnalyticsSeries(name: "Revenue", points: revenuePoints, accent: .lime),
            weeklyUsers: AnalyticsSeries(name: "New Users", points: userPoints, accent: .cyan),
            kpis: kpis
        )
    }

    // MARK: Activity

    func loadActivity() async -> [ActivityEvent] {
        await Self.simulateLatency()
        let now = Date()
        let minute = 60.0
        let hour = 3_600.0
        let day = 86_400.0
        return [
            ActivityEvent(title: "Payment received", detail: "$2,480 from Stripe payout",
                          date: now.addingTimeInterval(-12 * minute), category: .payment),
            ActivityEvent(title: "New user signed up", detail: "Jordan Blake joined the Pro plan",
                          date: now.addingTimeInterval(-48 * minute), category: .user),
            ActivityEvent(title: "Server scaled up", detail: "Auto-scaling added 2 instances",
                          date: now.addingTimeInterval(-2 * hour), category: .system),
            ActivityEvent(title: "High traffic alert", detail: "Requests spiked 220% in 5 min",
                          date: now.addingTimeInterval(-3 * hour), category: .alert),
            ActivityEvent(title: "Support message", detail: "Casey Morgan replied to ticket #18",
                          date: now.addingTimeInterval(-5 * hour), category: .message),
            ActivityEvent(title: "Payment received", detail: "$49 Pro subscription · Riley Chen",
                          date: now.addingTimeInterval(-1 * day - 1 * hour), category: .payment),
            ActivityEvent(title: "New user signed up", detail: "Taylor Reed created an account",
                          date: now.addingTimeInterval(-1 * day - 4 * hour), category: .user),
            ActivityEvent(title: "Database backup", detail: "Nightly snapshot completed",
                          date: now.addingTimeInterval(-1 * day - 9 * hour), category: .system),
            ActivityEvent(title: "Refund processed", detail: "$68 refund for order #4821",
                          date: now.addingTimeInterval(-2 * day - 2 * hour), category: .alert),
            ActivityEvent(title: "Support message", detail: "Riley Chen opened ticket #21",
                          date: now.addingTimeInterval(-2 * day - 6 * hour), category: .message),
        ]
    }

    // MARK: Profile

    func loadProfile() async -> UserProfile {
        await Self.simulateLatency()
        return UserProfile(name: "Alex Rivera", role: "Product Owner", email: "alex@pulse.app")
    }

    // MARK: - Helpers

    /// Simulates network/database latency so loading states are visible.
    private static func simulateLatency() async {
        try? await Task.sleep(for: .milliseconds(450))
    }

    /// Deterministic pseudo-random value in 0...1 based on an index and salt.
    private static func hash(_ index: Int, salt: Int) -> Double {
        let x = sin(Double(index) * 12.9898 + Double(salt) * 78.233) * 43_758.5453
        return x - floor(x)
    }

    /// Sparse axis labels appropriate for the selected range.
    private static func axisLabel(for range: AnalyticsRange, index: Int, total: Int) -> String {
        switch range {
        case .week:
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index % 7]
        case .month, .quarter:
            return "\(index + 1)"
        }
    }
}
