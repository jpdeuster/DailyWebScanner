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
    
    // Search Parameters
    @AppStorage("settings.serp.hl") private var serpLanguage: String = "" // Default: Any
    @AppStorage("settings.serp.gl") private var serpRegion: String = ""
    @AppStorage("settings.serp.num") private var serpCount: Int = 20
    @AppStorage("settings.serp.location") private var serpLocation: String = ""
    @AppStorage("settings.serp.safe") private var serpSafe: String = ""
    @AppStorage("settings.serp.tbm") private var serpTbm: String = ""
    @AppStorage("settings.serp.tbs") private var serpTbs: String = ""
    @AppStorage("settings.serp.as_qdr") private var serpAsQdr: String = ""
    
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
                            statusPill(text: getOpenAIStatusText(), color: getOpenAIStatusColor())
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
                                if openAIKey.isEmpty {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("OpenAI: Not configured (optional)")
                                        .font(.caption)
                                } else if openAIResult.contains("✅") {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("OpenAI: Configured")
                                        .font(.caption)
                                } else if !openAIResult.isEmpty && openAIResult.contains("❌") {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("OpenAI: Invalid key")
                                        .font(.caption)
                                } else {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("OpenAI: Not tested")
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(10)
                    
                    // Search Parameters
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear.circle.fill")
                                .foregroundColor(.orange)
                            Text("Search Parameters")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 16) {
                            // Basic Settings
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Basic Settings")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Language:")
                                                .fontWeight(.medium)
                                            Text("Interface language for search results")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpLanguage) {
                                            Text("Any").tag("")
                                            Text("Deutsch (de)").tag("de")
                                            Text("English (en)").tag("en")
                                            Text("Français (fr)").tag("fr")
                                            Text("Español (es)").tag("es")
                                            Text("Italiano (it)").tag("it")
                                            Text("Português (pt)").tag("pt")
                                            Text("Nederlands (nl)").tag("nl")
                                            Text("Русский (ru)").tag("ru")
                                            Text("中文 (zh)").tag("zh")
                                            Text("日本語 (ja)").tag("ja")
                                            Text("한국어 (ko)").tag("ko")
                                            Text("العربية (ar)").tag("ar")
                                            Text("हिन्दी (hi)").tag("hi")
                                            Text("Svenska (sv)").tag("sv")
                                            Text("Norsk (no)").tag("no")
                                            Text("Dansk (da)").tag("da")
                                            Text("Suomi (fi)").tag("fi")
                                            Text("Polski (pl)").tag("pl")
                                            Text("Čeština (cs)").tag("cs")
                                            Text("Magyar (hu)").tag("hu")
                                            Text("Română (ro)").tag("ro")
                                            Text("Български (bg)").tag("bg")
                                            Text("Hrvatski (hr)").tag("hr")
                                            Text("Slovenčina (sk)").tag("sk")
                                            Text("Slovenščina (sl)").tag("sl")
                                            Text("Ελληνικά (el)").tag("el")
                                            Text("Türkçe (tr)").tag("tr")
                                            Text("עברית (he)").tag("he")
                                            Text("ไทย (th)").tag("th")
                                            Text("Tiếng Việt (vi)").tag("vi")
                                            Text("Bahasa Indonesia (id)").tag("id")
                                            Text("Bahasa Malaysia (ms)").tag("ms")
                                            Text("Filipino (tl)").tag("tl")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Region:")
                                                .fontWeight(.medium)
                                            Text("Geographic region for search")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpRegion) {
                                            Text("Any").tag("")
                                            Text("Deutschland (de)").tag("de")
                                            Text("United States (us)").tag("us")
                                            Text("United Kingdom (uk)").tag("uk")
                                            Text("France (fr)").tag("fr")
                                            Text("Spain (es)").tag("es")
                                            Text("Italy (it)").tag("it")
                                            Text("Canada (ca)").tag("ca")
                                            Text("Australia (au)").tag("au")
                                            Text("Austria (at)").tag("at")
                                            Text("Switzerland (ch)").tag("ch")
                                            Text("Netherlands (nl)").tag("nl")
                                            Text("Belgium (be)").tag("be")
                                            Text("Sweden (se)").tag("se")
                                            Text("Norway (no)").tag("no")
                                            Text("Denmark (dk)").tag("dk")
                                            Text("Finland (fi)").tag("fi")
                                            Text("Poland (pl)").tag("pl")
                                            Text("Czech Republic (cz)").tag("cz")
                                            Text("Hungary (hu)").tag("hu")
                                            Text("Romania (ro)").tag("ro")
                                            Text("Bulgaria (bg)").tag("bg")
                                            Text("Croatia (hr)").tag("hr")
                                            Text("Slovakia (sk)").tag("sk")
                                            Text("Slovenia (si)").tag("si")
                                            Text("Greece (gr)").tag("gr")
                                            Text("Turkey (tr)").tag("tr")
                                            Text("Russia (ru)").tag("ru")
                                            Text("Ukraine (ua)").tag("ua")
                                            Text("Japan (jp)").tag("jp")
                                            Text("China (cn)").tag("cn")
                                            Text("South Korea (kr)").tag("kr")
                                            Text("India (in)").tag("in")
                                            Text("Brazil (br)").tag("br")
                                            Text("Mexico (mx)").tag("mx")
                                            Text("Argentina (ar)").tag("ar")
                                            Text("Chile (cl)").tag("cl")
                                            Text("Colombia (co)").tag("co")
                                            Text("Peru (pe)").tag("pe")
                                            Text("Venezuela (ve)").tag("ve")
                                            Text("South Africa (za)").tag("za")
                                            Text("Egypt (eg)").tag("eg")
                                            Text("Israel (il)").tag("il")
                                            Text("Saudi Arabia (sa)").tag("sa")
                                            Text("UAE (ae)").tag("ae")
                                            Text("Thailand (th)").tag("th")
                                            Text("Vietnam (vn)").tag("vn")
                                            Text("Indonesia (id)").tag("id")
                                            Text("Malaysia (my)").tag("my")
                                            Text("Philippines (ph)").tag("ph")
                                            Text("Singapore (sg)").tag("sg")
                                            Text("New Zealand (nz)").tag("nz")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Number of Results:")
                                                .fontWeight(.medium)
                                            Text("Maximum results per search")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpCount) {
                                            Text("10").tag(10)
                                            Text("20").tag(20)
                                            Text("30").tag(30)
                                            Text("50").tag(50)
                                            Text("100").tag(100)
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 120, alignment: .trailing)
                                    }
                                }
                            }
                            
                            // Advanced Settings
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Advanced Settings")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Location:")
                                                .fontWeight(.medium)
                                            Text("Geographic location for search results")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpLocation) {
                                            Text("Any").tag("")
                                            Text("Germany").tag("Germany")
                                            Text("United States").tag("United States")
                                            Text("United Kingdom").tag("United Kingdom")
                                            Text("France").tag("France")
                                            Text("Spain").tag("Spain")
                                            Text("Italy").tag("Italy")
                                            Text("Canada").tag("Canada")
                                            Text("Australia").tag("Australia")
                                            Text("Japan").tag("Japan")
                                            Text("China").tag("China")
                                            Text("India").tag("India")
                                            Text("Brazil").tag("Brazil")
                                            Text("Mexico").tag("Mexico")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Safe Search:")
                                                .fontWeight(.medium)
                                            Text("Filter out adult content")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpSafe) {
                                            Text("Any").tag("")
                                            Text("Off").tag("off")
                                            Text("Active").tag("active")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Time Range:")
                                                .fontWeight(.medium)
                                            Text("Filter results by publication date")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpAsQdr) {
                                            Text("Any Time").tag("")
                                            Text("Past 24h").tag("d")
                                            Text("Past Week").tag("w")
                                            Text("Past Month").tag("m")
                                            Text("Past Year").tag("y")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Search Type:")
                                                .fontWeight(.medium)
                                            Text("Type of content to search for")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: $serpTbm) {
                                            Text("All").tag("")
                                            Text("Images").tag("isch")
                                            Text("Videos").tag("vid")
                                            Text("News").tag("nws")
                                            Text("Books").tag("bks")
                                            Text("Shopping").tag("shop")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.07))
                    .cornerRadius(10)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .frame(minWidth: 700, minHeight: 600)
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
    
    // MARK: - Helper Functions
    
    private func getOpenAIStatusText() -> String {
        if openAIKey.isEmpty {
            return "Optional"
        } else if openAIResult.contains("✅") {
            return "Configured"
        } else if !openAIResult.isEmpty && openAIResult.contains("❌") {
            return "Invalid"
        } else {
            return "Not tested"
        }
    }
    
    private func getOpenAIStatusColor() -> Color {
        if openAIKey.isEmpty {
            return .gray
        } else if openAIResult.contains("✅") {
            return .green
        } else if !openAIResult.isEmpty && openAIResult.contains("❌") {
            return .red
        } else {
            return .orange
        }
    }
}

#Preview {
    APISettingsView()
}
