//
//  OSINTModels.swift
//  Pulse
//
//  Domain models for the OSINT investigation app.
//  Covers breach search results, stealer logs, queries, API status,
//  async search tracking, and shared design types.
//

import Foundation
import SwiftUI

// MARK: - Search

/// The type of identifier being searched.
enum SearchType: String, CaseIterable, Identifiable {
    case email = "Email"
    case username = "Username"
    case domain = "Domain"
    case ip = "IP Address"
    case phone = "Phone"

    var id: String { rawValue }

    var apiParam: String {
        switch self {
        case .email: return "email"
        case .username: return "username"
        case .domain: return "domain"
        case .ip: return "ip"
        case .phone: return "phone"
        }
    }
}

/// A search performed by the user, stored for history.
struct SearchQuery: Identifiable, Hashable {
    let id: UUID
    let term: String
    let type: SearchType
    let date: Date

    init(id: UUID = UUID(), term: String, type: SearchType, date: Date = Date()) {
        self.id = id
        self.term = term
        self.type = type
        self.date = date
    }
}

/// The data source that produced a result.
enum DataSource: String, Hashable {
    case osintdog = "OSINTDog"
    case horus = "Horus"
}

// MARK: - Horus field filter options

/// Field types available for filtering Horus stealer log searches.
enum HorusField: String, CaseIterable, Identifiable {
    case all = "All"
    case domain = "Domain"
    case email = "Email"
    case password = "Password"
    case url = "URL"
    case ip = "IP Address"
    case phone = "Phone"
    case fullname = "Full Name"
    case username = "Username"

    var id: String { rawValue }

    var apiValue: String? {
        switch self {
        case .all: return nil
        default: return rawValue.lowercased()
        }
    }
}

// MARK: - OSINTDog results

/// A single breach record from the OSINTDog API.
struct BreachResult: Identifiable, Hashable {
    let id: String
    let source: String
    let email: String?
    let username: String?
    let password: String?
    let domain: String?
    let ip: String?
    let date: Date?
    let fields: [String: String]

    init(
        id: String,
        source: String,
        email: String? = nil,
        username: String? = nil,
        password: String? = nil,
        domain: String? = nil,
        ip: String? = nil,
        date: Date? = nil,
        fields: [String: String] = [:]
    ) {
        self.id = id
        self.source = source
        self.email = email
        self.username = username
        self.password = password
        self.domain = domain
        self.ip = ip
        self.date = date
        self.fields = fields
    }

    /// User-visible summary line for the result card.
    var summary: String {
        email ?? username ?? domain ?? "Unknown identifier"
    }
}

/// Paginated response from OSINTDog.
struct OSINTDogSearchResponse: Hashable {
    let results: [BreachResult]
    let total: Int
    let page: Int
    let hasMore: Bool
}

/// An asynchronous search job tracked by OSINTDog.
struct OSINTDogAsyncSearch: Identifiable, Hashable {
    let id: String      // search ID returned by the API
    let status: OSINTDogSearchStatus
    let createdAt: Date
    let progress: Double?   // 0...1 if available

    var isComplete: Bool {
        status == .completed || status == .failed
    }
}

enum OSINTDogSearchStatus: String, Hashable {
    case queued
    case processing
    case completed
    case failed
}

/// API operational status response.
struct OSINTDogStatus: Hashable {
    let healthy: Bool
    let services: [String: Bool]    // service name → online
    let message: String?
}

// MARK: - Horus stealer log results

/// A stealer log entry from the Horus partner v1 API.
struct StealerLogResult: Identifiable, Hashable {
    let id: String
    let logId: String?
    let domain: String?
    let url: String?
    let username: String?
    let password: String?
    let os: String?
    let country: String?
    let ip: String?
    let malwareFamily: String?
    let capturedAt: Date?

    init(
        id: String,
        logId: String? = nil,
        domain: String? = nil,
        url: String? = nil,
        username: String? = nil,
        password: String? = nil,
        os: String? = nil,
        country: String? = nil,
        ip: String? = nil,
        malwareFamily: String? = nil,
        capturedAt: Date? = nil
    ) {
        self.id = id
        self.logId = logId
        self.domain = domain
        self.url = url
        self.username = username
        self.password = password
        self.os = os
        self.country = country
        self.ip = ip
        self.malwareFamily = malwareFamily
        self.capturedAt = capturedAt
    }

    var summary: String {
        domain ?? url ?? "Unknown host"
    }
}

/// Paginated response from Horus stealer search.
struct HorusSearchResponse: Hashable {
    let results: [StealerLogResult]
    let total: Int
    let cursor: String?
    let hasMore: Bool
}

/// A stealer log result from Horus telegram module.
struct HorusTelegramResult: Identifiable, Hashable {
    let id: String
    let chatId: String?
    let chatName: String?
    let message: String?
    let sender: String?
    let date: Date?
    let matchedKeyword: String?
}

/// A forum post result from Horus forums module.
struct HorusForumResult: Identifiable, Hashable {
    let id: String
    let threadTitle: String?
    let forumName: String?
    let content: String?
    let author: String?
    let date: Date?
    let url: String?
}

// MARK: - API health

/// Validation state for a configured API key.
enum ApiValidationState: Hashable {
    case unknown
    case validating
    case valid(plan: String?)
    case invalid(reason: String?)
    case error(String)

    var isReady: Bool {
        if case .valid = self { return true }
        return false
    }
}

/// Source filter for the Browse panel.
enum BrowseFilter: String, CaseIterable, Identifiable {
    case all = "All Sources"
    case osintdog = "OSINTDog"
    case horus = "Horus"

    var id: String { rawValue }
}

// MARK: - Shared design types

/// Named accent roles used by settings rows and other shared components.
enum MetricAccent: Hashable {
    case lime, cyan, coral, violet

    var color: Color {
        switch self {
        case .lime: return Theme.accent
        case .cyan: return Theme.cyan
        case .coral: return Theme.coral
        case .violet: return Theme.violet
        }
    }
}
