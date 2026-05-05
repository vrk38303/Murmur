import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored
    @AppStorage("rec.audioQuality") var audioQuality: String = "standard"

    @ObservationIgnored
    @AppStorage("rec.autoPauseOnSystemCall") var autoPauseOnSystemCall: Bool = true

    @ObservationIgnored
    @AppStorage("transcription.engine") var transcriptionEngineRaw: String = TranscriptionEngine.appleSpeechAnalyzer.rawValue

    @ObservationIgnored
    @AppStorage("summarization.engine") var summarizationEngineRaw: String = SummarizationEngine.appleIntelligence.rawValue

    @ObservationIgnored
    @AppStorage("summarization.cloudOptIn") var cloudOptIn: Bool = false

    @ObservationIgnored
    @AppStorage("mindmap.threshold") var threshold: Double = 0.82

    @ObservationIgnored
    @AppStorage("appearance.darkModeOverride") var darkModeOverride: String = "system"

    /// Diarization currently has no real implementation. We persist the mode
    /// so the picker reflects the user's last choice, but selecting anything
    /// other than "single" is honestly labeled "Coming soon" in the UI and
    /// short-circuits back to "single" in `setDiarizationMode`. PRD §10
    /// originally listed Off / Heuristic / Pro; we collapse to single until
    /// the SpeakerKit work lands (see LIMITATIONS.md).
    @ObservationIgnored
    @AppStorage("diarization.mode") var diarizationModeRaw: String = DiarizationMode.single.rawValue

    var diarizationMode: DiarizationMode {
        get { DiarizationMode(rawValue: diarizationModeRaw) ?? .single }
        set {
            // Refuse to commit to anything we can't actually do; force single
            // so the saved label on every transcript segment stays honest.
            if newValue == .single {
                diarizationModeRaw = newValue.rawValue
            } else {
                diarizationModeRaw = DiarizationMode.single.rawValue
                diarizationUnavailableNotice = true
            }
        }
    }
    var diarizationUnavailableNotice: Bool = false

    var deleteConfirmVisible: Bool = false
    var exportInProgress: Bool = false
    var exportBundleURL: URL?
    /// URL handed to the system share sheet after a successful export. Bound
    /// to a `.sheet(item:)` in SettingsView. Cleared when the sheet dismisses.
    var shareItem: URL?
    var error: AppError?

    /// WhisperKit on-device model state. Until the actual download pipeline
    /// lands (LIMITATIONS: "WhisperKit"), the row honestly reports
    /// "Unavailable in this build" rather than appearing to download
    /// silently. When wired up, set `state = .downloading(progress:)` from a
    /// `URLSessionDownloadTask` and `.installed` once the file lands.
    enum WhisperKitState: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case installed
        case unavailableInBuild
    }
    var whisperKitState: WhisperKitState = .unavailableInBuild
    var whisperKitNotice: String?

    var whisperKitDownloadLabel: String {
        switch whisperKitState {
        case .notDownloaded:        return "Download Whisper Large V3"
        case .downloading(let p):   return "Downloading Whisper Large V3 — \(Int(p * 100))%"
        case .installed:            return "Whisper Large V3 — installed"
        case .unavailableInBuild:   return "Whisper Large V3 — unavailable in this build"
        }
    }

    func downloadWhisperKitModel() async {
        switch whisperKitState {
        case .unavailableInBuild:
            // Honest surface so the user isn't left wondering whether their
            // tap did anything. See LIMITATIONS.md "WhisperKit".
            whisperKitNotice = "WhisperKit downloads aren't shipping in this build yet. The current transcription engine will keep working."
        case .installed:
            whisperKitNotice = "WhisperKit Large V3 is already installed."
        case .downloading:
            whisperKitNotice = "A download is already in progress."
        case .notDownloaded:
            // Hook here when the real WhisperKit fetcher lands.
            whisperKitNotice = "WhisperKit downloads aren't shipping in this build yet."
        }
    }

    private let services: ServiceContainer
    init(services: ServiceContainer) { self.services = services }

    /// Consent reminder toggle. Routed through the VM (PRD §14: "no business
    /// logic in views") rather than letting the view tap the service
    /// property directly. The setter writes through to
    /// `ConsentReminderService.alwaysRemind`, which now properly notifies
    /// Observation subscribers (see ConsentReminderService docs).
    var consentAlwaysRemind: Bool {
        get { services.consent.alwaysRemind }
        set { services.consent.alwaysRemind = newValue }
    }

    var transcriptionEngine: TranscriptionEngine {
        get { TranscriptionEngine(rawValue: transcriptionEngineRaw) ?? .appleSpeechAnalyzer }
        set {
            transcriptionEngineRaw = newValue.rawValue
            Task { await services.transcription.setEngine(newValue) }
        }
    }

    var summarizationEngine: SummarizationEngine {
        get { SummarizationEngine(rawValue: summarizationEngineRaw) ?? .bundledMLX }
        set {
            // Cloud requires explicit opt-in.
            if newValue == .cloud, !cloudOptIn { return }
            summarizationEngineRaw = newValue.rawValue
            Task { await services.summarization.setEngine(newValue) }
        }
    }

    /// Engines the picker should expose. Populated on view appear from
    /// `SummarizationService.availableEngines()` so a build that doesn't
    /// import `FoundationModels` never offers Apple Intelligence — picking it
    /// would just throw `summarizationUnavailable`.
    var availableSummarizationEngines: [SummarizationEngine] = SummarizationEngine.allCases

    func loadAvailableEngines() async {
        availableSummarizationEngines = await services.summarization.availableEngines()
        // If a stale @AppStorage value points at an engine the current build
        // can't run (e.g. AI default rolled forward from a previous SDK),
        // fall back to the first available one so the picker is honest.
        if !availableSummarizationEngines.contains(summarizationEngine),
           let first = availableSummarizationEngines.first {
            summarizationEngine = first
        }
    }

    func setThreshold(_ v: Double) {
        threshold = v
        Task { await services.mindMap.setAutoConnectThreshold(v) }
    }

    /// Drop cached mind-map positions and trigger a fresh layout the
    /// next time the Mind Map tab loads. Visible to the user as a flash
    /// of node motion on the next visit; documented in Settings copy as
    /// "Reset map positions."
    func resetMapPositions() async {
        await services.mindMap.resetLayoutCache()
    }

    func exportLibrary(includeAudio: Bool) async {
        exportInProgress = true
        defer { exportInProgress = false }
        do {
            let bundle = try await services.export.exportEverything(includeAudio: includeAudio)
            exportBundleURL = bundle.archiveURL
            shareItem = bundle.archiveURL
        } catch {
            self.error = (error as? AppError) ?? .exportFailed("\(error)")
        }
    }

    func deleteEverything() async {
        do {
            try await services.permissions.confirmWithBiometrics(
                reason: "Delete all Murmur data on this device"
            )
            try await services.export.nuke()
        } catch {
            self.error = (error as? AppError) ?? .unknown("\(error)")
        }
    }
}
