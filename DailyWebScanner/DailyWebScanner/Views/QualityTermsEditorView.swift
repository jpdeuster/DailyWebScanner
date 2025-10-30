import SwiftUI

struct QualityTermsEditorView: View {
    @State private var qualityIndicators: String = ""
    @State private var lowQualityIndicators: String = ""
    @State private var meaningfulPatterns: String = ""
    @State private var emptyPatterns: String = ""
    @State private var excludedUrlPatterns: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                section(title: "Quality Indicators", text: $qualityIndicators, onSave: {
                    QualityConfig.shared.setQualityIndicators(parseList(qualityIndicators))
                })
                section(title: "Low Quality Indicators", text: $lowQualityIndicators, onSave: {
                    QualityConfig.shared.setLowQualityIndicators(parseList(lowQualityIndicators))
                })
                section(title: "Meaningful Content Patterns", text: $meaningfulPatterns, onSave: {
                    QualityConfig.shared.setMeaningfulContentPatterns(parseList(meaningfulPatterns))
                })
                section(title: "Empty Content Patterns", text: $emptyPatterns, onSave: {
                    QualityConfig.shared.setEmptyContentPatterns(parseList(emptyPatterns))
                })
                section(title: "Excluded URL Patterns", text: $excludedUrlPatterns, onSave: {
                    QualityConfig.shared.setExcludedUrlPatterns(parseList(excludedUrlPatterns))
                })
            }
            .padding()
        }
        .onAppear(perform: load)
        .navigationTitle("Quality Terms Editor")
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "list.bullet")
                .foregroundColor(.blue)
                .font(.title2)
            Text("Edit Quality Term Lists")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
        }
    }
    
    private func section(title: String, text: Binding<String>, onSave: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            TextEditor(text: text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3) as Color, lineWidth: 1)
                )
            HStack {
                Text("Comma or newline separated").font(.caption).foregroundColor(.secondary)
                Spacer()
                Button("Save", action: onSave).buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08) as Color)
        .cornerRadius(10)
    }
    
    private func load() {
        qualityIndicators = formatList(QualityConfig.shared.qualityIndicators)
        lowQualityIndicators = formatList(QualityConfig.shared.lowQualityIndicators)
        meaningfulPatterns = formatList(QualityConfig.shared.meaningfulContentPatterns)
        emptyPatterns = formatList(QualityConfig.shared.emptyContentPatterns)
        excludedUrlPatterns = formatList(QualityConfig.shared.excludedUrlPatterns)
    }
    
    private func parseList(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: ",", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func formatList(_ items: [String]) -> String {
        items.sorted().joined(separator: "\n")
    }
}

#Preview {
    QualityTermsEditorView()
}


