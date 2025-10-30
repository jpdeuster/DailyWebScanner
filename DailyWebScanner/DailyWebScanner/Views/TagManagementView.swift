import SwiftUI
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var newTag: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag").foregroundColor(.blue)
                Text("Tags").font(.title2).fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 8) {
                TextField("New tag name", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTag)
                Button("Add", action: addTag).buttonStyle(.bordered)
            }
            
            List {
                ForEach(tags) { tag in
                    HStack {
                        Text(tag.name)
                        Spacer()
                        Button(role: .destructive) {
                            TagManager.delete(tag, in: modelContext)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Tag Management")
    }
    
    private func addTag() {
        let name = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        _ = TagManager.getOrCreate(name: name, in: modelContext)
        try? modelContext.save()
        newTag = ""
    }
}

#Preview {
    TagManagementView()
}


