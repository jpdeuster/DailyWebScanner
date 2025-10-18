import Foundation
import SwiftData
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var isSearching: Bool = false
    @Published var historySearch: String = ""
    @Published var activeError: ViewError?

    private var modelContext: ModelContext?

    // Handle to the current search task and a token to identify it
    private var currentSearchTask: Task<SearchRecord, Error>?
    private var currentTaskToken: UUID?

    // Clients read API-Keys dynamically from Keychain
    private lazy var serpClient = SerpAPIClient(apiKeyProvider: { KeychainHelper.get(.serpAPIKey) })
    private lazy var openAIClient = OpenAIClient(apiKeyProvider: { KeychainHelper.get(.openAIAPIKey) })
    private let renderer = HTMLRenderer()

    // UserDefaults keys (avoid magic strings)
    private enum DefaultsKey {
        static let serpHL = "settings.serp.hl"
        static let serpGL = "settings.serp.gl"
        static let serpNum = "settings.serp.num"
    }

    func inject(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func cancelCurrentSearch() {
        currentSearchTask?.cancel()
        currentSearchTask = nil
        currentTaskToken = nil
        isSearching = false
    }

    func runSearch(query: String) async throws -> SearchRecord {
        cancelCurrentSearch()

        guard let modelContext else {
            let err = ViewError(message: "Kein ModelContext verfügbar.")
            activeError = err
            throw err
        }

        // Read Serp settings from UserDefaults (as written by SettingsView via @AppStorage)
        let defaults = UserDefaults.standard
        let hl = defaults.string(forKey: DefaultsKey.serpHL) ?? "de"
        let gl = defaults.string(forKey: DefaultsKey.serpGL) ?? "de"
        let configuredNum = defaults.integer(forKey: DefaultsKey.serpNum)
        let count = configuredNum > 0 ? configuredNum : 20

        let ctx = modelContext

        isSearching = true
        let token = UUID()
        currentTaskToken = token

        let task = Task<SearchRecord, Error> {
            try Task.checkCancellation()

            let serpResults = try await serpClient.fetchTopResults(query: query, count: count, hl: hl, gl: gl)

            try Task.checkCancellation()

            var results: [SearchResult] = []
            results.reserveCapacity(serpResults.count)

            for r in serpResults {
                try Task.checkCancellation()

                let title = r.title ?? "(ohne Titel)"
                let link = r.link ?? ""
                let snippet = r.snippet ?? ""
                guard !link.isEmpty, !snippet.isEmpty else { continue }

                // Versuche OpenAI-Zusammenfassung, falls Key vorhanden, sonst verwende Original-Snippet
                let summary: String
                if let openAIKey = KeychainHelper.get(.openAIAPIKey), !openAIKey.isEmpty {
                    do {
                        summary = try await openAIClient.summarize(snippet: snippet, title: r.title, link: r.link)
                    } catch {
                        // Bei Fehler mit OpenAI, verwende das Original-Snippet
                        summary = snippet
                    }
                } else {
                    // Kein OpenAI Key vorhanden, verwende Original-Snippet
                    summary = snippet
                }
                
                results.append(SearchResult(title: title, link: link, snippet: snippet, summary: summary))
            }

            try Task.checkCancellation()

            let html = renderer.renderHTML(query: query, results: results)

            let record = SearchRecord(query: query, htmlSummary: html, results: results)
            ctx.insert(record)
            try ctx.save()

            return record
        }

        currentSearchTask = task

        defer {
            if currentTaskToken == token {
                currentSearchTask = nil
                currentTaskToken = nil
                isSearching = false
            }
        }

        do {
            return try await task.value
        } catch is CancellationError {
            // Propagate cancellation without converting to another error type
            throw CancellationError()
        } catch {
            let err = ViewError(message: (error as NSError).localizedDescription)
            activeError = err
            throw err
        }
    }

    func rerenderHTML(for record: SearchRecord) async {
        let newHTML = renderer.renderHTML(query: record.query, results: record.results)
        record.htmlSummary = newHTML
        do {
            try modelContext?.save()
        } catch {
            activeError = ViewError(message: "Speichern fehlgeschlagen: \(error.localizedDescription)")
        }
    }
}

struct ViewError: Identifiable, Error {
    let id = UUID()
    let message: String
}
