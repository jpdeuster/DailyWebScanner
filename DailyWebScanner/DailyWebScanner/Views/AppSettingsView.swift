//
//  AppSettingsView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("maxSearchHistory") private var maxSearchHistory: Int = 0 // 0 = Unlimited
    @AppStorage("appearanceMode") private var appearanceMode: String = "system" // system, light, dark
    
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
                            HStack {
                                Text("Appearance Mode:")
                                    .fontWeight(.medium)
                                
                                Picker("", selection: $appearanceMode) {
                                    Text("System").tag("system")
                                    Text("Light").tag("light")
                                    Text("Dark").tag("dark")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                                .onChange(of: appearanceMode) { _, newValue in
                                    applyAppearanceMode(newValue)
                                }
                            }
                            
                            HStack {
                                Text("History Limit:")
                                    .fontWeight(.medium)
                                
                                Picker("", selection: $maxSearchHistory) {
                                    Text("Unlimited").tag(0)
                                    Text("100").tag(100)
                                    Text("500").tag(500)
                                    Text("1000").tag(1000)
                                    Text("5000").tag(5000)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
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
        maxSearchHistory = 0 // Unlimited
        appearanceMode = "system"
    }
    
    private func applyAppearanceMode(_ mode: String) {
        switch mode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case "system":
            NSApp.appearance = nil // Follows system setting
        default:
            NSApp.appearance = nil
        }
    }
}

#Preview {
    AppSettingsView()
}
