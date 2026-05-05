import Foundation
import AVFoundation
import Speech
import Contacts
import LocalAuthentication

enum PermissionStatus: String {
    case notDetermined, granted, denied, restricted
}

@MainActor
final class PermissionsManager {
    static let shared = PermissionsManager()

    func microphoneStatus() -> PermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined: .notDetermined
        case .denied: .denied
        case .granted: .granted
        @unknown default: .notDetermined
        }
    }

    func requestMicrophone() async -> PermissionStatus {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { ok in
                cont.resume(returning: ok ? .granted : .denied)
            }
        }
    }

    func speechStatus() -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined: .notDetermined
        case .authorized:    .granted
        case .denied:        .denied
        case .restricted:    .restricted
        @unknown default:    .notDetermined
        }
    }

    func requestSpeech() async -> PermissionStatus {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                let mapped: PermissionStatus = switch status {
                case .authorized:    .granted
                case .denied:        .denied
                case .restricted:    .restricted
                case .notDetermined: .notDetermined
                @unknown default:    .notDetermined
                }
                cont.resume(returning: mapped)
            }
        }
    }

    func contactsStatus() -> PermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined: .notDetermined
        case .denied:        .denied
        case .restricted:    .restricted
        case .authorized, .limited: .granted
        @unknown default:    .notDetermined
        }
    }

    func requestContacts() async -> PermissionStatus {
        do {
            let ok = try await CNContactStore().requestAccess(for: .contacts)
            return ok ? .granted : .denied
        } catch {
            return .denied
        }
    }

    /// Face ID gate for destructive actions (delete-all). Falls back to
    /// passcode if biometrics aren't enrolled.
    func confirmWithBiometrics(reason: String) async throws {
        let ctx = LAContext()
        var nsError: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication
        guard ctx.canEvaluatePolicy(policy, error: &nsError) else {
            throw AppError.faceIDFailed
        }
        let ok = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            ctx.evaluatePolicy(policy, localizedReason: reason) { success, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: success) }
            }
        }
        if !ok { throw AppError.faceIDFailed }
    }
}
