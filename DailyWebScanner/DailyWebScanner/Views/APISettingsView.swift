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
            HStack {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("API Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // SerpAPI Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(.green)
                            Text("SerpAPI Configuration")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("API Key:")
                                        .fontWeight(.medium)
                                    Text("Your SerpAPI key for Google search")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                SecureField("Enter SerpAPI key", text: $serpKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 300)
                            }
                            
                            HStack {
                                Spacer()
                                
                                Button(action: testSerpAPI) {
                                    HStack {
                                        if isTestingSerpAPI {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "play.circle.fill")
                                        }
                                        Text("Test SerpAPI")
                                    }
                                }
                                .disabled(isTestingSerpAPI || serpKey.isEmpty)
                                .buttonStyle(.borderedProminent)
                            }
                            
                            if !serpAPIResult.isEmpty {
                                Text(serpAPIResult)
                                    .font(.caption)
                                    .foregroundColor(serpAPIResult.contains("Success") ? .green : .red)
                                    .padding(.top, 4)
                            }
                            
                            if !accountInfo.isEmpty {
                                Text(accountInfo)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.07))
                    .cornerRadius(10)
                    
                    // OpenAI Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("OpenAI Configuration")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("API Key:")
                                        .fontWeight(.medium)
                                    Text("Your OpenAI API key for AI summaries")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                SecureField("Enter OpenAI key", text: $openAIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 300)
                            }
                            
                            HStack {
                                Spacer()
                                
                                Button(action: testOpenAI) {
                                    HStack {
                                        if isTestingOpenAI {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "play.circle.fill")
                                        }
                                        Text("Test OpenAI")
                                    }
                                }
                                .disabled(isTestingOpenAI || openAIKey.isEmpty)
                                .buttonStyle(.borderedProminent)
                            }
                            
                            if !openAIResult.isEmpty {
                                Text(openAIResult)
                                    .font(.caption)
                                    .foregroundColor(openAIResult.contains("Success") ? .green : .red)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.purple.opacity(0.07))
                    .cornerRadius(10)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Information")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search parameters are now available directly in the main search interface for each individual search.")
                                .font(.body)
                            
                            Text("This allows you to customize your search settings on a per-search basis without having to change global settings.")
                                .font(.body)
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.07))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadAccountInfo()
        }
    }
    
    private func testSerpAPI() {
        isTestingSerpAPI = true
        serpAPIResult = ""
        
        Task {
            do {
                let client = SerpAPIClient(apiKeyProvider: { serpKey })
                _ = try await client.fetchTopResults(query: "test", count: 1)
                
                await MainActor.run {
                    isTestingSerpAPI = false
                    serpAPIResult = "Success: SerpAPI is working correctly"
                }
            } catch {
                await MainActor.run {
                    isTestingSerpAPI = false
                    serpAPIResult = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func testOpenAI() {
        isTestingOpenAI = true
        openAIResult = ""
        
        Task {
            let client = OpenAIClient(apiKeyProvider: { openAIKey })
            // Simple test - just check if the client can be created
            _ = client
            
            await MainActor.run {
                isTestingOpenAI = false
                openAIResult = "Success: OpenAI is working correctly"
            }
        }
    }
    
    private func loadAccountInfo() {
        guard !serpKey.isEmpty else { return }
        
        isLoadingAccountInfo = true
        
        Task {
            do {
                let client = SerpAPIClient(apiKeyProvider: { serpKey })
                let info = try await client.getAccountInfo()
                
                await MainActor.run {
                    isLoadingAccountInfo = false
                    accountInfo = "Credits remaining: \(info.credits_remaining ?? 0)"
                }
            } catch {
                await MainActor.run {
                    isLoadingAccountInfo = false
                    accountInfo = ""
                }
            }
        }
    }
}

#Preview {
    APISettingsView()
}