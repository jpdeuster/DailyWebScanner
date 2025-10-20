import Foundation
import SwiftData

@Model
final class SearchRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var query: String
    var createdAt: Date
    var htmlSummary: String
    
    // Search Parameters
    var language: String = ""
    var region: String = ""
    var location: String = ""
    var safeSearch: String = ""
    var searchType: String = ""
    var timeRange: String = ""
    var numberOfResults: Int = 20
    
    // Additional metadata
    var searchDuration: TimeInterval = 0.0
    var resultCount: Int = 0
    
    // Automated Search Properties
    var isEnabled: Bool = true
    var executionCount: Int = 0
    var lastExecutionDate: Date?
    var scheduledTime: String = "10:00"  // HH:MM format
    var dateRange: String = ""  // For timeRange parameter
    
    // Content Analysis
    var contentAnalysis: String = ""  // JSON string of ContentAnalysis
    var headlinesCount: Int = 0
    var linksCount: Int = 0
    var contentBlocksCount: Int = 0
    var tagsCount: Int = 0
    var hasContentAnalysis: Bool = false
    
    // Link Content Storage
    var linkContents: String = ""  // JSON string of [LinkContent]
    var hasLinkContents: Bool = false
    var totalImagesDownloaded: Int = 0
    var totalContentSize: Int = 0  // in bytes

    @Relationship(deleteRule: .nullify)
    var results: [SearchResult]
    
    @Relationship(deleteRule: .nullify)
    var linkRecords: [LinkRecord]

    init(id: UUID = UUID(), query: String, createdAt: Date = .now, htmlSummary: String = "",
         language: String = "", region: String = "", location: String = "", safeSearch: String = "",
         searchType: String = "", timeRange: String = "", numberOfResults: Int = 20,
         searchDuration: TimeInterval = 0.0, resultCount: Int = 0, results: [SearchResult] = [],
         contentAnalysis: String = "", headlinesCount: Int = 0, linksCount: Int = 0, 
         contentBlocksCount: Int = 0, tagsCount: Int = 0, hasContentAnalysis: Bool = false,
         linkContents: String = "", hasLinkContents: Bool = false, totalImagesDownloaded: Int = 0,
         totalContentSize: Int = 0, isEnabled: Bool = true, executionCount: Int = 0,
         lastExecutionDate: Date? = nil, scheduledTime: String = "10:00", dateRange: String = "") {
        self.id = id
        self.query = query
        self.createdAt = createdAt
        self.htmlSummary = htmlSummary
        self.language = language
        self.region = region
        self.location = location
        self.safeSearch = safeSearch
        self.searchType = searchType
        self.timeRange = timeRange
        self.numberOfResults = numberOfResults
        self.searchDuration = searchDuration
        self.resultCount = resultCount
        self.contentAnalysis = contentAnalysis
        self.headlinesCount = headlinesCount
        self.linksCount = linksCount
        self.contentBlocksCount = contentBlocksCount
        self.tagsCount = tagsCount
        self.hasContentAnalysis = hasContentAnalysis
        self.linkContents = linkContents
        self.hasLinkContents = hasLinkContents
        self.totalImagesDownloaded = totalImagesDownloaded
        self.totalContentSize = totalContentSize
        self.isEnabled = isEnabled
        self.executionCount = executionCount
        self.lastExecutionDate = lastExecutionDate
        self.scheduledTime = scheduledTime
        self.dateRange = dateRange
        self.results = results
        self.linkRecords = []
    }
}
