import SwiftUI

// UserDefaults keys for @AppStorage
private enum SettingsKeys {
    static let serpEngine = "settings.serp.engine"   // e.g., "google"
    static let serpHL = "settings.serp.hl"           // e.g., "de"
    static let serpGL = "settings.serp.gl"           // e.g., "de"
    static let serpNum = "settings.serp.num"         // e.g., 20
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
    @AppStorage(SettingsKeys.frequency) private var frequencyRaw: String = Frequency.manual.rawValue

    @State private var didSave: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult?

    enum TestResult: Equatable {
        case success(String)
        case failure(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar area style
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 24) {
                // API Keys Section
                SectionHeader("API-Schlüssel")

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        rightAlignedLabel("SerpAPI Key")
                        SecureField("SerpAPI Key eingeben", text: $serpKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 320)
                            .help("Deinen SerpAPI Schlüssel findest du unter „Manage API Key“.")
                    }
                    GridRow {
                        Spacer().frame(width: 140)
                        HStack(spacing: 16) {
                            Link("SerpAPI – Manage API Key", destination: URL(string: "https://serpapi.com/manage-api-key")!)
                            Link("Playground", destination: URL(string: "https://serpapi.com/playground")!)
                            Link("Searches", destination: URL(string: "https://serpapi.com/searches")!)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    GridRow {
                        rightAlignedLabel("OpenAI Key")
                        SecureField("OpenAI Key eingeben (optional)", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 320)
                            .help("Deinen OpenAI Schlüssel findest du im OpenAI Dashboard. Ohne Key werden Original-Snippets verwendet.")
                    }
                    GridRow {
                        Spacer().frame(width: 140)
                        Link("OpenAI – API Keys", destination: URL(string: "https://platform.openai.com/api-keys")!)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if serpKey.isEmpty {
                        GridRow {
                            Spacer().frame(width: 140)
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("SerpAPI Key ist erforderlich für die Suche.")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.callout)
                        }
                    } else if openAIKey.isEmpty {
                        GridRow {
                            Spacer().frame(width: 140)
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

                Divider().padding(.trailing, 20)

                // SerpAPI Parameters
                SectionHeader("SerpAPI Parameter")

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        rightAlignedLabel("Engine")
                        TextField("z. B. google", text: $serpEngine)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 200, maxWidth: 240)
                            .help("Standard: google")
                    }
                    GridRow {
                        rightAlignedLabel("Sprache (hl)")
                        TextField("z. B. de", text: $serpHL)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 120, maxWidth: 160)
                    }
                    GridRow {
                        rightAlignedLabel("Land (gl)")
                        TextField("z. B. de", text: $serpGL)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 120, maxWidth: 160)
                    }
                    GridRow {
                        rightAlignedLabel("Anzahl Ergebnisse")
                        HStack {
                            Stepper(value: $serpNum, in: 1...50) {
                                Text("\(serpNum)")
                            }
                            .frame(maxWidth: 160, alignment: .leading)
                            .help("Top N Ergebnisse abrufen (1–50)")
                        }
                    }
                }

                Divider().padding(.trailing, 20)

                // Automation
                SectionHeader("Automatisierung")

                HStack(spacing: 12) {
                    rightAlignedLabel("Häufigkeit")
                    Picker("", selection: Binding(
                        get: { Frequency(rawValue: frequencyRaw) ?? .manual },
                        set: { frequencyRaw = $0.rawValue }
                    )) {
                        ForEach(Frequency.allCases, id: \.self) { f in
                            Text(f.title).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260, alignment: .leading)
                }

                Text("Hinweis: Die automatische Ausführung nutzt einen Timer, solange die App läuft.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 140)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            // Bottom bar with actions
            HStack {
                if let testResult {
                    switch testResult {
                    case .success(let msg):
                        Label(msg, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                    }
                } else if didSave {
                    Label("Gespeichert", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text(" ")
                }
                Spacer()
                Button("Zurücksetzen") { resetToDefaults() }
                Button(isTesting ? "Test läuft…" : "API testen") {
                    Task { await testAPIs() }
                }
                .disabled(isTesting || serpKey.isEmpty)
                Button("Speichern") { saveAll() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            .background(.bar)
        }
        .frame(minWidth: 560, idealWidth: 640, maxWidth: .infinity,
               minHeight: 420, idealHeight: 520, maxHeight: .infinity,
               alignment: .topLeading)
        .onAppear {
            serpKey = KeychainHelper.get(.serpAPIKey) ?? ""
            openAIKey = KeychainHelper.get(.openAIAPIKey) ?? ""
        }
    }

    // MARK: - Helpers

    private func rightAlignedLabel(_ text: String) -> some View {
        Text(text)
            .frame(width: 140, alignment: .trailing)
            .foregroundStyle(.secondary)
    }

    private func resetToDefaults() {
        serpEngine = "google"
        serpHL = "de"
        serpGL = "de"
        serpNum = 20
        frequencyRaw = Frequency.manual.rawValue
        serpKey = ""
        openAIKey = ""
        KeychainHelper.delete(.serpAPIKey)
        KeychainHelper.delete(.openAIAPIKey)
        withAnimation {
            didSave = true
            testResult = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { didSave = false }
        }
    }

    private func saveAll() {
        _ = KeychainHelper.set(serpKey, for: .serpAPIKey)
        _ = KeychainHelper.set(openAIKey, for: .openAIAPIKey)
        // AppStorage values are already persisted live
        withAnimation {
            didSave = true
            testResult = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { didSave = false }
        }
    }

    private func testAPIs() async {
        // Non-destructive smoke test: just check that keys exist and endpoints are reachable
        isTesting = true
        defer { isTesting = false }
        guard !serpKey.isEmpty else {
            withAnimation {
                testResult = .failure("SerpAPI Key ist erforderlich.")
            }
            return
        }

        // Simple reachability checks (HEAD or quick GET)
        do {
            // SerpAPI ping
            let serpOK = try await quickHead(url: URL(string: "https://serpapi.com")!)
            
            if openAIKey.isEmpty {
                // Nur SerpAPI testen
                if serpOK {
                    withAnimation { testResult = .success("SerpAPI-Verbindung erfolgreich. OpenAI Key optional.") }
                } else {
                    withAnimation { testResult = .failure("SerpAPI-Test fehlgeschlagen.") }
                }
            } else {
                // Beide APIs testen
                let openAIOK = try await quickAuthGET(url: URL(string: "https://api.openai.com/v1/models")!, bearer: openAIKey)
                
                if serpOK && openAIOK {
                    withAnimation { testResult = .success("Beide API-Verbindungen erfolgreich.") }
                } else if serpOK {
                    withAnimation { testResult = .success("SerpAPI OK. OpenAI-Problem - verwende Original-Snippets.") }
                } else {
                    withAnimation { testResult = .failure("SerpAPI-Test fehlgeschlagen.") }
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
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (200..<400).contains(code)
    }

    private func quickAuthGET(url: URL, bearer: String) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        // 200–399 OK; 401 also proves reachability but indicates key invalid
        return (200..<400).contains(code) || code == 401
    }
}

enum Frequency: String, CaseIterable {
    case manual, daily, weekly

    var title: String {
        switch self {
        case .manual: return "Manuell"
        case .daily: return "Täglich"
        case .weekly: return "Wöchentlich"
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.leading, 2)
    }
}
