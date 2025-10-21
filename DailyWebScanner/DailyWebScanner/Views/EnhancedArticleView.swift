import SwiftUI
import SwiftData

/// Enhanced article view with powerful content extraction and beautiful display
struct EnhancedArticleView: View {
    let linkRecord: LinkRecord
    let searchRecord: (any SearchRecordProtocol)? // Optional search record for parameters
    @State private var extractedContent: HTMLContentExtractor.ExtractedContent?
    @State private var isLoading: Bool = true
    @State private var extractionError: String?
    @State private var selectedTab: ArticleTab = .content
    @State private var showFullImage: Bool = false
    @State private var selectedImageIndex: Int = 0
    @Environment(\.modelContext) private var modelContext
    
    enum ArticleTab: String, CaseIterable {
        case content = "Text View"
        case html = "HTML View"
        case images = "Images"
        case videos = "Videos"
        case links = "Links"
        case metadata = "Info"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with article title and metadata
            ArticleHeaderView(
                title: linkRecord.title,
                url: linkRecord.originalUrl,
                wordCount: extractedContent?.wordCount ?? linkRecord.wordCount,
                readingTime: extractedContent?.readingTime ?? linkRecord.readingTime,
                publishDate: extractedContent?.metadata.publishDate,
                author: extractedContent?.metadata.author,
                searchParameters: createSearchParameters(from: linkRecord)
            )
            
            // Tab Navigation
            TabNavigationView(selectedTab: $selectedTab)
                .onChange(of: selectedTab) { oldTab, newTab in
                    let startTime = Date()
                    DebugLogger.shared.logWebViewAction("🔄 EnhancedArticleView: Switching from '\(oldTab.rawValue)' to '\(newTab.rawValue)' tab")
                    
                    // Log when Info tab is selected
                    if newTab == .metadata {
                        DebugLogger.shared.logWebViewAction("ℹ️ EnhancedArticleView: Info tab selected - starting timing")
                    }
                    
                    // Log when Images tab is selected
                    if newTab == .images {
                        DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Images tab selected - starting timing")
                        let imageCount = extractedContent?.images.count ?? 0
                        DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Found \(imageCount) images to display")
                    }
                    
                    // Log tab switch completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let switchTime = Date().timeIntervalSince(startTime)
                        DebugLogger.shared.logWebViewAction("⏱️ EnhancedArticleView: Tab switch to '\(newTab.rawValue)' completed in \(String(format: "%.3f", switchTime)) seconds")
                    }
                }
            
