import SwiftUI
import WebKit

struct LinkDetailView: View {
    let linkRecord: LinkRecord
    @State private var showingFullArticle = false
    
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
            
            // Artikel-Inhalt (Vorschau)
            VStack(alignment: .leading, spacing: 12) {
                Text("Article Preview")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    Text(linkRecord.content)
                        .font(.body)
                        .lineSpacing(4)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 300)
            }
            
            // Buttons
            HStack {
                Button("View Full Article") {
                    showingFullArticle = true
                }
                .buttonStyle(.borderedProminent)
                
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
        .sheet(isPresented: $showingFullArticle) {
            FullArticleView(linkRecord: linkRecord)
        }
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

struct FullArticleView: View {
    let linkRecord: LinkRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            WebView(html: linkRecord.htmlPreview, allowExternalLinks: false)
                .navigationTitle(linkRecord.title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
        .frame(minWidth: 800, minHeight: 700)
    }
}

#Preview {
    LinkDetailView(linkRecord: LinkRecord(
        searchRecordId: UUID(),
        originalUrl: "https://example.com",
        title: "Sample Article",
        content: "This is a sample article content...",
        html: "<html><body>Sample HTML</body></html>",
        css: "body { font-family: Arial; }",
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
        contentAnalysisJSON: "",
        htmlPreview: "<html><body>Sample preview</body></html>"
    ))
}
