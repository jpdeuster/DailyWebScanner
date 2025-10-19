import SwiftUI
import SwiftData

struct NewContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0 // 0 = Articles, 1 = Searches
    
    // SerpAPI Account Info
    @AppStorage("serpAPIKey") private var serpKey: String = ""
    @State private var accountInfo = ""
    @State private var isLoadingAccountInfo = false
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    TextField("Enter search query...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Task {
                            do {
                                _ = try await viewModel.runSearch(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                            } catch {
                                DebugLogger.shared.logWebViewAction("Search failed: \(error)")
                            }
                        }
                            }
                        }
                    
                    Button(action: {
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Task {
                                do {
                                    _ = try await viewModel.runSearch(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                                } catch {
                                    DebugLogger.shared.logWebViewAction("Search failed: \(error)")
                                }
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSearching || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                
                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Text("Articles").tag(0)
                    Text("Searches").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // Articles Tab
                    LinkListView()
                } else {
                    // Searches Tab
                    SearchHistoryView()
                }
                
                // Account Info
                if !accountInfo.isEmpty {
                    VStack {
                        Divider()
                        Text(accountInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Articles" : "Search History")
            .navigationSplitViewColumnWidth(min: 300, ideal: 400)
        } detail: {
            if selectedTab == 0 {
                // Articles Tab - Show LinkListView's detail view
                LinkListView()
            } else {
                // Searches Tab - Show search results
                SearchHistoryView()
            }
        }
        .onAppear {
            loadAccountInfo()
        }
    }
    
    private func loadAccountInfo() {
        guard !serpKey.isEmpty else {
            accountInfo = "❌ SerpAPI: No API key configured"
            return
        }
        
        isLoadingAccountInfo = true
        
        Task {
            do {
                let accountInfo = try await SerpAPIClient(apiKeyProvider: { KeychainHelper.get(.serpAPIKey) }).getAccountInfo()
                await MainActor.run {
                    if let credits = accountInfo.credits_remaining {
                        self.accountInfo = "✅ SerpAPI OK - \(credits) searches available"
                    } else {
                        self.accountInfo = "✅ SerpAPI OK"
                    }
                    self.isLoadingAccountInfo = false
                }
            } catch {
                await MainActor.run {
                    if let serpError = error as? SerpAPIClient.SerpError {
                        switch serpError {
                        case .missingAPIKey:
                            self.accountInfo = "❌ SerpAPI: No API key configured"
                        case .http(let statusCode):
                            self.accountInfo = "❌ SerpAPI: HTTP error \(statusCode)"
                        case .network(let error):
                            self.accountInfo = "❌ SerpAPI: Network error - \(error)"
                        case .badURL:
                            self.accountInfo = "❌ SerpAPI: Invalid URL"
                        case .decoding:
                            self.accountInfo = "❌ SerpAPI: Data parsing error"
                        case .empty:
                            self.accountInfo = "❌ SerpAPI: No data received"
                        }
                    } else {
                        self.accountInfo = "❌ SerpAPI: \(error.localizedDescription)"
                    }
                    self.isLoadingAccountInfo = false
                }
            }
        }
    }
}

struct SearchHistoryView: View {
    @Query(sort: \SearchRecord.createdAt, order: .reverse)
    private var searchRecords: [SearchRecord]
    
    @State private var selectedRecord: SearchRecord?
    
    var body: some View {
        NavigationSplitView {
            if !searchRecords.isEmpty {
                List(searchRecords, selection: $selectedRecord) { record in
                    NavigationLink(value: record) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.query)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Search Parameters als Tags
                            HStack {
                                ParameterTag(label: "Lang", value: record.language.isEmpty ? "Any" : record.language)
                                ParameterTag(label: "Region", value: record.region.isEmpty ? "Any" : record.region)
                                ParameterTag(label: "Type", value: record.searchType.isEmpty ? "All" : record.searchType)
                                ParameterTag(label: "Time", value: record.timeRange.isEmpty ? "Any Time" : record.timeRange)
                                ParameterTag(label: "Results", value: "\(record.numberOfResults)")
                            }
                            
                            // Delete button
                            HStack {
                                Spacer()
                                Button(action: {
                                    deleteSelectedRecord(record)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .listStyle(.sidebar)
            } else {
                VStack {
                    Spacer()
                    Text("No search history")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        } detail: {
            if let selectedRecord = selectedRecord {
                VStack(alignment: .leading, spacing: 20) {
                    // Search Parameters Header
                    SearchParametersHeaderView()
                    
                    // WebView mit Suchergebnissen
                    WebView(html: selectedRecord.htmlSummary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Link Content falls vorhanden
                    if selectedRecord.hasLinkContents, let linkContents = decodeLinkContents(from: selectedRecord.linkContents) {
                        LinkContentView(linkContents: linkContents)
                    }
                }
                .navigationTitle(selectedRecord.query)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Select a search to view results")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose a search from the sidebar to see its results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func deleteSelectedRecord(_ record: SearchRecord) {
        // Implementation for deleting search records
    }
}

// Helper functions and views from original ContentView
private func decodeLinkContents(from jsonString: String) -> [LinkContent]? {
    guard !jsonString.isEmpty,
          let data = jsonString.data(using: .utf8) else {
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([LinkContent].self, from: data)
    } catch {
        DebugLogger.shared.logWebViewAction("Failed to decode link contents: \(error)")
        return nil
    }
}



#Preview {
    NewContentView()
        .modelContainer(for: [SearchRecord.self, LinkRecord.self])
}
