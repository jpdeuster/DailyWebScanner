import SwiftUI

// UserDefaults keys for @AppStorage
private enum SettingsKeys {
    static let serpEngine = "settings.serp.engine"   // e.g., "google"
    static let serpHL = "settings.serp.hl"           // e.g., "de"
    static let serpGL = "settings.serp.gl"           // e.g., "de"
    static let serpNum = "settings.serp.num"         // e.g., 20
    static let serpLocation = "settings.serp.location" // e.g., "Germany"
    static let serpSafe = "settings.serp.safe"       // e.g., "active"
    static let serpTbm = "settings.serp.tbm"         // e.g., "isch" for images
    static let serpTbs = "settings.serp.tbs"         // e.g., "qdr:d" for past day
    static let serpAsQdr = "settings.serp.as_qdr"    // e.g., "d" for past day
    static let frequency = "settings.frequency"      // "manual", "daily", "weekly"
}

struct SettingsView: View {
    // Keychain-backed fields (loaded on appear)
    @State private var serpKey: String = ""
    @State private var openAIKey: String = ""

    // UserDefaults-backed parameters
    @AppStorage(SettingsKeys.serpEngine) private var serpEngine: String = "google"
    @AppStorage(SettingsKeys.serpHL) private var serpHL: String = "de"
    @AppStorage(SettingsKeys.serpGL) private var serpGL: String = "de"
    @AppStorage(SettingsKeys.serpNum) private var serpNum: Int = 20
    @AppStorage(SettingsKeys.serpLocation) private var serpLocation: String = ""
    @AppStorage(SettingsKeys.serpSafe) private var serpSafe: String = ""
    @AppStorage(SettingsKeys.serpTbm) private var serpTbm: String = ""
    @AppStorage(SettingsKeys.serpTbs) private var serpTbs: String = ""
    @AppStorage(SettingsKeys.serpAsQdr) private var serpAsQdr: String = ""
    @AppStorage(SettingsKeys.frequency) private var frequencyRaw: String = Frequency.manual.rawValue

    @State private var didSave: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult?

