import Foundation
import SwiftUI

// MARK: - Link Content Models

struct LinkContent: Codable {
    let url: String
    let title: String
    let content: String
    let images: [ImageData]
    let metadata: ArticleMetadata
    let fetchedAt: Date
    // HTML/CSS entfernt (nur noch Plain Text)
    let aiOverview: AIOverview?
}

struct AIOverview: Codable {
    let textBlocks: [AITextBlock]
    let thumbnail: String?
    let references: [AIReference]?
}

struct AITextBlock: Codable {
    let type: String
    let snippet: String?
    let snippetHighlightedWords: [String]?
    let referenceIndexes: [Int]?
    let list: [AIListItem]?
}

struct AIListItem: Codable {
    let title: String
    let link: String
    let snippet: String
    let snippetLinks: [AISnippetLink]?
    let referenceIndexes: [Int]?
}

struct AISnippetLink: Codable {
    let text: String
    let link: String
}

struct AIReference: Codable {
    let title: String
    let link: String
    let snippet: String
    let source: String
    let index: Int
}

struct ImageData: Codable {
    let url: String
    let localPath: String?
    let altText: String?
    let width: Int?
    let height: Int?
    let data: Data?
}

struct ArticleMetadata: Codable {
    let author: String?
    let publishDate: Date?
    let description: String?
    let keywords: [String]
    let language: String?
    let wordCount: Int
    let readingTime: Int // in minutes
}

// MARK: - Link Content Fetcher

class LinkContentFetcher {
    private let session = URLSession.shared
    private let fileManager = FileManager.default
    
    // MARK: - Main Fetch Function
    
    func fetchCompleteArticle(from url: String) async throws -> LinkContent {
        guard let articleURL = URL(string: url) else {
            throw LinkContentError.invalidURL
        }
        
        // Fetch HTML content
        let htmlContent = try await fetchHTML(from: articleURL)
        
        // Parse HTML to extract structured content
        let parser = HTMLArticleParser(html: htmlContent, baseURL: articleURL)
        let parsedContent = try parser.parse()
        
        // Download and store images
        let images = try await downloadImages(parsedContent.images, baseURL: articleURL)
        
        // Extract metadata
        let metadata = extractMetadata(from: parsedContent)
        
        // Extract AI Overview if available
        let aiOverview = extractAIOverview(from: htmlContent)
        
        return LinkContent(
            url: url,
            title: parsedContent.title,
            content: parsedContent.mainText,
            images: images,
            metadata: metadata,
            fetchedAt: Date(),
            aiOverview: aiOverview
        )
    }
    
    // MARK: - HTML Fetching
    
    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("DailyWebScanner/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LinkContentError.fetchFailed
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw LinkContentError.encodingFailed
        }
        
