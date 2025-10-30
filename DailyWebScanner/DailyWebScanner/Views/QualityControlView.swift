import SwiftUI
import SwiftData

struct QualityControlView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var linkRecords: [LinkRecord]
    
    private var qualityStats: (high: Int, medium: Int, low: Int, excluded: Int) {
        var stats = (high: 0, medium: 0, low: 0, excluded: 0)
        
        for record in linkRecords {
            switch record.contentQuality {
            case "high":
                stats.high += 1
            case "medium":
                stats.medium += 1
            case "low":
                stats.low += 1
            case "excluded":
                stats.excluded += 1
            default:
                stats.medium += 1
            }
        }
        
        return stats
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quality Control")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Manage content quality filters and patterns")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .background(Color(NSColor.controlBackgroundColor))
                
                // Quality Terms Editor Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quality Terms")
                                .font(.headline)
                            Text("Configure patterns for content filtering")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    NavigationLink(destination: QualityTermsEditorView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Quality Terms")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Customize meaningful content patterns, low quality indicators, and excluded URL patterns")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.title3)
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                
                // Quality Statistics Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quality Statistics")
                                .font(.headline)
                            Text("Overview of content quality distribution")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QualityStatCard(
                            title: "High Quality",
                            count: qualityStats.high,
                            color: .green,
                            icon: "checkmark.circle.fill",
                            description: "Well-structured content"
                        )
                        
                        QualityStatCard(
                            title: "Medium Quality",
                            count: qualityStats.medium,
                            color: .orange,
                            icon: "exclamationmark.circle.fill",
                            description: "Acceptable content"
                        )
                        
                        QualityStatCard(
                            title: "Low Quality",
                            count: qualityStats.low,
                            color: .red,
                            icon: "xmark.circle.fill",
                            description: "Poor content quality"
                        )
                        
                        QualityStatCard(
                            title: "Excluded",
                            count: qualityStats.excluded,
                            color: .gray,
                            icon: "minus.circle.fill",
                            description: "Filtered out content"
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                // Quick Actions Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Actions")
                                .font(.headline)
                            Text("Common quality control tasks")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        QuickActionButton(
                            title: "Reset to Defaults",
                            description: "Restore original quality patterns",
                            icon: "arrow.clockwise",
                            color: .blue
                        ) {
                            // TODO: Implement reset functionality
                        }
                        
                        QuickActionButton(
                            title: "Export Settings",
                            description: "Save quality patterns to file",
                            icon: "square.and.arrow.up",
                            color: .green
                        ) {
                            // TODO: Implement export functionality
                        }
                        
                        QuickActionButton(
                            title: "Import Settings",
                            description: "Load quality patterns from file",
                            icon: "square.and.arrow.down",
                            color: .purple
                        ) {
                            // TODO: Implement import functionality
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("Quality Control")
    }
}

struct QualityStatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct QuickActionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QualityControlView()
}
