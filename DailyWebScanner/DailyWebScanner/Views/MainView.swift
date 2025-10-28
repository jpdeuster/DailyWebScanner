import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ManualSearchRecord.query, order: .forward) private var searchRecords: [ManualSearchRecord]
    @State private var searchText: String = ""
    @State private var selectedSearchRecord: ManualSearchRecord?
    @State private var filterText: String = ""
    @State private var isSearching: Bool = false
    @State private var progressValue: Double? = nil
    @State private var progressText: String = ""
    @AppStorage("searchLanguage") var language: String = ""
    @AppStorage("searchRegion") var region: String = ""
    @AppStorage("searchLocation") var location: String = ""
    @AppStorage("searchSafeSearch") var safeSearch: String = "off"
    @AppStorage("searchType") var searchType: String = ""
    @AppStorage("searchTimeRange") var timeRange: String = ""
    @AppStorage("searchDateRange") var dateRange: String = ""
    @AppStorage("serpAPIKey") private var serpKey: String = ""
    @AppStorage("openAIKey") private var openAIKey: String = ""
    @State private var isTestingSerpAPI: Bool = false
    @State private var serpAPIStatusText: String = ""
    @State private var serpAPIStatusOK: Bool? = nil
    @State private var openAIStatusOK: Bool? = nil
    @State private var serpCreditsText: String = ""
    @State private var serpPlanText: String = ""
    @State private var hasActiveAutomatedSearches: Bool = true

    private var filteredSearchRecords: [ManualSearchRecord] {
        let records = filterText.isEmpty ? searchRecords : searchRecords.filter { record in
            record.query.localizedCaseInsensitiveContains(filterText) ||
            record.language.localizedCaseInsensitiveContains(filterText) ||
            record.region.localizedCaseInsensitiveContains(filterText) ||
            record.location.localizedCaseInsensitiveContains(filterText)
        }
        return records.sorted { $0.query.localizedCaseInsensitiveCompare($1.query) == .orderedAscending }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search Parameters
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "gear").font(.caption2).foregroundColor(.blue)
                        Text("Search Parameters").font(.caption).fontWeight(.medium).foregroundColor(.primary)
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe").font(.caption2).foregroundColor(.blue)
                            Picker("Language", selection: $language) {
                                ForEach(LanguageHelper.languages, id: \.code) { language in
                                    Text(language.name).tag(language.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "map").font(.caption2).foregroundColor(.blue)
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
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "shield").font(.caption2).foregroundColor(.blue)
                            Picker("Safe", selection: $safeSearch) {
                                Text("Off").tag("off")
                                Text("Active").tag("active")
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass").font(.caption2).foregroundColor(.blue)
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
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock").font(.caption2).foregroundColor(.blue)
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
                        HStack(spacing: 4) {
                            Image(systemName: "building.2").font(.caption2).foregroundColor(.blue)
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
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.blue.opacity(0.15), lineWidth: 0.5))
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

                // Manual Search Field
                HStack {
                    TextField("Enter search query...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { performSearch() }
                    Button(action: { performSearch() }) {
                        Image(systemName: "magnifyingglass").foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

                // Banner
                if !hasActiveAutomatedSearches {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath").foregroundColor(.blue).font(.caption)
                        Text("Would you like to add daily automated searches?")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Button(action: { showAutomatedSearchWindow() }) { Text("Open Automated Search").font(.caption) }
                            .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.08)))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }

                // Search Records List
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("Manual Search").font(.headline); Spacer() }
                        .padding(.horizontal)
                    List(selection: $selectedSearchRecord) {
                        ForEach(filteredSearchRecords) { record in
                            NavigationLink(value: record) {
                                SearchQueryRow(record: record) { deleteSearchRecord(record) }
                            }
                            .swipeActions {
                                Button(role: .destructive) { deleteSearchRecord(record) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }

                // Progress bar
                if isSearching {
                    Divider()
                    HStack(spacing: 8) {
                        if let value = progressValue { ProgressView(value: value).frame(width: 160, height: 4) }
                        else { ProgressView().frame(width: 160, height: 4) }
                        Text(progressText.isEmpty ? "Searching…" : progressText).font(.caption).foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }

                // API status (two lines)
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: serpAPIStatusOK == true ? "checkmark.circle.fill" : (resolveSerpKey().isEmpty ? "questionmark.circle.fill" : "xmark.circle.fill"))
                                .foregroundColor(resolveSerpKey().isEmpty ? .blue : (serpAPIStatusOK == true ? .green : .red))
                                .font(.caption)
                            Text("SerpAPI").font(.caption).foregroundColor(.primary)
                            if !serpAPIStatusText.isEmpty { Text(serpAPIStatusText).font(.caption2).foregroundColor(.secondary) }
                            if !serpPlanText.isEmpty { Text(serpPlanText).font(.caption2).foregroundColor(.secondary) }
                            if !serpCreditsText.isEmpty { Text(serpCreditsText).font(.caption2).foregroundColor(.secondary) }
                        }
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: openAIKey.isEmpty ? "questionmark.circle.fill" : "checkmark.circle.fill").foregroundColor(openAIKey.isEmpty ? .blue : .green).font(.caption)
                            Text("OpenAI").font(.caption).foregroundColor(.primary)
                            Text(openAIKey.isEmpty ? "Not configured" : "Configured").font(.caption2).foregroundColor(.secondary)
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
            DebugLogger.shared.logWebViewAction("MainView appeared - searchRecords count: \(searchRecords.count)")
            openAIStatusOK = openAIKey.isEmpty ? nil : true
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
                            if let rem = rem, let lim = lim { serpCreditsText = "Credits: \(rem)/\(lim)" }
                            else if let rem = rem { serpCreditsText = "Credits: \(rem)" }
                            else { serpCreditsText = "" }
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
            let automatedRecords = try? modelContext.fetch(FetchDescriptor<AutomatedSearchRecord>())
            if let automatedRecords = automatedRecords {
                let activeAutomated = automatedRecords.filter { $0.isEnabled }
                hasActiveAutomatedSearches = !activeAutomated.isEmpty
            }
        }
    }

    private func deleteSearchRecord(_ record: ManualSearchRecord) {
        if selectedSearchRecord?.id == record.id { selectedSearchRecord = nil }
        modelContext.delete(record)
        do { try modelContext.save() } catch { }
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            do {
                await MainActor.run { isSearching = true; progressValue = nil; progressText = "Searching…" }
                let viewModel = SearchViewModel(); viewModel.modelContext = modelContext
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
                    if total > 0 { progressValue = 0.0; progressText = "Extracting content (0/\(total))…" }
                    else { progressValue = nil; progressText = "No results" }
                }
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
                for (idx, searchResult) in searchResults.enumerated() {
                    let _ = await fetchHTMLFromURL(searchResult.link)
                    let extractor = HTMLContentExtractor()
                    let extractedContent = try await extractor.extractContent(from: searchResult.link)
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
                    linkRecord.extractedLinksJSON = linksJSON
                    linkRecord.extractedVideosJSON = videosJSON
                    linkRecord.extractedMetadataJSON = metadataJSON
                    // Map metadata to top-level fields
                    linkRecord.author = extractedContent.metadata.author
                    linkRecord.publishDate = extractedContent.metadata.publishDate
                    linkRecord.language = extractedContent.metadata.language
                    linkRecord.keywords = extractedContent.metadata.tags.joined(separator: ", ")
                    linkRecord.wordCount = extractedContent.wordCount
                    linkRecord.readingTime = extractedContent.readingTime
                    // Speichere Plain-Text-Datei optional ab
                    let plainText = linkRecord.extractedText.isEmpty ? extractedContent.mainText : linkRecord.extractedText
                    savePlainTextFile(for: linkRecord, text: plainText)
                    // AI/Analysis placeholders (can be filled later by background tasks)
                    linkRecord.hasAIOverview = !linkRecord.aiOverviewJSON.isEmpty
                    linkRecord.hasContentAnalysis = !linkRecord.contentAnalysisJSON.isEmpty
                    var totalImageBytes = 0
                    for image in extractedContent.images {
                        DebugLogger.shared.logWebViewAction("🖼️ MainView: Downloading image: \(image.url)")
                        var localPath: String?
                        var fileSize: Int = 0
                        if let imageURL = URL(string: image.url) {
                            do {
                                let (data, response) = try await URLSession.shared.data(from: imageURL)
                                fileSize = data.count
                                totalImageBytes += fileSize
                                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                let imagesPath = documentsPath.appendingPathComponent("DailyWebScanner/Images")
                                try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
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
                            } catch { }
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
                        modelContext.insert(imageRecord)
                    }
                    // Video thumbnails (YouTube only quick pass)
                    for video in extractedContent.videos {
                        switch video.platform {
                        case .youtube:
                            // Ableitung einer stabilen Thumbnail-URL
                            let thumbURL = video.thumbnail ?? video.url
                            if let url = URL(string: thumbURL) {
                                do {
                                    let (data, response) = try await URLSession.shared.data(from: url)
                                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                    let imagesPath = documentsPath.appendingPathComponent("DailyWebScanner/Images")
                                    try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
                                    let ext: String = {
                                        if let mime = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")?.lowercased() {
                                            if mime.contains("image/png") { return "png" }
                                            if mime.contains("image/webp") { return "webp" }
                                            if mime.contains("image/gif") { return "gif" }
                                        }
                                        return "jpg"
                                    }()
                                    let fileName = "\(linkRecord.id.uuidString)_yt_\(UUID().uuidString).\(ext)"
                                    let fileURL = imagesPath.appendingPathComponent(fileName)
                                    try data.write(to: fileURL)
                                    let imageRecord = ImageRecord(
                                        linkRecordId: linkRecord.id,
                                        originalUrl: thumbURL,
                                        localPath: fileURL.path,
                                        altText: video.title,
                                        width: nil,
                                        height: nil,
                                        fileSize: data.count,
                                        downloadedAt: Date()
                                    )
                                    linkRecord.images.append(imageRecord)
                                    modelContext.insert(imageRecord)
                                    linkRecord.imageCount = linkRecord.images.count
                                    linkRecord.totalImageSize += data.count
                                } catch { }
                            }
                        default:
                            break
                        }
                    }
                    linkRecord.imageCount = linkRecord.images.count
                    linkRecord.totalImageSize = totalImageBytes
                    modelContext.insert(linkRecord)
                    // manuelle Suche: Beziehung am Parent pflegen
                    record.linkRecords.append(linkRecord)
                    do { try modelContext.save() } catch { }
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
                    searchText = ""
                    isSearching = false
                    progressValue = nil
                    progressText = ""
                }
            } catch {
                await MainActor.run {
                    progressText = "Error: \(error.localizedDescription)"
                    progressValue = nil
                    isSearching = false
                }
            }
        }
    }

    // Encoding helpers
    private struct SimpleLink: Codable { let url: String; let title: String; let description: String; let isExternal: Bool }
    private struct SimpleVideo: Codable { let url: String; let title: String; let thumbnail: String?; let duration: String?; let platform: String }
    private struct MetadataDTO: Codable { let author: String?; let publishDate: String?; let category: String?; let tags: [String]; let language: String? }
    private func encodeLinksJSON(_ links: [HTMLContentExtractor.ExtractedLink]) -> String {
        let simple = links.map { SimpleLink(url: $0.url, title: $0.title, description: $0.description, isExternal: $0.isExternal) }
        let enc = JSONEncoder(); return (try? enc.encode(simple)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
    private func encodeVideosJSON(_ videos: [HTMLContentExtractor.ExtractedVideo]) -> String {
        let simple = videos.map { SimpleVideo(url: $0.url, title: $0.title, thumbnail: $0.thumbnail, duration: $0.duration, platform: platformString($0.platform)) }
        let enc = JSONEncoder(); return (try? enc.encode(simple)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
    private func encodeMetadataJSON(_ meta: HTMLContentExtractor.ContentMetadata) -> String {
        let iso = ISO8601DateFormatter()
        let dto = MetadataDTO(author: meta.author, publishDate: meta.publishDate.map { iso.string(from: $0) }, category: meta.category, tags: meta.tags, language: meta.language)
        let enc = JSONEncoder(); return (try? enc.encode(dto)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
    private func platformString(_ p: HTMLContentExtractor.VideoPlatform) -> String {
        switch p { case .youtube: return "youtube"; case .vimeo: return "vimeo"; case .direct: return "direct"; case .other(let s): return s }
    }

    // CSS helpers
    private func extractInlineCSS(from html: String) -> String {
        let pattern = "<style[^>]*>([\\s\\S]*?)</style>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return "" }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        var parts: [String] = []
        for m in matches { if let r = Range(m.range(at: 1), in: html) { parts.append(String(html[r])) } }
        return parts.joined(separator: "\n\n")
    }
    private func fetchLinkedCSSResources(fromHTML html: String, baseURL: String, maxFiles: Int, maxTotalBytes: Int) async -> String {
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
            guard hrefRange.location != NSNotFound, let r = Range(hrefRange, in: html) else { continue }
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
            } catch { continue }
        }
        return aggregated.joined(separator: "\n\n")
    }
    private func resolveCSSURL(_ url: String, baseURL: String) -> String {
        if url.hasPrefix("http://") || url.hasPrefix("https://") { return url }
        if url.hasPrefix("//") { return "https:" + url }
        if url.hasPrefix("/") { return baseURL + url }
        return baseURL + "/" + url
    }

    private func loadAccountInfo() { }

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
        searchQueriesWindow.isReleasedWhenClosed = false
        searchQueriesWindow.makeKeyAndOrderFront(nil)
    }

    private func fetchHTMLFromURL(_ urlString: String) async -> String {
        guard let url = URL(string: urlString) else { return "" }
        do {
            var request = URLRequest(url: url)
            if UserDefaults.standard.bool(forKey: "acceptAllCookies") {
                let consentPairs: [String] = [
                    "CookieConsent=allow",
                    "cookieconsent_status=allow",
                    "cookie_consent=accepted",
                    "borlabs-cookie=all",
                    "OptanonConsent=isIABGlobal=false&datestamp=now&version=6.33.0&hosts=&consentId=anonymous&interactionCount=1&landingPath=/",
                    "CONSENT=YES+1",
                    "euconsent-v2=",
                    "gdprApplies=1"
                ]
                request.setValue(consentPairs.joined(separator: "; "), forHTTPHeaderField: "Cookie")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            return String(data: data, encoding: .utf8) ?? ""
        } catch { return "" }
    }

    private func resolveSerpKey() -> String { if let key = KeychainHelper.get(.serpAPIKey), !key.isEmpty { return key }; return serpKey }

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

// Reuse subviews from ContentView file; no duplicates here