        return html
    }
    
    // MARK: - Image Downloading
    
    private func downloadImages(_ imageURLs: [String], baseURL: URL) async throws -> [ImageData] {
        var images: [ImageData] = []
        
        for imageURL in imageURLs {
            do {
                let imageData = try await downloadImage(from: imageURL, baseURL: baseURL)
                images.append(imageData)
            } catch {
                // Continue with other images if one fails
                print("Failed to download image: \(imageURL) - \(error)")
            }
        }
        
        return images
    }
    
    private func downloadImage(from urlString: String, baseURL: URL) async throws -> ImageData {
        let imageURL: URL
        
        if urlString.hasPrefix("data:") {
            // Data URL (data:image/svg+xml,... or data:image/gif;base64,...)
            guard let url = URL(string: urlString) else {
                throw LinkContentError.invalidImageURL
            }
            imageURL = url
        } else if urlString.hasPrefix("http") {
            // Absolute URL with protocol
            guard let url = URL(string: urlString) else {
                throw LinkContentError.invalidImageURL
            }
            imageURL = url
        } else if urlString.hasPrefix("//") {
            // Protocol-relative URL (//example.com/image.jpg)
            guard let url = URL(string: "https:\(urlString)") else {
                throw LinkContentError.invalidImageURL
            }
            imageURL = url
        } else {
            // Relative URL - construct full URL
            if urlString.hasPrefix("/") {
                // Absolute path from domain root
                let scheme = baseURL.scheme ?? "https"
                let host = baseURL.host ?? ""
                guard let url = URL(string: "\(scheme)://\(host)\(urlString)") else {
                    throw LinkContentError.invalidImageURL
                }
                imageURL = url
            } else {
                // Relative path from current directory
                imageURL = baseURL.appendingPathComponent(urlString)
            }
        }
        
        let data: Data
        let response: URLResponse?
        
        if urlString.hasPrefix("data:") {
            // Data URL - decode directly without network request
            guard let dataURL = URL(string: urlString),
                  let dataFromURL = try? Data(contentsOf: dataURL) else {
                throw LinkContentError.imageDownloadFailed
            }
            data = dataFromURL
            response = nil // No HTTP response for data URLs
        } else {
            // Network request for regular URLs
            let (networkData, networkResponse) = try await session.data(from: imageURL)
            data = networkData
            response = networkResponse
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw LinkContentError.imageDownloadFailed
            }
        }
        
        // Save image to local storage
        let localPath = try saveImageToLocal(data, originalURL: imageURL)
        
        // Get image dimensions
        let dimensions = getImageDimensions(from: data)
        
        return ImageData(
            url: imageURL.absoluteString,
            localPath: localPath,
            altText: nil, // Could be extracted from HTML
            width: dimensions.width,
            height: dimensions.height,
            data: data
        )
    }
    
    private func saveImageToLocal(_ data: Data, originalURL: URL) throws -> String {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("ArticleImages")
        
        // Create directory if it doesn't exist
        try fileManager.createDirectory(at: imagesPath, withIntermediateDirectories: true)
        
        // Generate unique filename
        let filename = "\(UUID().uuidString).\(originalURL.pathExtension.isEmpty ? "jpg" : originalURL.pathExtension)"
        let localURL = imagesPath.appendingPathComponent(filename)
        
        try data.write(to: localURL)
        return localURL.path
    }
    
    private func getImageDimensions(from data: Data) -> (width: Int?, height: Int?) {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return (nil, nil)
        }
        
        let width = imageProperties[kCGImagePropertyPixelWidth] as? Int
        let height = imageProperties[kCGImagePropertyPixelHeight] as? Int
        
        return (width, height)
    }
    
    // MARK: - AI Overview Extraction
    
    private func extractAIOverview(from html: String) -> AIOverview? {
        // Look for AI Overview in JSON-LD structured data
        let jsonLdPattern = "<script[^>]*type=\"application/ld\\+json\"[^>]*>(.*?)</script>"
        let jsonLdMatches = extractAllMatches(pattern: jsonLdPattern, from: html)
        
        for jsonString in jsonLdMatches {
            if let aiOverview = parseAIOverviewFromJSON(jsonString) {
                return aiOverview
            }
        }
        
        // Look for AI Overview in inline JSON data
        let inlinePattern = "\"ai_overview\"\\s*:\\s*\\{([^}]+(?:\\{[^}]*\\}[^}]*)*)\\}"
        if let match = extractFirstMatch(pattern: inlinePattern, from: html) {
            if let aiOverview = parseAIOverviewFromJSON(match) {
                return aiOverview
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Methods for Pattern Matching
    
    private func extractFirstMatch(pattern: String, from text: String) -> String? {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            let matchRange = match.range(at: 1)
            if let range = Range(matchRange, in: text) {
                return String(text[range])
            }
        }
        
        return nil
    }
    
    private func extractAllMatches(pattern: String, from text: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: text.utf16.count)
        var matches: [String] = []
        
        regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let match = match, match.numberOfRanges > 1 {
                let matchRange = match.range(at: 1)
                if let range = Range(matchRange, in: text) {
                    matches.append(String(text[range]))
                }
            }
        }
        
        return matches
    }
    
            private func parseAIOverviewFromJSON(_ jsonString: String) -> AIOverview? {
                guard let data = jsonString.data(using: .utf8) else { return nil }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    // Check if this JSON contains ai_overview
                    if let aiOverviewData = json?["ai_overview"] as? [String: Any],
                       let textBlocksData = aiOverviewData["text_blocks"] as? [[String: Any]] {
                        
                        var textBlocks: [AITextBlock] = []
                        
                        for blockData in textBlocksData {
                            let type = blockData["type"] as? String ?? ""
                            let snippet = blockData["snippet"] as? String
                            let snippetHighlightedWords = blockData["snippet_highlighted_words"] as? [String]
                            let referenceIndexes = blockData["reference_indexes"] as? [Int]
                            
                            var list: [AIListItem]? = nil
                            if let listData = blockData["list"] as? [[String: Any]] {
                                list = parseAIListItems(from: listData)
                            }
                            
                            let textBlock = AITextBlock(
                                type: type, 
                                snippet: snippet, 
                                snippetHighlightedWords: snippetHighlightedWords,
                                referenceIndexes: referenceIndexes,
                                list: list
                            )
                            textBlocks.append(textBlock)
                        }
                        
                        // Parse thumbnail and references
                        let thumbnail = aiOverviewData["thumbnail"] as? String
                        var references: [AIReference]? = nil
                        
                        if let referencesData = aiOverviewData["references"] as? [[String: Any]] {
                            references = parseAIReferences(from: referencesData)
                        }
                        
                        return AIOverview(textBlocks: textBlocks, thumbnail: thumbnail, references: references)
                    }
                } catch {
                    DebugLogger.shared.logWebViewAction("Failed to parse AI Overview JSON: \(error)")
                }
                
                return nil
            }
    
    private func parseAIListItems(from listData: [[String: Any]]) -> [AIListItem] {
        var items: [AIListItem] = []
        
        for itemData in listData {
            let title = itemData["title"] as? String ?? ""
            let link = itemData["link"] as? String ?? ""
            let snippet = itemData["snippet"] as? String ?? ""
            
            var snippetLinks: [AISnippetLink]? = nil
            if let snippetLinksData = itemData["snippet_links"] as? [[String: Any]] {
                snippetLinks = snippetLinksData.compactMap { linkData in
                    guard let text = linkData["text"] as? String,
                          let link = linkData["link"] as? String else { return nil }
                    return AISnippetLink(text: text, link: link)
                }
            }
            
            let referenceIndexes = itemData["reference_indexes"] as? [Int]
            
            let item = AIListItem(
                title: title,
                link: link,
                snippet: snippet,
                snippetLinks: snippetLinks,
                referenceIndexes: referenceIndexes
            )
            items.append(item)
        }
        
        return items
    }
    
    private func parseAIReferences(from referencesData: [[String: Any]]) -> [AIReference] {
        var references: [AIReference] = []
        
        for refData in referencesData {
            let title = refData["title"] as? String ?? ""
            let link = refData["link"] as? String ?? ""
            let snippet = refData["snippet"] as? String ?? ""
            let source = refData["source"] as? String ?? ""
            let index = refData["index"] as? Int ?? 0
            
            let reference = AIReference(
                title: title,
                link: link,
                snippet: snippet,
                source: source,
                index: index
            )
            references.append(reference)
        }
        
        return references
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from content: ParsedContent) -> ArticleMetadata {
        let wordCount = content.mainText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        let readingTime = max(1, wordCount / 200) // Assume 200 words per minute
        
        return ArticleMetadata(
            author: content.author,
            publishDate: content.publishDate,
            description: content.description,
            keywords: content.keywords,
            language: content.language,
            wordCount: wordCount,
            readingTime: readingTime
        )
    }
}

