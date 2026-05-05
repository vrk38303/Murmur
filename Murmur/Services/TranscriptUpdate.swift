import Foundation

struct TranscriptUpdate: Sendable, Hashable {
    let segmentId: UUID
    let text: String
    let isFinal: Bool
    let confidence: Double
    let timestamp: TimeInterval
    let speakerLabel: String

    init(segmentId: UUID = UUID(),
         text: String,
         isFinal: Bool,
         confidence: Double = 0.9,
         timestamp: TimeInterval = 0,
         speakerLabel: String = "You") {
        self.segmentId = segmentId
        self.text = text
        self.isFinal = isFinal
        self.confidence = confidence
        self.timestamp = timestamp
        self.speakerLabel = speakerLabel
    }
}

enum TranscriptionEngine: String, Codable, CaseIterable, Sendable {
    case appleSpeechAnalyzer    // iOS 26+
    case appleSFSpeechRecognizer // iOS 18-25 fallback
    case whisperKit              // opt-in download

    var displayName: String {
        switch self {
        case .appleSpeechAnalyzer:    return "Apple SpeechAnalyzer"
        case .appleSFSpeechRecognizer: return "Apple Speech (legacy)"
        case .whisperKit:             return "Whisper Large V3 (on-device)"
        }
    }
}

/// Speaker diarization modes. Today only `.single` is implemented; the
/// other cases are picker entries that surface a "coming soon" alert and
/// roll back to `.single` rather than silently mislabeling segments. See
/// LIMITATIONS.md "SpeakerKit / diarization" and SettingsViewModel
/// `setDiarizationMode`.
enum DiarizationMode: String, Codable, CaseIterable, Sendable {
    case single       // every segment labeled with the recorder ("You")
    case heuristic    // not implemented
    case pro          // not implemented (gated behind Pro tier when shipped)

    var displayName: String {
        switch self {
        case .single:    return "Single speaker"
        case .heuristic: return "Multi-speaker (coming soon)"
        case .pro:       return "Multi-speaker Pro (coming soon)"
        }
    }

    var isAvailable: Bool { self == .single }
}

enum SummarizationEngine: String, Codable, CaseIterable, Sendable {
    case appleIntelligence
    case bundledMLX
    case cloud

    /// User-facing engine name. We deliberately label `bundledMLX` as
    /// "preview" until the actual MLX runner lands (LIMITATIONS:
    /// "Bundled MLX (Gemma 2 2B 4-bit)") — the current implementation
    /// is a deterministic heuristic, not a real LLM. Lying about that
    /// is a paid-app trust violation and a likely App Review trigger.
    /// Strip "(preview)" from this string the same PR that wires up
    /// `runBundledMLX` to mlx-swift-examples.
    var displayName: String {
        switch self {
        case .appleIntelligence: return "Apple Intelligence"
        case .bundledMLX:        return "Bundled (MLX) — preview"
        case .cloud:             return "Cloud (off by default)"
        }
    }
}
