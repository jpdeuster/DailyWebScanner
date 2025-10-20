import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var searchRecords: [SearchRecord]
    @State private var searchText: String = ""
    @State private var selectedSearchRecord: SearchRecord?
    @State private var filterText: String = ""
    @State private var searchParameters = SearchParametersView()
    
    // Computed property for filtered search records
    private var filteredSearchRecords: [SearchRecord] {
        if filterText.isEmpty {
            return searchRecords
        } else {
            return searchRecords.filter { record in
                record.query.localizedCaseInsensitiveContains(filterText) ||
                record.language.localizedCaseInsensitiveContains(filterText) ||
                record.region.localizedCaseInsensitiveContains(filterText) ||
                record.location.localizedCaseInsensitiveContains(filterText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header with Articles Button
                HStack(spacing: 12) {
                    Button(action: {
                        showSearchQueriesWindow()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text("Show Saved Articles")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Open Articles List (⌘⇧S)")
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                
                // Manual Search Field
                HStack {
                    TextField("Enter search query...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            performSearch()
                        }
                    
                    Button(action: {
                        performSearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                
                // Search Records List
                List(selection: $selectedSearchRecord) {
                    ForEach(filteredSearchRecords) { record in
                        NavigationLink(value: record) {
                            SearchQueryRow(record: record) {
                                deleteSearchRecord(record)
                            }
                        }
                        .onTapGesture {
                            DebugLogger.shared.logWebViewAction("🖱️ ContentView: NavigationLink tapped for SearchRecord '\(record.query)' (ID: \(record.id))")
                            selectedSearchRecord = record
                            DebugLogger.shared.logWebViewAction("🖱️ ContentView: selectedSearchRecord set to '\(record.query)'")
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Query: \(searchRecord.query)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Results: \(searchRecord.results.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    if !searchRecord.results.isEmpty {
                        List(searchRecord.results) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                if !result.snippet.isEmpty {
                                    Text(result.snippet)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                
                                Button(action: {
                                    if let url = URL(string: result.link) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Text(result.link)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                    } else {
                        Text("No results available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
                .onAppear {
                    DebugLogger.shared.logWebViewAction("🔍 DEBUG: Detail View Active")
                    DebugLogger.shared.logWebViewAction("📱 ContentView: Detail view appeared for SearchRecord '\(searchRecord.query)' (ID: \(searchRecord.id))")
                    DebugLogger.shared.logWebViewAction("📊 ContentView: SearchRecord has \(searchRecord.results.count) results")
                    DebugLogger.shared.logWebViewAction("📊 ContentView: SearchRecord has \(searchRecord.linkRecords.count) link records")
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to DailyWebScanner")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Select a search from the sidebar to view results")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 16) {
                        InfoCard(
                            icon: "clock.arrow.circlepath",
                            title: "Search History",
                            description: "View and manage your past searches"
                        )
                        
                        InfoCard(
                            icon: "list.bullet",
                            title: "Detailed Results",
                            description: "See comprehensive search results with AI summaries"
                        )
                        
                        InfoCard(
                            icon: "link",
                            title: "Article Links",
                            description: "Access saved articles and extracted content"
                        )
                    }
                }
                .padding(40)
            }
        }
        .onAppear {
            loadAccountInfo()
            DebugLogger.shared.logWebViewAction("ContentView appeared - searchRecords count: \(searchRecords.count)")
        }
    }
    
    private func deleteSearchRecord(_ record: SearchRecord) {
        DebugLogger.shared.logWebViewAction("🗑️ ContentView: Starting delete for SearchRecord '\(record.query)' (ID: \(record.id))")
        
        // Clear selection if deleted record was selected
        if selectedSearchRecord?.id == record.id {
            DebugLogger.shared.logWebViewAction("🗑️ ContentView: Clearing selectedSearchRecord - deleted record was active")
            selectedSearchRecord = nil
        }
        
        modelContext.delete(record)
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("✅ ContentView: SearchRecord deleted successfully: '\(record.query)'")
        } catch {
            DebugLogger.shared.logWebViewAction("❌ ContentView: Failed to delete SearchRecord: \(error.localizedDescription)")
        }
    }
    
    private func performSearch() {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                do {
                    let params = searchParameters.getParameters()
                    let viewModel = SearchViewModel()
                    viewModel.modelContext = modelContext
                    let record = try await viewModel.runSearch(
                        query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                        language: params.language,
                        region: params.region,
                        location: params.location,
                        safe: params.safe,
                        tbm: params.tbm,
                        tbs: params.tbs,
                        as_qdr: params.as_qdr,
                        nfpr: params.nfpr,
                        filter: params.filter
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
    
    private func loadAccountInfo() {
        // Load account information if needed
    }
    
    private func showSearchQueriesWindow() {
        let searchQueriesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        searchQueriesWindow.title = "Articles"
        searchQueriesWindow.center()
        searchQueriesWindow.contentView = NSHostingView(rootView: SearchQueriesView()
            .environment(\.modelContext, modelContext))
        
        // Configure window to not close the app when closed
        searchQueriesWindow.isReleasedWhenClosed = false
        searchQueriesWindow.makeKeyAndOrderFront(nil)
    }
}

struct SearchQueryRow: View {
    let record: SearchRecord
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "magnifyingglass.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.query)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(record.createdAt, format: .dateTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Search Parameters as Tags
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
                    if !record.safeSearch.isEmpty && record.safeSearch != "off" {
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
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Delete search")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SearchQueryDetailView: View {
    let searchRecord: SearchRecord
    @Environment(\.modelContext) private var modelContext
    
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
                    SearchParametersHeaderView(searchRecord: searchRecord)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                
                // Search Results
                if !searchRecord.results.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Search Results (\(searchRecord.results.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        List {
                            ForEach(searchRecord.results) { result in
                                SearchResultRow(result: result)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            deleteSearchResult(result, from: searchRecord)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if !searchRecord.htmlSummary.isEmpty {
                    WebView(html: searchRecord.htmlSummary)
                        .frame(minHeight: 400)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 8) {
                            Text("No Search Results Found")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Your search for \"\(searchRecord.query)\" did not return any results.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 12) {
                            Text("⚠️ Your search criteria are very restrictive")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text("Try adjusting your search parameters:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.orange)
                                    Text("Remove time restrictions (Date Range)")
                                        .font(.body)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.orange)
                                    Text("Remove location restrictions")
                                        .font(.body)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.orange)
                                    Text("Change content type to 'All'")
                                        .font(.body)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.orange)
                                    Text("Use the 'Quick Test' button for less restrictive settings")
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(40)
                }
            }
            .padding()
        }
        .navigationTitle("Search Results")
    }
    
    private func deleteSearchResult(_ result: SearchResult, from searchRecord: SearchRecord) {
        // Remove from the relationship
        if let index = searchRecord.results.firstIndex(where: { $0.id == result.id }) {
            searchRecord.results.remove(at: index)
        }
        
        // Delete from model context
        modelContext.delete(result)
        
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("SearchResult deleted: \(result.title)")
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to delete SearchResult: \(error.localizedDescription)")
        }
    }
}

struct SearchParametersHeaderView: View {
    let searchRecord: SearchRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Parameters")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ParameterDisplayItem(
                    icon: "globe",
                    label: "Language",
                    value: searchRecord.language.isEmpty ? "Any" : searchRecord.language
                )
                
                ParameterDisplayItem(
                    icon: "map",
                    label: "Region",
                    value: searchRecord.region.isEmpty ? "Any" : searchRecord.region
                )
                
                ParameterDisplayItem(
                    icon: "location",
                    label: "Location",
                    value: searchRecord.location.isEmpty ? "Any" : searchRecord.location
                )
                
                ParameterDisplayItem(
                    icon: "shield",
                    label: "Safe Search",
                    value: searchRecord.safeSearch.isEmpty ? "Off" : searchRecord.safeSearch
                )
                
                ParameterDisplayItem(
                    icon: "magnifyingglass",
                    label: "Type",
                    value: searchRecord.searchType.isEmpty ? "All" : searchRecord.searchType
                )
                
                ParameterDisplayItem(
                    icon: "clock",
                    label: "Date Range",
                    value: searchRecord.timeRange.isEmpty ? "Any Time" : searchRecord.timeRange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ParameterDisplayItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if !result.snippet.isEmpty {
                Text(result.snippet)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Button(action: {
                    if let url = URL(string: result.link) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text(result.link)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .underline()
                }
                .buttonStyle(.plain)
                .help("Open in browser")
                
                Spacer()
                
                if !result.summary.isEmpty {
                    Text("AI Summary Available")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
    }
}

struct ParameterTag: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label): \(value)")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

extension ContentView {
    private func deleteSearchResult(_ result: SearchResult, from searchRecord: SearchRecord) {
        // Remove from the relationship
        if let index = searchRecord.results.firstIndex(where: { $0.id == result.id }) {
            searchRecord.results.remove(at: index)
        }
        
        // Delete from model context
        modelContext.delete(result)
        
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("SearchResult deleted: \(result.title)")
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to delete SearchResult: \(error.localizedDescription)")
        }
    }
}