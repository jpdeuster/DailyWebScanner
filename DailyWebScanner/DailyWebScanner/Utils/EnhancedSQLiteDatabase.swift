import Foundation
import SQLite3

class EnhancedSQLiteDatabase {
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dbPath = documentsPath.appendingPathComponent("DailyWebScanner_Enhanced.db").path
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) != SQLITE_OK {
            print("Error closing database")
        }
    }
    
    private func createTables() {
        // Search Records Table
        let createSearchRecordsTable = """
        CREATE TABLE IF NOT EXISTS search_records (
            id TEXT PRIMARY KEY,
            query TEXT NOT NULL,
            created_at TEXT NOT NULL,
            html_summary TEXT,
            language TEXT,
            region TEXT,
            location TEXT,
            safe_search TEXT,
            search_type TEXT,
            time_range TEXT,
            number_of_results INTEGER,
            search_duration REAL,
            result_count INTEGER,
            content_analysis TEXT,
            headlines_count INTEGER,
            links_count INTEGER,
            content_blocks_count INTEGER,
            tags_count INTEGER,
            has_content_analysis BOOLEAN
        );
        """
        
        // Link Records Table
        let createLinkRecordsTable = """
        CREATE TABLE IF NOT EXISTS link_records (
            id TEXT PRIMARY KEY,
            search_record_id TEXT NOT NULL,
            original_url TEXT NOT NULL,
            title TEXT,
            content TEXT,
            html TEXT,
            css TEXT,
            fetched_at TEXT NOT NULL,
            author TEXT,
            publish_date TEXT,
            description TEXT,
            keywords TEXT,
            language TEXT,
            word_count INTEGER,
            reading_time INTEGER,
            image_count INTEGER,
            total_image_size INTEGER,
            has_ai_overview BOOLEAN,
            ai_overview_json TEXT,
            ai_overview_thumbnail TEXT,
            ai_overview_references TEXT,
            has_content_analysis BOOLEAN,
            content_analysis_json TEXT,
            html_preview TEXT,
            FOREIGN KEY (search_record_id) REFERENCES search_records (id) ON DELETE CASCADE
        );
        """
        
        // Image Records Table
        let createImageRecordsTable = """
        CREATE TABLE IF NOT EXISTS image_records (
            id TEXT PRIMARY KEY,
            link_record_id TEXT NOT NULL,
            original_url TEXT NOT NULL,
            local_path TEXT,
            alt_text TEXT,
            width INTEGER,
            height INTEGER,
            file_size INTEGER,
            downloaded_at TEXT NOT NULL,
            FOREIGN KEY (link_record_id) REFERENCES link_records (id) ON DELETE CASCADE
        );
        """
        
        // Search Results Table (existing)
        let createSearchResultsTable = """
        CREATE TABLE IF NOT EXISTS search_results (
            id TEXT PRIMARY KEY,
            search_record_id TEXT NOT NULL,
            title TEXT,
            link TEXT,
            snippet TEXT,
            position INTEGER,
            FOREIGN KEY (search_record_id) REFERENCES search_records (id) ON DELETE CASCADE
        );
        """
        
        executeSQL(createSearchRecordsTable)
        executeSQL(createLinkRecordsTable)
        executeSQL(createImageRecordsTable)
        executeSQL(createSearchResultsTable)
    }
    
    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error executing SQL: \(sql)")
            }
        } else {
            print("Error preparing SQL: \(sql)")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Search Records
    
    func insertSearchRecord(_ record: SearchRecord) {
        let sql = """
        INSERT INTO search_records (
            id, query, created_at, html_summary, language, region, location,
            safe_search, search_type, time_range, number_of_results, search_duration,
            result_count, content_analysis, headlines_count, links_count,
            content_blocks_count, tags_count, has_content_analysis
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, record.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, record.query, -1, nil)
            sqlite3_bind_text(statement, 3, ISO8601DateFormatter().string(from: record.createdAt), -1, nil)
            sqlite3_bind_text(statement, 4, record.htmlSummary, -1, nil)
            sqlite3_bind_text(statement, 5, record.language, -1, nil)
            sqlite3_bind_text(statement, 6, record.region, -1, nil)
            sqlite3_bind_text(statement, 7, record.location, -1, nil)
            sqlite3_bind_text(statement, 8, record.safeSearch, -1, nil)
            sqlite3_bind_text(statement, 9, record.searchType, -1, nil)
            sqlite3_bind_text(statement, 10, record.timeRange, -1, nil)
            sqlite3_bind_int(statement, 11, Int32(record.numberOfResults))
            sqlite3_bind_double(statement, 12, record.searchDuration)
            sqlite3_bind_int(statement, 13, Int32(record.resultCount))
            sqlite3_bind_text(statement, 14, record.contentAnalysis, -1, nil)
            sqlite3_bind_int(statement, 15, Int32(record.headlinesCount))
            sqlite3_bind_int(statement, 16, Int32(record.linksCount))
            sqlite3_bind_int(statement, 17, Int32(record.contentBlocksCount))
            sqlite3_bind_int(statement, 18, Int32(record.tagsCount))
            sqlite3_bind_int(statement, 19, record.hasContentAnalysis ? 1 : 0)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting search record")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Link Records
    
    func insertLinkRecord(_ linkRecord: LinkRecord) {
        let sql = """
        INSERT INTO link_records (
            id, search_record_id, original_url, title, content, html, css, fetched_at,
            author, publish_date, description, keywords, language, word_count, reading_time,
            image_count, total_image_size, has_ai_overview, ai_overview_json,
            ai_overview_thumbnail, ai_overview_references, has_content_analysis,
            content_analysis_json, html_preview
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, linkRecord.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, linkRecord.searchRecordId.uuidString, -1, nil)
            sqlite3_bind_text(statement, 3, linkRecord.originalUrl, -1, nil)
            sqlite3_bind_text(statement, 4, linkRecord.title, -1, nil)
            sqlite3_bind_text(statement, 5, linkRecord.content, -1, nil)
            // HTML/CSS entfernt
            sqlite3_bind_text(statement, 6, ISO8601DateFormatter().string(from: linkRecord.fetchedAt), -1, nil)
            sqlite3_bind_text(statement, 7, linkRecord.author, -1, nil)
            sqlite3_bind_text(statement, 8, linkRecord.publishDate?.description, -1, nil)
            sqlite3_bind_text(statement, 9, linkRecord.articleDescription, -1, nil)
            sqlite3_bind_text(statement, 10, linkRecord.keywords, -1, nil)
            sqlite3_bind_text(statement, 11, linkRecord.language, -1, nil)
            sqlite3_bind_int(statement, 12, Int32(linkRecord.wordCount))
            sqlite3_bind_int(statement, 13, Int32(linkRecord.readingTime))
            sqlite3_bind_int(statement, 14, Int32(linkRecord.imageCount))
            sqlite3_bind_int(statement, 15, Int32(linkRecord.totalImageSize))
            sqlite3_bind_int(statement, 16, linkRecord.hasAIOverview ? 1 : 0)
            sqlite3_bind_text(statement, 17, linkRecord.aiOverviewJSON, -1, nil)
            sqlite3_bind_text(statement, 18, linkRecord.aiOverviewThumbnail, -1, nil)
            sqlite3_bind_text(statement, 19, linkRecord.aiOverviewReferences, -1, nil)
            sqlite3_bind_int(statement, 20, linkRecord.hasContentAnalysis ? 1 : 0)
            sqlite3_bind_text(statement, 21, linkRecord.contentAnalysisJSON, -1, nil)
            // htmlPreview entfernt
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting link record")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Image Records
    
    func insertImageRecord(_ imageRecord: ImageRecord) {
        let sql = """
        INSERT INTO image_records (
            id, link_record_id, original_url, local_path, alt_text, width, height,
            file_size, downloaded_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, imageRecord.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, imageRecord.linkRecordId.uuidString, -1, nil)
            sqlite3_bind_text(statement, 3, imageRecord.originalUrl, -1, nil)
            sqlite3_bind_text(statement, 4, imageRecord.localPath, -1, nil)
            sqlite3_bind_text(statement, 5, imageRecord.altText, -1, nil)
            sqlite3_bind_int(statement, 6, Int32(imageRecord.width ?? 0))
            sqlite3_bind_int(statement, 7, Int32(imageRecord.height ?? 0))
            sqlite3_bind_int(statement, 8, Int32(imageRecord.fileSize))
            sqlite3_bind_text(statement, 9, ISO8601DateFormatter().string(from: imageRecord.downloadedAt), -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting image record")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Query Methods
    
    func getLinkRecords(for searchRecordId: UUID) -> [LinkRecord] {
        let sql = "SELECT * FROM link_records WHERE search_record_id = ?"
        var statement: OpaquePointer?
        let linkRecords: [LinkRecord] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, searchRecordId.uuidString, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                // Parse the result and create LinkRecord objects
                // This would need to be implemented based on your specific needs
            }
        }
        sqlite3_finalize(statement)
        return linkRecords
    }
}
