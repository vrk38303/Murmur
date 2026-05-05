import Foundation
import SwiftData
import CoreGraphics

struct MindMapNode: Identifiable, Hashable, Sendable {
    let id: UUID
    let type: NodeType
    let label: String
    let importance: Int
    var position: CGPoint  // normalized [0,1]
}

struct MindMapEdge: Identifiable, Hashable, Sendable {
    let id: UUID
    let source: UUID
    let target: UUID
    let weight: Double
    let isUserCreated: Bool
}

struct MindMapGraph: Sendable {
    let nodes: [MindMapNode]
    let edges: [MindMapEdge]
    static let empty = MindMapGraph(nodes: [], edges: [])
}

protocol MindMapServiceProtocol: Actor {
    func attachCallToTopics(callId: UUID, topicLabels: [String]) async throws
    func graph() async throws -> MindMapGraph
    func userCreateEdge(from: UUID, to: UUID) async throws
    func userDeleteEdge(_ edgeId: UUID) async throws
    func setAutoConnectThreshold(_ value: Double) async
    /// Drop the cached Fruchterman-Reingold positions so the next
    /// `graph()` call recomputes layout from scratch. Surfaced in
    /// Settings as "Reset map positions" so the user can break out of
    /// a layout that has settled into a visually unhelpful arrangement.
    func resetLayoutCache() async
}

