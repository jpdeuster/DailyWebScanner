import SwiftUI
import SwiftData

struct LinkListView: View {
    @Query private var linkRecords: [LinkRecord]
    @State private var selectedLink: LinkRecord?
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .newest
    
    enum SortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case title = "Title A-Z"
        case author = "Author"
    }
    
    var filteredAndSortedLinks: [LinkRecord] {
        var links = linkRecords
        
        // Filter by search text
        if !searchText.isEmpty {
            links = links.filter { link in
                link.title.localizedCaseInsensitiveContains(searchText) ||
                link.content.localizedCaseInsensitiveContains(searchText) ||
                (link.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort
        switch sortOrder {
        case .newest:
            links.sort { $0.fetchedAt > $1.fetchedAt }
        case .oldest:
            links.sort { $0.fetchedAt < $1.fetchedAt }
        case .title:
            links.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:
            links.sort { 
                let author1 = $0.author ?? ""
                let author2 = $1.author ?? ""
                return author1.localizedCaseInsensitiveCompare(author2) == .orderedAscending
            }
        }
        
        return links
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search and Sort Controls
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search articles...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Sort Order", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 150)
                        
                        Spacer()
                        
                        Text("\(filteredAndSortedLinks.count) articles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                // Links List
                if filteredAndSortedLinks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No articles found" : "No articles match your search")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("Start a search to see articles here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredAndSortedLinks, selection: $selectedLink) { link in
                        LinkRowView(link: link)
                            .tag(link)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Articles")
            .navigationSplitViewColumnWidth(min: 300, ideal: 400)
        } detail: {
            if let selectedLink = selectedLink {
                LinkDetailView(linkRecord: selectedLink)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Select an article to view details")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose an article from the sidebar to see its content, AI overview, and metadata")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct LinkRowView: View {
    let link: LinkRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(link.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Author and Date
            HStack {
                if let author = link.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(link.fetchedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Content Preview
            Text(link.content)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            // Metadata
            HStack {
                // Reading time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(link.readingTime) min")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Word count
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                    Text("\(link.wordCount) words")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Images
                if link.imageCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.caption)
                        Text("\(link.imageCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // AI Overview indicator
                if link.hasAIOverview {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                        Text("AI")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LinkListView()
        .modelContainer(for: [LinkRecord.self])
}
