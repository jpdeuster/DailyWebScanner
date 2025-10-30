import Foundation

/// Intelligente Content-Qualitätsbewertung und Filterung
struct ContentQualityFilter {
    
    // MARK: - Quality Thresholds
    static let minWordCount = 50
    static let minReadingTime = 1 // minutes
    static let maxLinkDensity = 0.3 // 30% links vs text
    static let minContentLength = 200 // characters
    
    // MARK: - URL Patterns to Exclude (editable via settings)
    static var excludedUrlPatterns: [String] { QualityConfig.shared.excludedUrlPatterns }
    
    // MARK: - Content Quality Indicators (mehrsprachig, editable)
    static var qualityIndicators: [String] { QualityConfig.shared.qualityIndicators }
    
    static var lowQualityIndicators: [String] { QualityConfig.shared.lowQualityIndicators }
    
    // Mehrsprachige Content-Qualitätskriterien (editable)
    static var meaningfulContentPatterns: [String] { QualityConfig.shared.meaningfulContentPatterns }
    
    static var emptyContentPatterns: [String] { QualityConfig.shared.emptyContentPatterns }
    
    // MARK: - Main Quality Assessment
    static func assessQuality(for linkRecord: LinkRecord) -> ContentQuality {
        let url = linkRecord.originalUrl.lowercased()
        let title = linkRecord.title.lowercased()
        let content = linkRecord.content.lowercased()
        
        // Nur technische/strukturelle URL-Ausschlüsse
        if isExcludedUrl(url) {
            return .excluded(reason: "Technical/structural URL pattern excluded")
        }
        
        // Check basic content requirements
        if linkRecord.wordCount < minWordCount {
            return .low(reason: "Too few words (\(linkRecord.wordCount) < \(minWordCount))")
        }
        
        if linkRecord.readingTime < minReadingTime {
            return .low(reason: "Too short reading time (\(linkRecord.readingTime) < \(minReadingTime) min)")
        }
        
        if linkRecord.content.count < minContentLength {
            return .low(reason: "Content too short (\(linkRecord.content.count) < \(minContentLength) chars)")
        }
        
        // Calculate link density
        let linkDensity = calculateLinkDensity(content: linkRecord.content)
        if linkDensity > maxLinkDensity {
            return .low(reason: "High link density (\(Int(linkDensity * 100))% > \(Int(maxLinkDensity * 100))%)")
        }
        
        // Check for meaningful content patterns (deutsch)
        let hasMeaningfulContent = meaningfulContentPatterns.contains { pattern in
            content.contains(pattern)
        }
        
        // Check for empty content patterns
        let hasEmptyContent = emptyContentPatterns.contains { pattern in
            content.contains(pattern)
        }
        
        // Check for quality indicators
        let hasQualityIndicators = qualityIndicators.contains { indicator in
            title.contains(indicator) || content.contains(indicator)
        }
        
        let hasLowQualityIndicators = lowQualityIndicators.contains { indicator in
            title.contains(indicator) || content.contains(indicator)
        }
        
        // Check for meaningful content structure
        let hasStructure = hasParagraphs(content: linkRecord.content) || 
                          hasHeadings(content: linkRecord.content) ||
                          hasLists(content: linkRecord.content)
        
        // Content-Qualitätsbewertung basierend auf Inhalt, nicht URL
        if hasEmptyContent && !hasMeaningfulContent {
            return .low(reason: "Contains empty content patterns")
        }
        
        if hasLowQualityIndicators && !hasQualityIndicators && !hasMeaningfulContent {
            return .low(reason: "Contains low-quality indicators without meaningful content")
        }
        
        if !hasStructure && !hasMeaningfulContent {
            return .low(reason: "Lacks content structure and meaningful content")
        }
        
        // Positive Bewertung für guten Content
        if hasMeaningfulContent && linkRecord.wordCount > Int(Double(minWordCount) * 1.5) {
            return .high(reason: "High-quality content with meaningful patterns")
        }
        
        if hasQualityIndicators && linkRecord.wordCount > minWordCount * 2 {
            return .high(reason: "High-quality content with good indicators")
        }
        
        if hasMeaningfulContent || hasStructure {
            return .medium(reason: "Standard quality content with some structure")
        }
        
        return .medium(reason: "Standard quality content")
    }
    
    // MARK: - Helper Methods
    
    private static func isExcludedUrl(_ url: String) -> Bool {
        return excludedUrlPatterns.contains { pattern in
            url.contains(pattern)
        }
    }
    
    private static func calculateLinkDensity(content: String) -> Double {
        let linkMatches = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.contains("http") || $0.hasPrefix("www.") }
        let totalWords = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !totalWords.isEmpty else { return 0.0 }
        return Double(linkMatches.count) / Double(totalWords.count)
    }
    
    private static func hasParagraphs(content: String) -> Bool {
        return content.components(separatedBy: "\n\n").count > 2
    }
    
    private static func hasHeadings(content: String) -> Bool {
        return content.contains("#") || content.contains("**") || content.contains("##")
    }
    
    private static func hasLists(content: String) -> Bool {
        return content.contains("- ") || content.contains("* ") || content.contains("1. ")
    }
}

// MARK: - Content Quality Enum

enum ContentQuality: Equatable {
    case high(reason: String)
    case medium(reason: String)
    case low(reason: String)
    case excluded(reason: String)
    
    var isVisible: Bool {
        switch self {
        case .high, .medium:
            return true
        case .low, .excluded:
            return false
        }
    }
    
    var displayReason: String {
        switch self {
        case .high(let reason), .medium(let reason), .low(let reason), .excluded(let reason):
            return reason
        }
    }
    
    var icon: String {
        switch self {
        case .high:
            return "star.fill"
        case .medium:
            return "star"
        case .low:
            return "exclamationmark.triangle"
        case .excluded:
            return "xmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .high:
            return "green"
        case .medium:
            return "blue"
        case .low:
            return "orange"
        case .excluded:
            return "red"
        }
    }
}
