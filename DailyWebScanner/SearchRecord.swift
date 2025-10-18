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

    @Relationship(deleteRule: .cascade)
    var results: [SearchResult]

    init(id: UUID = UUID(), query: String, createdAt: Date = .now, htmlSummary: String = "", 
         language: String = "", region: String = "", location: String = "", safeSearch: String = "",
         searchType: String = "", timeRange: String = "", numberOfResults: Int = 20,
         searchDuration: TimeInterval = 0.0, resultCount: Int = 0, results: [SearchResult] = []) {
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
        self.results = results
    }
}
