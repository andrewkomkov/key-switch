/// The text replacements of the user: a shortcut and the phrase that it stands for.
public struct TextReplacements: Sendable {
    /// Marks that can follow a shortcut. They stay after the phrase.
    private static let trailingMarks: Set<Character> = [".", ",", "!", "?", ";", ":", ")", "]", "»", "\""]

    private let phrases: [String: String]

    public var count: Int { phrases.count }

    /// Ignores an entry that cannot work on one typed word: a shortcut with white space,
    /// a phrase with a line break, a phrase that is the same as its shortcut.
    public init(_ items: [(shortcut: String, phrase: String)]) {
        var phrases: [String: String] = [:]
        for (shortcut, phrase) in items
        where !shortcut.isEmpty && !phrase.isEmpty && shortcut != phrase
            && !shortcut.contains(where: \.isWhitespace) && !phrase.contains(where: \.isNewline) {
            phrases[shortcut] = phrase
        }
        self.phrases = phrases
    }

    /// The text that replaces the typed word, or `nil` if the word is not a shortcut.
    public func expansion(for typed: String) -> String? {
        if let phrase = phrase(for: typed) { return phrase }
        guard let last = typed.lastIndex(where: { !Self.trailingMarks.contains($0) }) else { return nil }
        let marks = typed[typed.index(after: last)...]
        guard !marks.isEmpty, let phrase = phrase(for: String(typed[...last])) else { return nil }
        return phrase + marks
    }

    /// An exact match, or the shortcut with a capital first letter.
    private func phrase(for word: String) -> String? {
        if let phrase = phrases[word] { return phrase }
        guard let first = word.first, first.isUppercase,
              let phrase = phrases[first.lowercased() + word.dropFirst()]
        else { return nil }
        return phrase.prefix(1).uppercased() + phrase.dropFirst()
    }
}
