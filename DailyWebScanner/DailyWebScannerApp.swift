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

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Wenn das letzte Fenster geschlossen wurde, App beenden
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hauptfenster nach dem Start zentrieren
        if let window = NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first {
            window.center()
        } else {
            // Falls das Fenster minimal verzögert erstellt wird, noch einmal asynchron probieren.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first {
                    window.center()
                }
            }
        }
    }
}

@main
struct DailyWebScannerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
        }

        Settings {
            SettingsView()
                .frame(minWidth: 560, idealWidth: 640, maxWidth: .infinity,
                       minHeight: 420, idealHeight: 520, maxHeight: .infinity,
                       alignment: .topLeading)
        }
    }
}
