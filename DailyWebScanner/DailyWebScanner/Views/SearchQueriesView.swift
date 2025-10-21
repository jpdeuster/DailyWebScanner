import SwiftUI
import SwiftData

struct SearchQueriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var linkRecords: [LinkRecord]
    
    @State private var selectedLinkRecord: LinkRecord?
    @State private var filterText: String = ""
    
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
                    ForEach(filteredLinkRecords) { record in
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
        }
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
