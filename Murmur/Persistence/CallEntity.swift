import Foundation
import SwiftData

@Model
final class CallEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var contactIdentifier: String?
    var contactName: String?
    var phoneNumber: String?
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Double
    /// File URL relative to the encrypted audio directory. Stored as a path
    /// string so the URL doesn't bake in absolute paths that change between
    /// installs.
    var audioFileName: String
    var audioDurationSeconds: Double
    var sampleRate: Double
    var bitDepth: Int
    var summary: String?
    var keyPoints: [String]
    var actionItems: [ActionItem]
    var sentimentLabel: String?
    var processingStateRaw: String
    var processingError: String?
    var isPinned: Bool
    var isArchived: Bool
    var consentRecorded: Bool
    @Relationship(deleteRule: .cascade, inverse: \TranscriptSegmentEntity.call)
    var transcriptSegments: [TranscriptSegmentEntity]
    @Relationship(deleteRule: .nullify)
    var topics: [TopicEntity]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         title: String,
         contactIdentifier: String? = nil,
         contactName: String? = nil,
         phoneNumber: String? = nil,
         startedAt: Date = .now,
         endedAt: Date? = nil,
         durationSeconds: Double = 0,
         audioFileName: String,
         audioDurationSeconds: Double = 0,
         sampleRate: Double = 16_000,
         bitDepth: Int = 16,
         summary: String? = nil,
         keyPoints: [String] = [],
         actionItems: [ActionItem] = [],
         sentimentLabel: String? = nil,
         processingState: ProcessingState = .pending,
         processingError: String? = nil,
         isPinned: Bool = false,
         isArchived: Bool = false,
         consentRecorded: Bool = false) {
        self.id = id
        self.title = title
        self.contactIdentifier = contactIdentifier
        self.contactName = contactName
        self.phoneNumber = phoneNumber
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.audioFileName = audioFileName
        self.audioDurationSeconds = audioDurationSeconds
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.summary = summary
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.sentimentLabel = sentimentLabel
        self.processingStateRaw = processingState.rawValue
        self.processingError = processingError
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.consentRecorded = consentRecorded
        self.transcriptSegments = []
        self.topics = []
        self.createdAt = .now
        self.updatedAt = .now
    }

    var processingState: ProcessingState {
        get { ProcessingState(rawValue: processingStateRaw) ?? .pending }
        set { processingStateRaw = newValue.rawValue; updatedAt = .now }
    }

    var displayName: String {
        contactName ?? title
    }
}
