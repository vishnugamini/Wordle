import SwiftData
import SwiftUI

@main
struct AureliaWordsApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try Self.makeContainer()
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .modelContainer(container)
        }
    }
}

private extension AureliaWordsApp {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([StoredGame.self, StoredSettings.self])
        let storeURL = try storeURL()
        let configuration = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            try removeStoreArtifacts(at: storeURL)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }

    static func storeURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupport.appendingPathComponent("AureliaWords.store")
    }

    static func removeStoreArtifacts(at storeURL: URL) throws {
        let fm = FileManager.default
        let relatedURLs = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for url in relatedURLs where fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }
}