actor MindMapService: MindMapServiceProtocol {
    private let container: ModelContainer
    private let embedder = ContextualEmbedder()
    private var threshold: Double = 0.82
    private let maxEdgesPerCall = 5

    /// Cached layout positions, keyed by node id. Recomputed on >5% change.
    private var cachedPositions: [UUID: CGPoint] = [:]
    private var lastNodeCount: Int = 0

    init(container: ModelContainer) {
        self.container = container
    }

    func setAutoConnectThreshold(_ value: Double) {
        threshold = max(0.7, min(0.95, value))
    }

    /// Each actor-isolated method spins up a fresh `ModelContext`. The
    /// `ModelContainer` is `Sendable`; the `ModelContext` is not, so we keep
    /// it scoped to the actor.
    private func newContext() -> ModelContext {
        ModelContext(container)
    }

    func attachCallToTopics(callId: UUID, topicLabels: [String]) async throws {
        let ctx = newContext()
        guard let call = try await fetchCall(id: callId, in: ctx) else { return }

        for raw in topicLabels.prefix(5) {
            let label = raw.trimmingCharacters(in: .whitespaces)
            guard !label.isEmpty else { continue }
            let embedding = embedder.embed(label)

            let topic: TopicEntity
            if let existing = try await nearestTopic(to: embedding, ctx: ctx),
               existing.similarity > threshold {
                topic = existing.entity
            } else {
                let new = TopicEntity(label: label, embedding: embedding)
                ctx.insert(new)
                topic = new
            }
            if !topic.calls.contains(where: { $0.id == call.id }) {
                topic.calls.append(call)
                topic.importance = topic.calls.count
                topic.updatedAt = .now
            }
        }
        try ctx.save()
        try await rebuildEdges(for: callId, ctx: ctx)
    }

    func graph() async throws -> MindMapGraph {
        let ctx = newContext()
        let calls = try ctx.fetch(FetchDescriptor<CallEntity>())
        let topics = try ctx.fetch(FetchDescriptor<TopicEntity>())
        let edges = try ctx.fetch(FetchDescriptor<MindMapEdgeEntity>())

        var nodes: [MindMapNode] = []
        nodes.reserveCapacity(calls.count + topics.count)
        for c in calls {
            nodes.append(MindMapNode(id: c.id, type: .call,
                                     label: c.displayName,
                                     importance: c.topics.count,
                                     position: .zero))
        }
        for t in topics {
            nodes.append(MindMapNode(id: t.id, type: .topic,
                                     label: t.label,
                                     importance: t.importance,
                                     position: .zero))
        }
        let edgeModels = edges.map {
            MindMapEdge(id: $0.id,
                        source: $0.sourceNodeId,
                        target: $0.targetNodeId,
                        weight: $0.weight,
                        isUserCreated: $0.isUserCreated)
        }

        let positioned = layout(nodes: nodes, edges: edgeModels)
        return MindMapGraph(nodes: positioned, edges: edgeModels)
    }

    func userCreateEdge(from: UUID, to: UUID) async throws {
        let ctx = newContext()
        // Pick types — try call first, fall back to topic.
        let srcType: NodeType = (try await fetchCall(id: from, in: ctx) != nil) ? .call : .topic
        let dstType: NodeType = (try await fetchCall(id: to, in: ctx) != nil) ? .call : .topic
        let edge = MindMapEdgeEntity(sourceNodeId: from,
                                     sourceNodeType: srcType,
                                     targetNodeId: to,
                                     targetNodeType: dstType,
                                     weight: 1.0,
                                     isUserCreated: true)
        ctx.insert(edge)
        try ctx.save()
    }

    func userDeleteEdge(_ edgeId: UUID) async throws {
        let ctx = newContext()
        let pred = #Predicate<MindMapEdgeEntity> { $0.id == edgeId }
        if let e = try ctx.fetch(FetchDescriptor(predicate: pred)).first {
            ctx.delete(e)
            try ctx.save()
        }
    }

    // MARK: - Internals

    private func fetchCall(id: UUID, in ctx: ModelContext) async throws -> CallEntity? {
        let pred = #Predicate<CallEntity> { $0.id == id }
        return try ctx.fetch(FetchDescriptor(predicate: pred)).first
    }

    private struct TopicMatch { let entity: TopicEntity; let similarity: Double }

    private func nearestTopic(to embedding: [Float],
                              ctx: ModelContext) async throws -> TopicMatch? {
        let topics = try ctx.fetch(FetchDescriptor<TopicEntity>())
        var best: TopicMatch?
        for t in topics {
            let s = ContextualEmbedder.cosine(embedding, t.embedding)
            if best == nil || s > best!.similarity {
                best = TopicMatch(entity: t, similarity: s)
            }
        }
        return best
    }

    /// Re-derive call-to-call edges through shared topics. Caps at 5 per call.
    private func rebuildEdges(for callId: UUID, ctx: ModelContext) async throws {
        guard let me = try await fetchCall(id: callId, in: ctx) else { return }

        // Drop existing auto edges that involve me.
        let existing = try ctx.fetch(FetchDescriptor<MindMapEdgeEntity>())
        for e in existing where !e.isUserCreated &&
            (e.sourceNodeId == callId || e.targetNodeId == callId) {
            ctx.delete(e)
        }

        // Build candidate calls: anyone sharing a topic with me.
        var candidates: [UUID: Double] = [:]
        for t in me.topics {
            for other in t.calls where other.id != me.id {
                let weight = otherTopicSimilarity(me: me, other: other)
                candidates[other.id] = max(candidates[other.id] ?? 0, weight)
            }
        }

        let topK = candidates.sorted { $0.value > $1.value }.prefix(maxEdgesPerCall)
        for (otherId, w) in topK {
            let edge = MindMapEdgeEntity(sourceNodeId: callId,
                                         sourceNodeType: .call,
                                         targetNodeId: otherId,
                                         targetNodeType: .call,
                                         weight: w,
                                         isUserCreated: false)
            ctx.insert(edge)
        }
        try ctx.save()
    }

    private func otherTopicSimilarity(me: CallEntity, other: CallEntity) -> Double {
        var best = 0.0
        for tm in me.topics {
            for to in other.topics {
                let s = ContextualEmbedder.cosine(tm.embedding, to.embedding)
                if s > best { best = s }
            }
        }
        return best
    }

    // MARK: - Layout (Fruchterman-Reingold, normalized output)

    func layout(nodes: [MindMapNode], edges: [MindMapEdge]) -> [MindMapNode] {
        let n = nodes.count
        guard n > 0 else { return [] }

        // Re-use cached positions when:
        //   1. We have a cache at all (first run is never "fresh"), AND
        //   2. The graph hasn't grown by more than 5% since the last layout, AND
        //   3. Every current node id has a cached position (no new nodes added).
        // Without the emptiness guard, the very first layout (lastNodeCount == 0,
        // n == 1) would satisfy `1 <= 1` and return an empty cache, leaving
        // every node at a random point. Without the id-coverage guard, adding
        // a single node within the 5% tolerance would still return a stale
        // position map missing that new node.
        let allCached = nodes.allSatisfy { cachedPositions[$0.id] != nil }
        if !cachedPositions.isEmpty,
           lastNodeCount > 0,
           allCached,
           abs(n - lastNodeCount) <= max(1, Int(Double(lastNodeCount) * 0.05)) {
            return nodes.map { node in
                var copy = node
                copy.position = cachedPositions[node.id] ?? randomPoint()
                return copy
            }
        }

        let area: Double = 1.0
        let k = sqrt(area / Double(n))
        var pos: [UUID: CGPoint] = [:]
        for node in nodes { pos[node.id] = randomPoint() }

        var temp = 0.1
        let cooling = temp / 50.0
        for _ in 0..<50 {
            var disp: [UUID: CGPoint] = [:]
            for node in nodes { disp[node.id] = .zero }

            // Repulsive forces — O(n^2). Fine up to a few hundred nodes.
            for i in 0..<n {
                for j in (i + 1)..<n {
                    let a = nodes[i].id, b = nodes[j].id
                    guard let pa = pos[a], let pb = pos[b] else { continue }
                    let dx = pa.x - pb.x
                    let dy = pa.y - pb.y
                    let dist = max(0.001, sqrt(dx * dx + dy * dy))
                    let force = (k * k) / dist
                    let ux = dx / dist, uy = dy / dist
                    disp[a]?.x += ux * force; disp[a]?.y += uy * force
                    disp[b]?.x -= ux * force; disp[b]?.y -= uy * force
                }
            }
            // Attractive forces along edges.
            for e in edges {
                guard let pa = pos[e.source], let pb = pos[e.target] else { continue }
                let dx = pa.x - pb.x, dy = pa.y - pb.y
                let dist = max(0.001, sqrt(dx * dx + dy * dy))
                let force = (dist * dist) / k
                let ux = dx / dist, uy = dy / dist
                disp[e.source]?.x -= ux * force; disp[e.source]?.y -= uy * force
                disp[e.target]?.x += ux * force; disp[e.target]?.y += uy * force
            }
            // Apply.
            for node in nodes {
                guard let d = disp[node.id], var p = pos[node.id] else { continue }
                let mag = max(0.0001, sqrt(d.x * d.x + d.y * d.y))
                p.x += (d.x / mag) * min(mag, temp)
                p.y += (d.y / mag) * min(mag, temp)
                p.x = min(1, max(0, p.x))
                p.y = min(1, max(0, p.y))
                pos[node.id] = p
            }
            temp = max(0, temp - cooling)
        }
        cachedPositions = pos
        lastNodeCount = n
        return nodes.map { node in
            var c = node
            c.position = pos[node.id] ?? randomPoint()
            return c
        }
    }

    private func randomPoint() -> CGPoint {
        CGPoint(x: .random(in: 0.1...0.9), y: .random(in: 0.1...0.9))
    }

    func resetLayoutCache() { cachedPositions.removeAll(); lastNodeCount = 0 }
}
