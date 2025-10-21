import SwiftUI

/// Beautiful header view for search queries with comprehensive information
struct SearchQueryHeaderView: View {
    let searchRecord: any SearchRecordProtocol
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Header Card with Gradient Background
            VStack(spacing: 20) {
                // Header with Query and Status
                HStack(alignment: .top, spacing: 16) {
                    // Enhanced Search Icon with Background
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    // Query Information with Enhanced Styling
                    VStack(alignment: .leading, spacing: 8) {
                        Text(searchRecord.query)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        // Enhanced Status Badges
                        HStack(spacing: 12) {
                            StatusBadge(
                                icon: "checkmark.circle.fill",
                                text: "\(searchRecord.results.count) Results",
                                color: .green,
                                style: .filled
                            )
                            
                            if let automatedRecord = searchRecord as? AutomatedSearchRecord {
                                if automatedRecord.isEnabled {
                                    StatusBadge(
                                        icon: "play.circle.fill",
                                        text: "Automated",
                                        color: .orange,
                                        style: .filled
                                    )
                                } else {
                                    StatusBadge(
                                        icon: "pause.circle.fill",
                                        text: "Paused",
                                        color: .gray,
                                        style: .outlined
                                    )
                                }
                            }
                            
                            if searchRecord is ManualSearchRecord {
                                StatusBadge(
                                    icon: "hand.point.up.fill",
                                    text: "Manual",
                                    color: .blue,
                                    style: .filled
                                )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced Expand/Collapse Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isExpanded ? 1.1 : 1.0)
                }
                
                // Timestamp and Quick Info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Searched: \(searchRecord.timestamp, format: .dateTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let automatedRecord = searchRecord as? AutomatedSearchRecord,
                           !automatedRecord.scheduledTime.isEmpty {
                            Text("Next: \(nextSearchTime(for: automatedRecord))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Quick Stats
                    HStack(spacing: 12) {
                        QuickStat(
                            icon: "clock",
                            value: "\(searchRecord.readingTime) min",
                            label: "Read"
                        )
                        
                        QuickStat(
                            icon: "textformat",
                            value: "\(searchRecord.wordCount)",
                            label: "Words"
                        )
                    }
                }
                
                // Expanded Details
                if isExpanded {
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, -16)
                        
                        // Search Parameters Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ParameterCard(
                                icon: "globe",
                                title: "Language",
                                value: searchRecord.language.isEmpty ? "Any" : searchRecord.language,
                                color: .blue
                            )
                            
                            ParameterCard(
                                icon: "map",
                                title: "Region",
                                value: searchRecord.region.isEmpty ? "Any" : searchRecord.region,
                                color: .green
                            )
                            
                            ParameterCard(
                                icon: "shield",
                                title: "Safe Search",
                                value: searchRecord.safe.isEmpty ? "Off" : searchRecord.safe,
                                color: searchRecord.safe == "active" ? .green : .gray
                            )
                            
                            ParameterCard(
                                icon: "magnifyingglass",
                                title: "Type",
                                value: searchRecord.tbm.isEmpty ? "All" : searchRecord.tbm,
                                color: .purple
                            )
                            
                            if !searchRecord.location.isEmpty {
                                ParameterCard(
                                    icon: "location",
                                    title: "Location",
                                    value: searchRecord.location,
                                    color: .orange
                                )
                            }
                            
                            if !searchRecord.as_qdr.isEmpty {
                                ParameterCard(
                                    icon: "clock",
                                    title: "Time Range",
                                    value: searchRecord.as_qdr,
                                    color: .red
                                )
                            }
                        }
                        
                        // Additional Info for Automated Searches
                        if let automatedRecord = searchRecord as? AutomatedSearchRecord {
                            VStack(spacing: 8) {
                                Divider()
                                    .padding(.horizontal, -16)
                                
                                HStack {
                                    Text("Automation Details")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                HStack(spacing: 16) {
                                    AutomationDetail(
                                        icon: "repeat",
                                        title: "Schedule",
                                        value: automatedRecord.scheduledTime
                                    )
                                    
                                    AutomationDetail(
                                        icon: "number",
                                        title: "Executions",
                                        value: "\(automatedRecord.executionCount)"
                                    )
                                    
                                    if let lastExecution = automatedRecord.lastExecutionDate {
                                        AutomationDetail(
                                            icon: "clock.arrow.circlepath",
                                            title: "Last Run",
                                            value: lastExecution.formatted(.relative(presentation: .named))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func nextSearchTime(for record: AutomatedSearchRecord) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        let scheduledTime = parseScheduledTime(record.scheduledTime)
        let scheduledHour = scheduledTime.hour
        let scheduledMinute = scheduledTime.minute
        
        var nextDate = calendar.date(bySettingHour: scheduledHour, minute: scheduledMinute, second: 0, of: now) ?? now
        
        if nextDate <= now {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? now
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: nextDate)
    }
    
    private func parseScheduledTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let components = timeString.split(separator: ":")
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            return (hour: hour, minute: minute)
        }
        return (hour: 10, minute: 0) // Default
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color
    let style: BadgeStyle
    
    enum BadgeStyle {
        case filled
        case outlined
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .fontWeight(.semibold)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(style == .filled ? .white : color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(style == .filled ? color : color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: style == .outlined ? 1.5 : 0)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ParameterCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

struct AutomationDetail: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.05))
        )
    }
}

// MARK: - Protocol for Search Records

protocol SearchRecordProtocol {
    var id: UUID { get }
    var query: String { get }
    var language: String { get }
    var region: String { get }
    var location: String { get }
    var safe: String { get }
    var tbm: String { get }
    var as_qdr: String { get }
    var timestamp: Date { get }
    var results: [SearchResult] { get }
    var wordCount: Int { get }
    var readingTime: Int { get }
}

// MARK: - Extensions

extension ManualSearchRecord: SearchRecordProtocol {
    var wordCount: Int {
        return results.reduce(0) { $0 + $1.snippet.split(separator: " ").count }
    }
    
    var readingTime: Int {
        return max(1, wordCount / 200)
    }
}

extension AutomatedSearchRecord: SearchRecordProtocol {
    var wordCount: Int {
        return results.reduce(0) { $0 + $1.snippet.split(separator: " ").count }
    }
    
    var readingTime: Int {
        return max(1, wordCount / 200)
    }
}
