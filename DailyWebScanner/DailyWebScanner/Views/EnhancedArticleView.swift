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
    
    enum ArticleTab: String, CaseIterable {
        case content = "Text View"
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
                            ContentTabView(content: extractedContent)
                        case .images:
                            ImagesTabView(
                                images: extractedContent?.images ?? [],
                                showFullImage: $showFullImage,
                                selectedImageIndex: $selectedImageIndex
                            )
                        case .videos:
                            VideosTabView(videos: extractedContent?.videos ?? [])
                        case .links:
                            LinksTabView(links: extractedContent?.links ?? [])
                        case .metadata:
                            MetadataTabView(metadata: extractedContent?.metadata)
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
            
            // Reload content for new article
            Task {
                await loadContent()
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
            
            let extractor = HTMLContentExtractor()
            let content = await extractor.extractContent(
                from: htmlContent,
                baseURL: linkRecord.originalUrl
            )
            
            await MainActor.run {
                self.extractedContent = content
                self.isLoading = false
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
    
    var body: some View {
        ScrollView {
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
                                pasteboard.clearContents()
                                pasteboard.setString(content.mainText, forType: .string)
                                print("📋 Text copied to clipboard: \(content.mainText.prefix(50))...")
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
                        
                        ScrollView {
                            Text(content.mainText)
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
                        .frame(maxHeight: 400) // Begrenzte Höhe für bessere UX
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
        }
    }
}

struct ImageCardView: View {
    let image: HTMLContentExtractor.ExtractedImage
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder (in real implementation, load actual image)
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
                .onTapGesture {
                    onTap()
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
                        .lineLimit(1)
                }
                
                if let width = image.width, let height = image.height {
                    Text("\(width) × \(height)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if image.isMainImage {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Main Image")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
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
            
            // Image display (simplified)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text(images[selectedIndex].alt)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
    }
}

