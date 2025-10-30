import Foundation
import SwiftData

enum TagManager {
    static func fetchAll(_ context: ModelContext) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name, order: .forward)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    static func fetchByName(_ name: String, _ context: ModelContext) -> Tag? {
        var descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
    
    static func getOrCreate(name: String, in context: ModelContext) -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return Tag(name: "") }
        if let existing = fetchByName(trimmed, context) {
            return existing
        }
        let tag = Tag(name: trimmed)
        context.insert(tag)
        return tag
    }
    
    static func delete(_ tag: Tag, in context: ModelContext) {
        context.delete(tag)
    }
}


