import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class LiveRecordingViewModel {
    enum State: Equatable { case idle, recording, paused, processing }

    var state: State = .idle
    var elapsed: TimeInterval = 0
    var contactName: String? = nil
    var levels: [CGFloat] = Array(repeating: 0.4, count: 28)
    var liveText: String = ""
    var error: AppError?
    var processingProgress: ProcessingProgress = .init()

    private let services: ServiceContainer
    private var callId: UUID?
    private var startedAt: Date?
    private var ticker: Task<Void, Never>?
    private var levelTask: Task<Void, Never>?
    private var transcriptTask: Task<Void, Never>?
    private var aggregatedSegments: [TranscriptUpdate] = []

    init(services: ServiceContainer) {
        self.services = services
    }

    func start() async {
        services.subscriptions.recordRecordingStart()
        do {
            let id = try await services.recording.start(
                consentConfirmed: services.consent.alwaysRemind,
                contactName: contactName
            )
            self.callId = id
            self.startedAt = .now
            self.state = .recording
            startTicker()
            await subscribeToStreams()
        } catch {
            self.error = (error as? AppError) ?? .audioEngineFailed("\(error)")
        }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard let self else { return }
                if self.state == .recording, let started = self.startedAt {
                    self.elapsed = Date.now.timeIntervalSince(started)
                }
            }
        }
    }

    private func subscribeToStreams() async {
        let levelStream = await services.recording.liveAudioLevels
        let transcriptStream = await services.recording.livePartialTranscripts

        levelTask = Task { [weak self] in
            for await rms in levelStream {
                guard let self else { return }
                await MainActor.run {
                    let n = self.levels.count
                    var bars = self.levels
                    bars.removeFirst()
                    bars.append(CGFloat(rms))
                    // Smooth — per the design's stylised animation.
                    for i in 0..<n {
                        let phase = Double(i) * 0.7 + Double(rms) * 5.0
                        let modulated = 0.35 + 0.55 * abs(sin(phase) * cos(phase * 0.4))
                        bars[i] = CGFloat(min(1.0, max(Double(bars[i]) * 0.7, modulated * Double(rms))))
                    }
                    self.levels = bars
                }
            }
        }

        transcriptTask = Task { [weak self] in
            for await update in transcriptStream {
                guard let self else { return }
                await MainActor.run {
                    self.liveText = update.text
                    if update.isFinal {
                        self.aggregatedSegments.append(update)
                    }
                }
            }
        }
    }

    func pause() async {
        await services.recording.pause()
        state = .paused
    }

    func resume() async {
        do {
            try await services.recording.resume()
            state = .recording
        } catch {
            self.error = .audioEngineFailed("\(error)")
        }
    }

    func stop() async {
        ticker?.cancel(); ticker = nil
        levelTask?.cancel(); levelTask = nil
        transcriptTask?.cancel(); transcriptTask = nil

        do {
            let result = try await services.recording.stop()
            state = .processing
            processingProgress = .init()
            try await finalize(result: result)
        } catch {
            self.error = (error as? AppError) ?? .audioEngineFailed("\(error)")
        }
    }

    private func finalize(result: RecordingResult) async throws {
        let ctx = ModelContext(services.modelContainer)
        let title = contactName ?? "Conversation \(formatDate(.now))"
        let call = CallEntity(
            id: result.callId,
            title: title,
            contactName: contactName,
            startedAt: startedAt ?? .now,
            endedAt: .now,
            durationSeconds: result.duration,
            audioFileName: result.audioFileName,
            audioDurationSeconds: result.duration,
            sampleRate: result.sampleRate,
            bitDepth: result.bitDepth,
            processingState: .transcribing,
            consentRecorded: result.consentRecorded
        )
        ctx.insert(call)
        // Save aggregated final segments.
        for (i, seg) in aggregatedSegments.enumerated() {
            let entity = TranscriptSegmentEntity(
                id: seg.segmentId,
                callId: call.id,
                startTimeSeconds: Double(i) * 6.0,
                endTimeSeconds: Double(i + 1) * 6.0,
                speakerLabel: seg.speakerLabel,
                text: seg.text,
                confidence: seg.confidence,
                call: call
            )
            ctx.insert(entity)
        }
        try ctx.save()
        processingProgress.transcribed = true

        // Run summarization.
        do {
            let segments = call.transcriptSegments
            let summary = try await services.summarization.summarize(
                transcript: segments,
                contactName: contactName
            )
            call.summary = summary.summary
            call.keyPoints = summary.keyPoints
            call.actionItems = summary.actionItems
            call.sentimentLabel = summary.sentiment.rawValue
            call.processingState = .summarizing
            try ctx.save()
            processingProgress.summarized = true

            try await services.mindMap.attachCallToTopics(callId: call.id,
                                                          topicLabels: summary.topics)
            call.processingState = .complete
            try ctx.save()
            processingProgress.linkedToMap = true
        } catch {
            call.processingState = .failed
            call.processingError = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            try? ctx.save()
            self.error = (error as? AppError) ?? .summarizationFailed("\(error)")
        }
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: d)
    }

    func cleanup() {
        ticker?.cancel(); ticker = nil
        levelTask?.cancel(); levelTask = nil
        transcriptTask?.cancel(); transcriptTask = nil
    }
}

struct ProcessingProgress: Hashable {
    var transcribed = false
    var summarized = false
    var linkedToMap = false
}
