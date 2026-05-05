import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Builds the export `.zip` per PRD §11.1.
///
/// We use `NSFileCoordinator` with `.forUploading` reading intent to produce
/// a real `.zip` from the staging directory — that's the documented iOS-stdlib
/// path for "give me a single archive of this folder", available since iOS 11
/// and used by AirDrop/Mail/Files for the same purpose. No third-party zip
/// library required.
///
/// The returned URL points to the `.zip` file itself. Callers that share via
/// `UIActivityViewController` or `UIDocumentInteractionController` get a single
/// file (good UX) instead of a directory (which most share targets reject).
struct ExportBundle: Sendable {
    /// URL of the produced `.zip` archive.
    let archiveURL: URL

    /// Backwards-compatible alias. Prior code referred to this as
    /// `directoryURL`; it now points at the `.zip` file. Kept so existing
    /// call sites in `SettingsViewModel` keep compiling without coordinated
    /// changes.
    var directoryURL: URL { archiveURL }
}

actor ExportService {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// Actor-local context — `ModelContainer` is Sendable, `ModelContext` is
    /// not, so we keep contexts scoped to the call site.
    private func newContext() -> ModelContext { ModelContext(container) }

    /// Produces a single `.zip` archive containing calls.json,
    /// transcripts.json, topics.json, mindmap.json and (optionally) the
    /// decrypted audio. Caller can hand the returned URL to
    /// UIActivityViewController / UIDocumentInteractionController.
    func exportEverything(includeAudio: Bool) async throws -> ExportBundle {
        let ctx = newContext()
        let calls = try ctx.fetch(FetchDescriptor<CallEntity>())
        let segments = try ctx.fetch(FetchDescriptor<TranscriptSegmentEntity>())
        let topics = try ctx.fetch(FetchDescriptor<TopicEntity>())
        let edges = try ctx.fetch(FetchDescriptor<MindMapEdgeEntity>())

        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let dir = URL.temporaryDirectory
            .appending(path: "MurmurExport-\(stamp)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        try encoder.encode(calls.map(CallExport.init)).write(to: dir.appending(path: "calls.json"))
        try encoder.encode(segments.map(SegmentExport.init)).write(to: dir.appending(path: "transcripts.json"))
        try encoder.encode(topics.map(TopicExport.init)).write(to: dir.appending(path: "topics.json"))
        try encoder.encode(edges.map(EdgeExport.init)).write(to: dir.appending(path: "mindmap.json"))

        if includeAudio {
            let audioDir = dir.appending(path: "audio", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
            for c in calls {
                guard !c.audioFileName.isEmpty else { continue }
                let plain = try await EncryptedFileStore.shared.decryptToTempFile(fileName: c.audioFileName)
                let dst = audioDir.appending(path: "\(c.id.uuidString).wav")
                try? FileManager.default.removeItem(at: dst)
                try FileManager.default.moveItem(at: plain, to: dst)
            }
        }

        let archive = try zipDirectory(at: dir, archiveName: "MurmurExport-\(stamp).zip")
        // Once we have the archive, the staging directory is just bytes on
        // disk — clean up so two exports in a row don't pile up under tmp.
        try? FileManager.default.removeItem(at: dir)
        return ExportBundle(archiveURL: archive)
    }

    /// Produce a real `.zip` archive of `directory` using NSFileCoordinator's
    /// `.forUploading` reading intent. Returns the URL of the resulting zip
    /// (placed in `tmp/` so the share sheet can hand it to other apps).
    private func zipDirectory(at directory: URL, archiveName: String) throws -> URL {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var producedURL: URL?
        var moveError: Error?

        let destination = URL.temporaryDirectory.appending(path: archiveName)
        try? FileManager.default.removeItem(at: destination)

        coordinator.coordinate(readingItemAt: directory,
                               options: [.forUploading],
                               error: &coordError) { tempZipURL in
            // `tempZipURL` is a system-managed temp file that is reclaimed
            // when this closure returns. Move it to a stable location so the
            // share sheet can reference it after the closure exits.
            do {
                try FileManager.default.moveItem(at: tempZipURL, to: destination)
                producedURL = destination
            } catch {
                moveError = error
            }
        }

        if let coordError {
            throw AppError.exportFailed("Could not zip export: \(coordError.localizedDescription)")
        }
        if let moveError {
            throw AppError.exportFailed("Could not move zip into place: \(moveError.localizedDescription)")
        }
        guard let producedURL else {
            throw AppError.exportFailed("Zip coordinator returned no URL")
        }
        return producedURL
    }

    /// Wipe everything: SwiftData store, encrypted audio, encryption key.
    /// Caller must Face-ID-confirm first (PermissionsManager).
    func nuke() async throws {
        let ctx = newContext()
        for c in try ctx.fetch(FetchDescriptor<CallEntity>()) { ctx.delete(c) }
        for s in try ctx.fetch(FetchDescriptor<TranscriptSegmentEntity>()) { ctx.delete(s) }
        for t in try ctx.fetch(FetchDescriptor<TopicEntity>()) { ctx.delete(t) }
        for e in try ctx.fetch(FetchDescriptor<MindMapEdgeEntity>()) { ctx.delete(e) }
        try ctx.save()
        try await EncryptedFileStore.shared.wipeEverything()
        try? KeychainStore.deleteKey()
    }
}

// MARK: - DTOs (avoid leaking SwiftData internals into the export)

private struct CallExport: Codable {
    let id: UUID
    let title: String
    let contactName: String?
    let startedAt: Date
    let durationSeconds: Double
    let summary: String?
    let keyPoints: [String]
    let actionItems: [ActionItem]
    let sentiment: String?
    let processingState: String

    init(_ c: CallEntity) {
        self.id = c.id
        self.title = c.title
        self.contactName = c.contactName
        self.startedAt = c.startedAt
        self.durationSeconds = c.durationSeconds
        self.summary = c.summary
        self.keyPoints = c.keyPoints
        self.actionItems = c.actionItems
        self.sentiment = c.sentimentLabel
        self.processingState = c.processingStateRaw
    }
}

private struct SegmentExport: Codable {
    let id: UUID
    let callId: UUID
    let startTimeSeconds: Double
    let endTimeSeconds: Double
    let speakerLabel: String
    let text: String
    let confidence: Double

    init(_ s: TranscriptSegmentEntity) {
        self.id = s.id
        self.callId = s.callId
        self.startTimeSeconds = s.startTimeSeconds
        self.endTimeSeconds = s.endTimeSeconds
        self.speakerLabel = s.speakerLabel
        self.text = s.text
        self.confidence = s.confidence
    }
}

private struct TopicExport: Codable {
    let id: UUID
    let label: String
    /// Embeddings are exported as base64-encoded packed Float32 (PRD §11.1).
    let embeddingBase64: String
    let importance: Int
    let callIds: [UUID]

    init(_ t: TopicEntity) {
        self.id = t.id
        self.label = t.label
        self.embeddingBase64 = TopicExport.encode(t.embedding)
        self.importance = t.importance
        self.callIds = t.calls.map(\.id)
    }

    private static func encode(_ floats: [Float]) -> String {
        let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
        return data.base64EncodedString()
    }
}

private struct EdgeExport: Codable {
    let id: UUID
    let source: UUID
    let sourceType: String
    let target: UUID
    let targetType: String
    let weight: Double
    let isUserCreated: Bool

    init(_ e: MindMapEdgeEntity) {
        self.id = e.id
        self.source = e.sourceNodeId
        self.sourceType = e.sourceNodeTypeRaw
        self.target = e.targetNodeId
        self.targetType = e.targetNodeTypeRaw
        self.weight = e.weight
        self.isUserCreated = e.isUserCreated
    }
}
