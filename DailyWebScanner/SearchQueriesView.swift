import SwiftUI
import SwiftData

struct SearchQueriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LinkRecord.fetchedAt, order: .reverse)
    private var linkRecords: [LinkRecord]
    
    @State private var selectedLinkRecord: LinkRecord?
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Article Links")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(linkRecords.count) articles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Link Records List
                List(selection: $selectedLinkRecord) {
                    ForEach(linkRecords) { record in
                        NavigationLink(value: record) {
                            ArticleLinkRow(record: record)
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
                ArticleLinkDetailView(linkRecord: linkRecord)
            } else {
                Text("Select an article from the sidebar")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            DebugLogger.shared.logWebViewAction("SearchQueriesView appeared - linkRecords count: \(linkRecords.count)")
        }
    }
    
    private func deleteLinkRecord(_ record: LinkRecord) {
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
    
    var body: some View {
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
