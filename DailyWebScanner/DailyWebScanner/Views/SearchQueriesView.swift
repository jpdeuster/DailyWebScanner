import SwiftUI
import SwiftData

struct SearchQueriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var linkRecords: [LinkRecord]
    @Query private var imageRecords: [ImageRecord]
    @State private var selectedLinkRecord: LinkRecord?
    @State private var filterText: String = ""
    @State private var databaseSize: String = "Calculating..."
    @State private var totalImagesSize: String = "Calculating..."
    
    // Computed property for filtered link records (alphabetically sorted)
    private var filteredLinkRecords: [LinkRecord] {
        let records = if filterText.isEmpty {
            linkRecords
        } else {
            linkRecords.filter { record in
                record.title.localizedCaseInsensitiveContains(filterText) ||
                record.content.localizedCaseInsensitiveContains(filterText) ||
                (record.author?.localizedCaseInsensitiveContains(filterText) ?? false) ||
                (record.language?.localizedCaseInsensitiveContains(filterText) ?? false)
            }
        }
        return records.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Article Links")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(filteredLinkRecords.count) articles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HelpButton(urlString: "https://github.com/jpdeuster/DailyWebScanner#readme")
                }
                .padding()
                
                Divider()
                
                // Filter Section
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Filter articles...", text: $filterText)
                        .textFieldStyle(.plain)
                        .onChange(of: filterText) { _, _ in
                            // Filter will be applied automatically via computed property
                        }
                    
                    if !filterText.isEmpty {
                        Button(action: {
                            filterText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                
                // Link Records List
                List(selection: $selectedLinkRecord) {
                    ForEach(filteredLinkRecords.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) { record in
                        NavigationLink(value: record) {
                            VStack(alignment: .leading, spacing: 4) {
                                ArticleLinkRow(record: record) {
                                    deleteLinkRecord(record)
                                }
                                
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteLinkRecord(record)
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
            if let linkRecord = selectedLinkRecord {
                // Use EnhancedArticleView for better display
                EnhancedArticleView(linkRecord: linkRecord, searchRecord: nil)
                    .onAppear {
                        DebugLogger.shared.logWebViewAction("🔍 DEBUG: Selected Article")
                        DebugLogger.shared.logWebViewAction("📱 SearchQueriesView: Detail view appeared for LinkRecord '\(linkRecord.title)' (ID: \(linkRecord.id))")
                        DebugLogger.shared.logWebViewAction("📊 SearchQueriesView: LinkRecord has \(linkRecord.images.count) images")
                    }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Select an Article")
                    .font(.title)
                        .foregroundColor(.primary)
                    
                    Text("Choose an article from the sidebar to view its content")
                        .font(.body)
                    .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            }
        }
        .onAppear {
            DebugLogger.shared.logWebViewAction("SearchQueriesView appeared - linkRecords count: \(linkRecords.count)")
            calculateDatabaseSize()
        }
        .safeAreaInset(edge: .bottom) {
            // Enhanced Database Status Bar
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
                
                HStack(spacing: 20) {
                    // Database Size
                    HStack(spacing: 6) {
                        Image(systemName: "externaldrive.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Database:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(databaseSize)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Articles Count
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Articles:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(linkRecords.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Images Count & Size
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Images:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(imageRecords.count) (\(totalImagesSize))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    // ManualSearchRecord Count
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("Manual Searches:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(manualCount())")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    // SearchResult Count
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                            .font(.caption)
                            .foregroundColor(.brown)
                        Text("Results:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(searchResultCount())")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Refresh Button
                    Button(action: {
                        calculateDatabaseSize()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Refresh")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh database statistics")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
            }
        }
    }
    
    private func manualCount() -> Int {
        (try? modelContext.fetch(FetchDescriptor<ManualSearchRecord>())).map { $0.count } ?? 0
    }
    private func searchResultCount() -> Int {
        (try? modelContext.fetch(FetchDescriptor<SearchResult>())).map { $0.count } ?? 0
    }
    
    // Calculate database size and image statistics
    private func calculateDatabaseSize() {
        Task {
            var totalSize: Int64 = 0
            var totalImagesSize: Int64 = 0
            
            // Resolve app support directory and default.store file
            let (appSupportDir, defaultStoreFile) = getDatabasePaths()
            let realDatabaseSizeDir = getFileSize(at: appSupportDir)
            let fm = FileManager.default
            let appSupportExists = fm.fileExists(atPath: appSupportDir)
            DebugLogger.shared.logWebViewAction("📁 SearchQueriesView: AppSupport exists=\(appSupportExists) path=\(appSupportDir)")
            let defaultStoreExists = fm.fileExists(atPath: defaultStoreFile)
            if !defaultStoreExists {
                DebugLogger.shared.logWebViewAction("ℹ️ SearchQueriesView: default.store not found (fresh DB or different backend). path=\(defaultStoreFile)")
            }
            let realDatabaseSizeFile: Int64 = defaultStoreExists ? getFileSize(at: defaultStoreFile) : 0
            let realDatabaseSize = realDatabaseSizeDir > 0 ? realDatabaseSizeDir : realDatabaseSizeFile

            // Discover actual SwiftData store files (store/sqlite + WAL/SHM) as a robust fallback
            let discoveredFiles = discoverSwiftDataStoreFiles(preferredDirPath: appSupportDir)
            let discoveredSize = sumFileSizes(discoveredFiles)
            // Log discovered files (limit to first 10 for readability)
            if !discoveredFiles.isEmpty {
                let preview = discoveredFiles.prefix(10).map { url -> String in
                    let size = (try? fm.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
                    return "\(url.lastPathComponent)=\(formatBytes(Int64(size)))"
                }.joined(separator: ", ")
                DebugLogger.shared.logWebViewAction("🔎 SearchQueriesView: Discovered store files (\(discoveredFiles.count)): [\(preview)\(discoveredFiles.count > 10 ? ", …" : "")] ")
            } else {
                DebugLogger.shared.logWebViewAction("🔎 SearchQueriesView: No store files discovered in preferred bases (fresh install?)")
            }
            let effectiveDatabaseSize = max(realDatabaseSize, discoveredSize)
            
            // Calculate LinkRecord sizes (approximation)
            for record in linkRecords {
                // HTML entfernt
                totalSize += Int64(record.extractedText.count)
                totalSize += Int64(record.extractedLinksJSON.count)
                totalSize += Int64(record.extractedVideosJSON.count)
                totalSize += Int64(record.extractedMetadataJSON.count)
                totalSize += Int64(record.content.count)
                totalSize += Int64(record.title.count)
                totalSize += Int64(record.originalUrl.count)
            }
            
            // Calculate ImageRecord sizes (local files)
            for image in imageRecords {
                totalImagesSize += Int64(image.fileSize)
                totalSize += Int64(image.fileSize)
            }
            
            await MainActor.run {
                // Use real/discovered database size if available, otherwise calculated size
                let finalDatabaseSize = effectiveDatabaseSize > 0 ? effectiveDatabaseSize : totalSize
                databaseSize = formatBytes(finalDatabaseSize)
                self.totalImagesSize = formatBytes(totalImagesSize)
                DebugLogger.shared.logWebViewAction("📊 SearchQueriesView: AppSupport=\(appSupportDir), default.store=\(defaultStoreFile)")
                DebugLogger.shared.logWebViewAction("📊 SearchQueriesView: Real DB size (dir/file): \(formatBytes(realDatabaseSizeDir))/\(formatBytes(realDatabaseSizeFile)), Discovered: \(formatBytes(discoveredSize)), Calculated: \(formatBytes(totalSize)), Images: \(imageRecords.count) (\(self.totalImagesSize))")
            }
        }
    }
    
    // Get App Support directory for bundle and default.store file path; ensure directory exists
    private func getDatabasePaths() -> (dirPath: String, storeFilePath: String) {
        let fm = FileManager.default
        let baseURL: URL
        if let url = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            baseURL = url
        } else {
            baseURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        }
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "de.deusterdevelopment.DailyWebScanner"
        let appSupportURL = baseURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
        // Ensure directory exists
        if !fm.fileExists(atPath: appSupportURL.path) {
            try? fm.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }
        let storeURL = appSupportURL.appendingPathComponent("default.store")
        return (appSupportURL.path, storeURL.path)
    }
    
    // Discover SwiftData store-related files (.store/.sqlite and WAL/SHM companions) in preferred dir and fallbacks
    private func discoverSwiftDataStoreFiles(preferredDirPath: String) -> [URL] {
        let fm = FileManager.default
        var candidates: Set<URL> = []
        let preferredDir = URL(fileURLWithPath: preferredDirPath)
        let appSupportBase = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)) ?? preferredDir.deletingLastPathComponent()
        let searchBases: [URL] = [preferredDir, appSupportBase]
        let suffixes = [
            ".store", ".sqlite", ".store-wal", ".store-shm", ".sqlite-wal", ".sqlite-shm"
        ]
        for base in searchBases {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: base.path, isDirectory: &isDir), isDir.boolValue else { continue }
            if let enumerator = fm.enumerator(at: base, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    let name = fileURL.lastPathComponent.lowercased()
                    if suffixes.contains(where: { name.hasSuffix($0) }) {
                        candidates.insert(fileURL)
                    }
                }
            }
        }
        return Array(candidates)
    }

    private func sumFileSizes(_ urls: [URL]) -> Int64 {
        let fm = FileManager.default
        var total: Int64 = 0
        for u in urls {
            do {
                let attrs = try fm.attributesOfItem(atPath: u.path)
                if let s = attrs[.size] as? NSNumber { total += s.int64Value }
            } catch { continue }
        }
        return total
    }

    // Get total size of directory or single file in bytes
    private func getFileSize(at path: String) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                // Sum all files in directory (e.g., default.store, .wal, .shm)
                let url = URL(fileURLWithPath: path)
                if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey], options: [.skipsHiddenFiles]) {
                    var total: Int64 = 0
                    for case let fileURL as URL in enumerator {
                        do {
                            let res = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                            if res.isRegularFile == true, let fs = res.fileSize { total += Int64(fs) }
                        } catch { continue }
                    }
                    return total
                }
            } else {
                do {
                    let attributes = try fm.attributesOfItem(atPath: path)
                    if let fileSize = attributes[.size] as? NSNumber { return fileSize.int64Value }
                } catch { }
            }
        }
        DebugLogger.shared.logWebViewAction("ℹ️ SearchQueriesView: Could not get size for path (missing/unreadable): \(path)")
        return 0
    }
    
    // Format bytes to human readable string
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func deleteLinkRecord(_ record: LinkRecord) {
        // Clear selection if the deleted record is currently selected
        if selectedLinkRecord?.id == record.id {
            selectedLinkRecord = nil
        }
        
        modelContext.delete(record)
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("LinkRecord deleted: \(record.title)")
        } catch {
            DebugLogger.shared.logWebViewAction("Failed to delete LinkRecord: \(error.localizedDescription)")
        }
    }
}

