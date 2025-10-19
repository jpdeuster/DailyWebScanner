import Foundation
import SQLite3
import os.log

/// SQLite database manager for DailyWebScanner
class SQLiteDatabase {
    private var db: OpaquePointer?
    private let dbPath: String
    private let logger = Logger(subsystem: "de.deusterdevelopment.DailyWebScanner", category: "SQLite")
    
    init() {
        // Store the database inside the App Sandbox container:
        // ~/Library/Containers/<bundle id>/Data/Library/Application Support/DailyWebScanner/DailyWebScanner.sqlite
        let fm = FileManager.default
        let appSupportURLs = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportBase = appSupportURLs.first!
        
        // Create an app-specific subdirectory to keep things tidy
        let appFolder = appSupportBase.appendingPathComponent("DailyWebScanner", isDirectory: true)
        
        // Ensure the directory exists
        do {
            try fm.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // If we cannot create the directory, fall back to base Application Support
            logger.error("❌ Failed to create Application Support subdirectory: \(error.localizedDescription)")
        }
        
        // Prefer the app-specific folder if it exists, otherwise use base
        let baseForDB = (fm.fileExists(atPath: appFolder.path) ? appFolder : appSupportBase)
        let dbURL = baseForDB.appendingPathComponent("DailyWebScanner.sqlite", isDirectory: false)
        self.dbPath = dbURL.path
        
        logger.info("🗄️ SQLite Database Path: \(self.dbPath)")
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Operations
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            logger.info("✅ SQLite database opened successfully")
        } else {
            let errMsg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            logger.error("❌ Failed to open SQLite database: \(errMsg)")
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) == SQLITE_OK {
            logger.info("✅ SQLite database closed successfully")
        } else {
            let errMsg = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            logger.error("❌ Failed to close SQLite database: \(errMsg)")
        }
    }
    
    // MARK: - Table Creation
    
    private func createTables() {
        createSearchSessionsTable()
        createSearchResultsTable()
        createSearchCategoriesTable()
        createResultCategoriesTable()
        createSearchTagsTable()
        createResultTagsTable()
        createUserBookmarksTable()
        createSearchAnalyticsTable()
        createIndexes()
    }
    
    private func createSearchSessionsTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS search_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            search_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            user_id TEXT,
            search_engine TEXT DEFAULT 'google',
            language TEXT DEFAULT 'de',
            region TEXT DEFAULT 'de',
            location TEXT,
            safe_search TEXT,
            search_type TEXT,
            time_range TEXT,
            number_of_results INTEGER DEFAULT 20,
            result_count INTEGER,
            processing_time_ms INTEGER,
            search_duration REAL DEFAULT 0.0,
            ai_summary_enabled BOOLEAN DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createSearchResultsTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS search_results (
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
            source_type TEXT DEFAULT 'web',
            relevance_score REAL,
            click_count INTEGER DEFAULT 0,
            bookmark_count INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (session_id) REFERENCES search_sessions(id) ON DELETE CASCADE
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createSearchCategoriesTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS search_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            color TEXT,
            icon TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createResultCategoriesTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS result_categories (
            result_id INTEGER NOT NULL,
            category_id INTEGER NOT NULL,
            confidence REAL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (result_id, category_id),
            FOREIGN KEY (result_id) REFERENCES search_results(id) ON DELETE CASCADE,
            FOREIGN KEY (category_id) REFERENCES search_categories(id) ON DELETE CASCADE
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createSearchTagsTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS search_tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tag TEXT NOT NULL UNIQUE,
            usage_count INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createResultTagsTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS result_tags (
            result_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (result_id, tag_id),
            FOREIGN KEY (result_id) REFERENCES search_results(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES search_tags(id) ON DELETE CASCADE
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createUserBookmarksTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS user_bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            result_id INTEGER NOT NULL,
            notes TEXT,
            tags TEXT,
            priority INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (result_id) REFERENCES search_results(id) ON DELETE CASCADE
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createSearchAnalyticsTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS search_analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            event_type TEXT NOT NULL,
            event_data TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (session_id) REFERENCES search_sessions(id) ON DELETE CASCADE
        );
        """
        
        executeSQL(createTableSQL)
    }
    
    private func createIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_search_sessions_timestamp ON search_sessions(search_timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_search_sessions_query ON search_sessions(query);",
            "CREATE INDEX IF NOT EXISTS idx_search_results_session_id ON search_results(session_id);",
            "CREATE INDEX IF NOT EXISTS idx_search_results_domain ON search_results(domain);",
            "CREATE INDEX IF NOT EXISTS idx_search_results_position ON search_results(position);",
            "CREATE INDEX IF NOT EXISTS idx_search_analytics_timestamp ON search_analytics(timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_search_analytics_event_type ON search_analytics(event_type);"
        ]
        
        for indexSQL in indexes {
            executeSQL(indexSQL)
        }
    }
    
    // MARK: - SQL Execution
    
    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                logger.info("✅ SQL executed successfully")
            } else {
                let errMsg = String(cString: sqlite3_errmsg(self.db))
                logger.error("❌ SQL execution failed: \(errMsg)")
            }
        } else {
            let errMsg = String(cString: sqlite3_errmsg(self.db))
            logger.error("❌ SQL preparation failed: \(errMsg)")
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Search Session Operations
    
    func insertSearchSession(query: String, searchEngine: String = "google", language: String = "de", region: String = "de", aiSummaryEnabled: Bool = false) -> Int64? {
        let insertSQL = """
        INSERT INTO search_sessions (query, search_engine, language, region, ai_summary_enabled)
        VALUES (?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        var sessionId: Int64?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, query, -1, nil)
            sqlite3_bind_text(statement, 2, searchEngine, -1, nil)
            sqlite3_bind_text(statement, 3, language, -1, nil)
            sqlite3_bind_text(statement, 4, region, -1, nil)
            sqlite3_bind_int(statement, 5, aiSummaryEnabled ? 1 : 0)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sessionId = sqlite3_last_insert_rowid(db)
                logger.info("✅ Search session inserted with ID: \(sessionId ?? -1)")
            } else {
                logger.error("❌ Failed to insert search session")
            }
        } else {
            logger.error("❌ Failed to prepare search session insert statement")
        }
        
        sqlite3_finalize(statement)
        return sessionId
    }
    
    func updateSearchSession(sessionId: Int64, resultCount: Int, processingTimeMs: Int) {
        let updateSQL = """
        UPDATE search_sessions 
        SET result_count = ?, processing_time_ms = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(resultCount))
            sqlite3_bind_int(statement, 2, Int32(processingTimeMs))
            sqlite3_bind_int64(statement, 3, sessionId)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                logger.info("✅ Search session updated")
            } else {
                logger.error("❌ Failed to update search session")
            }
        } else {
            logger.error("❌ Failed to prepare search session update statement")
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Search Result Operations
    
    func insertSearchResult(sessionId: Int64, title: String, url: String, snippet: String, aiSummary: String?, position: Int, domain: String?) -> Int64? {
        let insertSQL = """
        INSERT INTO search_results (session_id, title, url, snippet, ai_summary, original_snippet, position, domain)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        var resultId: Int64?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, sessionId)
            sqlite3_bind_text(statement, 2, title, -1, nil)
            sqlite3_bind_text(statement, 3, url, -1, nil)
            sqlite3_bind_text(statement, 4, snippet, -1, nil)
            sqlite3_bind_text(statement, 5, aiSummary, -1, nil)
            sqlite3_bind_text(statement, 6, snippet, -1, nil) // original_snippet
            sqlite3_bind_int(statement, 7, Int32(position))
            sqlite3_bind_text(statement, 8, domain, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                resultId = sqlite3_last_insert_rowid(db)
                logger.info("✅ Search result inserted with ID: \(resultId ?? -1)")
            } else {
                logger.error("❌ Failed to insert search result")
            }
        } else {
            logger.error("❌ Failed to prepare search result insert statement")
        }
        
        sqlite3_finalize(statement)
        return resultId
    }
    
    // MARK: - Analytics Operations
    
    func insertSearchAnalytics(sessionId: Int64, eventType: String, eventData: String?) {
        let insertSQL = """
        INSERT INTO search_analytics (session_id, event_type, event_data)
        VALUES (?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, sessionId)
            sqlite3_bind_text(statement, 2, eventType, -1, nil)
            sqlite3_bind_text(statement, 3, eventData, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                logger.info("✅ Search analytics inserted")
            } else {
                logger.error("❌ Failed to insert search analytics")
            }
        } else {
            logger.error("❌ Failed to prepare search analytics insert statement")
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - Query Operations
    
    func getRecentSessions(limit: Int = 10) -> [SearchSessionDB] {
        let querySQL = """
        SELECT id, query, search_timestamp, result_count, processing_time_ms, ai_summary_enabled
        FROM search_sessions
        ORDER BY search_timestamp DESC
        LIMIT ?;
        """
        
        var statement: OpaquePointer?
        var sessions: [SearchSessionDB] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(limit))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let query = String(cString: sqlite3_column_text(statement, 1))
                let timestamp = String(cString: sqlite3_column_text(statement, 2))
                let resultCount = sqlite3_column_int(statement, 3)
                let processingTime = sqlite3_column_int(statement, 4)
                let aiEnabled = sqlite3_column_int(statement, 5) != 0
                
                let session = SearchSessionDB(
                    id: id,
                    query: query,
                    timestamp: timestamp,
                    resultCount: Int(resultCount),
                    processingTime: Int(processingTime),
                    aiSummaryEnabled: aiEnabled
                )
                sessions.append(session)
            }
        } else {
            logger.error("❌ Failed to prepare recent sessions query")
        }
        
        sqlite3_finalize(statement)
        return sessions
    }
}

// MARK: - Data Models

struct SearchSessionDB {
    let id: Int64
    let query: String
    let timestamp: String
    let resultCount: Int
    let processingTime: Int
    let aiSummaryEnabled: Bool
}
