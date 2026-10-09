import Foundation

/// Dictionary and character trigram model of one language.
///
/// Both are built from a frequency list: one `word count` pair per line, most frequent first.
public struct LanguageModel: Sendable {
    public let language: String

    private let index: [Character: Int]
    private let size: Int
    private let ranks: [String: Int32]
    private let logProbability: [Float]

    public init(language: String, alphabet: String, wordList: String) {
        self.language = language
        var index: [Character: Int] = [:]
        for (i, letter) in alphabet.enumerated() { index[letter] = i + 1 }
        self.index = index
        let size = alphabet.count + 1
        self.size = size

        var ranks: [String: Int32] = [:]
        var counts = [Float](repeating: 0, count: size * size * size)
        var rank: Int32 = 0
        for line in wordList.split(separator: "\n") {
            let parts = line.split(separator: " ")
            guard let first = parts.first else { continue }
            let word = Self.normalize(String(first))
            let count = parts.count > 1 ? Float(parts[1]) ?? 1 : 1
            if ranks[word] == nil { ranks[word] = rank }
            rank += 1
            // Log weight: frequent words count more, but function words do not drown the rest.
            let weight = log(1 + count)
            var a = 0, b = 0
            var valid = true
            var trigrams: [Int] = []
            for letter in word {
                guard let c = index[letter] else { valid = false; break }
                trigrams.append((a * size + b) * size + c)
                a = b; b = c
            }
            guard valid else { continue }
            trigrams.append((a * size + b) * size)
            for t in trigrams { counts[t] += weight }
        }
        self.ranks = ranks

        let smoothing: Float = 0.05
        var logProbability = [Float](repeating: 0, count: counts.count)
        for context in 0..<(size * size) {
            let base = context * size
            var total: Float = 0
            for c in 0..<size { total += counts[base + c] }
            let denominator = total + smoothing * Float(size)
            for c in 0..<size {
                logProbability[base + c] = log((counts[base + c] + smoothing) / denominator)
            }
        }
        self.logProbability = logProbability
    }

    /// Position of the word in the frequency list, 0 is the most frequent. `nil` if absent.
    public func rank(of word: String) -> Int? {
        ranks[Self.normalize(word)].map(Int.init)
    }

    public func isLetter(_ character: Character) -> Bool {
        index[character] != nil
    }

    /// Mean log probability of the trigrams of the word. `nil` if a character is not a
    /// letter of this language or the word is empty.
    public func score(_ word: String) -> Float? {
        var a = 0, b = 0, n = 0
        var sum: Float = 0
        for letter in Self.normalize(word) {
            guard let c = index[letter] else { return nil }
            sum += logProbability[(a * size + b) * size + c]
            a = b; b = c; n += 1
        }
        guard n > 0 else { return nil }
        sum += logProbability[(a * size + b) * size]
        return sum / Float(n + 1)
    }

    static func normalize(_ word: String) -> String {
        word.lowercased().replacingOccurrences(of: "ё", with: "е")
    }
}

extension LanguageModel {
    public static let russianAlphabet = "абвгдежзийклмнопрстуфхцчшщъыьэюя"
    public static let englishAlphabet = "abcdefghijklmnopqrstuvwxyz"

    public static func russian(wordList: String) -> LanguageModel {
        LanguageModel(language: "ru", alphabet: russianAlphabet, wordList: wordList)
    }

    public static func english(wordList: String) -> LanguageModel {
        LanguageModel(language: "en", alphabet: englishAlphabet, wordList: wordList)
    }
}
