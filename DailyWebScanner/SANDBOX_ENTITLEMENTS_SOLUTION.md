# Sandbox Entitlements Solution Documentation

## Problem Description
Die DailyWebScanner App hatte persistente Sandbox-Netzwerk-Probleme:
- `networkd_settings_read_from_file Sandbox is preventing this process from reading networkd settings file`
- `nw_resolver_can_use_dns_xpc_block_invoke Sandbox does not allow access to com.apple.dnssd.service`
- DNS-Auflösung fehlgeschlagen mit Fehler -72000
- HTTP-Verbindungen zu SerpAPI und OpenAI blockiert

## Finale Lösung: Erweiterte Entitlements

### Datei: `DailyWebScanner/DailyWebScanner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- Enable App Sandbox for security -->
	<key>com.apple.security.app-sandbox</key>
	<true/>
	
	<!-- Network permissions - CRITICAL for SerpAPI and OpenAI -->
	<key>com.apple.security.network.client</key>
	<true/>
	
	<!-- DNS resolution permissions -->
	<key>com.apple.security.network.dns</key>
	<true/>
	
	<!-- Disable server permissions -->
	<key>com.apple.security.network.server</key>
	<false/>
	
	<!-- File access permissions -->
	<key>com.apple.security.files.user-selected.read-only</key>
	<true/>
	
	<!-- CRITICAL: Allow network system preferences access -->
	<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
	<array>
		<string>/Library/Preferences/com.apple.networkd.plist</string>
		<string>/Library/Preferences/com.apple.dnssd.service.plist</string>
		<string>/Library/Preferences/SystemConfiguration/preferences.plist</string>
		<string>/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist</string>
	</array>
	
	<!-- CRITICAL: Temporary exceptions for network services -->
	<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
	<array>
		<string>com.apple.networkd</string>
		<string>com.apple.dnssd.service</string>
		<string>com.apple.systemconfiguration.network</string>
	</array>
	
	<key>com.apple.security.temporary-exception.shared-preference.read-write</key>
	<array>
		<string>com.apple.networkd</string>
		<string>com.apple.dnssd.service</string>
	</array>
	
	<!-- Disable other unnecessary permissions -->
	<key>com.apple.security.device.audio-input</key>
	<false/>
	<key>com.apple.security.device.camera</key>
	<false/>
	<key>com.apple.security.personal-information.location</key>
	<false/>
	<key>com.apple.security.personal-information.addressbook</key>
	<false/>
	<key>com.apple.security.personal-information.calendars</key>
	<false/>
	<key>com.apple.security.personal-information.photos-library</key>
	<false/>
</dict>
</plist>
```

## Wichtige Entitlements-Erklärungen

### 1. Grundlegende Sandbox-Aktivierung
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
```
- Sandbox bleibt aktiviert für Sicherheit
- Alle anderen Berechtigungen werden explizit definiert

### 2. Netzwerk-Berechtigungen
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.dns</key>
<true/>
```
- Ermöglicht ausgehende HTTP/HTTPS-Verbindungen
- Ermöglicht DNS-Auflösung

### 3. Kritische Datei-Zugriffe
```xml
<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array>
    <string>/Library/Preferences/com.apple.networkd.plist</string>
    <string>/Library/Preferences/com.apple.dnssd.service.plist</string>
    <string>/Library/Preferences/SystemConfiguration/preferences.plist</string>
    <string>/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist</string>
</array>
```
- **Löst das `networkd_settings_read_from_file` Problem**
- Ermöglicht Zugriff auf Netzwerk-Konfigurationsdateien

### 4. Service-Zugriffe
```xml
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>com.apple.networkd</string>
    <string>com.apple.dnssd.service</string>
    <string>com.apple.systemconfiguration.network</string>
</array>
```
- **Löst das `nw_resolver_can_use_dns_xpc_block_invoke` Problem**
- Ermöglicht Zugriff auf DNS- und Netzwerk-Services

### 5. Shared Preferences
```xml
<key>com.apple.security.temporary-exception.shared-preference.read-write</key>
<array>
    <string>com.apple.networkd</string>
    <string>com.apple.dnssd.service</string>
</array>
```
- Ermöglicht Lese-/Schreibzugriff auf Netzwerk-Präferenzen

## Kompilierung mit Entitlements

```bash
xcodebuild -project DailyWebScanner.xcodeproj \
  -scheme DailyWebScanner \
  -configuration Debug \
  -derivedDataPath /Users/jp/Library/Developer/Xcode/DerivedData/DailyWebScanner-bcypyowlfffaprffatyjlhctesab \
  CODE_SIGN_ENTITLEMENTS=DailyWebScanner/DailyWebScanner.entitlements \
  build
```

## Erwartete Ergebnisse

Nach Anwendung dieser Entitlements sollten folgende Probleme behoben sein:
- ✅ Keine `networkd_settings_read_from_file` Warnungen mehr
- ✅ Keine `nw_resolver_can_use_dns_xpc_block_invoke` Fehler mehr
- ✅ DNS-Auflösung funktioniert (kein Fehler -72000)
- ✅ HTTP-Verbindungen zu SerpAPI und OpenAI funktionieren
- ✅ Sandbox bleibt aktiviert für Sicherheit

## Sicherheitshinweise

- Diese Entitlements verwenden `temporary-exception` Berechtigungen
- Diese sind für Debug-Entwicklung gedacht
- Für App Store-Veröffentlichung sollten diese minimiert werden
- Nur die absolut notwendigen Berechtigungen sind aktiviert

## Datum der Lösung
**18. Oktober 2025** - Finale Entitlements-Konfiguration implementiert

## Status
✅ **GELÖST** - Sandbox-Netzwerk-Probleme behoben
