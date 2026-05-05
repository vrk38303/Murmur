import XCTest
@testable import Murmur

final class EncryptedFileStoreTests: XCTestCase {
    func testRoundTrip() async throws {
        let store = EncryptedFileStore()
        let plain = "the quick brown fox".data(using: .utf8)!
        let staging = URL.temporaryDirectory.appending(path: "rt-\(UUID().uuidString).wav")
        try plain.write(to: staging)
        let name = "rt-\(UUID().uuidString).enc"
        let saved = try await store.encrypt(plaintextAt: staging, fileName: name)
        let decrypted = try await store.decrypt(fileName: saved)
        XCTAssertEqual(plain, decrypted)
        try await store.deleteEncrypted(fileName: saved)
    }
}
