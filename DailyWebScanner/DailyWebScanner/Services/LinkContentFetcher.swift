import Foundation
import SwiftUI
#if canImport(WebKit)
import WebKit
#endif
import ImageIO

// MARK: - Link Content Models

struct LinkContent: Codable {
    let url: String
    let title: String
    let content: String
    let blocks: [ContentBlockItem]?
    let images: [ImageData]
    let metadata: ArticleMetadata
    let fetchedAt: Date
    // HTML/CSS entfernt (nur noch Plain Text)
    let aiOverview: AIOverview?
}

struct ContentBlockItem: Codable {
    let type: String // paragraph | heading | list
    let text: String
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
        var htmlContent = try await fetchHTML(from: articleURL)
        
        // Heuristik: Wenn zu wenig Text oder sehr hohe Link-Dichte, versuche JS-Render-Fallback
        if shouldRenderWithWebView(htmlContent) {
            if let rendered = try? await renderHTMLWithWebView(articleURL) {
                htmlContent = rendered
            }
        }
        
        // Parse HTML main content with Readability-style extractor
        let readability = HTMLReadability()
        let result = readability.extract(from: htmlContent, baseURL: articleURL)
        
        // Download and store images
        let images = try await downloadImages(result.images, baseURL: articleURL)
        
        // Extract metadata from HTML & computed text
        let metadata = extractMetadata(fromHTML: htmlContent, title: result.title, mainText: result.mainText)
        
        // Extract AI Overview if available
        let aiOverview = extractAIOverview(from: htmlContent)
        
               let linkContent = LinkContent(
                   url: url,
                   title: result.title,
                   content: result.mainText,
                   blocks: result.blocks.map { ContentBlockItem(type: $0.type, text: $0.text) },
                   images: images,
                   metadata: metadata,
                   fetchedAt: Date(),
                   aiOverview: aiOverview
               )
               
