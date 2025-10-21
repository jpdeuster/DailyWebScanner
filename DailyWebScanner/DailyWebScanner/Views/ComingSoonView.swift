import SwiftUI

struct ComingSoonView: View {
    let feature: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .opacity(0.7)
            
            // Title
            Text("Coming Soon")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Feature Name
            Text(feature)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Progress indicator
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < 2 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text("In Development")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    ComingSoonView(
        feature: "Advanced Search Filters",
        description: "Enhanced search capabilities with custom filters, date ranges, and content type selection.",
        icon: "slider.horizontal.3"
    )
}
