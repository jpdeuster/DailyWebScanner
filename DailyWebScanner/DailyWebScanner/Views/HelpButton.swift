import SwiftUI

struct HelpButton: View {
    let urlString: String
    
    init(urlString: String = "https://github.com/jpdeuster/DailyWebScanner#readme") {
        self.urlString = urlString
    }
    
    var body: some View {
        Button(action: openHelp) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.blue)
                .font(.caption)
        }
        .buttonStyle(.plain)
        .help("Open documentation on GitHub")
    }
    
    private func openHelp() {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
