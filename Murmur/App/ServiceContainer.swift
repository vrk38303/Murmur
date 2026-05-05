import Foundation
import SwiftData
import SwiftUI

/// PRD §3.3 — lightweight environment-based DI. Tests inject mocks by
/// constructing their own container and overriding the protocol-typed
/// references.
@MainActor
@Observable
final class ServiceContainer {
    let modelContainer: ModelContainer
    let recording: RecordingService
    let transcription: TranscriptionService
    let summarization: SummarizationService
    let mindMap: MindMapService
    let consent: ConsentReminderService
    let subscriptions: SubscriptionService
    let export: ExportService
    let permissions: PermissionsManager

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let transcription = TranscriptionService()
        let recording = RecordingService(transcription: transcription)
        Task { await recording.attach(transcription: transcription) }
        self.transcription = transcription
        self.recording = recording
        self.summarization = SummarizationService()
        self.mindMap = MindMapService(container: modelContainer)
        self.consent = ConsentReminderService()
        self.subscriptions = SubscriptionService()
        self.export = ExportService(container: modelContainer)
        self.permissions = .shared
    }

    static func live() -> ServiceContainer {
        let container: ModelContainer
        do {
            container = try MurmurStore.makeContainer()
        } catch {
            // Last-resort: fall back to in-memory so the app still launches.
            container = MurmurStore.previewContainer()
        }
        return ServiceContainer(modelContainer: container)
    }

    static func preview() -> ServiceContainer {
        ServiceContainer(modelContainer: MurmurStore.previewContainer())
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    @MainActor static let defaultValue: ServiceContainer = .preview()
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