struct ArticleLinkRow: View {
    let record: LinkRecord
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(record.fetchedAt, format: .dateTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Article Metadata als Tags
            HStack {
                if let author = record.author, !author.isEmpty {
                    ParameterTag(label: "Author", value: author)
                }
                if let language = record.language, !language.isEmpty {
                    ParameterTag(label: "Lang", value: language)
                }
                ParameterTag(label: "Words", value: "\(record.wordCount)")
                ParameterTag(label: "Read", value: "\(record.readingTime)min")
                if record.imageCount > 0 {
                    ParameterTag(label: "Images", value: "\(record.imageCount)")
                }
            }
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Delete article")
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

struct ArticleLinkDetailView: View {
    let linkRecord: LinkRecord
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Article Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(linkRecord.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let author = linkRecord.author, !author.isEmpty {
                        Text("By \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let publishDate = linkRecord.publishDate {
                        Text("Published: \(publishDate, format: .dateTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Article Metadata
                    HStack {
                        ParameterTag(label: "Words", value: "\(linkRecord.wordCount)")
                        ParameterTag(label: "Read", value: "\(linkRecord.readingTime)min")
                        if linkRecord.imageCount > 0 {
                            ParameterTag(label: "Images", value: "\(linkRecord.imageCount)")
                        }
                        if let language = linkRecord.language, !language.isEmpty {
                            ParameterTag(label: "Lang", value: language)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                
                // Article Content (Plain Text)
                let textToShow = linkRecord.extractedText.isEmpty ? linkRecord.content : linkRecord.extractedText
                Text(textToShow)
                    .font(.body)
                    .lineSpacing(6)
                    .padding()
                
                // AI Overview if available
                if linkRecord.hasAIOverview && !linkRecord.aiOverviewJSON.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let overview = decodeAIOverview(linkRecord.aiOverviewJSON) {
                            if !overview.summary.isEmpty {
                                Text(overview.summary)
                                    .font(.body)
                            }
                            if !overview.keyPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(overview.keyPoints, id: \.self) { p in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•").foregroundColor(.blue)
                                            Text(p).font(.subheadline)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                            if let confidence = overview.confidence {
                                Text(String(format: "Confidence: %.0f%%", confidence * 100))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                        Text("AI Overview content available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Article Details")
    }
    
    // MARK: - AI Overview Decoder
    private struct AIOverview: Codable {
        let summary: String
        let keyPoints: [String]
        let confidence: Double?
    }
    private func decodeAIOverview(_ json: String) -> AIOverview? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AIOverview.self, from: data)
    }
}

#Preview {
    SearchQueriesView()
        .modelContainer(for: [SearchRecord.self, LinkRecord.self])
}
