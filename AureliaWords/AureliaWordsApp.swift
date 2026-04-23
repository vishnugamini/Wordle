import SwiftData
import SwiftUI

@main
struct AureliaWordsApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: StoredGame.self, StoredSettings.self)
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
