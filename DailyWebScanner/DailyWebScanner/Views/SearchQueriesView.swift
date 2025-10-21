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
    
    // Calculate database size and image statistics
    private func calculateDatabaseSize() {
        Task {
            var totalSize: Int64 = 0
            var totalImagesSize: Int64 = 0
            
            // Get real database file size
            let databasePath = getDatabasePath()
            let realDatabaseSize = getFileSize(at: databasePath)
            
            // Calculate LinkRecord sizes (approximation)
            for record in linkRecords {
                totalSize += Int64(record.html.count)
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
                // Use real database size if available, otherwise calculated size
                let finalDatabaseSize = realDatabaseSize > 0 ? realDatabaseSize : totalSize
                databaseSize = formatBytes(finalDatabaseSize)
                self.totalImagesSize = formatBytes(totalImagesSize)
                DebugLogger.shared.logWebViewAction("📊 SearchQueriesView: Real DB size: \(formatBytes(realDatabaseSize)), Calculated: \(formatBytes(totalSize)), Images: \(imageRecords.count) (\(self.totalImagesSize))")
            }
        }
    }
    
    // Get the actual database file path
    private func getDatabasePath() -> String {
        let containerURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "de.deusterdevelopment.DailyWebScanner"
        let appContainerURL = containerURL.appendingPathComponent(bundleIdentifier)
        DebugLogger.shared.logWebViewAction("📁 SearchQueriesView: Database path: \(appContainerURL.path)")
        return appContainerURL.path
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
        DebugLogger.shared.logWebViewAction("⚠️ SearchQueriesView: Could not get database file size: Path missing or unreadable")
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
                
                // Article Content
                if !linkRecord.htmlPreview.isEmpty {
                    WebView(html: linkRecord.htmlPreview)
                        .frame(minHeight: 400)
                } else if !linkRecord.content.isEmpty {
                    Text(linkRecord.content)
                        .font(.body)
                        .padding()
                }
                
                // AI Overview if available
                if linkRecord.hasAIOverview && !linkRecord.aiOverviewJSON.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // TODO: Parse and display AI Overview JSON
                        Text("AI Overview content available")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
}

#Preview {
    SearchQueriesView()
        .modelContainer(for: [SearchRecord.self, LinkRecord.self])
}
