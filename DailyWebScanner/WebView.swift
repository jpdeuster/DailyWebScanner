import SwiftUI
import WebKit
import AppKit

struct WebView: NSViewRepresentable {
    let html: String
    let allowExternalLinks: Bool

    init(html: String, allowExternalLinks: Bool = true) {
        self.html = html
        self.allowExternalLinks = allowExternalLinks
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(allowExternalLinks: allowExternalLinks)
    }

    func makeNSView(context: Context) -> WKWebView {
        DebugLogger.shared.logWebKitStart()

        let config = WKWebViewConfiguration()
        // JavaScript standardmäßig an; bei Bedarf deaktivieren:
        // config.preferences.javaScriptEnabled = false

        // App-Bound-Domains nicht einschränken (Standard); hier nur explizit gesetzt
        config.limitsNavigationsToAppBoundDomains = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Gesten explizit deaktivieren (Default ist false, zur Klarheit)
        webView.allowsBackForwardNavigationGestures = false

        // Transparenter Hintergrund (macOS)
        // Variante 1 (bewährt): KVC -> zeichnet keinen Hintergrund
        webView.setValue(false, forKey: "drawsBackground")
        // Variante 2 (ergänzend): Layer-Hintergrund transparent
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.clear.cgColor

        // Erstinitialisierung laden
        context.coordinator.currentHTMLHash = html.hashValue

        // BaseURL setzen, falls spätere relative Ressourcen dazukommen (hier: nil -> about:blank)
        webView.loadHTMLString(html, baseURL: nil)

        DebugLogger.shared.logWebViewAction("WKWebView created and initial HTML loaded")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let newHash = html.hashValue
        if context.coordinator.currentHTMLHash != newHash {
            context.coordinator.currentHTMLHash = newHash
            DebugLogger.shared.logWebViewAction("WKWebView reloading updated HTML, length: \(html.count)")
            webView.loadHTMLString(html, baseURL: nil)
        } else {
            DebugLogger.shared.logWebViewAction("WKWebView update skipped (HTML unchanged)")
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var currentHTMLHash: Int?
        let allowExternalLinks: Bool

        init(allowExternalLinks: Bool = true) {
            self.allowExternalLinks = allowExternalLinks
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // about:blank oder interne Anker erlauben
            if url.scheme == "about" {
                decisionHandler(.allow)
                return
            }

            // Je nach Konfiguration externe Links behandeln
            if allowExternalLinks {
                // Externe http/https-Links im Standardbrowser öffnen
                if let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                    DebugLogger.shared.logWebViewAction("Opening external link in default browser: \(url.absoluteString)")
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            } else {
                // Alle externen Links blockieren (für HTML-Vorschau)
                DebugLogger.shared.logWebViewAction("Blocking external navigation: \(url.absoluteString)")
                decisionHandler(.cancel)
                return
            }

            // data:, file: etc. können je nach Bedarf restriktiver behandelt werden
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DebugLogger.shared.logWebKitNavigationStart(url: webView.url?.absoluteString ?? "(inline HTML)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DebugLogger.shared.logWebKitNavigationComplete(url: webView.url?.absoluteString ?? "(inline HTML)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DebugLogger.shared.logWebKitNavigationError(url: webView.url?.absoluteString ?? "(inline HTML)", error: error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DebugLogger.shared.logWebKitNavigationError(url: webView.url?.absoluteString ?? "(inline HTML)", error: error)
        }
    }
}
