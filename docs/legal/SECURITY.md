# Sicherheitsrichtlinien

## Melden von Sicherheitslücken

Wenn Sie eine Sicherheitslücke in diesem Projekt entdecken, melden Sie diese bitte **NICHT** öffentlich über GitHub Issues.

Stattdessen kontaktieren Sie uns direkt unter: [Ihre E-Mail-Adresse]

## Sicherheitsmaßnahmen

### API-Keys und sensible Daten
- ✅ **Keine hardcodierten API-Keys** im Quellcode
- ✅ **Keychain-Integration** für sichere Speicherung von API-Keys
- ✅ **Sandbox-Berechtigungen** für minimale Systemzugriffe
- ✅ **Entitlements-Datei** für kontrollierte Berechtigungen

### Datenschutz
- 🔒 **Lokale Speicherung**: Alle Daten werden lokal im Keychain gespeichert
- 🔒 **Keine Cloud-Synchronisation**: Keine Daten werden an externe Server gesendet
- 🔒 **Sandbox-Isolation**: App läuft in isolierter Umgebung

### Netzwerk-Sicherheit
- 🔐 **HTTPS-only**: Alle API-Aufrufe verwenden verschlüsselte Verbindungen
- 🔐 **API-Key-Masking**: Keys werden nicht in Logs oder URLs angezeigt
- 🔐 **Minimale Berechtigungen**: Nur notwendige Netzwerk-Berechtigungen

## Verantwortlichkeitsbereich

Dieses Projekt ist für die Sicherheit der folgenden Komponenten verantwortlich:

- ✅ **App-Code**: SwiftUI-Anwendung
- ✅ **API-Integration**: SerpAPI und OpenAI
- ✅ **Datenpersistierung**: SwiftData und Keychain
- ✅ **Netzwerk-Kommunikation**: URLSession

## Nicht im Verantwortungsbereich

- ❌ **Externe APIs**: SerpAPI, OpenAI
- ❌ **Betriebssystem**: macOS Sandbox
- ❌ **Drittanbieter-Services**: GitHub, etc.

## Best Practices für Entwickler

1. **Niemals API-Keys committen**
2. **Verwenden Sie Umgebungsvariablen für Tests**
3. **Regelmäßige Sicherheitsupdates**
4. **Code-Reviews für sicherheitskritische Änderungen**

## Bekannte Sicherheitsüberlegungen

- **Sandbox-Einschränkungen**: App kann nur auf explizit erlaubte Ressourcen zugreifen
- **Keychain-Zugriff**: Nur die App selbst kann auf gespeicherte Keys zugreifen
- **Netzwerk-Isolation**: Keine lokalen Netzwerk-Services

---

**Letzte Aktualisierung**: Oktober 2024
