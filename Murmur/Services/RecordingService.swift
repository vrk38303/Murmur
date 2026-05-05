import Foundation
import AVFoundation

/// AVAudioPCMBuffer is not declared `Sendable` by Apple, but it is in practice
/// safe to pass between actors as long as the buffer is no longer mutated by
/// the producer after handoff — which is the case here, because each tap
/// callback receives a fresh buffer that AVFoundation will not touch again.
extension AVAudioPCMBuffer: @unchecked Sendable {}
extension AVAudioFormat: @unchecked Sendable {}

protocol RecordingServiceProtocol: Sendable {
    func start(consentConfirmed: Bool, contactName: String?) async throws -> UUID
    func pause() async
    func resume() async throws
    func stop() async throws -> RecordingResult
    var liveAudioLevels: AsyncStream<Float> { get async }
    var livePartialTranscripts: AsyncStream<TranscriptUpdate> { get async }
}

struct RecordingResult: Sendable {
    let callId: UUID
    let audioFileName: String
    let duration: TimeInterval
    let sampleRate: Double
    let bitDepth: Int
    let consentRecorded: Bool
}

actor RecordingService: RecordingServiceProtocol {
    enum State: Equatable { case idle, recording, paused }

    private let engine = AVAudioEngine()
    private var inputFormat: AVAudioFormat?
    private var targetFormat: AVAudioFormat?
    /// Cached for the lifetime of a recording session. Allocating an
    /// `AVAudioConverter` per buffer was producing ~16 allocations/second on
    /// 1024-frame taps, which both wasted heap and discarded the converter's
    /// internal resampler state between buffers.
    private var converter: AVAudioConverter?
    private var fileWriter: AVAudioFile?
    private var stagingURL: URL?
    private var state: State = .idle
    private var startedAt: Date?
    private var elapsedBeforePause: TimeInterval = 0
    private var consentConfirmed: Bool = false
    private var currentCallId: UUID?

    // Async streams the UI subscribes to.
    private var levelContinuation: AsyncStream<Float>.Continuation?
    private var transcriptContinuation: AsyncStream<TranscriptUpdate>.Continuation?
    private var levelStream: AsyncStream<Float>?
    private var transcriptStream: AsyncStream<TranscriptUpdate>?

    // Wired in by ServiceContainer.
    private var transcription: TranscriptionService?

    // Interruption handling: stored token for the AVAudioSession notification.
    private var interruptionObserver: NSObjectProtocol?

    init(transcription: TranscriptionService? = nil) {
        self.transcription = transcription
    }

    func attach(transcription: TranscriptionService) {
        self.transcription = transcription
    }

    var liveAudioLevels: AsyncStream<Float> {
        get async {
            if let levelStream { return levelStream }
            let (stream, cont) = AsyncStream<Float>.makeStream(bufferingPolicy: .bufferingNewest(8))
            self.levelStream = stream
            self.levelContinuation = cont
            return stream
        }
    }

    var livePartialTranscripts: AsyncStream<TranscriptUpdate> {
        get async {
            if let transcriptStream { return transcriptStream }
            let (stream, cont) = AsyncStream<TranscriptUpdate>.makeStream(bufferingPolicy: .bufferingNewest(32))
            self.transcriptStream = stream
            self.transcriptContinuation = cont
            return stream
        }
    }

    func start(consentConfirmed: Bool, contactName: String?) async throws -> UUID {
        guard state == .idle else { return currentCallId ?? UUID() }

        try await AudioSessionManager.shared.activate()
        let callId = UUID()
        self.currentCallId = callId
        self.consentConfirmed = consentConfirmed

        let staging = try await EncryptedFileStore.shared.plaintextStagingURL(callId: callId)
        self.stagingURL = staging

        let input = engine.inputNode
        let nativeFormat = input.outputFormat(forBus: 0)
        // Target: 16 kHz mono 16-bit PCM (PRD §5.2). We let AVAudioEngine
        // resample on the tap by writing to a file format that differs from
        // the tap format.
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                               sampleRate: 16_000,
                                               channels: 1,
                                               interleaved: true) else {
            throw AppError.audioEngineFailed("could not build target audio format")
        }
        self.inputFormat = nativeFormat
        self.targetFormat = targetFormat
        // Build the converter once per recording session. Skipped when the
        // tap already happens to deliver our exact target format (rare, but
        // possible on hardware that runs at 16 kHz int16 natively).
        if nativeFormat != targetFormat {
            guard let conv = AVAudioConverter(from: nativeFormat, to: targetFormat) else {
                throw AppError.audioEngineFailed("could not build audio converter")
            }
            self.converter = conv
        } else {
            self.converter = nil
        }

        let writerSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        self.fileWriter = try AVAudioFile(forWriting: staging,
                                          settings: writerSettings,
                                          commonFormat: .pcmFormatInt16,
                                          interleaved: true)

        // Tap input — buffer size 1024 frames per PRD §5.2.
        input.installTap(onBus: 0, bufferSize: 1024, format: nativeFormat) { [weak self] buffer, _ in
            guard let self else { return }
            Task { await self.handle(buffer: buffer) }
        }

        try engine.start()
        startedAt = .now
        state = .recording

        observeInterruptions()
        await transcription?.beginStreaming(callId: callId,
                                            sampleRate: 16_000,
                                            speakerHint: "You") { [weak self] update in
            await self?.transcriptContinuation?.yield(update)
        }
        return callId
    }

    func pause() async {
        guard state == .recording else { return }
        engine.pause()
        if let startedAt {
            elapsedBeforePause += Date.now.timeIntervalSince(startedAt)
        }
        startedAt = nil
        state = .paused
    }

    func resume() async throws {
        guard state == .paused else { return }
        try engine.start()
        startedAt = .now
        state = .recording
    }

    func stop() async throws -> RecordingResult {
        guard state != .idle else {
            throw AppError.audioEngineFailed("not recording")
        }
        // Order of operations: removing the tap first prevents AVAudioEngine
        // from delivering more buffers; stopping the engine drains any
        // in-flight ones the OS already had queued. We then yield once so
        // any buffer Task scheduled (but not yet executed) before
        // removeTap gets a chance to land its `fileWriter.write(...)`
        // before we nil out the writer.
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // One Task.yield isn't a guarantee — the buffer Task could be
        // queued behind unrelated work. But it's a meaningful nudge in
        // practice and the worst case (a single dropped trailing
        // buffer ≈ 64 ms of audio at 16 kHz) is acceptable for a
        // 1+ minute recording. If we see truncation in the field, swap
        // to a serial buffer-write pipeline rather than fan-out Tasks.
        await Task.yield()

        if let startedAt {
            elapsedBeforePause += Date.now.timeIntervalSince(startedAt)
        }
        let duration = elapsedBeforePause
        elapsedBeforePause = 0

        await transcription?.endStreaming()

        // Encrypt the staging WAV into the encrypted directory.
        guard let staging = stagingURL, let callId = currentCallId else {
            throw AppError.audioEngineFailed("missing staging URL")
        }
        let fileName = "\(callId.uuidString).wav.enc"
        let saved = try await EncryptedFileStore.shared.encrypt(plaintextAt: staging,
                                                                fileName: fileName)
        await AudioSessionManager.shared.deactivate()
        removeInterruptionObserver()

        // Reset state for the next session.
        let result = RecordingResult(callId: callId,
                                     audioFileName: saved,
                                     duration: duration,
                                     sampleRate: 16_000,
                                     bitDepth: 16,
                                     consentRecorded: consentConfirmed)
        state = .idle
        currentCallId = nil
        stagingURL = nil
        fileWriter = nil
        converter = nil
        targetFormat = nil
        return result
    }

    // MARK: - Buffer pipeline

    private func handle(buffer: AVAudioPCMBuffer) async {
        guard let fileWriter, let target = targetFormat else { return }
        // Convert to target format if necessary, then write + emit level + forward to STT.
        let converted: AVAudioPCMBuffer?
        if buffer.format == target {
            converted = buffer
        } else {
            converted = convert(buffer: buffer, to: target)
        }
        guard let converted else { return }
        do { try fileWriter.write(from: converted) } catch { /* lossy on write fail */ }
        emitLevel(from: converted)
        await transcription?.feed(buffer: converted)
    }

    private func convert(buffer: AVAudioPCMBuffer, to target: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Reuse the session-scoped converter; allocating per buffer was
        // ~16/sec at 1024-frame taps and threw away resampler state every
        // callback (see M1 in QA_REPORT).
        guard let converter else { return nil }
        let ratio = target.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 16)
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return nil }
        var error: NSError?
        var supplied = false
        let status = converter.convert(to: out, error: &error) { _, statusPtr in
            // The block can be called multiple times per `convert` call; on
            // the second invocation we must signal end-of-stream rather than
            // re-handing the same buffer (which produces duplicated frames).
            if supplied {
                statusPtr.pointee = .noDataNow
                return nil
            }
            supplied = true
            statusPtr.pointee = .haveData
            return buffer
        }
        if error != nil { return nil }
        return (status == .haveData || status == .inputRanDry) ? out : nil
    }

    private func emitLevel(from buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.int16ChannelData else { return }
        let n = Int(buffer.frameLength)
        guard n > 0 else { return }
        var sum: Double = 0
        let ptr = channels[0]
        for i in 0..<n {
            let v = Double(ptr[i]) / 32768.0
            sum += v * v
        }
        let rms = sqrt(sum / Double(n))
        levelContinuation?.yield(Float(min(1.0, rms * 4.0))) // scale up — speech is quiet
    }

    // MARK: - Interruptions (PRD §5.4)

    private func observeInterruptions() {
        removeInterruptionObserver()
        let center = NotificationCenter.default
        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: nil
        ) { [weak self] note in
            guard let self else { return }
            Task { await self.handleInterruption(note) }
        }
    }

    private func removeInterruptionObserver() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        interruptionObserver = nil
    }

    private func handleInterruption(_ note: Notification) async {
        guard let info = note.userInfo,
              let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeRaw)
        else { return }
        switch type {
        case .began:
            await pause()
        case .ended:
            let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt).map(AVAudioSession.InterruptionOptions.init(rawValue:)) ?? []
            if opts.contains(.shouldResume) {
                try? await resume()
            } else {
                _ = try? await stop()
            }
        @unknown default: break
        }
    }
}
