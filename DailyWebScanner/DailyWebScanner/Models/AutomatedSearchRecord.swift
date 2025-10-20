import Foundation
import SwiftData

@Model
class AutomatedSearchRecord {
    var id: UUID
    var query: String
    var language: String
    var region: String
    var location: String
    var safe: String
    var tbm: String
    var tbs: String
    var as_qdr: String
    var nfpr: String
    var filter: String
    var timestamp: Date
    var results: [SearchResult]
    
    // Automation properties
    var isEnabled: Bool
    var scheduledTime: String
    var executionCount: Int
    var lastExecutionDate: Date?
    
    init(
        query: String,
        language: String = "",
        region: String = "",
        location: String = "",
        safe: String = "off",
        tbm: String = "",
        tbs: String = "",
        as_qdr: String = "",
        nfpr: String = "",
        filter: String = "",
        scheduledTime: String = ""
    ) {
        self.id = UUID()
        self.query = query
        self.language = language
        self.region = region
        self.location = location
        self.safe = safe
        self.tbm = tbm
        self.tbs = tbs
        self.as_qdr = as_qdr
        self.nfpr = nfpr
        self.filter = filter
        self.timestamp = Date()
        self.results = []
        
        // Automation properties
        self.isEnabled = true
        self.scheduledTime = scheduledTime
        self.executionCount = 0
        self.lastExecutionDate = nil
    }
}
