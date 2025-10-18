//
//  DailyWebScannerApp.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI
import SwiftData
import AppKit

// Notifications für Menübefehle
extension Notification.Name {
    static let focusSearchField = Notification.Name("FocusSearchField")
    static let triggerManualSearch = Notification.Name("TriggerManualSearch")
}

// Delegate für Settings-Fenster, damit sie nur das Fenster schließen, nicht die App
class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Fenster schließen, aber App nicht beenden
        return true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // App NICHT beenden, wenn das letzte Fenster geschlossen wurde
        // (Standardverhalten vieler macOS-Apps; verhindert Beenden durch Settings-Fenster)
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Wenn App bereits läuft und erneut gestartet wird, bestehende Instanz in den Vordergrund bringen
        if flag {
            // App hat bereits sichtbare Fenster - nichts tun
            return false
        } else {
            // App hat keine sichtbaren Fenster - Fenster wieder anzeigen
            if let window = NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            return true
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLogger.shared.logAppStart()
        
        // Prüfe, ob bereits eine Instanz läuft
        checkForExistingInstance()
        
        // Hauptfenster nach dem Start zentrieren
        if let window = NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first {
            window.center()
            DebugLogger.shared.logWindowCreation()
        } else {
            // Falls das Fenster minimal verzögert erstellt wird, noch einmal asynchron probieren.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first {
                    window.center()
                    DebugLogger.shared.logWindowCreation()
                }
            }
        }
    }
    
    private func checkForExistingInstance() {
        // Prüfe, ob bereits eine andere Instanz der App läuft
        let runningApps = NSWorkspace.shared.runningApplications
        let currentApp = NSRunningApplication.current
        
        for app in runningApps {
            if app.bundleIdentifier == currentApp.bundleIdentifier && 
               app.processIdentifier != currentApp.processIdentifier {
                // Eine andere Instanz läuft bereits
                print("DailyWebScanner läuft bereits. Beende neue Instanz.")
                
                // Bestehende Instanz in den Vordergrund bringen
                app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                
                // Neue Instanz beenden
                NSApp.terminate(nil)
                return
            }
        }
    }
}

@main
struct DailyWebScannerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    // Speichere die Delegate-Instanzen, damit sie nicht freigegeben werden
    private let apiWindowDelegate = SettingsWindowDelegate()
    private let searchWindowDelegate = SettingsWindowDelegate()
    private let appWindowDelegate = SettingsWindowDelegate()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SearchRecord.self,
            SearchResult.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandMenu("Suche") {
                Button("Suchen…") {
                    NotificationCenter.default.post(name: .focusSearchField, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command]) // ⌘F: Fokus ins Suchfeld

                Button("Neu Suchen…") {
                    NotificationCenter.default.post(name: .triggerManualSearch, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command]) // ⌘R: Suche auslösen
            }
            
            CommandMenu("Settings") {
                Button("API Settings") {
                    showAPISettingsWindow()
                }
                .keyboardShortcut(",", modifiers: [.command, .shift])
                
                Button("Search Parameters") {
                    showSearchSettingsWindow()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("App Settings") {
                    showAppSettingsWindow()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
            }
            
            CommandMenu("Help") {
                Button("About DailyWebScanner") {
                    showAboutWindow()
                }
                
                Divider()
                
                Button("Disclaimer") {
                    showDisclaimerWindow()
                }
                
                Button("Privacy & Responsibility") {
                    showPrivacyWindow()
                }
                
                Button("License") {
                    showLicenseWindow()
                }
            }
            
            // Quit Command hinzufügen
            CommandGroup(replacing: .appInfo) {
                Button("Quit DailyWebScanner") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: [.command]) // ⌘Q: App beenden
            }
        }

        // Settings werden jetzt über separate Menüs geöffnet
    }
    
    // MARK: - Help Menu Functions
    
    private func showAboutWindow() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About DailyWebScanner"
        aboutWindow.center()
        aboutWindow.contentView = NSHostingView(rootView: AboutView())
        aboutWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showDisclaimerWindow() {
        let disclaimerWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        disclaimerWindow.title = "Disclaimer & Legal Notice"
        disclaimerWindow.center()
        disclaimerWindow.contentView = NSHostingView(rootView: DisclaimerView())
        disclaimerWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showPrivacyWindow() {
        let privacyWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        privacyWindow.title = "Privacy & Data Responsibility"
        privacyWindow.center()
        privacyWindow.contentView = NSHostingView(rootView: PrivacyView())
        privacyWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showLicenseWindow() {
        let licenseWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        licenseWindow.title = "MIT License"
        licenseWindow.center()
        licenseWindow.contentView = NSHostingView(rootView: LicenseView())
        licenseWindow.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Settings Menu Functions
    
    private func showAPISettingsWindow() {
        let apiWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        apiWindow.title = "API Settings"
        apiWindow.center()
        apiWindow.contentView = NSHostingView(rootView: APISettingsView())
        
        // Konfiguriere das Fenster so, dass es nur das Fenster schließt, nicht die App
        apiWindow.delegate = apiWindowDelegate
        
        // Wichtig: NICHT freigeben beim Schließen, damit die App nicht beendet wird
        apiWindow.isReleasedWhenClosed = false
        
        apiWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showSearchSettingsWindow() {
        let searchWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        searchWindow.title = "Search Parameters"
        searchWindow.center()
        searchWindow.contentView = NSHostingView(rootView: SearchSettingsView())
        
        // Konfiguriere das Fenster so, dass es nur das Fenster schließt, nicht die App
        searchWindow.delegate = searchWindowDelegate
        
        // Wichtig: NICHT freigeben beim Schließen, damit die App nicht beendet wird
        searchWindow.isReleasedWhenClosed = false
        
        searchWindow.makeKeyAndOrderFront(nil)
    }
    
    private func showAppSettingsWindow() {
        let appWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        appWindow.title = "App Settings"
        appWindow.center()
        appWindow.contentView = NSHostingView(rootView: AppSettingsView())
        
        // Konfiguriere das Fenster so, dass es nur das Fenster schließt, nicht die App
        appWindow.delegate = appWindowDelegate
        
        // Wichtig: NICHT freigeben beim Schließen, damit die App nicht beendet wird
        appWindow.isReleasedWhenClosed = false
        
        appWindow.makeKeyAndOrderFront(nil)
    }
}
