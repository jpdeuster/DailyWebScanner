import SwiftUI
import SwiftData
// HTML-Rendering entfernt

struct LinkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newTagName: String = ""
    let linkRecord: LinkRecord
    // HTML-Rendering entfernt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header mit Metadaten
            VStack(alignment: .leading, spacing: 12) {
                Text(linkRecord.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                // Metadaten
                VStack(alignment: .leading, spacing: 8) {
                    if let author = linkRecord.author {
                        HStack {
                            Image(systemName: "person")
                            Text(author)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let publishDate = linkRecord.publishDate {
                        HStack {
                            Image(systemName: "calendar")
                            Text(publishDate.formatted(date: .complete, time: .shortened))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "text.alignleft")
                        Text("\(linkRecord.wordCount) words • \(linkRecord.readingTime) min read")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    if linkRecord.imageCount > 0 {
                        HStack {
                            Image(systemName: "photo")
                            Text("\(linkRecord.imageCount) images")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("Fetched: \(linkRecord.fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            
            // AI Overview falls vorhanden
            if linkRecord.hasAIOverview {
                AIOverviewSection(linkRecord: linkRecord)
            }
            
            // Artikel-Inhalt (Vorschau) – Plain Text
            VStack(alignment: .leading, spacing: 12) {
                Text("Article Preview")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    Text(linkRecord.extractedText.isEmpty ? linkRecord.content : linkRecord.extractedText)
                        .font(.body)
                        .lineSpacing(6)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 300)
            }
            
            // Tags Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                    .padding(.horizontal)
                
                // Current tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(linkRecord.tags) { tag in
                            HStack(spacing: 4) {
                                Image(systemName: "tag")
                                Text(tag.name)
                                Button {
                                    if let idx = linkRecord.tags.firstIndex(where: { $0.id == tag.id }) {
                                        linkRecord.tags.remove(at: idx)
                                        try? modelContext.save()
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15) as Color)
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    TextField("Add tag (press Return)", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            let tag = TagManager.getOrCreate(name: name, in: modelContext)
                            if !linkRecord.tags.contains(where: { $0.id == tag.id }) {
                                linkRecord.tags.append(tag)
                                try? modelContext.save()
                            }
                            newTagName = ""
                        }
                    Button("Add") {
                        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        let tag = TagManager.getOrCreate(name: name, in: modelContext)
                        if !linkRecord.tags.contains(where: { $0.id == tag.id }) {
                            linkRecord.tags.append(tag)
                            try? modelContext.save()
                        }
                        newTagName = ""
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            
            // Buttons
            HStack {
                Button("Open Original") {
                    if let url = URL(string: linkRecord.originalUrl) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("Article Details")
        // HTML-Ansicht entfernt
    }
}

struct AIOverviewSection: View {
    let linkRecord: LinkRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("AI Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            if let aiOverviewJSON = linkRecord.aiOverviewJSON.data(using: .utf8),
               let aiOverview = try? JSONDecoder().decode(AIOverview.self, from: aiOverviewJSON) {
                AIOverviewView(aiOverview: aiOverview)
                    .padding(.horizontal)
            } else {
                Text("AI Overview data not available")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// FullArticleView entfernt (kein HTML-Rendering mehr)

#Preview {
    LinkDetailView(linkRecord: LinkRecord(
        searchRecordId: UUID(),
        originalUrl: "https://example.com",
        title: "Sample Article",
        content: "This is a sample article content...",
        author: "John Doe",
        publishDate: Date(),
        articleDescription: "A sample article description",
        keywords: "sample, article, test",
        language: "en",
        wordCount: 150,
        readingTime: 2,
        imageCount: 3,
        totalImageSize: 1024000,
        hasAIOverview: false,
        aiOverviewJSON: "",
        hasContentAnalysis: false,
        contentAnalysisJSON: ""
    ))
}
