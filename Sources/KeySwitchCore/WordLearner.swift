/// Counts the unknown words that the user types. The counts live in memory only.
public struct WordLearner: Sendable {
    /// A word is learned when it was typed this many times.
    public static let threshold = 3

    private var counts: [String: Int] = [:]

    public init() {}

    /// Counts one more use. Returns `true` when the word reaches the threshold.
    public mutating func observe(_ word: String, language: String) -> Bool {
        let key = Self.entry(word, language: language)
        counts[key, default: 0] += 1
        guard counts[key] == Self.threshold else { return false }
        counts[key] = nil
        return true
    }

    public mutating func forget(_ word: String, language: String) {
        counts[Self.entry(word, language: language)] = nil
    }

    /// How a learned word is stored: the language code, a colon, the word.
    public static func entry(_ word: String, language: String) -> String {
        "\(language):\(word)"
    }
}
