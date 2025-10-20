import Foundation
import SwiftData
import Combine
import os.log

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var isSearching: Bool = false
    @Published var historySearch: String = ""
    @Published var activeError: Error?

    var modelContext: ModelContext?

    // Handle to the current search task and a token to identify it
    private var currentSearchTask: Task<[SerpResultData], Error>?
    private var currentTaskToken: UUID?
    
    // Create a struct to hold the raw data that is Sendable
    private struct SerpResultData: Sendable {
        let title: String
        let link: String
        let snippet: String
    }

    // Clients read API-Keys dynamically from Keychain
    private lazy var serpClient = SerpAPIClient(apiKeyProvider: { KeychainHelper.get(.serpAPIKey) })
    private lazy var openAIClient = OpenAIClient(apiKeyProvider: { KeychainHelper.get(.openAIAPIKey) })
    private let renderer = HTMLRenderer()

    func cancelCurrentSearch() {
        currentSearchTask?.cancel()
        currentSearchTask = nil
        currentTaskToken = nil
        isSearching = false
    }

    func runSearchForResults(query: String, language: String = "", region: String = "", location: String = "", safe: String = "", tbm: String = "", tbs: String = "", as_qdr: String = "", nfpr: String = "", filter: String = "") async throws -> [SearchResult] {
        DebugLogger.shared.logSearchStart(query: query)
        cancelCurrentSearch()

        guard modelContext != nil else {
            let err = NSError(domain: "SearchViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kein ModelContext verfügbar."])
            activeError = err
            DebugLogger.shared.logSearchError(query: query, error: err)
            throw err
        }

        // Use provided parameters or defaults
        let hl = language.isEmpty ? "" : language
        let gl = region.isEmpty ? "" : region
        // Always fetch all available results (up to 100 to avoid overwhelming the system)
        let count = 100
        
        // Debug: Log search parameters
        DebugLogger.shared.logSearchParameters(query: query, language: hl, region: gl, count: count)
        DebugLogger.shared.logWebViewAction("SerpAPI: Fetching all available results (max 100)")

        isSearching = true
        let token = UUID()
        currentTaskToken = token


        let task = Task<[SerpResultData], Error> {
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
                as_qdr: as_qdr.isEmpty ? nil : as_qdr,
                nfpr: nfpr.isEmpty ? nil : nfpr,
                filter: filter.isEmpty ? nil : filter
            )
            
            DebugLogger.shared.logWebViewAction("SerpAPI returned \(serpResults.count) results (requested: \(count))")

            // Check if task was cancelled
            try Task.checkCancellation()

            // Process results and create SerpResultData objects (Sendable)
            var searchResults: [SerpResultData] = []
            
            for result in serpResults {
                let searchResult = SerpResultData(
                    title: result.title ?? "",
                    link: result.link ?? "",
                    snippet: result.snippet ?? ""
                )
                searchResults.append(searchResult)
            }

            // Check if task was cancelled before returning
            try Task.checkCancellation()
            
            DebugLogger.shared.logSearchSuccess(query: query, resultCount: searchResults.count)
            return searchResults
        }

        currentSearchTask = task

        do {
            let rawResults = try await task.value
            isSearching = false
            currentSearchTask = nil
            currentTaskToken = nil
            
            // Now create SearchResult objects on the main thread
            var searchResults: [SearchResult] = []
            for rawResult in rawResults {
                let searchResult = SearchResult(
                    title: rawResult.title,
                    link: rawResult.link,
                    snippet: rawResult.snippet
                )
                searchResults.append(searchResult)
            }
            
            return searchResults
        } catch {
            isSearching = false
            currentSearchTask = nil
            currentTaskToken = nil
            
            if error is CancellationError {
                DebugLogger.shared.logSearchCancelled(query: query)
                throw error
            }
            
            let viewError = NSError(domain: "SearchViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Suche fehlgeschlagen: \(error.localizedDescription)"])
            activeError = viewError
            DebugLogger.shared.logSearchError(query: query, error: viewError)
            throw viewError
        }
    }

    func runSearch(query: String, language: String = "", region: String = "", location: String = "", safe: String = "", tbm: String = "", tbs: String = "", as_qdr: String = "", nfpr: String = "", filter: String = "") async throws -> SearchRecord {
        DebugLogger.shared.logSearchStart(query: query)
        cancelCurrentSearch()

        guard modelContext != nil else {
            let err = NSError(domain: "SearchViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kein ModelContext verfügbar."])
            activeError = err
            DebugLogger.shared.logSearchError(query: query, error: err)
            throw err
        }

        // Use provided parameters or defaults
        let hl = language.isEmpty ? "" : language
        let gl = region.isEmpty ? "" : region
        // Always fetch all available results (up to 100 to avoid overwhelming the system)
        let count = 100
        
        // Debug: Log search parameters
        DebugLogger.shared.logSearchParameters(query: query, language: hl, region: gl, count: count)
        DebugLogger.shared.logWebViewAction("SerpAPI: Fetching all available results (max 100)")

        isSearching = true
        let token = UUID()
        currentTaskToken = token


        let task = Task<[SerpResultData], Error> {
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
                as_qdr: as_qdr.isEmpty ? nil : as_qdr,
                nfpr: nfpr.isEmpty ? nil : nfpr,
                filter: filter.isEmpty ? nil : filter
            )
            
            DebugLogger.shared.logWebViewAction("SerpAPI returned \(serpResults.count) results (requested: \(count))")

            try Task.checkCancellation()

            // Process results and create SerpResultData objects (Sendable)
            var searchResults: [SerpResultData] = []
            
            for result in serpResults {
                let searchResult = SerpResultData(
                    title: result.title ?? "",
                    link: result.link ?? "",
                    snippet: result.snippet ?? ""
                )
                searchResults.append(searchResult)
            }

            try Task.checkCancellation()

            DebugLogger.shared.logSearchSuccess(query: query, resultCount: searchResults.count)
            return searchResults
        }

        currentSearchTask = task

        do {
            let rawResults = try await task.value
            isSearching = false
                currentSearchTask = nil
                currentTaskToken = nil
            
            // Now create SearchResult objects on the main thread
            var results: [SearchResult] = []
            for rawResult in rawResults {
                let result = SearchResult(
                    title: rawResult.title,
                    link: rawResult.link,
                    snippet: rawResult.snippet
                )
                results.append(result)
            }

            let record = SearchRecord(
                query: query,
                language: hl,
                region: gl,
                location: location,
                safeSearch: safe,
                searchType: tbm,
                timeRange: as_qdr
            )
            record.results = results
            
            return record
        } catch {
            isSearching = false
            currentSearchTask = nil
            currentTaskToken = nil
            
            if error is CancellationError {
                DebugLogger.shared.logSearchCancelled(query: query)
                throw error
            }
            
            let viewError = NSError(domain: "SearchViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Suche fehlgeschlagen: \(error.localizedDescription)"])
            activeError = viewError
            DebugLogger.shared.logSearchError(query: query, error: viewError)
            throw viewError
        }
    }

    func updateSearchRecordWithLinkContents(_ record: SearchRecord) async {
        guard let modelContext = modelContext else { return }
        
        do {
            // Update each SearchResult with link content
            for result in record.results {
                if URL(string: result.link) != nil {
                    // Simple content fetching - just set summary to snippet for now
                    result.summary = result.snippet
                }
            }
            
            // Save the updated record
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("Updated search record with link contents")
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to update search record with link contents: \(error)")
        }
    }
}