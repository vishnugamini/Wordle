import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppSettingsStore {
    private let context: ModelContext
    @ObservationIgnored private var record: StoredSettings?
    private var isLoading = false

    var hapticsEnabled = true {
        didSet { persistIfNeeded() }
    }
    var colorBlindMode = false {
        didSet { persistIfNeeded() }
    }
    var reduceMotion = false {
        didSet { persistIfNeeded() }
    }
    var hasSeenHowToPlay = false {
        didSet { persistIfNeeded() }
    }

    init(context: ModelContext) {
        self.context = context
        load()
    }

    func effectiveReduceMotion(systemReduceMotion: Bool) -> Bool {
        systemReduceMotion || reduceMotion
    }

    func markHowToPlaySeen() {
        guard !hasSeenHowToPlay else { return }
        hasSeenHowToPlay = true
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<StoredSettings>(predicate: #Predicate { $0.id == "settings" })
        let stored = (try? context.fetch(descriptor).first) ?? nil
        let resolved = stored ?? StoredSettings()

        if stored == nil {
            context.insert(resolved)
            try? context.save()
        }

        record = resolved
        hapticsEnabled = resolved.hapticsEnabled
        colorBlindMode = resolved.colorBlindMode
        reduceMotion = resolved.reduceMotion
        hasSeenHowToPlay = resolved.hasSeenHowToPlay
    }

    private func persistIfNeeded() {
        guard !isLoading else { return }
        persist()
    }

    private func persist() {
        let current = record ?? StoredSettings()
        current.hapticsEnabled = hapticsEnabled
        current.colorBlindMode = colorBlindMode
        current.reduceMotion = reduceMotion
        current.hasSeenHowToPlay = hasSeenHowToPlay

        if record == nil {
            context.insert(current)
            record = current
        }

        try? context.save()
    }
}
