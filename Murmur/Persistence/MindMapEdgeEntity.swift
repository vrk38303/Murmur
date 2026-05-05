import Foundation
import SwiftData

@Model
final class MindMapEdgeEntity {
    @Attribute(.unique) var id: UUID
    var sourceNodeId: UUID
    var sourceNodeTypeRaw: String
    var targetNodeId: UUID
    var targetNodeTypeRaw: String
    var weight: Double
    var isUserCreated: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         sourceNodeId: UUID,
         sourceNodeType: NodeType,
         targetNodeId: UUID,
         targetNodeType: NodeType,
         weight: Double,
         isUserCreated: Bool = false) {
        self.id = id
        self.sourceNodeId = sourceNodeId
        self.sourceNodeTypeRaw = sourceNodeType.rawValue
        self.targetNodeId = targetNodeId
        self.targetNodeTypeRaw = targetNodeType.rawValue
        self.weight = weight
        self.isUserCreated = isUserCreated
        self.createdAt = .now
    }

    var sourceNodeType: NodeType { NodeType(rawValue: sourceNodeTypeRaw) ?? .call }
    var targetNodeType: NodeType { NodeType(rawValue: targetNodeTypeRaw) ?? .call }
}
