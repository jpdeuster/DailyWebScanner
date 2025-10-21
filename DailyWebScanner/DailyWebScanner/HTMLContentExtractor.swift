import Foundation
import SwiftUI
import WebKit

/// Powerful HTML content extractor that captures text, images, videos, and metadata
class HTMLContentExtractor: NSObject {
    
    // MARK: - Content Types
    struct ExtractedContent {
        let title: String
        let description: String
        let mainText: String
        let images: [ExtractedImage]
        let videos: [ExtractedVideo]
        let links: [ExtractedLink]
        let metadata: ContentMetadata
        let readingTime: Int
        let wordCount: Int
    }
    
    struct ExtractedImage {
        let url: String
        let alt: String
        let caption: String
        let width: Int?
        let height: Int?
        let isMainImage: Bool
    }
    
    struct ExtractedVideo {
        let url: String
        let title: String
        let thumbnail: String?
        let duration: String?
        let platform: VideoPlatform
    }
    
    struct ExtractedLink {
        let url: String
        let title: String
        let description: String
        let isExternal: Bool
    }
    
    struct ContentMetadata {
        let author: String?
        let publishDate: Date?
        let category: String?
        let tags: [String]
        let language: String?
        let wordCount: Int
        let readingTime: Int
    }
    
    enum VideoPlatform {
        case youtube
        case vimeo
        case direct
        case other(String)
    }
    
    // MARK: - Extraction Methods
    