            // Content Area
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        LoadingView()
                    } else if let error = extractionError {
                        ErrorView(error: error) {
                            Task {
                                await loadContent()
                            }
                        }
                    } else {
        switch selectedTab {
                        case .content:
                            ContentTabView(content: extractedContent, linkRecord: linkRecord)
                                .onAppear {
                                    let textLength = linkRecord.extractedText.isEmpty ? (extractedContent?.mainText.count ?? 0) : linkRecord.extractedText.count
                                    DebugLogger.shared.logWebViewAction("📝 EnhancedArticleView: Text View appeared - text length: \(textLength) characters")
                                    DebugLogger.shared.logWebViewAction("📝 EnhancedArticleView: Using extractedText: \(!linkRecord.extractedText.isEmpty), content.mainText: \(extractedContent?.mainText.isEmpty == false)")
                                }
        case .html:
            HTMLTabView(html: linkRecord.html, css: linkRecord.css, url: linkRecord.originalUrl)
                                .onAppear {
                                    DebugLogger.shared.logWebViewAction("🌐 EnhancedArticleView: HTML tab appeared - HTML length: \(linkRecord.html.count) characters, CSS length: \(linkRecord.css.count) characters, baseURL: \(linkRecord.originalUrl)")
                                    if linkRecord.html.isEmpty {
                                        DebugLogger.shared.logWebViewAction("⚠️ EnhancedArticleView: HTML content is empty!")
                                    } else {
                                        DebugLogger.shared.logWebViewAction("✅ EnhancedArticleView: HTML content available (\(linkRecord.html.count) chars)")
                                    }
                                }
        case .images:
            // Prefer locally saved images; map localPath to file:// URL for offline rendering
            var imagesToShow = !linkRecord.images.isEmpty ? linkRecord.images.map { imageRecord in
                let urlString: String
                if let path = imageRecord.localPath {
                    urlString = URL(fileURLWithPath: path).absoluteString
                } else {
                    urlString = imageRecord.originalUrl
                }
                return HTMLContentExtractor.ExtractedImage(
                    url: urlString,
                    alt: imageRecord.altText ?? "",
                    caption: "",
                    width: nil,
                    height: nil,
                    isMainImage: false
                )
            } : (extractedContent?.images ?? [])
            
            ImagesTabView(
                images: imagesToShow,
                showFullImage: $showFullImage,
                selectedImageIndex: $selectedImageIndex
            )
            .onAppear {
                // Nachladen direkt aus der DB, falls zum Zeitpunkt des Renderns noch leer
                if imagesToShow.isEmpty {
                    do {
                        let descriptor = FetchDescriptor<ImageRecord>(predicate: #Predicate { $0.linkRecordId == linkRecord.id })
                        if let fetched = try? modelContext.fetch(descriptor), !fetched.isEmpty {
                            let mapped = fetched.map { rec in
                                HTMLContentExtractor.ExtractedImage(
                                    url: (rec.localPath.map { URL(fileURLWithPath: $0).absoluteString }) ?? rec.originalUrl,
                                    alt: rec.altText ?? "",
                                    caption: "",
                                    width: rec.width,
                                    height: rec.height,
                                    isMainImage: false
                                )
                            }
                            self.extractedContent = HTMLContentExtractor.ExtractedContent(
                                title: extractedContent?.title ?? linkRecord.title,
                                description: extractedContent?.description ?? (linkRecord.articleDescription ?? ""),
                                mainText: extractedContent?.mainText ?? linkRecord.extractedText,
                                images: mapped,
                                videos: extractedContent?.videos ?? [],
                                links: extractedContent?.links ?? [],
                                metadata: extractedContent?.metadata ?? HTMLContentExtractor.ContentMetadata(author: linkRecord.author, publishDate: linkRecord.publishDate, category: nil, tags: [], language: linkRecord.language, wordCount: linkRecord.wordCount, readingTime: linkRecord.readingTime),
                                readingTime: extractedContent?.readingTime ?? linkRecord.readingTime,
                                wordCount: extractedContent?.wordCount ?? linkRecord.wordCount
                            )
                            imagesToShow = mapped
                            DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Fetched \(mapped.count) images from DB onAppear")
                        }
                    }
                }
                let imageCount = imagesToShow.count
                let linkRecordImages = linkRecord.images.count
                let sample = imagesToShow.prefix(3).map { $0.url }.joined(separator: ", ")
                DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Images tab appeared - toShow: \(imageCount), linkRecord images: \(linkRecordImages), sample: [\(sample)]")
                
                if imageCount == 0 && linkRecordImages > 0 {
                    DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: No extracted images, but \(linkRecordImages) images in linkRecord")
                }
            }
        case .videos:
            VideosTabView(videos: extractedContent?.videos ?? [])
        case .links:
            LinksTabView(links: decodedLinks() ?? (extractedContent?.links ?? []))
                .onAppear {
                    let count = (decodedLinks() ?? (extractedContent?.links ?? [])).count
                    let sample = (decodedLinks() ?? (extractedContent?.links ?? [])).prefix(3).map { $0.url }.joined(separator: ", ")
                    DebugLogger.shared.logWebViewAction("🔗 EnhancedArticleView: Links tab appeared - count: \(count), sample: [\(sample)]")
                }
        case .metadata:
            MetadataTabView(metadata: decodedMetadata() ?? extractedContent?.metadata)
                                .onAppear {
                                    DebugLogger.shared.logWebViewAction("ℹ️ EnhancedArticleView: Info tab appeared - metadata available: \(extractedContent?.metadata != nil)")
                                    if let metadata = decodedMetadata() ?? extractedContent?.metadata {
                                        let publishDateString = metadata.publishDate?.description ?? "none"
                                        DebugLogger.shared.logWebViewAction("ℹ️ EnhancedArticleView: Metadata - author: '\(metadata.author ?? "none")', publishDate: '\(publishDateString)', language: '\(metadata.language ?? "none")', tags: \(metadata.tags.count)")
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            await loadContent()
        }
        .onChange(of: linkRecord.id) { _, _ in
            // Reset state when linkRecord changes
            extractedContent = nil
            isLoading = true
            extractionError = nil
            selectedTab = .content
            
            // Start timing for article loading
            let startTime = Date()
            DebugLogger.shared.logWebViewAction("⏱️ EnhancedArticleView: Starting article load timing for '\(linkRecord.title)'")
            
            // Reload content for new article
            Task {
                await loadContent()
                
                // Log total loading time
                let loadTime = Date().timeIntervalSince(startTime)
                DebugLogger.shared.logWebViewAction("⏱️ EnhancedArticleView: Article loaded in \(String(format: "%.2f", loadTime)) seconds")
            }
        }
        .sheet(isPresented: $showFullImage) {
            if let images = extractedContent?.images, !images.isEmpty {
                FullScreenImageView(
                    images: images,
                    selectedIndex: $selectedImageIndex
                )
            }
        }
    }
    
    // MARK: - Content Loading
    
    private func loadContent() async {
        isLoading = true
        extractionError = nil
        
        DebugLogger.shared.logWebViewAction("🔄 EnhancedArticleView: Starting content loading for '\(linkRecord.title)'")
        DebugLogger.shared.logWebViewAction("📄 EnhancedArticleView: HTML content length: \(linkRecord.html.count) characters")
        DebugLogger.shared.logWebViewAction("📝 EnhancedArticleView: Extracted text length: \(linkRecord.extractedText.count) characters")
        DebugLogger.shared.logWebViewAction("🔗 EnhancedArticleView: Links JSON length: \(linkRecord.extractedLinksJSON.count) characters")
        DebugLogger.shared.logWebViewAction("🎥 EnhancedArticleView: Videos JSON length: \(linkRecord.extractedVideosJSON.count) characters")
        DebugLogger.shared.logWebViewAction("ℹ️ EnhancedArticleView: Metadata JSON length: \(linkRecord.extractedMetadataJSON.count) characters")
        
        do {
            // If HTML is empty, try to fetch it
            var htmlContent = linkRecord.html
            if htmlContent.isEmpty {
                DebugLogger.shared.logWebViewAction("🌐 EnhancedArticleView: HTML is empty, attempting to fetch from URL")
                htmlContent = await fetchHTMLFromURL(linkRecord.originalUrl)
                
                // Save the fetched HTML back to the database
                if !htmlContent.isEmpty {
                    await MainActor.run {
                        linkRecord.html = htmlContent
                        try? linkRecord.modelContext?.save()
                        DebugLogger.shared.logWebViewAction("💾 EnhancedArticleView: HTML saved to database (\(htmlContent.count) characters)")
                    }
                }
            } else {
                DebugLogger.shared.logWebViewAction("📄 EnhancedArticleView: Using cached HTML from database (\(htmlContent.count) characters)")
            }
            
            if htmlContent.isEmpty {
                throw NSError(domain: "ContentExtraction", code: 1, userInfo: [NSLocalizedDescriptionKey: "No HTML content available"])
            }
            
            // If DB already contains most data, construct content from DB to avoid re-extraction
            if !linkRecord.extractedText.isEmpty || !linkRecord.extractedLinksJSON.isEmpty || !linkRecord.extractedMetadataJSON.isEmpty || !linkRecord.images.isEmpty {
                let links = decodedLinks() ?? []
                let meta = decodedMetadata()
                let words = (linkRecord.extractedText.isEmpty ? linkRecord.html : linkRecord.extractedText).split(separator: " ").count
                let reading = max(1, words / 200)
                DebugLogger.shared.logWebViewAction("💾 EnhancedArticleView: Constructing content from DB cache - text: \(linkRecord.extractedText.count) chars, links: \(links.count), images: \(linkRecord.images.count)")
                self.extractedContent = HTMLContentExtractor.ExtractedContent(
                    title: linkRecord.title,
                    description: linkRecord.articleDescription ?? "",
                    mainText: linkRecord.extractedText,
                    images: linkRecord.images.map { img in
                        HTMLContentExtractor.ExtractedImage(
                            url: (img.localPath.map { URL(fileURLWithPath: $0).absoluteString }) ?? img.originalUrl,
                            alt: img.altText ?? "",
                            caption: "",
                            width: img.width,
                            height: img.height,
                            isMainImage: false
                        )
                    },
                    videos: [],
                    links: links,
                    metadata: HTMLContentExtractor.ContentMetadata(
                        author: meta?.author,
                        publishDate: meta?.publishDate,
                        category: meta?.category,
                        tags: meta?.tags ?? [],
                        language: meta?.language,
                        wordCount: words,
                        readingTime: reading
                    ),
                    readingTime: reading,
                    wordCount: words
                )
                self.isLoading = false
                DebugLogger.shared.logWebViewAction("✅ EnhancedArticleView: Loaded content from local database cache")
                return
            }

            // Otherwise extract now
            let extractor = HTMLContentExtractor()
            let content = await extractor.extractContent(
                from: htmlContent,
                baseURL: linkRecord.originalUrl
            )
            
            // Save extracted text for future fast access
            linkRecord.extractedText = content.mainText
            
            // Save links as JSON (skip for now - need to make ExtractedLink Encodable)
            // if let linksData = try? JSONEncoder().encode(content.links),
            //    let linksJSON = String(data: linksData, encoding: .utf8) {
            //     linkRecord.extractedLinksJSON = linksJSON
            //     DebugLogger.shared.logWebViewAction("🔗 EnhancedArticleView: Saved \(content.links.count) links to database")
            // }
            
            // Save videos as JSON (references only, not downloaded) - skip for now
            // if let videosData = try? JSONEncoder().encode(content.videos),
            //    let videosJSON = String(data: videosData, encoding: .utf8) {
            //     linkRecord.extractedVideosJSON = videosJSON
            //     DebugLogger.shared.logWebViewAction("🎥 EnhancedArticleView: Saved \(content.videos.count) video references to database")
            // }
            
            // Save metadata as JSON - skip for now
            // if let metadataData = try? JSONEncoder().encode(content.metadata),
            //    let metadataJSON = String(data: metadataData, encoding: .utf8) {
            //     linkRecord.extractedMetadataJSON = metadataJSON
            //     DebugLogger.shared.logWebViewAction("ℹ️ EnhancedArticleView: Saved metadata to database")
            // }
            
            // Download and save images to ImageRecord relationships (only if not present yet)
            if linkRecord.images.isEmpty {
                for image in content.images {
                DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Downloading image: \(image.url)")
                
                // Download image data
                var localPath: String?
                var fileSize: Int = 0
                
                if let imageURL = URL(string: image.url) {
                    do {
                        if imageURL.isFileURL {
                            let data = try Data(contentsOf: imageURL)
                            fileSize = data.count
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let imagesPath = documentsPath.appendingPathComponent("DailyWebScanner/Images")
                            try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
                            let fileName = "\(linkRecord.id.uuidString)_\(UUID().uuidString).jpg"
                            let fileURL = imagesPath.appendingPathComponent(fileName)
                            try data.write(to: fileURL)
                            localPath = fileURL.path
                            DebugLogger.shared.logWebViewAction("💾 EnhancedArticleView: Copied local image to \(fileURL.path) (\(fileSize) bytes)")
                        } else {
                            let (data, response) = try await URLSession.shared.data(from: imageURL)
                            fileSize = data.count
                            if let http = response as? HTTPURLResponse {
                                DebugLogger.shared.logWebViewAction("📡 EnhancedArticleView: Image HTTP Status \(http.statusCode) for \(image.url)")
                            }
                            // Save to local file system
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let imagesPath = documentsPath.appendingPathComponent("DailyWebScanner/Images")
                            try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
                            
                            let fileName = "\(linkRecord.id.uuidString)_\(UUID().uuidString).jpg"
                            let fileURL = imagesPath.appendingPathComponent(fileName)
                            try data.write(to: fileURL)
                            localPath = fileURL.path
                            
                            DebugLogger.shared.logWebViewAction("💾 EnhancedArticleView: Image saved to \(fileURL.path) (\(fileSize) bytes)")
                        }
                    } catch {
                        DebugLogger.shared.logWebViewAction("❌ EnhancedArticleView: Failed to download image \(image.url): \(error.localizedDescription)")
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
                DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Downloaded and saved \(content.images.count) images to database")
            } else {
                DebugLogger.shared.logWebViewAction("🖼️ EnhancedArticleView: Using \(linkRecord.images.count) cached images from database")
            }
            
            await MainActor.run {
                self.extractedContent = content
                self.isLoading = false
                
                try? linkRecord.modelContext?.save()
                DebugLogger.shared.logWebViewAction("💾 EnhancedArticleView: All extracted content saved to database")
                DebugLogger.shared.logWebViewAction("📊 EnhancedArticleView: Summary - Text: \(content.mainText.count) chars, Links: \(content.links.count), Videos: \(content.videos.count), Images: \(content.images.count)")
                DebugLogger.shared.logWebViewAction("✅ EnhancedArticleView: Content loading completed successfully")
            }
        } catch {
            await MainActor.run {
                self.extractionError = error.localizedDescription
                self.isLoading = false
                DebugLogger.shared.logWebViewAction("❌ EnhancedArticleView: Content loading failed - \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchHTMLFromURL(_ urlString: String) async -> String {
        guard let url = URL(string: urlString) else {
            DebugLogger.shared.logWebViewAction("❌ EnhancedArticleView: Invalid URL: \(urlString)")
            return ""
        }
        
        do {
            DebugLogger.shared.logWebViewAction("🌐 EnhancedArticleView: Fetching HTML from \(urlString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                DebugLogger.shared.logWebViewAction("📡 EnhancedArticleView: HTTP Status: \(httpResponse.statusCode)")
            }
            
            let html = String(data: data, encoding: .utf8) ?? ""
            DebugLogger.shared.logWebViewAction("📄 EnhancedArticleView: Fetched HTML length: \(html.count) characters")
            return html
        } catch {
            DebugLogger.shared.logWebViewAction("❌ EnhancedArticleView: Failed to fetch HTML - \(error.localizedDescription)")
            return ""
        }
    }
    
    private func createSearchParameters(from linkRecord: LinkRecord) -> ArticleHeaderView.SearchParameters? {
        // Get search parameters from the associated search record
        guard let searchRecord = searchRecord else {
            // Fallback to linkRecord language if available
            return ArticleHeaderView.SearchParameters(
                language: linkRecord.language ?? "",
                region: "",
                location: "",
                safe: "",
                tbm: "",
                as_qdr: ""
            )
        }
        
        return ArticleHeaderView.SearchParameters(
            language: searchRecord.language,
            region: searchRecord.region,
            location: searchRecord.location,
            safe: searchRecord.safe,
            tbm: searchRecord.tbm,
            as_qdr: searchRecord.as_qdr
        )
    }
}

// MARK: - Article Header

struct ArticleHeaderView: View {
    let title: String
    let url: String
    let wordCount: Int
    let readingTime: Int
    let publishDate: Date?
    let author: String?
    let searchParameters: SearchParameters?
    
    struct SearchParameters {
        let language: String
        let region: String
        let location: String
        let safe: String
        let tbm: String
        let as_qdr: String
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Enhanced Title with Gradient Background
            VStack(spacing: 16) {
                // Article Title
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
                
                // URL with Enhanced Styling
                Button(action: {
                    if let url = URL(string: url) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(url)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Enhanced Metadata Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Reading Stats
                EnhancedReadingStat(
                    icon: "textformat",
                    value: "\(wordCount)",
                    label: "Words",
                    color: .blue
                )
                
                EnhancedReadingStat(
                    icon: "clock",
                    value: "\(readingTime) min",
                    label: "Reading Time",
                    color: .green
                )
                
                if let author = author {
                    EnhancedReadingStat(
                        icon: "person",
                        value: author,
                        label: "Author",
                        color: .purple
                    )
                } else if let publishDate = publishDate {
                    EnhancedReadingStat(
                        icon: "calendar",
                        value: publishDate.formatted(.dateTime.day().month().year()),
                        label: "Published",
                        color: .orange
                    )
                } else {
                    Spacer()
                }
            }
            
            // Search Parameters Section
            if let params = searchParameters {
                SearchParametersCard(parameters: params)
            }
            
            // Author and Date (if not shown above)
            if author != nil && publishDate != nil {
                HStack(spacing: 20) {
                    if let author = author {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(author)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let publishDate = publishDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.circle")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(publishDate.formatted(.dateTime.day().month().year()))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(NSColor.controlBackgroundColor).opacity(0.8),
                            Color(NSColor.controlBackgroundColor).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct ReadingStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct EnhancedReadingStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct SearchParametersCard: View {
    let parameters: ArticleHeaderView.SearchParameters
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Search Parameters")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Always show all parameters, even if they are default values
                ParameterItem(
                    icon: "globe",
                    label: "Language",
                    value: parameters.language.isEmpty ? "Any" : parameters.language,
                    color: .blue
                )
                
                ParameterItem(
                    icon: "map",
                    label: "Region",
                    value: parameters.region.isEmpty ? "Any" : parameters.region,
                    color: .green
                )
                
                ParameterItem(
                    icon: "shield",
                    label: "Safe Search",
                    value: parameters.safe.isEmpty ? "Off" : parameters.safe,
                    color: parameters.safe == "active" ? .green : .gray
                )
                
                ParameterItem(
                    icon: "magnifyingglass",
                    label: "Type",
                    value: parameters.tbm.isEmpty ? "All" : parameters.tbm,
                    color: .purple
                )
                
                ParameterItem(
                    icon: "location",
                    label: "Location",
                    value: parameters.location.isEmpty ? "Any" : parameters.location,
                    color: .orange
                )
                
                ParameterItem(
                    icon: "clock",
                    label: "Time Range",
                    value: parameters.as_qdr.isEmpty ? "Any Time" : parameters.as_qdr,
                    color: .red
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ParameterItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Tab Navigation

struct TabNavigationView: View {
    @Binding var selectedTab: EnhancedArticleView.ArticleTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EnhancedArticleView.ArticleTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - Content Tabs

struct ContentTabView: View {
    let content: HTMLContentExtractor.ExtractedContent?
    let linkRecord: LinkRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let content = content {
                // Enhanced Description
                if !content.description.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.quote")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Text(content.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
                
                // Enhanced Main Content
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Article Content")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        
                        // Copy Button
                        Button(action: {
                            let pasteboard = NSPasteboard.general
                            let textToCopy = linkRecord.extractedText.isEmpty ? content.mainText : linkRecord.extractedText
                            pasteboard.clearContents()
                            pasteboard.setString(textToCopy, forType: .string)
                            print("📋 Text copied to clipboard: \(textToCopy.prefix(50))...")
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 12))
                                Text("Copy All")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Copy entire article text to clipboard")
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(linkRecord.extractedText.isEmpty ? content.mainText : linkRecord.extractedText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled) // ← Macht den Text kopierbar!
                            .padding(20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Content Available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("The article content could not be extracted or is not available.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .padding()
    }
}

struct ImagesTabView: View {
    let images: [HTMLContentExtractor.ExtractedImage]
    @Binding var showFullImage: Bool
    @Binding var selectedImageIndex: Int
    
    var body: some View {
        if images.isEmpty {
            EmptyStateView(
                icon: "photo",
                title: "No Images Found",
                description: "This article doesn't contain any images."
            )
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ImageCardView(
                        image: image,
                        onTap: {
                            selectedImageIndex = index
                            showFullImage = true
                        }
                    )
                }
            }
            .onAppear {
                DebugLogger.shared.logWebViewAction("🖼️ ImagesTabView: Displaying \(images.count) images")
                let sample = images.prefix(3).map { $0.url }.joined(separator: ", ")
                DebugLogger.shared.logWebViewAction("🖼️ ImagesTabView: Sample URLs: [\(sample)]")
            }
        }
    }
}

struct ImageCardView: View {
    let image: HTMLContentExtractor.ExtractedImage
    let onTap: () -> Void
    @State private var imageData: Data?
    @State private var isLoading: Bool = true
    @State private var loadedByteCount: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Try to load actual image from URL
            Group {
                if let imageData = imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .clipped()
                } else if isLoading {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text("Image")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
            .cornerRadius(8)
            .onTapGesture {
                onTap()
            }
            .task {
                await loadImage()
            }
            .contextMenu {
                Button("Bild sichern…") {
                    Task { await saveImage() }
                }
                if let url = URL(string: image.url) {
                    if url.isFileURL {
                        Button("Im Finder anzeigen") {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    } else {
                        Button("Bild-URL im Browser öffnen") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            
            // Image info
            VStack(alignment: .leading, spacing: 4) {
                if !image.alt.isEmpty {
                    Text(image.alt)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                if !image.caption.isEmpty {
                    Text(image.caption)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                // Größe und Quelle
                HStack(spacing: 6) {
                    if let bytes = loadedByteCount {
                        Text(byteString(bytes))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let url = URL(string: image.url) {
                        Text(url.isFileURL ? "Local" : "Remote")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                // Quelle (gekürzt)
                Text(image.url)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
    }
    
    private func loadImage() async {
        guard let url = URL(string: image.url) else {
            await MainActor.run {
                isLoading = false
            }
            DebugLogger.shared.logWebViewAction("❌ ImageCardView: Invalid URL: \(image.url)")
            return
        }
        
        do {
            if url.isFileURL {
                let data = try Data(contentsOf: url)
                await MainActor.run {
                    self.imageData = data
                    self.loadedByteCount = data.count
                    self.isLoading = false
                }
                DebugLogger.shared.logWebViewAction("🖼️ ImageCardView: Loaded local image (\(data.count) bytes) from \(url.path)")
            } else {
                let (data, response) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.imageData = data
                    self.loadedByteCount = data.count
                    self.isLoading = false
                }
                if let http = response as? HTTPURLResponse {
                    DebugLogger.shared.logWebViewAction("🖼️ ImageCardView: Loaded remote image (\(data.count) bytes), HTTP \(http.statusCode) from \(url.absoluteString)")
                } else {
                    DebugLogger.shared.logWebViewAction("🖼️ ImageCardView: Loaded remote image (\(data.count) bytes) from \(url.absoluteString)")
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            DebugLogger.shared.logWebViewAction("❌ ImageCardView: Failed to load image \(url.absoluteString) - \(error.localizedDescription)")
        }
    }
    
    private func saveImage() async {
        // Daten sicherstellen
        var dataToSave: Data?
        if let data = imageData {
            dataToSave = data
        } else if let url = URL(string: image.url) {
            do {
                if url.isFileURL {
                    dataToSave = try Data(contentsOf: url)
                } else {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    dataToSave = data
                }
            } catch {
                DebugLogger.shared.logWebViewAction("❌ ImageCardView: Failed to fetch image for save - \(error.localizedDescription)")
            }
        }
        guard let finalData = dataToSave else { return }
        
        await MainActor.run {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.jpeg, .png, .tiff]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            let suggested = suggestedFileName()
            panel.nameFieldStringValue = suggested
            if panel.runModal() == .OK, let url = panel.url {
                do {
                    try finalData.write(to: url)
                    DebugLogger.shared.logWebViewAction("💾 ImageCardView: Image saved to \(url.path)")
                } catch {
                    DebugLogger.shared.logWebViewAction("❌ ImageCardView: Failed to save image - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func suggestedFileName() -> String {
        if let url = URL(string: image.url) {
            if url.isFileURL {
                return url.lastPathComponent
            } else {
                let name = url.lastPathComponent
                return name.isEmpty ? "image.jpg" : name
            }
        }
        return "image.jpg"
    }
    
    private func byteString(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct VideosTabView: View {
    let videos: [HTMLContentExtractor.ExtractedVideo]
    
    var body: some View {
        if videos.isEmpty {
            EmptyStateView(
                icon: "video",
                title: "No Videos Found",
                description: "This article doesn't contain any videos."
            )
        } else {
            LazyVStack(spacing: 16) {
                ForEach(Array(videos.enumerated()), id: \.offset) { index, video in
                    VideoCardView(video: video)
                }
            }
        }
    }
}

struct VideoCardView: View {
    let video: HTMLContentExtractor.ExtractedVideo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Video placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: platformIcon(video.platform))
                            .font(.title)
                            .foregroundColor(.blue)
                        Text(platformName(video.platform))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let duration = video.duration {
                    Text("Duration: \(duration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(video.url)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("Open") {
                        if let url = URL(string: video.url) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
    }
    
    private func platformIcon(_ platform: HTMLContentExtractor.VideoPlatform) -> String {
        switch platform {
        case .youtube:
            return "play.rectangle.fill"
        case .vimeo:
            return "play.circle.fill"
        case .direct:
            return "video.fill"
        case .other:
            return "play.fill"
        }
    }
    
    private func platformName(_ platform: HTMLContentExtractor.VideoPlatform) -> String {
        switch platform {
        case .youtube:
            return "YouTube"
        case .vimeo:
            return "Vimeo"
        case .direct:
            return "Direct Video"
        case .other(let name):
            return name
        }
    }
}

struct LinksTabView: View {
    let links: [HTMLContentExtractor.ExtractedLink]
    
    var body: some View {
        if links.isEmpty {
            EmptyStateView(
                icon: "link",
                title: "No Links Found",
                description: "This article doesn't contain any links."
            )
        } else {
            LazyVStack(spacing: 12) {
                ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                    LinkCardView(link: link)
                }
            }
        }
    }
}

// MARK: - DB Decoders
extension EnhancedArticleView {
    private struct DecodedMetadata: Codable {
        let author: String?
        let publishDate: String?
        let category: String?
        let tags: [String]
        let language: String?
    }
    private struct DecodedLink: Codable {
        let url: String
        let title: String
        let description: String
        let isExternal: Bool
    }
    private func decodedLinks() -> [HTMLContentExtractor.ExtractedLink]? {
        guard !linkRecord.extractedLinksJSON.isEmpty,
              let data = linkRecord.extractedLinksJSON.data(using: .utf8),
              let simple = try? JSONDecoder().decode([DecodedLink].self, from: data) else { return nil }
        return simple.map { link in
            HTMLContentExtractor.ExtractedLink(
                url: link.url,
                title: link.title,
                description: link.description,
                isExternal: link.isExternal
            )
        }
    }
    private func decodedMetadata() -> HTMLContentExtractor.ContentMetadata? {
        guard !linkRecord.extractedMetadataJSON.isEmpty,
              let data = linkRecord.extractedMetadataJSON.data(using: .utf8),
              let meta = try? JSONDecoder().decode(DecodedMetadata.self, from: data) else { return nil }
        let iso = ISO8601DateFormatter()
        let date = meta.publishDate.flatMap { iso.date(from: $0) }
        return .init(author: meta.author, publishDate: date, category: meta.category, tags: meta.tags, language: meta.language, wordCount: 0, readingTime: 0)
    }
}

struct LinkCardView: View {
    let link: HTMLContentExtractor.ExtractedLink
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: link.isExternal ? "arrow.up.right.square" : "link")
                .font(.title3)
                .foregroundColor(link.isExternal ? .orange : .blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(link.title.isEmpty ? "Link" : link.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if !link.description.isEmpty {
                    Text(link.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(link.url)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button("Open") {
                if let url = URL(string: link.url) {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
    }
}

struct MetadataTabView: View {
    let metadata: HTMLContentExtractor.ContentMetadata?
    
    var body: some View {
        if let metadata = metadata {
            VStack(alignment: .leading, spacing: 16) {
                MetadataSection(title: "Content Info") {
                    MetadataRow(label: "Word Count", value: "\(metadata.wordCount)")
                    MetadataRow(label: "Reading Time", value: "\(metadata.readingTime) minutes")
                    if let language = metadata.language {
                        MetadataRow(label: "Language", value: language)
                    }
                }
                
                if let author = metadata.author {
                    MetadataSection(title: "Author") {
                        MetadataRow(label: "Name", value: author)
                    }
                }
                
                if let publishDate = metadata.publishDate {
                    MetadataSection(title: "Publication") {
                        MetadataRow(label: "Date", value: publishDate.formatted(.dateTime.day().month().year()))
                    }
                }
                
                if let category = metadata.category {
                    MetadataSection(title: "Category") {
                        MetadataRow(label: "Category", value: category)
                    }
                }
                
                if !metadata.tags.isEmpty {
                    MetadataSection(title: "Tags") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(metadata.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        } else {
            EmptyStateView(
                icon: "info.circle",
                title: "No Metadata Available",
                description: "No additional information was found for this article."
            )
        }
    }
}

struct MetadataSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Extracting content...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("Extraction Failed")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct FullScreenImageView: View {
    let images: [HTMLContentExtractor.ExtractedImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var imageData: Data?
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("\(selectedIndex + 1) of \(images.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Image display with actual image loading
            Group {
                if let imageData = imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading image...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text(images[selectedIndex].alt)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .contextMenu {
                Button("Bild sichern…") {
                    Task { await saveCurrent() }
                }
                if let url = URL(string: images[selectedIndex].url) {
                    if url.isFileURL {
                        Button("Im Finder anzeigen") {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    } else {
                        Button("Bild-URL im Browser öffnen") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: selectedIndex) { _, _ in
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        guard selectedIndex < images.count else { return }
        
        let image = images[selectedIndex]
        guard let url = URL(string: image.url) else {
            await MainActor.run {
                isLoading = false
            }
            DebugLogger.shared.logWebViewAction("❌ FullScreenImageView: Invalid URL: \(image.url)")
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            if url.isFileURL {
                let data = try Data(contentsOf: url)
                await MainActor.run {
                    self.imageData = data
                    self.isLoading = false
                }
                DebugLogger.shared.logWebViewAction("🖼️ FullScreenImageView: Loaded local image (\(data.count) bytes) from \(url.path)")
            } else {
                let (data, response) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.imageData = data
                    self.isLoading = false
                }
                if let http = response as? HTTPURLResponse {
                    DebugLogger.shared.logWebViewAction("🖼️ FullScreenImageView: Loaded remote image (\(data.count) bytes), HTTP \(http.statusCode) from \(url.absoluteString)")
                } else {
                    DebugLogger.shared.logWebViewAction("🖼️ FullScreenImageView: Loaded remote image (\(data.count) bytes) from \(url.absoluteString)")
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            DebugLogger.shared.logWebViewAction("❌ FullScreenImageView: Failed to load image \(url.absoluteString) - \(error.localizedDescription)")
        }
    }
    
    private func saveCurrent() async {
        guard selectedIndex < images.count else { return }
        let item = images[selectedIndex]
        var dataToSave: Data?
        if let data = imageData {
            dataToSave = data
        } else if let url = URL(string: item.url) {
            do {
                if url.isFileURL {
                    dataToSave = try Data(contentsOf: url)
                } else {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    dataToSave = data
                }
            } catch {
                DebugLogger.shared.logWebViewAction("❌ FullScreenImageView: Failed to fetch image for save - \(error.localizedDescription)")
            }
        }
        guard let finalData = dataToSave else { return }
        
        await MainActor.run {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.jpeg, .png, .tiff]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            let suggested = suggestedFileName(for: item)
            panel.nameFieldStringValue = suggested
            if panel.runModal() == .OK, let url = panel.url {
                do {
                    try finalData.write(to: url)
                    DebugLogger.shared.logWebViewAction("💾 FullScreenImageView: Image saved to \(url.path)")
                } catch {
                    DebugLogger.shared.logWebViewAction("❌ FullScreenImageView: Failed to save image - \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func suggestedFileName(for img: HTMLContentExtractor.ExtractedImage) -> String {
        if let url = URL(string: img.url) {
            if url.isFileURL { return url.lastPathComponent }
            let name = url.lastPathComponent
            return name.isEmpty ? "image.jpg" : name
        }
        return "image.jpg"
    }
}

// MARK: - HTML Tab View

struct HTMLTabView: View {
    let html: String
    let css: String
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("HTML Source")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                
                // Copy HTML Button
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(html, forType: .string)
                    print("📋 HTML copied to clipboard")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 12))
                        Text("Copy HTML")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Copy HTML source to clipboard")
            }
            
            // HTML Content (inline CSS if present)
            ScrollView {
                if html.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.html")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No HTML Content Available")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("The HTML content for this article is not available.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    Text(css.isEmpty ? html : "<style>\n\(css)\n</style>\n\n" + html)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .frame(maxHeight: 500)
        }
    }
}

