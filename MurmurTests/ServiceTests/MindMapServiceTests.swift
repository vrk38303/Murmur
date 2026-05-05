import XCTest
import SwiftData
@testable import Murmur

@MainActor
final class MindMapServiceTests: XCTestCase {
    func testTopicAttachmentCreatesTopics() async throws {
        let container = MurmurStore.previewContainer()
        let service = MindMapService(container: container)
        let ctx = ModelContext(container)
        let call = CallEntity(title: "Test", audioFileName: "x")
        ctx.insert(call); try ctx.save()

        try await service.attachCallToTopics(callId: call.id,
                                             topicLabels: ["Job search", "IBM offer"])
        let graph = try await service.graph()
        XCTAssertGreaterThanOrEqual(graph.nodes.count, 3) // 1 call + ≥2 topics
    }

    func testThresholdMergesSimilarTopics() async throws {
        let container = MurmurStore.previewContainer()
        let service = MindMapService(container: container)
        // The service clamps threshold to [0.7, 0.95]; we use the floor so any
        // close-by label merges with an existing topic.
        await service.setAutoConnectThreshold(0.7)
        let ctx = ModelContext(container)
        let a = CallEntity(title: "A", audioFileName: "a")
        let b = CallEntity(title: "B", audioFileName: "b")
        ctx.insert(a); ctx.insert(b); try ctx.save()

        try await service.attachCallToTopics(callId: a.id, topicLabels: ["job"])
        try await service.attachCallToTopics(callId: b.id, topicLabels: ["job"])
        let topics = try ctx.fetch(FetchDescriptor<TopicEntity>())
        // Same label twice → one topic, two calls attached.
        XCTAssertEqual(topics.count, 1)
        XCTAssertEqual(topics.first?.calls.count, 2)
    }

    func testCosineSanity() {
        let v: [Float] = [1, 0, 0]
        XCTAssertEqual(ContextualEmbedder.cosine(v, v), 1.0, accuracy: 0.001)
        let w: [Float] = [0, 1, 0]
        XCTAssertEqual(ContextualEmbedder.cosine(v, w), 0.0, accuracy: 0.001)
    }

    func testLayoutFitsInUnitSquare() async throws {
        let container = MurmurStore.previewContainer()
        let service = MindMapService(container: container)
        let nodes = (0..<10).map {
            MindMapNode(id: UUID(), type: .call, label: "n\($0)",
                        importance: 1, position: .zero)
        }
        let positioned = await service.layout(nodes: nodes, edges: [])
        for n in positioned {
            XCTAssertGreaterThanOrEqual(n.position.x, 0)
            XCTAssertLessThanOrEqual(n.position.x, 1)
            XCTAssertGreaterThanOrEqual(n.position.y, 0)
            XCTAssertLessThanOrEqual(n.position.y, 1)
        }
    }
}