    enum TestResult: Equatable {
        case success(String)
        case failure(String)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title bar
                HStack {
                    Text("Einstellungen")
                        .font(.title2.weight(.semibold))
                    Spacer()
                    if didSave {
                        Label("Gespeichert", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                Divider()

                // Content
                VStack(alignment: .leading, spacing: 32) {
                    // API Keys Section
                    SettingsSection(title: "API-Schlüssel", icon: "key.fill") {
                        VStack(spacing: 20) {
                            // SerpAPI Key
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SerpAPI Key")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                SecureField("SerpAPI Key eingeben", text: $serpKey)
                                    .textFieldStyle(.roundedBorder)
                                    .help("Deinen SerpAPI Schlüssel findest du unter 'Manage API Key'.")
                                
                                HStack(spacing: 16) {
                                    Link("SerpAPI – Manage API Key", destination: URL(string: "https://serpapi.com/manage-api-key")!)
                                        .font(.callout)
                                        .foregroundColor(.blue)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Link("Playground", destination: URL(string: "https://serpapi.com/playground")!)
                                        .font(.callout)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // OpenAI Key
                            VStack(alignment: .leading, spacing: 8) {
                                Text("OpenAI Key (optional)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                SecureField("OpenAI Key eingeben (optional)", text: $openAIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .help("Deinen OpenAI Schlüssel findest du im OpenAI Dashboard. Ohne Key werden Original-Snippets verwendet.")
                                
                                Link("OpenAI – API Keys", destination: URL(string: "https://platform.openai.com/api-keys")!)
                                    .font(.callout)
                                    .foregroundColor(.blue)
                            }
                            
                            // Status Messages
                            if serpKey.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text("SerpAPI Key ist erforderlich für die Suche.")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.callout)
                            } else if openAIKey.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("OpenAI Key ist optional. Ohne Key werden Original-Snippets verwendet.")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.callout)
                            }
                        }
                    }

                    // SerpAPI Parameters
                    SettingsSection(title: "Suchparameter", icon: "magnifyingglass") {
                        VStack(spacing: 20) {
                            // Basic Parameters
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Grundlegende Einstellungen")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Engine")
                                            .font(.headline)
                                        TextField("z. B. google", text: $serpEngine)
                                            .textFieldStyle(.roundedBorder)
                                            .help("Standard: google")
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Sprache (hl)")
                                            .font(.headline)
                                        TextField("z. B. de", text: $serpHL)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Land (gl)")
                                            .font(.headline)
                                        TextField("z. B. de", text: $serpGL)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Anzahl Ergebnisse")
                                            .font(.headline)
                                        HStack {
                                            Stepper(value: $serpNum, in: 1...50) {
                                                Text("\(serpNum)")
                                            }
                                            .help("Top N Ergebnisse abrufen (1–50)")
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            
                            Divider()
                            
                            // Advanced Parameters
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Erweiterte Einstellungen")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Standort")
                                            .font(.headline)
                                        TextField("z. B. Germany, Berlin", text: $serpLocation)
                                            .textFieldStyle(.roundedBorder)
                                            .help("Geografische Einschränkung der Suche")
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Safe Search")
                                            .font(.headline)
                                        Picker("Safe Search", selection: $serpSafe) {
                                            Text("Aus").tag("")
                                            Text("Aktiv").tag("active")
                                            Text("Moderat").tag("moderate")
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Zeitraum")
                                                .font(.headline)
                                            Picker("Zeitraum", selection: $serpAsQdr) {
                                                Text("Alle Zeit").tag("")
                                                Text("Letzter Tag").tag("d")
                                                Text("Letzte Woche").tag("w")
                                                Text("Letzter Monat").tag("m")
                                                Text("Letztes Jahr").tag("y")
                                            }
                                            .pickerStyle(.menu)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Suchtyp")
                                                .font(.headline)
                                            Picker("Suchtyp", selection: $serpTbm) {
                                                Text("Web").tag("")
                                                Text("Bilder").tag("isch")
                                                Text("News").tag("nws")
                                                Text("Videos").tag("vid")
                                            }
                                            .pickerStyle(.menu)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Automation
                    SettingsSection(title: "Automatisierung", icon: "clock.fill") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Suchhäufigkeit")
                                .font(.headline)
                            Picker("Häufigkeit", selection: $frequencyRaw) {
                                Text("Manuell").tag(Frequency.manual.rawValue)
                                Text("Täglich").tag(Frequency.daily.rawValue)
                                Text("Wöchentlich").tag(Frequency.weekly.rawValue)
                            }
                            .pickerStyle(.segmented)
                            .help("Wie oft soll automatisch gesucht werden?")
                        }
                    }

                    // Test Section
                    SettingsSection(title: "API-Test", icon: "checkmark.circle.fill") {
                        VStack(alignment: .leading, spacing: 16) {
                            Button("API testen") {
                                Task { await testAPIs() }
                            }
                            .disabled(isTesting || serpKey.isEmpty)
                            .buttonStyle(.borderedProminent)
                            
                            if let result = testResult {
                                HStack(spacing: 8) {
                                    Image(systemName: result == .success("") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(result == .success("") ? .green : .red)
                                    Text(result == .success("") ? "Test erfolgreich" : "Test fehlgeschlagen")
                                        .foregroundStyle(result == .success("") ? .green : .red)
                                }
                                .font(.callout)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            loadKeysFromKeychain()
        }
    }
    
    // MARK: - Helper Views
    
    struct SettingsSection<Content: View>: View {
        let title: String
        let icon: String
        let content: Content
        
        init(title: String, icon: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.icon = icon
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .font(.title3)
                    Text(title)
                        .font(.title3.weight(.semibold))
                }
                
                content
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadKeysFromKeychain() {
        serpKey = KeychainHelper.get(.serpAPIKey) ?? ""
        openAIKey = KeychainHelper.get(.openAIAPIKey) ?? ""
    }
    
    private func saveKeysToKeychain() {
        _ = KeychainHelper.set(serpKey, for: .serpAPIKey)
        _ = KeychainHelper.set(openAIKey, for: .openAIAPIKey)
    }
    
    private func testAPIs() async {
        isTesting = true
        defer { isTesting = false }
        guard !serpKey.isEmpty else {
            withAnimation {
                testResult = .failure("SerpAPI Key ist erforderlich.")
            }
            return
        }

        do {
            let serpOK = try await quickHead(url: URL(string: "https://serpapi.com")!)
            
            if openAIKey.isEmpty {
                if serpOK {
                    withAnimation { testResult = .success("SerpAPI connection successful. OpenAI Key optional.") }
                } else {
                    withAnimation { testResult = .failure("SerpAPI test failed.") }
                }
            } else {
                let openAIOK = try await quickAuthGET(url: URL(string: "https://api.openai.com/v1/models")!, bearer: openAIKey)
                
                if serpOK && openAIOK {
                    withAnimation { testResult = .success("Both API connections successful.") }
                } else if serpOK {
                    withAnimation { testResult = .success("SerpAPI OK. OpenAI problem - using original snippets.") }
                } else {
                    withAnimation { testResult = .failure("SerpAPI test failed.") }
                }
            }
        } catch {
            withAnimation { testResult = .failure("Fehler: \(error.localizedDescription)") }
        }
    }
    
    private func quickHead(url: URL) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
    
    private func quickAuthGET(url: URL, bearer: String) async throws -> Bool {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
}

// MARK: - Supporting Types

enum Frequency: String, CaseIterable {
    case manual = "manual"
    case daily = "daily"
    case weekly = "weekly"
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .frame(width: 600, height: 800)
    }
}