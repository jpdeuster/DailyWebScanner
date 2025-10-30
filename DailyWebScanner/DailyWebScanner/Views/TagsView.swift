import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var newTag: String = ""
    @State private var searchText: String = ""
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: Tag?
    
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return tags
        } else {
            return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tag Management")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Organize your articles with custom tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Search and Add Section
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search tags...", text: $searchText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .opacity(searchText.isEmpty ? 0 : 1)
                    }
                    
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            TextField("New tag name", text: $newTag)
                                .onSubmit(addTag)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        Button("Add Tag", action: addTag)
                            .buttonStyle(.borderedProminent)
                            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
                .padding(.vertical, 8)
            
            // Tags List
            if filteredTags.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "tag" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No tags yet" : "No tags found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "Create your first tag to organize articles" : "Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                List {
                    ForEach(filteredTags) { tag in
                        TagRowView(
                            tag: tag,
                            articleCount: tagCount(for: tag),
                            onDelete: {
                                tagToDelete = tag
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Tags")
        .alert("Delete Tag", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let tag = tagToDelete {
                    TagManager.delete(tag, in: modelContext)
                }
            }
        } message: {
            if let tag = tagToDelete {
                Text("Are you sure you want to delete the tag '\(tag.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func addTag() {
        let name = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        _ = TagManager.getOrCreate(name: name, in: modelContext)
        try? modelContext.save()
        newTag = ""
    }
    
    private func tagCount(for tag: Tag) -> Int {
        // Fetch all LinkRecords and count manually due to SwiftData predicate limitations with many-to-many
        let descriptor = FetchDescriptor<LinkRecord>()
        let allLinks = (try? modelContext.fetch(descriptor)) ?? []
        return allLinks.filter { linkRecord in
            linkRecord.tags.contains { $0.id == tag.id }
        }.count
    }
}

struct TagRowView: View {
    let tag: Tag
    let articleCount: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Tag Icon
            Image(systemName: "tag.fill")
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            // Tag Info
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(articleCount == 1 ? "1 article" : "\(articleCount) articles")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .padding(8)
            .background(Color.red.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

#Preview {
    TagsView()
}
