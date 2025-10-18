//
//  ContentView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Search history records
    @Query(sort: \SearchRecord.createdAt, order: .reverse)
    private var records: [SearchRecord]

    @State private var selectedRecord: SearchRecord?
    @StateObject private var viewModel = SearchViewModel()

    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Quick search field at top of sidebar
                HStack {
                    TextField("Suchbegriff eingeben …", text: $searchText, onCommit: {
                        DebugLogger.shared.logSearchTextEntered(searchText)
                        Task { await runSearch() }
                    })
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .onChange(of: isSearchFieldFocused) { _, focused in
                        if focused {
                            DebugLogger.shared.logSearchFieldFocus()
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        if !newValue.isEmpty {
                            DebugLogger.shared.logSearchTextEntered(newValue)
                        }
                    }

                    Button {
                        DebugLogger.shared.logSearchButtonPressed()
                        Task { await runSearch() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut(.defaultAction)
                    .padding(.trailing, 8)
                    .disabled(viewModel.isSearching || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Suche starten")
                }

                List(selection: $selectedRecord) {
                    ForEach(records) { record in
                        NavigationLink(value: record) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.query)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(record.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteRecords)
                }
                
                // Löschen-Buttons am Ende der Sidebar
                if !records.isEmpty {
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack {
                            Button("Delete All") {
                                deleteAllRecords()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .help("Delete all search results")
                            
                            Spacer()
                            
                            Button("Delete Selected") {
                                deleteSelectedRecord()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.orange)
                            .disabled(selectedRecord == nil)
                            .help("Delete selected search result")
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("Verlauf")
            .toolbar {
                ToolbarItemGroup {
                    if viewModel.isSearching {
                        Button(role: .cancel) {
                            viewModel.cancelCurrentSearch()
                        } label: {
                            Label("Abbrechen", systemImage: "xmark.circle")
                        }
                        .help("Laufende Suche abbrechen")
                    } else {
                        Button {
                            Task { await runSearch() }
                        } label: {
                            Label("Suchen", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .help("Manuelle Suche starten")
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            Group {
                if viewModel.isSearching {
                    ProgressView("Suche läuft …")
                        .controlSize(.large)
                        .onAppear {
                            DebugLogger.shared.logWebViewAction("Showing search progress view")
                        }
                } else if let record = selectedRecord ?? records.first {
                    WebView(html: record.htmlSummary)
                        .id(record.id) // force reload when switching records
                        .navigationTitle(record.query)
                        .onAppear {
                            DebugLogger.shared.logWebViewAction("Displaying WebView for record: \(record.query)")
                            DebugLogger.shared.logWebViewAction("HTML content length: \(record.htmlSummary.count)")
                        }
                } else {
                    ContentPlaceholderView()
                        .onAppear {
                            DebugLogger.shared.logWebViewAction("Showing placeholder view - no records available")
                        }
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        Task { await rerenderSelectedRecord() }
                    } label: {
                        Label("Neu rendern", systemImage: "arrow.clockwise")
                    }
                    .disabled(selectedRecord == nil)
                    .help("HTML-Ansicht neu rendern")
                }
            }
        }
        .onAppear {
            DebugLogger.shared.logUserInterfaceReady()
            DebugLogger.shared.logSearchViewModelReady()
            
            viewModel.inject(modelContext: modelContext)

            // Menübefehle abonnieren
            NotificationCenter.default.addObserver(forName: .focusSearchField, object: nil, queue: .main) { _ in
                isSearchFieldFocused = true
            }
            NotificationCenter.default.addObserver(forName: .triggerManualSearch, object: nil, queue: .main) { _ in
                Task { await runSearch() }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .focusSearchField, object: nil)
            NotificationCenter.default.removeObserver(self, name: .triggerManualSearch, object: nil)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Cancel any running search when app goes inactive/background
            if newPhase != .active {
                viewModel.cancelCurrentSearch()
            }
        }
        .alert(item: $viewModel.activeError) { err in
            Alert(title: Text("Fehler"), message: Text(err.message), dismissButton: .default(Text("OK")))
        }
    }

    private func runSearch() async {
        DebugLogger.shared.logSearchInitiated(query: searchText)
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DebugLogger.shared.logSearchStateChange("Empty search text - focusing search field")
            // Setze den Fokus ins Suchfeld, falls leer
            isSearchFieldFocused = true
            return
        }
        
        DebugLogger.shared.logSearchStart(query: trimmed)
        DebugLogger.shared.logSearchStateChange("Starting search for: '\(trimmed)'")
        
        do {
            let record = try await viewModel.runSearch(query: trimmed)
            DebugLogger.shared.logSearchStateChange("Search completed successfully")
            selectedRecord = record
            searchText = ""
        } catch is CancellationError {
            DebugLogger.shared.logSearchStateChange("Search cancelled by user")
            // User cancelled; no alert
        } catch {
            DebugLogger.shared.logSearchError(query: trimmed, error: error)
            DebugLogger.shared.logSearchStateChange("Search failed with error: \(error.localizedDescription)")
            // Error is already surfaced via activeError
        }
    }

    private func rerenderSelectedRecord() async {
        guard let record = selectedRecord else { return }
        await viewModel.rerenderHTML(for: record)
    }

    private func deleteRecords(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
    
    private func deleteAllRecords() {
        withAnimation {
            for record in records {
                modelContext.delete(record)
            }
            selectedRecord = nil
        }
    }
    
    private func deleteSelectedRecord() {
        guard let record = selectedRecord else { return }
        
        withAnimation {
            modelContext.delete(record)
            selectedRecord = nil
        }
    }
}

private struct ContentPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Noch keine Suche durchgeführt")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Geben Sie einen Suchbegriff ein und klicken Sie auf Suchen.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SearchRecord.self, SearchResult.self], inMemory: true)
}