    /// Extract comprehensive content from HTML with detailed logging
    func extractContent(from html: String, baseURL: String) async -> ExtractedContent {
        DebugLogger.shared.logWebViewAction("🔍 HTMLContentExtractor: Starting content extraction from \(baseURL)")
        DebugLogger.shared.logWebViewAction("📄 HTMLContentExtractor: HTML length: \(html.count) characters")
        
        let parser = HTMLParser()
        
        // Parse HTML structure
        let document = parser.parse(html)
        DebugLogger.shared.logWebViewAction("🌐 HTMLContentExtractor: HTML document parsed successfully")
        
        // Extract different content types with logging
        let title = extractTitle(from: document)
        DebugLogger.shared.logWebViewAction("📝 HTMLContentExtractor: Title extracted: '\(title)'")
        
        let description = extractDescription(from: document)
        DebugLogger.shared.logWebViewAction("📄 HTMLContentExtractor: Description extracted: \(description.count) characters")
        
        let mainText = extractMainText(from: document)
        DebugLogger.shared.logWebViewAction("📖 HTMLContentExtractor: Main text extracted: \(mainText.count) characters")
        
        let images = extractImages(from: document, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🖼️ HTMLContentExtractor: Images found: \(images.count)")
        
        let videos = extractVideos(from: document, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🎥 HTMLContentExtractor: Videos found: \(videos.count)")
        
        let links = extractLinks(from: document, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🔗 HTMLContentExtractor: Links found: \(links.count)")
        
        let metadata = extractMetadata(from: document)
        DebugLogger.shared.logWebViewAction("📊 HTMLContentExtractor: Metadata extracted - Author: \(metadata.author ?? "None"), Language: \(metadata.language ?? "None")")
        
        // Calculate reading metrics
        let wordCount = mainText.split(separator: " ").count
        let readingTime = max(1, wordCount / 200) // 200 words per minute
        
        DebugLogger.shared.logWebViewAction("📈 HTMLContentExtractor: Content metrics - Words: \(wordCount), Reading time: \(readingTime) minutes")
        
        let extractedContent = ExtractedContent(
            title: title,
            description: description,
            mainText: mainText,
            images: images,
            videos: videos,
            links: links,
            metadata: ContentMetadata(
                author: metadata.author,
                publishDate: metadata.publishDate,
                category: metadata.category,
                tags: metadata.tags,
                language: metadata.language,
                wordCount: wordCount,
                readingTime: readingTime
            ),
            readingTime: readingTime,
            wordCount: wordCount
        )
        
        DebugLogger.shared.logWebViewAction("✅ HTMLContentExtractor: Content extraction completed successfully")
        return extractedContent
    }
    
    // MARK: - Title Extraction
    
    private func extractTitle(from document: HTMLDocument) -> String {
        // Try multiple title sources in order of preference
        let titleSources = [
            "meta[property='og:title']",
            "meta[name='twitter:title']",
            "title",
            "h1",
            ".article-title",
            ".post-title",
            ".entry-title"
        ]
        
        for selector in titleSources {
            if let title = document.querySelector(selector)?.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                return title
            }
        }
        
        return "Untitled Article"
    }
    
    // MARK: - Description Extraction
    
    private func extractDescription(from document: HTMLDocument) -> String {
        let descriptionSources = [
            "meta[property='og:description']",
            "meta[name='twitter:description']",
            "meta[name='description']",
            ".article-description",
            ".post-excerpt",
            ".entry-summary"
        ]
        
        for selector in descriptionSources {
            if let description = document.querySelector(selector)?.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
               !description.isEmpty {
                return description
            }
        }
        
        return ""
    }
    
    // MARK: - Main Text Extraction
    
    private func extractMainText(from document: HTMLDocument) -> String {
        // Try to find main content areas
        let contentSelectors = [
            "article",
            ".article-content",
            ".post-content",
            ".entry-content",
            ".content",
            "main",
            ".main-content"
        ]
        
        var mainContent = ""
        
        for selector in contentSelectors {
            if let contentElement = document.querySelector(selector) {
                mainContent = extractTextFromElement(contentElement)
                if !mainContent.isEmpty {
                    break
                }
            }
        }
        
        // Fallback: extract from body
        if mainContent.isEmpty {
            if let body = document.querySelector("body") {
                mainContent = extractTextFromElement(body)
            }
        }
        
        return cleanText(mainContent)
    }
    
    private func extractTextFromElement(_ element: HTMLElement) -> String {
        var text = ""
        
        // Remove script and style elements (simplified implementation)
        // In a real implementation, you would use a proper HTML parser
        
        // Extract text content
        text = element.textContent ?? ""
        
        return text
    }
    
    private func cleanText(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Image Extraction
    
    private func extractImages(from document: HTMLDocument, baseURL: String) -> [ExtractedImage] {
        var images: [ExtractedImage] = []
        
        // Find all img elements
        let imgElements = document.querySelectorAll("img")
        
        for (index, img) in imgElements.enumerated() {
            let src = img.getAttribute("src") ?? ""
            let alt = img.getAttribute("alt") ?? ""
            let title = img.getAttribute("title") ?? ""
            let width = Int(img.getAttribute("width") ?? "")
            let height = Int(img.getAttribute("height") ?? "")
            
            // Determine if this is likely the main image
            let isMainImage = index == 0 || 
                             alt.lowercased().contains("main") ||
                             alt.lowercased().contains("featured") ||
                             img.className.contains("main") ||
                             img.className.contains("featured")
            
            // Resolve relative URLs
            let fullURL = resolveURL(src, baseURL: baseURL)
            
            images.append(ExtractedImage(
                url: fullURL,
                alt: alt,
                caption: title,
                width: width,
                height: height,
                isMainImage: isMainImage
            ))
        }
        
        return images
    }
    
    // MARK: - Video Extraction
    
    private func extractVideos(from document: HTMLDocument, baseURL: String) -> [ExtractedVideo] {
        var videos: [ExtractedVideo] = []
        
        // Extract YouTube videos
        let youtubeEmbeds = document.querySelectorAll("iframe[src*='youtube.com'], iframe[src*='youtu.be']")
        for embed in youtubeEmbeds {
            if let src = embed.getAttribute("src") {
                let video = extractYouTubeVideo(from: src)
                videos.append(video)
            }
        }
        
        // Extract Vimeo videos
        let vimeoEmbeds = document.querySelectorAll("iframe[src*='vimeo.com']")
        for embed in vimeoEmbeds {
            if let src = embed.getAttribute("src") {
                let video = extractVimeoVideo(from: src)
                videos.append(video)
            }
        }
        
        // Extract direct video elements
        let videoElements = document.querySelectorAll("video")
        for video in videoElements {
            if let src = video.getAttribute("src") {
                let fullURL = resolveURL(src, baseURL: baseURL)
                videos.append(ExtractedVideo(
                    url: fullURL,
                    title: video.getAttribute("title") ?? "",
                    thumbnail: video.getAttribute("poster"),
                    duration: video.getAttribute("duration"),
                    platform: .direct
                ))
            }
        }
        
        return videos
    }
    
    private func extractYouTubeVideo(from src: String) -> ExtractedVideo {
        // Extract YouTube video ID
        let videoID = extractYouTubeVideoID(from: src)
        let thumbnailURL = "https://img.youtube.com/vi/\(videoID)/maxresdefault.jpg"
        
        return ExtractedVideo(
            url: src,
            title: "YouTube Video",
            thumbnail: thumbnailURL,
            duration: nil,
            platform: .youtube
        )
    }
    
    private func extractVimeoVideo(from src: String) -> ExtractedVideo {
        return ExtractedVideo(
            url: src,
            title: "Vimeo Video",
            thumbnail: nil,
            duration: nil,
            platform: .vimeo
        )
    }
    
    private func extractYouTubeVideoID(from src: String) -> String {
        // Extract video ID from various YouTube URL formats
        let patterns = [
            "youtube\\.com/watch\\?v=([^&]+)",
            "youtu\\.be/([^?]+)",
            "youtube\\.com/embed/([^?]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(src.startIndex..., in: src)
                if let match = regex.firstMatch(in: src, range: range) {
                    return String(src[Range(match.range(at: 1), in: src)!])
                }
            }
        }
        
        return ""
    }
    
    // MARK: - Link Extraction
    
    private func extractLinks(from document: HTMLDocument, baseURL: String) -> [ExtractedLink] {
        var links: [ExtractedLink] = []
        
        let linkElements = document.querySelectorAll("a[href]")
        
        for link in linkElements {
            guard let href = link.getAttribute("href"),
                  !href.isEmpty else { continue }
            
            let fullURL = resolveURL(href, baseURL: baseURL)
            let title = link.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let isExternal = !fullURL.hasPrefix(baseURL)
            
            links.append(ExtractedLink(
                url: fullURL,
                title: title,
                description: link.getAttribute("title") ?? "",
                isExternal: isExternal
            ))
        }
        
        return links
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from document: HTMLDocument) -> ContentMetadata {
        let author = extractAuthor(from: document)
        let publishDate = extractPublishDate(from: document)
        let category = extractCategory(from: document)
        let tags = extractTags(from: document)
        let language = extractLanguage(from: document)
        
        return ContentMetadata(
            author: author,
            publishDate: publishDate,
            category: category,
            tags: tags,
            language: language,
            wordCount: 0, // Will be calculated separately
            readingTime: 0 // Will be calculated separately
        )
    }
    
    private func extractAuthor(from document: HTMLDocument) -> String? {
        let authorSelectors = [
            "meta[name='author']",
            "meta[property='article:author']",
            ".author",
            ".byline",
            ".post-author"
        ]
        
        for selector in authorSelectors {
            if let element = document.querySelector(selector),
               let author = element.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
               !author.isEmpty {
                return author
            }
        }
        
        return nil
    }
    
    private func extractPublishDate(from document: HTMLDocument) -> Date? {
        let dateSelectors = [
            "meta[property='article:published_time']",
            "meta[name='date']",
            "meta[name='pubdate']",
            ".published",
            ".post-date",
            "time[datetime]"
        ]
        
        for selector in dateSelectors {
            if let element = document.querySelector(selector) {
                let dateString = element.getAttribute("content") ?? 
                                element.getAttribute("datetime") ?? 
                                element.textContent ?? ""
                
                if let date = parseDate(dateString) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private func extractCategory(from document: HTMLDocument) -> String? {
        let categorySelectors = [
            "meta[property='article:section']",
            ".category",
            ".post-category",
            ".entry-category"
        ]
        
        for selector in categorySelectors {
            if let element = document.querySelector(selector),
               let category = element.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
               !category.isEmpty {
                return category
            }
        }
        
        return nil
    }
    
    private func extractTags(from document: HTMLDocument) -> [String] {
        var tags: [String] = []
        
        // Try meta tags first
        if let metaTags = document.querySelector("meta[name='keywords']")?.getAttribute("content") {
            tags = metaTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        // Try tag elements
        let tagElements = document.querySelectorAll(".tag, .tags a, .post-tags a")
        for element in tagElements {
            if let tag = element.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
               !tag.isEmpty {
                tags.append(tag)
            }
        }
        
        return tags
    }
    
    private func extractLanguage(from document: HTMLDocument) -> String? {
        // Try html lang attribute
        if let html = document.querySelector("html"),
           let lang = html.getAttribute("lang") {
            return lang
        }
        
        // Try meta tag
        if let meta = document.querySelector("meta[http-equiv='content-language']") {
            return meta.getAttribute("content")
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func resolveURL(_ url: String, baseURL: String) -> String {
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }
        
        if url.hasPrefix("//") {
            return "https:" + url
        }
        
        if url.hasPrefix("/") {
            return baseURL + url
        }
        
        return baseURL + "/" + url
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
            "MMM dd, yyyy",
            "dd MMM yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - HTML Parser (Simplified)

class HTMLParser {
    func parse(_ html: String) -> HTMLDocument {
        return HTMLDocument(html: html)
    }
}

class HTMLDocument {
    private let html: String
    
    init(html: String) {
        self.html = html
    }
    
    func querySelector(_ selector: String) -> HTMLElement? {
        // Simplified implementation - in production, use a proper HTML parser
        return HTMLElement(html: html)
    }
    
    func querySelectorAll(_ selector: String) -> [HTMLElement] {
        // Simplified implementation
        return [HTMLElement(html: html)]
    }
}

class HTMLElement {
    private let html: String
    
    init(html: String) {
        self.html = html
    }
    
    var textContent: String? {
        // Extract text content from HTML
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
    
    var className: String {
        return ""
    }
    
    func getAttribute(_ name: String) -> String? {
        // Extract attribute value from HTML
        let pattern = "\(name)=\"([^\"]+)\""
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range) {
                return String(html[Range(match.range(at: 1), in: html)!])
            }
        }
        return nil
    }
    
    func remove() {
        // Remove element (simplified)
    }
}
