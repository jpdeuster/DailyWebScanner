//
//  AppSettingsView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("autoSaveResults") private var autoSaveResults: Bool = true
    @AppStorage("showDebugInfo") private var showDebugInfo: Bool = false
    @AppStorage("maxSearchHistory") private var maxSearchHistory: Int = 100
    @AppStorage("defaultSearchCount") private var defaultSearchCount: Int = 20
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("App Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("General settings for the DailyWebScanner app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // General Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("General")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Automatically save search results", isOn: $autoSaveResults)
                                .help("Automatically saves all search results in history")
                            
                            Toggle("Show debug information", isOn: $showDebugInfo)
                                .help("Shows detailed debug information in the console")
                            
                            HStack {
                                Text("Maximum history entries:")
                                    .fontWeight(.medium)
                                
                                Picker("History", selection: $maxSearchHistory) {
                                    Text("50").tag(50)
                                    Text("100").tag(100)
                                    Text("200").tag(200)
                                    Text("500").tag(500)
                                    Text("Unlimited").tag(0)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Search Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("Search")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Default number of results:")
                                    .fontWeight(.medium)
                                
                                Picker("Number", selection: $defaultSearchCount) {
                                    Text("10").tag(10)
                                    Text("20").tag(20)
                                    Text("30").tag(30)
                                    Text("50").tag(50)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 100)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // App Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            Text("App Information")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Version:")
                                    .fontWeight(.medium)
                                Text("0.5-beta")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Build:")
                                    .fontWeight(.medium)
                                Text("Debug")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Developer:")
                                    .fontWeight(.medium)
                                Text("Jörg-Peter Deuster")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Reset Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            Text("Reset")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Reset all settings") {
                                resetAllSettings()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .help("Resets all settings to default values")
                            
                            Text("⚠️ This action cannot be undone")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func resetAllSettings() {
        autoSaveResults = true
        showDebugInfo = false
        maxSearchHistory = 100
        defaultSearchCount = 20
    }
}

#Preview {
    AppSettingsView()
}
