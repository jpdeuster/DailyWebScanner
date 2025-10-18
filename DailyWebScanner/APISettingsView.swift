//
//  APISettingsView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI

struct APISettingsView: View {
    @AppStorage("serpAPIKey") private var serpKey: String = ""
    @AppStorage("openAIKey") private var openAIKey: String = ""
    
    @State private var showingTestResults = false
    @State private var testResults = ""
    @State private var isTestingSerpAPI = false
    @State private var isTestingOpenAI = false
    @State private var serpAPIResult = ""
    @State private var openAIResult = ""
    @State private var accountInfo = ""
    @State private var isLoadingAccountInfo = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Close Button
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Configure your API keys for SerpAPI and OpenAI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 10)
            
            Divider()
            
            // SerpAPI Settings
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SerpAPI")
                            .font(.headline)
                        Text("For Google Web Search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Enter SerpAPI Key...", text: $serpKey)
                        .textFieldStyle(.roundedBorder)
                        .help("Your SerpAPI key for Google Web Search")
                    
                    HStack {
                        if serpKey.isEmpty {
                            Text("⚠️ SerpAPI key is required for search")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("✅ SerpAPI key is configured")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Button(action: testSerpAPI) {
                            HStack {
                                if isTestingSerpAPI {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text("Test")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(serpKey.isEmpty || isTestingSerpAPI)
                        .help("Test SerpAPI connection")
                    }
                    
                    if !serpAPIResult.isEmpty {
                        Text(serpAPIResult)
                            .font(.caption)
                            .foregroundColor(serpAPIResult.contains("✅") ? .green : .red)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // OpenAI Settings
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenAI")
                            .font(.headline)
                        Text("For AI Summaries (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Enter OpenAI Key... (optional)", text: $openAIKey)
                        .textFieldStyle(.roundedBorder)
                        .help("Your OpenAI key for AI summaries")
                    
                    HStack {
                        if openAIKey.isEmpty {
                            Text("ℹ️ OpenAI key is optional - Original text will be used")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("✅ OpenAI key is configured")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Button(action: testOpenAI) {
                            HStack {
                                if isTestingOpenAI {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text("Test")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(openAIKey.isEmpty || isTestingOpenAI)
                        .help("Test OpenAI connection")
                    }
                    
                    if !openAIResult.isEmpty {
                        Text(openAIResult)
                            .font(.caption)
                            .foregroundColor(openAIResult.contains("✅") ? .green : .red)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
            
            // Summary Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration Summary")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: serpKey.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(serpKey.isEmpty ? .red : .green)
                        Text("SerpAPI: \(serpKey.isEmpty ? "Not configured" : "Configured")")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: openAIKey.isEmpty ? "minus.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(openAIKey.isEmpty ? .orange : .green)
                        Text("OpenAI: \(openAIKey.isEmpty ? "Not configured (optional)" : "Configured")")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func testSerpAPI() {
        isTestingSerpAPI = true
        serpAPIResult = "Testing SerpAPI..."
        
        Task {
            do {
                // Simple test query with minimal parameters
                let serpClient = SerpAPIClient(apiKeyProvider: { serpKey })
                let results = try await serpClient.fetchTopResults(query: "test", count: 1, hl: "en", gl: "us")
                
                if results.isEmpty {
                    serpAPIResult = "⚠️ SerpAPI: API key valid but no results returned"
                } else {
                    serpAPIResult = "✅ SerpAPI: Connection successful"
                }
            } catch {
                // More detailed error reporting
                if let serpError = error as? SerpAPIClient.SerpError {
                    switch serpError {
                    case .missingAPIKey:
                        serpAPIResult = "❌ SerpAPI: API key is missing"
                    case .http(let code):
                        if code == 401 {
                            serpAPIResult = "❌ SerpAPI: Invalid API key (401 Unauthorized)"
                        } else if code == 403 {
                            serpAPIResult = "❌ SerpAPI: API key access denied (403 Forbidden)"
                        } else if code == 429 {
                            serpAPIResult = "❌ SerpAPI: Rate limit exceeded (429 Too Many Requests)"
                        } else {
                            serpAPIResult = "❌ SerpAPI: HTTP error \(code)"
                        }
                    case .network(let message):
                        serpAPIResult = "❌ SerpAPI: \(message)"
                    default:
                        serpAPIResult = "❌ SerpAPI: \(serpError.localizedDescription)"
                    }
                } else {
                    serpAPIResult = "❌ SerpAPI: \(error.localizedDescription)"
                }
            }
            
            isTestingSerpAPI = false
        }
    }
    
    private func testOpenAI() {
        isTestingOpenAI = true
        openAIResult = "Testing OpenAI..."
        
        Task {
            do {
                let openAIClient = OpenAIClient(apiKeyProvider: { openAIKey })
                let _ = try await openAIClient.summarize(snippet: "Test", title: "Test", link: "https://test.com")
                openAIResult = "✅ OpenAI: Connection successful"
            } catch {
                openAIResult = "❌ OpenAI: \(error.localizedDescription)"
            }
            
            isTestingOpenAI = false
        }
    }
}

#Preview {
    APISettingsView()
}
