import Foundation
import SwiftData

@Model
final class SearchResult: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var link: String
    var snippet: String
    var summary: String

    init(id: UUID = UUID(), title: String, link: String, snippet: String, summary: String = "") {
        self.id = id
        self.title = title
        self.link = link
        self.snippet = snippet
        self.summary = summary
    }
}
