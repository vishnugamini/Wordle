import Foundation

enum StoreItemID: String, CaseIterable, Identifiable, Codable {
    case revealLetter = "reveal-letter"
    case removeWrongLetters = "remove-wrong-letters"

    var id: String { rawValue }
}

struct StoreItem: Identifiable, Equatable {
    let id: StoreItemID
    let name: String
    let summary: String
    let price: Int
    let systemImage: String

    static let revealLetter = StoreItem(
        id: .revealLetter,
        name: "Reveal Letter",
        summary: "Pins one correct letter into the current Daily or Practice puzzle.",
        price: 40,
        systemImage: "sparkles.rectangle.stack"
    )

    static let removeWrongLetters = StoreItem(
        id: .removeWrongLetters,
        name: "Remove Wrong Letters",
        summary: "Removes two unused letters that are not in the current Daily or Practice answer.",
        price: 30,
        systemImage: "xmark.circle"
    )

    static let catalog: [StoreItem] = [
        .revealLetter,
        .removeWrongLetters
    ]
}

enum StorePurchaseResult: Equatable {
    case success
    case insufficientCoins
}

enum SkinPurchaseResult: Equatable {
    case success
    case insufficientCoins
    case alreadyOwned
}

enum StoreConsumeResult: Equatable {
    case success
    case unavailable
    case unsupportedMode
}
