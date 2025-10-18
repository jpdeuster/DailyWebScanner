# SQL Database Integration Plan

## 🎯 Overview

This document outlines the plan to integrate a local SQLite database into DailyWebScanner for enhanced search result storage, caching, and advanced querying capabilities.

## 📊 Database Schema Design

### Core Tables

#### 1. **search_sessions**
```sql
CREATE TABLE search_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    search_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id TEXT,
    search_engine TEXT DEFAULT 'google',
    language TEXT DEFAULT 'de',
    region TEXT DEFAULT 'de',
    result_count INTEGER,
    processing_time_ms INTEGER,
    ai_summary_enabled BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. **search_results**
```sql
CREATE TABLE search_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    snippet TEXT,
    ai_summary TEXT,
    original_snippet TEXT,
    position INTEGER,
    domain TEXT,
    favicon_url TEXT,
    image_url TEXT,
    published_date DATETIME,
    author TEXT,
    source_type TEXT, -- 'web', 'news', 'academic', 'image'
    relevance_score REAL,
    click_count INTEGER DEFAULT 0,
    bookmark_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES search_sessions(id) ON DELETE CASCADE
);
```

#### 3. **search_categories**
```sql
CREATE TABLE search_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    color TEXT,
    icon TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 4. **result_categories**
```sql
CREATE TABLE result_categories (
    result_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    confidence REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (result_id, category_id),
    FOREIGN KEY (result_id) REFERENCES search_results(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES search_categories(id) ON DELETE CASCADE
);
```

#### 5. **search_tags**
```sql
CREATE TABLE search_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag TEXT NOT NULL UNIQUE,
    usage_count INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 6. **result_tags**
```sql
CREATE TABLE result_tags (
    result_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (result_id, tag_id),
    FOREIGN KEY (result_id) REFERENCES search_results(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES search_tags(id) ON DELETE CASCADE
);
```

#### 7. **user_bookmarks**
```sql
CREATE TABLE user_bookmarks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    result_id INTEGER NOT NULL,
    notes TEXT,
    tags TEXT, -- JSON array of custom tags
    priority INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (result_id) REFERENCES search_results(id) ON DELETE CASCADE
);
```

#### 8. **search_analytics**
```sql
CREATE TABLE search_analytics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    event_type TEXT NOT NULL, -- 'search', 'click', 'bookmark', 'share'
    event_data TEXT, -- JSON data
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES search_sessions(id) ON DELETE CASCADE
);
```

## 🔧 Implementation Plan

### Phase 1: Core Database Setup (v0.6.0)

#### **Database Manager**
```swift
class DatabaseManager {
    static let shared = DatabaseManager()
    private let db: SQLiteDatabase
    
    private init() {
        self.db = SQLiteDatabase()
        setupDatabase()
    }
    
    func setupDatabase() {
        // Create tables
        // Set up indexes
        // Configure foreign keys
    }
}
```

#### **Search Session Management**
```swift
struct SearchSession {
    let id: Int
    let query: String
    let timestamp: Date
    let resultCount: Int
    let processingTime: TimeInterval
    let aiSummaryEnabled: Bool
}

class SearchSessionManager {
    func createSession(query: String, aiEnabled: Bool) -> SearchSession
    func updateSession(_ session: SearchSession, resultCount: Int, processingTime: TimeInterval)
    func getRecentSessions(limit: Int) -> [SearchSession]
    func searchSessions(query: String) -> [SearchSession]
}
```

#### **Search Result Storage**
```swift
struct SearchResultDB {
    let id: Int
    let sessionId: Int
    let title: String
    let url: String
    let snippet: String
    let aiSummary: String?
    let position: Int
    let domain: String
    let clickCount: Int
    let bookmarkCount: Int
}

