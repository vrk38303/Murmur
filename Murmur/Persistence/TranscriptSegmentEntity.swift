import Foundation
import SwiftData

@Model
final class TranscriptSegmentEntity {
    @Attribute(.unique) var id: UUID
    var callId: UUID
    var startTimeSeconds: Double
    var endTimeSeconds: Double
    var speakerLabel: String
    var text: String
    var confidence: Double
    var createdAt: Date
    var call: CallEntity?

    init(id: UUID = UUID(),
         callId: UUID,
         startTimeSeconds: Double,
         endTimeSeconds: Double,
         speakerLabel: String,
         text: String,
         confidence: Double = 1.0,
         call: CallEntity? = nil) {
        self.id = id
        self.callId = callId
        self.startTimeSeconds = startTimeSeconds
        self.endTimeSeconds = endTimeSeconds
        self.speakerLabel = speakerLabel
        self.text = text
        self.confidence = confidence
        self.createdAt = .now
        self.call = call
    }
}
