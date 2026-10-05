//
//  PasswordExporter.swift
//  Pulse
//
//  Builds shareable exports of every credential found in the current search
//  results: a full CSV with all fields and a plain-text password list.
//

import Foundation

/// One credential line collected from search results, ready for export.
struct CredentialRow: Identifiable {
    let id = UUID()
    let source: String
    let identifier: String
    let username: String?
    let password: String
    let domain: String?
    let date: Date?
}

/// Flattens breach and stealer results into credential rows and renders
/// them as CSV or plain-text exports written to shareable temp files.
enum PasswordExporter {

    // MARK: - Collection

    /// Collects every password-bearing entry from all result sources.
    /// Duplicates are kept here and removed at export time via `deduplicated`.
    static func collect(
        breaches: [BreachResult],
        dehashed: [BreachResult],
        stealer: [StealerLogResult]
    ) -> [CredentialRow] {
        var rows: [CredentialRow] = []

        for breach in breaches + dehashed {
            guard let password = clean(breach.password) else { continue }
            rows.append(CredentialRow(
                source: breach.source,
                identifier: breach.summary,
                username: clean(breach.username),
                password: password,
                domain: breach.domain ?? domain(fromEmail: breach.email),
                date: breach.date
            ))
        }

        for log in stealer {
            guard let password = clean(log.password) else { continue }
            rows.append(CredentialRow(
                source: "Horus",
                identifier: log.username ?? log.summary,
                username: clean(log.username),
                password: password,
                domain: log.domain ?? domain(fromURL: log.url),
                date: log.capturedAt
            ))
        }

        return rows
    }

    // MARK: - Formats

    /// CSV with one row per credential, header line first.
    /// Identical rows are exported once — duplicates removed.
    static func csv(from allRows: [CredentialRow]) -> String {
        let rows = deduplicated(allRows)
        var lines: [String] = ["source,identifier,username,password,domain,captured"]
        for row in rows {
            let date = row.date.map(fileStampFormatter.string(from:)) ?? ""
            lines.append([
                row.source,
                row.identifier,
                row.username ?? "",
                row.password,
                row.domain ?? "",
                date
            ].map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    /// Plain-text list with each unique password on its own line,
    /// in first-seen order.
    static func passwordList(from allRows: [CredentialRow]) -> String {
        deduplicated(allRows).map(\.password).joined(separator: "\n")
    }

    /// Removes duplicate credentials, keeping the first occurrence.
    /// Two rows count as duplicates when source, identifier, username,
    /// password, domain, and date all match.
    static func deduplicated(_ rows: [CredentialRow]) -> [CredentialRow] {
        var seen = Set<String>()
        var unique: [CredentialRow] = []
        unique.reserveCapacity(rows.count)
        for row in rows {
            let key = "\(row.source)|\(row.identifier)|\(row.username ?? "")|\(row.password)|\(row.domain ?? "")|\(row.date?.timeIntervalSince1970 ?? 0)"
            if seen.insert(key).inserted {
                unique.append(row)
            }
        }
        return unique
    }

    /// Pretty-printed JSON array of credential objects, duplicates removed.
    static func json(from allRows: [CredentialRow]) -> String {
        let rows = deduplicated(allRows)
        let payload: [[String: Any]] = rows.map { row in
            var dict: [String: Any] = [
                "source": row.source,
                "identifier": row.identifier,
                "password": row.password
            ]
            if let username = row.username { dict["username"] = username }
            if let domain = row.domain { dict["domain"] = domain }
            if let date = row.date { dict["captured"] = jsonDateFormatter.string(from: date) }
            return dict
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return text
    }

    /// Unique passwords, most frequent first — used for clipboard copying.
    static func uniquePasswords(from rows: [CredentialRow]) -> [String] {
        var counts: [String: Int] = [:]
        for password in rows.map(\.password) { counts[password, default: 0] += 1 }
        return counts
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
            }
            .map(\.key)
    }

    // MARK: - Files

    /// Writes content to a temp file and returns its URL for the share sheet.
    static func write(_ content: String, fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Builds a safe file name from the search term and export kind,
    /// e.g. "pulse_johndoe.com_2026-10-05.csv".
    static func fileName(term: String, extension ext: String) -> String {
        let sanitized = term
            .map { ($0.isLetter || $0.isNumber) ? String($0) : "_" }
            .joined()
        let trimmed = String(sanitized.prefix(24))
        return "pulse_\(trimmed)_\(fileStampFormatter.string(from: Date())).\(ext)"
    }

    // MARK: - Private

    private static let jsonDateFormatter = ISO8601DateFormatter()

    private static let fileStampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func domain(fromEmail email: String?) -> String? {
        guard let email, let at = email.firstIndex(of: "@") else { return nil }
        return String(email[email.index(after: at)...])
    }

    private static func domain(fromURL url: String?) -> String? {
        guard let url, let host = URL(string: url)?.host else { return nil }
        return host
    }

    /// RFC 4180 escaping: quote fields containing commas, quotes, or newlines.
    private static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}
