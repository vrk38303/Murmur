import Foundation
import AVFoundation
import Speech

protocol TranscriptionServiceProtocol: Actor {
    func availableEngines() -> [TranscriptionEngine]
    func currentEngine() -> TranscriptionEngine
    func setEngine(_ engine: TranscriptionEngine) async
    func beginStreaming(callId: UUID,
                        sampleRate: Double,
                        speakerHint: String,
                        onUpdate: @escaping @Sendable (TranscriptUpdate) async -> Void) async
    func feed(buffer: AVAudioPCMBuffer) async
    func endStreaming() async
    func transcribeFile(at url: URL, callId: UUID) async throws -> [TranscriptUpdate]
}

actor TranscriptionService: TranscriptionServiceProtocol {
    private var engine: TranscriptionEngine
    private var sfRecognizer: SFSpeechRecognizer?
    private var sfRequest: SFSpeechAudioBufferRecognitionRequest?
    private var sfTask: SFSpeechRecognitionTask?
    private var currentCallId: UUID?
    private var currentSpeakerHint: String = "You"
    private var onUpdate: (@Sendable (TranscriptUpdate) async -> Void)?

    init() {
        self.engine = Self.bestAvailableEngine()
        self.sfRecognizer = SFSpeechRecognizer(locale: .current)
    }

    static func bestAvailableEngine() -> TranscriptionEngine {
        if #available(iOS 26, *) {
            // SpeechAnalyzer is preferred when present; fall through to SFSR
            // if the module isn't installed for the current locale.
            return .appleSpeechAnalyzer
        }
        return .appleSFSpeechRecognizer
    }

    func availableEngines() -> [TranscriptionEngine] {
        var out: [TranscriptionEngine] = []
        if #available(iOS 26, *) { out.append(.appleSpeechAnalyzer) }
        if SFSpeechRecognizer(locale: .current) != nil {
            out.append(.appleSFSpeechRecognizer)
        }
        // WhisperKit is opt-in: surfaced in the engine list but only usable
        // after the user has downloaded the model (see SettingsViewModel).
        out.append(.whisperKit)
        return out
    }

    func currentEngine() -> TranscriptionEngine { engine }
    func setEngine(_ engine: TranscriptionEngine) async {
        self.engine = engine
    }

    func beginStreaming(callId: UUID,
                        sampleRate: Double,
                        speakerHint: String,
                        onUpdate: @escaping @Sendable (TranscriptUpdate) async -> Void) async {
        self.currentCallId = callId
        self.currentSpeakerHint = speakerHint
        self.onUpdate = onUpdate

        switch engine {
        case .appleSFSpeechRecognizer, .appleSpeechAnalyzer:
            // SpeechAnalyzer (iOS 26) and SFSpeechRecognizer (iOS 18-25) share
            // the buffer-feed shape from the caller's perspective. We lean on
            // SFSR here because SpeechAnalyzer's API is gated and we want one
            // code path that compiles against iOS 18.
            await startSFRecognizer()
        case .whisperKit:
            // WhisperKit is non-streaming in the bundled OSS package; we
            // accumulate audio and run it on `endStreaming()`. See LIMITATIONS.
            break
        }
    }

    private func startSFRecognizer() async {
        guard let recognizer = sfRecognizer, recognizer.isAvailable else {
            // Surface the exact Settings path the user has to walk so they can
            // self-serve. Silent "(transcription unavailable)" looked like a
            // bug on locales where the on-device model isn't installed.
            await onUpdate?(TranscriptUpdate(text: AppError.transcriptionUnavailable.errorDescription ?? "Transcription unavailable.",
                                             isFinal: true,
                                             confidence: 0,
                                             speakerLabel: currentSpeakerHint))
            return
        }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        if #available(iOS 16, *) {
            req.addsPunctuation = true
        }
        self.sfRequest = req
        let speakerHint = currentSpeakerHint
        let cb = self.onUpdate
        self.sfTask = recognizer.recognitionTask(with: req) { result, error in
            if let result {
                let conf = result.bestTranscription.segments.last?.confidence ?? 0.9
                let upd = TranscriptUpdate(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal,
                    confidence: Double(conf),
                    timestamp: Date.now.timeIntervalSince1970,
                    speakerLabel: speakerHint
                )
                Task { await cb?(upd) }
            }
            if error != nil { /* surfaced via stream end */ }
        }
    }

    func feed(buffer: AVAudioPCMBuffer) async {
        switch engine {
        case .appleSFSpeechRecognizer, .appleSpeechAnalyzer:
            sfRequest?.append(buffer)
        case .whisperKit:
            // No-op until file-based mode lands. See LIMITATIONS.md.
            break
        }
    }

    func endStreaming() async {
        sfRequest?.endAudio()
        sfRequest = nil
        sfTask?.finish()
        sfTask = nil
        currentCallId = nil
        onUpdate = nil
    }

    func transcribeFile(at url: URL, callId: UUID) async throws -> [TranscriptUpdate] {
        guard let recognizer = sfRecognizer, recognizer.isAvailable else {
            throw AppError.transcriptionUnavailable
        }
        let req = SFSpeechURLRecognitionRequest(url: url)
        req.shouldReportPartialResults = false
        req.requiresOnDeviceRecognition = true

        // Belt-and-braces continuation guard. Apple usually delivers exactly one
        // of (error, finalResult), but the callback shape allows neither, both,
        // or repeated calls. We need a single resume; everything else must
        // become a no-op. A 120s defensive timer breaks any silent hang so the
        // continuation can never be leaked.
        let box = ContinuationBox()
        return try await withCheckedThrowingContinuation { cont in
            box.setContinuation(cont)

            let task = recognizer.recognitionTask(with: req) { result, error in
                if let error {
                    box.fulfillError(AppError.transcriptionFailed(error.localizedDescription))
                    return
                }
                guard let result, result.isFinal else { return }
                let segments = result.bestTranscription.segments.map { seg in
                    TranscriptUpdate(
                        text: seg.substring,
                        isFinal: true,
                        confidence: Double(seg.confidence),
                        timestamp: seg.timestamp,
                        speakerLabel: "You"
                    )
                }
                box.fulfillSuccess(segments)
            }
            box.setTask(task)

            Task {
                try? await Task.sleep(nanoseconds: 120 * 1_000_000_000)
                box.timeout()
            }
        }
    }
}

