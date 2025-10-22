import Foundation
import SwiftUI
import WebKit
import NaturalLanguage

/// Powerful HTML content extractor that captures text, images, videos, and metadata
class HTMLContentExtractor: NSObject {
    
    // MARK: - Content Types
    struct ExtractedContent: Codable {
        let title: String
        let description: String
        let mainText: String
        let images: [ExtractedImage]
        let videos: [ExtractedVideo]
        let audios: [ExtractedAudio]
        let links: [ExtractedLink]
        let metadata: ContentMetadata
        let readingTime: Int
        let wordCount: Int
    }
    
    struct ExtractedImage: Codable {
        let url: String
        let alt: String
        let caption: String
        let width: Int?
        let height: Int?
        let isMainImage: Bool
    }
    
    struct ExtractedVideo: Codable {
        let url: String
        let title: String
        let thumbnail: String?
        let duration: String?
        let platform: VideoPlatform
    }
    
    struct ExtractedAudio: Codable {
        let url: String
        let title: String
        let duration: String?
    }
    
    struct ExtractedLink: Codable {
        let url: String
        let title: String
        let description: String
        let isExternal: Bool
    }
    
    struct ContentMetadata: Codable {
        let author: String?
        let publishDate: Date?
        let category: String?
        let tags: [String]
        let language: String?
        let wordCount: Int
        let readingTime: Int
    }
    
    enum VideoPlatform: Codable {
        case youtube
        case vimeo
        case direct
        case other(String)
        
