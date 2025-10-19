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
                    
                    // AI Overview (if available)
                    if let aiOverview = content.aiOverview {
                        AIOverviewView(aiOverview: aiOverview)
                    }
                    
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
        .frame(minWidth: 600, minHeight: 500)
        .frame(maxWidth: 1000, maxHeight: 800)
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
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
                // WebView with proper sizing (block external links)
                WebView(html: html, allowExternalLinks: false)
                    .frame(minWidth: 800, minHeight: 600)
        }
        .frame(minWidth: 800, minHeight: 700)
        .frame(maxWidth: 1200, maxHeight: 900)
    }
}

struct AIOverviewView: View {
    let aiOverview: AIOverview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("AI Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(aiOverview.textBlocks.count) blocks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Thumbnail if available
            if let thumbnail = aiOverview.thumbnail, !thumbnail.isEmpty {
                AsyncImage(url: URL(string: thumbnail)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 100)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(aiOverview.textBlocks.enumerated()), id: \.offset) { index, block in
                    AITextBlockView(block: block, index: index)
                }
            }
            
            // References if available
            if let references = aiOverview.references, !references.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("References")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    ForEach(references, id: \.index) { reference in
                        AIReferenceView(reference: reference)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AITextBlockView: View {
    let block: AITextBlock
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let snippet = block.snippet {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snippet)
                        .font(.body)
                        .lineSpacing(2)
                    
                    // Show highlighted words if available
                    if let highlightedWords = block.snippetHighlightedWords, !highlightedWords.isEmpty {
                        HStack {
                            Text("Key points:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(highlightedWords, id: \.self) { word in
                                Text(word)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow.opacity(0.3))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    // Show reference indexes if available
                    if let referenceIndexes = block.referenceIndexes, !referenceIndexes.isEmpty {
                        HStack {
                            Text("References:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(referenceIndexes, id: \.self) { refIndex in
                                Text("[\(refIndex)]")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                    }
                }
            }
            
            if let list = block.list, !list.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(list.enumerated()), id: \.offset) { listIndex, item in
                        AIListItemView(item: item, listIndex: listIndex)
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AIListItemView: View {
    let item: AIListItem
    let listIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(listIndex + 1).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text(item.snippet)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            if let snippetLinks = item.snippetLinks, !snippetLinks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(snippetLinks.enumerated()), id: \.offset) { linkIndex, link in
                        HStack {
                            Image(systemName: "link")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text(link.text)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .underline()
                            
                            Spacer()
                        }
                        .onTapGesture {
                            if let url = URL(string: link.link) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
    }
}

struct AIReferenceView: View {
    let reference: AIReference
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("[\(reference.index)]")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                
                Text(reference.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Spacer()
            }
            
            Text(reference.snippet)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(reference.source)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Button("Open") {
                    if let url = URL(string: reference.link) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    LinkContentView(linkContents: [])
}
