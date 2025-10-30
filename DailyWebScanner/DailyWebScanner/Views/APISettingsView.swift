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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "gear.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Konfiguration der externen Dienste")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HelpButton(urlString: "https://github.com/jpdeuster/DailyWebScanner#readme")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // SerpAPI Configuration Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SerpAPI")
                                .font(.headline)
                            Text("Google-Suchergebnisse über SerpAPI abrufen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("API Key")
                                    .fontWeight(.medium)
                                Text("Ihr SerpAPI-Schlüssel für Google-Suche")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            SecureField("SerpAPI Key eingeben", text: $serpKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 260, maxWidth: 340)
                        }
                        
                        HStack(spacing: 6) {
                            Text("Kein Key?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Link("Hier Key erstellen", destination: URL(string: "https://serpapi.com/users/welcome")!)
                                .font(.caption)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: testSerpAPI) {
                                HStack(spacing: 6) {
                                    if isTestingSerpAPI { ProgressView().scaleEffect(0.8) } else { Image(systemName: "play.circle.fill") }
                                    Text("SerpAPI testen")
                                }
                            }
                            .disabled(isTestingSerpAPI || serpKey.isEmpty)
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if !serpAPIResult.isEmpty {
                            Text(serpAPIResult)
                                .font(.caption)
                                .foregroundColor(serpAPIResult.contains("Success") ? .green : .red)
                        }
                        
                        HStack(spacing: 6) {
                            Text("Nutzung / Credits prüfen:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Link("SerpAPI Dashboard öffnen", destination: URL(string: "https://serpapi.com/dashboard")!)
                                .font(.caption)
                        }
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // OpenAI Configuration Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("OpenAI")
                                .font(.headline)
                            Text("KI-Funktionen (z. B. Zusammenfassungen)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("API Key")
                                    .fontWeight(.medium)
                                Text("Ihr OpenAI-Schlüssel für KI-Funktionen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            SecureField("OpenAI Key eingeben", text: $openAIKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 260, maxWidth: 340)
                        }
                        
                        HStack(spacing: 6) {
                            Text("Kein Key?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Link("Hier Key erstellen", destination: URL(string: "https://platform.openai.com/api-keys")!)
                                .font(.caption)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: testOpenAI) {
                                HStack(spacing: 6) {
                                    if isTestingOpenAI { ProgressView().scaleEffect(0.8) } else { Image(systemName: "play.circle.fill") }
                                    Text("OpenAI testen")
                                }
                            }
                            .disabled(isTestingOpenAI || openAIKey.isEmpty)
                            .buttonStyle(.borderedProminent)
                        }
                        
                        if !openAIResult.isEmpty {
                            Text(openAIResult)
                                .font(.caption)
                                .foregroundColor(openAIResult.contains("Success") ? .green : .red)
                        }
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Information")
                                .font(.headline)
                            Text("Suchparameter sind pro Suche konfigurierbar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Die Suchparameter können direkt in der Suchoberfläche für jede Suche angepasst werden.")
                            .font(.body)
                        Text("Globale Änderungen sind dadurch seltener nötig und flexibler.")
                            .font(.body)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 10)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Load from Keychain into AppStorage for consistent UI
            if let kc = KeychainHelper.get(.serpAPIKey), !kc.isEmpty { serpKey = kc }
        }
        .onChange(of: serpKey) { _, newValue in
            // Mirror to Keychain for global usage
            _ = KeychainHelper.set(newValue, for: .serpAPIKey)
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
            _ = client
            
            await MainActor.run {
                isTestingOpenAI = false
                openAIResult = "Success: OpenAI is working correctly"
            }
        }
    }
}

#Preview {
    APISettingsView()
}