import Foundation

/// Single error type surfaced to the UI. Every throw in a service maps into
/// one of these so the user only ever sees one taxonomy.
enum AppError: LocalizedError, Equatable {
    case microphoneDenied
    case speechRecognitionDenied
    case contactsDenied
    case audioEngineFailed(String)
    case audioInterrupted
    case transcriptionUnavailable
    case transcriptionFailed(String)
    case summarizationUnavailable
    case summarizationFailed(String)
    case modelDownloadFailed(String)
    case persistenceFailed(String)
    case encryptionFailed(String)
    case exportFailed(String)
    case faceIDFailed
    case subscriptionFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return String(localized: "error.permission.mic")
        case .speechRecognitionDenied:
            return String(localized: "error.permission.speech")
        case .contactsDenied:
            return "Contacts access was denied. Calls won't be matched to names."
        case .audioEngineFailed(let m):
            return "Audio engine failed: \(m)"
        case .audioInterrupted:
            return "Recording was interrupted. The partial recording was saved."
        case .transcriptionUnavailable:
            return String(localized: "error.transcription.unavailable")
        case .transcriptionFailed(let m):
            return "Transcription failed: \(m)"
        case .summarizationUnavailable:
            return String(localized: "error.summarization.unavailable")
        case .summarizationFailed(let m):
            return "Summarization failed: \(m)"
        case .modelDownloadFailed(let m):
            return "Model download failed: \(m)"
        case .persistenceFailed(let m):
            return "Couldn't save: \(m)"
        case .encryptionFailed(let m):
            return "Encryption failed: \(m)"
        case .exportFailed(let m):
            return "Export failed: \(m)"
        case .faceIDFailed:
            return "Face ID couldn't verify you. Try again."
        case .subscriptionFailed(let m):
            return "Subscription error: \(m)"
        case .unknown(let m):
            return m.isEmpty ? String(localized: "error.generic") : m
        }
    }
}
