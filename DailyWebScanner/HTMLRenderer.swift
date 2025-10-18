import Foundation

struct HTMLRenderer {
    func renderHTML(query: String, results: [SearchResult]) -> String {
        let itemsHTML = results.map { r in
            // Prüfe, ob Summary eine AI-Zusammenfassung ist (anders als Original-Snippet)
            let isAISummary = r.summary != r.snippet && !r.summary.isEmpty
            let summaryHTML = isAISummary ? 
                """
                <div style="background-color: #E8F4FD; border-left: 4px solid #007AFF; padding: 10px; margin: 8px 0; border-radius: 4px;">
                  <h4 style="color: #007AFF; margin: 0 0 5px 0;">🤖 KI-Zusammenfassung:</h4>
                  <p style="margin: 0; line-height: 1.4;">\(escape(r.summary))</p>
                </div>
                """ : 
                """
                <div style="background-color: #F2F2F7; border-left: 4px solid #8E8E93; padding: 10px; margin: 8px 0; border-radius: 4px;">
                  <h4 style="color: #8E8E93; margin: 0 0 5px 0;">📄 Original-Text:</h4>
                  <p style="margin: 0; line-height: 1.4;">\(escape(r.snippet))</p>
                </div>
                """
            
            return """
            <div style="margin-bottom: 20px; padding: 10px; border-left: 3px solid #007AFF;">
              <h2><a href="\(escape(r.link))">\(escape(r.title))</a></h2>
              <p style="color: #666; font-size: 12px; margin: 5px 0;"><a href="\(escape(r.link))">\(escape(r.link))</a></p>
              \(summaryHTML)
            </div>
            """
        }.joined(separator: "\n")

        let html = """
        <!doctype html>
        <html lang="de">
        <head>
          <meta charset="utf-8">
          <title>Zusammenfassung – \(escape(query))</title>
        </head>
        <body>
          <h1>🔍 Suchbegriff: \(escape(query))</h1>
          \(itemsHTML)
        </body>
        </html>
        """
        return html
    }

    private func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
