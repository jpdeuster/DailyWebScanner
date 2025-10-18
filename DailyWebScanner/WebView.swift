import SwiftUI
import WebKit
import AppKit

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> NSScrollView {
        DebugLogger.shared.logWebKitStart()
        
        // FALLBACK: Verwende NSTextView statt WKWebView wegen WebKit-Crashes
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Konfiguration für HTML-Darstellung
        textView.isEditable = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: 800, height: 10000)
        
        // HTML zu NSAttributedString konvertieren mit besserer Formatierung
        if let data = html.data(using: .utf8) {
            do {
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
                
                // Zusätzliche Formatierung für bessere Darstellung
                let mutableString = NSMutableAttributedString(attributedString: attributedString)
                
                // Überschriften formatieren
                mutableString.enumerateAttribute(.font, in: NSRange(location: 0, length: mutableString.length), options: []) { value, range, _ in
                    if let font = value as? NSFont {
                        if font.fontDescriptor.symbolicTraits.contains(.bold) {
                            // Überschriften größer machen
                            let newFont = NSFont.boldSystemFont(ofSize: 16)
                            mutableString.addAttribute(.font, value: newFont, range: range)
                            mutableString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
                        }
                    }
                }
                
                // Links formatieren
                mutableString.enumerateAttribute(.link, in: NSRange(location: 0, length: mutableString.length), options: []) { value, range, _ in
                    if value != nil {
                        mutableString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
                        mutableString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                    }
                }
                
                textView.textStorage?.setAttributedString(mutableString)
                DebugLogger.shared.logWebViewAction("HTML content loaded into NSTextView with enhanced formatting")
            } catch {
                // Fallback: Plain text
                textView.string = html
                DebugLogger.shared.logWebViewAction("Fallback to plain text due to HTML parsing error: \(error)")
            }
        } else {
            textView.string = html
            DebugLogger.shared.logWebViewAction("Using plain text as fallback")
        }
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        
        DebugLogger.shared.logWebViewAction("Fallback NSTextView created instead of WKWebView")
        
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        DebugLogger.shared.logWebViewAction("updateNSView called with HTML length: \(html.count)")
        
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // HTML zu NSAttributedString konvertieren mit verbesserter Formatierung
        if let data = html.data(using: .utf8) {
            do {
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
                
                // Zusätzliche Formatierung für bessere Darstellung
                let mutableString = NSMutableAttributedString(attributedString: attributedString)
                
                // Überschriften formatieren
                mutableString.enumerateAttribute(.font, in: NSRange(location: 0, length: mutableString.length), options: []) { value, range, _ in
                    if let font = value as? NSFont {
                        if font.fontDescriptor.symbolicTraits.contains(.bold) {
                            // Überschriften größer machen
                            let newFont = NSFont.boldSystemFont(ofSize: 16)
                            mutableString.addAttribute(.font, value: newFont, range: range)
                            mutableString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
                        }
                    }
                }
                
                // Links formatieren
                mutableString.enumerateAttribute(.link, in: NSRange(location: 0, length: mutableString.length), options: []) { value, range, _ in
                    if value != nil {
                        mutableString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
                        mutableString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                    }
                }
                
                textView.textStorage?.setAttributedString(mutableString)
                DebugLogger.shared.logWebViewAction("HTML content loaded into NSTextView with enhanced formatting")
            } catch {
                // Fallback: Plain text
                textView.string = html
                DebugLogger.shared.logWebViewAction("Fallback to plain text due to HTML parsing error: \(error)")
            }
        } else {
            textView.string = html
            DebugLogger.shared.logWebViewAction("Using plain text as fallback")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        // Kein WKNavigationDelegate mehr nötig für NSTextView
    }
}
