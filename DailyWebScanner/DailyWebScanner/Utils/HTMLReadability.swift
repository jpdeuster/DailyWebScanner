import Foundation

struct ReadabilityBlock {
    let type: String // paragraph | heading | list
    let text: String
}

struct ReadabilityResult {
    let title: String
    let mainText: String
    let blocks: [ReadabilityBlock]
    let images: [String]
}

/// Readability-ähnliche Extraktion ohne externe Dependencies.
/// Heuristiken: Boilerplate entfernen, Kandidaten-Container scoren (Textlänge, Link-Dichte),
/// Absätze/Listen/Überschriften erhalten, Whitespace normalisieren.
final class HTMLReadability {
    func extract(from html: String, baseURL: URL?) -> ReadabilityResult {
        let htmlSanitized = removeScriptsAndStyles(html)
        let title = extractTitle(htmlSanitized) ?? "Untitled"

        // Entferne offensichtliche Boilerplate-Bereiche vor dem Scoring
        let htmlReduced = removeBoilerplateContainers(htmlSanitized)

        // Kandidatenbereiche sammeln (<article>, <main>, div mit content/article/post)
        let candidates = extractCandidates(htmlReduced)
        let scored = candidates.map { ($0, scoreCandidate($0)) }
        let best = scored.max { $0.1 < $1.1 }?.0 ?? htmlReduced

        // Inhalt in Blöcke extrahieren und normalisieren
        let blocks = extractBlocks(best)
        let mainText = blocks.map { $0.text }.joined(separator: "\n\n")
        let images = extractImages(best, baseURL: baseURL)

        return ReadabilityResult(title: title, mainText: mainText, blocks: blocks, images: images)
    }

    // MARK: - Title
    private func extractTitle(_ html: String) -> String? {
        if let m = firstMatch("<title[^>]*>(.*?)</title>", in: html) {
            return cleanText(m)
        }
        // Fallback: og:title
        if let m = firstMatch("<meta[^>]*property=\"og:title\"[^>]*content=\"([^\"]+)\"", in: html) {
            return cleanText(m)
        }
        return nil
    }

