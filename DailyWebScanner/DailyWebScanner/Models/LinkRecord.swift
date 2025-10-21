import Foundation
import SwiftData

@Model
final class LinkRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var searchRecordId: UUID  // Reference to parent SearchRecord
    var originalUrl: String
    var title: String
    var content: String
    var html: String
    var css: String
    var extractedText: String  // ← Extracted main text for fast access
    var fetchedAt: Date
    
    // Metadata
    var author: String?
    var publishDate: Date?
    var articleDescription: String?
    var keywords: String?
    var language: String?
    var wordCount: Int
    var readingTime: Int
    
    // Extracted Content (JSON strings for fast access)
    var extractedLinksJSON: String = ""  // JSON of extracted links
    var extractedVideosJSON: String = ""  // JSON of video references (not downloaded)
    var extractedMetadataJSON: String = ""  // JSON of metadata
    
    // Images
    var imageCount: Int
    var totalImageSize: Int  // in bytes
    
    @Relationship(deleteRule: .nullify)
    var images: [ImageRecord] = []
    
    // AI Overview
    var hasAIOverview: Bool
    var aiOverviewJSON: String  // JSON string of AIOverview
    var aiOverviewThumbnail: String?
    var aiOverviewReferences: String?  // JSON string of references
    
    // Content Analysis
    var hasContentAnalysis: Bool
    var contentAnalysisJSON: String  // JSON string of ContentAnalysis
    
    // HTML Preview
    var htmlPreview: String  // Rendered HTML for preview
    
    init(id: UUID = UUID(), searchRecordId: UUID, originalUrl: String, title: String, 
         content: String, html: String, css: String, extractedText: String = "", fetchedAt: Date = .now,
         author: String? = nil, publishDate: Date? = nil, articleDescription: String? = nil,
         keywords: String? = nil, language: String? = nil, wordCount: Int = 0,
         readingTime: Int = 0, imageCount: Int = 0, totalImageSize: Int = 0,
         hasAIOverview: Bool = false, aiOverviewJSON: String = "",
         aiOverviewThumbnail: String? = nil, aiOverviewReferences: String? = nil,
         hasContentAnalysis: Bool = false, contentAnalysisJSON: String = "",
         htmlPreview: String = "") {
        self.id = id
        self.searchRecordId = searchRecordId
        self.originalUrl = originalUrl
        self.title = title
        self.content = content
        self.html = html
        self.css = css
        self.extractedText = extractedText
        self.fetchedAt = fetchedAt
        self.author = author
        self.publishDate = publishDate
        self.articleDescription = articleDescription
        self.keywords = keywords
        self.language = language
        self.wordCount = wordCount
        self.readingTime = readingTime
        self.imageCount = imageCount
        self.totalImageSize = totalImageSize
        self.hasAIOverview = hasAIOverview
        self.aiOverviewJSON = aiOverviewJSON
        self.aiOverviewThumbnail = aiOverviewThumbnail
        self.aiOverviewReferences = aiOverviewReferences
        self.hasContentAnalysis = hasContentAnalysis
        self.contentAnalysisJSON = contentAnalysisJSON
        self.htmlPreview = htmlPreview
    }
}

@Model
final class ImageRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var linkRecordId: UUID  // Reference to parent LinkRecord
    var originalUrl: String
    var localPath: String?
    var altText: String?
    var width: Int?
    var height: Int?
    var fileSize: Int  // in bytes
    var downloadedAt: Date
    
    init(id: UUID = UUID(), linkRecordId: UUID, originalUrl: String,
         localPath: String? = nil, altText: String? = nil, width: Int? = nil,
         height: Int? = nil, fileSize: Int = 0, downloadedAt: Date = .now) {
        self.id = id
        self.linkRecordId = linkRecordId
        self.originalUrl = originalUrl
        self.localPath = localPath
        self.altText = altText
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.downloadedAt = downloadedAt
    }
}
