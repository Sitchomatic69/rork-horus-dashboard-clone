//
//  DateParsing.swift
//  Pulse
//
//  Lenient timestamp parsing for the heterogeneous date formats found
//  across OSINT APIs (ISO 8601 variants and localized breach-feed dates).
//

import Foundation

/// Parses timestamps in any format the intelligence APIs are known to emit.
enum DateParser {

    /// ISO 8601 with fractional seconds (e.g. "2026-10-04T03:37:29.0616938Z").
    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// ISO 8601 without fractional seconds (e.g. "2026-10-04T03:37:29Z").
    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Non-ISO patterns seen in breach feeds and stealer metadata.
    private static let fallbackFormats: [DateFormatter] = {
        ["yyyy-MM-dd HH:mm:ss", "dd.MM.yyyy HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss",
         "dd.MM.yyyy", "yyyy-MM-dd", "MM/dd/yyyy"]
            .map { pattern in
                let f = DateFormatter()
                f.dateFormat = pattern
                f.locale = Locale(identifier: "en_US_POSIX")
                f.timeZone = TimeZone.current
                return f
            }
    }()

    /// Returns a Date for any recognized timestamp string, otherwise nil.
    static func parse(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if let date = isoFractional.date(from: value) { return date }
        if let date = isoPlain.date(from: value) { return date }
        for formatter in fallbackFormats {
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}
