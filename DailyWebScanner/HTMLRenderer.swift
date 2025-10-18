import Foundation

struct HTMLRenderer {
    func renderHTML(query: String, results: [SearchResult]) -> String {
        let itemsHTML = results.map { r in
            // Prüfe, ob Summary eine AI-Zusammenfassung ist (anders als Original-Snippet)
            let isAISummary = r.summary != r.snippet && !r.summary.isEmpty
            let summaryHTML = isAISummary ? 
                """
                <div class="ai-summary">
                  <h4>🤖 KI-Zusammenfassung:</h4>
                  <p>\(escape(r.summary))</p>
                </div>
                """ : 
                """
                <div class="original-snippet">
                  <h4>📄 Original-Text:</h4>
                  <p>\(escape(r.snippet))</p>
                </div>
                """
            
            return """
            <article class="item">
              <h2><a href="\(escape(r.link))" target="_blank" rel="noopener noreferrer">\(escape(r.title))</a></h2>
              <p class="source"><a href="\(escape(r.link))" target="_blank" rel="noopener noreferrer">\(escape(r.link))</a></p>
              \(summaryHTML)
            </article>
            """
        }.joined(separator: "\n")

        let html = """
        <!doctype html>
        <html lang="de">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Zusammenfassung – \(escape(query))</title>
          <style>
            body { font-family: -apple-system, system-ui, Helvetica, Arial, sans-serif; margin: 24px; color: #1c1c1c; }
            h1 { font-size: 22px; margin: 0 0 16px 0; }
            .item { border-top: 1px solid #e5e5e5; padding: 16px 0; }
            .item:first-of-type { border-top: none; }
            h2 { font-size: 18px; margin: 0 0 6px 0; }
            .source { color: #6b6b6b; font-size: 12px; margin: 0 0 8px 0; }
            h4 { font-size: 14px; margin: 0 0 6px 0; color: #666; }
            .ai-summary { background: #e8f4fd; border-left: 4px solid #0066cc; padding: 12px; border-radius: 6px; margin: 8px 0; }
            .original-snippet { background: #f7f7f8; border-left: 4px solid #8e8e93; padding: 12px; border-radius: 6px; margin: 8px 0; }
            .ai-summary p, .original-snippet p { margin: 0; color: #333; line-height: 1.4; }
            a { color: #0066cc; text-decoration: none; }
            a:hover { text-decoration: underline; }
          </style>
        </head>
        <body>
          <h1>Suchbegriff: \(escape(query))</h1>
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
