# DailyWebScanner - Current Architecture Documentation

## 🎯 Overview

This document describes the current architecture of DailyWebScanner, a macOS application for comprehensive web search, content analysis, and article storage using SwiftData and modern SwiftUI.

## 📊 Current Status (Updated 2025-10-30)
- ✅ **SwiftData Integration** - Fully implemented
- ✅ **SearchRecord System** - Complete search session management
- ✅ **LinkRecord System** - Individual article storage and analysis
- ✅ **ImageRecord System** - Image management and storage
- ✅ **Tag System** - Global tags with Many-to-Many to LinkRecord
- ✅ **Quality Control** - Content quality assessment + customizable patterns
- ✅ **AI Integration** - OpenAI and Google AI Overview
- ✅ **Per-Search Parameters** - Dynamic search configuration
- ✅ **Multi-Window UI** - Separate windows for different views
- ✅ **API Status Bar** - SerpAPI/OpenAI status + credits display
- ✅ **JSON Persistence** - Links/Videos/Metadata saved as JSON strings
- ✅ **Robust DB Size** - Detects store/sqlite + WAL/SHM
- ✅ **Auto-Open Articles** - App setting to open Articles on launch

## 🏗️ Architecture Overview

### **Core Components:**
```
DailyWebScanner App
├── SwiftData Models
│   ├── SearchRecord (Main search sessions)
│   ├── LinkRecord (Individual articles)
│   ├── ImageRecord (Image storage)
│   └── Tag (Global tags)
├── API Integration
│   ├── SerpAPIClient (Google search)
│   ├── OpenAIClient (AI summaries)
│   └── LinkContentFetcher (Article extraction + quality assessment)
├── Quality & Config
│   ├── ContentQualityFilter (Heuristics + pattern lists)
│   └── QualityConfig (persisted, user-editable lists)
├── User Interface
│   ├── ContentView (Main search interface)
│   ├── SearchQueriesView (Article management)
│   ├── APISettingsView (API configuration)
│   ├── SearchParametersView (Per-search settings)
│   ├── TagsView (Global tag management)
│   ├── LinkDetailView (Per-article tag editor)
│   ├── QualityControlView (Stats + actions)
│   └── QualityTermsEditorView (Edit filter terms)
└── Data Management
    ├── SwiftData Container
    ├── Keychain Integration
    └── Content Analysis
```

## 📊 Data Models

### **1. SearchRecord - Main Search Sessions**
```swift
@Model
final class SearchRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var query: String
    var createdAt: Date
    var summary: String
    
    // Search Parameters
    var language: String = ""
    var region: String = ""
    var location: String = ""
    var safeSearch: String = ""
    var searchType: String = ""
    var timeRange: String = ""
    var numberOfResults: Int = 20
    
    // Metadata
    var searchDuration: TimeInterval = 0.0
    var resultCount: Int = 0
    
    // Content Analysis
    var contentAnalysis: String = ""  // JSON string
    var headlinesCount: Int = 0
    var linksCount: Int = 0
    var contentBlocksCount: Int = 0
    var tagsCount: Int = 0
    var hasContentAnalysis: Bool = false
    
    // Link Content Storage
    var linkContents: String = ""  // JSON string
    var hasLinkContents: Bool = false
    var totalImagesDownloaded: Int = 0
    var totalContentSize: Int = 0
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var results: [SearchResult]
    
    @Relationship(deleteRule: .cascade)
    var linkRecords: [LinkRecord]
}
```

### **2. LinkRecord - Individual Articles**
```swift
@Model
final class LinkRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var searchRecordId: UUID
    var originalUrl: String
    var title: String
    var content: String
    var fetchedAt: Date
    
    // Metadata
    var author: String?
    var publishDate: Date?
    var articleDescription: String?
    var keywords: String?
    var language: String?
    var wordCount: Int
    var readingTime: Int

    // Quality
    var contentQuality: String   // high|medium|low|excluded
    var qualityReason: String
    var isVisible: Bool

    // Tags
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]

    // Images
    var imageCount: Int
    var totalImageSize: Int
    var images: [ImageRecord] = []

    // AI Overview
    var hasAIOverview: Bool
    var aiOverviewJSON: String
    var aiOverviewThumbnail: String?
    var aiOverviewReferences: String?
    
    // Content Analysis
    var hasContentAnalysis: Bool
    var contentAnalysisJSON: String

    // Preview
    var preview: String
}
```

### **3. Tag - Global Tags**
```swift
@Model
final class Tag: Identifiable {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var createdAt: Date
}
```

### **4. ImageRecord - Image Storage**
```swift
@Model
final class ImageRecord: Identifiable {
    @Attribute(.unique) var id: UUID
    var linkRecordId: UUID
    var imageUrl: String
    var imageData: Data
    var imageSize: Int
    var imageType: String
}
```

### **4. SearchResult - Search Results**
```swift
@Model
final class SearchResult: Identifiable {
    @Attribute(.unique) var id: UUID
    var searchRecordId: UUID
    var title: String
    var url: String
    var snippet: String
    var position: Int
    var domain: String
    var faviconUrl: String?
    var imageUrl: String?
    var publishedDate: Date?
    var author: String?
    var sourceType: String
    var relevanceScore: Double
    var clickCount: Int
    var bookmarkCount: Int
}
```

## 🔧 Implementation Details

### **SwiftData Container Setup**
```swift
var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        SearchRecord.self,
        SearchResult.self,
        LinkRecord.self,
        ImageRecord.self,
        Tag.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

### **Search Workflow**
1. **User Input**: Search query with parameters
2. **SerpAPI Call**: Google search via SerpAPI
3. **SearchRecord Creation**: Store search session
4. **Content Extraction**: Fetch full article content
5. **LinkRecord Creation**: Store individual articles
6. **Image Download**: Download and store images
7. **Quality Assessment**: Heuristics + user patterns (QualityControl)
8. **Tagging**: User assigns tags (LinkDetailView / TagsView)
9. **Data Storage**: SwiftData persistence

### **Content Extraction & Quality**
- Readability-like extraction, link density, structural features
- Multilingual patterns (Meaningful/Empty/Indicators), editable in the app

## 🎨 User Interface

### **Main Application Window (ContentView)**
- Search Field, Parameters, History, Results

### **Search Queries Window (SearchQueriesView)**
- Article list, details, Quality Indicator

### **API Settings Window (APISettingsView)**
- SerpAPI/OpenAI Keys, Test Buttons

### **Tags Window (TagsView)**
- Tag list, search, add/delete, counter per tag

### **Quality Control (QualityControlView)**
- Metrics (high/medium/low/excluded), Quick Actions, link to editor

### **Quality Terms Editor (QualityTermsEditorView)**
- Edit pattern lists (multilingual), including Excluded URL Patterns

## 🔒 Security & Privacy
- Keychain, Local Storage, Sandbox, User Control

## 📈 Performance Metrics
- Sub-100ms Queries, efficient storage

## 🎯 Success Metrics
- Complete data capture, fast UI, AI-Ready, consistent UX

## 🔮 Future Enhancements
- Advanced Analytics, Smart Categorization, Export, Cloud Sync, Full-Text Search

---

*Created: 2024-12-19*
*Updated: 2025-10-30*
*Status: FULLY IMPLEMENTED - SwiftData Architecture (+ Tag & Quality)*
*Architecture: Modern SwiftData with comprehensive content analysis and quality filtering*
