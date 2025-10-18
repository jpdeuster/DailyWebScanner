//
//  ContentView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Search history records
    @Query(sort: \SearchRecord.createdAt, order: .reverse)
    private var records: [SearchRecord]

    @State private var selectedRecord: SearchRecord?
    @StateObject private var viewModel = SearchViewModel()

    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    // SerpAPI Account Info
    @AppStorage("serpAPIKey") private var serpKey: String = ""
    @State private var accountInfo = ""
    @State private var isLoadingAccountInfo = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Quick search field at top of sidebar
                HStack {
                    TextField("Suchbegriff eingeben …", text: $searchText, onCommit: {
                        Task { await runSearch() }
                    })
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .onChange(of: isSearchFieldFocused) { _, focused in
                        if focused {
                            DebugLogger.shared.logSearchFieldFocus()
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        if !newValue.isEmpty {
                            DebugLogger.shared.logSearchTextEntered(newValue)
                        }
                    }

                    Button {
                        DebugLogger.shared.logSearchButtonPressed()
                        Task { await runSearch() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut(.defaultAction)
                    .padding(.trailing, 8)
                    .disabled(viewModel.isSearching || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Suche starten")
                }

                List(selection: $selectedRecord) {
                    ForEach(records) { record in
                    NavigationLink(value: record) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.query)
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text(record.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                // Delete button for individual items
                                Button {
                                    deleteSelectedRecord(record)
                                } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .help("Delete this search result")
                            }
                            
                            // Search Parameters Display - immer anzeigen
                            HStack(spacing: 8) {
                                ParameterTag(
                                    text: "Lang: \(record.language.isEmpty ? "Any" : record.language)", 
                                    color: .blue
                                )
                                ParameterTag(
                                    text: "Region: \(record.region.isEmpty ? "Any" : record.region)", 
                                    color: .green
                                )
                                ParameterTag(
                                    text: "Type: \(record.searchType.isEmpty ? "All" : record.searchType)", 
                                    color: .orange
                                )
                                ParameterTag(
                                    text: "Time: \(record.timeRange.isEmpty ? "Any" : record.timeRange)", 
                                    color: .purple
                                )
                                ParameterTag(
                                    text: "Count: \(record.numberOfResults)", 
                                    color: .red
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                        )
                    }
                    }
                    .onDelete(perform: deleteRecords)
                }
                
            }
            .navigationTitle("Verlauf")
            .toolbar {
                ToolbarItemGroup {
                    if viewModel.isSearching {
                        Button(role: .cancel) {
                            viewModel.cancelCurrentSearch()
                        } label: {
                            Label("Abbrechen", systemImage: "xmark.circle")
                        }
                        .help("Laufende Suche abbrechen")
                    } else {
                        Button {
                            Task { await runSearch() }
                        } label: {
                            Label("Suchen", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .help("Manuelle Suche starten")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            Group {
                if viewModel.isSearching {
                    ProgressView("Suche läuft …")
                        .controlSize(.large)
                        .onAppear {
                            DebugLogger.shared.logWebViewAction("Showing search progress view")
                        }
                } else if let record = selectedRecord ?? records.first {
                    VStack(spacing: 0) {
                        // Search Parameters Display
                        SearchParametersHeaderView()
                        
                        // Search Results
                        WebView(html: record.htmlSummary)
                            .id(record.id) // force reload when switching records
                    }
                    .navigationTitle(record.query)
                    .onAppear {
                        DebugLogger.shared.logWebViewAction("Displaying WebView for record: \(record.query)")
                        DebugLogger.shared.logWebViewAction("HTML content length: \(record.htmlSummary.count)")
                    }
                } else {
                    ContentPlaceholderView()
                        .onAppear {
                            DebugLogger.shared.logWebViewAction("Showing placeholder view - no records available")
                        }
                }
            }
            .overlay(alignment: .bottom) {
                // SerpAPI Account Status at bottom of main view
                if !accountInfo.isEmpty || isLoadingAccountInfo {
                    VStack(spacing: 4) {
                        Divider()
                        
                        if isLoadingAccountInfo {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading account info...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if !accountInfo.isEmpty {
                            Text(accountInfo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
        .onAppear {
            DebugLogger.shared.logUserInterfaceReady()
            DebugLogger.shared.logSearchViewModelReady()
            
            viewModel.inject(modelContext: modelContext)

            // Menübefehle abonnieren
            NotificationCenter.default.addObserver(forName: .focusSearchField, object: nil, queue: .main) { _ in
                isSearchFieldFocused = true
            }
            NotificationCenter.default.addObserver(forName: .triggerManualSearch, object: nil, queue: .main) { _ in
                Task { await runSearch() }
            }
            
            // Load SerpAPI account info
            Task {
                await loadAccountInfo()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .focusSearchField, object: nil)
            NotificationCenter.default.removeObserver(self, name: .triggerManualSearch, object: nil)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Cancel any running search when app goes inactive/background
            if newPhase != .active {
                viewModel.cancelCurrentSearch()
            }
        }
        .alert(item: $viewModel.activeError) { err in
            Alert(title: Text("Fehler"), message: Text(err.message), dismissButton: .default(Text("OK")))
        }
    }

    private func runSearch() async {
        DebugLogger.shared.logSearchInitiated(query: searchText)
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DebugLogger.shared.logSearchStateChange("Empty search text - focusing search field")
            // Setze den Fokus ins Suchfeld, falls leer
            isSearchFieldFocused = true
            return
        }
        
        DebugLogger.shared.logSearchStart(query: trimmed)
        DebugLogger.shared.logSearchStateChange("Starting search for: '\(trimmed)'")
        
        do {
            let record = try await viewModel.runSearch(query: trimmed)
            DebugLogger.shared.logSearchStateChange("Search completed successfully")
            selectedRecord = record
            searchText = ""
        } catch is CancellationError {
            DebugLogger.shared.logSearchStateChange("Search cancelled by user")
            // User cancelled; no alert
        } catch {
            DebugLogger.shared.logSearchError(query: trimmed, error: error)
            DebugLogger.shared.logSearchStateChange("Search failed with error: \(error.localizedDescription)")
            // Error is already surfaced via activeError
        }
    }

    private func rerenderSelectedRecord() async {
        guard let record = selectedRecord else { return }
        await viewModel.rerenderHTML(for: record)
    }

    private func deleteRecords(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
    
    
    private func deleteSelectedRecord(_ record: SearchRecord) {
        withAnimation {
            modelContext.delete(record)
            if selectedRecord?.id == record.id {
                selectedRecord = nil
            }
        }
    }
    
    private func loadAccountInfo() async {
        guard !serpKey.isEmpty else {
            accountInfo = ""
            return
        }
        
        isLoadingAccountInfo = true
        DebugLogger.shared.logWebViewAction("Loading SerpAPI account info...")
        
        do {
            let serpClient = SerpAPIClient(apiKeyProvider: { serpKey })
            let info = try await serpClient.getAccountInfo()
            
            DebugLogger.shared.logWebViewAction("Account info loaded: \(info)")
            
            if let remaining = info.credits_remaining {
                accountInfo = "✅ SerpAPI OK - \(remaining) searches available"
            } else {
                accountInfo = "✅ SerpAPI OK"
            }
        } catch {
            DebugLogger.shared.logWebViewAction("Account info error: \(error)")
            
            // Vereinfachte Fehlermeldung
            if let serpError = error as? SerpAPIClient.SerpError {
                switch serpError {
                case .missingAPIKey:
                    accountInfo = "❌ SerpAPI: API key missing"
                case .http(let code):
                    accountInfo = "❌ SerpAPI: HTTP error \(code)"
                case .network(let message):
                    accountInfo = "❌ SerpAPI: \(message)"
                case .badURL:
                    accountInfo = "❌ SerpAPI: Invalid URL"
                case .decoding:
                    accountInfo = "❌ SerpAPI: Data parsing error"
                case .empty:
                    accountInfo = "❌ SerpAPI: No results returned"
                }
            } else {
                accountInfo = "❌ SerpAPI: \(error.localizedDescription)"
            }
        }
        
        isLoadingAccountInfo = false
    }
    
    // MARK: - Helper Functions
    
    private func hasSearchParameters(_ record: SearchRecord) -> Bool {
        return !record.language.isEmpty || 
               !record.region.isEmpty || 
               !record.searchType.isEmpty || 
               !record.timeRange.isEmpty || 
               record.numberOfResults != 20
    }
}

// MARK: - ParameterTag View

private struct ParameterTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

private struct ContentPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Noch keine Suche durchgeführt")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Geben Sie einen Suchbegriff ein und klicken Sie auf Suchen.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Parameters Header View
struct SearchParametersHeaderView: View {
    @AppStorage("settings.serp.hl") private var serpLanguage: String = ""
    @AppStorage("settings.serp.gl") private var serpRegion: String = ""
    @AppStorage("settings.serp.num") private var serpCount: Int = 20
    @AppStorage("settings.serp.location") private var serpLocation: String = ""
    @AppStorage("settings.serp.safe") private var serpSafe: String = ""
    @AppStorage("settings.serp.tbm") private var serpTbm: String = ""
    @AppStorage("settings.serp.as_qdr") private var serpAsQdr: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Search Parameters")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                // Language - immer anzeigen
                ParameterDisplayItem(
                    label: "Language",
                    value: serpLanguage.isEmpty ? "Any" : getLanguageDisplayName(serpLanguage),
                    color: .blue
                )
                
                // Region - immer anzeigen
                ParameterDisplayItem(
                    label: "Region",
                    value: serpRegion.isEmpty ? "Any" : getRegionDisplayName(serpRegion),
                    color: .green
                )
                
                // Results - immer anzeigen
                ParameterDisplayItem(
                    label: "Results",
                    value: "\(serpCount)",
                    color: .red
                )
                
                // Location - immer anzeigen
                ParameterDisplayItem(
                    label: "Location",
                    value: serpLocation.isEmpty ? "Any" : serpLocation,
                    color: .orange
                )
                
                // Safe Search - immer anzeigen
                ParameterDisplayItem(
                    label: "Safe Search",
                    value: serpSafe.isEmpty ? "Any" : getSafeSearchDisplayName(serpSafe),
                    color: .purple
                )
                
                // Search Type - immer anzeigen
                ParameterDisplayItem(
                    label: "Search Type",
                    value: serpTbm.isEmpty ? "All" : getSearchTypeDisplayName(serpTbm),
                    color: .cyan
                )
                
                // Time Range - immer anzeigen
                ParameterDisplayItem(
                    label: "Time Range",
                    value: serpAsQdr.isEmpty ? "Any Time" : getTimeRangeDisplayName(serpAsQdr),
                    color: .indigo
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        switch code {
        case "de": return "Deutsch"
        case "en": return "English"
        case "fr": return "Français"
        case "es": return "Español"
        case "it": return "Italiano"
        case "pt": return "Português"
        case "ru": return "Русский"
        case "ja": return "日本語"
        case "ko": return "한국어"
        case "zh": return "中文"
        default: return code.uppercased()
        }
    }
    
    private func getRegionDisplayName(_ code: String) -> String {
        switch code {
        case "de": return "Deutschland"
        case "us": return "United States"
        case "gb": return "United Kingdom"
        case "fr": return "France"
        case "es": return "Spain"
        case "it": return "Italy"
        case "pt": return "Portugal"
        case "ru": return "Russia"
        case "jp": return "Japan"
        case "kr": return "South Korea"
        case "cn": return "China"
        default: return code.uppercased()
        }
    }
    
    private func getSafeSearchDisplayName(_ code: String) -> String {
        switch code {
        case "active": return "Active"
        case "off": return "Off"
        case "moderate": return "Moderate"
        default: return code.capitalized
        }
    }
    
    private func getSearchTypeDisplayName(_ code: String) -> String {
        switch code {
        case "isch": return "Images"
        case "nws": return "News"
        case "vid": return "Videos"
        case "shop": return "Shopping"
        case "bks": return "Books"
        case "fin": return "Finance"
        default: return code.uppercased()
        }
    }
    
    private func getTimeRangeDisplayName(_ code: String) -> String {
        switch code {
        case "d": return "Past 24 hours"
        case "w": return "Past week"
        case "m": return "Past month"
        case "y": return "Past year"
        case "h": return "Past hour"
        default: return code.uppercased()
        }
    }
}

// MARK: - Parameter Display Item
struct ParameterDisplayItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SearchRecord.self, SearchResult.self], inMemory: true)
}
