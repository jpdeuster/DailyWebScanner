import SwiftUI

struct LinkContentView: View {
    let linkContents: [LinkContent]
    @State private var selectedContent: LinkContent?
    @State private var showingContentDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Link Contents")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(linkContents.count) articles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if linkContents.isEmpty {
                Text("No link contents available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // Content List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(linkContents.enumerated()), id: \.offset) { index, content in
                            LinkContentCard(
                                content: content,
                                index: index + 1,
                                onTap: {
                                    selectedContent = content
                                    showingContentDetail = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .sheet(isPresented: $showingContentDetail) {
            if let content = selectedContent {
                LinkContentDetailView(content: content)
            }
        }
    }
}

struct LinkContentCard: View {
    let content: LinkContent
    let index: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(index). \(content.title)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Metadata
                HStack(spacing: 12) {
                    if let author = content.metadata.author {
                        Label(author, systemImage: "person")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let publishDate = content.metadata.publishDate {
                        Label(publishDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(content.metadata.wordCount) words", systemImage: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if content.images.count > 0 {
                        Label("\(content.images.count) images", systemImage: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Preview text
                Text(content.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LinkContentDetailView: View {
    let content: LinkContent
    @Environment(\.dismiss) private var dismiss
    @State private var showingWebView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(content.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            if let author = content.metadata.author {
                                HStack {
                                    Image(systemName: "person")
                                    Text(author)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            
                            if let publishDate = content.metadata.publishDate {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text(publishDate.formatted(date: .complete, time: .shortened))
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "text.alignleft")
                                Text("\(content.metadata.wordCount) words • \(content.metadata.readingTime) min read")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            if content.images.count > 0 {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("\(content.images.count) images")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(12)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Article Content")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(content.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
                    .cornerRadius(12)
                    
                    // Images
                    if !content.images.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Images (\(content.images.count))")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 150))
                            ], spacing: 12) {
                                ForEach(Array(content.images.enumerated()), id: \.offset) { index, image in
                                    ImageView(image: image)
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button("View Original") {
                            if let url = URL(string: content.url) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("View HTML") {
                            showingWebView = true
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Article Content")
        }
        .sheet(isPresented: $showingWebView) {
            HTMLViewerView(html: content.html, title: content.title)
        }
    }
}

struct ImageView: View {
    let image: ImageData
    @State private var imageData: Data?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = image.data, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("Image not available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .cornerRadius(8)
            }
            
            if let altText = image.altText, !altText.isEmpty {
                Text(altText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let width = image.width, let height = image.height {
                Text("\(width) × \(height)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct HTMLViewerView: View {
    let html: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            WebView(html: html)
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    LinkContentView(linkContents: [])
}
