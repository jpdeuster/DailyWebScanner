import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔒 Privacy & Data Responsibility")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Your privacy and data security are important to us. Please understand your responsibilities when using DailyWebScanner.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Data Collection Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("📊 What We Collect")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✅ What IS collected:")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("• Search queries (stored locally)")
                        Text("• Search results (stored locally)")
                        Text("• API keys (stored securely in Keychain)")
                        Text("• App usage statistics (for debugging)")
                        
                        Text("❌ What is NOT collected:")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Text("• Personal information")
                        Text("• Browsing history outside the app")
                        Text("• Location data")
                        Text("• Contact information")
                        Text("• Any data sent to external servers (except API calls)")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // Data Storage Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("💾 Data Storage")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• All data is stored locally on your Mac")
                        Text("• Search history uses SwiftData (local database)")
                        Text("• API keys are stored in macOS Keychain")
                        Text("• No data is transmitted to our servers")
                        Text("• No cloud synchronization (unless you configure it)")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // External Services Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("🌐 External Services")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DailyWebScanner uses these external services:")
                            .fontWeight(.semibold)
                        
                        Text("• SerpAPI: For Google search results")
                        Text("  - Your search queries are sent to SerpAPI")
                        Text("  - SerpAPI's privacy policy applies")
                        Text("  - No personal data is shared beyond search queries")
                        
                        Text("• OpenAI: For AI summarization (optional)")
                        Text("  - Search snippets are sent to OpenAI for summarization")
                        Text("  - OpenAI's privacy policy applies")
                        Text("  - You can disable this feature entirely")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // Your Responsibilities Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("👤 Your Responsibilities")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("As a user, you are responsible for:")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text("• Protecting your API keys and not sharing them")
                        Text("• Complying with external service terms (SerpAPI, OpenAI)")
                        Text("• Ensuring your use complies with applicable laws")
                        Text("• Being aware of what data you're processing")
                        Text("• Making informed decisions about data usage")
                        Text("• Understanding the implications of AI processing")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // Security Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("🛡️ Security Measures")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We implement these security measures:")
                        Text("• macOS App Sandbox for process isolation")
                        Text("• Secure Keychain storage for API keys")
                        Text("• HTTPS-only communication")
                        Text("• No hardcoded credentials in source code")
                        Text("• Minimal system permissions")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // Important Notice
                VStack(alignment: .leading, spacing: 12) {
                    Text("⚠️ Important Notice")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("This is a hobby project for learning purposes. While we take privacy seriously, this software is provided 'as is' without warranty. You use it at your own risk and are responsible for your data usage.")
                        .font(.body)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    Text("For complete legal information, see the Disclaimer in the Help menu.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Last Updated: October 18, 2024")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PrivacyView()
}
