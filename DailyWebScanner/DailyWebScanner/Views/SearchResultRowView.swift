import SwiftUI

/// Beautiful row view for search results with enhanced information display
struct SearchResultRowView: View {
    let result: SearchResult
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Result Icon
            Image(systemName: "link.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(result.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Snippet
                if !result.snippet.isEmpty {
                    Text(result.snippet)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // URL and Metadata
                HStack(spacing: 12) {
                    // URL
                    Button(action: {
                        if let url = URL(string: result.link) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.caption2)
                            Text(result.link)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // AI Summary Badge
                    if !result.summary.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption2)
                            Text("AI Summary")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                if let url = URL(string: result.link) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.blue.opacity(0.05) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
