import Foundation
import SwiftData
import Combine
import os.log

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var isSearching: Bool = false
    @Published var historySearch: String = ""
    @Published var activeError: ViewError?

    private var modelContext: ModelContext?

    // Handle to the current search task and a token to identify it
    private var currentSearchTask: Task<SendableSearchRecord, Error>?
    private var currentTaskToken: UUID?
    
    // Wrapper to make SearchRecord Sendable for Task
    private struct SendableSearchRecord: @unchecked Sendable {
        let record: SearchRecord
        init(_ record: SearchRecord) {
            self.record = record
        }
    }

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

    private func encodeContentAnalysis(_ analysis: ContentAnalysis) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(analysis)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to encode content analysis: \(error)")
            return ""
        }
    }
    
    private func fetchLinkContents(for results: [SearchResult]) async {
        let fetcher = LinkContentFetcher()
        var linkContents: [LinkContent] = []
        var totalImages = 0
        var totalSize = 0
        
        // Limit to first 5 links to avoid overwhelming the system
        let linksToFetch = Array(results.prefix(5))
        
        for result in linksToFetch {
            do {
                DebugLogger.shared.logWebViewAction("Fetching content for: \(result.link)")
                let content = try await fetcher.fetchCompleteArticle(from: result.link)
                linkContents.append(content)
                totalImages += content.images.count
                totalSize += content.html.utf8.count
                
                // Add image sizes
                for image in content.images {
                    if let data = image.data {
                        totalSize += data.count
                    }
                }
                
            } catch {
                DebugLogger.shared.logWebViewAction("Failed to fetch content for \(result.link): \(error)")
            }
        }
        
        // Update the search record with link contents
        await updateSearchRecordWithLinkContents(linkContents, totalImages: totalImages, totalSize: totalSize)
    }
    
    private func updateSearchRecordWithLinkContents(_ linkContents: [LinkContent], totalImages: Int, totalSize: Int) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(linkContents)
            let linkContentsJSON = String(data: data, encoding: .utf8) ?? ""
            
            // Find the most recent search record
            let descriptor = FetchDescriptor<SearchRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let records = try modelContext.fetch(descriptor)
            
            if let latestRecord = records.first {
                latestRecord.linkContents = linkContentsJSON
                latestRecord.hasLinkContents = !linkContents.isEmpty
                latestRecord.totalImagesDownloaded = totalImages
                latestRecord.totalContentSize = totalSize
                
                try modelContext.save()
                DebugLogger.shared.logWebViewAction("Updated search record with \(linkContents.count) link contents")
            }
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to update search record with link contents: \(error)")
        }
    }
    
    func runSearch(query: String) async throws -> SearchRecord {
        DebugLogger.shared.logSearchStart(query: query)
        cancelCurrentSearch()

        guard let modelContext else {
            let err = ViewError(message: "Kein ModelContext verfügbar.")
            activeError = err
            DebugLogger.shared.logSearchError(query: query, error: err)
            throw err
        }

        // Read Serp settings from UserDefaults (as written by SettingsView via @AppStorage)
        let defaults = UserDefaults.standard
        let hl = defaults.string(forKey: "settings.serp.hl") ?? ""
        let gl = defaults.string(forKey: "settings.serp.gl") ?? ""
        let configuredNum = defaults.integer(forKey: "settings.serp.num")
        let count = configuredNum > 0 ? configuredNum : 20
        
        // Read additional SerpAPI parameters
        let location = defaults.string(forKey: "settings.serp.location") ?? ""
        let safe = defaults.string(forKey: "settings.serp.safe") ?? ""
        let tbm = defaults.string(forKey: "settings.serp.tbm") ?? ""
        let tbs = defaults.string(forKey: "settings.serp.tbs") ?? ""
        let as_qdr = defaults.string(forKey: "settings.serp.as_qdr") ?? ""
        
        // Debug: Log search parameters
        DebugLogger.shared.logSearchParameters(query: query, language: hl, region: gl, count: count)

        let ctx = modelContext

        isSearching = true
        let token = UUID()
        currentTaskToken = token

        let task = Task<SendableSearchRecord, Error> {
            try Task.checkCancellation()

            // Log SerpAPI call
            let serpKeyPresent = KeychainHelper.get(.serpAPIKey) != nil
            DebugLogger.shared.logSerpAPICall(query: query, apiKeyPresent: serpKeyPresent)

            let serpResults = try await serpClient.fetchTopResults(
                query: query, 
                count: count, 
                hl: hl, 
                gl: gl,
                location: location.isEmpty ? nil : location,
                safe: safe.isEmpty ? nil : safe,
                tbm: tbm.isEmpty ? nil : tbm,
                tbs: tbs.isEmpty ? nil : tbs,
                as_qdr: as_qdr.isEmpty ? nil : as_qdr
            )

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
                    DebugLogger.shared.logOpenAICall(query: query, apiKeyPresent: true)
                    do {
                        summary = try await openAIClient.summarize(snippet: snippet, title: r.title, link: r.link)
                    } catch {
                        // Bei Fehler mit OpenAI, verwende das Original-Snippet
                        DebugLogger.shared.logWarning(component: "SearchViewModel", message: "OpenAI summarization failed, using original snippet")
                        summary = snippet
                    }
                } else {
                    // Kein OpenAI Key vorhanden, verwende Original-Snippet
                    DebugLogger.shared.logOpenAICall(query: query, apiKeyPresent: false)
                    summary = snippet
                }
                
                results.append(SearchResult(title: title, link: link, snippet: snippet, summary: summary))
            }

            try Task.checkCancellation()

            let html = renderer.renderHTML(query: query, results: results)

        // Perform content analysis
        let contentAnalysis = HTMLContentParser.parseContent(from: html)
        let analysisJSON = encodeContentAnalysis(contentAnalysis)
        
        // Fetch link contents (async, don't block search)
        Task {
            await fetchLinkContents(for: results)
        }
        
        let record = SearchRecord(
            query: query,
            htmlSummary: html,
            language: hl,
            region: gl,
            location: location,
            safeSearch: safe,
            searchType: tbm,
            timeRange: as_qdr,
            numberOfResults: count,
            resultCount: results.count,
            results: results,
            contentAnalysis: analysisJSON,
            headlinesCount: contentAnalysis.headlines.count,
            linksCount: contentAnalysis.links.count,
            contentBlocksCount: contentAnalysis.contentBlocks.count,
            tagsCount: contentAnalysis.tags.count,
            hasContentAnalysis: true
        )
            ctx.insert(record)
            try ctx.save()

            return SendableSearchRecord(record)
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
            let sendableRecord = try await task.value
            return sendableRecord.record
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
