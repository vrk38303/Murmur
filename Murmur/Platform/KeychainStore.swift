import Foundation
import Security

/// Thin Keychain wrapper. We store one symmetric key for at-rest encryption.
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` matches the PRD: keys are
/// non-syncable and only available when the device is unlocked.
enum KeychainStore {
    static let service = "app.murmur.encryption"
    static let account = "audio-aes-256-gcm"

    static func loadOrCreateKey(byteCount: Int = 32) throws -> Data {
        if let existing = try? load(account: account) { return existing }
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard status == errSecSuccess else {
            throw AppError.encryptionFailed("could not generate random bytes")
        }
        let data = Data(bytes)
        try save(data, account: account)
        return data
    }

    static func deleteKey() throws {
        try delete(account: account)
    }

    private static func load(account: String) throws -> Data {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound {
            throw AppError.encryptionFailed("key missing")
        }
        guard status == errSecSuccess, let data = out as? Data else {
            throw AppError.encryptionFailed("keychain status \(status)")
        }
        return data
    }

    private static func save(_ data: Data, account: String) throws {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(q as CFDictionary) // remove any stale
        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.encryptionFailed("keychain add status \(status)")
        }
    }

    private static func delete(account: String) throws {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let status = SecItemDelete(q as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.encryptionFailed("keychain delete status \(status)")
        }
    }
}
