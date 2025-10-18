import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("DailyWebScanner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 0.5 Beta")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("A modern macOS app for daily web searches with Google Search integration and optional AI-powered summarization.")
                    .multilineTextAlignment(.center)
                
                Text("Built with SwiftUI and designed for learning purposes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Features:")
                    .font(.headline)
                
                FeatureRow(icon: "magnifyingglass", text: "Google Web Search Integration")
                FeatureRow(icon: "brain.head.profile", text: "Optional AI Summarization")
                FeatureRow(icon: "clock", text: "Search History")
                FeatureRow(icon: "lock.shield", text: "Secure Keychain Storage")
                FeatureRow(icon: "globe", text: "Multi-language Support")
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                Text("This is a hobby project for learning purposes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Use at your own risk. See Help menu for legal information.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            Text(text)
                .font(.caption)
        }
    }
}

#Preview {
    AboutView()
}
