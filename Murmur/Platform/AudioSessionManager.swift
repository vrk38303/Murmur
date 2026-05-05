import Foundation
import AVFoundation

/// Owns the `AVAudioSession` lifecycle. Configured per PRD §5.1: playAndRecord
/// + voiceChat + bluetooth + defaultToSpeaker + mixWithOthers (so we can
/// record while another VoIP / phone app is using the audio session).
actor AudioSessionManager {
    static let shared = AudioSessionManager()

    private var isActive = false

    func activate() throws {
        let s = AVAudioSession.sharedInstance()
        try s.setCategory(.playAndRecord,
                          mode: .voiceChat,
                          options: [.allowBluetooth, .defaultToSpeaker, .mixWithOthers])
        try s.setActive(true, options: .notifyOthersOnDeactivation)
        isActive = true
    }

    func deactivate() {
        let s = AVAudioSession.sharedInstance()
        try? s.setActive(false, options: .notifyOthersOnDeactivation)
        isActive = false
    }

    func currentInputSampleRate() -> Double {
        AVAudioSession.sharedInstance().sampleRate
    }
}
