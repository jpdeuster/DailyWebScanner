import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ManualSearchRecord.query, order: .forward) private var searchRecords: [ManualSearchRecord]
    @State private var searchText: String = ""
    @State private var selectedSearchRecord: ManualSearchRecord?
    @State private var filterText: String = ""
    @State private var isSearching: Bool = false
    @State private var progressValue: Double? = nil
    @State private var progressText: String = ""
    // Search parameters using @AppStorage
    @AppStorage("searchLanguage") var language: String = ""
    @AppStorage("searchRegion") var region: String = ""
    @AppStorage("searchLocation") var location: String = ""
    @AppStorage("searchSafeSearch") var safeSearch: String = "off"
    @AppStorage("searchType") var searchType: String = ""
    @AppStorage("searchTimeRange") var timeRange: String = ""
    @AppStorage("searchDateRange") var dateRange: String = ""
    // API keys for status bar
    @AppStorage("serpAPIKey") private var serpKey: String = ""
    @AppStorage("openAIKey") private var openAIKey: String = ""
    @State private var isTestingSerpAPI: Bool = false
    @State private var serpAPIStatusText: String = ""
    @State private var serpAPIStatusOK: Bool? = nil
    @State private var openAIStatusOK: Bool? = nil
    @State private var serpCreditsText: String = ""
    @State private var serpPlanText: String = ""
    @State private var hasActiveAutomatedSearches: Bool = true
    
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

                // Suggest automated searches if none active
                if !hasActiveAutomatedSearches {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Would you like to add daily automated searches?")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Button(action: { showAutomatedSearchWindow() }) {
                            Text("Open Automated Search")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.08))
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                
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
                // Status bar (progress)
                if isSearching {
                    Divider()
                    HStack(spacing: 8) {
                        if let value = progressValue {
                            ProgressView(value: value)
                                .frame(width: 160, height: 4)
                        } else {
                            ProgressView()
                                .frame(width: 160, height: 4)
                        }
                        Text(progressText.isEmpty ? "Searching…" : progressText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                // API Status bar (always visible) - two lines
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    // Line 1: SerpAPI
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: serpAPIStatusOK == true ? "checkmark.circle.fill" : (resolveSerpKey().isEmpty ? "questionmark.circle.fill" : "xmark.circle.fill"))
                                .foregroundColor(resolveSerpKey().isEmpty ? .blue : (serpAPIStatusOK == true ? .green : .red))
                                .font(.caption)
                            Text("SerpAPI")
                                .font(.caption)
                                .foregroundColor(.primary)
                            if !serpAPIStatusText.isEmpty {
                                Text(serpAPIStatusText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if !serpPlanText.isEmpty {
                                Text(serpPlanText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if !serpCreditsText.isEmpty {
                                Text(serpCreditsText)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        // Test button removed; testing available in API Settings
                        Spacer()
                    }
                    // Line 2: OpenAI
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: openAIKey.isEmpty ? "questionmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(openAIKey.isEmpty ? .blue : .green)
                                .font(.caption)
                            Text("OpenAI")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text(openAIKey.isEmpty ? "Not configured" : "Configured")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .frame(minWidth: 300)
        } detail: {
            MainDetailView(
                searchRecord: selectedSearchRecord,
                onOpenAutomatedSearch: { showAutomatedSearchWindow() },
                onOpenArticles: { showArticlesWindow() }
            )
        }
        .onAppear {
            loadAccountInfo()
            DebugLogger.shared.logWebViewAction("ContentView appeared - searchRecords count: \(searchRecords.count)")
            // Initialize API status
            openAIStatusOK = openAIKey.isEmpty ? nil : true
            // Sync AppStorage from Keychain if needed
            if let kc = KeychainHelper.get(.serpAPIKey), !kc.isEmpty { serpKey = kc }
            let effectiveKey = resolveSerpKey()
            serpAPIStatusOK = effectiveKey.isEmpty ? nil : true
            if !effectiveKey.isEmpty {
                Task {
                    do {
                        let client = SerpAPIClient(apiKeyProvider: { resolveSerpKey() })
                        let info = try await client.getAccountInfo()
                        await MainActor.run {
                            serpAPIStatusOK = true
                            let plan = (info.plan ?? "").isEmpty ? nil : info.plan
                            let rem = info.credits_remaining
                            let lim = info.credits_limit
                            serpPlanText = plan.map { "Plan: \($0)" } ?? ""
                            if let rem = rem, let lim = lim {
                                serpCreditsText = "Credits: \(rem)/\(lim)"
                            } else if let rem = rem {
                                serpCreditsText = "Credits: \(rem)"
                            } else {
                                serpCreditsText = ""
                            }
                            serpAPIStatusText = "OK"
                        }
                    } catch {
                        await MainActor.run {
                            serpAPIStatusOK = false
                            serpAPIStatusText = error.localizedDescription
                        }
                        // ignore credit fetch errors silently
                    }
                }
            }
            
            // Debug: Show automated search status
            let automatedRecords = try? modelContext.fetch(FetchDescriptor<AutomatedSearchRecord>())
            if let automatedRecords = automatedRecords {
                let activeAutomated = automatedRecords.filter { $0.isEnabled }
                DebugLogger.shared.logWebViewAction("🤖 AUTOMATED SEARCHES STATUS:")
                DebugLogger.shared.logWebViewAction("   Total automated searches: \(automatedRecords.count)")
                DebugLogger.shared.logWebViewAction("   Active automated searches: \(activeAutomated.count)")
                hasActiveAutomatedSearches = !activeAutomated.isEmpty
                
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
    
    private func testSerpAPIStatus() {
        isTestingSerpAPI = true
        serpAPIStatusText = ""
        Task {
            defer { Task { await MainActor.run { isTestingSerpAPI = false } } }
            do {
                let client = SerpAPIClient(apiKeyProvider: { resolveSerpKey() })
                _ = try await client.fetchTopResults(query: "status", count: 1)
                await MainActor.run {
                    serpAPIStatusOK = true
                    serpAPIStatusText = "OK"
                }
            } catch {
                await MainActor.run {
                    serpAPIStatusOK = false
                    serpAPIStatusText = error.localizedDescription
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
                    await MainActor.run {
                        isSearching = true
                        progressValue = nil
                        progressText = "Searching…"
                    }
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
                    let total = searchResults.count
                    await MainActor.run {
                        if total > 0 {
                            progressValue = 0.0
                            progressText = "Extracting content (0/\(total))…"
                        } else {
                            progressValue = nil
                            progressText = "No results"
                        }
                    }
                    
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
                    DebugLogger.shared.logWebViewAction("🧮 ContentView: Will create LinkRecords for \(searchResults.count) results")
                    var createdCount = 0
                    var duplicateCount = 0
                    var failureCount = 0
                    for (idx, searchResult) in searchResults.enumerated() {
                        DebugLogger.shared.logWebViewAction("➡️ ContentView: Processing result \(idx+1)/\(searchResults.count) — title='\(searchResult.title)', url=\(searchResult.link)")
                        // Duplicate check (diagnostic only)
                        do {
                            let url = searchResult.link
                            let dupes = try modelContext.fetch(FetchDescriptor<LinkRecord>(predicate: #Predicate { $0.originalUrl == url }))
                            if !dupes.isEmpty {
                                duplicateCount += 1
                                DebugLogger.shared.logWebViewAction("🟠 ContentView: Skipping duplicate url=\(searchResult.link) (existing=\(dupes.count))")
                                continue
                            }
                        } catch {
                            DebugLogger.shared.logWebViewAction("⚠️ ContentView: Duplicate check failed for url=\(searchResult.link): \(error.localizedDescription)")
                        }
                        // Fetch HTML content immediately to avoid network requests later
                        let _ = await fetchHTMLFromURL(searchResult.link)
                        
                        // Extract ALL content from HTML for fast access
                        do {
                        DebugLogger.shared.logWebViewAction("🔄 ContentView: Starting content extraction for '\(searchResult.title)'")
                        let extractor = HTMLContentExtractor()
                        let extractedContent = try await extractor.extractContent(from: searchResult.link)
                        
                        DebugLogger.shared.logWebViewAction("📊 ContentView: Extracted content - Text: \(extractedContent.mainText.count) chars, Links: \(extractedContent.links.count), Videos: \(extractedContent.videos.count), Images: \(extractedContent.images.count)")
                        
                        // Build JSON payloads (links/videos/metadata)
                        let linksJSON = encodeLinksJSON(extractedContent.links)
                        let videosJSON = encodeVideosJSON(extractedContent.videos)
                        let metadataJSON = encodeMetadataJSON(extractedContent.metadata)
                        
                        let linkRecord = LinkRecord(
                            searchRecordId: record.id,
                            originalUrl: searchResult.link,
                            title: searchResult.title,
                            content: searchResult.snippet,
                            extractedText: extractedContent.mainText,
                            fetchedAt: Date(),
                            articleDescription: searchResult.snippet,
                            wordCount: searchResult.snippet.split(separator: " ").count,
                            readingTime: max(1, searchResult.snippet.split(separator: " ").count / 200)
                        )
                        // Speichere Plain-Text-Datei optional ab
                        let plainText = linkRecord.extractedText.isEmpty ? extractedContent.mainText : linkRecord.extractedText
                        savePlainTextFile(for: linkRecord, text: plainText)
                        linkRecord.extractedLinksJSON = linksJSON
                        linkRecord.extractedVideosJSON = videosJSON
                        linkRecord.extractedMetadataJSON = metadataJSON
                        
                        // Download and save images to ImageRecord relationships
                        var totalImageBytes = 0
                        for image in extractedContent.images {
                            DebugLogger.shared.logWebViewAction("🖼️ ContentView: Downloading image: \(image.url)")
                            
                            // Download image data
                            var localPath: String?
                            var fileSize: Int = 0
                            
                            if let imageURL = URL(string: image.url) {
                                do {
                                    let (data, response) = try await URLSession.shared.data(from: imageURL)
                                    fileSize = data.count
                                    totalImageBytes += fileSize
                                    
                                    // Save to local file system
                                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                    let imagesPath = documentsPath.appendingPathComponent("DailyWebScanner/Images")
                                    try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
                                    // Determine extension by MIME type
                                    let ext: String = {
                                        if let mime = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")?.lowercased() {
                                            if mime.contains("image/png") { return "png" }
                                            if mime.contains("image/webp") { return "webp" }
                                            if mime.contains("image/gif") { return "gif" }
                                            if mime.contains("image/tiff") { return "tiff" }
                                            if mime.contains("image/heic") { return "heic" }
                                        }
                                        return "jpg"
                                    }()
                                    let fileName = "\(linkRecord.id.uuidString)_\(UUID().uuidString).\(ext)"
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
                            // Ensure the image record is persisted
                            modelContext.insert(imageRecord)
                        }
                        linkRecord.imageCount = linkRecord.images.count
                        linkRecord.totalImageSize = totalImageBytes
                        
                        DebugLogger.shared.logWebViewAction("💾 ContentView: Saved complete content to database for '\(searchResult.title)'")
                        modelContext.insert(linkRecord)
                        createdCount += 1
                        DebugLogger.shared.logWebViewAction("✅ ContentView: Created LinkRecord id=\(linkRecord.id) for url=\(searchResult.link)")
                        DebugLogger.shared.logWebViewAction("Created LinkRecord: \(searchResult.title) (Text length: \(extractedContent.mainText.count))")
                        // Save after inserting images and link
                        do { try modelContext.save() } catch { DebugLogger.shared.logWebViewAction("❌ ContentView: modelContext.save() failed: \(error.localizedDescription)") }
                        } catch {
                            failureCount += 1
                            DebugLogger.shared.logWebViewAction("❌ ContentView: Failed processing result \(idx+1)/\(searchResults.count) url=\(searchResult.link): \(error.localizedDescription)")
                            continue
                        }

                        // Update progress
                    DebugLogger.shared.logWebViewAction("📦 ContentView: Summary — created=\(createdCount) / total=\(searchResults.count), duplicates=\(duplicateCount), failures=\(failureCount)")
                await MainActor.run {
                            if total > 0 {
                                let current = idx + 1
                                progressValue = Double(current) / Double(total)
                                progressText = "Extracting content (\(current)/\(total))…"
                            }
                        }
                    }
                
                await MainActor.run {
                        modelContext.insert(record)
                        selectedSearchRecord = record
                        searchText = "" // Clear search text after successful search
                        DebugLogger.shared.logWebViewAction("Manual search completed - searchRecords count: \(searchRecords.count)")
                        DebugLogger.shared.logWebViewAction("Created \(searchResults.count) LinkRecords for article list")
                        isSearching = false
                        progressValue = nil
                        progressText = ""
                }
            } catch {
                    DebugLogger.shared.logWebViewAction("Search failed: \(error)")
                await MainActor.run {
                        progressText = "Error: \(error.localizedDescription)"
                        progressValue = nil
                        isSearching = false
                    }
                }
            }
        }
    }

    // MARK: - Encoding Helpers
    private struct SimpleLink: Codable {
        let url: String
        let title: String
        let description: String
        let isExternal: Bool
    }
    private struct SimpleVideo: Codable {
        let url: String
        let title: String
        let thumbnail: String?
        let duration: String?
        let platform: String
    }
    private struct MetadataDTO: Codable {
        let author: String?
        let publishDate: String?
        let category: String?
        let tags: [String]
        let language: String?
    }
    private func encodeLinksJSON(_ links: [HTMLContentExtractor.ExtractedLink]) -> String {
        let simple = links.map { SimpleLink(url: $0.url, title: $0.title, description: $0.description, isExternal: $0.isExternal) }
        let enc = JSONEncoder()
        return (try? enc.encode(simple)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
    private func encodeVideosJSON(_ videos: [HTMLContentExtractor.ExtractedVideo]) -> String {
        let simple = videos.map { SimpleVideo(url: $0.url, title: $0.title, thumbnail: $0.thumbnail, duration: $0.duration, platform: platformString($0.platform)) }
        let enc = JSONEncoder()
        return (try? enc.encode(simple)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
    private func encodeMetadataJSON(_ meta: HTMLContentExtractor.ContentMetadata) -> String {
        let iso = ISO8601DateFormatter()
        let dto = MetadataDTO(author: meta.author, publishDate: meta.publishDate.map { iso.string(from: $0) }, category: meta.category, tags: meta.tags, language: meta.language)
        let enc = JSONEncoder()
        return (try? enc.encode(dto)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
    private func platformString(_ p: HTMLContentExtractor.VideoPlatform) -> String {
        switch p {
        case .youtube: return "youtube"
        case .vimeo: return "vimeo"
        case .direct: return "direct"
        case .other(let s): return s
        }
    }
    
    // MARK: - CSS Helpers
    private func extractInlineCSS(from html: String) -> String {
        // very simple extraction of <style> blocks
        let pattern = "<style[^>]*>([\\s\\S]*?)</style>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return "" }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        var parts: [String] = []
        for m in matches {
            if let r = Range(m.range(at: 1), in: html) { parts.append(String(html[r])) }
        }
        return parts.joined(separator: "\n\n")
    }
    private func fetchLinkedCSSResources(fromHTML html: String, baseURL: String, maxFiles: Int, maxTotalBytes: Int) async -> String {
        // find <link rel="stylesheet" href="...">
        let pattern = "<link[^>]*rel=\\\"stylesheet\\\"[^>]*href=\\\"([^\\\"]+)\\\"[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return "" }
        let ns = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))
        var downloaded = 0
        var totalBytes = 0
        var aggregated: [String] = []
        for m in results {
            if downloaded >= maxFiles || totalBytes >= maxTotalBytes { break }
            let hrefRange = m.range(at: 1)
            guard hrefRange.location != NSNotFound,
                  let r = Range(hrefRange, in: html) else { continue }
            let href = String(html[r])
            let resolved = resolveCSSURL(href, baseURL: baseURL)
            guard let u = URL(string: resolved) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: u)
                if totalBytes + data.count > maxTotalBytes { break }
                if let css = String(data: data, encoding: .utf8) {
                    aggregated.append(css)
                    totalBytes += data.count
                    downloaded += 1
                }
            } catch {
                continue
            }
        }
        return aggregated.joined(separator: "\n\n")
    }
    private func resolveCSSURL(_ url: String, baseURL: String) -> String {
        if url.hasPrefix("http://") || url.hasPrefix("https://") { return url }
        if url.hasPrefix("//") { return "https:" + url }
        if url.hasPrefix("/") { return baseURL + url }
        return baseURL + "/" + url
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
            fetchedAt: Date(),
            articleDescription: result.snippet,
            wordCount: result.snippet.split(separator: " ").count,
            readingTime: max(1, result.snippet.split(separator: " ").count / 200)
        )
    }

    private func resolveSerpKey() -> String {
        if let key = KeychainHelper.get(.serpAPIKey), !key.isEmpty { return key }
        return serpKey
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
                            ForEach(searchRecord.results.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) { result in
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
                    ScrollView {
                        Text(searchRecord.htmlSummary)
                            .font(.body)
                            .padding()
                    }
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
            DebugLogger.shared.logWebViewAction("❌ MainView: Invalid URL: \(urlString)")
            return ""
        }
        
        do {
            DebugLogger.shared.logWebViewAction("🌐 MainView: Fetching HTML from \(urlString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                DebugLogger.shared.logWebViewAction("📡 MainView: HTTP Status: \(httpResponse.statusCode)")
            }
            
            let html = String(data: data, encoding: .utf8) ?? ""
            DebugLogger.shared.logWebViewAction("📄 MainView: Fetched content length: \(html.count) characters")
            return html
        } catch {
            DebugLogger.shared.logWebViewAction("❌ MainView: Failed to fetch content - \(error.localizedDescription)")
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
    
    private func savePlainTextFile(for record: LinkRecord, text: String) {
        guard !text.isEmpty else { return }
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dir = docs.appendingPathComponent("DailyWebScanner/Text", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let fileURL = dir.appendingPathComponent("\(record.id.uuidString).txt")
            try (text + "\n").write(to: fileURL, atomically: true, encoding: .utf8)
            record.plainTextFilePath = fileURL.path
            DebugLogger.shared.logWebViewAction("📝 Saved plain text to \(fileURL.path)")
        } catch {
            DebugLogger.shared.logWebViewAction("⚠️ Failed to save plain text: \(error.localizedDescription)")
        }
    }
}