        private enum CodingKeys: String, CodingKey { case type, value }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let t = try c.decode(String.self, forKey: .type)
            switch t {
            case "youtube": self = .youtube
            case "vimeo": self = .vimeo
            case "direct": self = .direct
            case "other": self = .other(try c.decode(String.self, forKey: .value))
            default: self = .other(t)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .youtube: try c.encode("youtube", forKey: .type)
            case .vimeo: try c.encode("vimeo", forKey: .type)
            case .direct: try c.encode("direct", forKey: .type)
            case .other(let s):
                try c.encode("other", forKey: .type)
                try c.encode(s, forKey: .value)
            }
        }
    }
    
    // MARK: - Extraction Methods
    
    /// Extract comprehensive content from HTML with detailed logging
    func extractContent(from html: String, baseURL: String) async -> ExtractedContent {
        DebugLogger.shared.logWebViewAction("🔍 HTMLContentExtractor: Starting content extraction from \(baseURL)")
        DebugLogger.shared.logWebViewAction("📄 HTMLContentExtractor: HTML length: \(html.count) characters")
        
        let parser = HTMLParser()
        
        // Try to isolate likely article markup before parsing to reduce boilerplate
        let articleHTML = isolateArticleHTML(html)
        if articleHTML.count != html.count {
            DebugLogger.shared.logWebViewAction("🧩 HTMLContentExtractor: Using isolated <article>/<main> segment (length: \(articleHTML.count))")
        }
        
        // Parse HTML structure
        let document = parser.parse(articleHTML)
        DebugLogger.shared.logWebViewAction("🌐 HTMLContentExtractor: HTML document parsed successfully")
        
        // Extract different content types with logging
        let title = extractTitle(from: document)
        DebugLogger.shared.logWebViewAction("📝 HTMLContentExtractor: Title extracted: '\(title)'")
        
        let description = extractDescription(from: document)
        DebugLogger.shared.logWebViewAction("📄 HTMLContentExtractor: Description extracted: \(description.count) characters")
        
        var mainText = extractMainText(from: document)
        if mainText.count < 50 {
            // Fallback: erneut mit vollständigem HTML parsen (ohne Isolierung)
            let fullDoc = parser.parse(html)
            let fallbackText = extractMainText(from: fullDoc)
            if fallbackText.count > mainText.count { mainText = fallbackText }
            // Letzter Fallback: plain Text aus gesamtem HTML
            if mainText.count < 20 {
                mainText = HTMLElement(html: html).textContent ?? ""
            }
        }
        DebugLogger.shared.logWebViewAction("📖 HTMLContentExtractor: Main text extracted: \(mainText.count) characters")
        
        let images = extractImagesFromHTML(articleHTML, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🖼️ HTMLContentExtractor: Images found: \(images.count)")
        
        let videos = extractVideos(from: document, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🎥 HTMLContentExtractor: Videos found: \(videos.count)")
        
        let audios = extractAudiosFromHTML(articleHTML, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🔊 HTMLContentExtractor: Audios found: \(audios.count)")
        
        let links = extractLinks(from: document, baseURL: baseURL)
        DebugLogger.shared.logWebViewAction("🔗 HTMLContentExtractor: Links found: \(links.count)")
        
        var metadata = extractMetadata(from: document)
        // Sprach-Fallback via NLLanguageRecognizer
        if (metadata.language == nil || metadata.language?.isEmpty == true) && !mainText.isEmpty {
            metadata = ContentMetadata(
                author: metadata.author,
                publishDate: metadata.publishDate,
                category: metadata.category,
                tags: metadata.tags,
                language: detectLanguageCode(from: mainText),
                wordCount: metadata.wordCount,
                readingTime: metadata.readingTime
            )
        }
        DebugLogger.shared.logWebViewAction("📊 HTMLContentExtractor: Metadata extracted - Author: \(metadata.author ?? "None"), Language: \(metadata.language ?? "None"), Tags: \(metadata.tags.count)")
        
        // Calculate reading metrics
        let wordCount = mainText.split(separator: " ").count
        let readingTime = max(1, wordCount / 200) // 200 words per minute
        
        DebugLogger.shared.logWebViewAction("📈 HTMLContentExtractor: Content metrics - Words: \(wordCount), Reading time: \(readingTime) minutes")
        
        // Improved author detection (prefer JSON-LD/meta over weak CSS text)
        let smartAuthor = extractAuthorSmart(fromHTML: html)
        if let sa = smartAuthor { DebugLogger.shared.logWebViewAction("🧠 HTMLContentExtractor: Smart author detected: \(sa)") }
        
        let extractedContent = ExtractedContent(
            title: title,
            description: description,
            mainText: mainText,
            images: images,
            videos: videos,
            audios: audios,
            links: links,
            metadata: ContentMetadata(
                author: smartAuthor ?? metadata.author,
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
    
    private func extractImagesFromHTML(_ html: String, baseURL: String) -> [ExtractedImage] {
        var results: [ExtractedImage] = []
        // Find all <img ...> tags
        let imgTagPattern = "<img[^>]*>"
        guard let tagRegex = try? NSRegularExpression(pattern: imgTagPattern, options: [.caseInsensitive]) else { return results }
        let fullRange = NSRange(html.startIndex..., in: html)
        let matches = tagRegex.matches(in: html, options: [], range: fullRange)
        
        for m in matches {
            guard let r = Range(m.range, in: html) else { continue }
            let tag = String(html[r])
            
            func attr(_ name: String) -> String? {
                let pattern = "\\b\(name)\\s*=\\s*\"([^\"]*)\"|\\b\(name)\\s*=\\s*'([^']*)'|\\b\(name)\\s*=\\s*([^\\s>]+)"
                if let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    if let am = rx.firstMatch(in: tag, options: [], range: NSRange(tag.startIndex..., in: tag)) {
                        for i in 1..<am.numberOfRanges {
                            if let ar = Range(am.range(at: i), in: tag) {
                                let val = String(tag[ar])
                                if !val.isEmpty { return val }
                            }
                        }
                    }
                }
                return nil
            }
            
            // Prefer srcset largest <= 1600w, else largest available
            var chosenURL: String?
            var chosenWidth: Int?
            if let srcset = attr("srcset"), !srcset.isEmpty {
                let candidates = parseSrcset(srcset, baseURL: baseURL)
                if !candidates.isEmpty {
                    // w-Deskriptor priorisieren, Grenze 1600px
                    let withW = candidates.compactMap { $0.width != nil ? $0 : nil }
                    if !withW.isEmpty {
                        let suitable = withW.filter { ($0.width ?? 0) <= 1600 }
                        let pick = (suitable.max { ($0.width ?? 0) < ($1.width ?? 0) }) ?? (withW.max { ($0.width ?? 0) < ($1.width ?? 0) })
                        chosenURL = pick?.url
                        chosenWidth = pick?.width
                    } else {
                        // Fallback: höchstes x (DPR)
                        let byScale = candidates.sorted { ($0.scale ?? 1.0) > ($1.scale ?? 1.0) }
                        chosenURL = byScale.first?.url
                    }
                }
            }
            
            // Fallbacks auf src / data-src / data-original / data-lazy-src
            if chosenURL == nil {
                if let src = attr("src"), !src.isEmpty { chosenURL = src }
                else if let dsrc = attr("data-src"), !dsrc.isEmpty { chosenURL = dsrc }
                else if let dorig = attr("data-original"), !dorig.isEmpty { chosenURL = dorig }
                else if let dlazy = attr("data-lazy-src"), !dlazy.isEmpty { chosenURL = dlazy }
            }
            guard var srcFinal = chosenURL, !srcFinal.isEmpty else { continue }
            
            // Resolve relative and protocol-relative URLs; allow data URLs as-is
            if !srcFinal.lowercased().hasPrefix("data:") {
                srcFinal = resolveURL(srcFinal, baseURL: baseURL)
            }
            
            let alt = attr("alt") ?? ""
            let title = attr("title") ?? ""
            let width = chosenWidth ?? Int(attr("width") ?? "")
            let height = Int(attr("height") ?? "")
            
            results.append(ExtractedImage(
                url: srcFinal,
                alt: alt,
                caption: title,
                width: width,
                height: height,
                isMainImage: false
            ))
        }
        
        // Meta-Fallbacks (og:image, twitter:image, link rel=image_src)
        func addMetaImageIfPresent(_ pattern: String) {
            if let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let m = rx.firstMatch(in: html, options: [], range: fullRange),
               m.numberOfRanges > 1, let rr = Range(m.range(at: 1), in: html) {
                var url = String(html[rr])
                if !url.lowercased().hasPrefix("data:") { url = resolveURL(url, baseURL: baseURL) }
                if !results.contains(where: { $0.url == url }) {
                    results.append(ExtractedImage(url: url, alt: "", caption: "", width: nil, height: nil, isMainImage: true))
                }
            }
        }
        addMetaImageIfPresent(#"<meta[^>]*property=\"og:image\"[^>]*content=\"([^\"]+)\"[^>]*>"#)
        addMetaImageIfPresent(#"<meta[^>]*name=\"twitter:image\"[^>]*content=\"([^\"]+)\"[^>]*>"#)
        addMetaImageIfPresent(#"<link[^>]*rel=\"image_src\"[^>]*href=\"([^\"]+)\"[^>]*>"#)
        
        // Deduplicate by URL
        var seen: Set<String> = []
        results = results.filter { img in
            if seen.contains(img.url) { return false }
            seen.insert(img.url)
            return true
        }
        
        return results
    }
    
    // Parse srcset into candidate list (url, width?, scale?)
    private func parseSrcset(_ srcset: String, baseURL: String) -> [(url: String, width: Int?, scale: Double?)] {
        let parts = srcset.split(separator: ",")
        var out: [(String, Int?, Double?)] = []
        for p in parts {
            let comp = p.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
            guard let first = comp.first else { continue }
            var url = String(first)
            if !url.lowercased().hasPrefix("data:") { url = resolveURL(url, baseURL: baseURL) }
            var w: Int?
            var s: Double?
            if comp.count >= 2 {
                let d = comp[1]
                if d.hasSuffix("w"), let val = Int(d.dropLast()) { w = val }
                else if d.hasSuffix("x"), let val = Double(d.dropLast()) { s = val }
            }
            out.append((url, w, s))
        }
        return out
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
    
    // MARK: - Audio Extraction
    private func extractAudiosFromHTML(_ html: String, baseURL: String) -> [ExtractedAudio] {
        var results: [ExtractedAudio] = []
        let fullRange = NSRange(html.startIndex..., in: html)
        
        // 1) <audio src> and <audio><source src></audio>
        if let audioTagRx = try? NSRegularExpression(pattern: "<audio[\\s\\S]*?>[\\s\\S]*?</audio>|<audio[^>]*>", options: [.caseInsensitive]) {
            let matches = audioTagRx.matches(in: html, options: [], range: fullRange)
            for m in matches {
                guard let r = Range(m.range, in: html) else { continue }
                let block = String(html[r])
                // Try src on audio
                if let src = firstAttr("src", in: block) {
                    let url = resolveCandidateURL(src, baseURL: baseURL)
                    results.append(ExtractedAudio(url: url, title: firstAttr("title", in: block) ?? "Audio", duration: firstAttr("duration", in: block)))
                }
                // Try <source src=...>
                if let sourceRx = try? NSRegularExpression(pattern: "<source[^>]*>", options: [.caseInsensitive]) {
                    let innerRange = NSRange(block.startIndex..., in: block)
                    let inner = sourceRx.matches(in: block, options: [], range: innerRange)
                    for sm in inner {
                        guard let rr = Range(sm.range, in: block) else { continue }
                        let tag = String(block[rr])
                        if let src = firstAttr("src", in: tag) {
                            let url = resolveCandidateURL(src, baseURL: baseURL)
                            results.append(ExtractedAudio(url: url, title: firstAttr("title", in: tag) ?? "Audio", duration: firstAttr("duration", in: tag)))
                        }
                    }
                }
            }
        }
        
        // 2) Anchor links to common audio file extensions
        let audioExt = "(mp3|wav|m4a|aac|ogg|oga|opus)"
        if let linkRx = try? NSRegularExpression(pattern: "<a[^>]*href=\\\"([^\\\"]+\\.\(audioExt))\\\"[^>]*>([\\s\\S]*?)</a>", options: [.caseInsensitive]) {
            for m in linkRx.matches(in: html, options: [], range: fullRange) {
                if m.numberOfRanges >= 3, let r1 = Range(m.range(at: 1), in: html) {
                    var url = String(html[r1])
                    url = resolveCandidateURL(url, baseURL: baseURL)
                    var title = "Audio"
                    if let r2 = Range(m.range(at: 2), in: html) {
                        title = HTMLElement(html: String(html[r2])).textContent ?? title
                    }
                    results.append(ExtractedAudio(url: url, title: title, duration: nil))
                }
            }
        }
        
        // 3) Meta tags (og:audio)
        func addMetaAudio(_ pattern: String) {
            if let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let m = rx.firstMatch(in: html, options: [], range: fullRange),
               m.numberOfRanges > 1, let rr = Range(m.range(at: 1), in: html) {
                var url = String(html[rr])
                url = resolveCandidateURL(url, baseURL: baseURL)
                if !results.contains(where: { $0.url == url }) {
                    results.append(ExtractedAudio(url: url, title: "Audio", duration: nil))
                }
            }
        }
        addMetaAudio(#"<meta[^>]*property=\"og:audio\"[^>]*content=\"([^\"]+)\"[^>]*>"#)
        addMetaAudio(#"<meta[^>]*name=\"twitter:player:stream\"[^>]*content=\"([^\"]+)\"[^>]*>"#)
        
        // Deduplicate by URL
        var seen: Set<String> = []
        results = results.filter { a in
            if seen.contains(a.url) { return false }
            seen.insert(a.url)
            return true
        }
        
        return results
    }
    
    private func firstAttr(_ name: String, in tag: String) -> String? {
        let pattern = "\\b\(name)\\s*=\\s*\"([^\"]*)\"|\\b\(name)\\s*=\\s*'([^']*)'|\\b\(name)\\s*=\\s*([^\\s>]+)"
        if let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            if let am = rx.firstMatch(in: tag, options: [], range: NSRange(tag.startIndex..., in: tag)) {
                for i in 1..<am.numberOfRanges {
                    if let ar = Range(am.range(at: i), in: tag) {
                        let val = String(tag[ar])
                        if !val.isEmpty { return val }
                    }
                }
            }
        }
        return nil
    }
    
    private func resolveCandidateURL(_ candidate: String, baseURL: String) -> String {
        if candidate.lowercased().hasPrefix("data:") { return candidate }
        return resolveURL(candidate, baseURL: baseURL)
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

    // Prefer structured data/meta; then heuristic. Return one name or nil
    private func extractAuthorSmart(fromHTML html: String) -> String? {
        // 1) JSON-LD schema.org Article/NewsArticle/BlogPosting: author.name or author[0].name
        if let jsonAuthor = extractAuthorFromJSONLD(html: html) {
            return jsonAuthor
        }
        // 2) Meta tags: article:author, name=author, twitter:creator (strip leading @)
        if let metaAuthor = extractAuthorFromMeta(html: html) {
            return metaAuthor
        }
        // 3) Heuristic Byline around common patterns (very conservative)
        if let byline = extractBylineHeuristic(html: html) {
            return byline
        }
        return nil
    }

    private func extractAuthorFromJSONLD(html: String) -> String? {
        // Very lightweight: find <script type="application/ld+json"> blocks and look for "@type":"(Article|NewsArticle|BlogPosting)"
        let pattern = "<script[^>]*type=\\\"application/ld\\+json\\\"[^>]*>([\\s\\S]*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        for m in matches {
            guard let r = Range(m.range(at: 1), in: html) else { continue }
            let json = String(html[r])
            if let name = parseJSONLDAuthor(json: json) { return name }
        }
        return nil
    }

    private func parseJSONLDAuthor(json: String) -> String? {
        // Nahezu-regexbasiert um Abhängigkeiten zu vermeiden; robust genug für häufige Fälle
        // Entscheide nur, wenn ein Article‑Typ vorhanden ist.
        let articlePattern = "\\\"@type\\\"\\s*:\\s*\\\"(Article|NewsArticle|BlogPosting)\\\""
        guard (try? NSRegularExpression(pattern: articlePattern))?.firstMatch(in: json, range: NSRange(json.startIndex..., in: json)) != nil else { return nil }
        // author als Objekt mit name
        let namePattern = "\\\"author\\\"[\\s\\S]*?\\\"name\\\"\\s*:\\s*\\\"([^\\\"]{2,60})\\\""
        if let rx = try? NSRegularExpression(pattern: namePattern), let m = rx.firstMatch(in: json, range: NSRange(json.startIndex..., in: json)), let r = Range(m.range(at: 1), in: json) {
            let candidate = String(json[r]).trimmingCharacters(in: .whitespacesAndNewlines)
            if isLikelyPersonName(candidate) { return candidate }
        }
        // author als Array von Objekten
        let arrayNamePattern = "\\\"author\\\"[\\s\\S]*?\\[([\\s\\S]*?)\\]"
        if let rx = try? NSRegularExpression(pattern: arrayNamePattern), let m = rx.firstMatch(in: json, range: NSRange(json.startIndex..., in: json)), let r = Range(m.range(at: 1), in: json) {
            let body = String(json[r])
            let inner = "\\\"name\\\"\\s*:\\s*\\\"([^\\\"]{2,60})\\\""
            if let rx2 = try? NSRegularExpression(pattern: inner), let m2 = rx2.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)), let r2 = Range(m2.range(at: 1), in: body) {
                let candidate = String(body[r2]).trimmingCharacters(in: .whitespacesAndNewlines)
                if isLikelyPersonName(candidate) { return candidate }
            }
        }
        return nil
    }

    private func extractAuthorFromMeta(html: String) -> String? {
        let patterns = [
            "<meta[^>]*property=\\\"article:author\\\"[^>]*content=\\\"([^\\\"]{2,60})\\\"[^>]*>",
            "<meta[^>]*name=\\\"author\\\"[^>]*content=\\\"([^\\\"]{2,60})\\\"[^>]*>",
            "<meta[^>]*name=\\\"twitter:creator\\\"[^>]*content=\\\"([^\\\"]{2,60})\\\"[^>]*>"
        ]
        for p in patterns {
            if let rx = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]),
               let m = rx.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let r = Range(m.range(at: 1), in: html) {
                var candidate = String(html[r]).trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.hasPrefix("@") { candidate.removeFirst() }
                if isLikelyPersonName(candidate) { return candidate }
            }
        }
        return nil
    }

    private func extractBylineHeuristic(html: String) -> String? {
        // Sehr konservatives Muster: „von <Name>“ / „By <Name>“ nahe dem Anfang
        let snippet = String(html.prefix(10000))
        let patterns = [
            #"(?:\bvon\b|\bby\b)\s+([A-ZÄÖÜ][A-Za-zÄÖÜäöüß'’\-]{1,}\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß'’\-]{1,}(?:\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß'’\-]{1,})?)"#
        ]
        for p in patterns {
            if let rx = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]),
               let m = rx.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)),
               let r = Range(m.range(at: 1), in: snippet) {
                let candidate = String(snippet[r]).trimmingCharacters(in: .whitespacesAndNewlines)
                if isLikelyPersonName(candidate) { return candidate }
            }
        }
        return nil
    }

    private func isLikelyPersonName(_ s: String) -> Bool {
        if s.count < 2 || s.count > 60 { return false }
        if s.contains("@") || s.contains("http") { return false }
        let words = s.split(separator: " ")
        if words.count < 1 || words.count > 4 { return false }
        // Basic character check
        let allowed = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'’"))
        if s.unicodeScalars.contains(where: { !allowed.contains($0) }) { return false }
        // Ausschluss typischer Organisationsbegriffe
        let lower = s.lowercased()
        let orgHints = ["verlag", "media", "news", "press", "diario", "hoy", "zeitung", "gazette", "daily", "sur", "abc", "tribune", "agency", "agencia", "redaction", "redaktion"]
        if orgHints.contains(where: { lower.contains($0) }) { return false }
        return true
    }

    private func detectLanguageCode(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        if let lang = recognizer.dominantLanguage {
            return lang.rawValue
        }
        return nil
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
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        if trimmed.lowercased().hasPrefix("data:") {
            return trimmed
        }
        if trimmed.hasPrefix("//") {
            // Keep scheme from base if possible, else https
            if let base = URL(string: baseURL), let scheme = base.scheme {
                return "\(scheme):\(trimmed)"
            }
            return "https:\(trimmed)"
        }
        // Use Foundation URL resolution for relative paths
        if let base = URL(string: baseURL), let resolved = URL(string: trimmed, relativeTo: base)?.absoluteURL {
            return resolved.absoluteString
        }
        return trimmed
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
    
    // Heuristic isolation of likely article content to improve mainText quality
    private func isolateArticleHTML(_ html: String) -> String {
        // 1) Prefer explicit <article> block
        if let rangeStart = html.range(of: "<article", options: [.caseInsensitive]),
           let closeRange = html.range(of: "</article>", options: [.caseInsensitive], range: rangeStart.lowerBound..<html.endIndex) {
            return String(html[rangeStart.lowerBound..<closeRange.upperBound])
        }
        // 2) Fallback to <main>
        if let rangeStart = html.range(of: "<main", options: [.caseInsensitive]),
           let closeRange = html.range(of: "</main>", options: [.caseInsensitive], range: rangeStart.lowerBound..<html.endIndex) {
            return String(html[rangeStart.lowerBound..<closeRange.upperBound])
        }
        // 3) Fallback: try common containers quickly by class hints; take a window
        let hints = [
            "article-content", "entry-content", "post-content", "content__article", "story-body", "c-article__body", "articleBody"
        ]
        for hint in hints {
            if let hintRange = html.range(of: hint, options: [.caseInsensitive]) {
                let startIndex = html[..<hintRange.lowerBound].range(of: "<div", options: [.backwards, .caseInsensitive])?.lowerBound ?? html.startIndex
                let from = startIndex
                let to = html.index(from, offsetBy: min(200_000, html.distance(from: from, to: html.endIndex)), limitedBy: html.endIndex) ?? html.endIndex
                return String(html[from..<to])
            }
        }
        // 4) Otherwise, return full HTML
        return html
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
        // Extract text content from HTML and remove CSS/JS
        var cleanText = html
        
        // Remove script and style blocks FIRST (so their contents don't leak when tags are stripped)
        cleanText = cleanText.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
        cleanText = cleanText.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove HTML comments
        cleanText = cleanText.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: .regularExpression)
        
        // Remove HTML tags
        cleanText = cleanText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Extra safety: strip leftover CSS blocks and at-rules that might have leaked as plain text
        cleanText = cleanText.replacingOccurrences(of: "@media[^\\{]*\\{[\\s\\S]*?\\}", with: "", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "@keyframes[^\\{]*\\{[\\s\\S]*?\\}", with: "", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)
        
        // Remove remaining CSS rule bodies if any
        cleanText = cleanText.replacingOccurrences(of: "\\{[^}]*\\}", with: "", options: .regularExpression)
        
        // Remove CSS selectors fragments like .class or #id tokens (best-effort)
        cleanText = cleanText.replacingOccurrences(of: "\\.[a-zA-Z0-9_-]+", with: "", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "#[a-zA-Z0-9_-]+", with: "", options: .regularExpression)
        
        // Clean up multiple spaces and newlines
        cleanText = cleanText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanText
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
