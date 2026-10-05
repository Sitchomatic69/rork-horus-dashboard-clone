//
//  SearchView.swift
//  Pulse
//
//  The Search panel: universal search bar with type selection,
//  result tabs for breach data (OSINTDog), leak records (DeHashed),
//  stealer logs (Horus), pagination, and detailed result cards.
//

import SwiftUI
import UIKit

struct SearchView: View {
    let apiKeyManager: ApiKeyManager
    @State private var viewModel: SearchViewModel
    @State private var shareItem: ShareItem?
    @State private var copiedCount: Int?
    @State private var selectedFormat: ExportFormat = .csv

    init(apiKeyManager: ApiKeyManager) {
        self.apiKeyManager = apiKeyManager
        self._viewModel = State(wrappedValue: SearchViewModel(apiKeyManager: apiKeyManager))
    }

    var body: some View {
        DashboardScreen {
            header
        } content: {
            searchBar
            if viewModel.isLoading && viewModel.breachResults.isEmpty && viewModel.stealerResults.isEmpty && viewModel.dehashedResults.isEmpty {
                loadingState
            } else if let error = viewModel.error, viewModel.breachResults.isEmpty && viewModel.stealerResults.isEmpty && viewModel.dehashedResults.isEmpty {
                errorState(error)
            } else if !viewModel.breachResults.isEmpty || !viewModel.stealerResults.isEmpty || !viewModel.dehashedResults.isEmpty {
                resultsSection
            } else {
                emptyState
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Search")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Breach data & stealer logs across 15+ sources")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 12)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        VStack(spacing: 10) {
            SearchBarView(
                text: $viewModel.searchTerm,
                selectedType: $viewModel.selectedType,
                isSearching: viewModel.isLoading,
                onSubmit: { Task { await viewModel.search() } }
            )

            HStack(spacing: 8) {
                Text("Horus field:")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(HorusField.allCases) { field in
                            FilterChip(
                                title: field.rawValue,
                                isSelected: viewModel.horusField == field,
                                action: { viewModel.horusField = field }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            exportBar
            if !viewModel.breachResults.isEmpty {
                resultsGroup(
                    title: "Breach Records — OSINTDog",
                    count: viewModel.totalDog,
                    tint: Theme.accent,
                    results: viewModel.breachResults.map { breach in
                        ResultCardData.breach(breach)
                    },
                    hasMore: viewModel.hasMoreDog,
                    onLoadMore: { Task { await viewModel.loadMoreDog() } }
                )
            }

            if !viewModel.stealerResults.isEmpty {
                resultsGroup(
                    title: "Stealer Logs — Horus",
                    count: viewModel.totalHorus,
                    tint: Theme.cyan,
                    results: viewModel.stealerResults.map { log in
                        ResultCardData.stealer(log)
                    },
                    hasMore: viewModel.hasMoreHorus,
                    onLoadMore: { Task { await viewModel.loadMoreHorus() } }
                )
            }

            if !viewModel.dehashedResults.isEmpty {
                resultsGroup(
                    title: "Leak Records — DeHashed",
                    count: viewModel.totalDeHashed,
                    tint: Theme.violet,
                    results: viewModel.dehashedResults.map { breach in
                        ResultCardData.breach(breach)
                    },
                    hasMore: viewModel.hasMoreDehashed,
                    onLoadMore: { Task { await viewModel.loadMoreDeHashed() } }
                )
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(Theme.accent)
                    Spacer()
                }
            }
        }
    }

    private func resultsGroup(
        title: String,
        count: Int,
        tint: Color,
        results: [ResultCardData],
        hasMore: Bool,
        onLoadMore: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
                Spacer()
                Text("\(count) total")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }

            LazyVStack(spacing: 10) {
                ForEach(results) { data in
                    ResultCard(data: data)
                }

                if hasMore {
                    Button(action: onLoadMore) {
                        Text("Load more…")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    // MARK: - Export

    /// Output formats available in the export dropdown.
    private enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case txt = "TXT"
        case json = "JSON"

        var id: String { rawValue }

        var fileExtension: String { rawValue.lowercased() }

        var menuTitle: String {
            switch self {
            case .csv: return "Full credentials (.csv)"
            case .txt: return "Complete password list (.txt)"
            case .json: return "Structured credentials (.json)"
            }
        }

        var icon: String {
            switch self {
            case .csv: return "tablecells"
            case .txt: return "doc.plaintext"
            case .json: return "curlybraces.square"
            }
        }
    }

    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    /// Number of unique credentials currently loaded (matches what exports contain).
    private var loadedCredentialCount: Int {
        PasswordExporter.deduplicated(
            PasswordExporter.collect(
                breaches: viewModel.breachResults,
                dehashed: viewModel.dehashedResults,
                stealer: viewModel.stealerResults
            )
        ).count
    }

    private var exportBar: some View {
        HStack(spacing: 12) {
            if viewModel.isExporting {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Theme.accent)
                        .controlSize(.small)
                    Text("Fetching all pages…")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            } else if let copied = copiedCount {
                Label("\(copied) passwords copied", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.positive)
            } else {
                Text("\(loadedCredentialCount) credentials")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            HStack(spacing: 8) {
                // Format dropdown
                Menu {
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            Haptics.select()
                            selectedFormat = format
                        } label: {
                            if selectedFormat == format {
                                Label(format.menuTitle, systemImage: "checkmark")
                            } else {
                                Label(format.menuTitle, systemImage: format.icon)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedFormat.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.surfaceElevated))
                    .overlay(Capsule().strokeBorder(Theme.strokeStrong))
                }
                .disabled(viewModel.isExporting || viewModel.isLoading)

                // Export action — uses the selected format
                Button {
                    Task { await export(format: selectedFormat) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.accent))
                }
                .disabled(viewModel.isExporting || viewModel.isLoading)

                // Copy shortcut
                Button { copyPasswords() } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Theme.surfaceElevated))
                        .overlay(Circle().strokeBorder(Theme.strokeStrong))
                }
                .disabled(viewModel.isExporting || viewModel.isLoading)
            }
        }
    }

    /// Fetches all remaining pages first, then generates the file in the
    /// selected format and opens the share sheet.
    private func export(format: ExportFormat) async {
        Haptics.tap()
        await viewModel.fetchAllPages()

        let rows = PasswordExporter.collect(
            breaches: viewModel.breachResults,
            dehashed: viewModel.dehashedResults,
            stealer: viewModel.stealerResults
        )
        guard !rows.isEmpty else { return }

        let content: String
        switch format {
        case .csv:
            content = PasswordExporter.csv(from: rows)
        case .txt:
            content = PasswordExporter.passwordList(from: rows)
        case .json:
            content = PasswordExporter.json(from: rows)
        }

        guard let url = PasswordExporter.write(
            content,
            fileName: PasswordExporter.fileName(
                term: viewModel.searchTerm,
                extension: format.fileExtension
            )
        ) else { return }

        Haptics.soft()
        shareItem = ShareItem(url: url)
    }

    private func copyPasswords() {
        let rows = PasswordExporter.collect(
            breaches: viewModel.breachResults,
            dehashed: viewModel.dehashedResults,
            stealer: viewModel.stealerResults
        )
        let passwords = PasswordExporter.uniquePasswords(from: rows)
        guard !passwords.isEmpty else { return }

        UIPasteboard.general.string = passwords.joined(separator: "\n")
        Haptics.soft()
        copiedCount = passwords.count
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            copiedCount = nil
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            ForEach(0..<4, id: \.self) { _ in
                SkeletonBlock(height: 80)
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.negative)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textTertiary)
            Text("Enter a search term above\nto query breach databases")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    SearchView(apiKeyManager: ApiKeyManager())
        .preferredColorScheme(.dark)
}