class SearchResultManager {
    func storeResults(_ results: [SearchResult], for session: SearchSession)
    func getResults(for session: SearchSession) -> [SearchResultDB]
    func updateClickCount(for resultId: Int)
    func updateBookmarkCount(for resultId: Int)
}
```

### Phase 2: Advanced Features (v0.7.0)

#### **Search Analytics**
```swift
class SearchAnalytics {
    func trackSearchEvent(_ event: SearchEvent)
    func getSearchTrends() -> [SearchTrend]
    func getPopularQueries() -> [String]
    func getClickThroughRates() -> [String: Double]
}
```

#### **Smart Categorization**
```swift
class SmartCategorizer {
    func categorizeResult(_ result: SearchResultDB) -> [Category]
    func trainModel(with data: [SearchResultDB])
    func predictCategories(for text: String) -> [Category]
}
```

#### **Search History & Favorites**
```swift
class SearchHistoryManager {
    func getSearchHistory() -> [SearchSession]
    func getFavoriteSearches() -> [SearchSession]
    func getRelatedSearches(for query: String) -> [String]
    func deleteSearchHistory(olderThan date: Date)
}
```

### Phase 3: Advanced Analytics (v0.8.0)

#### **Search Insights**
```swift
class SearchInsights {
    func getSearchPatterns() -> [SearchPattern]
    func getDomainStatistics() -> [DomainStats]
    func getTimeBasedTrends() -> [TimeTrend]
    func getUserBehavior() -> UserBehavior
}
```

#### **Export & Reporting**
```swift
class SearchExporter {
    func exportToCSV(sessions: [SearchSession]) -> Data
    func exportToJSON(sessions: [SearchSession]) -> Data
    func generateSearchReport() -> SearchReport
    func exportAnalytics() -> AnalyticsReport
}
```

## 🚀 Benefits

### **Performance Improvements**
- **Faster Search**: Cached results for repeated queries
- **Offline Access**: Access to previous search results
- **Smart Suggestions**: Based on search history
- **Incremental Loading**: Load results as needed

### **Enhanced Features**
- **Search History**: Complete search history with analytics
- **Bookmarks**: Save and organize favorite results
- **Categories**: Automatic categorization of results
- **Tags**: Custom tagging system
- **Analytics**: Detailed search behavior insights

### **User Experience**
- **Smart Recommendations**: Suggest related searches
- **Quick Access**: Fast access to previous results
- **Personalization**: Learn from user behavior
- **Export Options**: Export search data in various formats

## 📊 Database Indexes

```sql
-- Performance indexes
CREATE INDEX idx_search_sessions_timestamp ON search_sessions(search_timestamp);
CREATE INDEX idx_search_sessions_query ON search_sessions(query);
CREATE INDEX idx_search_results_session_id ON search_results(session_id);
CREATE INDEX idx_search_results_domain ON search_results(domain);
CREATE INDEX idx_search_results_position ON search_results(position);
CREATE INDEX idx_search_analytics_timestamp ON search_analytics(timestamp);
CREATE INDEX idx_search_analytics_event_type ON search_analytics(event_type);

-- Full-text search indexes
CREATE VIRTUAL TABLE search_results_fts USING fts5(
    title, snippet, ai_summary, content='search_results', content_rowid='id'
);
```

## 🔒 Security & Privacy

### **Data Encryption**
- SQLite database encryption using SQLCipher
- Keychain integration for encryption keys
- User-controlled data retention policies

### **Privacy Controls**
- Local-only storage (no cloud sync by default)
- User-controlled data export/deletion
- Anonymized analytics (optional)
- GDPR compliance features

## 📈 Migration Strategy

### **From SwiftData to SQLite**
1. **Phase 1**: Parallel implementation (both systems)
2. **Phase 2**: Data migration tools
3. **Phase 3**: SwiftData deprecation
4. **Phase 4**: Full SQLite implementation

### **Data Migration**
```swift
class DataMigrator {
    func migrateFromSwiftData() async throws
    func validateMigration() -> Bool
    func rollbackMigration() async throws
}
```

## 🧪 Testing Strategy

### **Unit Tests**
- Database operations
- Data integrity
- Performance benchmarks
- Migration testing

### **Integration Tests**
- End-to-end search workflows
- Data consistency
- Performance under load
- Error handling

## 📋 Implementation Plan

### **v0.6.0 - Core Database**
- [ ] SQLite database setup
- [ ] Basic CRUD operations
- [ ] Search session management
- [ ] Result storage and retrieval
- [ ] Migration from SwiftData

### **v0.7.0 - Advanced Features**
- [ ] Search analytics
- [ ] Smart categorization
- [ ] Bookmark system
- [ ] Export functionality
- [ ] Performance optimization

### **v0.8.0 - Analytics & Insights**
- [ ] Advanced analytics
- [ ] Search insights
- [ ] User behavior analysis
- [ ] Reporting system
- [ ] Data visualization

## 🎯 Success Metrics

### **Performance**
- Search result loading time < 100ms
- Database query performance < 50ms
- Memory usage optimization
- Storage efficiency

### **User Experience**
- Search history accessibility
- Bookmark management
- Export functionality
- Analytics insights

### **Data Quality**
- Data integrity validation
- Search result accuracy
- Categorization precision
- Analytics reliability

---

*This plan will be updated as development progresses and new requirements emerge.*