               return linkContent
    }
    
    // MARK: - Content Quality Assessment
    
    /// Bewertet die Content-Qualität für ein LinkContent-Objekt
    func assessContentQuality(for linkContent: LinkContent) -> (quality: String, reason: String, isVisible: Bool) {
        let tempRecord = LinkRecord.createForQualityAssessment(
            url: linkContent.url,
            title: linkContent.title,
            content: linkContent.content,
            wordCount: linkContent.metadata.wordCount,
            readingTime: linkContent.metadata.readingTime,
            author: linkContent.metadata.author
        )
        
        let quality = ContentQualityFilter.assessQuality(for: tempRecord)
        
        switch quality {
        case .high(let reason):
            return ("high", reason, true)
        case .medium(let reason):
            return ("medium", reason, true)
        case .low(let reason):
            return ("low", reason, false)
        case .excluded(let reason):
            return ("excluded", reason, false)
        }
    }
    
    // MARK: - HTML Fetching
    
    private func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        // Realistischere Header für bessere Server-Akzeptanz
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 30

        // Einfache Retry-Logik bei transienten Fehlern
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LinkContentError.fetchFailed
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    // Bei 429/5xx ggf. retry
                    if httpResponse.statusCode == 429 || (500..<600).contains(httpResponse.statusCode) {
                        throw LinkContentError.fetchFailed
                    }
                    throw LinkContentError.fetchFailed
                }

                // Robuste Encoding-Erkennung und Decoding
                let html = try decodeHTMLData(data, response: httpResponse)
                return html
            } catch {
                lastError = error
                // Exponentielles Backoff (100ms, 300ms)
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: UInt64(100_000_000 * (attempt == 0 ? 1 : 3)))
                    continue
                }
            }
        }

        throw lastError ?? LinkContentError.fetchFailed
    }

    // MARK: - JS-Rendering Fallback (WKWebView)
    private func shouldRenderWithWebView(_ html: String) -> Bool {
        let text = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        let wordCount = words.count
        let links = matchesCount(pattern: "<a [^>]*>([\\s\\S]*?)</a>", in: html)
        let linkDensity = Double(links) / max(1.0, Double(wordCount) / 80.0)
        return wordCount < 200 || linkDensity > 1.5
    }

    private func matchesCount(pattern: String, in text: String) -> Int {
        (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]))
            .map { $0.numberOfMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) } ?? 0
    }

    private func renderHTMLWithWebView(_ url: URL) async throws -> String {
        #if canImport(WebKit)
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let webView = WKWebView(frame: .zero)
                let request = URLRequest(url: url)
                webView.load(request)
                // Warte bis "loaded" und dann JavaScript zum Extrahieren von outerHTML
                let work = {
                    webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let html = result as? String {
                            continuation.resume(returning: html)
                        } else {
                            continuation.resume(throwing: LinkContentError.fetchFailed)
                        }
                    }
                }
                // Kleines Timeout-Fenster (z. B. 3 Sekunden nach load nachfassen)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
            }
        }
        #else
        throw LinkContentError.fetchFailed
        #endif
    }

    // MARK: - Encoding Detection & Decoding

    private func decodeHTMLData(_ data: Data, response: HTTPURLResponse) throws -> String {
        // 1) HTTP Header charset auswerten
        if let contentType = response.value(forHTTPHeaderField: "Content-Type"),
           let charsetName = parseCharset(from: contentType),
           let enc = encoding(from: charsetName),
           let html = String(data: data, encoding: enc) {
            return html
        }

        // 2) BOM erkennen
        if let bomEncoding = detectBOM(data), let html = String(data: data, encoding: bomEncoding) {
            return html
        }

        // 3) Grob als ISO-8859-1 decodieren, um <meta charset> heuristisch lesen zu können
        let latin1 = String(data: data, encoding: .isoLatin1)
        if let latin1 = latin1 {
            if let metaCharset = extractMetaCharset(from: latin1),
               let enc = encoding(from: metaCharset),
               let html = String(data: data, encoding: enc) {
                return html
            }
        }

        // 4) Häufige Fallbacks
        if let html = String(data: data, encoding: .utf8) { return html }
        if let html = String(data: data, encoding: .windowsCP1252) { return html }
        if let html = String(data: data, encoding: .isoLatin1) { return html }

        throw LinkContentError.encodingFailed
    }

    private func parseCharset(from contentType: String) -> String? {
        // Beispiel: text/html; charset=UTF-8
        let parts = contentType.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        for part in parts {
            let lower = part.lowercased()
            if lower.hasPrefix("charset=") {
                let value = lower.replacingOccurrences(of: "charset=", with: "")
                return value.replacingOccurrences(of: "\"", with: "")
            }
        }
        return nil
    }

    private func encoding(from charset: String) -> String.Encoding? {
        // Versuche IANA-Name -> CFStringEncodings -> String.Encoding
        let upper = charset.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if upper == "UTF8" { return .utf8 }
        if upper == "UTF-8" { return .utf8 }
        if upper == "ISO-8859-1" || upper == "ISO8859-1" || upper == "LATIN1" { return .isoLatin1 }
        if upper == "WINDOWS-1252" || upper == "CP1252" { return .windowsCP1252 }

        let cfEnc = CFStringConvertIANACharSetNameToEncoding(upper as CFString)
        if cfEnc != kCFStringEncodingInvalidId {
            let nsEnc = CFStringConvertEncodingToNSStringEncoding(cfEnc)
            return String.Encoding(rawValue: nsEnc)
        }
        return nil
    }

    private func detectBOM(_ data: Data) -> String.Encoding? {
        if data.count >= 3 {
            // UTF-8 BOM: EF BB BF
            if data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF { return .utf8 }
        }
        if data.count >= 2 {
            // UTF-16 BE BOM: FE FF
            if data[0] == 0xFE && data[1] == 0xFF { return .utf16BigEndian }
            // UTF-16 LE BOM: FF FE
            if data[0] == 0xFF && data[1] == 0xFE { return .utf16LittleEndian }
        }
        if data.count >= 4 {
            // UTF-32 BE BOM: 00 00 FE FF
            if data[0] == 0x00 && data[1] == 0x00 && data[2] == 0xFE && data[3] == 0xFF { return .utf32BigEndian }
            // UTF-32 LE BOM: FF FE 00 00
            if data[0] == 0xFF && data[1] == 0xFE && data[2] == 0x00 && data[3] == 0x00 { return .utf32LittleEndian }
        }
        return nil
    }

    private func extractMetaCharset(from htmlSnippet: String) -> String? {
        // Suche nach <meta charset="..."> oder http-equiv
        // Nur in den ersten ~8 KB suchen
        let prefix = String(htmlSnippet.prefix(8192))
        let patterns = [
            "<meta[^>]*charset=\"?([^\\\"'>\\s]+)\"?[^>]*>",
            "<meta[^>]*http-equiv=\"content-type\"[^>]*content=\"[^\\\"]*;\\s*charset=([^\\\"'>\\s]+)\"[^>]*>"
        ]
        for pat in patterns {
            if let regex = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: prefix.utf16.count)
                if let match = regex.firstMatch(in: prefix, options: [], range: range), match.numberOfRanges >= 2 {
                    if let r = Range(match.range(at: 1), in: prefix) {
                        return String(prefix[r])
                    }
                }
            }
        }
        return nil
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
    
    private func extractMetadata(fromHTML html: String, title: String, mainText: String) -> ArticleMetadata {
        let author = extractAuthor(fromHTML: html)
        let publishDate = extractPublishDate(fromHTML: html)
        let description = extractDescription(fromHTML: html)
        let keywords = extractKeywords(fromHTML: html)
        let language = extractLanguage(fromHTML: html)

        let wordCount = mainText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        let readingTime = max(1, wordCount / 200) // Assume 200 words per minute
        
        return ArticleMetadata(
            author: author,
            publishDate: publishDate,
            description: description,
            keywords: keywords,
            language: language,
            wordCount: wordCount,
            readingTime: readingTime
        )
    }

    // MARK: - Metadata (OG/Twitter/JSON-LD/Meta)

    private func extractAuthor(fromHTML html: String) -> String? {
        let patterns = [
            "<meta[^>]*name=\"author\"[^>]*content=\"([^\"]+)\"",
            "<meta[^>]*property=\"article:author\"[^>]*content=\"([^\"]+)\"",
            "<meta[^>]*name=\"twitter:creator\"[^>]*content=\"@?([^\"]+)\"",
            "<span[^>]*class=\"[^\"]*author[^\"]*\"[^>]*>([\\s\\S]*?)</span>"
        ]
        if let v = firstMatch(in: html, patterns: patterns) { return stripTags(v).trimmingCharacters(in: .whitespacesAndNewlines) }
        // JSON-LD
        if let ld = firstJsonLd(html), let author = jsonLdString(ld, keys: ["author","creator","publisher","creator.name","author.name","publisher.name"]) { return author }
        return nil
    }

    private func extractPublishDate(fromHTML html: String) -> Date? {
        let patterns = [
            "<meta[^>]*property=\"article:published_time\"[^>]*content=\"([^\"]+)\"",
            "<time[^>]*datetime=\"([^\"]+)\"",
            "<meta[^>]*name=\"date\"[^>]*content=\"([^\"]+)\""
        ]
        if let s = firstMatch(in: html, patterns: patterns) {
            if let d = ISO8601DateFormatter().date(from: s) { return d }
            // try RFC 3339-lite
            let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let d = f.date(from: s) { return d }
        }
        if let ld = firstJsonLd(html) {
            if let s = jsonLdString(ld, keys: ["datePublished","dateCreated","uploadDate"]) {
                if let d = ISO8601DateFormatter().date(from: s) { return d }
                let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let d = f.date(from: s) { return d }
            }
        }
        return nil
    }

    private func extractDescription(fromHTML html: String) -> String? {
        let patterns = [
            "<meta[^>]*name=\"description\"[^>]*content=\"([^\"]+)\"",
            "<meta[^>]*property=\"og:description\"[^>]*content=\"([^\"]+)\""
        ]
        if let v = firstMatch(in: html, patterns: patterns) { return stripTags(v).trimmingCharacters(in: .whitespacesAndNewlines) }
        if let ld = firstJsonLd(html), let s = jsonLdString(ld, keys: ["description","headline"]) { return s }
        return nil
    }

    private func extractKeywords(fromHTML html: String) -> [String] {
        if let s = firstMatch(in: html, patterns: ["<meta[^>]*name=\"keywords\"[^>]*content=\"([^\"]+)\""]) {
            return s.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        if let ld = firstJsonLd(html), let s = jsonLdString(ld, keys: ["keywords"]) {
            return s.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        return []
    }

    private func extractLanguage(fromHTML html: String) -> String? {
        if let v = firstMatch(in: html, patterns: ["<html[^>]*lang=\"([^\"]+)\""]) { return v }
        if let v = firstMatch(in: html, patterns: ["<meta[^>]*http-equiv=\"content-language\"[^>]*content=\"([^\"]+)\""]) { return v }
        return nil
    }

    // MARK: - Small helpers
    private func firstMatch(in text: String, patterns: [String]) -> String? {
        for p in patterns {
            if let regex = try? NSRegularExpression(pattern: p, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let m = regex.firstMatch(in: text, options: [], range: range), m.numberOfRanges >= 2, let r = Range(m.range(at: 1), in: text) {
                    return String(text[r])
                }
            }
        }
        return nil
    }

    private func stripTags(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private func firstJsonLd(_ html: String) -> Any? {
        let pattern = "<script[^>]*type=\"application/ld\\+json\"[^>]*>([\\s\\S]*?)</script>"
        if let json = firstMatch(in: html, patterns: [pattern]) {
            if let data = json.data(using: .utf8), let obj = try? JSONSerialization.jsonObject(with: data) { return obj }
        }
        return nil
    }

    private func jsonLdString(_ obj: Any, keys: [String]) -> String? {
        // Unterstützt flache Keys und dotted keys wie "author.name"
        func value(for dotted: String, in dict: [String: Any]) -> Any? {
            let parts = dotted.split(separator: ".").map(String.init)
            var current: Any? = dict
            for p in parts {
                if let d = current as? [String: Any] { current = d[p] }
                else { return nil }
            }
            return current
        }

        if let dict = obj as? [String: Any] {
            for k in keys {
                if let v = value(for: k, in: dict) as? String { return v }
                if let v = dict[k] as? String { return v }
                if let a = dict[k] as? [[String: Any]] { if let v = a.first?["name"] as? String { return v } }
                if let d = dict[k] as? [String: Any], let v = d["name"] as? String { return v }
            }
        } else if let arr = obj as? [[String: Any]] {
            for item in arr {
                if let s = jsonLdString(item, keys: keys) { return s }
            }
        }
        return nil
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
