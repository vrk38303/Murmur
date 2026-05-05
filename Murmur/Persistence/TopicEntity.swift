import Foundation
import SwiftData

@Model
final class TopicEntity {
    @Attribute(.unique) var id: UUID
    var label: String
    /// 384-dim embedding from `ContextualEmbedder`. Stored as `[Float]`.
    var embedding: [Float]
    var importance: Int
    @Relationship(inverse: \CallEntity.topics)
    var calls: [CallEntity]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         label: String,
         embedding: [Float],
         importance: Int = 1) {
        self.id = id
        self.label = label
        self.embedding = embedding
        self.importance = importance
        self.calls = []
        self.createdAt = .now
        self.updatedAt = .now
    }
}
