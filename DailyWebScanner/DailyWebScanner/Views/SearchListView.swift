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
                        Text("Search History")
                            .font(.headline)
                        
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                    
                    // Search Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Query:")
                                .fontWeight(.semibold)
                            Text(searchRecord.query)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Created:")
                                .fontWeight(.semibold)
                            Text(searchRecord.timestamp, format: .dateTime)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Executions:")
                                .fontWeight(.semibold)
                            Text("\(searchRecord.executionCount)")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Last Run:")
                                .fontWeight(.semibold)
                            Text(searchRecord.lastExecutionDate?.formatted() ?? "Never")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Results:")
                                .fontWeight(.semibold)
                            Text("\(searchRecord.results.count)")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Status:")
                                .fontWeight(.semibold)
                            Text(searchRecord.isEnabled ? "Enabled" : "Disabled")
                                .foregroundColor(searchRecord.isEnabled ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // Search Results Preview
                    if !searchRecord.results.isEmpty {
                        Text("Recent Results")
                            .font(.headline)
                        
                        List(searchRecord.results.prefix(5)) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                if !result.snippet.isEmpty {
                                    Text(result.snippet)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                
                                Button(action: {
                                    if let url = URL(string: result.link) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Text(result.link)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                    } else {
                        Text("No results yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Select a search from the sidebar")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("View search details and execution history")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .onAppear {
            DebugLogger.shared.logWebViewAction("🔍 SearchListView appeared - allSearchRecords count: \(allSearchRecords.count)")
            for (index, record) in allSearchRecords.enumerated() {
                DebugLogger.shared.logWebViewAction("🔍 SearchListView: Record \(index): '\(record.query)' (ID: \(record.id))")
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
                            html: "",
                            css: "",
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
            }
            
            Spacer()
            
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