    // MARK: - Boilerplate Removal
    private func removeScriptsAndStyles(_ html: String) -> String {
        return html
            .replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: [.regularExpression])
    }

    private func removeBoilerplateContainers(_ html: String) -> String {
        var reduced = html
        let tags = ["header","nav","footer","aside","form","noscript"]
        for tag in tags {
            reduced = reduced.replacingOccurrences(of: "<\(tag)[^>]*>[\\s\\S]*?</\(tag)>".replacingOccurrences(of: "\\(tag)", with: tag), with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Klassen/IDs mit typischen Noise-Begriffen
        let noise = ["cookie","consent","banner","ads","advert","breadcrumb","sidebar","share","newsletter","related","comments","promo","paywall","subscribe"]
        for key in noise {
            // <div class="...key...">...</div>
            let classPattern = "<div[^>]*class=\\\"[^\\\"]*\(key)[^\\\"]*\\\"[^>]*>[\\s\\S]*?</div>"
                .replacingOccurrences(of: "\\(key)", with: key)
            reduced = reduced.replacingOccurrences(of: classPattern, with: "", options: [.regularExpression, .caseInsensitive])

            // <div id="...key...">...</div>
            let idPattern = "<div[^>]*id=\\\"[^\\\"]*\(key)[^\\\"]*\\\"[^>]*>[\\s\\S]*?</div>"
                .replacingOccurrences(of: "\\(key)", with: key)
            reduced = reduced.replacingOccurrences(of: idPattern, with: "", options: [.regularExpression, .caseInsensitive])
        }

        return reduced
    }

    // MARK: - Candidates and Scoring
    private func extractCandidates(_ html: String) -> [String] {
        var candidates: [String] = []
        
        // <article>...</article>
        candidates.append(contentsOf: allMatches("<article[^>]*>([\\s\\S]*?)</article>", in: html))
        
        // <main>...</main>
        candidates.append(contentsOf: allMatches("<main[^>]*>([\\s\\S]*?)</main>", in: html))
        
        // div with content/article/post classes
        candidates.append(contentsOf: allMatches("<div[^>]*class=\\\"[^\\\"]*(content|article|post|story|text|body)[^\\\"]*\\\"[^>]*>([\\s\\S]*?)</div>", in: html))
        
        // div with content/article/post IDs
        candidates.append(contentsOf: allMatches("<div[^>]*id=\\\"[^\\\"]*(content|article|post|story|text|body)[^\\\"]*\\\"[^>]*>([\\s\\S]*?)</div>", in: html))
        
        // section tags (oft für Artikelinhalt verwendet)
        candidates.append(contentsOf: allMatches("<section[^>]*>([\\s\\S]*?)</section>", in: html))

        // Fallback: Body
        if candidates.isEmpty, let body = firstMatch("<body[^>]*>([\\s\\S]*?)</body>", in: html) {
            candidates.append(body)
        }
        if candidates.isEmpty { candidates.append(html) }
        return candidates
    }

    private func scoreCandidate(_ html: String) -> Double {
        let text = stripTags(html)
        let length = Double(text.count)
        let linkCount = Double(allMatches("<a [^>]*>([\\s\\S]*?)</a>", in: html).count)
        let linkDensity = linkCount / max(1.0, length / 80.0) // grobe Heuristik
        // Bonus für Absätze/Listen/Überschriften
        let pCount = Double(allMatches("<p[^>]*>([\\s\\S]*?)</p>", in: html).count)
        let liCount = Double(allMatches("<li[^>]*>([\\s\\S]*?)</li>", in: html).count)
        let hCount = Double(allMatches("<h[1-6][^>]*>([\\s\\S]*?)</h[1-6]>", in: html).count)
        let structureBonus = pCount * 4.0 + liCount * 1.5 + hCount * 1.0
        // Score: Textlänge + Struktur – Link-Dichte Malstrafe
        return length * 0.01 + structureBonus - linkDensity * 10.0
    }

    // MARK: - Blocks
    private func extractBlocks(_ html: String) -> [ReadabilityBlock] {
        var blocks: [ReadabilityBlock] = []

        // Überschriften (in Reihenfolge)
        let headings = allMatchesWithGroup("<h([1-6])[^>]*>([\\s\\S]*?)</h[1-6]>", in: html)
        for match in headings {
            let text = normalizeWhitespace(stripTags(match.1))
            if !text.isEmpty { blocks.append(ReadabilityBlock(type: "heading", text: text)) }
        }

        // Absätze
        let paragraphs = allMatches("<p[^>]*>([\\s\\S]*?)</p>", in: html)
        for p in paragraphs {
            let text = normalizeWhitespace(stripTags(p))
            if text.count > 0 { blocks.append(ReadabilityBlock(type: "paragraph", text: text)) }
        }

        // Listen
        let lis = allMatches("<li[^>]*>([\\s\\S]*?)</li>", in: html)
        if !lis.isEmpty {
            let text = lis.map { normalizeWhitespace(stripTags($0)) }.filter { !$0.isEmpty }.joined(separator: "\n")
            if !text.isEmpty { blocks.append(ReadabilityBlock(type: "list", text: text)) }
        }

        // Zusätzliche Content-Container für bessere Abdeckung
        let divs = allMatches("<div[^>]*>([\\s\\S]*?)</div>", in: html)
        for div in divs {
            let text = normalizeWhitespace(stripTags(div))
            // Nur längere Textblöcke hinzufügen (mindestens 50 Zeichen)
            if text.count > 50 && !isDuplicateContent(text, in: blocks) {
                blocks.append(ReadabilityBlock(type: "paragraph", text: text))
            }
        }

        // Fallback, wenn keine Blöcke gefunden wurden: gesamten Body als Paragraph
        if blocks.isEmpty {
            let text = normalizeWhitespace(stripTags(html))
            if !text.isEmpty { blocks.append(ReadabilityBlock(type: "paragraph", text: text)) }
        }
        
        return blocks
    }
    
    // Hilfsfunktion um Duplikate zu vermeiden
    private func isDuplicateContent(_ text: String, in blocks: [ReadabilityBlock]) -> Bool {
        let normalizedText = normalizeWhitespace(text)
        return blocks.contains { block in
            let similarity = calculateSimilarity(normalizedText, block.text)
            return similarity > 0.8 // 80% Ähnlichkeit = Duplikat
        }
    }
    
    // Einfache Ähnlichkeitsberechnung
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let words2 = Set(text2.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    // MARK: - Images
    private func extractImages(_ html: String, baseURL: URL?) -> [String] {
        let raw = allMatches("<img[^>]+src=\\\"([^\\\"]+)\\\"[^>]*>", in: html)
        guard let baseURL else { return raw }
        return raw.map { resolveURL($0, base: baseURL) }
    }

    private func resolveURL(_ urlString: String, base: URL) -> String {
        if urlString.hasPrefix("http") { return urlString }
        if urlString.hasPrefix("//") { return "https:\\" + urlString }
        if urlString.hasPrefix("/") {
            let scheme = base.scheme ?? "https"
            let host = base.host ?? ""
            return "\(scheme)://\(host)\(urlString)"
        }
        return base.appendingPathComponent(urlString).absoluteString
    }

    // MARK: - Helpers
    private func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges >= 2 else { return nil }
        if let r = Range(match.range(at: 1), in: text) { return String(text[r]) }
        return nil
    }

    private func allMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(location: 0, length: text.utf16.count)
        var matches: [String] = []
        regex.enumerateMatches(in: text, options: [], range: range) { m, _, _ in
            if let m, m.numberOfRanges >= 2, let r = Range(m.range(at: 1), in: text) {
                matches.append(String(text[r]))
            }
        }
        return matches
    }

    private func allMatchesWithGroup(_ pattern: String, in text: String) -> [(String,String)] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(location: 0, length: text.utf16.count)
        var matches: [(String,String)] = []
        regex.enumerateMatches(in: text, options: [], range: range) { m, _, _ in
            if let m, m.numberOfRanges >= 3,
               let r1 = Range(m.range(at: 1), in: text),
               let r2 = Range(m.range(at: 2), in: text) {
                matches.append((String(text[r1]), String(text[r2])))
            }
        }
        return matches
    }

    private func stripTags(_ html: String) -> String {
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private func cleanText(_ html: String) -> String {
        normalizeWhitespace(stripTags(html))
    }

    private func normalizeWhitespace(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(of: "[\\t\\f\\r ]+", with: " ", options: .regularExpression)
        return collapsed.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