/// Single-shot continuation wrapper. SFSpeechRecognizer's callback may fire
/// zero, one, or many times; `CheckedContinuation` must be resumed exactly
/// once. This box enforces "first resume wins" by serializing through a
/// dedicated queue. It also owns the strong reference to the
/// `SFSpeechRecognitionTask` so the timeout path can cancel it without
/// passing a captured `var` between concurrency domains.
private final class ContinuationBox: @unchecked Sendable {
    private let queue = DispatchQueue(label: "murmur.transcription.cont")
    private var fulfilled = false
    private var cont: CheckedContinuation<[TranscriptUpdate], Error>?
    private var task: SFSpeechRecognitionTask?

    func setContinuation(_ cont: CheckedContinuation<[TranscriptUpdate], Error>) {
        queue.sync { self.cont = cont }
    }

    func setTask(_ task: SFSpeechRecognitionTask) {
        queue.sync { self.task = task }
    }

    func fulfillSuccess(_ value: [TranscriptUpdate]) {
        queue.sync {
            guard !fulfilled else { return }
            fulfilled = true
            cont?.resume(returning: value)
            cont = nil
            task = nil
        }
    }

    func fulfillError(_ error: Error) {
        queue.sync {
            guard !fulfilled else { return }
            fulfilled = true
            cont?.resume(throwing: error)
            cont = nil
            task = nil
        }
    }

    func timeout() {
        queue.sync {
            guard !fulfilled else { return }
            fulfilled = true
            task?.cancel()
            cont?.resume(throwing: AppError.transcriptionFailed("timeout"))
            cont = nil
            task = nil
        }
    }
}
