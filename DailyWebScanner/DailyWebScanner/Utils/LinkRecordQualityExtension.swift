import Foundation

extension LinkRecord {
    
    /// Bewertet die Content-Qualität und aktualisiert die entsprechenden Felder
    func assessContentQuality() {
        let quality = ContentQualityFilter.assessQuality(for: self)
        
        switch quality {
        case .high(let reason):
            self.contentQuality = "high"
            self.qualityReason = reason
            self.isVisible = true
            
        case .medium(let reason):
            self.contentQuality = "medium"
            self.qualityReason = reason
            self.isVisible = true
            
        case .low(let reason):
            self.contentQuality = "low"
            self.qualityReason = reason
            self.isVisible = false
            
        case .excluded(let reason):
            self.contentQuality = "excluded"
            self.qualityReason = reason
            self.isVisible = false
        }
    }
    
    /// Erstellt einen temporären LinkRecord für die Qualitätsbewertung
    static func createForQualityAssessment(
        url: String,
        title: String,
        content: String,
        wordCount: Int,
        readingTime: Int,
        author: String? = nil
    ) -> LinkRecord {
        let record = LinkRecord(
            searchRecordId: UUID(),
            originalUrl: url,
            title: title,
            content: content,
            extractedText: content,
            author: author,
            wordCount: wordCount,
            readingTime: readingTime
        )
        return record
    }
}
