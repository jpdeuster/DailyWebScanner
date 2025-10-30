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
    @AppStorage("acceptAllCookies") private var acceptAllCookies: Bool = true
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .foregroundColor(.blue)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Allgemeine Einstellungen der Anwendung")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HelpButton(urlString: "https://github.com/jpdeuster/DailyWebScanner#readme")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // General Settings Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allgemein")
                                .font(.headline)
                            Text("Darstellung und Verhaltensoptionen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Appearance Mode:")
                                .fontWeight(.medium)
                            Spacer()
                            Picker("", selection: $appearanceMode) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                            .onChange(of: appearanceMode) { _, newValue in
                                applyAppearanceMode(newValue)
                            }
                        }
                        
                        Toggle(isOn: $openArticlesOnLaunch) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Open Articles on Launch")
                                    .fontWeight(.medium)
                                Text("Artikel-Fenster nach dem Start automatisch öffnen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $acceptAllCookies) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Accept All Cookies (Best‑Effort)")
                                    .fontWeight(.medium)
                                Text("Generische Consent-Cookies senden und Cookie-Banner verstecken")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // App Info Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.purple)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Information")
                                .font(.headline)
                            Text("Version, Build, Entwickler")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
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
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // Reset Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset")
                                .font(.headline)
                            Text("Einstellungen auf Standard zurücksetzen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Alle Einstellungen zurücksetzen") {
                            resetAllSettings()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .help("Setzt alle Einstellungen auf Standardwerte zurück")
                        
                        Text("Diese Aktion kann nicht rückgängig gemacht werden.")
                            .font(.caption)
                            .foregroundColor(.orange)
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
    }
    
    private func resetAllSettings() {
        appearanceMode = "system"
        openArticlesOnLaunch = true
        acceptAllCookies = true
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
