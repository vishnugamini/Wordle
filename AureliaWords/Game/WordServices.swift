import Foundation
import UIKit

@MainActor
final class DictionaryDefinitionService: DefinitionProviding {
    func definition(for word: String) async -> WordDefinition? {
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord)")
        else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let entries = try JSONDecoder().decode([DictionaryAPIEntry].self, from: data)
            var meanings: [WordMeaning] = []

            for entry in entries {
                for meaning in entry.meanings {
                    for definition in meaning.definitions {
                        let text = definition.definition.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { continue }
                        meanings.append(
                            WordMeaning(
                                partOfSpeech: meaning.partOfSpeech,
                                text: text
                            )
                        )
                    }
                }

                if !meanings.isEmpty {
                    return WordDefinition(
                        word: entry.word,
                        meanings: meanings,
                        sourceName: "Dictionary API"
                    )
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}

@MainActor
final class PracticeWordGenerator {
    private static let memoryLimit = 4096

    private let words: [String]
    private var generatedHistory: [String] = []
    private var generatedSet: Set<String> = []

    init(words: [String]) {
        self.words = words
    }

    func nextWord(excluding blocked: Set<String>) -> String {
        let freshPool = words.filter { !blocked.contains($0) && !generatedSet.contains($0) }
        let fallbackPool = words.filter { !blocked.contains($0) }
        let fallback = (freshPool.isEmpty ? fallbackPool : freshPool).randomElement()
            ?? words.randomElement()
            ?? "crane"
        remember(fallback)
        return fallback
    }

    private func remember(_ word: String) {
        generatedHistory.append(word)
        generatedSet.insert(word)

        if generatedHistory.count > Self.memoryLimit {
            let expired = generatedHistory.removeFirst()
            generatedSet.remove(expired)
        }
    }
}

private struct DictionaryAPIEntry: Decodable {
    let word: String
    let meanings: [DictionaryAPIMeaning]
}

private struct DictionaryAPIMeaning: Decodable {
    let partOfSpeech: String?
    let definitions: [DictionaryAPIDefinition]
}

private struct DictionaryAPIDefinition: Decodable {
    let definition: String
}
