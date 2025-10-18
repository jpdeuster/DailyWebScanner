import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Minimale Konfiguration für Stabilität
        config.allowsAirPlayForMediaPlayback = false
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.suppressesIncrementalRendering = true
        
        // JavaScript-Konfiguration
        let userController = WKUserContentController()
        config.userContentController = userController
        
        // Preferences für bessere Performance
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false // Deaktiviere JS für Stabilität
        config.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // transparent background
        
        // Navigation-Delegates für bessere Fehlerbehandlung
        webView.navigationDelegate = context.coordinator
        
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Nur laden, wenn HTML sich geändert hat
        if webView.url == nil || !html.isEmpty {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView loaded successfully")
        }
    }
}