// MARK: - HTML Article Parser

struct ParsedContent {
    let title: String
    let mainText: String
    let images: [String]
    let css: String
    let author: String?
    let publishDate: Date?
    let description: String?
    let keywords: [String]
    let language: String?
}

class HTMLArticleParser {
    private let html: String
    private let baseURL: URL
    
    init(html: String, baseURL: URL) {
        self.html = html
        self.baseURL = baseURL
    }
    
    func parse() throws -> ParsedContent {
        // Extract title
        let title = extractTitle()
        
        // Extract main content (remove navigation, ads, etc.)
        let mainText = extractMainContent()
        
        // Extract images
        let images = extractImages()
        
        // Extract CSS
        let css = extractCSS()
        
        // Extract metadata
        let author = extractAuthor()
        let publishDate = extractPublishDate()
        let description = extractDescription()
        let keywords = extractKeywords()
        let language = extractLanguage()
        
        return ParsedContent(
            title: title,
            mainText: mainText,
            images: images,
            css: css,
            author: author,
            publishDate: publishDate,
            description: description,
            keywords: keywords,
            language: language
        )
    }
    
    private func extractTitle() -> String {
        let titlePattern = "<title[^>]*>(.*?)</title>"
        return extractFirstMatch(pattern: titlePattern) ?? "Untitled"
    }
    
