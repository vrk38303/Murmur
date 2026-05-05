import Foundation
import SwiftData
import SwiftUI

enum CallDetailSegment: String, CaseIterable, Hashable {
    case summary, transcript, map
    var label: LocalizedStringKey {
        switch self {
        case .summary:    return "detail.seg.summary"
        case .transcript: return "detail.seg.transcript"
        case .map:        return "detail.seg.map"
        }
    }
}

@MainActor
@Observable
final class CallDetailViewModel {
    let callId: UUID
    var segment: CallDetailSegment = .summary
    var call: CallEntity?
    var segments: [TranscriptSegmentEntity] = []
    var connectedTopics: [TopicEntity] = []
    var error: AppError?

    private let services: ServiceContainer
    /// Long-lived context so mutations on `call` save through the same store.
    /// Creating a fresh context per save is a SwiftData anti-pattern: the
    /// mutated entity belongs to the load context, not the save context.
    private let context: ModelContext

    init(callId: UUID, services: ServiceContainer) {
        self.callId = callId
        self.services = services
        self.context = ModelContext(services.modelContainer)
    }

    func load() {
        // `#Predicate` does not allow capturing `self` — extract to a local.
        let id = callId
        let pred = #Predicate<CallEntity> { $0.id == id }
        do {
            self.call = try context.fetch(FetchDescriptor(predicate: pred)).first
            if let call {
                self.segments = call.transcriptSegments.sorted {
                    $0.startTimeSeconds < $1.startTimeSeconds
                }
                self.connectedTopics = call.topics
            }
        } catch {
            self.error = .persistenceFailed(error.localizedDescription)
        }
    }

    func toggleActionItem(_ id: UUID) {
        guard let call else { return }
        if let idx = call.actionItems.firstIndex(where: { $0.id == id }) {
            call.actionItems[idx].isCompleted.toggle()
            call.updatedAt = .now
            do { try context.save() }
            catch { self.error = .persistenceFailed(error.localizedDescription) }
        }
    }
}
