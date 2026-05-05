import XCTest
@testable import Murmur

final class SummarizationServiceTests: XCTestCase {
    func testParsesValidJSON() async throws {
        let svc = SummarizationService()
        await svc.setEngine(.bundledMLX)
        let segments: [TranscriptSegmentEntity] = [
            TranscriptSegmentEntity(callId: UUID(),
                                    startTimeSeconds: 0, endTimeSeconds: 1,
                                    speakerLabel: "You",
                                    text: "Discussed the IBM offer in Austin and the timing relative to other interviews."),
            TranscriptSegmentEntity(callId: UUID(),
                                    startTimeSeconds: 1, endTimeSeconds: 2,
                                    speakerLabel: "Neera",
                                    text: "Don't undersell the Atlanta option just because IBM is loud right now.")
        ]
        let r = try await svc.summarize(transcript: segments, contactName: "Neera")
        XCTAssertFalse(r.summary.isEmpty)
        XCTAssertNotNil(SentimentLabel(rawValue: r.sentiment.rawValue))
    }

    func testHeuristicTopicsExtractKeywords() {
        let topics = SummarizationService.extractTopics(
            from: "The IBM interview discussed counter strategy and Atlanta plans"
        )
        XCTAssertFalse(topics.isEmpty)
    }
}
