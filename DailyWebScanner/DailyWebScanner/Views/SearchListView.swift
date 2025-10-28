import SwiftUI
import SwiftData

struct SearchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AutomatedSearchRecord.query, order: .forward) private var allSearchRecords: [AutomatedSearchRecord]
    @State private var selectedSearchRecord: AutomatedSearchRecord?
    @State private var filterText: String = ""
    @State private var newSearchQuery: String = ""
    @State private var selectedHour: Int = 10
    @State private var selectedMinute: Int = 0
    @State private var timeUntilNextSearch: String = ""
    @State private var timer: Timer?
    @State private var globalTimer: Timer?
    // Search parameters using @AppStorage
    @AppStorage("automatedSearchLanguage") var language: String = ""
    @AppStorage("automatedSearchRegion") var region: String = ""
    @AppStorage("automatedSearchLocation") var location: String = ""
    @AppStorage("automatedSearchSafeSearch") var safeSearch: String = "off"
    @AppStorage("automatedSearchType") var searchType: String = ""
    @AppStorage("automatedSearchTimeRange") var timeRange: String = ""
    @AppStorage("automatedSearchDateRange") var dateRange: String = ""
    
    // Computed property for filtered automated search records (alphabetically sorted)
    private var filteredSearchRecords: [AutomatedSearchRecord] {
        let records = if filterText.isEmpty {
            allSearchRecords
        } else {
            allSearchRecords.filter { record in
                record.query.localizedCaseInsensitiveContains(filterText) ||
                record.language.localizedCaseInsensitiveContains(filterText) ||
                record.region.localizedCaseInsensitiveContains(filterText) ||
                record.location.localizedCaseInsensitiveContains(filterText)
            }
        }
        return records.sorted { $0.query.localizedCaseInsensitiveCompare($1.query) == .orderedAscending }
    }
    
    // Function to calculate time until next search for a specific record
    private func timeUntilNextSearch(for record: SearchRecord) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        let scheduledTime = parseScheduledTime(record.scheduledTime)
        let scheduledHour = scheduledTime.hour
        let scheduledMinute = scheduledTime.minute
        
        // Calculate next occurrence of this time today
        var nextDate = calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: now) ?? now
        
        // If the time has already passed today, move to tomorrow
        if nextDate <= now {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? now
        }
        
        let timeInterval = nextDate.timeIntervalSince(now)
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search Parameters Configuration
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "gear")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Search Parameters")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    // Language and Region Row
                    HStack(spacing: 8) {
                        // Language Picker
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Language", selection: $language) {
                                ForEach(LanguageHelper.languages, id: \.code) { language in
                                    Text(language.name).tag(language.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        // Region Picker
                        HStack(spacing: 4) {
                            Image(systemName: "map")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Region", selection: $region) {
                                ForEach(LanguageHelper.countries, id: \.code) { country in
                                    Text(country.name).tag(country.code)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        Spacer()
                    }
                    
                    // Safe Search and Type Row
                    HStack(spacing: 8) {
                        // Safe Search Picker
                        HStack(spacing: 4) {
                            Image(systemName: "shield")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Safe", selection: $safeSearch) {
                                Text("Off").tag("off")
                                Text("Active").tag("active")
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        // Search Type Picker
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Type", selection: $searchType) {
                                Text("All").tag("")
                                Text("News").tag("nws")
                                Text("Images").tag("isch")
                                Text("Videos").tag("vid")
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        Spacer()
                    }
                    
                    // Time Range and Location Row
                    HStack(spacing: 8) {
                        // Time Range Picker
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Picker("Time", selection: $timeRange) {
                                Text("Any Time").tag("")
                                Text("Past Hour").tag("qdr:h")
                                Text("Past Day").tag("qdr:d")
                                Text("Past Week").tag("qdr:w")
                                Text("Past Month").tag("qdr:m")
                                Text("Past Year").tag("qdr:y")
                            }
                            .pickerStyle(.menu)
                            .font(.caption2)
                        }
                        
                        // Location Field for City/Region
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            TextField("City (e.g., Berlin, New York)", text: $location)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption2)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                
                // Manual Search Field
                HStack {
                    TextField("Enter search query...", text: $newSearchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addAutomatedSearch()
                        }
                    
                    // Time Picker for Automation
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        // Hour Picker (0-23)
                        HStack {
                            Button(action: {
                                if selectedHour > 0 {
                                    selectedHour -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                            
                            Text(String(format: "%02d", selectedHour))
                                .font(.caption)
                                .frame(width: 30)
                            
                            Button(action: {
                                if selectedHour < 23 {
                                    selectedHour += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                        
                        Text(":")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Minute Picker (0-59)
                        HStack {
                            Button(action: {
                                if selectedMinute > 0 {
                                    selectedMinute -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                            
                            Text(String(format: "%02d", selectedMinute))
                                .font(.caption)
                                .frame(width: 30)
                            
                            Button(action: {
                                if selectedMinute < 59 {
                                    selectedMinute += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                    }
                    
                    Button(action: {
                        addAutomatedSearch()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add")
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.bordered)
                    .disabled(newSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                
                // Timer Display
                if !timeUntilNextSearch.isEmpty {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Next search in: \(timeUntilNextSearch)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                // Search List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        
                        TextField("Filter searches...", text: $filterText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    .padding(.horizontal)
                    
                    if filteredSearchRecords.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No automated searches yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Add your first automated search above")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List(selection: $selectedSearchRecord) {
                            ForEach(filteredSearchRecords) { record in
                                NavigationLink(value: record) {
                                    SearchListRow(record: record) {
                                        deleteSearchRecord(record)
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteSearchRecord(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.sidebar)
                    }
                }
            }
            .frame(minWidth: 300)
        } detail: {
            if let searchRecord = selectedSearchRecord {
                VStack(spacing: 16) {
                    // Beautiful Search Query Header
                    SearchQueryHeaderView(searchRecord: searchRecord)
                    
                    // Search Results (non-clickable)
                    if !searchRecord.results.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Search Results (\(searchRecord.results.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            // Results List (non-clickable)
                            List(searchRecord.results.prefix(10)) { result in
                                SearchResultRowView(result: result)
                            }
                            .listStyle(.plain)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No Results Yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("This search hasn't been executed yet or returned no results.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
                } else {
                    VStack(spacing: 20) {
                        // Navigation Buttons (top-right)
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showManualSearchWindow()
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption)
                                    Text("Manual Search")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Open Manual Search (⌘M)")
                            .keyboardShortcut("m", modifiers: .command)
                            
                            Button(action: {
                                showArticlesWindow()
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.caption)
                                    Text("Show Saved Articles")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Open Articles List (⌘L)")
                            .keyboardShortcut("l", modifiers: .command)
                        }
                        .padding(.horizontal)
                        
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to DailyWebScanner")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select a search from the sidebar to view results")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 16) {
                            InfoCard(
                                icon: "clock.arrow.circlepath",
                                title: "Automated Searches",
                                description: "View and manage your automated search schedules"
                            )
                            
                            InfoCard(
                                icon: "list.bullet",
                                title: "Search Results",
                                description: "See comprehensive search results with AI summaries"
                            )
                            
                            InfoCard(
                                icon: "link",
                                title: "Article Links",
                                description: "Access saved articles and extracted content"
                            )
                        }
                    }
                    .padding(40)
                }
        }
        .onAppear {
            DebugLogger.shared.logWebViewAction("🚀 DailyWebScanner - SearchListView appeared - allSearchRecords count: \(allSearchRecords.count)")
            
            // Debug: Show all search records with their status
            for (index, record) in allSearchRecords.enumerated() {
                let status = record.isEnabled ? "✅ ACTIVE" : "⏸️ PAUSED"
                // Calculate time until next execution
                let now = Date()
                let calendar = Calendar.current
                let scheduledTime = parseScheduledTime(record.scheduledTime)
                var nextDate = calendar.date(bySettingHour: scheduledTime.hour, minute: scheduledTime.minute, second: 0, of: now) ?? now
                if nextDate <= now {
                    nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
                }
                let timeInterval = nextDate.timeIntervalSince(now)
                let hours = Int(timeInterval) / 3600
                let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
                let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
                let nextExecution = hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
                DebugLogger.shared.logWebViewAction("🔍 SearchListView: Record \(index): '\(record.query)' (ID: \(record.id)) - \(status)")
                DebugLogger.shared.logWebViewAction("⏰ Next execution: \(nextExecution)")
                
                // Show search parameters
                DebugLogger.shared.logWebViewAction("📋 Search parameters: Language=\(record.language.isEmpty ? "Any" : record.language), Region=\(record.region.isEmpty ? "Any" : record.region), Location=\(record.location.isEmpty ? "Any" : record.location)")
                DebugLogger.shared.logWebViewAction("🔧 Additional params: Safe=\(record.safe.isEmpty ? "Off" : record.safe), Type=\(record.tbm.isEmpty ? "All" : record.tbm), TimeRange=\(record.as_qdr.isEmpty ? "Any" : record.as_qdr)")
                DebugLogger.shared.logWebViewAction("📊 Execution count: \(record.executionCount), Last run: \(record.lastExecutionDate?.formatted() ?? "Never")")
            }
            
            // Debug: Show next automated search details
            let activeRecords = allSearchRecords.filter { $0.isEnabled }
            if !activeRecords.isEmpty {
                DebugLogger.shared.logWebViewAction("🚀 ACTIVE AUTOMATED SEARCHES: \(activeRecords.count)")
                
                // Find the next search to execute
                let now = Date()
                var nextSearch: AutomatedSearchRecord?
                var nextExecutionTime: Date?
                
                for record in activeRecords {
                    let scheduledTime = parseScheduledTime(record.scheduledTime)
                    let calendar = Calendar.current
                    
                    // Calculate next occurrence of this time today
                    var nextDate = calendar.date(bySettingHour: scheduledTime.hour, minute: scheduledTime.minute, second: 0, of: now) ?? now
                    
                    // If the time has already passed today, move to tomorrow
                    if nextDate <= now {
                        nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
                    }
                    
                    if nextExecutionTime == nil || nextDate < nextExecutionTime! {
                        nextExecutionTime = nextDate
                        nextSearch = record
                    }
                }
                
                if let nextSearch = nextSearch, let nextTime = nextExecutionTime {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateStyle = .short
                    timeFormatter.timeStyle = .short
                    
                    DebugLogger.shared.logWebViewAction("⏭️ NEXT AUTOMATED SEARCH:")
                    DebugLogger.shared.logWebViewAction("   Query: '\(nextSearch.query)'")
                    DebugLogger.shared.logWebViewAction("   Scheduled time: \(nextSearch.scheduledTime)")
                    DebugLogger.shared.logWebViewAction("   Next execution: \(timeFormatter.string(from: nextTime))")
                    // Calculate time until execution for nextSearch
                    let nextNow = Date()
                    let nextCalendar = Calendar.current
                    let nextScheduledTime = parseScheduledTime(nextSearch.scheduledTime)
                    var nextNextDate = nextCalendar.date(bySettingHour: nextScheduledTime.hour, minute: nextScheduledTime.minute, second: 0, of: nextNow) ?? nextNow
                    if nextNextDate <= nextNow {
                        nextNextDate = nextCalendar.date(byAdding: .day, value: 1, to: nextNextDate) ?? nextNextDate
                    }
                    let nextTimeInterval = nextNextDate.timeIntervalSince(nextNow)
                    let nextHours = Int(nextTimeInterval) / 3600
                    let nextMinutes = Int(nextTimeInterval.truncatingRemainder(dividingBy: 3600)) / 60
                    let nextSeconds = Int(nextTimeInterval.truncatingRemainder(dividingBy: 60))
                    let nextTimeUntilExecution = nextHours > 0 ? String(format: "%02d:%02d:%02d", nextHours, nextMinutes, nextSeconds) : String(format: "%02d:%02d", nextMinutes, nextSeconds)
                    DebugLogger.shared.logWebViewAction("   Time until execution: \(nextTimeUntilExecution)")
                    DebugLogger.shared.logWebViewAction("   Search parameters: \(nextSearch.language.isEmpty ? "Any" : nextSearch.language) language, \(nextSearch.region.isEmpty ? "Any" : nextSearch.region) region")
                }
            } else {
                DebugLogger.shared.logWebViewAction("⏸️ NO ACTIVE AUTOMATED SEARCHES")
            }
            
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func addAutomatedSearch() {
        if !newSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                do {
                    let viewModel = SearchViewModel()
                    viewModel.modelContext = modelContext
                    let searchResults = try await viewModel.runSearchForResults(
                        query: newSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines),
                        language: language,
                        region: region,
                        location: location,
                        safe: safeSearch,
                        tbm: searchType,
                        tbs: "",
                        as_qdr: timeRange,
                        nfpr: "",
                        filter: ""
                    )
                    
                    // Create AutomatedSearchRecord
                    let record = AutomatedSearchRecord(
                        query: newSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines),
                        language: language,
                        region: region,
                        location: location,
                        safe: safeSearch,
                        tbm: searchType,
                        tbs: "",
                        as_qdr: timeRange,
                        nfpr: "",
                        filter: "",
                        scheduledTime: String(format: "%02d:%02d", selectedHour, selectedMinute)
                    )
                    record.results = searchResults
                    
                    // Convert SearchResults to LinkRecords for the article list
                    for (_, searchResult) in searchResults.enumerated() {
                        let linkRecord = LinkRecord(
                            searchRecordId: record.id,
                            originalUrl: searchResult.link,
                            title: searchResult.title,
                            content: searchResult.snippet,
                            fetchedAt: Date(),
                            articleDescription: searchResult.snippet,
                            wordCount: searchResult.snippet.split(separator: " ").count,
                            readingTime: max(1, searchResult.snippet.split(separator: " ").count / 200)
                        )
                        modelContext.insert(linkRecord)
                        DebugLogger.shared.logWebViewAction("Created LinkRecord: \(searchResult.title)")
                    }
                    
                    await MainActor.run {
                        modelContext.insert(record)
                        selectedSearchRecord = record
                        newSearchQuery = "" // Clear search text after successful search
                        DebugLogger.shared.logWebViewAction("✅ SearchListView: Added automated search '\(record.query)' with \(record.results.count) results")
                        DebugLogger.shared.logWebViewAction("Created \(searchResults.count) LinkRecords for article list")
                    }
                } catch {
                    DebugLogger.shared.logWebViewAction("❌ SearchListView: Failed to create automated search: \(error)")
                }
            }
        }
    }
    
    // MARK: - Timer Functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeUntilNextSearch()
        }
        updateTimeUntilNextSearch() // Initial update
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startGlobalTimer() {
        globalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkAndExecuteAutomatedSearches()
        }
    }
    
    private func stopGlobalTimer() {
        globalTimer?.invalidate()
        globalTimer = nil
    }
    
    // MARK: - Helper Functions
    
    private func createLinkRecord(from result: SearchResult, searchRecord: AutomatedSearchRecord) -> LinkRecord {
        return LinkRecord(
            searchRecordId: searchRecord.id,
            originalUrl: result.link,
            title: result.title,
            content: result.snippet,
            fetchedAt: Date(),
            articleDescription: result.snippet,
            wordCount: result.snippet.split(separator: " ").count,
            readingTime: max(1, result.snippet.split(separator: " ").count / 200)
        )
    }
    
    private func showManualSearchWindow() {
        let manualSearchWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        manualSearchWindow.title = "Manual Search"
        manualSearchWindow.center()
        manualSearchWindow.contentView = NSHostingView(rootView: MainView()
            .environment(\.modelContext, modelContext))
        
        manualSearchWindow.isReleasedWhenClosed = false
        manualSearchWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showArticlesWindow() {
        let articlesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        articlesWindow.title = "Articles"
        articlesWindow.center()
        articlesWindow.contentView = NSHostingView(rootView: SearchQueriesView()
            .environment(\.modelContext, modelContext))
        
        articlesWindow.isReleasedWhenClosed = false
        articlesWindow.makeKeyAndOrderFront(nil)
    }
    
    private func checkAndExecuteAutomatedSearches() {
        let now = Date()
        let calendar = Calendar.current
        
        for record in allSearchRecords {
            guard record.isEnabled && !record.scheduledTime.isEmpty else { continue }
            
            let scheduledTime = parseScheduledTime(record.scheduledTime)
            let scheduledHour = scheduledTime.hour
            let scheduledMinute = scheduledTime.minute
            
            // Calculate next occurrence of this time today
            var nextDate = calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: now) ?? now
            
            // If the time has already passed today, move to tomorrow
            if nextDate <= now {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? now
            }
            
            let timeInterval = nextDate.timeIntervalSince(now)
            let totalSeconds = Int(timeInterval)
            
            // Check if it's time to execute the search (within 1 second tolerance)
            if totalSeconds <= 1 && totalSeconds >= 0 {
                executeGlobalAutomatedSearch(record)
            }
        }
    }
    
    private func executeGlobalAutomatedSearch(_ record: AutomatedSearchRecord) {
        DebugLogger.shared.logWebViewAction("🔄 Executing global automated search: \(record.query)")
        
        Task {
            do {
                let searchViewModel = SearchViewModel()
                let searchResults = try await searchViewModel.runSearchForResults(
                    query: record.query,
                    language: record.language,
                    region: record.region,
                    location: record.location,
                    safe: record.safe,
                    tbm: record.tbm,
                    tbs: record.tbs,
                    as_qdr: record.as_qdr,
                    nfpr: record.nfpr,
                    filter: record.filter
                )
                
                await MainActor.run {
                    // Add results to the record
                    record.results.append(contentsOf: searchResults)
                    record.executionCount += 1
                    record.lastExecutionDate = Date()
                    
                    // Convert SearchResults to LinkRecords for the article list
                    for (_, searchResult) in searchResults.enumerated() {
                        let linkRecord = LinkRecord(
                            searchRecordId: record.id,
                            originalUrl: searchResult.link,
                            title: searchResult.title,
                            content: searchResult.snippet,
                            fetchedAt: Date(),
                            articleDescription: searchResult.snippet,
                            wordCount: searchResult.snippet.split(separator: " ").count,
                            readingTime: max(1, searchResult.snippet.split(separator: " ").count / 200)
                        )
                        modelContext.insert(linkRecord)
                    }
                    
                    DebugLogger.shared.logWebViewAction("✅ Global automated search completed: \(record.query) - \(searchResults.count) results")
                }
            } catch {
                DebugLogger.shared.logWebViewAction("❌ Global automated search failed: \(record.query) - \(error)")
            }
        }
    }
    
    private func updateTimeUntilNextSearch() {
        let enabledSearches = allSearchRecords
        
        if enabledSearches.isEmpty {
            timeUntilNextSearch = ""
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        var nextSearchTime: Date?
        
        for search in enabledSearches {
            let scheduledTime = parseScheduledTime(search.scheduledTime)
            let scheduledHour = scheduledTime.hour
            let scheduledMinute = scheduledTime.minute
            
            // Calculate next occurrence of this time today
            var nextDate = calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: now) ?? now
            
            // If the time has already passed today, move to tomorrow
            if nextDate <= now {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? now
            }
            
            if nextSearchTime == nil || nextDate < nextSearchTime! {
                nextSearchTime = nextDate
            }
        }
        
        if let nextTime = nextSearchTime {
            let timeInterval = nextTime.timeIntervalSince(now)
            let totalSeconds = Int(timeInterval)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if hours > 0 {
                timeUntilNextSearch = String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else if minutes > 0 {
                timeUntilNextSearch = String(format: "%d:%02d", minutes, seconds)
            } else {
                timeUntilNextSearch = String(format: "%ds", seconds)
            }
        } else {
            timeUntilNextSearch = ""
        }
    }
    
    private func parseScheduledTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let components = timeString.split(separator: ":")
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }
        return (hour: 0, minute: 0)
    }
    
    private func deleteSearchRecord(_ record: AutomatedSearchRecord) {
        DebugLogger.shared.logWebViewAction("🗑️ SearchListView: Starting delete for SearchRecord '\(record.query)' (ID: \(record.id))")
        
        // Clear selection if deleted record was selected
        if selectedSearchRecord?.id == record.id {
            DebugLogger.shared.logWebViewAction("🗑️ SearchListView: Clearing selectedSearchRecord - deleted record was active")
            selectedSearchRecord = nil
        }
        
        modelContext.delete(record)
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("✅ SearchListView: SearchRecord deleted successfully: '\(record.query)'")
        } catch {
            DebugLogger.shared.logWebViewAction("❌ SearchListView: Failed to delete SearchRecord: \(error.localizedDescription)")
        }
    }
}

struct SearchListRow: View {
    let record: AutomatedSearchRecord
    let onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var timeUntilNext: String = ""
    @State private var timer: Timer?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.isEnabled ? "clock.circle.fill" : "clock.circle")
                .foregroundColor(record.isEnabled ? .blue : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.query)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(record.timestamp, format: .dateTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Search Parameters as Tags
                HStack {
                    if !record.language.isEmpty {
                        ParameterTag(label: "Lang", value: record.language)
                    }
                    if !record.region.isEmpty {
                        ParameterTag(label: "Region", value: record.region)
                    }
                    if !record.location.isEmpty {
                        ParameterTag(label: "Location", value: record.location)
                    }
                    if !record.safe.isEmpty && record.safe != "off" {
                        ParameterTag(label: "Safe", value: record.safe)
                    }
                    if !record.tbm.isEmpty {
                        ParameterTag(label: "Type", value: record.tbm)
                    }
                    if !record.as_qdr.isEmpty {
                        ParameterTag(label: "Time", value: record.as_qdr)
                    }
                }
                
                // Automation Metadata as Tags
                HStack {
                    if record.executionCount > 0 {
                        ParameterTag(label: "Runs", value: "\(record.executionCount)")
                    }
                    if record.isEnabled {
                        ParameterTag(label: "Status", value: "Enabled")
                    } else {
                        ParameterTag(label: "Status", value: "Disabled")
                    }
                    if !record.results.isEmpty {
                        ParameterTag(label: "Results", value: "\(record.results.count)")
                    }
                    if !record.scheduledTime.isEmpty {
                        ParameterTag(label: "Time", value: record.scheduledTime)
                    }
                    if record.isEnabled && !timeUntilNext.isEmpty {
                        ParameterTag(label: "Next in", value: timeUntilNext, color: .blue)
                    }
                }
                
                // Prominent Timer Display for Enabled Searches
                if record.isEnabled && !record.scheduledTime.isEmpty && !timeUntilNext.isEmpty {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Next search in: \(timeUntilNext)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Enable/Disable Toggle Button
            Button(action: {
                record.isEnabled.toggle()
            }) {
                Image(systemName: record.isEnabled ? "pause.circle.fill" : "play.circle.fill")
                    .foregroundColor(record.isEnabled ? .orange : .green)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(record.isEnabled ? "Disable automated search" : "Enable automated search")
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Delete search")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3) as Color, lineWidth: 1)
                )
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        guard record.isEnabled && !record.scheduledTime.isEmpty else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeUntilNext()
        }
        updateTimeUntilNext() // Initial update
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimeUntilNext() {
        guard record.isEnabled && !record.scheduledTime.isEmpty else {
            timeUntilNext = ""
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let scheduledTime = parseScheduledTime(record.scheduledTime)
        let scheduledHour = scheduledTime.hour
        let scheduledMinute = scheduledTime.minute
        
        // Calculate next occurrence of this time today
        var nextDate = calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: now) ?? now
        
        // If the time has already passed today, move to tomorrow
        if nextDate <= now {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? now
        }
        
        let timeInterval = nextDate.timeIntervalSince(now)
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            timeUntilNext = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            timeUntilNext = String(format: "%d:%02d", minutes, seconds)
        } else {
            timeUntilNext = String(format: "%ds", seconds)
        }
        
        // Check if it's time to execute the search (within 1 second tolerance)
        if totalSeconds <= 1 && totalSeconds >= 0 {
            executeAutomatedSearch()
        }
    }
    
    private func executeAutomatedSearch() {
        DebugLogger.shared.logWebViewAction("🔄 Executing automated search: \(record.query)")
        
        Task {
            do {
                let searchViewModel = SearchViewModel()
                let searchResults = try await searchViewModel.runSearchForResults(
                    query: record.query,
                    language: record.language,
                    region: record.region,
                    location: record.location,
                    safe: record.safe,
                    tbm: record.tbm,
                    tbs: record.tbs,
                    as_qdr: record.as_qdr,
                    nfpr: record.nfpr,
                    filter: record.filter
                )
                
                await MainActor.run {
                    // Add results to the record
                    record.results.append(contentsOf: searchResults)
                    record.executionCount += 1
                    record.lastExecutionDate = Date()
                    
                    // Convert SearchResults to LinkRecords for the article list
                    for (_, searchResult) in searchResults.enumerated() {
                        let linkRecord = LinkRecord(
                            searchRecordId: record.id,
                            originalUrl: searchResult.link,
                            title: searchResult.title,
                            content: searchResult.snippet,
                            fetchedAt: Date(),
                            articleDescription: searchResult.snippet,
                            wordCount: searchResult.snippet.split(separator: " ").count,
                            readingTime: max(1, searchResult.snippet.split(separator: " ").count / 200)
                        )
                        modelContext.insert(linkRecord)
                    }
                    
                    DebugLogger.shared.logWebViewAction("✅ Automated search completed: \(record.query) - \(searchResults.count) results")
                }
            } catch {
                DebugLogger.shared.logWebViewAction("❌ Automated search failed: \(record.query) - \(error)")
            }
        }
    }
    
    private func parseScheduledTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let components = timeString.split(separator: ":")
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }
        return (hour: 0, minute: 0)
    }
    
}


#Preview {
    SearchListView()
        .modelContainer(for: [SearchRecord.self, LinkRecord.self, ImageRecord.self, SearchResult.self])
}
