import Foundation
import CryptoKit

/// AES-256-GCM at-rest encryption for audio recordings. Files live under
/// `Application Support/Murmur/audio/`. We append a random 12-byte nonce and
/// a 16-byte auth tag inside the saved blob via `SealedBox.combined`.
///
/// Streaming writes (during recording) buffer chunks to a plaintext temp file
/// inside the app sandbox, then encrypt the whole file on `finalize()`. This
/// keeps the recorder's hot path simple and audits well.
actor EncryptedFileStore {
    static let shared = EncryptedFileStore()

    private let fm = FileManager.default

    func encryptedDirectory() throws -> URL {
        let dir = URL.applicationSupportDirectory
            .appending(path: "Murmur", directoryHint: .isDirectory)
            .appending(path: "audio", directoryHint: .isDirectory)
        if !fm.fileExists(atPath: dir.path()) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true,
                                   attributes: [.protectionKey: FileProtectionType.complete])
        }
        return dir
    }

    func plaintextStagingURL(callId: UUID) throws -> URL {
        let staging = URL.cachesDirectory
            .appending(path: "Murmur", directoryHint: .isDirectory)
            .appending(path: "staging", directoryHint: .isDirectory)
        if !fm.fileExists(atPath: staging.path()) {
            try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        }
        return staging.appending(path: "\(callId.uuidString).wav")
    }

    /// Encrypt a plaintext file into the encrypted directory, deleting the
    /// plaintext source. Returns the file *name* (not URL) so the entity
    /// stays portable across installs.
    func encrypt(plaintextAt src: URL, fileName: String) throws -> String {
        let key = SymmetricKey(data: try KeychainStore.loadOrCreateKey())
        let plaintext = try Data(contentsOf: src)
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw AppError.encryptionFailed("nil combined sealed box")
        }
        let dst = try encryptedDirectory().appending(path: fileName)
        try combined.write(to: dst, options: [.atomic, .completeFileProtection])
        try? fm.removeItem(at: src)
        return fileName
    }

    func decrypt(fileName: String) throws -> Data {
        let key = SymmetricKey(data: try KeychainStore.loadOrCreateKey())
        let url = try encryptedDirectory().appending(path: fileName)
        let blob = try Data(contentsOf: url)
        let box = try AES.GCM.SealedBox(combined: blob)
        return try AES.GCM.open(box, using: key)
    }

    /// Decrypt to a temporary file (used for export and playback). The caller
    /// is responsible for cleaning up the returned URL.
    func decryptToTempFile(fileName: String) throws -> URL {
        let data = try decrypt(fileName: fileName)
        let tmp = URL.temporaryDirectory.appending(path: "play-\(UUID().uuidString).wav")
        try data.write(to: tmp, options: [.atomic])
        return tmp
    }

    func deleteEncrypted(fileName: String) throws {
        let url = try encryptedDirectory().appending(path: fileName)
        if fm.fileExists(atPath: url.path()) {
            try fm.removeItem(at: url)
        }
    }

    func wipeEverything() throws {
        let dir = try encryptedDirectory()
        let items = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for u in items { try? fm.removeItem(at: u) }
    }

    /// Janitor: deletes any plaintext WAVs left in the staging directory by a
    /// previous crash. Call once on app launch. Privacy promise: plaintext
    /// audio must never live longer than the recording session that produced
    /// it.
    func cleanStagingOnLaunch() async {
        let staging = URL.cachesDirectory
            .appending(path: "Murmur", directoryHint: .isDirectory)
            .appending(path: "staging", directoryHint: .isDirectory)
        guard fm.fileExists(atPath: staging.path()) else { return }
        let items = (try? fm.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil)) ?? []
        for u in items { try? fm.removeItem(at: u) }
    }
}
