import Foundation

class HTMLPreviewGenerator {
    
    static func generatePreview(for linkRecord: LinkRecord) -> String {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escape(linkRecord.title))</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f8f9fa;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    border-radius: 12px;
                    margin-bottom: 30px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                }
                .title {
                    font-size: 2.2em;
                    font-weight: 700;
                    margin: 0 0 15px 0;
                    line-height: 1.2;
                }
                .metadata {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 20px;
                    font-size: 0.9em;
                    opacity: 0.9;
                }
                .metadata-item {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                .content {
                    background: white;
                    padding: 30px;
                    border-radius: 12px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    margin-bottom: 30px;
                }
                .ai-overview {
                    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                    color: white;
                    padding: 25px;
                    border-radius: 12px;
                    margin-bottom: 30px;
                }
                .ai-overview h3 {
                    margin: 0 0 15px 0;
                    font-size: 1.4em;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }
                .ai-text-block {
                    background: rgba(255,255,255,0.1);
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 15px;
                }
                .ai-highlighted-words {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 8px;
                    margin-top: 10px;
                }
                .highlight-tag {
                    background: rgba(255,255,255,0.2);
                    padding: 4px 8px;
                    border-radius: 4px;
                    font-size: 0.8em;
                }
                .references {
                    background: #e3f2fd;
                    padding: 25px;
                    border-radius: 12px;
                    margin-bottom: 30px;
                }
                .references h3 {
                    margin: 0 0 15px 0;
                    color: #1976d2;
                }
                .reference-item {
                    background: white;
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 10px;
                    border-left: 4px solid #1976d2;
                }
                .reference-title {
                    font-weight: 600;
                    color: #1976d2;
                    margin-bottom: 5px;
                }
                .reference-source {
                    font-size: 0.8em;
                    color: #666;
                    background: #f5f5f5;
                    padding: 4px 8px;
                    border-radius: 4px;
                    display: inline-block;
                }
                .images-section {
                    background: white;
                    padding: 25px;
                    border-radius: 12px;
                    margin-bottom: 30px;
                }
                .image-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 15px;
                    margin-top: 15px;
                }
                .image-item {
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    overflow: hidden;
                }
                .image-item img {
                    width: 100%;
                    height: 150px;
                    object-fit: cover;
                }
                .image-caption {
                    padding: 10px;
                    font-size: 0.9em;
                    color: #666;
                }
                .footer {
                    text-align: center;
                    color: #666;
                    font-size: 0.9em;
                    margin-top: 30px;
                    padding: 20px;
                    border-top: 1px solid #eee;
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1 class="title">\(escape(linkRecord.title))</h1>
                <div class="metadata">
                    \(generateMetadataHTML(for: linkRecord))
                </div>
            </div>
            
            \(generateAIOverviewHTML(for: linkRecord))
            
            <div class="content">
                <h2>Article Content</h2>
                <div class="article-text">
                    \(linkRecord.content)
                </div>
            </div>
            
            \(generateImagesHTML(for: linkRecord))
            
            <div class="footer">
                <p>Fetched on \(formatDate(linkRecord.fetchedAt)) | 
                   \(linkRecord.wordCount) words | 
                   \(linkRecord.readingTime) min read</p>
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    private static func generateMetadataHTML(for linkRecord: LinkRecord) -> String {
        var metadata = ""
        
        if let author = linkRecord.author {
            metadata += "<div class=\"metadata-item\">👤 \(escape(author))</div>"
        }
        
        if let publishDate = linkRecord.publishDate {
            metadata += "<div class=\"metadata-item\">📅 \(formatDate(publishDate))</div>"
        }
        
        if let language = linkRecord.language, !language.isEmpty {
            metadata += "<div class=\"metadata-item\">🌐 \(escape(language))</div>"
        }
        
        metadata += "<div class=\"metadata-item\">📊 \(linkRecord.wordCount) words</div>"
        metadata += "<div class=\"metadata-item\">⏱️ \(linkRecord.readingTime) min read</div>"
        
        if linkRecord.imageCount > 0 {
            metadata += "<div class=\"metadata-item\">🖼️ \(linkRecord.imageCount) images</div>"
        }
        
        return metadata
    }
    
    private static func generateAIOverviewHTML(for linkRecord: LinkRecord) -> String {
        guard linkRecord.hasAIOverview, !linkRecord.aiOverviewJSON.isEmpty else {
            return ""
        }
        
        // Parse AI Overview JSON and generate HTML
        // This would need to be implemented based on the AIOverview structure
        
        return """
        <div class="ai-overview">
            <h3>🧠 AI Overview</h3>
            <div class="ai-text-block">
                <p>AI-generated summary and insights about this article.</p>
            </div>
        </div>
        """
    }
    
    private static func generateImagesHTML(for linkRecord: LinkRecord) -> String {
        guard linkRecord.imageCount > 0 else {
            return ""
        }
        
        return """
        <div class="images-section">
            <h3>🖼️ Images (\(linkRecord.imageCount))</h3>
            <div class="image-grid">
                <div class="image-item">
                    <img src="placeholder.jpg" alt="Article image">
                    <div class="image-caption">Images from the article</div>
                </div>
            </div>
        </div>
        """
    }
    
    private static func escape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
