import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \SearchRecord.createdAt, order: .reverse)
    private var searchRecords: [SearchRecord]

    @State private var selectedSearchRecord: SearchRecord?
    @StateObject private var viewModel = SearchViewModel()

    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchParameters = SearchParametersView()
    
    @AppStorage("serpAPIKey") private var serpKey: String = ""
    @State private var accountInfo = ""
    @State private var isLoadingAccountInfo = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search Parameters
                SearchParametersView()
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                
                // Quick search field at top of sidebar
                HStack {
                    TextField("Enter search query...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Task {
                                    do {
                                        let params = searchParameters.getParameters()
                                        let record = try await viewModel.runSearch(
                                            query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                                            language: params.language,
                                            region: params.region,
                                            location: params.location,
                                            safe: params.safe,
                                            tbm: params.tbm,
                                            tbs: params.tbs,
                                            as_qdr: params.as_qdr
                                        )
                                        await MainActor.run {
                                            selectedSearchRecord = record
                                            searchText = "" // Clear search text after successful search
                                            DebugLogger.shared.logWebViewAction("Search completed - searchRecords count: \(searchRecords.count)")
                                        }
                                    } catch {
                                        DebugLogger.shared.logWebViewAction("Search failed: \(error)")
                                    }
                                }
                            }
                        }
                    .focused($isSearchFieldFocused)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                        .onChange(of: isSearchFieldFocused) { _, focused in
                            if focused {
                                DebugLogger.shared.logSearchFieldFocus()
                            }
                        }
                        .onChange(of: searchText) { _, newValue in
                            DebugLogger.shared.logWebViewAction("User entered search text: '\(newValue)'")
                        }
                    
                    Button(action: {
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Task {
                                do {
                                    let params = searchParameters.getParameters()
                                    let record = try await viewModel.runSearch(
                                        query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                                        language: params.language,
                                        region: params.region,
                                        location: params.location,
                                        safe: params.safe,
                                        tbm: params.tbm,
                                        tbs: params.tbs,
                                        as_qdr: params.as_qdr
                                    )
                                    await MainActor.run {
                                        selectedSearchRecord = record
                                        searchText = "" // Clear search text after successful search
                                        DebugLogger.shared.logWebViewAction("Search completed - searchRecords count: \(searchRecords.count)")
                                    }
                                } catch {
                                    DebugLogger.shared.logWebViewAction("Search failed: \(error)")
                                }
                            }
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Search Records List
                List(selection: $selectedSearchRecord) {
                    ForEach(searchRecords) { record in
                        NavigationLink(value: record) {
                            SearchQueryRow(record: record)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteSearchRecord(record)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 300)
        } detail: {
            if let searchRecord = selectedSearchRecord {
                SearchQueryDetailView(searchRecord: searchRecord)
                } else {
                Text("Select a search from the sidebar")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            loadAccountInfo()
            DebugLogger.shared.logWebViewAction("ContentView appeared - searchRecords count: \(searchRecords.count)")
        }
    }
    
    private func deleteSearchRecord(_ record: SearchRecord) {
        modelContext.delete(record)
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("SearchRecord deleted: \(record.query)")
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to delete SearchRecord: \(error.localizedDescription)")
        }
    }
    
    private func loadAccountInfo() {
        guard !serpKey.isEmpty else { return }
        
        isLoadingAccountInfo = true
        
        Task {
            do {
                let client = SerpAPIClient(apiKeyProvider: { serpKey })
                let info = try await client.getAccountInfo()
                
                await MainActor.run {
                    isLoadingAccountInfo = false
                    accountInfo = "Credits remaining: \(info.credits_remaining ?? 0)"
                }
            } catch {
                await MainActor.run {
                    isLoadingAccountInfo = false
                    accountInfo = ""
                }
            }
        }
    }
}

struct SearchQueryRow: View {
    let record: SearchRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.query)
                .font(.headline)
                .lineLimit(2)
            
            Text(record.createdAt, format: .dateTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Search Parameters als Tags
            HStack {
                if !record.language.isEmpty {
                    ParameterTag(label: "Lang", value: record.language)
                }
                if !record.region.isEmpty {
                    ParameterTag(label: "Region", value: record.region)
                }
                if !record.location.isEmpty {
                    ParameterTag(label: "Location", value: record.location)
                }
                if !record.safeSearch.isEmpty {
                    ParameterTag(label: "Safe", value: record.safeSearch)
                }
                if !record.searchType.isEmpty {
                    ParameterTag(label: "Type", value: record.searchType)
                }
                if !record.timeRange.isEmpty {
                    ParameterTag(label: "Time", value: record.timeRange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3) as Color)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3) as Color, lineWidth: 1)
        )
    }
}

struct SearchQueryDetailView: View {
    let searchRecord: SearchRecord
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Search Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(searchRecord.query)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Searched: \(searchRecord.createdAt, format: .dateTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Search Parameters
                    SearchParametersHeaderView()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                
                // Search Results
                if !searchRecord.htmlSummary.isEmpty {
                    WebView(html: searchRecord.htmlSummary)
                        .frame(minHeight: 400)
                } else {
                    Text("No results available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Search Results")
    }
}

struct SearchParametersHeaderView: View {
    @AppStorage("serpLanguage") private var language: String = ""
    @AppStorage("serpRegion") private var region: String = ""
    @AppStorage("serpLocation") private var location: String = ""
    @AppStorage("serpSafe") private var safe: String = ""
    @AppStorage("serpTbm") private var tbm: String = ""
    @AppStorage("serpTbs") private var tbs: String = ""
    @AppStorage("serpAsQdr") private var asQdr: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Parameters")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ParameterDisplayItem(label: "Language", value: language.isEmpty ? "Any" : language)
                ParameterDisplayItem(label: "Region", value: region.isEmpty ? "Any" : region)
                ParameterDisplayItem(label: "Location", value: location.isEmpty ? "Any" : location)
                ParameterDisplayItem(label: "Safe Search", value: safe.isEmpty ? "Off" : safe)
                ParameterDisplayItem(label: "Search Type", value: tbm.isEmpty ? "All" : tbm)
                ParameterDisplayItem(label: "Time Range", value: tbs.isEmpty ? "Any Time" : tbs)
                ParameterDisplayItem(label: "Date Range", value: asQdr.isEmpty ? "Any" : asQdr)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
    }
}

struct ParameterDisplayItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct ParameterTag: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SearchRecord.self, SearchResult.self, LinkRecord.self, ImageRecord.self])
}