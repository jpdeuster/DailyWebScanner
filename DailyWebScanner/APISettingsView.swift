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
    
    @State private var isTestingSerpAPI = false
    @State private var isTestingOpenAI = false
    @State private var serpAPIResult = ""
    @State private var openAIResult = ""
    @State private var accountInfo = ""
    @State private var isLoadingAccountInfo = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("API Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Configure your API keys for SerpAPI and OpenAI")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 12) {
                    // SerpAPI
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(.blue)
                            Text("SerpAPI")
                                .font(.headline)
                            Spacer()
                            statusPill(text: serpKey.isEmpty ? "Not configured" : "Configured",
                                       color: serpKey.isEmpty ? .orange : .green)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Enter SerpAPI Key…", text: $serpKey)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack(spacing: 8) {
                                Button(action: testSerpAPI) {
                                    Label("Test", systemImage: isTestingSerpAPI ? "hourglass" : "play.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(serpKey.isEmpty || isTestingSerpAPI)
                                
                                if isTestingSerpAPI {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                
                                Spacer()
                                
                                if !serpAPIResult.isEmpty {
                                    Text(serpAPIResult)
                                        .font(.caption)
                                        .foregroundColor(serpAPIResult.contains("✅") ? .green : .red)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.07))
                    .cornerRadius(10)
                    
                    // OpenAI
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("OpenAI")
                                .font(.headline)
                            Spacer()
                            statusPill(text: openAIKey.isEmpty ? "Optional" : "Configured",
                                       color: openAIKey.isEmpty ? .gray : .green)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Enter OpenAI Key… (optional)", text: $openAIKey)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack(spacing: 8) {
                                Button(action: testOpenAI) {
                                    Label("Test", systemImage: isTestingOpenAI ? "hourglass" : "play.circle.fill")
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                                .disabled(openAIKey.isEmpty || isTestingOpenAI)
                                
                                if isTestingOpenAI {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                
                                Spacer()
                                
                                if !openAIResult.isEmpty {
                                    Text(openAIResult)
                                        .font(.caption)
                                        .foregroundColor(openAIResult.contains("✅") ? .green : .red)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.purple.opacity(0.07))
                    .cornerRadius(10)
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configuration Summary")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: serpKey.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(serpKey.isEmpty ? .red : .green)
                                Text("SerpAPI: \(serpKey.isEmpty ? "Not configured" : "Configured")")
                                    .font(.caption)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: openAIKey.isEmpty ? "minus.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(openAIKey.isEmpty ? .orange : .green)
                                Text("OpenAI: \(openAIKey.isEmpty ? "Not configured (optional)" : "Configured")")
                                    .font(.caption)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(10)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .frame(minWidth: 480, minHeight: 380)
    }
    
    // MARK: - Helpers
    
    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }
    
    // MARK: - Actions
    
    private func testSerpAPI() {
        isTestingSerpAPI = true
        serpAPIResult = "Testing SerpAPI…"
        
        Task {
            do {
                let serpClient = SerpAPIClient(apiKeyProvider: { serpKey })
                let results = try await serpClient.fetchTopResults(query: "test", count: 1, hl: "en", gl: "us")
                
                if results.isEmpty {
                    serpAPIResult = "⚠️ SerpAPI: API key valid but no results returned"
                } else {
                    serpAPIResult = "✅ SerpAPI: Connection successful"
                }
            } catch {
                if let serpError = error as? SerpAPIClient.SerpError {
                    switch serpError {
                    case .missingAPIKey:
                        serpAPIResult = "❌ SerpAPI: API key is missing"
                    case .http(let code):
                        if code == 401 {
                            serpAPIResult = "❌ SerpAPI: Invalid API key (401)"
                        } else if code == 403 {
                            serpAPIResult = "❌ SerpAPI: Access denied (403)"
                        } else if code == 429 {
                            serpAPIResult = "❌ SerpAPI: Rate limit (429)"
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
        openAIResult = "Testing OpenAI…"
        
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
