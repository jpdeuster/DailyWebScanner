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
        // JavaScript enabled by default; disable here if needed
        // config.preferences.javaScriptEnabled = false

        // Do not restrict to app-bound domains (default); explicitly set here
        config.limitsNavigationsToAppBoundDomains = false

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Explicitly disable back/forward gestures (default is false; keep explicit)
        webView.allowsBackForwardNavigationGestures = false

        // Transparent background (macOS)
        // Option 1: KVC disables background drawing
        webView.setValue(false, forKey: "drawsBackground")
        // Option 2: transparent layer background
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.clear.cgColor

        // Initial load
        context.coordinator.currentHTMLHash = html.hashValue

        // Set baseURL in case of relative resources later (nil -> about:blank)
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

            // Allow about:blank or internal anchors
            if url.scheme == "about" {
                decisionHandler(.allow)
                return
            }

            // Handle external links per configuration
            if allowExternalLinks {
                // Open external http/https links in default browser
                if let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                    DebugLogger.shared.logWebViewAction("Opening external link in default browser: \(url.absoluteString)")
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            } else {
                // Block all external links (for HTML preview)
                DebugLogger.shared.logWebViewAction("Blocking external navigation: \(url.absoluteString)")
                decisionHandler(.cancel)
                return
            }

            // data:, file:, etc. can be handled more strictly if needed
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
