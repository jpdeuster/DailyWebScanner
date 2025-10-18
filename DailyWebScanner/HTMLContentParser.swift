import Foundation
import SwiftUI

// MARK: - Content Analysis Models

struct ContentAnalysis: Codable {
    let headlines: [HeadlineInfo]
    let links: [LinkInfo]
    let contentBlocks: [ContentBlock]
    let tags: [String]
}

struct HeadlineInfo: Codable {
    let text: String
    let level: Int              // h1=1, h2=2, h3=3, etc.
    let position: Int
    let source: String?
}

struct LinkInfo: Codable {
    let url: String
    let title: String
    let description: String?
    let domain: String
    let position: Int
    let isAd: Bool
    let tags: [String]
}

struct ContentBlock: Codable {
    let type: ContentType
    let text: String
    let position: Int
    let source: String?
    let tags: [String]
}

enum ContentType: String, CaseIterable, Codable {
    case headline = "headline"
    case paragraph = "paragraph"
    case list = "list"
    case link = "link"
    case image = "image"
    case other = "other"
}

// MARK: - HTML Content Parser

class HTMLContentParser {
    
    // MARK: - Main Parsing Function
    
    static func parseContent(from htmlString: String) -> ContentAnalysis {
        let headlines = extractHeadlines(from: htmlString)
        let links = extractLinks(from: htmlString)
        let contentBlocks = extractContentBlocks(from: htmlString)
        let tags = extractAutoTags(from: htmlString)
        
        return ContentAnalysis(
            headlines: headlines,
            links: links,
            contentBlocks: contentBlocks,
            tags: tags
        )
    }
    
    // MARK: - Headline Extraction
    
