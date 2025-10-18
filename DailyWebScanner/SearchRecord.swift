import Foundation
import SwiftData

@Model
final class SearchRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var query: String
    var createdAt: Date
    var htmlSummary: String

    @Relationship(deleteRule: .cascade)
    var results: [SearchResult]

    init(id: UUID = UUID(), query: String, createdAt: Date = .now, htmlSummary: String = "", results: [SearchResult] = []) {
        self.id = id
        self.query = query
        self.createdAt = createdAt
        self.htmlSummary = htmlSummary
        self.results = results
    }
}
