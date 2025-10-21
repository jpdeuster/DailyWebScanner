import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ManualSearchRecord.query, order: .forward) private var searchRecords: [ManualSearchRecord]
    @State private var searchText: String = ""
    @State private var selectedSearchRecord: ManualSearchRecord?
    @State private var filterText: String = ""
    // Search parameters using @AppStorage
    @AppStorage("searchLanguage") var language: String = ""
    @AppStorage("searchRegion") var region: String = ""
    @AppStorage("searchLocation") var location: String = ""
    @AppStorage("searchSafeSearch") var safeSearch: String = "off"
    @AppStorage("searchType") var searchType: String = ""
    @AppStorage("searchTimeRange") var timeRange: String = ""
    @AppStorage("searchDateRange") var dateRange: String = ""
    
    // Computed property for filtered manual search records (alphabetically sorted)
    private var filteredSearchRecords: [ManualSearchRecord] {
        let records = if filterText.isEmpty {
            searchRecords
        } else {
            searchRecords.filter { record in
                record.query.localizedCaseInsensitiveContains(filterText) ||
                record.language.localizedCaseInsensitiveContains(filterText) ||
                record.region.localizedCaseInsensitiveContains(filterText) ||
                record.location.localizedCaseInsensitiveContains(filterText)
            }
        }
        return records.sorted { $0.query.localizedCaseInsensitiveCompare($1.query) == .orderedAscending }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                
                // Search Parameters Configuration
                VStack(spacing: 12) {
                HStack {
                        Image(systemName: "gear")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Search Parameters")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    // Language and Region Row
                    HStack(spacing: 8) {
                        // Language Picker
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Language", selection: $language) {
                                ForEach(LanguageHelper.languages, id: \.code) { language in
                                    Text(language.name).tag(language.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        // Region Picker
                        HStack(spacing: 4) {
                            Image(systemName: "map")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Region", selection: $region) {
                                ForEach(LanguageHelper.countries, id: \.code) { country in
                                    Text(country.name).tag(country.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        Spacer()
                    }
                    
                    // Safe Search and Type Row
                    HStack(spacing: 8) {
                        // Safe Search Picker
                        HStack(spacing: 4) {
                            Image(systemName: "shield")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Safe", selection: $safeSearch) {
                                Text("Off").tag("off")
                                Text("Active").tag("active")
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        // Search Type Picker
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Type", selection: $searchType) {
                                Text("All").tag("")
                                Text("News").tag("nws")
                                Text("Images").tag("isch")
                                Text("Videos").tag("vid")
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        Spacer()
                    }
                    
                        // Time Range and Location Row
                        HStack(spacing: 8) {
                            // Time Range Picker
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Picker("Time", selection: $timeRange) {
                                    Text("Any Time").tag("")
                                    Text("Past Hour").tag("qdr:h")
                                    Text("Past Day").tag("qdr:d")
                                    Text("Past Week").tag("qdr:w")
                                    Text("Past Month").tag("qdr:m")
                                    Text("Past Year").tag("qdr:y")
                                }
                                .pickerStyle(.menu)
                                .font(.caption2)
                            }
                            
                            // Location Field for City/Region
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                TextField("City (e.g., Berlin, New York)", text: $location)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption2)
                            }
                            
                            Spacer()
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 0.5)
                        )
                )
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Manual Search")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                List(selection: $selectedSearchRecord) {
                    ForEach(filteredSearchRecords) { record in
                        NavigationLink(value: record) {
                            SearchQueryRow(record: record) {
                                deleteSearchRecord(record)
                            }
                        }
                        .onChange(of: selectedSearchRecord) { oldValue, newValue in
                            if let newRecord = newValue {
                                DebugLogger.shared.logWebViewAction("🖱️ ContentView: Selection changed to SearchRecord '\(newRecord.query)' (ID: \(newRecord.id))")
                            }
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
            }
            .frame(minWidth: 300)
        } detail: {
            if let searchRecord = selectedSearchRecord {
                VStack(spacing: 16) {
                    // Beautiful Search Query Header (same as Automated Search)
                    SearchQueryHeaderView(searchRecord: searchRecord)
                    
                    // Search Results (non-clickable)
                    if !searchRecord.results.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Search Results (\(searchRecord.results.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            // Results List (non-clickable)
                            List(searchRecord.results.prefix(10)) { result in
                                SearchResultRowView(result: result)
                            }
                            .listStyle(.plain)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No Results Yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("This search returned no results.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
                .onAppear {
                    DebugLogger.shared.logWebViewAction("🔍 DEBUG: Detail View Active")
                    DebugLogger.shared.logWebViewAction("📱 ContentView: Detail view appeared for SearchRecord '\(searchRecord.query)' (ID: \(searchRecord.id))")
                    DebugLogger.shared.logWebViewAction("📊 ContentView: SearchRecord has \(searchRecord.results.count) results")
                }
                } else {
                VStack(spacing: 20) {
                    // Navigation Buttons (top-right)
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showAutomatedSearchWindow()
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                Text("Automated Search")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Open Automated Search (⌘A)")
                        .keyboardShortcut("a", modifiers: .command)
                        
                        Button(action: {
                            showArticlesWindow()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.caption)
                                Text("Show Saved Articles")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Open Articles List (⌘L)")
                        .keyboardShortcut("l", modifiers: .command)
                    }
                    .padding(.horizontal)
                    
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
            
            // Debug: Show automated search status
            let automatedRecords = try? modelContext.fetch(FetchDescriptor<AutomatedSearchRecord>())
            if let automatedRecords = automatedRecords {
                let activeAutomated = automatedRecords.filter { $0.isEnabled }
                DebugLogger.shared.logWebViewAction("🤖 AUTOMATED SEARCHES STATUS:")
                DebugLogger.shared.logWebViewAction("   Total automated searches: \(automatedRecords.count)")
                DebugLogger.shared.logWebViewAction("   Active automated searches: \(activeAutomated.count)")
                
                if !activeAutomated.isEmpty {
                    DebugLogger.shared.logWebViewAction("   Active searches:")
                    for record in activeAutomated {
                        DebugLogger.shared.logWebViewAction("     - '\(record.query)' (scheduled: \(record.scheduledTime))")
                    }
                } else {
                    DebugLogger.shared.logWebViewAction("   No active automated searches")
                }
            }
        }
    }
    
    private func deleteSearchRecord(_ record: ManualSearchRecord) {
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
                    let viewModel = SearchViewModel()
                    viewModel.modelContext = modelContext
                    let searchResults = try await viewModel.runSearchForResults(
                        query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                        language: language,
                        region: region,
                        location: location,
                        safe: safeSearch,
                        tbm: searchType,
                        tbs: "",
                        as_qdr: timeRange,
                        nfpr: "",
                        filter: ""
                    )
                    
                    // Create ManualSearchRecord
                    let record = ManualSearchRecord(
                        query: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                        language: language,
                        region: region,
                        location: location,
                        safe: safeSearch,
                        tbm: searchType,
                        tbs: "",
                        as_qdr: timeRange,
                        nfpr: "",
                        filter: ""
                    )
                    record.results = searchResults
                    
                    // Convert SearchResults to LinkRecords for the article list
                    for (_, searchResult) in searchResults.enumerated() {
                        // Fetch HTML content immediately to avoid network requests later
                        let htmlContent = await fetchHTMLFromURL(searchResult.link)
                        
                        // Extract ALL content from HTML for fast access
                        DebugLogger.shared.logWebViewAction("🔄 ContentView: Starting content extraction for '\(searchResult.title)'")
                        let extractor = HTMLContentExtractor()
                        let extractedContent = await extractor.extractContent(from: htmlContent, baseURL: searchResult.link)
                        
                        DebugLogger.shared.logWebViewAction("📊 ContentView: Extracted content - Text: \(extractedContent.mainText.count) chars, Links: \(extractedContent.links.count), Videos: \(extractedContent.videos.count), Images: \(extractedContent.images.count)")
                        
        // Save links as JSON (skip for now - need to make ExtractedLink Encodable)
        _ = "" // (try? JSONEncoder().encode(extractedContent.links)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        
        // Save videos as JSON (references only) - skip for now
        _ = "" // (try? JSONEncoder().encode(extractedContent.videos)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        
        // Save metadata as JSON - skip for now
        _ = "" // (try? JSONEncoder().encode(extractedContent.metadata)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        
                        let linkRecord = LinkRecord(
                            searchRecordId: record.id,
                            originalUrl: searchResult.link,
                            title: searchResult.title,
                            content: searchResult.snippet,
                            html: htmlContent,  // ← HTML wird sofort geladen!
                            css: "",
                            extractedText: extractedContent.mainText,  // ← Extracted text wird gespeichert!
                            fetchedAt: Date(),
                            articleDescription: searchResult.snippet,
                            wordCount: searchResult.snippet.split(separator: " ").count,
                            readingTime: max(1, searchResult.snippet.split(separator: " ").count / 200)
                        )
                        
                        // Download and save images to ImageRecord relationships
                        for image in extractedContent.images {
                            DebugLogger.shared.logWebViewAction("🖼️ ContentView: Downloading image: \(image.url)")
                            
                            // Download image data
                            var localPath: String?
                            var fileSize: Int = 0
                            
                            if let imageURL = URL(string: image.url) {
                                do {
                                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                                    fileSize = data.count
                                    
                                    // Save to local file system
                                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                    let imagesPath = documentsPath.appendingPathComponent("DailyWebScanner/Images")
                                    try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
                                    
                                    let fileName = "\(linkRecord.id.uuidString)_\(UUID().uuidString).jpg"
                                    let fileURL = imagesPath.appendingPathComponent(fileName)
                                    try data.write(to: fileURL)
                                    localPath = fileURL.path
                                    
                                    DebugLogger.shared.logWebViewAction("💾 ContentView: Image saved to \(fileURL.path) (\(fileSize) bytes)")
                                } catch {
                                    DebugLogger.shared.logWebViewAction("❌ ContentView: Failed to download image \(image.url): \(error.localizedDescription)")
                                }
                            }
                            
                            let imageRecord = ImageRecord(
                                linkRecordId: linkRecord.id,
                                originalUrl: image.url,
                                localPath: localPath,
                                altText: image.alt,
                                width: image.width,
                                height: image.height,
                                fileSize: fileSize,
                                downloadedAt: Date()
                            )
                            linkRecord.images.append(imageRecord)
                        }
                        
                        DebugLogger.shared.logWebViewAction("💾 ContentView: Saved complete content to database for '\(searchResult.title)'")
                        modelContext.insert(linkRecord)
                        DebugLogger.shared.logWebViewAction("Created LinkRecord with HTML: \(searchResult.title) (HTML length: \(htmlContent.count))")
                    }
                
                await MainActor.run {
                        modelContext.insert(record)
                        selectedSearchRecord = record
                        searchText = "" // Clear search text after successful search
                        DebugLogger.shared.logWebViewAction("Manual search completed - searchRecords count: \(searchRecords.count)")
                        DebugLogger.shared.logWebViewAction("Created \(searchResults.count) LinkRecords for article list")
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
    
    private func createLinkRecord(from result: SearchResult, searchRecord: ManualSearchRecord) -> LinkRecord {
        return LinkRecord(
            searchRecordId: searchRecord.id,
            originalUrl: result.link,
            title: result.title,
            content: result.snippet,
            html: "", // Will be fetched by EnhancedArticleView
            css: "",
            fetchedAt: Date(),
            articleDescription: result.snippet,
            wordCount: result.snippet.split(separator: " ").count,
            readingTime: max(1, result.snippet.split(separator: " ").count / 200)
        )
    }
}

struct SearchQueryRow: View {
    let record: ManualSearchRecord
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
            
            Text(record.timestamp, format: .dateTime)
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
                    if !record.safe.isEmpty && record.safe != "off" {
                    ParameterTag(label: "Safe", value: record.safe)
                }
                if !record.tbm.isEmpty {
                    ParameterTag(label: "Type", value: record.tbm)
                }
                if !record.as_qdr.isEmpty {
                    ParameterTag(label: "Time", value: record.as_qdr)
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
    let color: Color
    
    init(label: String, value: String, color: Color = .blue) {
        self.label = label
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label): \(value)")
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

extension ContentView {
    private func showAutomatedSearchWindow() {
        let automatedSearchWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        automatedSearchWindow.title = "Automated Search"
        automatedSearchWindow.center()
        automatedSearchWindow.contentView = NSHostingView(rootView: SearchListView()
            .environment(\.modelContext, modelContext))
        
        automatedSearchWindow.isReleasedWhenClosed = false
        automatedSearchWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showArticlesWindow() {
        let articlesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        articlesWindow.title = "Articles"
        articlesWindow.center()
        articlesWindow.contentView = NSHostingView(rootView: SearchQueriesView()
            .environment(\.modelContext, modelContext))
        
        articlesWindow.isReleasedWhenClosed = false
        articlesWindow.makeKeyAndOrderFront(nil)
    }
    
    private func fetchHTMLFromURL(_ urlString: String) async -> String {
        guard let url = URL(string: urlString) else {
            DebugLogger.shared.logWebViewAction("❌ ContentView: Invalid URL: \(urlString)")
            return ""
        }
        
        do {
            DebugLogger.shared.logWebViewAction("🌐 ContentView: Fetching HTML from \(urlString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                DebugLogger.shared.logWebViewAction("📡 ContentView: HTTP Status: \(httpResponse.statusCode)")
            }
            
            let html = String(data: data, encoding: .utf8) ?? ""
            DebugLogger.shared.logWebViewAction("📄 ContentView: Fetched HTML length: \(html.count) characters")
            return html
        } catch {
            DebugLogger.shared.logWebViewAction("❌ ContentView: Failed to fetch HTML - \(error.localizedDescription)")
            return ""
        }
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