    private func extractMainContent() -> String {
        // Try to find main content area
        let contentPatterns = [
            "<main[^>]*>(.*?)</main>",
            "<article[^>]*>(.*?)</article>",
            "<div[^>]*class=\"[^\"]*content[^\"]*\"[^>]*>(.*?)</div>",
            "<div[^>]*id=\"[^\"]*content[^\"]*\"[^>]*>(.*?)</div>"
        ]
        
        for pattern in contentPatterns {
            if let content = extractFirstMatch(pattern: pattern) {
                return cleanHTML(content)
            }
        }
        
        // Fallback: extract body content
        let bodyPattern = "<body[^>]*>(.*?)</body>"
        if let bodyContent = extractFirstMatch(pattern: bodyPattern) {
            return cleanHTML(bodyContent)
        }
        
        return html
    }
    
    private func extractImages() -> [String] {
        let imagePattern = "<img[^>]+src=\"([^\"]+)\"[^>]*>"
        return extractAllMatches(pattern: imagePattern)
    }
    
    private func extractCSS() -> String {
        let cssPattern = "<style[^>]*>(.*?)</style>"
        return extractAllMatches(pattern: cssPattern).joined(separator: "\n")
    }
    
    private func extractAuthor() -> String? {
        let patterns = [
            "<meta[^>]*name=\"author\"[^>]*content=\"([^\"]+)\"",
            "<meta[^>]*property=\"article:author\"[^>]*content=\"([^\"]+)\"",
            "<span[^>]*class=\"[^\"]*author[^\"]*\"[^>]*>(.*?)</span>"
        ]
        
        for pattern in patterns {
            if let author = extractFirstMatch(pattern: pattern) {
                return cleanHTML(author)
            }
        }
        
        return nil
    }
    
    private func extractPublishDate() -> Date? {
        let patterns = [
            "<meta[^>]*property=\"article:published_time\"[^>]*content=\"([^\"]+)\"",
            "<time[^>]*datetime=\"([^\"]+)\"",
            "<meta[^>]*name=\"date\"[^>]*content=\"([^\"]+)\""
        ]
        
        for pattern in patterns {
            if let dateString = extractFirstMatch(pattern: pattern) {
                let formatter = ISO8601DateFormatter()
                return formatter.date(from: dateString)
            }
        }
        
        return nil
    }
    
    private func extractDescription() -> String? {
        let patterns = [
            "<meta[^>]*name=\"description\"[^>]*content=\"([^\"]+)\"",
            "<meta[^>]*property=\"og:description\"[^>]*content=\"([^\"]+)\""
        ]
        
        for pattern in patterns {
            if let description = extractFirstMatch(pattern: pattern) {
                return cleanHTML(description)
            }
        }
        
        return nil
    }
    
    private func extractKeywords() -> [String] {
        let keywordPattern = "<meta[^>]*name=\"keywords\"[^>]*content=\"([^\"]+)\""
        if let keywordsString = extractFirstMatch(pattern: keywordPattern) {
            return keywordsString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        return []
    }
    
    private func extractLanguage() -> String? {
        let languagePattern = "<html[^>]*lang=\"([^\"]+)\""
        return extractFirstMatch(pattern: languagePattern)
    }
    
    // MARK: - Helper Methods
    
    private func extractFirstMatch(pattern: String) -> String? {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: html.utf16.count)
        
        if let match = regex.firstMatch(in: html, options: [], range: range) {
            let matchRange = match.range(at: 1)
            if let range = Range(matchRange, in: html) {
                return String(html[range])
            }
        }
        
        return nil
    }
    
    private func extractAllMatches(pattern: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let range = NSRange(location: 0, length: html.utf16.count)
        var matches: [String] = []
        
        regex.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            if let match = match, match.numberOfRanges > 1 {
                let matchRange = match.range(at: 1)
                if let range = Range(matchRange, in: html) {
                    matches.append(String(html[range]))
                }
            }
        }
        
        return matches
    }
    
    private func cleanHTML(_ html: String) -> String {
        return html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error Types

enum LinkContentError: Error, LocalizedError {
    case invalidURL
    case fetchFailed
    case encodingFailed
    case invalidImageURL
    case imageDownloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .fetchFailed:
            return "Failed to fetch content from URL"
        case .encodingFailed:
            return "Failed to decode content"
        case .invalidImageURL:
            return "Invalid image URL"
        case .imageDownloadFailed:
            return "Failed to download image"
        }
    }
}
