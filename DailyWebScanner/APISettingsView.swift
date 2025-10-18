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
    @State private var isTesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("API Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Configure your API keys for SerpAPI and OpenAI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                        Text("Für Google Web Search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API-Schlüssel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("SerpAPI Key eingeben...", text: $serpKey)
                        .textFieldStyle(.roundedBorder)
                        .help("Ihr SerpAPI-Schlüssel für Google Web Search")
                    
                    if serpKey.isEmpty {
                        Text("⚠️ SerpAPI-Schlüssel ist erforderlich für die Suche")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("✅ SerpAPI-Schlüssel ist konfiguriert")
                            .font(.caption)
                            .foregroundColor(.green)
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
                        Text("Für KI-Zusammenfassungen (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API-Schlüssel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("OpenAI Key eingeben... (optional)", text: $openAIKey)
                        .textFieldStyle(.roundedBorder)
                        .help("Ihr OpenAI-Schlüssel für KI-Zusammenfassungen")
                    
                    if openAIKey.isEmpty {
                        Text("ℹ️ OpenAI-Schlüssel ist optional - Original-Text wird verwendet")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text("✅ OpenAI-Schlüssel ist konfiguriert")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
            
            // Test Section
            VStack(alignment: .leading, spacing: 12) {
                Text("API-Test")
                    .font(.headline)
                
                Button(action: testAPIs) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(isTesting ? "Teste APIs..." : "APIs testen")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(serpKey.isEmpty || isTesting)
                .help("Testet die Konfiguration der API-Schlüssel")
                
                if showingTestResults {
                    Text(testResults)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func testAPIs() {
        isTesting = true
        showingTestResults = true
        testResults = "Teste APIs..."
        
        Task {
            do {
                // Test SerpAPI
                let serpClient = SerpAPIClient(apiKeyProvider: { serpKey })
                let _ = try await serpClient.fetchTopResults(query: "test", count: 1)
                
                testResults = "✅ SerpAPI: Erfolgreich verbunden\n"
                
                // Test OpenAI (if configured)
                if !openAIKey.isEmpty {
                    let openAIClient = OpenAIClient(apiKeyProvider: { openAIKey })
                    let _ = try await openAIClient.summarize(snippet: "Test", title: "Test", link: "https://test.com")
                    testResults += "✅ OpenAI: Erfolgreich verbunden"
                } else {
                    testResults += "ℹ️ OpenAI: Nicht konfiguriert (optional)"
                }
                
            } catch {
                testResults = "❌ API-Test fehlgeschlagen: \(error.localizedDescription)"
            }
            
            isTesting = false
        }
    }
}

#Preview {
    APISettingsView()
}