    private static func extractHeadlines(from html: String) -> [HeadlineInfo] {
        var headlines: [HeadlineInfo] = []
        var position = 0
        
        // Regex pattern for headlines (h1-h6)
        let headlinePattern = "<h([1-6])[^>]*>(.*?)</h[1-6]>"
        let regex = try! NSRegularExpression(pattern: headlinePattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let levelRange = match.range(at: 1)
                let contentRange = match.range(at: 2)
                
                if let levelString = Range(levelRange, in: html).map({ String(html[$0]) }),
                   let level = Int(levelString),
                   let contentRange = Range(contentRange, in: html) {
                    
                    let content = String(html[contentRange])
                    let cleanText = stripHTMLTags(from: content)
                    
                    if !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        headlines.append(HeadlineInfo(
                            text: cleanText,
                            level: level,
                            position: position,
                            source: extractSource(from: content)
                        ))
                        position += 1
                    }
                }
            }
        }
        
        return headlines
    }
    
    // MARK: - Link Extraction
    
    private static func extractLinks(from html: String) -> [LinkInfo] {
        var links: [LinkInfo] = []
        var position = 0
        
        // Regex pattern for links
        let linkPattern = "<a[^>]+href=\"([^\"]+)\"[^>]*>(.*?)</a>"
        let regex = try! NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let urlRange = match.range(at: 1)
                let contentRange = match.range(at: 2)
                
                if let urlRange = Range(urlRange, in: html),
                   let contentRange = Range(contentRange, in: html) {
                    
                    let url = String(html[urlRange])
                    let content = String(html[contentRange])
                    let cleanText = stripHTMLTags(from: content)
                    
                    if !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let domain = extractDomain(from: url)
                        let isAd = isAdvertisement(url: url, title: cleanText)
                        
                        links.append(LinkInfo(
                            url: url,
                            title: cleanText,
                            description: extractDescription(from: content),
                            domain: domain,
                            position: position,
                            isAd: isAd,
                            tags: extractLinkTags(from: url, title: cleanText)
                        ))
                        position += 1
                    }
                }
            }
        }
        
        return links
    }
    
    // MARK: - Content Block Extraction
    
    private static func extractContentBlocks(from html: String) -> [ContentBlock] {
        var contentBlocks: [ContentBlock] = []
        var position = 0
        
        // Extract paragraphs
        let paragraphPattern = "<p[^>]*>(.*?)</p>"
        let paragraphRegex = try! NSRegularExpression(pattern: paragraphPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        
        let paragraphMatches = paragraphRegex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        for match in paragraphMatches {
            if match.numberOfRanges >= 2 {
                let contentRange = match.range(at: 1)
                if let contentRange = Range(contentRange, in: html) {
                    let content = String(html[contentRange])
                    let cleanText = stripHTMLTags(from: content)
                    
                    if !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        contentBlocks.append(ContentBlock(
                            type: .paragraph,
                            text: cleanText,
                            position: position,
                            source: extractSource(from: content),
                            tags: extractContentTags(from: cleanText)
                        ))
                        position += 1
                    }
                }
            }
        }
        
        // Extract lists
        let listPattern = "<li[^>]*>(.*?)</li>"
        let listRegex = try! NSRegularExpression(pattern: listPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        
        let listMatches = listRegex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        for match in listMatches {
            if match.numberOfRanges >= 2 {
                let contentRange = match.range(at: 1)
                if let contentRange = Range(contentRange, in: html) {
                    let content = String(html[contentRange])
                    let cleanText = stripHTMLTags(from: content)
                    
                    if !cleanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        contentBlocks.append(ContentBlock(
                            type: .list,
                            text: cleanText,
                            position: position,
                            source: extractSource(from: content),
                            tags: extractContentTags(from: cleanText)
                        ))
                        position += 1
                    }
                }
            }
        }
        
        return contentBlocks
    }
    
    // MARK: - Auto Tag Extraction
    
    private static func extractAutoTags(from html: String) -> [String] {
        var tags: Set<String> = []
        
        // Extract common keywords and create tags
        let keywords = extractKeywords(from: html)
        tags.formUnion(keywords)
        
        // Extract domain-based tags
        let domains = extractDomains(from: html)
        tags.formUnion(domains)
        
        // Extract content type tags
        let contentTypes = extractContentTypes(from: html)
        tags.formUnion(contentTypes)
        
        return Array(tags).sorted()
    }
    
    // MARK: - Helper Functions
    
    private static func stripHTMLTags(from html: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<[^>]+>", options: [])
        let range = NSRange(location: 0, length: html.utf16.count)
        let cleanText = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
        
        // Decode HTML entities
        return cleanText
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func extractDomain(from url: String) -> String {
        guard let urlObj = URL(string: url) else { return url }
        return urlObj.host ?? url
    }
    
    private static func extractSource(from content: String) -> String? {
        // Try to extract source from content
        let sourcePattern = "source[:\"\\s]*([^\"\\s]+)"
        let regex = try! NSRegularExpression(pattern: sourcePattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: content.utf16.count)
        
        if let match = regex.firstMatch(in: content, options: [], range: range) {
            let sourceRange = match.range(at: 1)
            if let sourceRange = Range(sourceRange, in: content) {
                return String(content[sourceRange])
            }
        }
        
        return nil
    }
    
    private static func extractDescription(from content: String) -> String? {
        // Extract description from link content
        let cleanText = stripHTMLTags(from: content)
        return cleanText.count > 100 ? String(cleanText.prefix(100)) + "..." : cleanText
    }
    
    private static func isAdvertisement(url: String, title: String) -> Bool {
        let adKeywords = ["ad", "advertisement", "sponsored", "promo", "buy", "shop", "deal"]
        let adDomains = ["amazon", "ebay", "shop", "buy", "store"]
        
        let lowerTitle = title.lowercased()
        let lowerUrl = url.lowercased()
        
        return adKeywords.contains { lowerTitle.contains($0) } ||
               adDomains.contains { lowerUrl.contains($0) }
    }
    
    private static func extractLinkTags(from url: String, title: String) -> [String] {
        var tags: Set<String> = []
        
        // Domain-based tags
        if let domain = URL(string: url)?.host {
            tags.insert(domain)
        }
        
        // Content-based tags
        let contentTags = extractContentTags(from: title)
        tags.formUnion(contentTags)
        
        return Array(tags)
    }
    
    private static func extractContentTags(from text: String) -> [String] {
        var tags: Set<String> = []
        
        // Common keywords
        let keywords = ["news", "article", "blog", "tutorial", "guide", "review", "analysis"]
        let lowerText = text.lowercased()
        
        for keyword in keywords {
            if lowerText.contains(keyword) {
                tags.insert(keyword)
            }
        }
        
        return Array(tags)
    }
    
    private static func extractKeywords(from html: String) -> [String] {
        // Extract common keywords from HTML content
        let commonKeywords = ["technology", "science", "business", "health", "education", "entertainment"]
        var foundKeywords: Set<String> = []
        
        let lowerHtml = html.lowercased()
        for keyword in commonKeywords {
            if lowerHtml.contains(keyword) {
                foundKeywords.insert(keyword)
            }
        }
        
        return Array(foundKeywords)
    }
    
    private static func extractDomains(from html: String) -> [String] {
        // Extract domains from links
        var domains: Set<String> = []
        
        let linkPattern = "href=\"([^\"]+)\""
        let regex = try! NSRegularExpression(pattern: linkPattern, options: [])
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        for match in matches {
            if match.numberOfRanges >= 2 {
                let urlRange = match.range(at: 1)
                if let urlRange = Range(urlRange, in: html) {
                    let url = String(html[urlRange])
                    if let domain = URL(string: url)?.host {
                        domains.insert(domain)
                    }
                }
            }
        }
        
        return Array(domains)
    }
    
    private static func extractContentTypes(from html: String) -> [String] {
        var types: Set<String> = []
        
        let lowerHtml = html.lowercased()
        
        if lowerHtml.contains("news") || lowerHtml.contains("article") {
            types.insert("news")
        }
        if lowerHtml.contains("blog") {
            types.insert("blog")
        }
        if lowerHtml.contains("shop") || lowerHtml.contains("buy") {
            types.insert("ecommerce")
        }
        if lowerHtml.contains("video") || lowerHtml.contains("youtube") {
            types.insert("video")
        }
        
        return Array(types)
    }
}

// MARK: - Content Analysis Extensions

extension ContentAnalysis {
    var headlineCount: Int { headlines.count }
    var linkCount: Int { links.count }
    var contentBlockCount: Int { contentBlocks.count }
    var tagCount: Int { tags.count }
    
    var nonAdLinks: [LinkInfo] {
        links.filter { !$0.isAd }
    }
    
    var adLinks: [LinkInfo] {
        links.filter { $0.isAd }
    }
    
    var mainHeadlines: [HeadlineInfo] {
        headlines.filter { $0.level <= 2 }
    }
    
    var allText: String {
        let headlineTexts = headlines.map { $0.text }
        let linkTexts = links.map { $0.title }
        let contentTexts = contentBlocks.map { $0.text }
        
        return (headlineTexts + linkTexts + contentTexts).joined(separator: " ")
    }
}
