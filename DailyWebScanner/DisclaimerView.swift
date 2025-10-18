import SwiftUI

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Important Legal Notice")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Please read this document carefully before using DailyWebScanner.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // No Warranty Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("🚫 No Warranty")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("THIS SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.")
                        .font(.body)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• \"As Is\": DailyWebScanner is provided \"as is\" and \"as available\" without any warranties")
                        Text("• No Guarantees: The developer makes no guarantees regarding reliability, accuracy, or performance")
                        Text("• No Support Obligation: While community support is encouraged, no technical support is guaranteed")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // User Responsibility Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("👤 User Responsibility")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("You, as the user, are solely and entirely responsible for your use of this application and any data you process, store, or transmit through it.")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Data Usage & Compliance:")
                            .fontWeight(.semibold)
                        Text("• Comply with all applicable laws and regulations regarding data processing")
                        Text("• Ensure your use respects copyright, data protection laws (GDPR, CCPA)")
                        Text("• You are responsible for any legal consequences")
                        
                        Text("2. API Keys & External Services:")
                            .fontWeight(.semibold)
                        Text("• You are responsible for obtaining, securing, and using your API keys")
                        Text("• Do not share your API keys publicly")
                        Text("• Comply with Terms of Service of third-party APIs")
                        
                        Text("3. Search Results & Content:")
                            .fontWeight(.semibold)
                        Text("• You are responsible for how you interpret and use search results")
                        Text("• Accuracy and reliability of results are not guaranteed")
                        Text("• You are responsible for any offensive or inappropriate content")
                        
                        Text("4. Privacy & Security:")
                            .fontWeight(.semibold)
                        Text("• You are responsible for protecting your privacy and others' privacy")
                        Text("• You are responsible for overall system security")
                        Text("• No liability for data breaches or security incidents")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // No Liability Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("🚫 No Liability")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("IN NO EVENT SHALL THE DEVELOPER, CONTRIBUTORS, OR ANY AFFILIATED PARTIES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES, INCLUDING BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR OTHER INTANGIBLE LOSSES.")
                        .font(.body)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Hobby Project Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("📚 Hobby Project for Learning")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("DailyWebScanner is developed as a personal hobby project with a focus on learning Swift, SwiftUI, and macOS development. It is not intended for commercial use or mission-critical applications.")
                        .font(.body)
                }
                
                Divider()
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Disclaimer may be updated from time to time. Your continued use of the software after any changes constitutes your acceptance of the new Disclaimer.")
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
    DisclaimerView()
}
