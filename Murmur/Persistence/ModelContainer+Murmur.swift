import Foundation
import SwiftData

enum MurmurStore {
    static let schema = Schema([
        CallEntity.self,
        TranscriptSegmentEntity.self,
        TopicEntity.self,
        MindMapEdgeEntity.self
    ])

    /// Production container — `.complete` file protection means the SQLite
    /// store is unreadable while the device is locked.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let url = inMemory ? URL(filePath: "/dev/null")
                           : storeURL()
        let config = ModelConfiguration(
            "MurmurStore",
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        try applyFileProtection(to: url)
        return container
    }

    /// Lightweight in-memory container for tests and previews.
    static func previewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // Force-try is acceptable in preview/test factories.
        return try! ModelContainer(for: schema, configurations: [config])
    }

    static func storeURL() -> URL {
        let base = URL.applicationSupportDirectory
            .appending(path: "Murmur", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: base,
                                                 withIntermediateDirectories: true)
        return base.appending(path: "MurmurStore.sqlite")
    }

    private static func applyFileProtection(to url: URL) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path()) else { return }
        try fm.setAttributes([.protectionKey: FileProtectionType.complete],
                             ofItemAtPath: url.path())
    }
}
