# DailyWebScanner

Eine moderne macOS-App für tägliche Websuchen mit optionaler KI-Unterstützung.

## Features

- 🔍 **Web-Suche**: Nutzt SerpAPI für Google-Suchergebnisse
- 🤖 **KI-Zusammenfassungen**: Optional OpenAI-Integration für intelligente Zusammenfassungen
- 📱 **Native macOS-App**: Entwickelt mit SwiftUI für macOS
- 🔒 **Sicherheit**: Sandbox-kompatibel mit sicherem Keychain-Speicher
- 📊 **Suchhistorie**: Speichert und zeigt vergangene Suchen
- 🎨 **Moderne UI**: Responsive Design mit HTML-Rendering

## Installation

1. Klonen Sie das Repository:
```bash
git clone https://github.com/jpdeuster/DailyWebScanner.git
cd DailyWebScanner
```

2. Öffnen Sie das Projekt in Xcode:
```bash
open DailyWebScanner.xcodeproj
```

3. Builden und ausführen (⌘+R)

## Konfiguration

### SerpAPI (Erforderlich)
1. Registrieren Sie sich bei [SerpAPI](https://serpapi.com)
2. Kopieren Sie Ihren API-Key
3. Fügen Sie ihn in den App-Einstellungen ein

### OpenAI (Optional)
1. Registrieren Sie sich bei [OpenAI](https://platform.openai.com)
2. Erstellen Sie einen API-Key
3. Fügen Sie ihn in den App-Einstellungen ein

**Hinweis**: Ohne OpenAI-Key werden die Original-Snippets der Suchergebnisse verwendet.

## Verwendung

1. **Suche starten**: Geben Sie einen Suchbegriff ein und drücken Sie Enter
2. **Ergebnisse anzeigen**: Die App zeigt Suchergebnisse mit Zusammenfassungen an
3. **Historie durchsuchen**: Vergangene Suchen werden automatisch gespeichert
4. **Einstellungen**: Konfigurieren Sie API-Keys und Suchparameter

## Technische Details

- **Framework**: SwiftUI, SwiftData
- **APIs**: SerpAPI, OpenAI
- **Sicherheit**: macOS App Sandbox, Keychain
- **Mindestanforderung**: macOS 14.0+

## Projektstruktur

```
DailyWebScanner/
├── DailyWebScannerApp.swift      # App-Entry-Point
├── ContentView.swift             # Haupt-UI
├── SearchViewModel.swift         # Suchlogik
├── SerpAPIClient.swift           # SerpAPI-Integration
├── OpenAIClient.swift            # OpenAI-Integration
├── HTMLRenderer.swift             # HTML-Darstellung
├── WebView.swift                 # WebKit-Integration
├── SettingsView.swift            # Einstellungen
├── KeychainHelper.swift          # Sichere Speicherung
├── SearchRecord.swift            # Datenmodell
├── SearchResult.swift            # Ergebnis-Modell
└── DailyWebScanner.entitlements  # Sandbox-Berechtigungen
```

## Entwicklung

### Build
```bash
xcodebuild -project DailyWebScanner.xcodeproj -scheme DailyWebScanner -configuration Debug build
```

### Tests
Die App wurde mit folgenden Konfigurationen getestet:
- ✅ Mit SerpAPI + OpenAI
- ✅ Mit SerpAPI ohne OpenAI
- ✅ Sandbox-Modus
- ✅ Netzwerk-Zugriff

## Lizenz

MIT License - siehe [LICENSE](LICENSE) für Details.

## Beitragen

1. Fork des Repositories
2. Feature-Branch erstellen (`git checkout -b feature/AmazingFeature`)
3. Änderungen committen (`git commit -m 'Add some AmazingFeature'`)
4. Branch pushen (`git push origin feature/AmazingFeature`)
5. Pull Request erstellen

## Support

Bei Fragen oder Problemen erstellen Sie bitte ein [Issue](https://github.com/jpdeuster/DailyWebScanner/issues).

---

Entwickelt mit ❤️ für macOS
