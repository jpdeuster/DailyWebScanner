import SwiftUI
import SwiftData

struct SearchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SearchRecord.createdAt, order: .reverse) private var searchRecords: [SearchRecord]
    @State private var selectedSearchRecord: SearchRecord?
    @State private var filterText: String = ""
    @State private var newSearchQuery: String = ""
    @State private var newSearchTime: String = "10:00"
    @State private var newSearchEnabled: Bool = true
    
    var filteredSearchRecords: [SearchRecord] {
        if filterText.isEmpty {
            return searchRecords
        } else {
            return searchRecords.filter { record in
                record.query.localizedCaseInsensitiveContains(filterText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header with Add New Search
                VStack(spacing: 12) {
                    Text("Automated Search Management")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Add New Search Section
                    VStack(spacing: 8) {
                        HStack {
                            TextField("Search query", text: $newSearchQuery)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Time (HH:MM)", text: $newSearchTime)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            
                            Toggle("Enabled", isOn: $newSearchEnabled)
                                .toggleStyle(.switch)
                        }
                        
                        Button("Add Automated Search") {
                            addAutomatedSearch()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newSearchQuery.isEmpty)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
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
                            Text(searchRecord.createdAt, format: .dateTime)
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
            DebugLogger.shared.logWebViewAction("🔍 SearchListView appeared - searchRecords count: \(searchRecords.count)")
            for (index, record) in searchRecords.enumerated() {
                DebugLogger.shared.logWebViewAction("🔍 SearchListView: Record \(index): '\(record.query)' (ID: \(record.id))")
            }
        }
    }
    
    private func addAutomatedSearch() {
        let newRecord = SearchRecord(
            query: newSearchQuery,
            language: "en",
            region: "US",
            location: "",
            safeSearch: "off",
            searchType: "",
            timeRange: "",
            numberOfResults: 20,
            searchDuration: 0.0,
            resultCount: 0,
            results: [],
            contentAnalysis: "",
            headlinesCount: 0,
            linksCount: 0,
            contentBlocksCount: 0,
            tagsCount: 0,
            hasContentAnalysis: false,
            linkContents: "",
            hasLinkContents: false,
            totalImagesDownloaded: 0,
            totalContentSize: 0,
            isEnabled: newSearchEnabled,
            executionCount: 0,
            lastExecutionDate: nil,
            scheduledTime: newSearchTime,
            dateRange: ""
        )
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            DebugLogger.shared.logWebViewAction("✅ SearchListView: Added automated search '\(newSearchQuery)'")
            
            // Reset form
            newSearchQuery = ""
            newSearchTime = "10:00"
            newSearchEnabled = true
        } catch {
            DebugLogger.shared.logWebViewAction("❌ SearchListView: Failed to add automated search: \(error.localizedDescription)")
        }
    }
    
    private func deleteSearchRecord(_ record: SearchRecord) {
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
    let record: SearchRecord
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.isEnabled ? "clock.circle.fill" : "clock.circle")
                .foregroundColor(record.isEnabled ? .blue : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.query)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(record.createdAt, format: .dateTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Search Metadata as Tags
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
    }
}


#Preview {
    SearchListView()
        .modelContainer(for: [SearchRecord.self, LinkRecord.self, ImageRecord.self, SearchResult.self])
}
