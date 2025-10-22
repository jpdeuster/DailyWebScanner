import SwiftUI
import SwiftData

struct MainDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let searchRecord: ManualSearchRecord?
    let onOpenAutomatedSearch: () -> Void
    let onOpenArticles: () -> Void
    
    var body: some View {
        if let searchRecord {
            VStack(spacing: 16) {
                // Header
                SearchQueryHeaderView(searchRecord: searchRecord)
                
                // Results
                if !searchRecord.results.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Search Results (\(searchRecord.results.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        List(searchRecord.results
                            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                            .prefix(10)) { result in
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
                        Text("This search returned no results.")
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
                // Top-right actions + Help live weiterhin in Main/MainDetailView
                HStack {
                    Spacer()
                    
                    Button(action: { onOpenAutomatedSearch() }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                            Text("Automated Search")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Open Automated Search (⌘A)")
                    .keyboardShortcut("a", modifiers: .command)
                    
                    Button(action: { onOpenArticles() }) {
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
                        title: "Search History",
                        description: "View and manage your past searches"
                    )
                    InfoCard(
                        icon: "list.bullet",
                        title: "Detailed Results",
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
}

#Preview {
    MainDetailView(searchRecord: nil, onOpenAutomatedSearch: {}, onOpenArticles: {})
}
