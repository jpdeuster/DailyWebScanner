import SwiftUI

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Content Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Advanced content analysis and AI-powered insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Coming Soon Content
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Coming Soon")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("This feature is currently under development and will be available in a future update.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // Planned Features
            VStack(alignment: .leading, spacing: 12) {
                Text("Planned Features:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                AnalysisFeatureRow(icon: "text.bubble", title: "Content Summarization", description: "AI-powered summaries of search results")
                AnalysisFeatureRow(icon: "tag", title: "Smart Tagging", description: "Automatic content categorization and tagging")
                AnalysisFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Trend Analysis", description: "Track topics and trends over time")
                AnalysisFeatureRow(icon: "link", title: "Link Analysis", description: "Analyze and categorize links and sources")
                AnalysisFeatureRow(icon: "brain.head.profile", title: "AI Insights", description: "Get intelligent insights from your search data")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Close Button
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(30)
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct AnalysisFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AnalysisView()
}
