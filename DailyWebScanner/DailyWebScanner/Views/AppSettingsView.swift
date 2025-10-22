//
//  AppSettingsView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system" // system, light, dark
    @AppStorage("openArticlesOnLaunch") private var openArticlesOnLaunch: Bool = true
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
    
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
                HStack { Spacer(); HelpButton(urlString: "https://github.com/jpdeuster/DailyWebScanner#readme") }
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
                            
                            Toggle(isOn: $openArticlesOnLaunch) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Open Articles on Launch")
                                        .fontWeight(.medium)
                                    Text("Automatically open the Articles window after app start")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                            
                            // History Limit removed as not useful in current UX
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
                                Text(appVersion)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Build:")
                                    .fontWeight(.medium)
                                Text(appBuild)
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
        appearanceMode = "system"
        openArticlesOnLaunch = true
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
